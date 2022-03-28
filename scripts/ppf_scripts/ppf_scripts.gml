function ppf_init() {
	
	globalvar ppf_data;
	ppf_data = {
	
		STATE: {
			WALK: 0,
			JUMP: 1,
		},
		
		AI: {
			Basic: {
				HITBOX_WIDTH: 24,
				HITBOX_HEIGHT: 24,
				SPEED: 3,
				JUMP: 10,
				GRAVITY: 0.3,
				MAX_FALL_HEIGHT: 32 * 5,
				CAN_JUMP: true,
				DRAW: true,
				COLOR: c_lime,
				ACTIVE: true,
				WAIT_BEFORE_JUMP: 0.05 * room_speed,
				WAIT_AFTER_LANDING: 0.1 * room_speed,
			},
		
			Big_n_Slow: {
				HITBOX_WIDTH: 24,
				HITBOX_HEIGHT: 24,
				SPEED: 1.5,
				JUMP: 5,
				GRAVITY: 0.3,
				MAX_FALL_HEIGHT: 32 * 4,
				CAN_JUMP: true,
				DRAW: false,
				COLOR: c_orange,
				ACTIVE: false,
				WAIT_BEFORE_JUMP: 0.2,
				WAIT_AFTER_LANDING: 0.3,
			},
		},
	};
}

#region PPF

function ppf_calc_jump(fx, fy, tx, ty, ai_data, test_jump_tries = 5) {
	
	var spd = abs(ai_data.SPEED);
	var jump = abs(ai_data.JUMP);
	var grav = abs(ai_data.GRAVITY);
	var w = ai_data.HITBOX_WIDTH;
	var h = ai_data.HITBOX_HEIGHT;
	
	test_jump_tries = max(test_jump_tries, 1);
	var jump_part = jump / test_jump_tries;
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
			for(var i = 0, len = array_length(path); i < len; i++) {
				path[i][0] *= ((tx - fx) / path[i][0]) * (i / len);
				path[i][0] += fx;
				if collision_rectangle(path[i][0]-w/2, path[i][1]-h/2, path[i][0]+w/2, path[i][1]+h/2, obj_solid, false, true) {
					col = true;
					break;
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
		mx = x + 16;
		my = y + 16;
		floor_id = collision_point(mx, my+32, obj_solid, false, true);
	}
	
	foreach "aidata" in ppf_data.AI as_struct {
		
		var ai_name = fed.cs.key;
		var ai_data = aidata;
		
		if !ai_data.ACTIVE continue;
		
		with(obj_node) {
			neig_data[$ ai_name] = [];
		}
		
		with(obj_node) {
			with(obj_node) {
				if id != other.id {
				
					var connect = false;
					var action = 0; // 0 walk, 1 jump
					var arr_path = [];
					
					if y == other.y {
					
						var ray = raycast(mx, my, other.mx, other.my, obj_solid, 32, 0);
						if ray[0] == noone {
				
							if floor_id == other.floor_id or reversed_raycast(mx, my+32, other.mx, other.my+32, obj_solid, 32) {
								connect = true;
								action = 0;
							}
						}
					}
					
					if !connect {
				
						var fromx = my - other.my < 0 ? mx + sign(other.x - x) * 16 : mx;
						var fromy = my;
						var tox = my - other.my > 0 ? other.mx + sign(x - other.x) * 16 : other.mx;
						var toy = other.my;
					
						var ray = raycast(fromx, fromy, tox, toy, obj_solid, 16, 0);
						if ray[0] == noone {
							var arr_path = ppf_calc_jump(mx, my, other.mx, other.my, ai_data, 10) {
								if array_length(arr_path) != 0 {
									connect = true;
									action = 1;
								}
							}
						}
					}
				
					if connect array_push(neig_data[$ ai_name], [other.id, action, arr_path]);
				}
			}
		}
	}
}

function ppf_find_path(from_x, from_y, to_x, to_y, name) {
	
	if !instance_exists(obj_node) return [];
	
	var start_node = noone;
	var end_node = noone;
	var start_dist = 999999;
	var end_dist = 999999;
	
	with(obj_node) {
		
		visited = false;
		sc = 999999;
		prev_node = noone;
		
		var dist1 = point_distance(x+16, y+16, from_x, from_y);
		var dist2 = point_distance(x+16, y+16, to_x, to_y);
		
		if dist1 < start_dist {
			start_dist = dist1;
			start_node = id;
		}
		
		if dist2 < end_dist {
			end_dist = dist2;
			end_node = id;
		}
	}
	
	with(start_node) {
		sc = 0;
	}
	
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

	while(true) {
		
		var node = lowest_score_node();
		
		if node == noone return [];
		else if node == end_node  break;

		node.visited = true;
		
		var neig = variable_struct_get(node.neig_data, name);
		for(var i = 0; i < array_length(neig); i++) {
			
			var n = neig[i][0];
			if n.visited continue;
			
			var pds = point_distance(n.x, n.y, node.x, node.y) * 0.1;
			if n.y != node.y pds *= 2;
			
			var new_score = node.sc + pds;
			if new_score < n.sc {
				n.sc = new_score;
				n.prev_node = node;
			}
		}
	}

	var get_path = function(start_node, end_node, name) {
		
		var array_reverse = function(arr) {
			var new_arr = [];
			var l = 0;
			for(var i = array_length(arr)-1; i > -1; i--) {
				new_arr[l++] = arr[i];
			}
			return new_arr;
		}
		
		var get_prev_node_neighbour_data = function(node, name) {
			if node.prev_node == noone return [node, 0, []];
			var prev_node_neig = node.prev_node.neig_data[$ name];
			
			for(var i = 0; i < array_length(prev_node_neig); i++) {
				if prev_node_neig[i][0] == node return prev_node_neig[i];
			}
			return [node, 0, []];
		}
		
		var path = [];
		var p = 0;
		
		var node = end_node;
		while(true) {
			path[p++] = get_prev_node_neighbour_data(node, name);
			if node == start_node return array_reverse(path);
			node = node.prev_node;
		}
	}
	
	return get_path(start_node, end_node, name);
}

#endregion

#region raycasts

// return if object is in the way
function raycast(x1, y1, x2, y2, obj, step, w) {
	
	var len = point_distance(x1, y1, x2, y2);
	var rot = point_direction(x1, y1, x2, y2);
	var c = noone;
	var dcos_ = dcos(rot);
	var dsin_ = dsin(rot);
	
	for(var l = 0; l < len; l += step) {
	    var xx = x1+dcos_*l;
	    var yy = y1-dsin_*l;
		
	    if w == 0 c = collision_point(xx, yy, obj, false, true);
		else c = collision_rectangle(xx-w, yy-w, xx+w, yy+w, obj, false, true);
	    if c != noone return [c, l, x2, y2];
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
