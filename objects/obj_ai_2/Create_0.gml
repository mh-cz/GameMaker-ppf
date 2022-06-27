ai_name = "Speedy";
ai_data = ppf.AI[$ ai_name];

vspd = 0;
hspd = 0;
grounded = false;
jumped = false;

new_target = [irandom(room_width), irandom(room_height)];

nodes = [];
node_num = 0;
nodes_len = 0;
towards_node = noone;

events = [];
events_len = 0;
event_num = 0;
event = 0;

next_x = x;
next_y = y;

next_node = function(this) {
	with(this) {
		if ++node_num >= nodes_len {
			x = next_x;
			y = next_y + ppf.CELL_SIZE * 0.5 - (abs(y - bbox_bottom) + 1);
			hspd = 0;
			vspd = 0;
			next_x = x;
			next_y = y;
			nodes = [];
			events = [];
			
			new_target = [irandom(room_width), irandom(room_height)];
		}
		else {
			towards_node = nodes[node_num][0];
			events = nodes[node_num][1];
			events_len = array_length(events);
			event_num = 0;
			next_event(this);
		}
	}
}

next_event = function(this) {
	with(this) {
		if event_num >= events_len next_node(this);
		else apply_event(this, events[event_num++]);
	}
}

apply_event = function(this, ev) {
	with(this) {
		x = ev.x;
		y = ev.y + ppf.CELL_SIZE * 0.5 - (abs(y - bbox_bottom) + 1);
		hspd = ev.hspd;
		vspd = ev.vspd;
		next_x = ev.next_x;
		next_y = ev.next_y;
	}
}
