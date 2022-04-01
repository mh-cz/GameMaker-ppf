draw_set_alpha(0.5);

if array_length(path) != 0 and ai_data.DEBUG_DRAW_AI_PATH {
	
	var path_draw = function(path, color, w) {
		draw_set_color(color);
		for(var i = 1; i < array_length(path); i++) {
			var prev_node = path[i-1][0];
			var node = path[i][0];
			var action = path[i][1];
			var curve = path[i][2];
			
			draw_circle(prev_node.mid_x, prev_node.mid_y, 3+w, false);
			
			if action == 1 and array_length(curve) != 0 {
				for(var c = 1; c < array_length(curve); c++) {
					draw_line_width(curve[c-1][0], curve[c-1][1], curve[c][0], curve[c][1], w);
				}
			}
			else draw_line_width(prev_node.mid_x, prev_node.mid_y, node.mid_x, node.mid_y, w);
			
			draw_circle(node.mid_x, node.mid_y, 3+w, false);
		}
	}
	
	//path_draw(path, c_black, 5);
	path_draw(path, ai_data.DEBUG_DRAW_COLOR, 5);
}
draw_set_alpha(1);

draw_self();
