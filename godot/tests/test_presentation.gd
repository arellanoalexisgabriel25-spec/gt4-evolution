extends SceneTree

const Map = preload("res://scripts/city_map.gd")
const Preview = preload("res://scripts/car_preview.gd")
const HUD = preload("res://scripts/race_hud.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func settle() -> void:
    for i in range(5):
        await process_frame

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    change_scene_to_file("res://scenes/main.tscn")
    await settle()
    var menu = current_scene
    check(menu.current_tab == "inicio" and menu.nav_buttons.size() == 8,"The game opens on the new home with all existing services accessible")
    var map
    for child in menu.content.get_children():
        if child.get_script() == Map:
            map = child
    check(map != null,"The home includes the original navigable city map")
    if map != null:
        var services: Array = map.find_children("*","Button",true,false)
        check(services.size() == 5,"The city map has five functional service destinations")
        for button in services:
            check(map.get_global_rect().encloses(button.get_global_rect()),"A service card fits within the visible map")
        check(root.get_visible_rect().encloses(map.get_global_rect()),"The complete home map fits at the default 1280×720 viewport")
        check(map.get_parent().get_parent().get_global_rect().encloses(map.get_global_rect()),"Home services are fully visible within the actual scrolling viewport")
        services[0].pressed.emit()
        await settle()
        check(menu.current_tab == "mercado","A map destination opens the existing dealership")
    var grid: Node
    for child in menu.content.get_children():
        if child is GridContainer:
            grid = child
    check(grid is GridContainer and grid.get_child_count() == 13,"The dealership retains ten legacy offers and adds three flagship cars")
    var balance: int = session.game.balance
    var button_found := false
    if grid is GridContainer:
        for card in grid.get_children():
            if card.get_meta("vehicle_id",0)!=1:
                continue
            for button in card.find_children("*","Button",true,false):
                if button.text == "INSPECCIÓN " + preload("res://scripts/money.gd").format(200):
                    button.pressed.emit()
                    button_found = true
                    break
    await settle()
    check(button_found and session.game.balance == balance-200 and bool(session.game.find_car(1)["inspected"]),"Inspecting from a redesigned card still applies the real economic transaction")
    session.game.buy(1)
    menu.nav_buttons["garaje"].pressed.emit()
    await settle()
    var preview_found := false
    for child in menu.content.get_children():
        if child.get_script() == Preview:
            preview_found = child.model_name == session.game.find_car(1)["model"]
    check(preview_found,"The garage presents the owned vehicle with the original 3D preview")
    session.career.license = "B"
    menu._render()
    check(menu.license_badge.text.ends_with("B"),"The new header refreshes when career license changes")
    for tab in ["carrera","taller","tuning","historial","ajustes","inicio"]:
        menu.nav_buttons[tab].pressed.emit()
        await settle()
        check(menu.current_tab == tab and menu.content.get_child_count() > 0,"Sidebar navigation retains service: "+tab)
    check(HUD.format_time(59.9999) == "1:00.000" and HUD.format_time(64.75876) == "1:04.759","Racing clock rounds across minute boundaries correctly")
    session.start_driving(1)
    change_scene_to_file("res://scenes/driving.tscn")
    await settle()
    var scene = current_scene
    var hud = scene.hud
    check(hud.track_map.route.size() == scene.circuit.points.size()+1,"Minimap closes the same original route used by physics and timing")
    check(hud.track_map.positions[0].is_equal_approx(scene.car.global_position),"Minimap player marker reads the actual vehicle world position")
    var start: Vector2 = hud.track_map.map_point(scene.circuit.points[0])
    var opposite: Vector2 = hud.track_map.map_point(scene.circuit.sample(scene.circuit.length/2.0))
    check(start.distance_to(opposite) > 40.0 and Rect2(Vector2.ZERO,hud.track_map.size).has_point(start),"Minimap preserves distinct locations within its displayed bounds")
    check(root.get_visible_rect().encloses(hud.speed_label.get_global_rect()),"Speed readout remains inside the bottom-right of the rendered viewport")
    check(root.get_visible_rect().encloses(hud.time_label.get_global_rect()),"Lap timer remains visible at the top centre")
    scene.physics.gear = -1
    scene.physics.rpm = 4200
    scene.physics.velocity = Vector2(0,10)
    scene._refresh_hud()
    check(hud.gear_label.text == "R" and hud.speed_label.text == "36" and hud.rpm_label.text.contains("4200"),"The compact HUD uses actual reverse gear, ground speed and engine RPM")
    scene._cycle_camera()
    scene._refresh_hud()
    check(hud.camera_label.text == scene.camera.MODES[scene.camera.mode],"The HUD reports the active camera mode")
    scene.set_physics_process(false)
    scene.car.recover(scene.circuit.points[0]+Vector3.UP*0.75)
    scene.car.physics.velocity = Vector2(0,-10)
    scene.car.drive(1.0/60.0,{"throttle":-1.0},true)
    check(scene.car.visual.brake_material.emission_energy_multiplier > 1.0,"Reverse pedal illuminates brake lights while slowing forward travel")
    scene.car.drive(1.0/60.0,{"throttle":0.0},true)
    check(scene.car.visual.brake_material.emission_energy_multiplier < 1.0,"Brake lights return to running intensity when the brake is released")
    scene.car.drive(0.1,{"throttle":0.0,"steer":1.0},true)
    check(absf(scene.car.visual.front_pivots[0].rotation.y)>0.01 and absf(scene.car.visual.wheels[0].rotation.x)>0.01,"Vehicle geometry animates the real steering angle and travelled wheel motion")
    if not failed:
        print("PASS: %d presentation integration assertions" % checks)
    quit(1 if failed else 0)
