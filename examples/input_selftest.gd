extends Node

## dot-input's headless suite (res://examples/input_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error
## aborts a section and not the run.

const EXPECTED_SECTIONS := 6
const EXPECTED_CHECKS := 63

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("dot-input")
	_config()
	_declare()
	_rebind()
	_conflicts()
	_intent()
	_text_and_map()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _config() -> void:
	var c := DotInputConfig.new()
	_check(c.validate().ok, "defaults validate")
	_check(c.config_keys().size() >= 6, "every tunable is a config key", str(c.config_keys().size()))
	for k in ["gamepad_deadzone", "trigger_threshold", "conflict_policy", "max_bindings_per_action", "default_device", "enabled"]:
		_check(c.has_key(k), "key %s exists" % k)
	c.gamepad_deadzone = 1.0
	_check(not c.validate().ok, "a deadzone of 1 is refused")
	c.gamepad_deadzone = 0.2
	c.default_device = "wheel"
	_check(not c.validate().ok, "an unknown device is refused")
	c.default_device = "pad"
	c.max_bindings_per_action = -1
	_check(not c.validate().ok, "a negative limit is refused, 0 is the no-limit value")
	_check(c.describe().begins_with("input on"), "describe names the state")
	_sections += 1


func _declare() -> void:
	var s := DotInputActionSet.new()
	_check(s.declare(&"fire", "button", {"kbm": ["mouse:1"], "pad": ["pad:rt"]}).ok, "a button declares")
	_check(s.declare(&"move_x", "axis", {"pad": ["pad:lx+"]}).ok, "an axis declares")
	_check(not s.declare(&"fire", "button").ok, "a duplicate name is refused")
	_check(s.declare(&"fire", "button").error.code == DotError.CODE_CONFLICT, "and it is a conflict")
	_check(not s.declare(&"", "button").ok, "an empty name is refused")
	_check(not s.declare(&"x", "slider").ok, "an unknown kind is refused")
	_check(not s.declare(&"bad", "button", {"kbm": ["pad:a"]}).ok, "a pad binding on the keyboard is refused")
	_check(not s.has(&"bad"), "a failed declare leaves nothing behind")
	_check(s.bindings(&"fire", "kbm") == PackedStringArray(["mouse:1"]), "bindings read back")
	_check(s.bindings(&"fire", "touch").is_empty(), "an unbound device is empty")
	_check(DotInputActionSet.is_valid_binding("touch", "touch:fire") and not DotInputActionSet.is_valid_binding("touch", "touch:"), "an empty binding body is not valid")
	_check(s.names().size() == 2, "two actions declared")
	_sections += 1


func _rebind() -> void:
	var cfg := DotInputConfig.new()
	var s := DotInputActionSet.new()
	s.declare(&"jump", "button", {"kbm": ["key:Space"]})
	s.declare(&"crouch", "button", {"kbm": ["key:C"]})
	s.declare(&"menu_ok", "button", {"kbm": ["key:Space"]}, "menu")
	_check(s.rebind(&"crouch", "kbm", "key:X", cfg).ok and s.bindings(&"crouch", "kbm") == PackedStringArray(["key:X"]), "a free rebind replaces the binding")
	var r := s.rebind(&"crouch", "kbm", "key:Space", cfg)
	_check(not r.ok and r.error.code == DotError.CODE_CONFLICT, "a taken binding is refused by default")
	_check(s.bindings(&"crouch", "kbm") == PackedStringArray(["key:X"]), "a refused rebind changes nothing")
	_check(s.holders(&"crouch", "kbm", "key:Space") == [&"jump"], "other contexts do not count as holders")
	cfg.conflict_policy = DotInputConfig.CONFLICT_STEAL
	_check(s.rebind(&"crouch", "kbm", "key:Space", cfg).ok, "steal takes it")
	_check(s.bindings(&"jump", "kbm").is_empty() and s.bindings(&"menu_ok", "kbm").size() == 1, "from the holder in the same context only")
	var lim := DotInputConfig.new()
	lim.max_bindings_per_action = 1
	_check(not s.add_binding(&"crouch", "kbm", "key:Z", false, lim).ok, "a configured limit refuses a second binding")
	lim.max_bindings_per_action = 0
	_check(s.add_binding(&"crouch", "kbm", "key:Z", false, lim).ok, "0 is no limit")
	_check(not s.rebind(&"nope", "kbm", "key:Q", cfg).ok, "an undeclared action is refused")
	_sections += 1


