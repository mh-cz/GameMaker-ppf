function ppf_init() {
	
	globalvar ppf;
	ppf = {
		
		CELL_SIZE: 32,
		SOLID_OBJ: obj_solid,
		HIDE_NODES: true,
		
		STATE: {
			WALK: 0,
			JUMP: 1,
		},
		
		AI: {
			Basic: {
				ACTIVE: true,
				HITBOX_WIDTH: 36,
				HITBOX_HEIGHT: 36,
				SPEED: 4,
				JUMP: 10,
				GRAVITY: 0.3,
				MAX_FALL_HEIGHT: 32 * 5,
				CAN_JUMP: true,
				WAIT_BEFORE_JUMP: 0 * room_speed,
				WAIT_AFTER_LANDING: 0 * room_speed,
				DEBUG_DRAW: false,
				DEBUG_DRAW_COLOR: c_lime,
				DEBUG_DRAW_AI_PATH: true,
			},
			
			Big_n_Slow: {
				ACTIVE: false,
				HITBOX_WIDTH: 24,
				HITBOX_HEIGHT: 24,
				SPEED: 1.5,
				JUMP: 5,
				GRAVITY: 0.3,
				MAX_FALL_HEIGHT: 32 * 4,
				CAN_JUMP: true,
				WAIT_BEFORE_JUMP: 0.2 * room_speed,
				WAIT_AFTER_LANDING: 0.3 * room_speed,
				DEBUG_DRAW: false,
				DEBUG_DRAW_COLOR: c_orange,
			},
		},
	};
}

#region PPF

function ppf_calc_jump(fx, fy, tx, ty, ai_data, jump_tries = 5) {
	
	var spd = abs(ai_data.SPEED);
	var jump = abs(ai_data.JUMP);
	var grav = abs(ai_data.GRAVITY);
	var w = ai_data.HITBOX_WIDTH;
	var h = ai_data.HITBOX_HEIGHT;
	
	jump_tries = max(jump_tries, 1);
	var jump_part = jump / jump_tries;
	var j = jump_part;
	
	var posx = fx;
	var posy = fy;
	var vspd = -j;
	var path = [];
	var maxy = fy;
	
	while(true) {
		
		while(posy < ty or vspd < 0) {
			array_push(path, [posx, posy]);
			vspd += grav;
			posx += spd;
			posy += vspd;
			maxy = min(maxy, posy);
			if vspd > 0 and maxy > ty break;
		}
		
		if posx > fx + abs(tx-fx) and maxy < ty {
			var col = false;
			var lastx = fx;
			var lasty = fy;
			
			for(var i = 0, len = array_length(path); i < len; i++) {
				path[i][0] *= ((tx - fx) / path[i][0]) * (i / len);
				path[i][0] += fx;
				
				if abs(path[i][0] - lastx) > w/2 
				or abs(path[i][1] - lasty) > h/2 or true {
					lastx = path[i][0];
					lasty = path[i][1];
					if collision_rectangle(path[i][0]-w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1, 
										   path[i][0]+w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1-h, 
										   ppf.SOLID_OBJ, false, true) {
						col = true;
						break;
					}
				}
			}
			if !col break;
		}
		
		j += jump_part;
		if j > jump return [];
		
		posx = fx;
		posy = fy;
		vspd = -j;
		path = [];
		maxy = fy;
	}
	
	return path;
}

function ppf_connect_nodes() {

	with(obj_node) {
		mid_x = x + ppf.CELL_SIZE/2;
		mid_y = y + ppf.CELL_SIZE/2;
		floor_id = collision_point(mid_x, mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, false, true);
	}
	
	foreach "aidata" in ppf.AI as_struct {
		
		var ai_name = fed.cs.key;
		var ai_data = aidata;
		if !ai_data.ACTIVE continue;
		
		// clear neighbours
		with(obj_node) {
			neig_data[$ ai_name] = [];
		}
		
		// loop through 
		with(obj_node) {
			with(obj_node) {
				if id != other.id {
				
					var connect = false;
					var action = ppf.STATE.WALK;
					var arr_path = [];
					
					// try walk
					if y == other.y {
						var ray = raycast(mid_x, mid_y, other.mid_x, other.mid_y, ppf.SOLID_OBJ, ppf.CELL_SIZE);
						if ray[0] == noone {
							if floor_id == other.floor_id
							or reversed_raycast(mid_x, mid_y+ppf.CELL_SIZE, other.mid_x, other.mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, ppf.CELL_SIZE) {
								connect = true;
								action = 0;
							}
						}
					}
					
					// try jump
					if !connect {
						var arr_path = ppf_calc_jump(mid_x, mid_y, other.mid_x, other.mid_y, ai_data, 10) {
							if array_length(arr_path) != 0 {
								connect = true;
								action = 1;
							}
						}
					}
					
					// add neighbour if connected
					if connect array_push(neig_data[$ ai_name], [other.id, action, arr_path]);
				}
			}
		}
	}
}

