extends Control
class_name DiveBodyHUD

var parts: Dictionary = {"HEAD":100.0,"TORSO":100.0,"ARMS":100.0,"LEGS":100.0}
var suit_integrity: float = 100.0
var patch_count: int = 2
var font_size: int = 13

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _severity(value: float) -> Color:
    return Color(0.96,0.38,0.31) if value<40.0 else Color(1.0,0.76,0.35) if value<75.0 else Color(0.48,0.93,0.77)

func _draw() -> void:
    var font := ThemeDB.fallback_font
    var hp := float(parts.get("HEAD",100.0))*0.28 + float(parts.get("TORSO",100.0))*0.32 + float(parts.get("ARMS",100.0))*0.18 + float(parts.get("LEGS",100.0))*0.22
    draw_string(font,Vector2(12,21),"DIVER / HP %d%%" % int(ceilf(hp)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,_severity(hp))
    var hx := 46.0
    draw_circle(Vector2(hx,49),10,_severity(float(parts.get("HEAD",100.0))))
    draw_rect(Rect2(hx-10,62,20,31),_severity(float(parts.get("TORSO",100.0))))
    draw_line(Vector2(hx-14,66),Vector2(hx-25,101),_severity(float(parts.get("ARMS",100.0))),9,true)
    draw_line(Vector2(hx+14,66),Vector2(hx+25,101),_severity(float(parts.get("ARMS",100.0))),9,true)
    draw_line(Vector2(hx-5,92),Vector2(hx-13,127),_severity(float(parts.get("LEGS",100.0))),9,true)
    draw_line(Vector2(hx+5,92),Vector2(hx+13,127),_severity(float(parts.get("LEGS",100.0))),9,true)
    var order := ["HEAD","TORSO","ARMS","LEGS"]
    for i in order.size():
        var key: String = order[i]
        var value: float = clampf(float(parts.get(key,100.0)),0,100)
        var y := 42.0+float(i)*25.0
        draw_string(font,Vector2(93,y),"%s  %d" % [key,int(ceilf(value))],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.83,0.94,0.94))
        draw_rect(Rect2(94,y+5,125,4),Color(0.12,0.28,0.32))
        draw_rect(Rect2(94,y+5,125.0*value/100.0,4),_severity(value))
    draw_string(font,Vector2(14,152),"SUIT %d%%    PATCHES %d" % [int(suit_integrity),patch_count],HORIZONTAL_ALIGNMENT_LEFT,-1,13,_severity(suit_integrity))
