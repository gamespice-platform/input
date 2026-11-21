@tool
class_name DotInputMap
extends RefCounted

## Applies binding text ([DotInputText]) to [InputMap] actions: create, replace, describe.
##
## [codeblock]
## DotInputMap.ensure_action(&"chat_open", "Y")   # only if the action has no binding yet
## DotInputMap.apply(&"chat_open", "Shift+Y")      # replaces, never adds
## [/codeblock]

const CHANNEL := "ui.binding"


## Points an action at exactly this binding, creating the action if it is new.
##
## Returns the binding that ended up on the action, which is [constant DotInputText.UNBOUND] when the
## text named nothing — a caller that shows the player their key wants what happened, not
## what was asked for.
##
## [b]It replaces rather than adds.[/b] A setting is one value; applying it twice must not
## leave the action bound to two keys, which is what `action_add_event` on an existing
## action does, and what makes a rebound key still work on its old one.
static func apply(action: StringName, text: String) -> String:
	var event := DotInputText.from_text(text)

	if not InputMap.has_action(action):
		InputMap.add_action(action)

	InputMap.action_erase_events(action)

	if event == null:
		# Text that names nothing is not the same as asking for nothing. A settings file
		# that says "Qwerty" for a key has just left the action with no binding at all,
		# and the player's only symptom is a key that does nothing. WARN, because the
		# person who can fix it is whoever wrote that value, and the value is in a file.
		if text.strip_edges() != DotInputText.UNBOUND:
			DotLog.warn(CHANNEL, "a binding names no input, so the action is unbound", {
				"action": String(action), "text": text,
			})
		return DotInputText.UNBOUND

	InputMap.action_add_event(action, event)
	return DotInputText.to_text(event)


## Creates the action with this binding only if the project does not already have it.
##
## What a game calls at boot for an action it ships a default for: a project that declares
## `chat_open` in its input map, or a player who has rebound it, keeps what they have.
## [method apply] is what a settings change calls.
static func ensure_action(action: StringName, text: String) -> String:
	if InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty():
		return describe_action(action)

	return apply(action, text)


## The first binding on an action, as text. Empty for an action with none.
static func describe_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return DotInputText.UNBOUND

	var events := InputMap.action_get_events(action)
	return DotInputText.UNBOUND if events.is_empty() else DotInputText.to_text(events[0])
