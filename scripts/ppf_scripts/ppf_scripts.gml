function ppf_init() {
	
	globalvar ppf;
	ppf = {
		
		CELL_SIZE: 32,
		SOLID_OBJ: obj_solid,
		HIDE_NODES: true,
		DYNAMIC_CONNECTIONS: 4,
		
		AI: {
			Basic: {
				ACTIVE: true,
				HITBOX_WIDTH: 30,
				HITBOX_HEIGHT: 30,
				SPEED: 2,
				JUMP: 12,
				GRAVITY: 0.3,
				MAX_FALL_HEIGHT: 32 * 5,
				CAN_JUMP: true,
				WAIT_BEFORE_JUMP: room_speed * 0,
				WAIT_AFTER_LANDING: room_speed * 0,
				DEBUG_DRAW: true,
				DEBUG_DRAW_COLOR: c_orange,
				DEBUG_DRAW_AI_PATH: true,
			},
			
			Big_n_Slow: {
				ACTIVE: false,
				HITBOX_WIDTH: 44,
				HITBOX_HEIGHT: 44,
				SPEED: 3,
				JUMP: 14,
				GRAVITY: 0.6,
				MAX_FALL_HEIGHT: 32 * 5,
				CAN_JUMP: true,
				WAIT_BEFORE_JUMP: room_speed * 0.1,
				WAIT_AFTER_LANDING: room_speed * 0.2,
				DEBUG_DRAW: true,
				DEBUG_DRAW_COLOR: c_aqua,
				DEBUG_DRAW_AI_PATH: true,
			},
		},
		
		dyn_start_new_cycle: true,
		dyn_nodes: [],
		dyn_counter1: 0,
		dyn_counter2: 0,
		dyn_progress: 0,
		dyn_done: false,
		
		STATE: {
			WALK: 0,
			JUMP: 1,
		},
		
		calcj: {
			hspd: 0,
			vspd: 1,
		}
	};
}

function ppf_join_nodes(n1, n2, ai_data, ai_name) {
	
	with(n1) {
		with(n2) {
			
			// try walk
			if y == other.y {
				var ray = raycast(mid_x, mid_y, other.mid_x, other.mid_y, ppf.SOLID_OBJ, ppf.CELL_SIZE);
				if ray[0] == noone {
					if reversed_raycast(mid_x, mid_y+ppf.CELL_SIZE, other.mid_x, other.mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, ppf.CELL_SIZE) {
						array_push(neig_data[$ ai_name], [other.id, ppf.STATE.WALK, []]);
						return true;
					}
				}
			}
			
			// try jump
			var curve = ppf_calc_jump(mid_x, mid_y, other.mid_x, other.mid_y, ai_data, 30);
			if array_length(curve) != 0 {
				array_push(neig_data[$ ai_name], [other.id, ppf.STATE.JUMP, curve]);
				return true;
			}
			
			return false;
		}
	}
}

