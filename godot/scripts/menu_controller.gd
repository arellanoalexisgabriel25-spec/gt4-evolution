extends Node

var page: Control
var initial_focus: Control
var back_action: Callable
var tab_action: Callable
var repeat_left := 0.0
var last_direction := Vector2i.ZERO
var start_is_back := false

func _direction() -> Vector2i:
    var pad = GameSession.controls.controller
    var x: float = pad.axis_value(JOY_AXIS_LEFT_X)
    var y: float = pad.axis_value(JOY_AXIS_LEFT_Y)
    if pad.pressed(JOY_BUTTON_DPAD_LEFT): x = -1
    if pad.pressed(JOY_BUTTON_DPAD_RIGHT): x = 1
    if pad.pressed(JOY_BUTTON_DPAD_UP): y = -1
    if pad.pressed(JOY_BUTTON_DPAD_DOWN): y = 1
    if maxf(absf(x),absf(y))<0.55:
        return Vector2i.ZERO
    return Vector2i(signi(int(signf(x))),0) if absf(x)>absf(y) else Vector2i(0,signi(int(signf(y))))

func _process(delta: float) -> void:
    if page==null or not page.is_visible_in_tree():
        last_direction = Vector2i.ZERO
        return
    var direction := _direction()
    repeat_left = maxf(0,repeat_left-delta)
    if direction==Vector2i.ZERO:
        last_direction = direction
        return
    if direction!=last_direction or repeat_left==0:
        _move(direction)
        repeat_left = 0.30 if direction!=last_direction else 0.12
    last_direction = direction

func _focus() -> Control:
    var focused := page.get_viewport().gui_get_focus_owner()
    if focused==null or not page.is_ancestor_of(focused):
        if is_instance_valid(initial_focus):
            initial_focus.grab_focus()
            return initial_focus
    return focused

func _move(direction: Vector2i) -> void:
    var focused := _focus()
    if focused==null:
        return
    if direction.x!=0 and focused is Range:
        focused.value += float(direction.x)*focused.step
        return
    if direction.x!=0 and focused is OptionButton:
        _option(focused,direction.x)
        return
    var side := SIDE_RIGHT if direction.x>0 else (SIDE_LEFT if direction.x<0 else (SIDE_BOTTOM if direction.y>0 else SIDE_TOP))
    var next := focused.find_valid_focus_neighbor(side)
    if next!=null and page.is_ancestor_of(next):
        next.grab_focus()

func _option(button: OptionButton, direction: int) -> void:
    var selected := wrapi(button.selected+direction,0,button.item_count)
    button.select(selected)
    button.item_selected.emit(selected)

func _input(event: InputEvent) -> void:
    if page==null or not page.is_visible_in_tree() or not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
        return
    # A button can detach this page immediately by changing scenes. Consume the
    # event before its callback; querying the detached page's viewport is invalid.
    var viewport := page.get_viewport()
    if viewport==null:
        return
    viewport.set_input_as_handled()
    var fresh: bool = GameSession.controls.controller.feed(event)
    if event is InputEventJoypadButton and fresh:
        if event.button_index==JOY_BUTTON_A:
            var focused := _focus()
            if focused is OptionButton:
                _option(focused,1)
            elif focused is BaseButton and not focused.disabled:
                if focused.toggle_mode:
                    focused.button_pressed = not focused.button_pressed
                focused.pressed.emit()
        elif (event.button_index==JOY_BUTTON_B or (start_is_back and event.button_index in [JOY_BUTTON_START,JOY_BUTTON_BACK])) and back_action.is_valid():
            back_action.call()
        elif event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER] and tab_action.is_valid():
            tab_action.call(-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1)
    # Consume releases too: accepting A must never activate the same button again
    # through Godot's default ui_accept action after rebuilding a menu.
