class_name DotInputVocab
extends RefCounted

## Converts between the two spellings of one binding. [DotInputActionSet] writes a binding as
## `device-prefix:name` (`key:F`, `mouse:1`, `pad:rt`, `pad:lx-`) because the prefix says which
## device owns it; [DotInputText] writes the word a person types in a settings file and reads on a
## rebinding button (`F`, `Mouse 1`, `Pad 0`, `Axis 5+`). Both exist for good reasons, so this is
## the one place that says how they correspond, rather than every caller guessing.
##
## [codeblock]
## DotInputVocab.to_text("key:F")      # "F"
## DotInputVocab.to_text("mouse:4")    # "Wheel up", as DotInputText.mouse_text(4)
## DotInputVocab.to_text("pad:a")      # "Pad 0"
## DotInputVocab.to_text("pad:rt")     # "Axis 5+"   (a trigger is an axis in Godot)
## DotInputVocab.to_text("pad:lx-")    # "Axis 0-"
## DotInputVocab.to_binding("Mouse 1") # "mouse:1"
## DotInputVocab.to_binding("Pad 0")   # "pad:a"
## [/codeblock]
##
## [b]Touch has no text form[/b] (`touch:fire` is a named on-screen button, not an event), so it
## converts to "" and back from nothing. [b]Unknown names convert to ""[/b] rather than being
## passed through, so a typo cannot reach an [InputMap] as a binding that never fires.

## Pad button names to [enum JoyButton] indices. `lt` and `rt` are not here: they are axes.
const PAD_BUTTONS := {
	"a": 0, "b": 1, "x": 2, "y": 3, "back": 4, "guide": 5, "start": 6, "ls": 7, "rs": 8,
	"lb": 9, "rb": 10, "dpad_up": 11, "dpad_down": 12, "dpad_left": 13, "dpad_right": 14,
}

## Pad axis names to [enum JoyAxis] indices: left stick x and y, right stick x and y, triggers.
const PAD_AXES := {"lx": 0, "ly": 1, "rx": 2, "ry": 3, "lt": 4, "rt": 5}


## A [DotInputActionSet] binding as [DotInputText] text, or "" when it has none.
static func to_text(binding: String) -> String:
	var colon := binding.find(":")
	if colon <= 0:
		return ""

	var prefix := binding.substr(0, colon)
	var body := binding.substr(colon + 1).strip_edges()
	if body.is_empty():
		return ""

	match prefix:
		"key":
			return body if DotInputText.is_bound(body) else ""
		"mouse":
			return DotInputText.mouse_text(body.to_int()) if body.is_valid_int() and body.to_int() > 0 else ""
		"pad":
			return _pad_text(body.to_lower())
	return ""


## [DotInputText] text as a [DotInputActionSet] binding, or "" when it names nothing.
static func to_binding(text: String) -> String:
	var event := DotInputText.from_text(text)
	if event is InputEventKey:
		return "key:" + DotInputText.to_text(event)
	if event is InputEventMouseButton:
		return "mouse:%d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index
		var button = PAD_BUTTONS.find_key(int(index))
		return "" if button == null else "pad:" + str(button)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var name = PAD_AXES.find_key(int(motion.axis))
		if name == null:
			return ""
		var positive := motion.axis_value > 0.0
		# A trigger only goes one way, so it has no sign in the binding, and no negative.
		if int(motion.axis) >= 4:
			return "pad:" + str(name) if positive else ""
		return "pad:" + str(name) + ("+" if positive else "-")
	return ""


static func _pad_text(body: String) -> String:
	if PAD_BUTTONS.has(body):
		return "Pad %d" % int(PAD_BUTTONS[body])

	if PAD_AXES.has(body):
		# "rt" alone: a trigger is one-directional, always positive.
		return "Axis %d+" % int(PAD_AXES[body]) if int(PAD_AXES[body]) >= 4 else ""

	var sign := body.right(1)
	var stem := body.left(body.length() - 1)
	if (sign == "+" or sign == "-") and PAD_AXES.has(stem):
		return "Axis %d%s" % [int(PAD_AXES[stem]), sign]

	return ""
