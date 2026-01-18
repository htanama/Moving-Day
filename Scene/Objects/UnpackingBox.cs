using Godot;
using System;

public partial class UnpackingBox : StaticBody3D
{
	// In C#, we use [Export] just like @export in GDScript
	[Export]
	public Godot.Collections.Array<PackedScene> Contents { get; set; } = new Godot.Collections.Array<PackedScene>();

	[Export]
	public float UnpackForce = 5.0f;
	
	private bool _isOpened = false;
	private Marker3D _spawnPoint;

	public override void _Ready()
	{
		// Get the spawn point node we created in the scene
		_spawnPoint = GetNode<Marker3D>("SpawnPoint");
	}

	// This is the function your Player script will call
	public void OpenBox()
	{
		if (_isOpened || Contents.Count == 0) return;

		_isOpened = true;
		GD.Print("Unpacking box...");

		// Loop through each PackedScene in our list
		foreach (PackedScene itemScene in Contents)
		{
			if (itemScene == null) continue;

			// 1. Instantiate the object (The C# way)
			Node3D item = itemScene.Instantiate<Node3D>();
			
			// 2. Add it to the scene tree
			GetParent().AddChild(item);

			// 3. Set position to the box's spawn point
			item.GlobalPosition = _spawnPoint.GlobalPosition;

			// 4. If it's a RigidBody, give it a little "pop" upward
			if (item is RigidBody3D rb)
			{
				// Create a random direction for variety
				Vector3 randomDir = new Vector3(
					(float)GD.RandRange(-1, 1),
					1.0f, // Always pop up
					(float)GD.RandRange(-1, 1)
				).Normalized();

				rb.ApplyCentralImpulse(randomDir * UnpackForce);
			}
		}

		// Optional: Hide the box or change its appearance
		// QueueFree(); // Or use this to delete the box after opening
	}
}
