#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_strategic_icons.sh" "$@"
fi

# Strategic icon recipes ------------------------------------------------------
#
# This is the user-editable part of the icon generator. You do not need to
# understand the ImageMagick implementation in generate_strategic_icons.sh.
#
# Typical workflow:
#   1. Edit colors, symbols, border styles, or icon families below.
#   2. Run: bash tools/strategic_icon_config.sh --check
#   3. Run: bash tools/strategic_icon_config.sh
#   4. Review artwork/strategic-icons/previews/
#
# Inspection commands:
#   bash tools/strategic_icon_config.sh --list-symbols
#   bash tools/strategic_icon_config.sh --list-border-patterns
#   bash tools/strategic_icon_config.sh --list-border-styles
#   bash tools/strategic_icon_config.sh --list-icons
#
# FAF's native player-color field uses this gray as its main tone. When an icon
# uses player_color as its background, the generator preserves the complete
# native field, including its darker shading, so the game can recolor it for the
# owning army at runtime.
player_color="#7b7d7b"

# Palette
black="#000000"
white="#ffffff"
yellow="#ffff33"
pure_yellow="#ffff00"
amber_tactical="#D97706"
green="#4dff70"
green_pure="#00ff00"
green_clear="#bffcff"
green_tactical_olive="#4A5320"
green_militar="#5D6532"
cyan="#27d9ff"
orange="#ff8a00"
red="#ff3030"
magenta="#ff00ff"
blue_cobalt_defense="#00ACFF"
blue_tactical_navy="#051C33"


# Icon geometry ---------------------------------------------------------------
#
# Shapes drive explicit icon recipes and automatic native TECH replacements.
#
# X = transparent, F = background layer, B = built-in border layer.
# Maps contain local geometry only; do not add X padding to position a shape.
# Each icon measures shape, TECH, interaction frame, and custom border,
# translates all layers together, then rounds to four-pixel DDS boundaries.
# Native fallback references are internal defaults.
# TECH recipes are global, with optional overrides keyed by the shape name.
# Selected canvases grow by four pixels and shapes move by 2 2 automatically.
# Hover states convert the complete shape silhouette to player color.

define_shape \
    --name square \
    --pixel-map "B B B B B B B B B B B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B B B B B B B B B B B"

define_shape \
    --name square_big \
    --pixel-map "B B B B B B B B B B B B B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B B B B B B B B B B B B B"

define_shape \
    --name rectangle \
    --pixel-map "B B B B B B B B B B B B B B B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B F F F F F F F F F F F F F B
                 B B B B B B B B B B B B B B B"

define_shape \
    --name hexagon \
    --pixel-map "X X X X B B B B B B B X X X X
                 X X X B B F F F F F B B X X X
                 X X B B F F F F F F F B B X X
                 X B B F F F F F F F F F B B X
                 B B F F F F F F F F F F F B B
                 X B B F F F F F F F F F B B X
                 X X B B F F F F F F F B B X X
                 X X X B B F F F F F B B X X X
                 X X X X B B B B B B B X X X X"

define_shape \
    --name diamond \
    --tech-overlap 2 \
    --pixel-map "X X X X X X B X X X X X X
                 X X X X X B B B X X X X X
                 X X X X B B F B B X X X X
                 X X X B B F F F B B X X X
                 X X B B F F F F F B B X X
                 X B B F F F F F F F B B X
                 B B F F F F F F F F F B B
                 X B B F F F F F F F B B X
                 X X B B F F F F F B B X X
                 X X X B B F F F B B X X X
                 X X X X B B F B B X X X X
                 X X X X X B B B X X X X X
                 X X X X X X B X X X X X X"

define_shape \
    --name triangle \
    --pixel-map "X X X X X X B X X X X X X
                 X X X X X X B X X X X X X
                 X X X X X B B B X X X X X
                 X X X X X B F B X X X X X
                 X X X X B B F B B X X X X
                 X X X X B F F F B X X X X
                 X X X B B F F F B B X X X
                 X X X B F F F F F B X X X
                 X X B B F F F F F B B X X
                 X X B F F F F F F F B X X
                 X B B F F F F F F F B B X
                 X B F F F F F F F F F B X
                 B B F F F F F F F F F B B
                 B B B B B B B B B B B B B"

define_shape \
    --name wide_triangle \
    --selected-canvas-size "24x16" \
    --selectedover-canvas-size "24x16" \
    --selected-shape-position "2 2" \
    --selectedover-shape-position "2 2" \
    --pixel-map "X X X X X X X X B X X X X X X X X
                 X X X X X X X B B B X X X X X X X
                 X X X X X X B B F B B X X X X X X
                 X X X X X B B F F F B B X X X X X
                 X X X X B B F F F F F B B X X X X
                 X X X B B F F F F F F F B B X X X
                 X X B B F F F F F F F F F B B X X
                 X B B F F F F F F F F F F F B B X
                 B B F F F F F F F F F F F F F B B
                 B B B B B B B B B B B B B B B B B"

