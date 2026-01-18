using Godot;
using System;

public partial class HUDManager : Control
{
	private Label _pickupTip;
	private Label _placeTip;
	private Label _rotateTip;
	private Tween _fadeTween;
	
	public override void _Ready()
	{
		_pickupTip = GetNode<Label>("VBoxContainer/PickupTip");
		_placeTip = GetNode<Label>("VBoxContainer/PlaceTip");
		_rotateTip = GetNode<Label>("VBoxContainer/RotateTip");

		_pickupTip.Modulate = new Color (1,1,1,0);
		_placeTip.Modulate = new Color (1,1,1,0);
		_rotateTip.Modulate = new Color (1,1,1,0);		
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
}
