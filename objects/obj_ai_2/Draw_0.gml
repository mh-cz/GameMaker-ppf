if ai.DEBUG.DRAW_AI_PATH {
	draw_set_alpha(0.2);
	draw_set_color(ai.DEBUG.DRAW_AI_PATH_COLOR);
	var l = array_length(nodes);
	if l > 0 {
		var prevx = nodes[0][0].mid_x;
		var prevy = nodes[0][0].mid_y;
		for(var i = 1; i < l; i++) {
			var n = nodes[i][0];
			draw_line_width(n.mid_x, n.mid_y, prevx, prevy, 3);
			prevx = n.mid_x;
			prevy = n.mid_y;
		}
	}
	draw_set_color(c_white);
	draw_circle(next_x, next_y, 4, false);
}
draw_set_alpha(1);

draw_self();