func _conflicts() -> void:
	var s := DotInputActionSet.new()
	s.declare(&"a", "button", {"kbm": ["key:E"]})
	s.declare(&"b", "button", {"kbm": ["key:E", "key:R"]})
	s.declare(&"c", "button", {"kbm": ["key:E"]}, "menu")
	var found := DotInputConflicts.find(s, "kbm")
	_check(found.size() == 1, "one shared binding", str(found))
	_check(found[0]["binding"] == "key:E" and found[0]["actions"] == ["a", "b"], "it names both actions, not the other context")
	_check(DotInputConflicts.find(s, "pad").is_empty(), "a device with nothing bound has none")
	_sections += 1


func _intent() -> void:
	var cfg := DotInputConfig.new()
	var s := DotInputActionSet.new()
	s.declare(&"fire", "button")
	s.declare(&"move_x", "axis")
	_check(is_equal_approx(DotInputIntent.apply_deadzone(0.1, 0.2), 0.0), "inside the dead zone is zero")
	_check(is_equal_approx(DotInputIntent.apply_deadzone(1.0, 0.2), 1.0), "full deflection stays 1")
	_check(is_equal_approx(DotInputIntent.apply_deadzone(-0.6, 0.2), -0.5), "the rest rescales and keeps its sign")
	var t1 := DotInputIntent.sample(s, cfg, {&"fire": 1.0, &"move_x": 0.6}, null, 1)
	_check(t1.is_down(&"fire") and t1.pressed.has(&"fire"), "a fresh press is down and pressed")
	_check(is_equal_approx(t1.axis(&"move_x"), 0.5), "the axis is shaped")
	var t2 := DotInputIntent.sample(s, cfg, {&"fire": 1.0}, t1, 2)
	_check(t2.is_down(&"fire") and not t2.pressed.has(&"fire"), "a held button is not pressed again")
	var t3 := DotInputIntent.sample(s, cfg, {&"fire": 0.2}, t2, 3)
	_check(not t3.is_down(&"fire") and t3.released.has(&"fire"), "under the threshold releases")
	_check(t3.is_empty(), "nothing held is empty")
	cfg.enabled = false
	_check(DotInputIntent.sample(s, cfg, {&"fire": 1.0}, null, 4).is_empty(), "a disabled addon samples empty")
	var back := DotInputIntent.from_dict(t1.to_dict())
	_check(back.tick == 1 and back.is_down(&"fire") and is_equal_approx(back.axis(&"move_x"), 0.5), "an intent survives its dictionary")
	_sections += 1



func _text_and_map() -> void:
	_check(DotInputText.to_text(DotInputText.from_text("Y")) == "Y", "a key round-trips through text")
	_check(DotInputText.to_text(DotInputText.from_text("Shift+A")) == "Shift+A", "a modifier round-trips")
	_check(DotInputText.to_text(DotInputText.from_text("Mouse 1")) == "Mouse 1", "a mouse button round-trips")
	_check(DotInputText.to_text(DotInputText.from_text("Wheel up")) == "Wheel up", "the wheel keeps its name")
	var old_wheel := DotInputText.from_text("Mouse 4") as InputEventMouseButton
	_check(old_wheel != null and old_wheel.button_index == MOUSE_BUTTON_WHEEL_UP, "an old Mouse 4 still reads as the wheel")
	var side := DotInputText.from_text("mouse back") as InputEventMouseButton
	_check(side != null and side.button_index == MOUSE_BUTTON_XBUTTON1, "names are case-blind and beat the number parse")
	_check(DotInputText.to_text(DotInputText.from_text("Pad 3")) == "Pad 3", "a pad button round-trips")
	_check(DotInputText.to_text(DotInputText.from_text("Axis 1-")) == "Axis 1-", "an axis direction round-trips")
	_check(DotInputText.from_text("Qwerty") == null and DotInputText.from_text("") == null, "nonsense and empty name nothing")
	_check(not DotInputText.is_bound("Axis 1"), "an axis without a sign is not a binding")
	var a := &"dot_input_selftest_action"
	_check(DotInputMap.apply(a, "Y") == "Y" and DotInputMap.describe_action(a) == "Y", "apply creates the action")
	DotInputMap.apply(a, "U")
	_check(InputMap.action_get_events(a).size() == 1 and DotInputMap.describe_action(a) == "U", "apply replaces, never adds")
	_check(DotInputMap.ensure_action(a, "K") == "U", "ensure_action keeps an existing binding")
	_check(DotInputMap.apply(a, "Qwerty") == "" and InputMap.action_get_events(a).is_empty(), "text naming nothing leaves the action unbound")
	_check(DotInputMap.ensure_action(a, "K") == "K", "ensure_action binds an empty action")
	_check(DotInputMap.describe_action(&"dot_input_selftest_missing") == "", "a missing action describes as unbound")
	InputMap.erase_action(a)
	_sections += 1


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)
