/*if ppf.dyn_start_new_cycle {
	ppf.dyn_start_new_cycle = false;
	
	with(obj_node) {
		array_push(ppf.dyn_nodes, id);
		foreach "v" in ppf.AI as_struct neig_data[$ fe.k_v] = [];
		mid_x = x + ppf.CELL_SIZE div 2;
		mid_y = y + ppf.CELL_SIZE div 2;
	}
	
	ppf.dyn_counter1 = 0;
	ppf.dyn_counter2 = 0;
	ppf.dyn_done = false;
}

if !ppf.dyn_done {

	var l = array_length(ppf.dyn_nodes);

	repeat(ppf.DYNAMIC_CONNECTIONS < 1 ? sqr(l) : ppf.DYNAMIC_CONNECTIONS) {
		
		if ppf.dyn_counter2 < l {
		
			var n1 = ppf.dyn_nodes[ppf.dyn_counter1];
			var n2 = ppf.dyn_nodes[ppf.dyn_counter2];
		
			if n1.id == n2.id and n1 < l n1 = ppf.dyn_nodes[++ppf.dyn_counter1];
		
			if ++ppf.dyn_counter1 >= l {
				ppf.dyn_counter1 = 0;
				ppf.dyn_counter2++;
				if ppf.dyn_counter2 == l {
					ppf.dyn_done = true;
					break;
				}
			}
		
			foreach "ai_data" in ppf.AI as_struct {
				if !fe.ai_data.ACTIVE continue;
				ppf_join_nodes(n1, n2, fe.ai_data, fe.k_ai_data);
			}
		}
	}
	
	ppf.dyn_progress = ppf.dyn_counter2 / l;
}
