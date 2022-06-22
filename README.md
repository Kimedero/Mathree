# AI Controlled Cars in Godot
 A small experiment on controlling cars with context-based steering AI in Godot.

The AI uses Raycasts to figure out if there's anything blocking the front of the car, and if there is, it reduces the speed, to allow the steering mechanism time to turn the car away from the obstacle. The AI can also unflip the car.