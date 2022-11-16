class_name Quantile

var coords: Vector2
var all_wave_tiles = []
var valid_wave_tiles = []
var is_collapsed = false

var neighbours = []
var all_quantiles
var master_game

var from = 0
var to = 0
var reset_count = 0

var final_wave_tile: WaveTileData
func _ready():
	pass

func connect_with_neighbours(quantiles: Array, sides: Array, master__game):
	all_quantiles = quantiles
	self.master_game = master__game
	for side in sides:
		var c_coords = side + coords
		
		var neighbour = null
		for n in quantiles:
			if n.coords == c_coords:
				neighbour = n
				break
		
		if neighbour:
			neighbours.push_back(neighbour)


func collapse() -> Array:
	if valid_wave_tiles.size() == 0:
		is_collapsed = true
		return[-1, Vector2(0,0)]
	
	var next_tile = get_weighted_random_wave_tile()
	var cell_id = next_tile.cell_id
	var aid = next_tile.sub_tile_coord
	
	from = valid_wave_tiles.size()
	to = 0
	valid_wave_tiles = []
	is_collapsed = true
	return [cell_id, aid]


func get_weighted_random_wave_tile():
	var scores = []
	var tiles = []
	var score_sum = 0
	var neighbours = master_game.get_neighbours(coords)
	for wave_tile in valid_wave_tiles:
		tiles.push_back(wave_tile)
		var s = wave_tile.get_score(neighbours)
		score_sum += s
		scores.push_back(s)
	
	var rng = randi()%score_sum
	var sum_up = 0
	for i in range(scores.size()):
		sum_up += scores[i]
		if sum_up > rng:
			return tiles[i]
			
	prints("ERROR no tile found")
	return null
	
	
func tell_the_neighbours(deepness = 0):
	if deepness > 1:
		return
		
	prints("tell_the_neighbours", coords, from, "->", to, "(", neighbours.size(), "neighbours)")
	for n in neighbours:
		n.remove_impossible_wavetiles(deepness + 1)

	
func should_collapse():
	return valid_wave_tiles.size() == 1 and is_collapsed == false

func cant_collapse():
	return valid_wave_tiles.size() == 0 and is_collapsed == false
	
func count_valid_neighbours(wave_tile: WaveTileData) -> int:
	var count = 0
	var wave_tile_tupel = wave_tile.get_tupel()
	prints("check wavetile", wave_tile.get_tupel())
	#prints("wave tile", wave_tile)
	
	for side in master_game.sides:
		var c_coords = coords + side
		var neighbour_id = master_game.tile_map.get_cellv(c_coords)
		
		match neighbour_id:
				-1:
					count += 1
				master_game.GENTILE_ID:
					
					var connector_quantile = master_game.get_quantile(c_coords)
							
					if connector_quantile:
						#check if that other quantile has whit current wavetile a an option
						if connector_quantile.valid_wave_tiles.size() == 0:
							count += 1
						else:
							for sub_wave_tile in connector_quantile.valid_wave_tiles:
								if sub_wave_tile.has_config_with(wave_tile_tupel, -side):
									count += 1
									break;
					else:
						assert(false)
				_:
					var neighbour_aid = master_game.tile_map.get_cell_autotile_coord(c_coords.x, c_coords.y)
					var tupel = [neighbour_id, neighbour_aid]
					var wave_tile_data = master_game.get_wave_tile_data_for_tupel(tupel)
					if wave_tile_data and wave_tile_data.has_config_with(wave_tile_tupel, -side):
						count += 1
	
	prints("count", count)	
	return count


func remove_impossible_wavetiles(deepnes = 0) -> bool:
	if is_collapsed:
		return true
	prints("remove_impossible_wavetiles")
	var left_overs = []
	
	for wave_tile in valid_wave_tiles:
		if count_valid_neighbours(wave_tile) == master_game.sides.size():
			left_overs.push_back(wave_tile)
		
				
	prints("left overs", left_overs.size())
	if left_overs.size() == 1:
		prints("forced collapse", coords)
		valid_wave_tiles = left_overs
		var data = collapse()
		prints("data from forces collapse", data)
		var final_id = data[0]
		var final_aid = data[1]
		master_game.set_tile_on_map(self.coords.x, self.coords.y, final_id, final_aid)
		tell_the_neighbours(deepnes)
		return true
		
	if valid_wave_tiles.size() != left_overs.size():
		from = valid_wave_tiles.size()
		to = left_overs.size()
		valid_wave_tiles = left_overs
		tell_the_neighbours(deepnes)
	
	return false
			


func reset():
	prints("RESET", coords)
	reset_count += 1
	valid_wave_tiles = []
	for t in all_wave_tiles:
		valid_wave_tiles.push_back(t)
		
	var counts = []
	var counts_wt = []
	var max_count = 0
	for wt in valid_wave_tiles:
		var c = count_valid_neighbours(wt)
		if c > 0:
			counts.push_back(c)
			counts_wt.push_back(wt)
			max_count = max(max_count, c)
	
	var possis = []
	for i in range(counts.size()):
		if counts[i] == max_count:
			possis.push_back(counts_wt[i])
			
	if possis.size() > 0:
		var id = randi() % possis.size()
		var best_wt = possis[id]
		valid_wave_tiles = [best_wt]
	else:
		valid_wave_tiles = []
		
	var data = collapse()
	var final_id = data[0]
	var final_aid = data[1]
	master_game.set_tile_on_map(self.coords.x, self.coords.y, final_id, final_aid)
	tell_the_neighbours()
