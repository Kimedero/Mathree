# Mathree
 
 Mathree is a Kenyan sheng word for public transport vehicles.

 This is a small experiment on controlling mathrees with context-based steering AI in Godot using mathree models.

 It uses the VehicleBody node in Godot as the basis for the mathree.

The AI uses Raycasts to figure out if there's anything blocking the front of the mathree.

One Raycast figures out how far away an obstacle is, infront of the mathree and calculates the acceration factor from that distance. That means, if the raycast collision distance is, say, 80, the mathree can accelerate to its full speed, but the lower that number gets, the slower the mathree gets. We also apply a curve to affect this velocity non-linearly. This means, when the  ray collision distance is very low, the mathree doesn't absolutely stop moving. 

We might have figure out a better way to reduce speed according to the distance from an obstacle. The AI is still quite rudimentary.

Also, there's an application of brakes, when the mathree speed is high and there appears to be an obstacle ahead suddenly.

The mathree can also unflip itself GTA5-style, by applying a rotational force to itself, while accounting for its weight.

We use timers to check for changes in condition, because commiting the checking to every frame (via _process or _physics_process) would overuse the CPU and slow down the game. This is to be tested further.

Enjoy and reach out if you make any interesting changes or have questions. I'd love to see what can happen, from here.