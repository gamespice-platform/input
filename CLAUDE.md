# GameSpice Input

Declared actions, device bindings, rebinding with conflict detection and one sampled intent per tick. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/dot_input/`**; it requires [GameSpice Core](../dot-core) only (`ln -s ../../dot-core/addons/dot_core addons/dot_core`, gitignored).

| Path | What |
| --- | --- |
| `core/dot_input_config.gd` | `GSInputConfig`: every tunable, `from_files()` |
| `core/dot_input_action_set.gd` | `GSInputActionSet`: declared actions, per-device bindings, rebind with the conflict policy |
| `core/dot_input_conflicts.gd` | `GSInputConflicts`: shared bindings in one context, for a rebinding screen |
| `core/dot_input_intent.gd` | `GSInputIntent`: one tick as values, dead zone, press and release edges, dictionary round trip |
| `core/dot_input_text.gd` | `GSInputText`: event to short text and back, pure, the vocabulary a settings file and a rebinding button share |
| `core/dot_input_map.gd` | `GSInputMap`: apply, ensure and describe binding text on `InputMap` actions (the only class here that touches `InputMap`) |
| `core/dot_input_vocab.gd` | `GSInputVocab`: converts `key:F` / `mouse:1` / `pad:rt` (action set) to and from `F` / `Mouse 1` / `Axis 5+` (`GSInputText`); touch and unknown names give "" |
| `examples/input_selftest.tscn` | the headless suite |

- **Boundaries.** Owned elsewhere, consume them, do not copy: look accumulation and movement (GameSpice Player Controller), rebindable-key rows (GameSpice Menu), on-screen widgets (GameSpice Mobile), `GSNetInput` and prediction (GameSpice Net).
- **Pure data, except `GSInputMap`.** Nothing else here calls `Input` or `InputMap`, so a dedicated server and a suite can hold every class.
- **No hard caps.** `max_bindings_per_action` 0 is unlimited; a refused rebind returns a failed `GSResult` naming the holder and changes nothing.
- **No class_name collisions.** `GSInputBinding` stays GameSpice UI's as a forwarder to `GSInputText` and `GSInputMap`; do not declare it here.
- **Validate**: `--import`, parse every `.gd`, run the suite.
