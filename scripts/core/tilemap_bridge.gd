class_name TileMapBridge
extends TileMapLayer

## Attach to your TileMapLayer. Registers with GridManager on ready.
## 
## SETUP:
## 1. Create a TileSet with an atlas source (use a 5x1 pixel image, 1px per tile)
## 2. Add custom data layer "cell_type" (type: int)
## 3. Set cell_type for each tile:
##    - Tile 0 = Entrance (0)
##    - Tile 1 = Beach (1)
##    - Tile 2 = Shallow (2)
##    - Tile 3 = Deep (3)
##    - Tile 4 = Obstacle (4)
## 4. Paint your map!

func _ready() -> void:
	GridManager.register_tilemap(self)
