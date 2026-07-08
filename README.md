# NextUI Icons

NextUI Icons is the strategic-icon companion mod for NextUI. It is a separate
FAF UI mod: it owns the generated icon sets, blueprint-to-icon assignments, and
the small upgrade-state overlays. NextUI itself does not need to ship or load
these files.

## Installation

Keep this repository in the FAF mods directory as `NextUI-Icons`, enable
**NextUI Icons** in the UI Mods menu, and restart the game after installing or
updating it. The mod uses its own UID and can be enabled independently of
NextUI.

Do not leave a `custom-strategic-icons` directory in the main NextUI mod after
migrating the assets. FAF treats any mod with that directory as an icon mod and
will try to load its `mod_icons.lua`.

## Editing and generating icons

`tools/strategic_icon_config.sh` is the user-facing recipe file.
`tools/generate_strategic_icons.sh` is the generator entry point. Its internal
implementation is grouped by responsibility under `tools/strategic-icons/`.
A `create_icon` recipe declares both its artwork and the blueprints it targets,
so generation updates the DDS files and `mod_icons.lua` together.

```bash
# Validate recipes without writing outputs.
bash tools/strategic_icon_config.sh --check

# Generate all DDS states and preview sheets.
bash tools/strategic_icon_config.sh

# Inspect the public recipe catalog.
bash tools/strategic_icon_config.sh --list-shapes
bash tools/strategic_icon_config.sh --list-symbols
bash tools/strategic_icon_config.sh --list-border-patterns
bash tools/strategic_icon_config.sh --list-border-styles
bash tools/strategic_icon_config.sh --list-icons
```

Generated game assets live in `custom-strategic-icons/`. Human-reviewable
preview sheets live in `artwork/strategic-icons/previews/`. Native files
extracted during generation and cache data are local build inputs and are not
part of the repository.

### Internal generator layout

The implementation under `tools/strategic-icons/` is split by responsibility:

- `common.sh`: shared paths, state, cache, and generated-file lifecycle.
- `config_api.sh`: declarative functions used by the recipe file.
- `rendering.sh`: ImageMagick primitives and icon-layer composition.
- `native_icons.sh`: FAF archive discovery, extraction, and TECH sources.
- `outputs.sh`: DDS families, overlays, and preview generation.
- `validation.sh`: configuration checks and read-only listing commands.

Every icon family uses all four FAF states:

```text
<icon-set>_rest.dds
<icon-set>_over.dds
<icon-set>_selected.dds
<icon-set>_selectedover.dds
```

For example:

```bash
create_icon \
    --name smd \
    --shape square \
    --techs "3" \
    --target-categories "STRUCTURE ANTIMISSILE" \
    --symbol antimissile \
    --color "$blue_cobalt_defense" \
    --border corners_small_blue
```

Use `--target-categories` when every listed blueprint category must match, or
`--target-icon-names` for exact FAF `StrategicIconName` values. The selected
tech must also be present in `--techs`. `mod_icons.lua` is generated from these
targets; do not edit it manually.
