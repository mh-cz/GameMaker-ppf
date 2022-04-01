if ai_data == 0 ai_data = ppf.AI[$ ai_name];

on_ground = vspd >= 0 and place_meeting(x, y+1, ppf.SOLID_OBJ);

if !on_ground vspd += ai_data.GRAVITY;

if place_meeting(x+hspd, y, ppf.SOLID_OBJ) repeat(ceil(abs(hspd))) {
	if !place_meeting(x+sign(hspd), y, ppf.SOLID_OBJ) x += sign(hspd);
	else {
		hspd = 0;
		break;
	}
}
x += hspd;

if place_meeting(x, y+vspd, ppf.SOLID_OBJ) repeat(ceil(abs(vspd))) {
	if !place_meeting(x, y+sign(vspd), ppf.SOLID_OBJ) y += sign(vspd);
	else {
		vspd = 0;
		break;
	}
}
y += vspd;

// AI

var next_node = function() {
	
	wait = 0;
	jumped = false;
	hspd = 0;
	vspd = 0;
	continous_hspd = 0;
	
	if ++path_pos == array_length(path) {
		path = [];
		action = -1;
	}
	else {
		if action == ppf.STATE.JUMP wait += ai_data.WAIT_AFTER_LANDING;
		
		node = path[path_pos][0];
		action = path[path_pos][1];
		curve = path[path_pos][2];
		
		if path_pos+1 < array_length(path) {
			var next_node = path[path_pos+1][0];
			var next_action = path[path_pos+1][1];
			var next_curve = path[path_pos+1][2];
			
			if action == ppf.STATE.WALK and next_action == ppf.STATE.WALK {
				if sign(node.mid_x - x) != sign(next_node.mid_x - x) {
					path_pos++;
					node = next_node;
					action = next_action;
					curve = next_curve;
				}
			}
		}
		
		if action == ppf.STATE.JUMP wait += ai_data.WAIT_BEFORE_JUMP;
	}
}

if mouse_check_button_pressed(mb_left) {
	path = ppf_find_path(x, y, mouse_x, mouse_y, ai_name);
	path_pos = -1;
	next_node();
}

if array_length(path) != 0 {
	
	if --wait < 0 switch(action) {
		case ppf.STATE.WALK:
			
			hspd = ai_data.SPEED * sign(node.mid_x - x);
			
			if point_distance(x, y, node.mid_x, node.mid_y) <= ai_data.SPEED {
				x = node.mid_x;
				y = node.mid_y;
				next_node();
			}
			
			break;
		
		case ppf.STATE.JUMP:
		
			if array_length(curve) < 2 {
				next_node();
				break;
			}
			
			if on_ground and !jumped {
				jumped = true;
				
				var p1x = curve[1][0];
				var p1y = curve[1][1];
				var pdr = point_direction(x, y, p1x, p1y);
				var pds = point_distance(x, y, p1x, p1y);
				
				continous_hspd = lengthdir_x(pds, pdr);
				vspd = lengthdir_y(pds, pdr) - ai_data.GRAVITY;
			}
			
			if continous_hspd != 0 hspd = continous_hspd;
			
			if y < node.y+ppf.CELL_SIZE and abs(x - node.mid_x) <= abs(continous_hspd) {
				hspd = (node.mid_x - x) * 0.25;
			}
			
			if point_distance(x, y, node.mid_x, node.mid_y) <= abs(continous_hspd) {
				x = node.mid_x;
				y = node.mid_y;
				next_node();
			}
			
			break;
	}
}
