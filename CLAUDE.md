# GameSpice Input

Declared actions, device bindings, rebinding with conflict detection and one sampled intent per tick. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/dot_input/`**; it requires [GameSpice Core](../dot-core) only (`ln -s ../../dot-core/addons/dot_core addons/dot_core`, gitignored).

| Path | What |
| --- | --- |
| `core/dot_input_config.gd` | `DotInputConfig`: every tunable, `from_files()` |
| `core/dot_input_action_set.gd` | `DotInputActionSet`: declared actions, per-device bindings, rebind with the conflict policy |
| `core/dot_input_conflicts.gd` | `DotInputConflicts`: shared bindings in one context, for a rebinding screen |
| `core/dot_input_intent.gd` | `DotInputIntent`: one tick as values, dead zone, press and release edges, dictionary round trip |
| `examples/input_selftest.tscn` | the headless suite |

- **Boundaries.** Owned elsewhere, consume them, do not copy: look accumulation and movement (GameSpice Player Controller), rebindable-key rows (GameSpice Menu), event to text via `DotInputBinding` (GameSpice UI), on-screen widgets (GameSpice Mobile), `DotNetInput` and prediction (GameSpice Net).
- **Pure data.** Nothing here calls `Input` or `InputMap`, so a dedicated server and a suite can hold every class.
- **No hard caps.** `max_bindings_per_action` 0 is unlimited; a refused rebind returns a failed `DotResult` naming the holder and changes nothing.
- **No class_name collisions.** `DotInputBinding` is GameSpice UI's; this addon's names are `DotInputConfig`, `DotInputActionSet`, `DotInputConflicts`, `DotInputIntent`.
- **Validate**: `--import`, parse every `.gd`, run the suite.
