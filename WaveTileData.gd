class_name WaveTileData

var cell_id: int
var sub_tile_coord: Vector2

var configs = []

func _to_string():
	var f = ""
	for config in configs:
		f += str("\n--", config)
	return "\nWTD: ID: (%s, %s) - Configs(%s): %s" % [cell_id, sub_tile_coord, configs.size(), f]


func add_config(new_config):
	new_config["count"] = 1
	configs.push_back(new_config)

func has_config(new_config) -> bool:
	var keys = new_config.keys()
	for c in configs:
		if c.keys().size() - 1 == keys.size():
			var found_one_not_fitting = false
			for key in keys:
				if c[key] != new_config[key]:
					found_one_not_fitting = true
					break
			if found_one_not_fitting == false:
				return true
	
	return false


func get_tupel():
	return [cell_id, sub_tile_coord]

func increase_config(side_tupels):
	var keys = side_tupels.keys()
	for c in configs:
		if c.keys().size() - 1 == keys.size():
			var found_one_not_fitting = false
			for key in keys:
				if side_tupels[key][0] == -1:
					pass
				elif c[key] != side_tupels[key]:
					found_one_not_fitting = true
					break
			if found_one_not_fitting == false:
				c["count"] += 1
	
	
func has_config_with(tupel, side):
	for config in configs:
		if config.has(side) and config[side] == tupel:
			return true
	
	return false


func get_score(neighbours) -> int:
	var keys = neighbours.keys()
	for c in configs:
		var found_one_not_fitting = false
		for key in keys:
			if c[key] != neighbours[key]:
				found_one_not_fitting = true
				break
		if found_one_not_fitting == false:
			return c["count"]
		
	return 1