define_shape \
    --name trapezium \
    --shape-position "0 2" \
    --tech-overlap 3 \
    --pixel-map "B B B B B B B B B B B B B B B
                 B B F F F F F F F F F F F B B
                 X B F F F F F F F F F F F B X
                 X B B F F F F F F F F F F B X
                 X X B F F F F F F F F F B B X
                 X X B F F F F F F F F F B X X
                 X X B B F F F F F F F B B X X
                 X X X B F F F F F F F B X X X
                 X X X B B B B B B B B B X X X"

define_shape \
    --name semicircle \
    --selected-canvas-size "20x16" \
    --selectedover-canvas-size "20x16" \
    --selected-shape-position "2 0" \
    --selectedover-shape-position "2 0" \
    --pixel-map "X X X X X B B B X X X X X
                 X X X B B B F B B B X X X
                 X X B B F F F F F B B X X
                 X B B F F F F F F F B B X
                 X B F F F F F F F F F B X
                 B B F F F F F F F F F B B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B B B B B B B B B B B B B"

define_shape \
    --name inverted_semicircle \
    --selected-canvas-size "20x16" \
    --selectedover-canvas-size "20x16" \
    --shape-position "0 5" \
    --selected-shape-position "2 5" \
    --selectedover-shape-position "2 5" \
    --tech-overlap 4 \
    --pixel-map "B B B B B B B B B B B B B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B F F F F F F F F F F F B
                 B B F F F F F F F F F B B
                 X B F F F F F F F F F B X
                 X B B F F F F F F F B B X
                 X X B B F F F F F B B X X
                 X X X B B B F B B B X X X
                 X X X X X B B B X X X X X"

define_shape \
    --name circle \
    --pixel-map "X X X B F F F B X X X
                 X X B B F F F B B X X
                 X B B F F F F F B B X
                 B B F F F F F F F B B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B F F F F F F F F F B
                 B B F F F F F F F B B
                 X B B F F F F F B B X
                 X X B B F F F B B X X
                 X X X B B B B B X X X"

# Explicit visual assignments. Exceptions should be declared before family
# globs; no geometry is inferred from "bot", "land", or similar code names.
assign_icon_shape --shape circle --icons "icon_subcommander*"
assign_icon_shape --shape square --icons "icon_structure*"
assign_icon_shape --shape rectangle --icons "icon_factory* icon_factoryhq*"
assign_icon_shape --shape hexagon --icons "icon_bot*"
assign_icon_shape --shape diamond --icons "icon_land*"
assign_icon_shape --shape triangle --icons "icon_fighter*"
assign_icon_shape --shape wide_triangle --icons "icon_bomber*"
assign_icon_shape --shape trapezium --icons "icon_gunship*"
assign_icon_shape --shape semicircle --icons "icon_ship*"
assign_icon_shape --shape inverted_semicircle --icons "icon_sub*"
assign_icon_shape --shape circle --icons "icon_experimental* icon_commander* icon_subcommander* icon_objective* icon_strategic*"

# Global tech-level symbols ---------------------------------------------------
#
# These recipes are independent from the role symbol and border below.
# The logical marker canvas is 12x4 and is centered at the bottom of icons of
# every shape. Use --none to remove a tech marker globally.
#
# TECH definitions are global by default. Use --for-shape only for a visual
# exception such as diamond's T3 marker. TECH1, TECH2, and TECH3 are required.
# TECH4 is optional.
global_tech_icons=true

create_tech_symbol \
    --techs 1 \
    --none

create_tech_symbol \
    --techs 2 \
    --pixel-map "X B B B B B X
                 X B A B A B X
                 X B A B A B X
                 X B B B B B X" \
    --colors "A=$white B=$black"

create_tech_symbol \
    --techs 3 \
    --pixel-map "B B B B B B B
                 B A B A B A B
                 B A B A B A B
                 B B B B B B B" \
    --colors "A=$white B=$black"

create_tech_symbol \
    --techs 3 \
    --pixel-map "B X X X X X B
                 B A X X X A B
                 B A B X B A B
                 B A B A B A B
                 B B B B B B B" \
    --colors "A=$white B=$black" \
    --for-shape diamond

create_tech_symbol \
    --techs 4 \
    --for-shape circle \
    --none

# Reusable symbols ------------------------------------------------------------
#
# Pixel maps use X for transparency and any other token for a visible symbol
# pixel. The renderer trims the local map and centers it on the target shape.
# --draw, --file, and --mask remain available for non-grid artwork.