function ppf_calc_jump(fx, fy, tx, ty, ai_data) {
	
	var spd = abs(ai_data.SPEED);
	var jump = abs(ai_data.JUMP);
	var grav = abs(ai_data.GRAVITY);
	var w = ai_data.HITBOX_WIDTH;
	var h = ai_data.HITBOX_HEIGHT;
	
	//var path = [];
	//var paths = [];
	var events = [];
	
	var posx = fx;
	var posy = fy;
	var hspd = spd;
	var vspd = -jump * 4;
	var maxy = fy;
	var maxx = fx;
	
	var t = 0;
	
	// max jump dist check
	while(posy < ty or vspd < 0) {
		draw_circle(posx, posy, 2, false);
		vspd += grav;
		posx += spd;
		posy += vspd;
		maxy = min(maxy, posy);
		if vspd > 0 and maxy > ty return [];
	}
	if posx < fx + abs(tx-fx) return [];
	maxx = posx;
	var posx = fx;
	var posy = fy;
	var hspd = spd;
	var vspd = -jump * 4;
	var maxy = fy;
	var maxx = fx;
	
	var t = 0;
	
	// max jump dist check
	while(posy < ty or vspd < 0) {
		draw_circle(posx, posy, 4, true);
		vspd += grav * sqr(4) - grav;
		posx += spd * 4;
		posy += vspd;
		maxy = min(maxy, posy);
		if vspd > 0 and maxy > ty return [];
	}
	if posx < fx + abs(tx-fx) return [];
	maxx = posx;
	
	#region normal jump
	
	for(var j = jump * 0.5; j < jump+0.1; j++) {
		
		posx = fx;
		posy = fy;
		vspd = -j;
		hspd = spd;
		maxy = fy;
		
		var event = [];
		var col = false;
		t = 0;
		
		array_push(event, { POS: [posx, posy], VSPD: vspd, HSPD: hspd, T:t } );
		
		while((posy < ty or vspd < 0) and !(vspd > 0 and maxy > ty)) {
			vspd += grav;
			posx += hspd;
			posy += vspd;
			maxy = min(maxy, posy);
		}
		
		array_push(event, { POS: [posx, posy], VSPD: vspd, HSPD: hspd, T:t } );
		
		if posx > fx + abs(tx-fx) and maxy < ty {
			
			var lastx = fx;
			var lasty = fy;
			
			for(var i = 0, len = array_length(path); i < len; i++) {
				
				path[i][0] = fx + (tx - fx) * (i / len);
				
				if abs(path[i][0] - lastx) > w/2
				or abs(path[i][1] - lasty) > h/2 {
					lastx = path[i][0];
					lasty = path[i][1];
					
					//draw_rectangle(path[i][0]-w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1, path[i][0]+w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1-h, true);
					
					if collision_rectangle(path[i][0]-w/2, path[i][1]+(ppf.CELL_SIZE/2)-1, 
											path[i][0]+w/2, path[i][1]+(ppf.CELL_SIZE/2)-1-h, 
											ppf.SOLID_OBJ, false, true) {
						col = true;
						break;
					}
				}
			}
			
			if !col {
				array_push(paths, path);
				break;
			}
		}
	}
	
	#endregion
	
	#region tight space jump
	
	for(var jy = ppf.CELL_SIZE * ((fy-ty)/ppf.CELL_SIZE); jy > -1; jy -= ppf.CELL_SIZE) {
		
		for(var j = jump * 0.5; j < jump+0.1; j++) {
			
			posx = fx;
			posy = fy;
			vspd = -j;
			hspd = 0;
			maxy = fy;
			
			path = [];
			col = false;
			
			var curve_start = -1;
			var frame_counter = 0;
			
			while((posy < ty or vspd < 0) and !(vspd > 0 and maxy > ty)) {
				
				array_push(path, [posx, posy]);
				
				if posy < (fy-jy)+1 and curve_start == -1 {
					hspd = spd;
					curve_start = frame_counter;
				}
				frame_counter++;
				
				vspd += grav;
				posx += hspd;
				posy += vspd;
				maxy = min(maxy, posy);
			}
			
			if posx > fx + abs(tx-fx) and maxy < ty {
				
				var lastx = fx;
				var lasty = fy;
				
				for(var i = 0, len = array_length(path); i < len; i++) {
					
					if i >= curve_start {
						path[i][0] = fx + (tx - fx) * ((i-curve_start) / (len-curve_start));
					}
					
					//draw_circle(path[i][0], path[i][1], 2, false);
					
					if abs(path[i][0] - lastx) > w/2
					or abs(path[i][1] - lasty) > h/2 {
						lastx = path[i][0];
						lasty = path[i][1];
						
						//draw_rectangle(path[i][0]-w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1, path[i][0]+w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1-h, true);
					
						if collision_rectangle(path[i][0]-w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1, 
											   path[i][0]+w/2, path[i][1]+(ppf.CELL_SIZE div 2)-1-h, 
											   ppf.SOLID_OBJ, false, true) {
							col = true;
							break;
						}
					}
				}
				
				if !col {
					array_push(paths, path);
					break;
				}
			}
		}
	}
	
	#endregion
	
	var lowest = infinity;
	var len = array_length(paths);
	var lpath = [];
	for(var i = 0; i < len; i++) {
		var l = array_length(paths[i]);
		if l < lowest {
			lowest = l;
			lpath = paths[i];
		}
	}
	
	return lpath;
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
			
			var dist = max(point_distance(n.mid_x, n.mid_y, node.mid_x, node.mid_y), array_length(curve)) * 0.1;
			
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

function ppf_calc_jump2(fx, fy, tx, ty, ai_data) {
	
	var spd = abs(ai_data.SPEED);
	var jump = abs(mouse_x * 0.1);
	var grav = abs(ai_data.GRAVITY);
	
	var posx = fx;
	var posy = fy;
	var hspd = spd;
	var vspd = -jump;
	
	while(posy < ty or vspd < 0) {
		draw_circle(posx, posy, 2, false);
		vspd += grav;
		posx += spd;
		posy += vspd;
	}
	
	var speedup = 5;
	
	var posx = fx;
	var posy = fy;
	var hspd = spd;
	var vspd = -jump
	
	while(posy < ty or vspd < 0) {
		draw_circle(posx, posy, 5, true);
		repeat(speedup) {
			vspd += grav;
			posx += spd;
			posy += vspd;
		}
	}
}
