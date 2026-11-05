extends SceneTree

const Strip = preload("res://scripts/drag_strip.gd")
const Night = preload("res://scripts/drag_night.gd")
const Lamps = preload("res://scripts/vehicle_lights.gd")
const HUD = preload("res://scripts/drag_hud.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280,720)
    var strip = Strip.new()
    strip.dual_lanes = true
    root.add_child(strip)
    await process_frame
    var night = strip.get_node("NightPresentation")
    var world = night.find_children("*","WorldEnvironment",true,false)[0]
    check(world.environment.background_color.srgb_to_linear().get_luminance()<0.02 and world.environment.ambient_light_energy<0.5,"The real drag scene uses a dark night environment with restrained ambient light")
    check(night.find_children("*","CollisionObject3D",true,false).is_empty(),"Night scenery creates no obstacles or changes to the physical racing surface")
    check(night.pool.size()==4 and night.find_children("*","OmniLight3D",true,false).size()==4,"Only four track point lights exist across the complete strip")
    var first: Vector3 = night.pool[0].position
    for z in [-100.0,-402.336,-680.0]:
        night.update_focus(z)
        var illuminated := false
        for light in night.pool:
            check(not light.shadow_enabled and is_equal_approx(light.position.y,Night.LAMP_HEIGHT-0.3),"Nearby track lamps avoid per-light shadow maps")
            illuminated = illuminated or absf(light.position.z-z)<Night.SPACING
        check(illuminated,"The moving pool lights the finish and runoff as well as the start")
    check(first!=night.pool[0].position,"Street lights follow progress between fixed posts")
    var solid := strip.find_children("*","StaticBody3D",true,false)
    check(solid.size()==4,"The original ground, two side barriers and runoff barrier remain physical")
    check(strip.lamps.size()==5 and strip.opponent_lamps.size()==5,"Both real starter lane signals remain present at night")
    var lights = Lamps.new()
    root.add_child(lights)
    await process_frame
    var idle: float = lights.rear_material.emission_energy_multiplier
    lights.set_brake(1.0)
    check(lights.rear_material.emission_energy_multiplier>idle and lights.brake_pool.visible and lights.beam.spot_range>=40.0,"Actual brake input brightens the rear lamps and reflected red pool while headlights illuminate ahead")
    var hud = HUD.new()
    root.add_child(hud)
    await process_frame
    hud.instruments.readings(120.0,4000.0,6500.0)
    check(hud.instruments.speed_kmh==120.0 and hud.instruments.rpm==4000.0 and hud.instruments.redline==6500.0,"Both analog instruments consume speed and RPM independently with the car's limiter")
    var viewport := Rect2(Vector2.ZERO,Vector2(1280,720))
    check(viewport.encloses(hud.speed_panel.get_global_rect()) and hud.speed_panel.get_global_rect().get_area()<viewport.get_area()*0.05,"Both dials fit in under five percent of the racing screen")
    check(not hud.speed_panel.get_global_rect().intersects(Rect2(400,130,450,390)),"The analog instrument panel leaves the central road view free")
    strip.queue_free()
    lights.queue_free()
    hud.queue_free()
    await process_frame
    if not failed: print("PASS: %d night drag presentation assertions" % checks)
    quit(1 if failed else 0)