define_symbol \
    --name pgen \
    --pixel-map "S X X
                 X S X
                 S S S
                 X S X
                 X X S" \
    --aliases "energy power generator"

define_symbol \
    --name mex \
    --pixel-map "X S S S X
                 S X X X S
                 S S X S S
                 X X X X X
                 X X S X X" \
    --aliases "mass extractor"

define_symbol \
    --name intel \
    --pixel-map "S S S S S
                 X X X X X
                 X S S S X
                 X X X X X
                 X X S X X" \
    --aliases "radar sonar omni"

define_symbol \
    --name missile \
    --pixel-map "S
                 S
                 S
                 S
                 S" \
    --aliases "tml sml tactical_missile strategic_missile"

define_symbol \
    --name antimissile \
    --pixel-map "S
                 S
                 X
                 S
                 X
                 S
                 S" \
    --aliases "smd anti_missile anti_missile_defense strategic_missile_defense"

define_symbol \
    --name artillery \
    --pixel-map "X S X
                 S S S
                 X S X" \
    --aliases "arty"

# Reusable border patterns and styles -----------------------------------------
#
# A border pattern describes geometry using abstract names such as color_1,
# color_2, or separator. A border style maps those slots to actual colors.
#
# Patterns support four complementary authoring methods:
#   tile
#       Define every pixel of a small tile and repeat it over the outer ring.
#   repeating sequence
#       Start at the ring's top-left pixel, walk clockwise, and repeat runs
#       such as "color_1:2 color_2:1".
#   exact sequence
#       Add --outer-mode once or --inner-mode once. Exact outer and inner
#       sequences must total 56 and 48 pixels respectively. A run ending in :1
#       represents one explicitly chosen pixel.
#   free drawing
#       Add one or more --draw "slot|primitives" options using ImageMagick
#       points, lines, rectangles, and polygons on the 16x20 canvas.
#
# --tile-pixels and --outer-sequence are alternative outer-ring renderers and
# cannot be used together. Either one may be combined with --inner-sequence
# and any number of --draw layers.
#
# Custom borders use FAF's expanded 16x20 canvas so hazard + black stay outside
# an 11x11 center instead of shrinking the normal icon's usable area.
# Their DDS files use lossless ARGB8888 because BC3 cannot represent player
# gray, two hazard colors, black, white, and a colored symbol in one 4x4 block.
# Hover and selected-hover remove the interaction border by converting it to
# player color. Selected icons receive FAF's two-pixel white frame
# unless --border-at-selected-state overrides it.
# The configured global tech marker is composited last so it remains legible
# above custom borders.
#
# In a border style, "auto" derives a dark companion from color_1 that
# interpolates toward FAF's neutral gray.

# Geometry and colors are separate. A pattern names abstract slots such as
# color_1 or separator; a style assigns real palette colors to those slots.
# Pixel-map borders are centered on the local shape automatically; matching
# odd/even dimensions guarantee an exact shared pixel center.

define_border_pattern \
    --name solid_frame \
    --outer-sequence "color_1:1" \
    --inner-sequence "color_1:1"

define_border_pattern \
    --name hazard \
    --outer-sequence "color_1:2 color_2:2 " \
    --inner-sequence "color_3:1"

define_border_pattern \
    --name corners \
    --pixel-map "B B B A A A A A A A A A B B B
                 B C C C C C C C C C C C C C B
                 B C X X X X X X X X X X X C B
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 A C X X X X X X X X X X X C A
                 B C X X X X X X X X X X X C B
                 B C C C C C C C C C C C C C B
                 B B B A A A A A A A A A B B B" \

define_border_pattern \
    --name corners_small \
    --pixel-map "B B B A A A A A A A B B B
                 B C C C C C C C C C C C B
                 B C X X X X X X X X X C B
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 A C X X X X X X X X X C A
                 B C X X X X X X X X X C B
                 B C C C C C C C C C C C B
                 B B B A A A A A A A B B B" \


define_border_style \
    --name hazard_warning \
    --pattern hazard \
    --colors "color_1=$yellow color_2=auto color_3=$black"

define_border_style \
    --name hazard_warning_black \
    --pattern hazard \
    --colors "color_1=$yellow color_2=$black color_3=$black"

define_border_style \
    --name corners_yellow \
    --pattern corners \
    --colors "A=$black B=$yellow C=$black"

define_border_style \
    --name solid_magenta \
    --pattern solid_frame \
    --colors "color_1=$magenta"

define_border_style \
    --name corners_small_blue \
    --pattern corners_small \
    --colors "B=$blue_cobalt_defense A=$black C=$black"

define_border_style \
    --name corners_big_blue \
    --pattern corners \
    --colors "B=$blue_cobalt_defense A=$black C=$black"

