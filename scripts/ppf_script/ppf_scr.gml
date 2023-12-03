function PPF_core() constructor {

	worlds = {};
	profiles = {};
	
	jump_arc = new PPF_jump_arc();
	nodes = ds_list_create();
	
	
}

function PPF_profile(name) constructor {
	
	global.PPF.profiles[$ name] = self;
	
	//
	
	spd = 5;
	g = 0.3;
	
	hitbox_width = 20;
	hitbox_height = 30;
	hitbox_extend = 4;
	
	jump_height = 200;
	jump_height_min = 16;
	jump_height_step = 32;
	
	fall_height = infinity;
	elevation_step = 32;
	
	//

	worlds = ds_list_create();
	
	static add_collision_world = function(cw_or_name) {
		
		if is_string(cw_or_name) 
			cw_or_name = global.PPF.worlds[$ cw_or_name];
			
		ds_list_add(worlds, cw_or_name);
		
		return self;
	}
	
}

function PPF_collision_world(name) constructor {
	
	global.PPF.worlds[$ name] = self;
	
	self.shapes = ds_list_create();
	self.fn_on_begin = function(this) {};
	
	static add_shape = function(shape) {
		
		ds_list_add(shapes, (shape));
		return self;
	}
	
	static add_shapes = function(shape_array) {
		
		for(var i = 0, l = array_length(shape_array); i < l; i++) 
			add_shape(shape_array[i]);
		
		return self;
	}

	static draw = function() {
		
		for(var i = 0, l = ds_list_size(shapes); i < l; i++) 
			shapes[| i].draw();
		
		return self;
	}

}

function PPF_jump(vspd, hspd, elevation) constructor {
	
	self.vspd = vspd;
	self.hspd = hspd;
	self.elevation = elevation;
}

function PPF_shape() constructor {
	
	self.coords = ds_list_create();
	
	self.bb_left = infinity;
	self.bb_top = infinity;
	self.bb_right = -infinity;
	self.bb_bottom = -infinity;
	
	self.collision_enabled = true;
	
	static deactivate_outside = function(left, top, right, bottom) {
		
		collision_enabled = !(left > bb_right or right < bb_left or top > bb_bottom or bottom < bb_top);
	}
	
	static add_point = function(px, py) {
		
		ds_list_add(coords, [px, py]);
		
		bb_left = min(bb_left, px);
		bb_top = min(bb_top, py);
		bb_right = max(bb_right, px);
		bb_bottom = max(bb_bottom, py);
		
		return self;
	}
	
	static add_points = function(xy_array) {
		
		for(var i = 0, l = array_length(xy_array); i < l; i += 2) 
			add_point(xy_array[i], xy_array[i+1]);
		
		return self;
	}
	
	static rectangle_intersection = function(rx1, ry1, rx2, ry2) {
		
        for (var i = 0, l = ds_list_size(coords); i < l; i++) {
			
			var this = coords[| i];
            var next = coords[| (i + 1) % l];
			if self.segment_rectangle_intersection(this[0], this[1], next[0], next[1], rx1, ry1, rx2, ry2) return true;
		}
		
		return false;
	}
	
	static segment_rectangle_intersection = function(x1, y1, x2, y2, rx1, ry1, rx2, ry2) {

		if point_in_rectangle(x1, y1, rx1+1, ry1+1, rx2-1, ry2-1)
		or point_in_rectangle(x2, y2, rx1+1, ry1+1, rx2-1, ry2-1)
			return true;

		if ((x1 <= rx1 and x2 <= rx1)
		or (y1 <= ry1 and y2 <= ry1)
		or (x1 >= rx2 and x2 >= rx2)
		or (y1 >= ry2 and y2 >= ry2))
		    return false;

		var m = (y2 - y1) / (x2 - x1);

		var yy = m * (rx1 - x1) + y1;
		if (yy > ry1 and yy < ry2) return true;

		yy = m * (rx2 - x1) + y1;
		if (yy > ry1 and yy < ry2) return true;

		var xx = (ry1 - y1) / m + x1;
		if (xx > rx1 and xx < rx2) return true;

		xx = (ry2 - y1) / m + x1;
		if (xx > rx1 and xx < rx2) return true;

		return false;
	}
	
	static draw = function() {
		
		/*for (var i = 0, l = ds_list_size(coords); i < l; i++) {
			
			var this = coords[| i];
	        var next = coords[| (i + 1) % l];
			
			draw_line(this[0], this[1], next[0], next[1]);
		}
		*/
		if collision_enabled draw_rectangle(bb_left, bb_top, bb_right, bb_bottom, true);
		
		return self;
	}
	
}

