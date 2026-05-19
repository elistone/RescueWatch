@tool
extends EditorScript

## Run this once from Editor → File → Run Script
## It creates the zone_tiles.png for your TileSet.

func _run() -> void:
	var img := Image.create(320, 64, false, Image.FORMAT_RGBA8)

	var colors := [
		Color("D9D9D9"),  # Entrance
		Color("F5DEB3"),  # Beach
		Color("9EEDEF"),  # Shallow
		Color("4087D1"),  # Deep
		Color("804D33"),  # Obstacle
	]

	for i in range(5):
		var rect := Rect2i(i * 64, 0, 64, 64)
		img.fill_rect(rect, colors[i])

	img.save_png("res://resources/zone_tiles.png")
	print("zone_tiles.png saved! Re-import in editor.")