# Icon families ---------------------------------------------------------------
#
# One recipe can generate one or several tech levels. Every output receives the
# nextui_ prefix, its tech suffix, and all four FAF states automatically.
# --target-categories assigns the family to blueprints containing every listed
# category. --target-icon-names matches FAF's exact StrategicIconName instead.
# The recipe's --techs always limits which tech levels can receive the icon.

create_icon \
    --name pgen \
    --shape square \
    --techs "2 3" \
    --target-categories "STRUCTURE ENERGYPRODUCTION" \
    --symbol pgen \
    --color "$yellow"

create_icon \
    --name mex \
    --shape square \
    --techs "1 2 3" \
    --target-categories "STRUCTURE MASSEXTRACTION" \
    --symbol mex \
    --color "$green"

create_icon \
    --name intel \
    --shape square \
    --techs "1 2 3" \
    --target-icon-names "icon_structure1_intel icon_structure2_intel icon_structure3_intel" \
    --symbol intel \
    --color "$cyan"

create_icon \
    --name tml \
    --shape square_big \
    --techs "2" \
    --target-icon-names "icon_structure2_missile" \
    --symbol missile \
    --color "$green_clear" \
    --border corners_yellow

create_icon \
    --name sml \
    --shape square_big \
    --techs "3" \
    --target-icon-names "icon_structure3_missile" \
    --symbol sml \
    --color "$magenta" \
    --border hazard_warning

create_icon \
    --name artillery \
    --shape square_big \
    --techs "3" \
    --target-categories "STRUCTURE ARTILLERY" \
    --exclude-blueprints "xab2307" \
    --symbol artillery \
    --color "$magenta" \
    --border hazard_warning

create_icon \
    --name smd \
    --shape square_big \
    --techs "3" \
    --target-categories "STRUCTURE ANTIMISSILE" \
    --symbol antimissile \
    --color "$blue_cobalt_defense" \
    --border corners_big_blue

# Example: create a custom three-tech icon family from a built-in symbol.
#
# create_icon \
#     --name my_icon \
#     --shape square \
#     --techs "1 2 3" \
#     --target-categories "STRUCTURE MY_CATEGORY" \
#     --symbol pgen \
#     --color "$white" \
#     --border solid_magenta
#
# The generated files will be named nextui_my_icon1_*.dds through
# nextui_my_icon3_*.dds. The generator also updates mod_icons.lua automatically.
#
# --border-at-selected-state white-border is implicit. The other built-in
# choices are player-color-border and none.
#
# Define a reusable symbol from transparent PNG artwork. Its alpha channel
# becomes the symbol mask. Use --mask for black/white mask artwork.
#
# define_symbol \
#     --name my_symbol \
#     --file "$ROOT/artwork/strategic-icons/masters/my-symbol.png"
#
# create_icon \
#     --name my_icon \
#     --shape square \
#     --techs "1 2 3" \
#     --symbol my_symbol \
#     --color "$white"
#
# Every definition automatically receives the nextui_ prefix, its tech suffix,
# all four FAF states, player-color previews, and stale-output tracking. Assign
# the resulting IconSet to units in mod_icons.lua; generation alone does not
# change any blueprints.
#
# A custom repeating perimeter needs no generator changes:
#
# define_border_pattern \
#     --name three_color_signal \
#     --outer-mode repeat \
#     --outer-sequence "color_1:2 color_2:1 color_3:3" \
#     --inner-mode repeat \
#     --inner-sequence "separator:1"
#
# define_border_style \
#     --name three_color_signal_cyan \
#     --pattern three_color_signal \
#     --colors "color_1=$cyan color_2=$white color_3=$magenta separator=$black"
#
# "repeat" is the default, so those two mode lines may normally be omitted.
#
# For non-repeating, pixel-exact perimeters, use the "once" modes. The outer
# runs must total 56 pixels and the inner runs 48 pixels:
#
# define_border_pattern \
#     --name asymmetric_example \
#     --outer-mode once \
#     --outer-sequence "color_1:2 color_2:1 color_1:3 color_3:50" \
#     --inner-mode once \
#     --inner-sequence "separator:47 accent:1"
#
# Free drawing uses literal coordinates on the 16x20 custom-border canvas.
# It can stand alone or add details over a tile or perimeter sequence:
#
# define_border_pattern \
#     --name corner_brackets \
#     --draw "color_1|line 0,1 4,1 line 0,1 0,5" \
#     --draw "color_1|line 10,1 14,1 line 14,1 14,5" \
#     --draw "color_2|point 7,1 point 7,15"
#
# define_border_style \
#     --name corner_brackets_cyan \
#     --pattern corner_brackets \
#     --colors "color_1=$cyan color_2=$white"
