extends Control
class_name CaveHudGlyph

# Crisp vector pictograms with zero font/texture dependencies.
var glyph: String = "torch"
var line_color: Color = Color(0.81, 0.98, 0.98)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var s := minf(size.x, size.y) / 48.0
    var c := Vector2(size.x * 0.5, size.y * 0.5)
    match glyph:
        "up":
            _stroke([Vector2(-13,5), Vector2(0,-9), Vector2(13,5)], s,c)
            _stroke([Vector2(0,-9), Vector2(0,15)],s,c)
        "down":
            _stroke([Vector2(-13,-5), Vector2(0,9), Vector2(13,-5)],s,c)
            _stroke([Vector2(0,9), Vector2(0,-15)],s,c)
        "torch":
            _stroke([Vector2(-11,16),Vector2(-6,-1),Vector2(5,-1),Vector2(10,16),Vector2(-11,16)],s,c)
            _stroke([Vector2(-8,-5),Vector2(-12,-13),Vector2(11,-13),Vector2(7,-5),Vector2(-8,-5)],s,c)
            for a in [-0.8,0.0,0.8]:
                var v := Vector2(sin(a), -cos(a))
                draw_line(c + v*18.0*s,c+v*24.0*s,line_color,2.1*s,true)
        "map":
            _stroke([Vector2(-18,-13),Vector2(-6,-17),Vector2(7,-11),Vector2(18,-15),Vector2(18,13),Vector2(6,17),Vector2(-7,11),Vector2(-18,15),Vector2(-18,-13)],s,c)
            _stroke([Vector2(-6,-17),Vector2(-7,11)],s,c)
            _stroke([Vector2(7,-11),Vector2(6,17)],s,c)
        "pause":
            draw_rect(Rect2(c+Vector2(-10,-13)*s,Vector2(6,26)*s),line_color)
            draw_rect(Rect2(c+Vector2(4,-13)*s,Vector2(6,26)*s),line_color)
        "play":
            var p := PackedVector2Array([c+Vector2(-7,-14)*s,c+Vector2(15,0)*s,c+Vector2(-7,14)*s])
            draw_colored_polygon(p,line_color)
        "volume":
            _stroke([Vector2(-17,-7),Vector2(-8,-7),Vector2(1,-15),Vector2(1,15),Vector2(-8,7),Vector2(-17,7),Vector2(-17,-7)],s,c)
            draw_arc(c+Vector2(0,0),13*s,-1.0,1.0,15,line_color,2*s,true)
        "back":
            _stroke([Vector2(-5,-13),Vector2(-18,0),Vector2(-5,13)],s,c)
            _stroke([Vector2(-18,0),Vector2(16,0)],s,c)
        "gear":
            draw_arc(c,11*s,0,TAU,32,line_color,2.3*s,true)
            draw_circle(c,3*s,line_color)
            for k in range(8):
                var a := float(k) * TAU / 8.0
                draw_line(c+Vector2(cos(a),sin(a))*14*s,c+Vector2(cos(a),sin(a))*20*s,line_color,2.5*s,true)
        "compass":
            draw_arc(c,15*s,0,TAU,40,line_color,2*s,true)
            _stroke([Vector2(-6,9),Vector2(4,-11),Vector2(9,-4),Vector2(-6,9)],s,c)
        "tank":
            _stroke([Vector2(-7,-13),Vector2(7,-13),Vector2(11,-8),Vector2(11,13),Vector2(6,17),Vector2(-6,17),Vector2(-11,13),Vector2(-11,-8),Vector2(-7,-13)],s,c)
            _stroke([Vector2(-5,-18),Vector2(5,-18)],s,c)
        "clock":
            draw_arc(c,15*s,0,TAU,40,line_color,2.2*s,true)
            _stroke([Vector2(0,-10),Vector2(0,0),Vector2(9,4)],s,c)
        "depth":
            _stroke([Vector2(0,-17),Vector2(0,14)],s,c)
            _stroke([Vector2(-8,6),Vector2(0,14),Vector2(8,6)],s,c)
            _stroke([Vector2(-12,-12),Vector2(-17,-12),Vector2(-17,13)],s,c)
        "close":
            _stroke([Vector2(-12,-12),Vector2(12,12)],s,c)
            _stroke([Vector2(12,-12),Vector2(-12,12)],s,c)
        "target":
            draw_arc(c,14*s,0,TAU,40,line_color,2*s,true)
            draw_arc(c,5*s,0,TAU,26,line_color,2*s,true)
            _stroke([Vector2(-22,0),Vector2(-12,0)],s,c)
            _stroke([Vector2(12,0),Vector2(22,0)],s,c)
        _:
            draw_arc(c,14*s,0,TAU,32,line_color,2*s,true)

func _stroke(vertices: Array[Vector2], scale: float, center: Vector2) -> void:
    for i in range(1, vertices.size()):
        draw_line(center + vertices[i - 1] * scale, center + vertices[i] * scale,line_color,2.4*scale,true)
