using Godot;
using System;


public partial class Player : CharacterBody3D
{
	[Export] public Material GhostMaterial;

	private AudioStreamPlayer3D _dropSound;

	private HUDManager _hud;

	// --- Constants ---
	private const float Speed = 5.0f;
	private const float JumpVelocity = 4.5f;
	private const float MouseSensitivity = 0.002f;

	// --- Node References ---
	private Node3D _head;
	private Camera3D _camera;
	private RayCast3D _raycast;
	private Marker3D _holdPos;
	private Node3D _shadowDot;
	private RayCast3D _dropRay;
	private Node3D _ghostPreview;
	private Label3D _displayInformation;
	private Control _crosshair; // Changed to Control to cover various UI types

	// --- Gameplay Variables ---
	private float _gravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();
	private RigidBody3D _pickedObject = null;
	private float _pullPower = 20.0f;
	private RigidBody3D _lastHoveredObject = null;
	private bool _isRotatingObject = false;
	private float _rotationSpeed = 0.05f;
	private bool _isTilted = false; // False = 0 deg, True = 90 deg
	private float _targetTiltX = 0.0f; // Stores the desired X rotation
	public override void _Ready()
	{
		// Initializing node references
		_hud = GetTree().Root.FindChild("HUD", true,false) as HUDManager;
		_head = GetNode<Node3D>("Head");
		_camera = GetNode<Camera3D>("Head/Camera3D");
		_raycast = GetNode<RayCast3D>("Head/Camera3D/RayCast3D");
		_holdPos = GetNode<Marker3D>("Head/Camera3D/HoldPos");
		_shadowDot = GetNode<Node3D>("ShadowDot");
		_dropRay = GetNode<RayCast3D>("Head/Camera3D/DropRay");
		_ghostPreview = GetNode<Node3D>("GhostPreview");
		_displayInformation = GetNode<Label3D>("DisplayInformation");
		_crosshair = GetNode<Control>("CanvasLayer/CenterContainer/Crosshair");
		_dropSound = GetNode<AudioStreamPlayer3D>("Head/Camera3D/DropSound");

		DisplayInformation();
		Input.MouseMode = Input.MouseModeEnum.Captured;
		
		_ghostPreview.Visible = false;
		_shadowDot.Visible = false;

		if (_crosshair != null)
			_crosshair.Modulate = Colors.White;
	}

	private async void DisplayInformation()
	{
		_displayInformation.Visible = true;
		// await the timer timeout
		await ToSignal(GetTree().CreateTimer(5.0), SceneTreeTimer.SignalName.Timeout);
		_displayInformation.Visible = false;	
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventMouseMotion mouseEvent)
		{
			if (_pickedObject != null && _isRotatingObject)
			{
				// Spin the object
				float rotAmount = mouseEvent.Relative.X * _rotationSpeed;
				Vector3 currentAngVel = _pickedObject.AngularVelocity;
				currentAngVel.Y = rotAmount * 10.0f;
				_pickedObject.AngularVelocity = currentAngVel;
			}
			else
			{
				// Look around
				RotateY(-mouseEvent.Relative.X * MouseSensitivity);
				_head.RotateX(-mouseEvent.Relative.Y * MouseSensitivity);
				
				// Clamp vertical look
				Vector3 headRot = _head.Rotation;
				headRot.X = Mathf.Clamp(headRot.X, Mathf.DegToRad(-80), Mathf.DegToRad(80));
				_head.Rotation = headRot;
			}
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		// Add gravity
		if (!IsOnFloor())
			velocity.Y -= _gravity * (float)delta;

		// Handle Jump
		if (Input.IsActionJustPressed("jump") && IsOnFloor())
			velocity.Y = JumpVelocity;

		// Get movement input
		Vector2 inputDir = Input.GetVector("left", "right", "forward", "backward");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}
		
		// Take the current local velocity and store it as the new global velocity
		Velocity = velocity;
		MoveAndSlide();

