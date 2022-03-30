draw_set_alpha(0.15);

with(obj_node) {
	
	var yoff = 0;
	var xoff = 0;
	visible = !ppf.HIDE_NODES;
	
	foreach "ai_data" in ppf.AI as_struct {
		
		//var path = ppf_calc_jump(mid_x, mid_y, mouse_x, mouse_y, ai_data, 10);
		//for(var i = 0; i < array_length(path); i++) draw_circle(path[i][0], path[i][1], 2, true);
		
		var neigs = neig_data[$ fed.cs.key];
		if !ai_data.DEBUG_DRAW continue;
		draw_set_color(ai_data.DEBUG_DRAW_COLOR);
		
		for(var i = 0; i < array_length(neigs); i++) {
		
			var n = neigs[i][0];
			var action = neigs[i][1];
			var curve = neigs[i][2];
			
			if action == 0 {
				draw_line_width(mid_x+xoff, mid_y+yoff, n.mid_x+xoff, n.mid_y+yoff, 2);
			}
			else if action == 1 {
				for(var c = 1; c < array_length(curve); c++) {
					draw_line_width(curve[c-1][0]+xoff, curve[c-1][1]+yoff, curve[c][0]+xoff, curve[c][1]+yoff, 2);
				}
			}
		}
		
		yoff -= 3;
		xoff -= 3;
	}
}
draw_set_alpha(1);
draw_set_color(c_white);

if keyboard_check_pressed(ord("R")) room_restart();
