/*if start_node != noone and end_node != noone {
	
	var prevx = start_node.mid_x;
	var prevy = start_node.mid_y;
	for(var i = 1; i < array_length(path); i++) {
		var p = path[i][0];
		draw_line_width(p.mid_x, p.mid_y, prevx, prevy, 3);
		prevx = p.mid_x;
		prevy = p.mid_y;
	}
	draw_line_width(end_node.mid_x, end_node.mid_y, prevx, prevy, 3);
}
