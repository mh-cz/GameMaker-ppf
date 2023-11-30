function PPF_profile() constructor {
	
	self.spd = 5;
	self.g = 0.3;
	self.jump_height = 200;
	self.hitbox_w = 20;
	self.hitbox_h = 30;
}

function PPF_shape() constructor {
	
	self.coords = ds_list_create();
	
	self.bb_left = infinity;
	self.bb_top = infinity;
	self.bb_right = -infinity;
	self.bb_bottom = -infinity;
	
	static add_point = function(x, y) {
		
		ds_list_add(coords, [x, y]);
		
		bb_left = min(bb_left, x);
		bb_top = min(bb_top, y);
		bb_right = max(bb_right, x);
		bb_bottom = max(bb_bottom, y);
		
		return self;
	}
	
	static add_points = function(xy_array) {
		
		for(var i = 0, l = array_length(xy_array); i < l; i += 2) 
			add_point(xy_array[i], xy_array[i+1]);
		
		return self;
	}
		
	static draw = function() {
		
		for (var i = 0, l = ds_list_size(coords); i < l; i++) {
			
			var this = coords[| i];
	        var next = coords[| (i + 1) % l];
			
			draw_line(this[0], this[1], next[0], next[1]);
		}
		
		return self;
	}
	
}

function PPF_world(hitbox_w, hitbox_h) constructor {
	
	self.poly_offset_x = hitbox_w * 0.5;
	self.poly_offset_y = hitbox_h * 0.5;
	self.collide = true;
	
	self.shapes = ds_list_create();
	
	static add_shape = function(shape) {
		
		ds_list_add(shapes, (shape));
		
		return self;
	}
	
	static add_shapes = function(shape_array) {
		
		for(var i = 0, l = array_length(shape_array); i < l; i++) 
			add_shape(shape_array[i]);
		
		return self;
	}

	static offset_polygon = function(shape) {
		
		var off_shape = new PPF_shape();
		
        for (var i = 0, l = ds_list_size(shape.coords); i < l; i++) {
			
            var prev = shape.coords[| (i - 1 + l) % l];
			var this = shape.coords[| i];
            var next = shape.coords[| (i + 1) % l];

			var angle = point_direction(this[0], this[1], next[0], next[1]);
			var poe = point_on_edge(poly_offset_x * 2, poly_offset_y * 2, angle);
			var dist = -point_distance(poly_offset_x, poly_offset_y, poe[0], poe[1]);


            off_shape.add_point(
				this[0] + lengthdir_x(dist, angle-90), 
				this[1] + lengthdir_y(dist, angle-90)
			);

            off_shape.add_point(
				next[0] + lengthdir_x(dist, angle-90), 
				next[1] + lengthdir_y(dist, angle-90)
			);


		}
		
		return off_shape;
	}
	
	static point_on_edge = function(w, h, a) {
		
		var s = dsin(a)
		var c = dcos(a);
		var dy = s > 0 ? h/2 : h/-2;
		var dx = s > 0 ? w/2 : w/-2;     
		
		if(abs(dx*s) < abs(dy*c)) { 
			dy = (dx * s) / c;
		} 
		else {
			dx = (dy * c) / s;
		}
		
		return [dx, dy]
	}
	
	static draw = function() {
		
		for(var i = 0, l = ds_list_size(shapes); i < l; i++) 
			shapes[| i].draw();
		
		return self;
	}

}








