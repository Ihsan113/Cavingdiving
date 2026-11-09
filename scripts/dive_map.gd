extends Control
class_name DiveMap

# Offline cartographic navigation display. Shows a fictional surveyed centerline.
# Small display uses a moving local window; full display shows the entire route.
var route: PackedVector3Array = PackedVector3Array()
var branches: Array[PackedVector3Array] = []
var discovered_branches: Array[bool] = []
var diver_position: Vector3 = Vector3.ZERO
var diver_yaw: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var large: bool = false
var show_player: bool = true
var checkpoints: Array[Vector3] = []
var recorded_sites: int = 0

func _ready() -> void:
    clip_contents = true

func _draw() -> void:
    if size.x < 10 or size.y < 10:
        return
    var r := Rect2(Vector2.ZERO,size)
    draw_rect(r,Color(0.027,0.083,0.104,0.97),true)
    draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(0.20,0.43,0.45,0.6),false,1.5)
    var top_margin := 46.0 if large else 25.0
    var bottom_margin := 110.0 if large else 13.0
    var inner := Rect2(Vector2(13,top_margin),size - Vector2(26,top_margin+bottom_margin))
    draw_rect(inner,Color(0.012,0.055,0.078,0.95),true)
    for i in range(1,9):
        var gx := inner.position.x + inner.size.x * float(i) / 9.0
        draw_line(Vector2(gx,inner.position.y),Vector2(gx,inner.end.y),Color(0.19,0.39,0.40,0.17),1.0)
    for i in range(1,9):
        var gy := inner.position.y + inner.size.y * float(i) / 9.0
        draw_line(Vector2(inner.position.x,gy),Vector2(inner.end.x,gy),Color(0.19,0.39,0.40,0.17),1.0)
    var font := ThemeDB.fallback_font
    draw_string(font,Vector2(15,26 if large else 17),"SURVEY / NAVIGATION" if large else "SONAR  //  LOCAL",HORIZONTAL_ALIGNMENT_LEFT,-1,17 if large else 12,Color(0.60,0.90,0.90))
    if route.size() < 2:
        return
    var min_x := INF
    var max_x := -INF
    var min_z := INF
    var max_z := -INF
    for p in route:
        min_x = minf(min_x,p.x)
        max_x = maxf(max_x,p.x)
        min_z = minf(min_z,p.z)
        max_z = maxf(max_z,p.z)
    for branch in branches:
        for p in branch:
            min_x = minf(min_x,p.x)
            max_x = maxf(max_x,p.x)
            min_z = minf(min_z,p.z)
            max_z = maxf(max_z,p.z)
    var scale := 0.0
    var origin := Vector2.ZERO
    if large:
        scale = minf(inner.size.x/maxf(12.0,(max_x-min_x)*2.7+18.0),inner.size.y/maxf(12.0,max_z-min_z+18.0))
        origin = inner.get_center() - Vector2((min_x+max_x)*1.35,(min_z+max_z)*0.5)*scale
    else:
        scale = 2.6
        origin = inner.get_center() - Vector2(diver_position.x,diver_position.z)*scale
    var sideways := 2.7 if large else 1.0
    var previous := Vector2.ZERO
    for i in range(route.size()):
        var p := route[i]
        var point := origin+Vector2(p.x*sideways,p.z)*scale
        if i>0:
            var segment := point-previous
            # Main passage is broad and naturally varied, with a crisp guideline center.
            draw_line(previous,point,Color(0.15,0.33,0.35,0.56),17 if large else 13,true)
            draw_line(previous,point,Color(0.31,0.54,0.54,0.48),9 if large else 7,true)
            draw_line(previous,point,Color(0.47,0.83,0.82,0.91),2.3 if large else 1.8,true)
        previous = point
    # Off-line galleries are drawn differently from the fixed yellow guideline.
    # The local map reveals a gallery only after its entrance is discovered.
    for branch_index in branches.size():
        var known := not show_player or (branch_index < discovered_branches.size() and discovered_branches[branch_index])
        if not known:
            continue
        var branch := branches[branch_index]
        var last_point := Vector2.ZERO
        for segment_index in branch.size():
            var bp := branch[segment_index]
            var point2 := origin+Vector2(bp.x*sideways,bp.z)*scale
            if segment_index>0:
                draw_line(last_point,point2,Color(0.74,0.48,0.27,0.28),12 if large else 6,true)
                var vector := point2-last_point
                var length := vector.length()
                if length>0.1:
                    var tangent := vector/length
                    for pixel in range(0,int(length),13 if large else 10):
                        var p0 := last_point+tangent*float(pixel)
                        var p1 := last_point+tangent*minf(length,float(pixel+5))
                        draw_line(p0,p1,Color(1,0.68,0.32,0.81),2 if large else 1.4,true)
            last_point = point2
    for i in checkpoints.size():
        var p := origin+Vector2(checkpoints[i].x*sideways,checkpoints[i].z)*scale
        draw_circle(p,5.2 if large else 3.7,Color(0.40,0.98,0.75) if i < recorded_sites else Color(1.0,0.69,0.31))
        if large:
            draw_arc(p,9,0,TAU,24,Color(1.0,0.78,0.45,0.66),1.4)
    var target := origin+Vector2(target_position.x*sideways,target_position.z)*scale
    draw_arc(target,10 if large else 6,0,TAU,24,Color(1.0,0.69,0.30,0.95),1.7)
    if show_player:
        var player := origin+Vector2(diver_position.x*sideways,diver_position.z)*scale
        draw_circle(player,6.0 if large else 5,Color(0.78,0.99,1.0))
        var vec := Vector2(-sin(diver_yaw),-cos(diver_yaw))
        draw_line(player,player+vec*(15 if large else 12),Color(0.95,1.0,1.0),2.3,true)
        draw_arc(player,10 if large else 8,0,TAU,30,Color(0.35,0.94,0.96,0.38),1.3)
    # Opaque bands keep local-map lines from drawing over title and legend.
    draw_rect(Rect2(Vector2.ZERO,Vector2(size.x,top_margin-1)),Color(0.027,0.083,0.104,0.97),true)
    draw_rect(Rect2(Vector2(0,size.y-bottom_margin),Vector2(size.x,bottom_margin)),Color(0.027,0.083,0.104,0.97),true)
    draw_string(font,Vector2(15,26 if large else 17),"SURVEY / NAVIGATION" if large else "SONAR  //  LOCAL",HORIZONTAL_ALIGNMENT_LEFT,-1,17 if large else 12,Color(0.60,0.90,0.90))
    if large:
        _draw_vertical_profile(font,Rect2(Vector2(15,size.y-91),Vector2(size.x-30,76)))
        draw_string(font,Vector2(15,size.y-14),"CYAN: MAIN LINE  /  ORANGE DASH: UNMARKED SIDE GALLERY  /  BELOW: DEPTH",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.63,0.78,0.79))
    draw_string(font,Vector2(size.x-40,26 if large else 17),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,16 if large else 12,Color(0.88,0.93,0.82))
    draw_line(Vector2(size.x-30,34 if large else 23),Vector2(size.x-30,40 if large else 27),Color(0.88,0.93,0.82),1.5)

