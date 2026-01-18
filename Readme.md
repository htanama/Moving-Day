Moving Day: Relaxing Simulator

A cozy, physics-based interior decoration and organization simulator built with Godot 4 and C#. 
Players unpack boxes, manage clutter, and arrange their new home with smooth, tactile 3D interactions.

![Moving-Day items to organize](https://github.com/htanama/Moving-Day/blob/main/Moving-Day-Pic2.png)

Key Technical Features

Precision Handling: Objects are moved using a custom PID-style physics pull system, ensuring they follow the player's hand naturally without clipping through walls.

Dynamic Rotation: 
Y-Axis Spin: Rotate item to adjust its orientation by holding right mouse button
90° X-Axis Flip: Use a quick-toggle system to flip items (like cup facing incorrect orientation) with instant response.

Constraint Management: Objects stay upright and stable while being carried, preventing "physics jitter."

Holographic Ghost Preview

Smart Alignment: A real-time "ghost" preview appears on the floor beneath the object you are holding, showing exactly where it will land.

Multi-Mesh Support: Handles complex 3D models with multiple sub-meshes (like the Bamboo Steamer) as a single holographic unit.

Depth-Correct Rendering: Uses a custom StandardMaterial3D with No Depth Test to ensure the ghost is always bright, visible, and clean.


Interactive Unpacking System

Dynamic Spawning: Cardboard boxes act as RigidBody3D containers that "pop" items out with random physical force.

Smart HUD: A context-sensitive UI system that fades in/out to provide tips (e.g., "[LMB] Pick up," "[G] Flip") only when needed.

### Controls

| Key / Input | Action | Description |
| :--- | :--- | :--- |
| **W / A / S / D** | **Move** | Navigate the player through the room. |
| **Space** | **Jump** | Reach higher surfaces or clear obstacles. |
| **Left Mouse (LMB)** | **Interact** | Pick up objects, drop them, or unpack boxes. |
| **Right Mouse (RMB)** | **Rotate (Y)** | Hold and move mouse to spin the item horizontally. |
| **G Key** | **Flip (X)** | Instantly toggle the item 90° (useful for cups/plates). |

Built With

    Engine: Godot 4.x

    Language: C# (.NET 6.0+)

    Physics: Godot Physics 3D


Solving the "Ghost" Overlap Rendering

Challenge: When creating ghosts for complex objects (like a Bamboo Steamer), multiple internal meshes would overlap. Because they were transparent, these overlapping areas appeared darker and messy, breaking the "hologram" look.

Solution: I implemented a custom StandardMaterial3D (GhostMaterial.tres) for the ghost preview. By enabling No Depth Test and increasing the Render Priority, 
I forced Godot to ignore internal mesh occlusions. This resulted in a bright, uniform blue glow regardless of how many sub-meshes the object contained.