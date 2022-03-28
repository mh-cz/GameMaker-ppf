if !is_struct(ai_data) ai_data = ppf_data.AI[$ ai_name];

if mouse_check_button_pressed(mb_left) {
	path = ppf_find_path(x, y, mouse_x, mouse_y, ai_name);
	path_pos = -1;
}

if array_length(path) != 0 {
	
	var next_path_point = function() {
		if ++path_pos > array_length(path)-1 {
			path = [];
			action = -1;
		}
		else {
			wait = 0;
			if action == ppf_data.STATE.JUMP wait += ai_data.WAIT_AFTER_LANDING;
			node = path[path_pos][0];
			action = path[path_pos][1];
			curve = path[path_pos][2];
			curve_pos = 0;
			if action == ppf_data.STATE.JUMP wait += ai_data.WAIT_BEFORE_JUMP;
		}	
	}
	
	if path_pos == -1 {
		next_path_point();
	}
	
	if --wait < 0 switch(action) {
		case 0:
			
			var pdr = point_direction(xx, yy, node.mx, node.my);
			var pds = point_distance(xx, yy, node.mx, node.my);
	
			xx += lengthdir_x(ai_data.SPEED, pdr);
			yy += lengthdir_y(ai_data.SPEED, pdr);
		
			if pds < ai_data.SPEED {
				xx = node.mx;
				yy = node.my;
				next_path_point();
			}
			
			break;
			
		case 1:
			if array_length(curve) == 0 break;

			if curve_pos == array_length(curve) {
				xx = node.mx;
				yy = node.my;
				next_path_point();
			}
			else {
				xx = curve[curve_pos][0];
				yy = curve[curve_pos][1];
				curve_pos++;
			}
			
			break;
	}

}

x = xx + x_offset;
y = yy + y_offset;

if array_length(path) != 0 and ai_data.DRAW {
	
	var path_draw = function(path, color, w) {
		draw_set_color(color);
		for(var i = 1; i < array_length(path); i++) {
			var prev_node = path[i-1][0];
			var node = path[i][0];
			var action = path[i][1];
			var curve = path[i][2];
			
			draw_circle(prev_node.mx, prev_node.my, 3+w, false);
			
			if action == 1 and array_length(curve) != 0 {
				for(var c = 1; c < array_length(curve); c++) {
					draw_line_width(curve[c-1][0], curve[c-1][1], curve[c][0], curve[c][1], w);
				}
			}
			else draw_line_width(prev_node.mx, prev_node.my, node.mx, node.my, w);
		}
	}
	
	path_draw(path, c_black, 5);
	path_draw(path, c_white, 3);
}

draw_self();