		// --- Picked Object Physics ---
		if (_pickedObject != null)
		{
			Vector3 targetPos = _holdPos.GlobalPosition;
			Vector3 currentPos = _pickedObject.GlobalPosition;
			
			// Move object toward hand
			Vector3 velocityVector = (targetPos - currentPos) * _pullPower;			
			_pickedObject.LinearVelocity = velocityVector.LimitLength(25.0f);
						
			// Keep object upright and adding Tilting rotation in X-axis
			Vector3 currentRot = _pickedObject.GlobalRotation;
			//_pickedObject.GlobalRotation = new Vector3(0, currentRot.Y, 0);
			_pickedObject.GlobalRotation = new Vector3(_targetTiltX, currentRot.Y, 0); // adding Tilting Rotatation in x-axis
			

			if (_isRotatingObject)
			{
				Vector3 angVel = _pickedObject.AngularVelocity;
				angVel.X = 0;
				angVel.Z = 0;
				_pickedObject.AngularVelocity = angVel;
			}
			else
			{
				_pickedObject.AngularVelocity = Vector3.Zero;
			}

			// --- Ghost & Shadow Logic ---
			_dropRay.GlobalPosition = _pickedObject.GlobalPosition;
			if (_dropRay.IsColliding())
			{
				Vector3 hitPos = _dropRay.GetCollisionPoint();
				_shadowDot.Visible = true;
				
				float dist = _pickedObject.GlobalPosition.DistanceTo(hitPos);
				float shadowScale = Mathf.Clamp(1.0f - (dist * 0.3f), 0.2f, 1.0f);
				_shadowDot.Scale = new Vector3(shadowScale, 1, shadowScale);
				_shadowDot.GlobalPosition = hitPos + new Vector3(0, 0.01f, 0);

				_ghostPreview.Visible = true;
				_ghostPreview.GlobalPosition = hitPos + new Vector3(0, 0.01f, 0);
				_ghostPreview.GlobalBasis = _pickedObject.GlobalBasis;
			}
			else
			{
				_shadowDot.Visible = false;
				_ghostPreview.Visible = false;
			}
		}
		else
		{
			_shadowDot.Visible = false;
			_ghostPreview.Visible = false;
		}

