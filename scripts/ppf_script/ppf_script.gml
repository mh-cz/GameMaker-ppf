globalvar ppf; ppf = {
	
	ENABLED: true,
	CELL_SIZE: 32,
	SOLID_OBJ: obj_solid,
	HIDE_NODES: true,
	MAX_GEN_CONN: 20,
	JUMP_PRECISION: 1,
	
	AI: {
		Basic: {
			ENABLED: true,
			HITBOX_WIDTH: 30,
			HITBOX_HEIGHT: 30,
			SPEED: 3,
			JUMP: 9,
			GRAVITY: 0.3,
			MAX_FALL_HEIGHT: 32 * 7,
			CAN_JUMP: true,
			WAIT_BEFORE_JUMP: room_speed * 0,
			WAIT_AFTER_LANDING: room_speed * 0,
			DEBUG: {
				DRAW_PATHS: true,
				DRAW_PATHS_AFTER_GEN_DONE: false,
				DRAW_PATHS_COLOR: c_orange,
				DRAW_AI_PATH: true,
				DRAW_AI_PATH_COLOR: c_orange,
			},
		},
		Speedy: {
			ENABLED: true,
			HITBOX_WIDTH: 30,
			HITBOX_HEIGHT: 30,
			SPEED: 5,
			JUMP: 12,
			GRAVITY: 0.3,
			MAX_FALL_HEIGHT: 32 * 7,
			CAN_JUMP: true,
			WAIT_BEFORE_JUMP: room_speed * 0,
			WAIT_AFTER_LANDING: room_speed * 0,
			DEBUG: {
				DRAW_PATHS: true,
				DRAW_PATHS_AFTER_GEN_DONE: false,
				DRAW_PATHS_COLOR: c_aqua,
				DRAW_AI_PATH: true,
				DRAW_AI_PATH_COLOR: c_aqua,
			},
		},
	},
	
	gen_start_new_cycle: false,
	gen_nodes: [],
	gen_counter1: 0,
	gen_counter2: 0,
	gen_progress: 0,
	gen_done: -1,
}

function ppf_join_nodes(n1, n2, ai_data, ai_name) {
	
	with(n1) {
		with(n2) {
			
			// try walk
			if y == other.y {
				var ray = raycast(mid_x, mid_y, other.mid_x, other.mid_y, ppf.SOLID_OBJ, ppf.CELL_SIZE);
				if ray[0] == noone {
					if reversed_raycast(mid_x, mid_y+ppf.CELL_SIZE, other.mid_x, other.mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, ppf.CELL_SIZE) {
						array_push(neig_data[$ ai_name], [other.id, [new ppf_move_event(mid_x, mid_y, 0, ai_data.SPEED * sign(other.mid_x - mid_x), other.mid_x, other.mid_y)]]);
						return true;
					}
				}
			}
			
			// try jump
			var events = ppf_calc_jump(mid_x, mid_y, other.mid_x, other.mid_y, ai_data);
			if array_length(events) != 0 {
				array_push(neig_data[$ ai_name], [other.id, events]);
				return true;
			}
			
			return false;
		}
	}
}

function ppf_move_event(x, y, vspd, hspd, next_x = -1, next_y = -1) constructor {
	self.x = x;
	self.y = y;
	self.vspd = vspd;
	self.hspd = hspd;
	self.next_x = next_x;
	self.next_y = next_y;
}

/*
var yoff = fy - ty;
var ynum = sqr(jump) - 2 * grav * yoff;
if ynum < 4 return 0; // too high
var t = (jump + sqrt(ynum)) / grav;
var hdiff = (tx - fx) / (t * spd);
if abs(hdiff) > 1 return 0; // too far
*/