function PPF_jump_arc() constructor {
	
	self.p_inner1 = new PPF_parabola();
	self.p_inner2 = new PPF_parabola();
	self.p_outer = new PPF_parabola();

	self.fx = 0; self.fy = 0;
	self.tx = 0; self.ty = 0;

	self.efx = 0; self.efy = 0;
	self.etx = 0; self.ety = 0;
	
	self.fx2 = 0; self.fy2 = 0;
	self.tx2 = 0; self.ty2 = 0;
	
	self.center_x = 0;
	self.top_lim = 0;
	self.left_lim = 0;
	self.left_bottom_lim = 0;
	self.right_lim = 0;
	self.right_bottom_lim = 0;
	
	self.hspd = 0;
	self.vspd = 0;
	self.jtime = 0;
	self.htb_w_half = 0;
	self.htb_h_half = 0;
	self.htb_extend = 0;
	self.hwe = 0;
	self.hhe = 0;
	self.shortest_jtime = infinity;
	self.profile = noone;
	self.jump_elevation = 0;
	self.fall_elevation = 0;
	
	self.bb_top = 0;
	self.bb_right = 0;
	self.bb_bottom = 0;
	self.bb_left = 0;
	
	self.collided = false;
	
	static try_jump = function(profile, from_x, from_y, to_x, to_y) {
		
		g = profile.g;
		spd = profile.spd;
		htb_w_half = profile.hitbox_width * 0.5;
		htb_h_half = profile.hitbox_height * 0.5;
		htb_extend = profile.hitbox_extend;
		hwe = htb_w_half + profile.hitbox_extend;
		hhe = htb_h_half + profile.hitbox_extend;
		jump_height = profile.jump_height;
		
		// og coords
		fx = from_x;
		fy = from_y;
		tx = to_x;
		ty = to_y;
		
		jump_elevation = 0;
		fall_elevation = 0;
		efy = fy;
		ety = ty;
		
		// quick check
		collided = !is_possible();
		if collided return self;
		
		// sorted coords
		if tx < fx {
			fx2 = tx;
			fy2 = ty;
			tx2 = fx;
			ty2 = fy;
		}
		else {
			fx2 = fx;
			fy2 = fy;
			tx2 = tx;
			ty2 = ty;	
		}

		// arc bounding box
		bb_top = fy - profile.jump_height - hhe;
		bb_bottom = max(fy, ty) + hhe;
		bb_left = fx2 - hwe;
		bb_right = tx2 + hwe;

		// turn off collision on shapes outside arc bbox
		for(var w = 0, wl = ds_list_size(profile.worlds); w < wl; w++) {
			var world = profile.worlds[| w];
			for(var i = 0, sl = ds_list_size(world.shapes); i < sl; i++) {
				world.shapes[| i].deactivate_outside(bb_left, bb_top, bb_right, bb_bottom);
			}
		}

		self.calc_limits();
		
		// stoodis
		var jresult = undefined//self.simple_jump(profile);
		//if !jresult and ty > fy jresult = self.elevated_fall(profile);
		//if !jresult jresult = self.elevated_jump(profile);
		if !jresult jresult = self.elevated_jump_and_fall(profile);
		
		if jresult self.draw();
		
		return jresult;
	}
	
	static calc_limits = function() {
		
		center_x = fx2 + (tx2 - fx2) * 0.5;
		left_lim = fx2 - htb_w_half;
		left_bottom_lim = fy2 - (fx < tx ? jump_elevation : fall_elevation) + htb_h_half;
		right_lim = tx2 + htb_w_half;
		right_bottom_lim = ty2 - (fx > tx ? jump_elevation : fall_elevation) + htb_h_half;
		
		// set limits
		p_outer.set_limits(left_lim, left_bottom_lim, 0, center_x, right_lim, right_bottom_lim);
		p_inner1.set_limits(left_lim, left_bottom_lim, 0, center_x, right_lim, right_bottom_lim);
		p_inner2.set_limits(left_lim, left_bottom_lim, 0, center_x, right_lim, right_bottom_lim);	
	}
	
	static is_possible = function() {

		vspd = sqrt(2 * g * jump_height);
		
		var ydiff = (vspd * vspd) - (2 * g * (efy - ety));
		if ydiff < 4 return false; // target too high
		
		jtime = (vspd + sqrt(ydiff)) / g;
		if jtime + jump_elevation > shortest_jtime return false // shorter jump exists
		
		hspd = ((tx - fx) / (jtime * spd)) * spd;
		if abs(hspd) > spd or hspd == 0 return false // target too far
		
		return true;
	}
	
	static simple_jump = function(profile) {

		jump_elevation = 0;
		fall_elevation = 0;

		for(
		var jh = profile.jump_height_min + jump_elevation; 
		jh < profile.jump_height; 
		jh += profile.jump_height_step) {
				
			collided = true;
				
			jump_height = jh - jump_elevation;
			if jump_height < profile.jump_height_min continue;
				
			if !self.calc_jump_params() continue;

			collided = false;
			for(var w = 0; w < ds_list_size(profile.worlds); w++) {
				var world = profile.worlds[| w];
				for(var i = 0; i < ds_list_size(world.shapes); i++) {
					var shape = world.shapes[| i];
					if !shape.collision_enabled continue;
					
					collided = self.shape_point_between(shape)
						or p_inner1.shape_intersection(shape) 
						or p_inner2.shape_intersection(shape)
						or p_outer.shape_intersection(shape)
						or shape.rectangle_intersection(tx - htb_w_half, ety - htb_h_half - 4, tx + htb_w_half, ty + htb_h_half)
						or shape.rectangle_intersection(fx - htb_w_half, efy - htb_h_half - 4, fx + htb_w_half, fy + htb_h_half);
							
					if collided break;
				}
				if collided continue;
				return new PPF_jump(vspd, hspd, jump_elevation);
			}
		}
		
		return undefined;
	}
	
	static elevated_jump = function(profile) {
		
		fall_elevation = 0;
		
		for(
		jump_elevation = profile.elevation_step; 
		jump_elevation < profile.jump_height; 
		jump_elevation += profile.elevation_step) {
			
			self.calc_limits();
			
			for(
			var jh = profile.jump_height_min + jump_elevation; 
			jh < profile.jump_height; 
			jh += profile.jump_height_step) {
				
				collided = true;
				
				jump_height = jh - jump_elevation;
				if jump_height < profile.jump_height_min continue;
				
				if !self.calc_jump_params() continue;

				collided = false;
				for(var w = 0; w < ds_list_size(profile.worlds); w++) {
					var world = profile.worlds[| w];
					for(var i = 0; i < ds_list_size(world.shapes); i++) {
						var shape = world.shapes[| i];
						if !shape.collision_enabled continue;
					
						collided = self.shape_point_between(shape)
							or p_inner1.shape_intersection(shape) 
							or p_inner2.shape_intersection(shape)
							or p_outer.shape_intersection(shape)
							or shape.rectangle_intersection(tx - htb_w_half, ety - htb_h_half - 4, tx + htb_w_half, ty + htb_h_half)
							or shape.rectangle_intersection(fx - htb_w_half, efy - htb_h_half - 4, fx + htb_w_half, fy + htb_h_half);
							
						if collided break;
					}
					if collided break;
				}
				if collided continue;
				return new PPF_jump(vspd, hspd, jump_elevation);
			}
		}
		
		return undefined;
	}
	
	static elevated_fall = function(profile) {
		
		jump_elevation = 0;
		
		for(
		fall_elevation = 0; 
		fall_elevation < profile.jump_height; 
		fall_elevation += profile.elevation_step) {

				self.calc_limits();

				for(
				var jh = profile.jump_height_min + jump_elevation; 
				jh < profile.jump_height; 
				jh += profile.jump_height_step) {
				
				collided = true;
				
				jump_height = jh - jump_elevation;
				if jump_height < profile.jump_height_min continue;
				
				if !self.calc_jump_params() continue;

				collided = false;
				for(var w = 0; w < ds_list_size(profile.worlds); w++) {
					var world = profile.worlds[| w];
					for(var i = 0; i < ds_list_size(world.shapes); i++) {
						var shape = world.shapes[| i];
						if !shape.collision_enabled continue;
					
						collided = self.shape_point_between(shape)
							or p_inner1.shape_intersection(shape) 
							or p_inner2.shape_intersection(shape)
							or p_outer.shape_intersection(shape)
							or shape.rectangle_intersection(tx - htb_w_half, ety - htb_h_half - 4, tx + htb_w_half, ty + htb_h_half)
							or shape.rectangle_intersection(fx - htb_w_half, efy - htb_h_half - 4, fx + htb_w_half, fy + htb_h_half);
							
						if collided break;
					}
					if collided break;
				}
				if collided continue;
				return new PPF_jump(vspd, hspd, jump_elevation);
			}
		}
		
		return undefined;
	}
	
	static elevated_jump_and_fall = function(profile) {
		
		for(
		fall_elevation = profile.elevation_step; 
		fall_elevation < profile.jump_height; 
		fall_elevation += profile.elevation_step) {

			for(
			jump_elevation = profile.elevation_step; 
			jump_elevation < profile.jump_height; 
			jump_elevation += profile.elevation_step) {
			
				self.calc_limits();
			
				for(var 
				jh = profile.jump_height_min + jump_elevation; 
				jh < profile.jump_height; 
				jh += profile.jump_height_step) {
				
					collided = true;
				
					jump_height = jh - jump_elevation;
					if jump_height < profile.jump_height_min continue;
				
					if !self.calc_jump_params() continue;

					collided = false;
					for(var w = 0; w < ds_list_size(profile.worlds); w++) {
						var world = profile.worlds[| w];
						for(var i = 0; i < ds_list_size(world.shapes); i++) {
							var shape = world.shapes[| i];
							if !shape.collision_enabled continue;
					
							collided = self.shape_point_between(shape)
								or p_inner1.shape_intersection(shape) 
								or p_inner2.shape_intersection(shape)
								or p_outer.shape_intersection(shape)
								or shape.rectangle_intersection(tx - htb_w_half, ety - htb_h_half - 4, tx + htb_w_half, ty + htb_h_half)
								or shape.rectangle_intersection(fx - htb_w_half, efy - htb_h_half - 4, fx + htb_w_half, fy + htb_h_half);
							
							if collided break;
						}
						if collided break;
					}
					if collided break;
				}
				if collided continue;
				return new PPF_jump(vspd, hspd, jump_elevation);
			}
		}
		
		return undefined;
	}

	static calc_jump_params = function() {
		
		efy = fy - jump_elevation;
		ety = ty - fall_elevation;
		
		if !is_possible() return false;

		var hsign = sign(hspd);

		var pmid = pos_t(jtime * 0.5);
		var pfraq = pos_t(jtime * (0.7 - (efy > ety) * 0.4));
		
		top_lim = efy - jump_height - hhe;
		
		p_outer.from_3_points(
			fx - (htb_w_half + 1) * hsign,
			efy - hhe,
			fx + pfraq[0] + hwe * (fx + pfraq[0] < center_x ? -1 : 1),
			efy + pfraq[1] - hhe,
			tx + (htb_w_half + 1) * hsign,
			ety - hhe
		)
		.tlim = top_lim;
		
		p_inner1.from_3_points(
			fx - htb_w_half - 1,
			efy + (htb_h_half),
			fx + pmid[0] - hwe,
			efy + pmid[1] + hhe,
			tx - htb_w_half - 1,
			ety + (htb_h_half)
		)
		.tlim = top_lim;
		
		p_inner2.from_3_points(
			fx + htb_w_half + 1,
			efy + (htb_h_half),
			fx + pmid[0] + hwe,
			efy + pmid[1] + hhe,
			tx + htb_w_half + 1,
			ety + (htb_h_half)
		)
		.tlim = top_lim;

		return true;
	}

	static draw = function() {
	
		draw_set_color(c_gray);
		
		if jump_elevation != 0 
			draw_rectangle(
				fx - htb_w_half, 
				efy - htb_h_half, 
				fx + htb_w_half, 
				fy + htb_h_half,
				true);
				
		if fall_elevation != 0 
			draw_rectangle(
				tx - htb_w_half, 
				ety - htb_h_half, 
				tx + htb_w_half, 
				ty + htb_h_half,
				true);
		
		var segments = 10;
		var step = jtime/segments;
		for(var i = 0, l = jtime + step/2; i < l; i += step) {
			
			var p = pos_t(i);
			var xoff = p[0];
			var yoff = p[1];

			draw_rectangle(
				fx + xoff - htb_w_half, 
				efy + yoff - htb_h_half, 
				fx + xoff + htb_w_half, 
				efy + yoff + htb_h_half, 
				true);	
		}
		/*
		draw_set_color(c_lime);
		p_inner1.draw();
		draw_set_color(c_aqua);
		p_inner2.draw();
		draw_set_color(c_red);
		p_outer.draw();
		*/
		return self;
	}
	
	static pos_t = function(t) {
		return [
			hspd * t, 
			-vspd * t + 0.5 * g * t * t
		];
	}
		
	static shape_point_between = function(shape) {
		
        for (var i = 0, l = ds_list_size(shape.coords); i < l; i++) {
			var this = shape.coords[| i];
			
			var px = this[0];
			var py = this[1];
			
			if (px > left_lim and px < right_lim)
			and ((px > center_x and py < right_bottom_lim) or (px < center_x and py < left_bottom_lim))
			and p_outer.point_below(px, py) 
			and (!p_inner1.point_below(px, py) or !p_inner2.point_below(px, py)) {
				//draw_circle(px, py, 4, false);
				return true;
			}
		}
		
		return false;
	}
}

