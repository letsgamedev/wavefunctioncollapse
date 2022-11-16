tool
class_name MapGenerator
extends Node2D

const TILE_SIZE = 16

export(bool) var start_generation_process = false
export(NodePath) var tile_map_path
export(String) var gentile_name
export(String) var stucktile_name

var GENTILE_ID
var STUCKTILE_ID

var stuck_tile_set = false

var sides = [
		Vector2(0,-1),
		Vector2(0,1),
		Vector2(-1,0),
		Vector2(1,0),
		
		Vector2(-1,-1),
		Vector2(-1,1),
		Vector2(1,-1),
		Vector2(1,1)
	]

var wave_tiles: Array = []
var quantiles
var all_quantiles

onready var tile_map: TileMap

func _ready():
	seed(OS.get_ticks_msec())
	if Engine.editor_hint == false:
		start_generation_process = true
	pass


func _process(_delta):
	if start_generation_process:
		start_generation_process = false
		start_generation()
	

func _draw():
	if quantiles == null:
		return
		
	var tile_set: TileSet = tile_map.tile_set
	
	#var tile_set_texture_data: Image = tile_set_texture.get_data()

	for q in all_quantiles:
		if q.is_collapsed:
			continue
		var rect = Rect2( q.coords.x * TILE_SIZE, q.coords.y * TILE_SIZE, TILE_SIZE,TILE_SIZE)
		
		if q.valid_wave_tiles.size() == 0:
					draw_rect(Rect2(q.coords.x * TILE_SIZE, q.coords.y * TILE_SIZE, TILE_SIZE,TILE_SIZE),  Color(1,0,0,0.3))
		for wave_tile in q.valid_wave_tiles:
			var tile_set_texture: Texture = tile_set.tile_get_texture(wave_tile.cell_id)
			var tile_get_texture_offset = tile_set.tile_get_region(wave_tile.cell_id).position / TILE_SIZE
			var coords = wave_tile.sub_tile_coord + tile_get_texture_offset
			var src_rect = Rect2(coords * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
			var c = Color(1, 1, 1, 1.0 / float(q.valid_wave_tiles.size()))
			draw_texture_rect_region(tile_set_texture, rect, src_rect, c)
				
	
func start_generation():
	prints("Start Generation")
	stuck_tile_set = false
	tile_map = get_node(tile_map_path)
	prints("tile map", tile_map)
	yield(get_tree(),"idle_frame")
	
	GENTILE_ID = tile_map.tile_set.find_tile_by_name(gentile_name)
	STUCKTILE_ID = tile_map.tile_set.find_tile_by_name(stucktile_name)
	
	quantiles = []
	all_quantiles = []
	
	create_tabel()
	#draw_all_wave_tiles()
	make_new_content()

func add_new_quantile(x: int, y: int):
	var quantile = Quantile.new()
	quantile.coords = Vector2(x, y)
	quantiles.push_back(quantile)
	all_quantiles.push_back(quantile)
	for wave_tile in wave_tiles:
		quantile.valid_wave_tiles.push_back(wave_tile)
		quantile.all_wave_tiles.push_back(wave_tile)
		
		
func create_tabel():
	var used_rect = tile_map.get_used_rect()
	prints(used_rect)
	
	var start_x = used_rect.position.x
	var start_y = used_rect.position.y
	var end_x = start_x + used_rect.size.x
	var end_y = start_y + used_rect.size.y
	
	wave_tiles = []
	
	var o = 0
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			analyse_tile(x, y)
			o += 1
	
	prints(o, "tiles analysed")
	prints(wave_tiles.size(), "wavetiles date")
	
	#prints(wave_tiles)
	#prints(wave_tiles[0])
	#prints(wave_tiles[10])
	#prints(wave_tiles[20])
	


func analyse_tile(x, y):
	var id = tile_map.get_cell(x, y)
	#prints(x, y, "get id", id)
	if id == -1:
		return
		
	var aid = tile_map.get_cell_autotile_coord(x, y)
	var tile_name = get_tile_name(x, y)
	
	if tile_name == gentile_name:
		add_new_quantile(x, y)
		return
	
		
	var wave_tile:WaveTileData = get_wave_tile(id, aid)
	
	var side_tupels = {}
	for side in sides:
		var side_id = tile_map.get_cell(x + side.x, y + side.y)
		var side_name = get_tile_name(x + side.x, y + side.y)
		
		if side_name == gentile_name:
			return
		
		if side_id == -1 :
			side_tupels[side] = [-1, Vector2(0,0)]
	
		if side_id != -1 and side_name != gentile_name:
			var s_aid = tile_map.get_cell_autotile_coord(x + side.x, y + side.y)
			side_tupels[side] = [side_id, s_aid]
	
	if wave_tile.has_config(side_tupels):
		wave_tile.increase_config(side_tupels)
	else:
		wave_tile.add_config(side_tupels)


func get_tile_name(x: int, y: int) -> String:
	var id = tile_map.get_cell(x, y)
	if id == -1:
		return "none"
	var tile_name = tile_map.tile_set.tile_get_name(id)
	return tile_name
	
	
func get_wave_tile(cell_id: int, coord: Vector2):
	for wave_tile in wave_tiles:
		if wave_tile.cell_id == cell_id and wave_tile.sub_tile_coord == coord:
			return wave_tile
	
	var new_tile = WaveTileData.new()
	new_tile.cell_id = cell_id
	new_tile.sub_tile_coord = coord
	wave_tiles.push_back(new_tile)
	
	return new_tile


func make_new_content():			
	prints("quantiles:", quantiles.size())
	
	for q in quantiles:
		q.connect_with_neighbours(quantiles, sides, self)
				
	yield(get_tree(),"idle_frame")
	

	for qantile in quantiles:
		qantile.remove_impossible_wavetiles(999)
	update()
	#yield(get_tree().create_timer(1), "timeout")
		
	while quantiles.size() > 0 and stuck_tile_set == false:
		prints("loop")

		#if saver % 10 == 0:
		yield(get_tree(),"idle_frame")
		update()
		#yield(get_tree().create_timer(1), "timeout")
		var collapsing_quantile = get_next_quantile(quantiles)
		if collapsing_quantile == null:
			prints("loop null")
			break
		if collapsing_quantile.cant_collapse():
			if collapsing_quantile.reset_count < 3 and false:
				collapsing_quantile.reset()
				collapsing_quantile.remove_impossible_wavetiles()
			else:
				prints("loop cant collapse")
				collapsing_quantile.is_collapsed = true
				set_tile_on_map(collapsing_quantile.coords.x, collapsing_quantile.coords.y, STUCKTILE_ID)
				collapsing_quantile.tell_the_neighbours()
		else:
			prints("loop normal")
			if collapsing_quantile.remove_impossible_wavetiles() == false:
				if collapsing_quantile.is_collapsed == false:
					var data = collapsing_quantile.collapse()
					var final_id = data[0]
					var final_aid = data[1]
					prints("data", data)
					set_tile_on_map(collapsing_quantile.coords.x, collapsing_quantile.coords.y, final_id, final_aid)
					collapsing_quantile.tell_the_neighbours()
		
		quantiles = check_for_auto_collapse(quantiles)




func get_next_quantile(quantiles: Array):
	var all_with_collapsed_neighbours = []
	for q in quantiles:
		if q.is_collapsed == false:
			var base = q.coords
			for side in sides:
				var id = tile_map.get_cell(base.x + side.x, base.y + side.y)
				if id == 0:
					all_with_collapsed_neighbours.push_back(q)
					break
	
	if all_with_collapsed_neighbours.size() == 0:
		var possis = []
		for q in quantiles:
			if q.is_collapsed == false:
				possis.push_back(q)
		if possis.size() == 0:
			return null
		var id = randi() % possis.size()
		return possis[id]
	
	var min_resets
	for q in all_with_collapsed_neighbours:
		if min_resets == null:
			min_resets = q
		else:
			if q.reset_count < min_resets.reset_count:
				min_resets = q
				
	var min_waves
	for q in all_with_collapsed_neighbours:
		if min_waves == null:
			min_waves = q
		else:
			if q.reset_count == min_resets and q.valid_wave_tiles.size() < min_waves.valid_wave_tiles.size():
				min_waves = q
				
	return min_waves
		



func check_for_auto_collapse(quantiles) -> Array:
	var left_overs = []

	for q in quantiles:
		if q.is_collapsed == false:
			left_overs.push_back(q)
	quantiles = left_overs
	
	return quantiles


func set_tile_on_map(x,y, id, atlas_pos = Vector2(0,0)):
	prints("set_tile_on_map", id, atlas_pos)
	print_stack()
	if id == -1:
		id = STUCKTILE_ID
		atlas_pos = Vector2(0,0)
		stuck_tile_set = true
	tile_map.set_cell(x,y, id, false, false, false, atlas_pos)


func draw_all_wave_tiles():
		var x = 0
		var y = 0
		for wt in wave_tiles:
			set_tile_on_map(x + 39, y + 1, wt.cell_id, wt.sub_tile_coord)
			x += 1
			if x >= 10:
				y += 1
				x = 0
			
			


func get_quantile(coords):
	for n in all_quantiles:
		if n.coords == coords:
			return n
	
	return null

func get_wave_tile_data_for_tupel(tupel):
	for wt in wave_tiles:
		if wt.get_tupel() == tupel:
			return wt
	
	return null
	
	
func get_neighbours(coords):
	var neighbours = {}
	for side in sides:
		var c_coords = coords + side
		var neighbour_id = tile_map.get_cellv(c_coords)
		if neighbour_id == -1 or neighbour_id == GENTILE_ID or neighbour_id == STUCKTILE_ID:
			neighbours[side] = [-1, Vector2(0,0)]
		else:
			var neighbour_aid = tile_map.get_cell_autotile_coord(c_coords.x, c_coords.y)
			neighbours[side] = [neighbour_id, neighbour_aid]
	return neighbours