function ppf_calc_jump(fx, fy, tx, ty, ai_data, specific_jump = -1) {
	
	var shortest_jump = [];
	var shortest_time = infinity;
	
	var normal_jump = function(fx, fy, tx, ty, ai_data, shortest_time) {
		
		var spd = ai_data.SPEED;
		var jump = ai_data.JUMP;
		var grav = ai_data.GRAVITY;
		var htb_w = ai_data.HITBOX_WIDTH;
		var htb_h = ai_data.HITBOX_HEIGHT;
		var max_jump_h = sqr(jump) / (2 * grav);
		var max_fall = ai_data.MAX_FALL_HEIGHT;
		var cell_size = ppf.CELL_SIZE;
		
		var shortest_jump = [];
	
		if fy < ty and abs(fy - ty) > max_fall return [[], infinity];
		
		var jh = 0.5;
		var j = 0;
		
		while(cell_size * jh < max_jump_h and j != jump) {
		
			j = sqrt(2 * grav * cell_size * jh);
			if j > jump j = jump;
			jh += ppf.JUMP_PRECISION;
		
			var events = [];
			var col = false;
		
			var yoff = fy - ty;
			var yh = sqr(j) - 2 * grav * yoff;
			if yh < 4 continue; // target too high
			var t = (j + sqrt(yh)) / grav;
			if t >= shortest_time continue; // shorter exists
			var hdiff = (tx - fx) / (t * spd);
			if abs(hdiff) > 1 continue; // target too far
		
			var posx = fx;
			var posy = fy;
			var hspd = spd * hdiff;
			var vspd = -j - 0.1;
		
			var lastx = fx;
			var lasty = fy;
		
			array_push(events, new ppf_move_event(posx, posy, vspd, hspd));
		
			while(posy < ty or vspd < 0) {
			
				draw_point(round(posx), round(posy));
			
				if abs(posx - lastx) > htb_w * 0.65 or abs(posy - lasty) > htb_h*2 + abs(vspd/2) {
					lastx = posx;
					lasty = posy;
					
					var left = lastx-htb_w/2;
					var right = lastx+htb_w/2;
					var up = max(fy - max_jump_h + cell_size/2 - htb_h, lasty+cell_size/2-htb_h*1.25-abs(vspd*4));
					var down = min((vspd < 0 ? fy : ty) + cell_size*0.25, lasty+cell_size/2+htb_h*0.25+abs(vspd*4));
				
					draw_set_color(c_yellow);
					draw_set_alpha(0.4);
					draw_rectangle(left, up, right, down, true);
					draw_set_color(c_white);
					draw_set_alpha(1);
				
					col = collision_rectangle(left, up, right, down, ppf.SOLID_OBJ, false, true);		
					if col break;
				}
				vspd += grav;
				posy += vspd;
				posx += hspd;
			}
		
			if !col {
				//array_push(events, new ppf_move_event(tx, ty, 0, 0, 0));
				var prev_ev = events[array_length(events)-1];
				prev_ev.next_x = tx;
				prev_ev.next_y = ty;
				shortest_time = t;
				shortest_jump = events;
				break;
			}
		}
		
		return [shortest_jump, shortest_time];
	}
	
	var tight_space_jump_up = function(fx, fy, tx, ty, ai_data, shortest_time) {
		
		var spd = ai_data.SPEED;
		var jump = ai_data.JUMP;
		var grav = ai_data.GRAVITY;
		var htb_w = ai_data.HITBOX_WIDTH;
		var htb_h = ai_data.HITBOX_HEIGHT;
		var max_jump_h = sqr(jump) / (2 * grav);
		var max_fall = ai_data.MAX_FALL_HEIGHT;
		var cell_size = ppf.CELL_SIZE;
		
		var shortest_jump = [];
	
		if fy < ty and abs(fy - ty) > max_fall return [[], infinity];
	
		var elevated_h = 0;
		while(elevated_h < max_jump_h) {
	
			elevated_h += cell_size;
			var jh = 0.5 + elevated_h / cell_size;
			var j = 0;
			var col = false;
	
			while(cell_size * jh < max_jump_h and j != jump) {
		
				var ej = sqrt(2 * grav * (cell_size * jh - elevated_h));
				j = sqrt(2 * grav * cell_size * jh);
				if j > jump j = jump;
				jh += ppf.JUMP_PRECISION;
		
				var events = [];
				var col = false;
		
				var yoff = (fy-elevated_h) - ty;
				var yh = sqr(ej) - 2 * grav * yoff;
				if yh < 4 continue; // target too high
				var t = (ej + sqrt(yh)) / grav;
				if t + elevated_h >= shortest_time continue; // shorter exists
				var hdiff = (tx - fx) / (t * spd);
				if abs(hdiff) > 1 continue; // target too far
		
				var posx = fx;
				var posy = fy;
				var hspd = spd * hdiff;
				var vspd = -j;
		
				var lastx = posx;
				var lasty = posy;
				var state = 0;
			
				array_push(events, new ppf_move_event(posx, posy, vspd, 0));
			
				while(posy < ty or vspd < 0) {
			
					//draw_point(round(posx), round(posy));
			
					if (abs(posx - lastx) > htb_w * 0.65 or abs(posy - lasty) > htb_h*2 + abs(vspd/2)) {
						lastx = posx;
						lasty = posy;
					
						var left = lastx-htb_w/2;
						var right = lastx+htb_w/2;
						var up = max(fy - max_jump_h + cell_size/2 - htb_h, lasty+cell_size/2-htb_h*1.25-abs(vspd*4));
						var down = min((vspd < 0 ? fy : ty) + cell_size*0.25, lasty+cell_size/2+htb_h*0.25+abs(vspd*4));
				
						/*draw_set_color(c_yellow);
						draw_set_alpha(0.4);
						draw_rectangle(left, up, right, down, true);
						draw_set_color(c_white);
						draw_set_alpha(1);*/
				
						col = collision_rectangle(left, up, right, down, ppf.SOLID_OBJ, false, true);	
						if col break;
					}
					if state == 0 {
						vspd += grav;
						posy += vspd;
						if posy <= fy-elevated_h {
							state++;
							
							var prev_ev = events[array_length(events)-1];
							prev_ev.next_x = posx;
							prev_ev.next_y = posy;
							array_push(events, new ppf_move_event(posx, posy, vspd, hspd));
						}
					}
					else if state == 1 {
						vspd += grav;
						posy += vspd;
						posx += hspd;
					}
				}
		
				if !col {
					var prev_ev = events[array_length(events)-1];
					prev_ev.next_x = tx;
					prev_ev.next_y = ty;
					shortest_time = t + elevated_h;
					shortest_jump = events;
					break;
				}
			}
			if !col break;
		}
		
		return [shortest_jump, shortest_time];
	}
	
	var tight_space_jump_down = function(fx, fy, tx, ty, ai_data, shortest_time) {
		
		var spd = ai_data.SPEED;
		var jump = ai_data.JUMP;
		var grav = ai_data.GRAVITY;
		var htb_w = ai_data.HITBOX_WIDTH;
		var htb_h = ai_data.HITBOX_HEIGHT;
		var max_jump_h = sqr(jump) / (2 * grav);
		var max_fall = ai_data.MAX_FALL_HEIGHT;
		var cell_size = ppf.CELL_SIZE;
		
		var shortest_jump = [];
		
		if fy < ty and abs(fy - ty) > max_fall return [[], infinity];
	
		var elevated_h = 0;
		while(elevated_h < max_fall) {
	
			elevated_h += cell_size;
			var jh = 0.5
			var j = 0;
			var col = false;
	
			while(cell_size * jh < max_jump_h and j != jump) {
		
				j = sqrt(2 * grav * cell_size * jh);
				if j > jump j = jump;
				jh += ppf.JUMP_PRECISION;
		
				var events = [];
				var col = false;
		
				var yoff = fy - (ty-elevated_h);
				var yh = sqr(j) - 2 * grav * yoff;
				if yh < 4 continue; // target too high
				var t = (j + sqrt(yh)) / grav;
				if t + elevated_h >= shortest_time continue; // shorter exists
				var hdiff = (tx - fx) / (t * spd);
				if abs(hdiff) > 1 continue; // target too far
				
				var posx = fx;
				var posy = fy;
				var hspd = spd * hdiff;
				var vspd = -j;
				
				var lastx = posx;
				var lasty = posy;
				var state = 0;
			
				array_push(events, new ppf_move_event(posx, posy, vspd, hspd));
			
				while(posy < ty or vspd < 0) {
			
					//draw_point(round(posx), round(posy));
			
					if abs(posx - lastx) > htb_w * 0.65 or abs(posy - lasty) > htb_h*2 + abs(vspd/2) {
						lastx = posx;
						lasty = posy;
					
						var left = lastx-htb_w/2;
						var right = lastx+htb_w/2;
						var up = max(fy - max_jump_h + cell_size/2 - htb_h, lasty+cell_size/2-htb_h*1.25-abs(vspd*4));
						var down = min((vspd < 0 ? fy : ty) + cell_size*0.25, lasty+cell_size/2+htb_h*0.25+abs(vspd*4));
				
						/*draw_set_color(c_yellow);
						draw_set_alpha(0.4);
						draw_rectangle(left, up, right, down, true);
						draw_set_color(c_white);
						draw_set_alpha(1);*/
				
						col = collision_rectangle(left, up, right, down, ppf.SOLID_OBJ, false, true);	
						if col break;
					}
					if state == 0 {
						vspd += grav;
						posy += vspd;
						posx += hspd;
						if abs(posx - tx) < abs(hspd) {
							state++;
							posx = tx;
							
							var prev_ev = events[array_length(events)-1];
							prev_ev.next_x = posx;
							prev_ev.next_y = posy;
							array_push(events, new ppf_move_event(posx, posy, vspd, 0));
						}
					}
					else if state == 1 {
						vspd += grav;
						posy += vspd;
					}
				}
		
				if !col {
					var prev_ev = events[array_length(events)-1];
					prev_ev.next_x = tx;
					prev_ev.next_y = ty;
					shortest_time = t + elevated_h;
					shortest_jump = events;
					break;
				}
			}
			if !col break;
		}
		
		return [shortest_jump, shortest_time];
	}
	
	if specific_jump == -1 {
		
		var jmp = normal_jump(fx, fy, tx, ty, ai_data, shortest_time);
		if jmp[1] < shortest_time {
			shortest_jump = jmp[0];
			shortest_time = jmp[1];
		}
	
		if fy > ty {
			var jmp = tight_space_jump_up(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}
			var jmp = tight_space_jump_down(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}
		}
		else {
			var jmp = tight_space_jump_down(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}
			var jmp = tight_space_jump_up(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}	
		}
	}
	else {
		if specific_jump == 0 {
			var jmp = normal_jump(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}	
		}
		else if specific_jump == 1 {
			var jmp = tight_space_jump_up(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}	
		}
		else if specific_jump == 2 {
			var jmp = tight_space_jump_down(fx, fy, tx, ty, ai_data, shortest_time);
			if jmp[1] < shortest_time {
				shortest_jump = jmp[0];
				shortest_time = jmp[1];
			}	
		}
	}
	
	return shortest_jump;
}

