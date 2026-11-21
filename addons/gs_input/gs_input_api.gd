extends RefCounted

## GameSpice Input's API level. The rule for bumping it is on [GSAddonApi].

# 1: GSInputActionSet, GSInputConflicts, GSInputIntent, GSInputConfig.
# 2: GSInputText (event and text, pure) and GSInputMap (apply to InputMap), moved from GameSpice UI.
const LEVEL := 2
const OLDEST := 1
