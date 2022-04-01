if ai_data == 0 ai_data = ppf.AI[$ ai_name];

hspd = (keyboard_check(vk_right) - keyboard_check(vk_left)) * ai_data.SPEED;

on_ground = vspd >= 0 and place_meeting(x, y+1, ppf.SOLID_OBJ);

if !on_ground {
	vspd += ai_data.GRAVITY;
}
else {
	if keyboard_check_pressed(vk_up) vspd = -ai_data.JUMP;
}
if keyboard_check_released(vk_up) vspd *= 0.5;

if place_meeting(x+hspd, y, ppf.SOLID_OBJ) repeat(ceil(abs(hspd))) {
	if !place_meeting(x+sign(hspd), y, ppf.SOLID_OBJ) x += sign(hspd);
	else { hspd = 0; break; }
}
x += hspd;

if place_meeting(x, y+vspd, ppf.SOLID_OBJ) repeat(ceil(abs(vspd))) {
	if !place_meeting(x, y+sign(vspd), ppf.SOLID_OBJ) y += sign(vspd);
	else { vspd = 0; break; }
}
y += vspd;
