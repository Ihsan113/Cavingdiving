extends SceneTree

# This runs in GitHub Actions AFTER Godot imports the project.
# It instantiates both sites, cave geometry, scripted HUD, tutorial and injury logic.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    if packed == null:
        push_error("Cannot load main scene")
        quit(1)
        return
    var game: Variant = packed.instantiate()
    root.add_child(game)
    game.site_index = 0
    game._create_underwater_world()
    var cave: Variant = game.cave
    if cave.branches.size() != 6 or cave.marker_positions.size() != 3:
        push_error("First site failed to instantiate network or beacons")
        quit(2)
        return
    if game.instructor == null:
        push_error("Instructor NPC missing")
        quit(3)
        return
    game._build_dive_hud()
    game._show_training(0)
    game._end_training()
    game.flow = 3
    game._on_sharp_rock_contact("ARMS",13.0)
    if float(game.body_health["ARMS"]) >= 100.0 or float(game.suit_integrity) >= 100.0:
        push_error("Sharp-rock injury did not affect health/suit")
        quit(4)
        return
    game._seal_suit()
    if game.patch_count != 1:
        push_error("Seal patch inventory logic failed")
        quit(5)
        return
    game._open_boat_world()
    game.site_index = 1
    game._create_underwater_world()
    if game.cave.branches.size() != 3 or game.cave.marker_positions.size() != 3:
        push_error("Second site regression")
        quit(6)
        return
    print("SMOKE DIVE PASSED: both cave networks, instructor, HUD, tutorial, rock collision and suit patch")
    quit(0)
