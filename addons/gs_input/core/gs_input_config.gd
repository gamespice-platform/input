class_name GSInputConfig
extends GSConfig

## Every tunable of the input model. A game binds it with GSGameConfigBinder (kind `input`) for cvars and the workbench; `cfg/addon/gs_input/*.yml`, `GS_INPUT_*` and `--input-*` layer over these defaults.

const ADDON := "gs-input"
## A rebind onto a binding another action already holds is refused.
const CONFLICT_REFUSE := 0
## A rebind onto a binding another action already holds takes it from that action.
const CONFLICT_STEAL := 1

## Master switch: off, a sampled intent is always empty.
@export var enabled: bool = true

@export_group("Sampling")
## Stick and trigger values under this read as zero; the rest is rescaled so the axis still reaches 1.
@export_range(0.0, 0.95, 0.01) var gamepad_deadzone: float = 0.2
## An analogue value at or over this counts as a button held.
@export_range(0.01, 1.0, 0.01) var trigger_threshold: float = 0.5

@export_group("Rebinding")
## What a rebind onto a taken binding does: 0 refuse, 1 steal it.
@export_range(0, 1, 1) var conflict_policy: int = CONFLICT_REFUSE
## The most bindings one action may hold per device; 0 is no limit.
@export_range(0, 8, 1) var max_bindings_per_action: int = 0
## The device a fresh profile starts on: kbm, pad or touch.
@export var default_device: String = "kbm"


func env_prefix() -> String:
	return "GS_INPUT_"


func cli_prefix() -> String:
	return "--input-"


func validate() -> GSResult:
	if gamepad_deadzone < 0.0 or gamepad_deadzone >= 1.0:
		return GSResult.fail(GSError.CODE_INVALID, "input gamepad_deadzone %.2f must be in [0, 1)" % gamepad_deadzone)
	if trigger_threshold <= 0.0 or trigger_threshold > 1.0:
		return GSResult.fail(GSError.CODE_INVALID, "input trigger_threshold %.2f must be in (0, 1]" % trigger_threshold)
	if conflict_policy != CONFLICT_REFUSE and conflict_policy != CONFLICT_STEAL:
		return GSResult.fail(GSError.CODE_INVALID, "input conflict_policy %d is not 0 or 1" % conflict_policy)
	if max_bindings_per_action < 0:
		return GSResult.fail(GSError.CODE_INVALID, "input max_bindings_per_action %d is negative (0 is no limit)" % max_bindings_per_action)
	if not GSInputActionSet.DEVICES.has(default_device):
		return GSResult.fail(GSError.CODE_INVALID, "input default_device '%s' is not one of %s" % [default_device, GSInputActionSet.DEVICES])
	return GSResult.success(self)


## Defaults, then `cfg/addon/gs_input/*.yml` and the game tier, then environment and command line.
static func from_files() -> GSResult:
	var cfg := GSInputConfig.new()
	var files := GSAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "input %s deadzone %.2f threshold %.2f conflicts %s max/action %d device %s" % [
		"on" if enabled else "disabled", gamepad_deadzone, trigger_threshold,
		"steal" if conflict_policy == CONFLICT_STEAL else "refuse", max_bindings_per_action, default_device]
