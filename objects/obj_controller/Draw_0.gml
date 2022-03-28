draw_set_alpha(0.5);

with(obj_node) {
	
	var yoff = 0;
	var xoff = 0;
	
	foreach "ai_data" in ppf_data.AI as_struct {
		
		var neig = neig_data[$ fed.cs.key];
		
		if !ai_data.DRAW continue;
		draw_set_color(ai_data.COLOR);
		
		for(var i = 0; i < array_length(neig); i++) {
		
			var n = neig[i][0];
			var action = neig[i][1];
			var curve = neig[i][2];
			
			if action == 0 {
				draw_line_width(mx+xoff, my+yoff, n.mx+xoff, n.my+yoff, 2);
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
