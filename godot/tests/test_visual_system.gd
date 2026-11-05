extends SceneTree
const Style = preload("res://scripts/racing_theme.gd")
const Map = preload("res://scripts/city_map.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)
func settle() -> void:
    for frame in range(8): await process_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var theme: Theme=Style.build()
    check(theme.default_font==Style.BODY and theme.get_font("font","Button")==Style.FONT,"Global typography distinguishes regular body text and semibold controls")
    var panel: StyleBoxFlat=theme.get_stylebox("panel","PanelContainer")
    check(panel.bg_color==Color("1a2129") and panel.border_color==Color("2e3845") and panel.border_width_left==1 and panel.corner_radius_top_left==6,"Shared cards follow the supplied dark palette with subtle borders")
    check(theme.get_stylebox("normal","PrimaryButton").bg_color==Color("3a7ca5") and theme.get_stylebox("hover","PrimaryButton").bg_color==Color("5ba3d0"),"Primary interactions use the steel-blue normal and hover colors")
    check(theme.get_color("font_hover_color","PrimaryButton")==Style.BACKGROUND,"The bright hover state retains readable dark text")
    check(theme.get_stylebox("focus","Button").border_color==Style.HOVER,"Keyboard and controller focus remain visible against dark cards")
    check(Style.navigation(true).border_width_left==3 and Style.navigation(false).border_width_left==0,"Selected services have a persistent slim left marker")
    check(theme.get_color("font_color","PopupMenu")==Style.TEXT and theme.get_stylebox("panel","PopupMenu").bg_color==Style.ELEVATED,"Selectors inherit a readable dark popup instead of a mismatched default")
    check(theme.get_stylebox("normal","LineEdit").bg_color==Style.BACKGROUND and theme.get_stylebox("selected","ItemList").border_color==Style.HOVER,"Input and list states use the same visual system")
    check(theme.get_stylebox("fill","ProgressBar").bg_color==Style.ACCENT and theme.get_stylebox("tab_selected","TabBar").border_width_bottom==2,"Progress and tabs retain thin consistent accents")
    check(is_equal_approx(Style.MONO.get_string_size("1111",HORIZONTAL_ALIGNMENT_LEFT,-1,20).x,Style.MONO.get_string_size("8888",HORIZONTAL_ALIGNMENT_LEFT,-1,20).x),"HUD digits have identical advance widths and do not jitter as their values change")
    var session=root.get_node("GameSession")
    session.reset()
    change_scene_to_file("res://scenes/main.tscn")
    await settle()
    var menu=current_scene
    check(menu.get_child(0) is ColorRect and menu.get_child(0).color==Style.BACKGROUND,"The actual main scene adopts the charcoal background")
    check(menu.funds.get_theme_font("font")==Style.MONO,"The real ARS balance uses aligned numeric typography")
    for dimensions in [Vector2i(1280,720),Vector2i(1280,800)]:
        root.size=dimensions
        menu._change_tab("inicio")
        await settle()
        var city
        for child in menu.content.get_children():
            if child.get_script()==Map: city=child
        var visible_rect: Rect2=root.get_visible_rect()
        check(city!=null and visible_rect.encloses(city.get_global_rect()),"The complete service map remains visible at "+str(dimensions))
        check(visible_rect.encloses(menu.funds.get_global_rect()) and visible_rect.encloses(menu.license_badge.get_global_rect()),"Header balance and license fit at "+str(dimensions))
        if city!=null:
            for button in city.buttons:
                check(city.get_global_rect().encloses(button.get_global_rect()),"Service cards remain inside the responsive dark map at "+str(dimensions))
    root.size=Vector2i(1280,720)
    session.game.buy(11)
    for page in ["mercado","garaje","taller","tuning","carrera","historial","ajustes"]:
        menu._change_tab(page)
        await settle()
        check(menu.current_tab==page and menu.content.get_child_count()>0 and menu.theme.get_color("font_color","Label")==Style.TEXT,"An existing service remains functional under the shared theme: "+page)
    session.start_drag(11)
    change_scene_to_file("res://scenes/drag.tscn")
    await settle()
    var scene=current_scene
    scene.set_physics_process(false)
    check(scene.hud.gear_label.get_theme_font("font")==Style.MONO and scene.hud.speed_label.get_theme_font("font")==Style.MONO and scene.hud.clock_label.get_theme_font("font")==Style.MONO,"Actual racing instruments use the shared monospace data font")
    check(scene.hud.speed_panel.get_theme_stylebox("panel").bg_color.a<0.8 and not scene.hud.details_panel.visible,"The new palette preserves the compact translucent racing HUD")
    for dimensions in [Vector2i(1280,720),Vector2i(1280,800)]:
        root.size=dimensions
        await settle()
        var visible_rect: Rect2=root.get_visible_rect()
        check(visible_rect.encloses(scene.hud.speed_panel.get_global_rect()) and visible_rect.encloses(scene.hud.preparation_panel.get_global_rect()),"Preparation and speed panels fit both supported aspect ratios: "+str(dimensions))
    if not failed: print("PASS: %d visual system assertions" % checks)
    quit(1 if failed else 0)
