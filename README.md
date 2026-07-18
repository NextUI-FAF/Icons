# NextUI Icons

NextUI Icons is the strategic-icon companion mod for NextUI. It is a separate
FAF UI mod: it owns the generated icon sets, blueprint-to-icon assignments, and
the small upgrade-state overlays.

<img width="1416" height="1944" alt="image" src="https://github.com/user-attachments/assets/1bebfcfd-f84e-4456-9b96-167444e3eac0" />

The mod will also add an upgrade animation to all upgrading structures.

<img width="11" height="9" alt="image" src="https://github.com/user-attachments/assets/5802c583-ef62-4e55-87b6-323fda437583" />

## Installation

Keep this repository in the FAF mods directory as `NextUI.Icons`, enable
**NextUI Icons** in the UI Mods menu, and restart the game after installing or
updating it. The mod uses its own UID and can be enabled independently of
NextUI.

Mods Directory:
Linux: `/home/username/My Games/Gas Powered Games/Supreme Commander Forged Alliance/mods`

Replace username... with your username.

## NEW: Editing and generating icons with Python

First you need to install the requeriments by runing the following command:

`pip install -r requeriments.txt`

You can create your own icons by running:

`python icon-generator/main.py`

To define new icons or to modify existing icons you should edit `icon-generator/main.py`.

Chinging icon colors is easy as:
    `compose_faf_icon_with_variants([square, pgen_symbol_outlined(pink_signal)], "icon_structure[T]_energy", [2, 3])`

As you can see you only need to specify the argument with parentheses `pgen_symbol_outlined(pink_signal)`

To add new pixel patterns modify `icon-generator/pixel_patterns.py`.

At pixel_patterns you can find all the pixel patterns that are used to generate icons, you can use them to generate new icons or to modify existing ones. 

Apart from that you dont need to modify anything else to work with the icon generator..

## OLD: Editing and generating icons with bash

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

## Strategic icon draw order

FAF uses `StrategicIconSortPriority` on unit blueprints to decide which
strategic icons draw above others. Lower values draw above higher values:

```text
0   highest priority
255 lowest priority
```

Edit `strategic_icon_priorities.lua` to raise specific icon families. The
default rules raise TML, SML, SMD, and T3 artillery so they remain visible over
lower-priority economy and structure icons. Rules can match by tech, categories,
exact FAF `StrategicIconName`, and excluded blueprint IDs.
