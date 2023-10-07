
# CS2 Smoke

# How To Use
- Create a new smoke instance with the .New function
- That will be your smoke instance and will be used for managing and creating the smoke
- When creating the smoke you will see a set of variables:
```lua
Radius: Number = The radius of the expanded smoke

Resolution: Number = The size of voxels (1/Resolution)

Life_Time: Vector2 = The life span of each voxel, a random number from x to y

BURST_SPEED: Vector2 = The speed of which the smoke will expand, a random number from x to y
```
- To create the smoke origin do something similar to this example:
```lua
local Origin = Smoke:CreateVoxel(Vector3.new(0,2,0), 0, true)
```

- To expand the smoke origin do something similar to this example:
```lua
Smoke:ExpandVoxel(Origin)
```

- To remove the Voxels to mimic shooting you can do something similar to this example:
```lua
Smoke:ShootVoxels(StartPosition, EndPosition, 2)
```
This will shoot a 2x2 block that starts at the StartPosition and ends at the EndPosition

## License

[MIT](https://choosealicense.com/licenses/mit/)