function PPF_parabola(a = 0.1, b = 0, c = 0) constructor {
	
	self.a = a;
	self.b = b;
	self.c = c;
	
	self.tlim = 0;
	self.rlim = 0;
	self.rblim = 0;
	self.llim = 0;
	self.lblim = 0;
	self.midx = 0;
	
	static set_limits = function(llim, lblim, tlim, midx, rlim, rblim) {
		
		self.tlim = tlim;
		self.rlim = rlim;
		self.rblim = rblim;
		self.llim = llim;
		self.lblim = lblim;
		self.midx = midx;
		
		return self;
	}
	
	static from_3_points = function(x1, y1, x2, y2, x3, y3) {
		
		var denom = 1 / ((x1 - x2) * (x1 - x3) * (x2 - x3));
		a = (x3 * (y2 - y1) + x2 * (y1 - y3) + x1 * (y3 - y2)) * denom;
		b = (x3 * x3 * (y1 - y2) + x2 * x2 * (y3 - y1) + x1 * x1 * (y2 - y3)) * denom;
		c = (x2 * x3 * (x2 - x3) * y1 + x3 * x1 * (x3 - x1) * y2 + x1 * x2 * (x1 - x2) * y3) * denom;
		
		return self;
	}
	
	static draw = function() {
		
	    for (x = -2000; x <= 2000; x += 10) { 
	        y = a * x * x + b * x + c;
	        draw_circle(x, y, 1, false);
	    }
	}
	
	static point_below = function(px, py) {
        return py > tlim and py > (a * px * px + b * px + c);
    }

	static line_intersection = function(m, d) {

		var bm = b - m;
	    var discriminant = bm * bm - 4 * a * (c - d);
	    if discriminant < 0.001 or is_nan(discriminant) return undefined;

		var sq = sqrt(discriminant);
	    var x1 = (-bm - sq) / (2 * a);
	    var x2 = (-bm + sq) / (2 * a);
	    var y1 = m * x1 + d;
	    var y2 = m * x2 + d

		return [x1, y1, x2, y2];
	}

    static segment_intersection = function(x1, y1, x2, y2) {
       
		if x1 == x2 {
			var yt = a * x1 * x1 + b * x1 + c;
			
			return (y1 > yt xor y2 > yt) 
				and (x1 > llim and x1 < rlim)
				and ((x1 > midx and (y2 < rblim or y1 < rblim)) 
				  or (x1 < midx and (y2 < lblim or y1 < lblim)));
		}

		var xx1, yy1, xx2, yy2;
		
		if x2 < x1 {
			// temp
			xx1 = x1;
			yy1 = y1;
			xx2 = x2;
			yy2 = y2;
			// switch
			x1 = xx2;
			y1 = yy2;
			x2 = xx1;
			y2 = yy1;
		}

		var m = (y2 - y1) / (x2 - x1);
		var d = y1 - (m * x1);

		var pts = self.line_intersection(m, d);
		if pts == undefined return false;
		
		xx1 = pts[0];
		yy1 = pts[1];
		xx2 = pts[2];
		yy2 = pts[3];	
		
		return (xx1 > x1 and xx1 < x2 and xx1 > llim and yy1 < lblim and yy1 > tlim) 
			or (xx2 > x1 and xx2 < x2 and xx2 < rlim and yy2 < rblim and yy2 > tlim);
	}
	
	static rectangle_intersection = function(x1, y1, x2, y2) {

		return self.segment_intersection(x1, y1, x1, y2) 
			or self.segment_intersection(x2, y1, x2, y2) 
			or self.segment_intersection(x1, y1, x2, y1) 
			or self.segment_intersection(x1, y2, x2, y2);
	}
		
	static shape_intersection = function(shape) {
		
        for (var i = 0, l = ds_list_size(shape.coords); i < l; i++) {
			
			var this = shape.coords[| i];
            var next = shape.coords[| (i + 1) % l];
			if self.segment_intersection(this[0], this[1], next[0], next[1]) return true;
		}
		
		return false;
	}
	
}

function PPF_node() constructor {
	
	self.pos_x = 0;
	self.pos_y = 0;
	
	self.neighbours = ds_list_create();
}



function print_return(str, ret = false) {
	show_debug_message(str);
	return ret;
}

function flor(val, num) {
	return floor(val/num)*num;
}

function rond(val, num) {
	return round(val/num)*num;
}
