draw_set_color(c_white);

with(obj_node) {
	foreach "ai_data" in ppf.AI as_struct {
		if !ai_data.ACTIVE or !ai_data.DEBUG_DRAW continue;
		draw_set_alpha(0.2);
		var events = ppf_calc_jump(mid_x, mid_y, floor(mouse_x/ppf.CELL_SIZE)*ppf.CELL_SIZE+ppf.CELL_SIZE/2, floor(mouse_y/ppf.CELL_SIZE)*ppf.CELL_SIZE+ppf.CELL_SIZE/2, ai_data);
		//var events = ppf_calc_jump(mid_x, mid_y, mouse_x, mouse_y, ai_data);
		
		draw_set_alpha(1);
		//for(var i = 0; i < array_length(events); i++) draw_circle(events[i].px, events[i].py, 2, false);
		for(var i = 0; i < array_length(events); i++) draw_circle(events[i][0], events[i][1], 2, false);
	}
}

draw_set_alpha(0.25);

with(obj_node) {
	
	var yoff = 0;
	var xoff = 0;
	visible = !ppf.HIDE_NODES;
	
	foreach "ai_data" in ppf.AI as_struct {
		
		if !ai_data.ACTIVE or !ai_data.DEBUG_DRAW continue;
		
		var neigs = neig_data[$ fed.cs.key];
		
		draw_set_color(ppf.dyn_done ? ai_data.DEBUG_DRAW_COLOR : c_white);
		
		for(var i = 0; i < array_length(neigs); i++) {
		
			var n = neigs[i][0];
			var action = neigs[i][1];
			var curve = neigs[i][2];
			
			if action == 0 {
				draw_line_width(mid_x+xoff, mid_y+yoff, n.mid_x+xoff, n.mid_y+yoff, 2);
			}
			else if action == 1 {
				var prec = 4;
				for(var c = prec; c < array_length(curve); c++) {
					if c % prec == 0 draw_line_width(curve[c-prec][0]+xoff, curve[c-prec][1]+yoff, curve[c][0]+xoff, curve[c][1]+yoff, 2);
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
