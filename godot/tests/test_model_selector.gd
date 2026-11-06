extends SceneTree
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var session=root.get_node("GameSession")
    session.reset()
    session.game.buy(1)
    var balance: int=session.game.balance
    change_scene_to_file("res://scenes/main.tscn")
    for i in range(3): await process_frame
    var menu=current_scene
    var selectors: Array=menu.content.find_children("*","OptionButton",true,false)
    check(selectors.size()==1,"Home offers one coherent model selector")
    if selectors.is_empty(): quit(1); return
    var selector: OptionButton=selectors[0]
    check(selector.item_count==37,"The selector retains all 36 drivable models and adds a separate Taos exhibition")
    check(selector.get_item_text(selector.selected)==session.game.find_car(1).model,"A selected owned legacy car matches its title and preview")
    var next := -1
    for index in range(selector.item_count):
        if selector.get_item_text(index)=="Fiat 500 Sport": next=index
    check(next>=0,"The new supplied Sport is selectable alongside the legacy owned car")
    if next>=0: selector.item_selected.emit(next)
    for i in range(3): await process_frame
    selectors=menu.content.find_children("*","OptionButton",true,false)
    check(menu.home_featured=="Fiat 500 Sport" and selectors[0].get_item_text(selectors[0].selected)=="Fiat 500 Sport","Choosing a new car updates preview and selector together")
    check(session.game.balance==balance and session.game.find_car(1).owner=="player" and session.game.find_car(23).owner=="seller","Viewing another model does not buy, sell or alter existing ownership")
    menu._feature("Volkswagen Taos")
    for i in range(3): await process_frame
    selectors=menu.content.find_children("*","OptionButton",true,false)
    check(selectors[0].get_item_text(selectors[0].selected)=="Volkswagen Taos","The exhibition model updates both selector and actual preview")
    var previews=menu.content.find_children("*","SubViewportContainer",true,false)
    check(previews.size()==1 and previews[0].model_name=="Volkswagen Taos","The gallery instantiates the supplied Taos instead of silently showing the last drivable car")
    var race_action:=false
    for button in menu.content.find_children("*","Button",true,false):
        if button.text.contains("DUELO"): race_action=true
    check(not race_action and not session.start_drag(1,"duel","technical","","Volkswagen Taos"),"A visual-only model cannot silently become a fictitious factory rival")
    check(session.game.balance==balance,"Exhibition does not charge or change the player's economy")
    if not failed: print("PASS: %d model selector assertions" % checks)
    quit(1 if failed else 0)
