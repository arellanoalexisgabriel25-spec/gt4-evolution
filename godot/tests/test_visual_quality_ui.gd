extends SceneTree
var checks:=0
var failed:=false
func check(ok:bool,message:String)->void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
    var session=root.get_node("GameSession")
    session.reset()
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    var menu=current_scene
    menu.controls_path="user://quality-ui-test.json"
    menu._change_tab("ajustes")
    await process_frame
    var option=menu.content.find_child("VisualQuality",true,false)
    check(option!=null and option.item_count==3,"Settings expose three actual graphics quality choices")
    for i in range(3):
        option.select(i)
        option.item_selected.emit(i)
        await process_frame
        check(session.controls.visual_quality==session.controls.VISUAL_QUALITIES[i] and root.msaa_3d==session.controls.msaa_level(),"A selection applies the current preference to the real game viewport")
        menu._change_tab("inicio")
        await process_frame
        var previews=menu.content.find_children("*","SubViewportContainer",true,false)
        check(previews.size()==1 and previews[0].viewport.msaa_3d==root.msaa_3d,"The new showroom inherits the selected antialiasing level")
        menu._change_tab("ajustes")
        await process_frame
        option=menu.content.find_child("VisualQuality",true,false)
        check(option.selected==i,"Returning to settings preserves the selected quality")
    session.controls.restore_defaults()
    session.apply_visual_quality()
    DirAccess.remove_absolute(menu.controls_path)
    if not failed:print("PASS: %d visual quality UI assertions"%checks)
    quit(1 if failed else 0)
