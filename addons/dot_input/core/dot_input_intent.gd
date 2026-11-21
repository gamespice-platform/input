class_name DotInputIntent
extends RefCounted

## One tick of sampled input as plain values: which buttons are down, what each axis reads, and which buttons went down or up since the previous tick. This is what a game sends to a server and what a prediction replays; it holds no `Input` calls.

var tick: int = 0
var down: Dictionary = {}
var axes: Dictionary = {}
var pressed: Dictionary = {}
var released: Dictionary = {}


## Samples [param raw] (action name to 0..1 or -1..1 value, as a device layer read it) against [param set] and [param cfg]. [param previous] gives the edges; null means everything was up.
static func sample(set: DotInputActionSet, cfg: DotInputConfig, raw: Dictionary, previous: DotInputIntent, at_tick: int) -> DotInputIntent:
	var out := DotInputIntent.new()
	out.tick = at_tick
	if not cfg.enabled:
		return out
	for action: StringName in set.names():
		var value := float(raw.get(action, raw.get(str(action), 0.0)))
		if set.kind_of(action) == DotInputActionSet.KIND_AXIS:
			var shaped := apply_deadzone(value, cfg.gamepad_deadzone)
			if shaped != 0.0:
				out.axes[action] = shaped
		elif absf(value) >= cfg.trigger_threshold:
			out.down[action] = true
	for action: StringName in out.down:
		if previous == null or not previous.down.has(action):
			out.pressed[action] = true
	if previous != null:
		for action: StringName in previous.down:
			if not out.down.has(action):
				out.released[action] = true
	return out


## Zero inside the dead zone, then rescaled so the edge of the zone is 0 and full deflection is still 1 (sign kept).
static func apply_deadzone(value: float, deadzone: float) -> float:
	var a := absf(value)
	if a <= deadzone:
		return 0.0
	return signf(value) * minf((a - deadzone) / (1.0 - deadzone), 1.0)


func is_down(action: StringName) -> bool:
	return down.has(action)


func axis(action: StringName) -> float:
	return float(axes.get(action, 0.0))


func is_empty() -> bool:
	return down.is_empty() and axes.is_empty()


## A string-keyed dictionary a network layer can carry, and [method from_dict] reads back.
func to_dict() -> Dictionary:
	return {"tick": tick, "down": down.keys().map(str), "axes": _stringify(axes)}


static func from_dict(d: Dictionary) -> DotInputIntent:
	var out := DotInputIntent.new()
	out.tick = int(d.get("tick", 0))
	for action in d.get("down", []):
		out.down[StringName(action)] = true
	var ax: Dictionary = d.get("axes", {})
	for action: String in ax:
		out.axes[StringName(action)] = float(ax[action])
	return out


static func _stringify(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in src:
		out[str(k)] = src[k]
	return out
