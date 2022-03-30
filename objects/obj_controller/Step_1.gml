if ppf.dyn_start_new_cycle {
	ppf.dyn_start_new_cycle = false;
		
	with(obj_node) {
		array_push(ppf.dyn_nodes, id);
		foreach "" in ppf.AI as_struct neig_data[$ fed.cs.key] = [];
	}
	
	ppf.dyn_counter1 = 1;
	ppf.dyn_counter2 = 0;
}

var l = array_length(ppf.dyn_nodes);

repeat(ppf.DYNAMIC_CONNECTING < 1 ? sqr(l) : ppf.DYNAMIC_CONNECTING) {
	
	if ppf.dyn_counter2 < l {
		
		var n1 = ppf.dyn_nodes[ppf.dyn_counter1];
		var n2 = ppf.dyn_nodes[ppf.dyn_counter2];
		
		if ++ppf.dyn_counter1 == l {
			ppf.dyn_counter1 = 0;
			ppf.dyn_counter2++;
		}
		
		foreach "aidata" in ppf.AI as_struct {
			
			var ai_data = aidata;
			if !ai_data.ACTIVE continue;
			var ai_name = fed.cs.key;
			
			with(n1) {
				
				if floor_id == noone {
					mid_x = x + ppf.CELL_SIZE div 2;
					mid_y = y + ppf.CELL_SIZE div 2;
					floor_id = collision_point(mid_x, mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, false, true);
				}
				
				with(n2) {
						
					if floor_id == noone {
						mid_x = x + ppf.CELL_SIZE div 2;
						mid_y = y + ppf.CELL_SIZE div 2;
						floor_id = collision_point(mid_x, mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, false, true);
					}
					
					if id != other.id {
							
						var connect = false;
						var action = ppf.STATE.WALK;
						var curve = [];
						
						// try walk
						if y == other.y {
							var ray = raycast(mid_x, mid_y, other.mid_x, other.mid_y, ppf.SOLID_OBJ, ppf.CELL_SIZE);
							if ray[0] == noone {
								if floor_id == other.floor_id
								or reversed_raycast(mid_x, mid_y+ppf.CELL_SIZE, other.mid_x, other.mid_y+ppf.CELL_SIZE, ppf.SOLID_OBJ, ppf.CELL_SIZE) {
									connect = true;
									action = ppf.STATE.WALK;
								}
							}
						}
					
						// try jump
						if !connect {
							var curve = ppf_calc_jump(mid_x, mid_y, other.mid_x, other.mid_y, ai_data, 10) {
								if array_length(curve) != 0 {
									connect = true;
									action = ppf.STATE.JUMP;
								}
							}
						}
					
						// add neighbour if connected
						if connect array_push(neig_data[$ ai_name], [other.id, action, curve]);
					}
				}
			}
		}
	}
}
