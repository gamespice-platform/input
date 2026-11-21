class_name GSInputActionSet
extends RefCounted

## The declared actions of a game and what each device binds them to. Pure data: it never touches `InputMap`, so a server and a suite can hold one. A binding is a short string, `key:F`, `mouse:1`, `pad:a`, `pad:lx-`, `touch:fire`; the prefix says which device it belongs to.

const DEVICES := ["kbm", "pad", "touch"]
const KIND_BUTTON := "button"
const KIND_AXIS := "axis"

const _PREFIXES := {"kbm": ["key:", "mouse:"], "pad": ["pad:"], "touch": ["touch:"]}

var _kinds: Dictionary = {}
var _contexts: Dictionary = {}
var _bindings: Dictionary = {}


## Declares [param action]. [param defaults] maps a device to its binding strings. [param context] groups actions that must not share a binding (`move` and `menu` may reuse a key, two `move` actions may not).
func declare(action: StringName, kind: String, defaults: Dictionary = {}, context: String = "play") -> GSResult:
	if action == &"":
		return GSResult.fail(GSError.CODE_INVALID, "an action needs a name")
	if kind != KIND_BUTTON and kind != KIND_AXIS:
		return GSResult.fail(GSError.CODE_INVALID, "action %s has kind '%s', not button or axis" % [action, kind])
	if _kinds.has(action):
		return GSResult.fail(GSError.CODE_CONFLICT, "action %s is already declared" % action)
	_kinds[action] = kind
	_contexts[action] = context
	_bindings[action] = {}
	for device: String in defaults:
		for text: String in defaults[device]:
			var r := add_binding(action, device, text, true)
			if not r.ok:
				_kinds.erase(action)
				_contexts.erase(action)
				_bindings.erase(action)
				return r
	return GSResult.success(action)


func has(action: StringName) -> bool:
	return _kinds.has(action)


func names() -> Array:
	return _kinds.keys()


func kind_of(action: StringName) -> String:
	return str(_kinds.get(action, ""))


func context_of(action: StringName) -> String:
	return str(_contexts.get(action, ""))


## The bindings of [param action] on [param device], in the order they were added.
func bindings(action: StringName, device: String) -> PackedStringArray:
	var by_device: Dictionary = _bindings.get(action, {})
	return PackedStringArray(by_device.get(device, PackedStringArray()))


## Whether [param text] is a well-formed binding for [param device].
static func is_valid_binding(device: String, text: String) -> bool:
	if not _PREFIXES.has(device):
		return false
	for prefix: String in _PREFIXES[device]:
		if text.begins_with(prefix) and text.length() > prefix.length():
			return true
	return false


## Adds a binding. [param cfg] is optional; with it a limit on bindings per action applies (0 is no limit).
func add_binding(action: StringName, device: String, text: String, ignore_limit: bool = true, cfg: GSInputConfig = null) -> GSResult:
	if not _kinds.has(action):
		return GSResult.fail(GSError.CODE_INVALID, "action %s is not declared" % action)
	if not is_valid_binding(device, text):
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not a %s binding" % [text, device])
	var list := bindings(action, device)
	if list.has(text):
		return GSResult.success(action)
	if cfg != null and not ignore_limit and cfg.max_bindings_per_action > 0 and list.size() >= cfg.max_bindings_per_action:
		return GSResult.fail(GSError.CODE_QUOTA, "action %s already holds %d %s bindings (the configured limit)" % [action, list.size(), device])
	list.append(text)
	(_bindings[action] as Dictionary)[device] = list
	return GSResult.success(action)


func remove_binding(action: StringName, device: String, text: String) -> void:
	var list := bindings(action, device)
	var at := list.find(text)
	if at >= 0:
		list.remove_at(at)
		(_bindings[action] as Dictionary)[device] = list


## Every other action in the same context that holds [param text] on [param device].
func holders(action: StringName, device: String, text: String) -> Array:
	var out: Array = []
	for other: StringName in _kinds:
		if other != action and _contexts[other] == _contexts.get(action, "play") and bindings(other, device).has(text):
			out.append(other)
	return out


## Rebinds [param action] on [param device] to exactly [param text], applying the conflict policy of [param cfg]. A refused rebind changes nothing and its error names the holder.
func rebind(action: StringName, device: String, text: String, cfg: GSInputConfig) -> GSResult:
	if not _kinds.has(action):
		return GSResult.fail(GSError.CODE_INVALID, "action %s is not declared" % action)
	if not is_valid_binding(device, text):
		return GSResult.fail(GSError.CODE_INVALID, "'%s' is not a %s binding" % [text, device])
	var taken := holders(action, device, text)
	if not taken.is_empty():
		if cfg.conflict_policy == GSInputConfig.CONFLICT_REFUSE:
			return GSResult.fail(GSError.CODE_CONFLICT, "%s is already bound to %s" % [text, taken[0]])
		for other: StringName in taken:
			remove_binding(other, device, text)
	(_bindings[action] as Dictionary)[device] = PackedStringArray([text])
	return GSResult.success(action)


## Puts one action back to the bindings it was declared with is the caller's job (keep the defaults set); this empties it.
func clear(action: StringName, device: String) -> void:
	if _bindings.has(action):
		(_bindings[action] as Dictionary)[device] = PackedStringArray()
