if ppf.gen_start_new_cycle {
	ppf.gen_start_new_cycle = false;
	
	ppf.gen_nodes = [];
	
	with(obj_node) {
		array_push(ppf.gen_nodes, id);
		Foreach ai_data inStruct ppf.AI Run neig_data[$ Loop.key] = [];
		mid_x = x + ppf.CELL_SIZE div 2;
		mid_y = y + ppf.CELL_SIZE div 2;
	}
	
	ppf.gen_counter1 = 0;
	ppf.gen_counter2 = 0;
	ppf.gen_done = false;
}

if !ppf.gen_done {

	var l = array_length(ppf.gen_nodes);

	repeat(ppf.MAX_GEN_CONN < 1 ? sqr(l) : ppf.MAX_GEN_CONN) {
		
		if ppf.gen_counter2 < l {
		
			var n1 = ppf.gen_nodes[ppf.gen_counter1];
			var n2 = ppf.gen_nodes[ppf.gen_counter2];
		
			if n1.id == n2.id and n1 < l n1 = ppf.gen_nodes[++ppf.gen_counter1];
		
			if ++ppf.gen_counter1 >= l {
				ppf.gen_counter1 = 0;
				ppf.gen_counter2++;
				if ppf.gen_counter2 == l {
					ppf.gen_done = true;
					break;
				}
			}
		
			Foreach ai_data inStruct ppf.AI Run {
				if !ai_data.ACTIVE continue;
				ppf_join_nodes(n1, n2, ai_data, Loop.key);
			}
		}
	}
	
	ppf.gen_progress = ppf.gen_counter2 / l;
}