		HandleHighlight();
	}

	public override void _Input(InputEvent @event)
	{
		if (@event.IsActionPressed("ui_cancel"))
			Input.MouseMode = Input.MouseModeEnum.Visible;
			
		if (@event.IsActionPressed("left_mouse_click"))
			Input.MouseMode = Input.MouseModeEnum.Captured;

		if (@event.IsActionPressed("interact"))
		{
			if (_pickedObject == null)
				PickUpObject();
			else
				DropObject();
		}

		if (@event.IsActionPressed("toggle_tilt") && _pickedObject != null)
		{
			_isTilted = !_isTilted;
			// Toggle If target is 0, make it 90. Otherwise, make it 0.
			if (_isTilted)
			{
				if (_targetTiltX == 0.0f)
				{
					_targetTiltX = Mathf.DegToRad(90);
				}
				else
					_targetTiltX = 0.0f;
			}
		}

		if (@event.IsActionPressed("rotate"))
			_isRotatingObject = true;
		else if (@event.IsActionReleased("rotate"))
			_isRotatingObject = false;
	}

	private void PickUpObject()
	{
		if (_raycast.IsColliding())
		{
			var collider = _raycast.GetCollider();

			// Check for Box: can we open it?
			if (collider is UnpackingBox box)
			{
				box.OpenBox();
			}


			if (collider is RigidBody3D rb)
			{
				_pickedObject = rb;
				_pickedObject.GravityScale = 0.0f;
				_pickedObject.SetCollisionMaskValue(3, false); // Layer 3 is Player
			

				// Clear any old ghost parts
				foreach (Node child in _ghostPreview.GetChildren())
				{
					child.QueueFree();
				}

				var meshes = _pickedObject.FindChildren("*", "MeshInstance3D", true);
				foreach (Node node in meshes)
					if (node is MeshInstance3D originalMesh)
					{
						// Skip hidden parts to keep the ghost bright and clean
						if (!originalMesh.Visible) continue;

						MeshInstance3D ghostPart = (MeshInstance3D)originalMesh.Duplicate();
						_ghostPreview.AddChild(ghostPart);
						// Keep the ghost part in the same local position ---
						ghostPart.Transform = originalMesh.Transform;
						// Clear highlight
						ghostPart.MaterialOverlay = null;
						// Make it blue/transparent
						ghostPart.MaterialOverride = GhostMaterial;
					}
			}
		}
	}

	private void DropObject()
	{
		if (_pickedObject != null)
		{
			// Play the sound immediately when the button is pressed
			if (_dropSound != null)
			{
				// Subtle pitch variation makes it sound less robotic
				_dropSound.PitchScale = (float)GD.RandRange(0.9f, 1.1f);
				_dropSound.Play();
			}
			
			if (_dropRay.IsColliding())
			{
				Vector3 hitPos = _dropRay.GetCollisionPoint();
				Vector3 hitNormal = _dropRay.GetCollisionNormal();
				_pickedObject.GlobalPosition = hitPos + (hitNormal * 0.05f);
				
				Vector3 currentRot = _pickedObject.GlobalRotation;
				_pickedObject.GlobalRotation = new Vector3(0, currentRot.Y, 0);
			}

			// Reset physics properties
			_pickedObject.SetCollisionMaskValue(3, true);
			_pickedObject.GravityScale = 1.0f;
			_pickedObject.LinearVelocity = Vector3.Zero;
			_pickedObject.AngularVelocity = Vector3.Zero;

			// Cleanup visuals
			_ghostPreview.Visible = false;			
			_pickedObject = null;
		}
	}

	private void HandleHighlight()
	{
		if (_pickedObject != null)
		{
			if (_crosshair != null) _crosshair.Modulate = Colors.White;
			_hud.ShowHoldingHints();
			
			if (_lastHoveredObject != null)
			{
				SetHighlight(_lastHoveredObject, false);
			}
			return;
		}

		if (_raycast.IsColliding())
		{
			var collider = _raycast.GetCollider();
			if (collider is RigidBody3D rb)
			{
				if (_crosshair != null) _crosshair.Modulate = Colors.Yellow;
				// hint to pick up item
				_hud.ShowPickupHint(rb.Name);

				if (_lastHoveredObject != rb)
				{
					if (_lastHoveredObject != null)
						SetHighlight(_lastHoveredObject, false);
					
					SetHighlight(rb, true);
					_lastHoveredObject = rb;
				}
			}
			else
			{
				ClearHighlight();
				_hud.HideAllTips();
			}
		}
		else
		{
			ClearHighlight();
			_hud.HideAllTips();
		}
	}

	private void ClearHighlight()
	{
		if (_crosshair != null) _crosshair.Modulate = Colors.White;
		if (_lastHoveredObject != null)
		{
			SetHighlight(_lastHoveredObject, false);
			_lastHoveredObject = null;
		}
	}

	private void SetHighlight(RigidBody3D obj, bool enabled)
	{
		if (obj == null) return;

		// This finds ALL MeshInstance3Ds attached to this RigidBody
		var allMeshes = obj.FindChildren("*", "MeshInstance3D", true);

		foreach (Node node in allMeshes)
		{
			if (node is MeshInstance3D mesh)
			{
				// Check if the mesh has the "Material Overlay" slot filled in the Inspector
				if (mesh.MaterialOverlay is StandardMaterial3D overlay)
				{
					Color color = overlay.AlbedoColor;
					color.A = enabled ? 1.0f : 0.0f; // 1.0 is visible, 0.0 is invisible
					overlay.AlbedoColor = color;
				}
			}
		}
	}
}
