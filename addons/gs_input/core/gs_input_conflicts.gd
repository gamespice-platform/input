class_name GSInputConflicts
extends RefCounted

## Finds bindings two actions of one context share, for a rebinding screen that wants to show them (the set itself refuses them on rebind, but defaults and loaded profiles can arrive already in conflict).


## One entry per shared binding on [param device]: {binding, actions}, actions sorted.
static func find(set: GSInputActionSet, device: String) -> Array:
	var seen: Dictionary = {}
	for action: StringName in set.names():
		for text in set.bindings(action, device):
			var key := "%s|%s" % [set.context_of(action), text]
			if not seen.has(key):
				seen[key] = {"binding": text, "actions": []}
			(seen[key]["actions"] as Array).append(str(action))
	var out: Array = []
	for key: String in seen:
		var entry: Dictionary = seen[key]
		if (entry["actions"] as Array).size() > 1:
			(entry["actions"] as Array).sort()
			out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["binding"]) < str(b["binding"]))
	return out
