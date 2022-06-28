draw_set_color(c_white);
draw_text(4, 4, "fps_real: " + string(floor(fps_real)));
draw_text(148, 4, "avg: " + string(floor(avg_fps)));
draw_text(4, 26, "ppf.gen_progress: " + string(round(ppf.gen_progress * 100)) + "%");

avg += fps_real;
++avg_counter;
if avg_counter > room_speed / 2 {
	avg_fps = avg / avg_counter;
	avg_counter = 0;
	avg = 0;
}
