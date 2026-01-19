using Godot;
using System;

public partial class HUDManager : Control
{	
	[ExportGroup("Level Completion Requirements")]
	[Export] public Label LabelCounterArea;
	[Export] public Label LabelCabinetArea;
	[Export] public int TotalZonesRequired = 2; 

	private int _completedZones = 0;
	private Label _pickupTip;
	private Label _placeTip;
	private Label _rotateTip;
	private Tween _fadeTween;
	private GpuParticles2D _screenStars;
	public override void _Ready()
	{
		_screenStars = GetNode<GpuParticles2D>("ScreenStars");

		_pickupTip = GetNode<Label>("VBoxContainer/PickupTip");
		_placeTip = GetNode<Label>("VBoxContainer/PlaceTip");
		_rotateTip = GetNode<Label>("VBoxContainer/RotateTip");

		_pickupTip.Modulate = new Color (1,1,1,0);
		_placeTip.Modulate = new Color (1,1,1,0);
		_rotateTip.Modulate = new Color (1,1,1,0);		

		// Objective for the player and text will be override by another function.
		LabelCounterArea.Text = "[ ] Stove and Counter Area (0/3)";
		LabelCabinetArea.Text = "[ ] Cabinet Area (0/3)";
	}

	public void HideAllTips()
	{
		FadeTo(_pickupTip, 0.0f);
		FadeTo(_placeTip, 0.0f);
		FadeTo(_rotateTip, 0.0f);
	}	

	public void ShowPickupHint(string itemName)
	{
		HideAllTips();
		_pickupTip.Text = $"Click Left Mouse Button to Pick Up {itemName}";
		FadeTo(_pickupTip, 1.0f);   // Fade In
		FadeTo(_placeTip, 0.0f);    // Fade Out others
		FadeTo(_rotateTip, 0.0f);
	}

	public void ShowHoldingHints()
	{		
	 	FadeTo(_pickupTip, 0.0f);
		FadeTo(_placeTip, 1.0f);    // Fade In place/rotate
		FadeTo(_rotateTip, 1.0f);
	}

	private void FadeTo(CanvasItem node, float targetOpacity)
	{
		// Only trigger a tween if the opacity is actually different
		if (Mathf.IsEqualApprox(node.Modulate.A, targetOpacity)) return;

		// Create a tween for this specific node
		Tween tween = GetTree().CreateTween();
		// Animate the 'modulate:a' property (Alpha) over 0.2 seconds
		tween.TweenProperty(node, "modulate:a", targetOpacity, 0.2f)
			 .SetTrans(Tween.TransitionType.Quad)
			 .SetEase(Tween.EaseType.Out);
	}

	public void PlayVictoryBurst()
	{
		if (_screenStars != null)
		{
			// Reset and Emit
			_screenStars.Emitting = false;
			_screenStars.Restart();
			_screenStars.Emitting = true;            
		}
	}

	public void UpdateZoneStatus(Label targetLabel, string zoneName, int current, int required, bool isDone)
	{
		if (targetLabel == null) return;

		string status = isDone ? "[DONE]" : "[  ]";
		targetLabel.Text = $"{status} {zoneName} ({current}/{required})";

		// Give the text a little "nudge" color-wise
		targetLabel.Modulate = isDone ? Colors.Green : Colors.White;

		// Play a little scale animation
		Tween tween = GetTree().CreateTween();
		tween.TweenProperty(targetLabel, "scale", new Vector2(1.05f, 1.05f), 0.05f);
		tween.TweenProperty(targetLabel, "scale", new Vector2(1.0f, 1.0f), 0.05f);

		CheckOverallVictory();
	}
	
	private void CheckOverallVictory()
	{
		// We check all placement areas in the scene and to make sure the PlacementZone.cs is attached
		var allAreas = GetTree().GetNodesInGroup("PlacementArea");
		int finishedCount = 0;

		foreach (Node node in allAreas)
		{
			// We check if the node has our script and if that script says it's done
			if (node is PlacementZone zone && zone.IsComplete)
			{
				finishedCount++;
			}
		}

		if (finishedCount >= TotalZonesRequired)
		{
			TriggerLevelVictory();
		}
	}
	
	private void ApplyBounceEffect(Label label)
	{
		// Makes the text "pop" slightly when it updates
		Tween tween = GetTree().CreateTween();
		tween.TweenProperty(label, "scale", new Vector2(1.1f, 1.1f), 0.1f);
		tween.SetTrans(Tween.TransitionType.Back);
		tween.TweenProperty(label, "scale", new Vector2(1.0f, 1.0f), 0.1f);
	}

	private void TriggerLevelVictory()
	{
		PlayVictoryBurst();
		
		// You can add logic here to open a "Next Level" button 
		// or show a big "KITCHEN ORGANIZED" message.
	}
}