function ppf_find_path(from_x, from_y, to_x, to_y, ai_name) {
	
	if !instance_exists(obj_node) return [];
	
	var start_node = noone;
	var end_node = noone;
	var start_dist = infinity;
	var end_dist = infinity;
	
	// clear nodes
	with(obj_node) {
		
		visited = false;
		sc = infinity; // score
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
	start_node.sc = 0;
	
	// get node with lowest sc
	var lowest_score_node = function() {
		var node = noone;
		var lowest = infinity;
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
		else if node == end_node break;

		node.visited = true;
		
		var neigs = node.neig_data[$ ai_name];
		for(var i = 0; i < array_length(neigs); i++) {
			
			var n = neigs[i][0];
			if n.visited continue;
			
			var dist = point_distance(n.mid_x, n.mid_y, node.mid_x, node.mid_y);
			
			var new_score = node.sc + dist;
			if new_score < n.sc {
				n.sc = new_score;
				n.prev_node = node;
			}
		}
	}
	
	// get the path
	var get_path = function(start_node, end_node, ai_name) {
		
		// reverse cuz it's from end to start
		var array_reverse = function(arr) {
			var new_arr = [];
			for(var i = array_length(arr)-1; i > -1; i--) array_push(new_arr, arr[i]);
			return new_arr;
		}
		
		// get data from node connected with the current one
		var get_prev_node_neighbour_data = function(node, ai_name) {
			if node.prev_node == noone return [node, []];
			var prev_node_neig = node.prev_node.neig_data[$ ai_name];
			for(var i = 0; i < array_length(prev_node_neig); i++) {
				if prev_node_neig[i][0] == node return prev_node_neig[i];
			}
			return [node, []];
		}
		
		// collect nodes and then return
		var path = [];
		var node = end_node;
		while(true) {
			array_push(path, get_prev_node_neighbour_data(node, ai_name));
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
	var cs = dcos(rot);
	var sn = dsin(rot);
	
	var c = noone;
	for(var l = 0; l < len; l += step) {
	    var xx = x1+cs*l;
	    var yy = y1-sn*l;
		draw_circle(xx, yy, 2, false);
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
	var cs = dcos(rot);
	var sn = dsin(rot);
	
	for(var l = 0; l < len; l += step) {
	    if !collision_point(x1+cs*l, y1-sn*l, obj, false, true) return false;
	}

	return true;
}

#endregion
