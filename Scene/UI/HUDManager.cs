using Godot;
using System;

public partial class HUDManager : Control
{
	private Label _pickupTip;
	private Label _placeTip;
	private Label _rotateTip;

	public override void _Ready()
	{
		_pickupTip = GetNode<Label>("VBoxContainer/PickupTip");
		_placeTip = GetNode<Label>("VBoxContainer/PlaceTip");
		_rotateTip = GetNode<Label>("VBoxContainer/RotateTip");

		HideAllTips();
	}

	public void HideAllTips()
	{
		_pickupTip.Visible = false;
		_placeTip.Visible = false;
		_rotateTip.Visible = false;
	}	

	public void ShowPickupHint(string itemName)
	{
		HideAllTips();
		_pickupTip.Text = $"Click Left Mouse Button to Pick Up {itemName}";
		_pickupTip.Visible = true;
	}

	public void ShowHoldingHints()
	{
		HideAllTips();
		_placeTip.Visible = true;
		_rotateTip.Visible = true;
	}
}
