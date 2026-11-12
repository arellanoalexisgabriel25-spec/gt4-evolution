extends SceneTree
var checks:=0
var failed:=false
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(why)
func _initialize() -> void: call_deferred("run")
func frames(n: int = 3) -> void:
    for i in range(n): await process_frame
func run() -> void:
    var session=root.get_node("GameSession")
    session.reset()
    session.game.balance=100000
    change_scene_to_file("res://scenes/main.tscn")
    await frames(5)
    var menu=current_scene
    menu._change_tab("mercado")
    await frames()
    var picker: OptionButton=menu.content.find_child("MarketBrandFilter",true,false)
    check(picker!=null and picker.item_count>2,"Market exposes an interactive brand filter")
    var fiat:=-1
    for i in range(picker.item_count):
        if picker.get_item_text(i)=="FIAT": fiat=i
    check(fiat>0,"The offered Fiat brand appears in the filter")
    picker.select(fiat)
    picker.item_selected.emit(fiat)
    await frames()
    var grid: GridContainer
    for child in menu.content.get_children():
        if child is GridContainer: grid=child
    var valid: bool = grid!=null and grid.get_child_count()>0
    if grid!=null:
        for card in grid.get_children():
            var id: int=int(card.get_meta("vehicle_id",0))
            valid=valid and str(session.game.find_car(id).model).begins_with("Fiat ")
    check(valid,"Brand filter shows only actual Fiat listings")
    var first=grid.get_child(0)
    var id: int=int(first.get_meta("vehicle_id",0))
    var before: int=session.game.balance
    var scroll: ScrollContainer = menu.content.get_parent()
    scroll.scroll_vertical = 500
    await frames()
    for button in first.find_children("*","Button",true,false):
        if button.text=="VER EN 3D":
            button.pressed.emit()
            break
    await frames()
    var preview=menu.content.find_child("MarketPreview",true,false)
    check(preview!=null and preview.model_name==session.game.find_car(id).model,"A listing opens its actual 3D model")
    check(scroll.scroll_vertical==0,"Opening a preview scrolls back to the visible model")
    check(session.game.balance==before and session.game.find_car(id).owner=="seller","Viewing a model never charges or buys it")
    check(session.game.buy(11).begins_with("Compraste"),"The player buys a real car for the workshop")
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part]=100.0
    menu._change_tab("tuning")
    await frames()
    var choice=menu.content.find_child("TuningVehicle",true,false)
    var tuning_preview=menu.content.find_child("TuningPreview",true,false)
    check(choice!=null and tuning_preview!=null and tuning_preview.model_name==session.game.find_car(11).model,"Tuning shows a selectable owned car and its 3D preview")
    var buy_turbo: Button
    for card in menu.content.find_children("*","PanelContainer",true,false):
        var labels=card.find_children("*","Label",true,false)
        for label in labels:
            if label.text.contains("Kit turbo de calle"):
                var buttons=card.find_children("*","Button",true,false)
                if not buttons.is_empty(): buy_turbo=buttons[0]
    check(buy_turbo!=null and not buy_turbo.disabled,"A compatible turbo can be installed through the actual tuning screen")
    before=session.game.balance
    if buy_turbo!=null: buy_turbo.pressed.emit()
    await frames()
    check(session.game.find_car(11).upgrades.has("turbo") and session.game.balance==before-3200,"The UI installs the turbo and charges exactly once")
    check(menu.content.find_child("TuningPreview",true,false)!=null,"The tuning preview remains after purchase")
    session.menu_music.set_menu_active(false)
    if not failed: print("PASS: %d market and tuning UI assertions"%checks)
    quit(1 if failed else 0)