function PPF_jump_arc() constructor {
	
	self.p_inner1 = new PPF_parabola();
	self.p_inner2 = new PPF_parabola();
	self.p_outer = new PPF_parabola();

	self.fx = 0;
	self.fy = 0;
	self.tx = 0;
	self.ty = 0;
	
	self.fx2 = 0;
	self.fy2 = 0;
	self.tx2 = 0;
	self.ty2 = 0;
	
	self.hspd = 0;
	self.vspd = 0;
	self.jtime = 0;
	self.htb_w_half = 0;
	self.htb_h_half = 0;
	self.shortest_jtime = infinity;
	self.profile = noone;
	
	self.rect_bbox_top = 0;
	self.rect_bbox_left = 0;
	self.rect_bbox_bottom = 0;
	self.rect_bbox_right = 0;
	
	self.p_inner_col = true;
	self.collided = false;
	
	static try_jump = function(world, profile, from_x, from_y, to_x, to_y) {
		
		self.profile = profile;
		g = profile.g;
		spd = profile.spd;
		htb_w_half = profile.hitbox_w * 0.5;
		htb_h_half = profile.hitbox_h * 0.5;
		
		fx = from_x;
		fy = from_y;
		tx = to_x;
		ty = to_y;
		
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
		
		for(jump_height = 16; jump_height < profile.jump_height; jump_height += 32) {
			
			if !self.calc_jump_params() continue;
			if !world.collide return draw();
			
			collided = false;
			for(var i = 0; i < ds_list_size(world.shapes); i++) {
				if p_outer.shape_intersection(world.shapes[| i]) 
				or p_inner1.shape_intersection(world.shapes[| i])
				or p_inner2.shape_intersection(world.shapes[| i]) 
				{
					collided = true;
					break;
				}
			}
			if collided continue;
			
			draw();
			break;
		}

		return self;
	}
	
	static calc_jump_params = function() {
		
		vspd = sqrt(2 * g * jump_height);
		
		var ydiff = (vspd * vspd) - (2 * g * (fy2 - ty2));
		if ydiff <= 8 return false; // target too high
		
		jtime = (vspd + sqrt(ydiff)) / g;
		if jtime > shortest_jtime return false; // shorter jump exists
		
		hspd = ((tx2 - fx2) / (jtime * spd)) * spd;
		if abs(hspd) > spd or hspd == 0 return false; // target too fat
		
		var EXTRA = 4;
		var hwe = htb_w_half + EXTRA;
		var hhe = htb_h_half + EXTRA;

		var pmid = pos_t(jtime * 0.5);
		var pfraq = pos_t(jtime * (ty2 < fy2 ? 0.3 : 0.7));
		
		var center_x = fx2 + ((vspd / (2 * (0.5 * g))) * hspd);
		var top_lim = fy2 - jump_height - hhe;
		var left_lim = fx2 - htb_w_half;
		var left_bottom_lim = fy2 + htb_h_half;
		var right_lim = tx2 + htb_w_half;
		var right_bottom_lim = ty2 + htb_h_half;
		
		/*draw_set_color(c_red);
		draw_line(left_lim, top_lim, right_lim, top_lim);
		
		draw_set_color(c_blue);
		draw_line(left_lim, 10000, left_lim, -10000);
		draw_line(10000, left_bottom_lim, -10000, left_bottom_lim);
		
		draw_set_color(c_green);
		draw_line(right_lim, 10000, right_lim, -10000);
		draw_line(10000, right_bottom_lim, -10000, right_bottom_lim);*/
		
		p_outer
		.from_3_points(
			fx2 - hwe,
			fy2 - hhe,
			fx2 + pfraq[0] + hwe * (fx2 + pfraq[0] < center_x ? -1 : 1),
			fy2 + pfraq[1] - hhe,
			tx2 + hwe,
			ty2 - hhe
		)
		.set_limits(
			left_lim, 
			left_bottom_lim, 
			top_lim, 
			center_x,
			right_lim, 
			right_bottom_lim
		);
		
		p_inner1
		.from_3_points(
			fx2 - hwe,
			fy2 + (htb_h_half),
			fx2 + pmid[0] - hwe,
			fy2 + pmid[1] + hhe,
			tx2 - hwe,
			ty2 + (htb_h_half)
		)
		.set_limits(
			left_lim, 
			left_bottom_lim, 
			top_lim, 
			center_x,
			right_lim, 
			right_bottom_lim
		);
		
		p_inner2
		.from_3_points(
			fx2 + hwe,
			fy2 + (htb_h_half),
			fx2 + pmid[0] + hwe,
			fy2 + pmid[1] + hhe,
			tx2 + hwe,
			ty2 + (htb_h_half)
		)
		.set_limits(
			left_lim, 
			left_bottom_lim, 
			top_lim, 
			center_x,
			right_lim, 
			right_bottom_lim
		);

		return true;
	}

	static draw = function() {
	
		draw_set_color(c_gray);
		
		var segments = abs(fx2 - tx2) / (htb_w_half*2);
		var step = jtime/segments;
		for(var i = 0, l = jtime + step/2; i < l; i += step) {
			
			var p = pos_t(i);
			var xoff = p[0];
			var yoff = p[1];

			draw_rectangle(
				fx2 + xoff - htb_w_half, 
				fy2 + yoff - htb_h_half, 
				fx2 + xoff + htb_w_half, 
				fy2 + yoff + htb_h_half, 
				true);	
		}
		
		draw_set_color(c_lime);
		p_inner1.draw();
		draw_set_color(c_aqua);
		p_inner2.draw();
		draw_set_color(c_red);
		p_outer.draw();
		
		return self;
	}
	
	static pos_t = function(t) {
		return [
			hspd * t, 
			-vspd * t + 0.5 * g * t * t
		];
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
	
	static below = function(x, y) {
        return y > tlim and y > (a * x * x + b * x + c);
    }

	static line_intersection = function(m, d) {

		var bm = b - m;
	    var discriminant = bm * bm - 4 * a * (c - d);
	    if discriminant < 0 return undefined;

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
			
			return (x1 > llim and x1 < rlim)
				and (y1 > yt xor y2 > yt) 
				and (
					(x1 > midx and (y2 < rblim or y1 < rblim)) 
				 or (x1 < midx and (y2 < lblim or y1 < lblim))
				);
		}

		var m = (y2 - y1) / (x2 - x1);
		var d = y1 - (m * x1);

		var pts = self.line_intersection(m, d);
		if pts == undefined return false;
		
		var px1 = pts[0];
		var py1 = pts[1];
		var px2 = pts[2];
		var py2 = pts[3];

		return 
			(py1 > tlim and py2 > tlim) 
			and (
				(px1 > x1 and px1 < x2 and px1 > llim and py1 < lblim) 
			 or (px2 > x1 and px2 < x2 and px2 < rlim and py2 < rblim)
			);
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

function PPF_collision_arc() constructor {
	
	self.outer = [];
	self.inner = [];
	
	static on_left_side = function(ax, ay, bx, by, cx, cy) {
		
		return (bx - ax) * (cy - ay) > (by - ay) * (cx - ax);
	}
	
	static segment_segment = function(p0_x,  p0_y,  p1_x,  p1_y,  p2_x,  p2_y,  p3_x,  p3_y) {
	
	    var s1_x = p1_x - p0_x;     
		var s1_y = p1_y - p0_y;
	    var s2_x = p3_x - p2_x;     
		var s2_y = p3_y - p2_y;
	
		var a = 1 / (-s2_x * s1_y + s1_x * s2_y);
	    var s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) * a;
	    var t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) * a;

	    return s >= 0 and s <= 1 and t >= 0 and t <= 1;
	}
	
	static check_with_segment = function(x1, y1, x2, y2) {
		
		var below_outer = false;
		
		for(var i = 0, l = array_length(outer)-3; i < l; i += 2) {
			
			var sx1 = outer[i];
			var sy1 = outer[i+1];
			var sx2 = outer[i+2];
			var sy2 = outer[i+3];
			
			/*var sx1 = min(xx1, xx2);
			var sy1 = min(yy1, yy2);
			var sx2 = max(xx1, xx2);
			var sy2 = max(yy1, yy2);*/
			
			var l1 = on_left_side(sx1, sy1, sx2, sy2, x1, y1);
			var l2 = on_left_side(sx1, sy1, sx2, sy2, x2, y2);
			
			if (l1 xor l2) and segment_segment(sx1, sy1, sx2, sy2, x1, y1, x2, y2) return true;
			
			below_outer = (l1 and x1 > sx1 and x1 < sx2) or (l2 and x2 > sx1 and x2 < sx2);
			if below_outer break;
		}
		
		var above_inner = false;
		
		for(var i = 0, l = array_length(inner)-3; i < l; i += 2) {
			
			var sx1 = inner[i];
			var sy1 = inner[i+1];
			var sx2 = inner[i+2];
			var sy2 = inner[i+3];
			
			/*var sx1 = min(xx1, xx2);
			var sy1 = min(yy1, yy2);
			var sx2 = max(xx1, xx2);
			var sy2 = max(yy1, yy2);*/
			
			var l1 = on_left_side(sx1, sy1, sx2, sy2, x1, y1);
			var l2 = on_left_side(sx1, sy1, sx2, sy2, x2, y2);

			if (l1 xor l2) and segment_segment(sx1, sy1, sx2, sy2, x1, y1, x2, y2) return true;

			above_inner = (!l1 and x1 > sx1 and x1 < sx2) or (!l2 and x2 > sx1 and x2 < sx2);
			if above_inner break;	
		}
		
		return below_outer and above_inner;
	}
	
	static draw = function() {
		
		for(var i = 0, l = array_length(outer)-3; i < l; i += 2) {
			draw_line(outer[i], outer[i+1], outer[i+2], outer[i+3]);
		}
		for(var i = 0, l = array_length(inner)-3; i < l; i += 2) {
			draw_line(inner[i], inner[i+1], inner[i+2], inner[i+3]);
		}
	}
}




