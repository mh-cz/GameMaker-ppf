if !ppf.gen_done exit;
ai_data.DRAW_PATHS = false;

//if mouse_check_button_pressed(mb_left) new_target = [mouse_x, mouse_y];

if grounded and new_target != 0 {
	
	nodes = ppf_find_path(x, y, new_target[0], new_target[1], ai_name);
	new_target = 0;
	
	nodes_len = array_length(nodes);
	if nodes_len != 0 {
		node_num = 0;
		event_num = 0;
		towards_node = nodes[0][0];
		events = nodes[0][1];
		events_len = array_length(events);
		next_x = towards_node.mid_x;
		next_y = towards_node.mid_y;
	}
}

if towards_node != noone {
	
	if node_num == 0 and vspd == 0 hspd = sign(towards_node.mid_x - x) * ai_data.SPEED;
	
	var xdist = max(abs(hspd), 4);
	var ydist = max(abs(vspd), 4);
	
	if abs(x - next_x) < xdist and abs((bbox_bottom - ppf.CELL_SIZE * 0.5) - next_y) < ydist {
		hspd = 0;
		vspd = 0;
		next_event(id);
	}
}

grounded = vspd == 0 and place_meeting(x, y+2, ppf.SOLID_OBJ);
if !grounded vspd += ai_data.GRAVITY else vspd = 0;

if place_meeting(x+hspd, y, ppf.SOLID_OBJ) {
	repeat(ceil(abs(hspd))) {
		if !place_meeting(x+sign(hspd), y, ppf.SOLID_OBJ) x += sign(hspd) else break;
	}
	//hspd = 0;
}
else x += hspd;

if place_meeting(x, y+vspd, ppf.SOLID_OBJ) {
	repeat(ceil(abs(vspd))) {
		if !place_meeting(x, y+sign(vspd), ppf.SOLID_OBJ) y += sign(vspd) else break;
	}
	vspd = 0;
}
y += vspd;