func _draw_vertical_profile(font: Font, plot: Rect2) -> void:
    if route.size()<2:
        return
    draw_rect(plot,Color(0.015,0.075,0.091,1.0),true)
    draw_rect(plot,Color(0.22,0.46,0.49,0.67),false,1.0)
    var total := 0.0
    for idx in range(1,route.size()):
        total += route[idx].distance_to(route[idx-1])
    var maximum := 1.0
    for p in route:
        maximum = maxf(maximum,-p.y)
    var progress := 0.0
    var prev := Vector2(plot.position.x,plot.position.y+(-route[0].y)/maximum*plot.size.y)
    var point := prev
    for i in range(1,route.size()):
        progress += route[i].distance_to(route[i-1])
        point = Vector2(plot.position.x+plot.size.x*progress/maxf(total,1.0),plot.position.y+(-route[i].y)/maximum*plot.size.y)
        draw_line(prev,point,Color(0.56,0.92,0.88),2.0,true)
        if absf(route[i].y-route[i-1].y)>10.0:
            draw_circle(point,3.2,Color(1.0,0.76,0.37))
        prev=point
    draw_string(font,plot.position+Vector2(7,14),"VERTICAL PROFILE  /  0 to %dm" % int(ceilf(maximum)),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.88,0.94,0.94))
    if show_player:
        var closest := 0
        var best := INF
        for i in route.size():
            var d := route[i].distance_squared_to(diver_position)
            if d < best:
                best = d
                closest = i
        var walked := 0.0
        for j in range(1,closest+1):
            walked += route[j].distance_to(route[j-1])
        var x := plot.position.x+walked/maxf(1.0,total)*plot.size.x
        var y := plot.position.y+(-diver_position.y)/maximum*plot.size.y
        draw_circle(Vector2(x,y),4.0,Color.WHITE)
