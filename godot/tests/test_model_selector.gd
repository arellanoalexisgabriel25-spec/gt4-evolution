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
    check(selector.item_count==29,"The selector retains all ten legacy and nineteen supplied models")
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
    if not failed: print("PASS: %d model selector assertions" % checks)
    quit(1 if failed else 0)
