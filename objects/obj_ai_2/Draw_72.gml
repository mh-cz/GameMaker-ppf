if ai_data.DEBUG.DRAW_AI_PATH {
	draw_set_alpha(0.3);
	draw_set_color(ai_data.DEBUG.DRAW_AI_PATH_COLOR);
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
}
draw_set_alpha(1);