function ppf_find_path(from_x, from_y, to_x, to_y, ai_name) {
	
	if !instance_exists(obj_node) return [];
	
	var start_node = noone;
	var end_node = noone;
	var start_dist = 999999;
	var end_dist = 999999;
	
	// clear nodes
	with(obj_node) {
		
		visited = false;
		sc = 999999; // score
		prev_node = noone;
		
		var dist1 = point_distance(mid_x, mid_y, from_x, from_y);
		var dist2 = point_distance(mid_x, mid_y, to_x, to_y);
		
		if dist1 < start_dist {
			start_dist = dist1;
			start_node = id;
		}
		
		if dist2 < end_dist {
			end_dist = dist2;
			end_node = id;
		}
	}
	
	// start from this node
	with(start_node) {
		sc = 0;
	}
	
	// get node with lowest sc
	var lowest_score_node = function() {
		var node = noone;
		var lowest = 999999;
		with(obj_node) {
			if !visited and sc < lowest {
				lowest = sc;
				node = id; 
			}
		}
		return node;
	}
	
	// try to connect start node with end node
	while(true) {
		
		var node = lowest_score_node();
		if node == noone return [];
		else if node == end_node  break;

		node.visited = true;
		
		var neigs = node.neig_data[$ ai_name];
		for(var i = 0; i < array_length(neigs); i++) {
			
			var n = neigs[i][0];
			if n.visited continue;
			var curve = neigs[i][2];
			
			var dist = max(point_distance(n.mid_x, n.mid_y, node.mid_x, node.mid_y), array_length(curve));
			
			var new_score = node.sc + dist;
			if new_score < n.sc {
				n.sc = new_score;
				n.prev_node = node;
			}
		}
	}
	
	// extract the path
	var get_path = function(start_node, end_node, ai_name) {
		
		// reverse cuz it's from end to start
		var array_reverse = function(arr) {
			var new_arr = [];
			for(var l = 0, i = array_length(arr)-1; i > -1; i--) {
				new_arr[l++] = arr[i];
			}
			return new_arr;
		}
		
		// get data from node connected with the current one
		var get_prev_node_neighbour_data = function(node, ai_name) {
			if node.prev_node == noone return [node, 0, []];
			var prev_node_neig = node.prev_node.neig_data[$ ai_name];
			
			for(var i = 0; i < array_length(prev_node_neig); i++) {
				if prev_node_neig[i][0] == node return prev_node_neig[i];
			}
			return [node, 0, []];
		}
		
		// collect nodes and then return
		var path = [];
		var p = 0;
		var node = end_node;
		while(true) {
			path[p++] = get_prev_node_neighbour_data(node, ai_name);
			if node == start_node return array_reverse(path);
			node = node.prev_node;
		}
	}
	
	return get_path(start_node, end_node, ai_name);
}

#endregion

#region raycasts

// return if object is in the way
function raycast(x1, y1, x2, y2, obj, step, w = 0) {
	
	var len = point_distance(x1, y1, x2, y2);
	var rot = point_direction(x1, y1, x2, y2);
	var dcos_ = dcos(rot);
	var dsin_ = dsin(rot);
	
	var c = noone;
	for(var l = 0; l < len; l += step) {
	    var xx = x1+dcos_*l;
	    var yy = y1-dsin_*l;
		
		if !is_array(obj) {
			c = (w == 0 
				? collision_point(xx, yy, obj, false, true)
				: collision_rectangle(xx-w, yy-w, xx+w, yy+w, obj, false, true));
			if c != noone return [c, l, x2, y2];
		}
		else for(var i = 0; i < array_length(obj); i++) {
			c = (w == 0 
				? collision_point(xx, yy, obj[i], false, true)
				: collision_rectangle(xx-w, yy-w, xx+w, yy+w, obj[i], false, true));
			if c != noone return [c, l, x2, y2];
		}
	}

	return [noone, len, x2, y2];
}

// return if object is NOT in the way
function reversed_raycast(x1, y1, x2, y2, obj, step) {
	
	var len = point_distance(x1, y1, x2, y2);
	var rot = point_direction(x1, y1, x2, y2);
	var dcos_ = dcos(rot);
	var dsin_ = dsin(rot);
	
	for(var l = 0; l < len; l += step) {
	    var xx = x1+dcos_*l;
	    var yy = y1-dsin_*l;
		
	    if !collision_point(xx, yy, obj, false, true) return false;
	}

	return true;
}

#endregion
