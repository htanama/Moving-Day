using Godot;
using System;
using System.Collections.Generic;

public partial class PlacementZone : Area3D
{
	[Export] public Label MyChecklistLabel;
	[Export] public string ZoneName = "Placement Area";
	[Export] public int RequiredItems = 3; // How many items do we need?
	
	// We store a list of items currently in the zone
	private List<RigidBody3D> _itemsInZone = new List<RigidBody3D>();
	private bool _isGoalReached = false;
 	private GpuParticles3D _stars;
	private AudioStreamPlayer3D _audio;
	private HUDManager _hud;
	public override void _Ready()
	{
		_stars = GetNode<GpuParticles3D>("GPUParticles3D");
		_audio = GetNode<AudioStreamPlayer3D>("VictorySound");
		// Connect the signals
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
		_hud = GetTree().Root.FindChild("HUD", true, false) as HUDManager;
	}

	private void OnBodyEntered(Node3D body)
	{
		if (body is RigidBody3D rb && !_itemsInZone.Contains(rb))
		{
			_itemsInZone.Add(rb);
			CheckCompletion();
		}
	}

	private void OnBodyExited(Node3D body)
	{
		if (body is RigidBody3D rb && _itemsInZone.Contains(rb))
		{
			_itemsInZone.Remove(rb);
			CheckCompletion();
		}
	}

	private void CheckCompletion()
	{
		int count = _itemsInZone.Count;
		bool isComplete = count >= RequiredItems;

		// Tell the HUD to update ONLY my specific label
		
		if (_hud != null && MyChecklistLabel != null)
		{
			_hud.UpdateZoneStatus(MyChecklistLabel, ZoneName, count, RequiredItems, isComplete);
		}

		if (isComplete && !_isGoalReached)
		{
			TriggerVictory();
		}
		else if (!isComplete)
		{
			_isGoalReached = false;
		}
	}
	

	private void TriggerVictory()
	{
		_isGoalReached = true;
		
		if (_hud != null)
		{
			_hud.PlayVictoryBurst();
		}
		
		// 1. Play Sound
		if (_audio != null) _audio.Play();

		// 2. Burst Stars
		if (_stars != null)
		{
			_stars.Restart(); // Resets the one-shot timer
			_stars.Emitting = true;
		}
		
		// 3. Optional: Call to HUD Manager
		// _hud.ShowMessage("Counter Organized!");
	}



	// private void CheckCompletion()
	// {
	// 	int placedCount = _itemsInZone.Count;

	// 	if (placedCount >= RequiredItems && _isGoalReached != true)
	// 	{
	// 		TriggerVictory();
	// 	}

	// 	else if (placedCount < RequiredItems)
	// 	{
	// 		_isGoalReached = false; // Reset if they take items away
	// 	}

	// 	GD.Print($"DEBUG: Items in zone: {_itemsInZone.Count} / {RequiredItems}");		
		
	// }
}
