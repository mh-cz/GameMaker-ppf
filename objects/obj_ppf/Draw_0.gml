if keyboard_check_pressed(ord("R")) room_restart();

if keyboard_check_pressed(ord("S")) {
	Foreach ai_data inStruct ppf.AI Run {
		ai_data.DEBUG.DRAW_AI_PATH = !ai_data.DEBUG.DRAW_AI_PATH;
	}
}

draw_set_color(c_white);
draw_set_alpha(1);

var mx = floor(mouse_x/ppf.CELL_SIZE)*ppf.CELL_SIZE+ppf.CELL_SIZE/2;
var my = floor(mouse_y/ppf.CELL_SIZE)*ppf.CELL_SIZE+ppf.CELL_SIZE/2;


/*if mouse_check_button_pressed(mb_left) start_node = instance_nearest(mouse_x, mouse_y, obj_node);
if mouse_check_button_pressed(mb_right) end_node = instance_nearest(mouse_x, mouse_y, obj_node);

if start_node != noone draw_circle(start_node.mid_x, start_node.mid_y, 16, true);
if end_node != noone draw_circle(end_node.mid_x, end_node.mid_y, 32, true);

if mouse_check_button_pressed(mb_any) {
	if start_node != noone and end_node != noone {
		path = ppf_find_path(start_node.x, start_node.y, end_node.x, end_node.y, "Basic");
	}
}*/
/*

with(obj_node) {
	if x == 512 and y == 448 {
		Foreach ai_data inStruct ppf.AI Run {
			if !ai_data.ENABLED or !ai_data.DEBUG.DRAW_PATHS or Loop.key != "Speedy" continue;
			var events = ppf_calc_jump(mid_x, mid_y, mx, my, ai_data, 0);
			draw_text(10, 50, events);
		}
	}
}
*/

draw_set_alpha(0.2);

with(obj_node) {
	
	var yoff = 0;
	var xoff = 0;
	
	Foreach ai_data inStruct ppf.AI Run {
		
		if !ai_data.ENABLED or !ai_data.DEBUG.DRAW_PATHS or (ppf.gen_done == 1 and !ai_data.DEBUG.DRAW_PATHS_AFTER_GEN_DONE) continue;
		var neigs = neig_data[$ Loop.key];
		draw_set_color(ai_data.DEBUG.DRAW_PATHS_COLOR);
		
		for(var i = 1; i < array_length(neigs); i++) {
			
			var n = neigs[i][0];
			var events = neigs[i][1];
			
			var prevx = mid_x;
			var prevy = mid_y;
			for(var e = 0; e < array_length(events); e++) {
				var ev = events[e];
				draw_line_width(ev.x, ev.y, prevx, prevy, 3);
				prevx = ev.x;
				prevy = ev.y;
			}
			
			draw_line_width(n.mid_x+xoff, n.mid_y+yoff, prevx, prevy, 3);
		}
		
		yoff -= 3;
		xoff -= 3;
	}
}

draw_set_alpha(1);
draw_set_color(c_white);
