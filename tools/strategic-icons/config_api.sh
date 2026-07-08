# Declarative API consumed by tools/strategic_icon_config.sh.

# Prints the rectangular dimensions of a semantic pixel map.
get_pixel_map_dimensions() {
    local pixel_map="$1"
    local -a rows=()
    local -a cells=()

    pixel_map="${pixel_map//\//$'\n'}"
    IFS=$'\n' read -r -d '' -a rows < <(
        printf '%s' "$pixel_map" |
            sed -E 's/^[ \t]+//;s/[ \t]+$//' |
            tr -d '\r'
        printf '\0'
    )
    read -r -a cells <<< "${rows[0]:-}"
    printf '%s %s\n' "${#cells[@]}" "${#rows[@]}"
}

# Rounds one positive pixel extent up to a DDS-friendly multiple of four.
round_canvas_extent() {
    local extent="$1"
    printf '%s\n' "$((((extent + 3) / 4) * 4))"
}

# Infers the normal output canvas from the positioned shape and TECH footprint.
infer_shape_canvas_size() {
    local pixel_map="$1"
    local shape_position="$2"
    local tech_position="$3"
    local tech_overlap="$4"
    local tech_offset="$5"
    local shape_width
    local shape_height
    local visible_left
    local visible_right
    local shape_x
    local shape_y
    local tech_x
    local tech_y
    local tech_offset_x
    local tech_offset_y
    local tech_width="${TECH_SYMBOL_SIZE%x*}"
    local tech_height="$TECH_SYMBOL_HEIGHT"

    read -r shape_width shape_height < <(get_pixel_map_dimensions "$pixel_map")
    ((shape_width > 0 && shape_height > 0)) ||
        die "Cannot infer a canvas from an empty shape pixel map."
    read_layer_position "$shape_position" shape_x shape_y
    read_layer_position "$tech_offset" tech_offset_x tech_offset_y

    if [[ -n "$tech_position" ]]; then
        read_layer_position "$tech_position" tech_x tech_y
    else
        tech_x=$((shape_x + (shape_width - tech_width) / 2 + tech_offset_x))
        tech_y=$((shape_y + shape_height - tech_overlap + tech_offset_y))
    fi

    local required_width=$((shape_x + shape_width))
    local required_height=$((shape_y + shape_height))
    ((tech_x + tech_width > required_width)) &&
        required_width=$((tech_x + tech_width))
    ((tech_y + tech_height > required_height)) &&
        required_height=$((tech_y + tech_height))

    printf '%sx%s\n' \
        "$(round_canvas_extent "$required_width")" \
        "$(round_canvas_extent "$required_height")"
}

# define_shape --name NAME [--canvas-size WIDTHxHEIGHT] --pixel-map MAP
#              --shape-position "X Y" [ANCHOR OPTIONS]
#              [--rest-pixel-map MAP ...] [--native-reference ICON_SET]
#
# A shape is color-independent geometry. X is transparent, F belongs to the
# background layer, and B belongs to the border layer. The map uses local
# coordinates beginning at 0,0; --shape-position places it on the output
# canvas. The normal canvas is inferred and rounded to four pixels unless an
# advanced override is supplied. State-specific maps override --pixel-map.
define_shape() {
    local name=""
    local canvas_size=""
    local rest_canvas_size=""
    local over_canvas_size=""
    local selected_canvas_size=""
    local selectedover_canvas_size=""
    local pixel_map=""
    local rest_map=""
    local over_map=""
    local selected_map=""
    local selectedover_map=""
    local shape_position="0 0"
    local rest_shape_position=""
    local over_shape_position=""
    local selected_shape_position=""
    local selectedover_shape_position=""
    local symbol_position=""
    local symbol_anchor="center"
    local symbol_offset="0 0"
    local tech_position=""
    local tech_anchor="bottom-center"
    local tech_overlap="1"
    local tech_offset="0 0"
    local tech_scope=""
    local native_reference=""

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for define_shape option: $1"
        case "$1" in
            --name) name="$2" ;;
            --canvas-size) canvas_size="$2" ;;
            --rest-canvas-size) rest_canvas_size="$2" ;;
            --over-canvas-size|--hover-canvas-size) over_canvas_size="$2" ;;
            --selected-canvas-size) selected_canvas_size="$2" ;;
            --selectedover-canvas-size|--hoverselected-canvas-size) selectedover_canvas_size="$2" ;;
            --pixel-map) pixel_map="$2" ;;
            --rest-pixel-map) rest_map="$2" ;;
            --over-pixel-map|--hover-pixel-map) over_map="$2" ;;
            --selected-pixel-map) selected_map="$2" ;;
            --selectedover-pixel-map|--hoverselected-pixel-map) selectedover_map="$2" ;;
            --shape-position) shape_position="$2" ;;
            --rest-shape-position) rest_shape_position="$2" ;;
            --over-shape-position|--hover-shape-position) over_shape_position="$2" ;;
            --selected-shape-position) selected_shape_position="$2" ;;
            --selectedover-shape-position|--hoverselected-shape-position) selectedover_shape_position="$2" ;;
            --symbol-position) symbol_position="$2" ;;
            --symbol-anchor) symbol_anchor="$2" ;;
            --symbol-offset) symbol_offset="$2" ;;
            --tech-icon-start-position|--tech-position) tech_position="$2" ;;
            --tech-anchor) tech_anchor="$2" ;;
            --tech-overlap) tech_overlap="$2" ;;
            --tech-offset) tech_offset="$2" ;;
            --tech-scope) tech_scope="$2" ;;
            --native-reference) native_reference="$2" ;;
            *) die "Unsupported define_shape option: $1" ;;
        esac
        shift 2
    done

    [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]] ||
        die "Invalid shape name '$name'. Use lowercase letters, numbers, and underscores."
    [[ -n "$pixel_map" ]] ||
        die "Shape '$name' requires --pixel-map."
    [[ -z "$canvas_size" || "$canvas_size" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]] ||
        die "Shape '$name' has invalid --canvas-size '$canvas_size'."
    [[ "$symbol_anchor" == "center" ]] ||
        die "Shape '$name' currently supports --symbol-anchor center."
    [[ "$tech_anchor" == "bottom-center" ]] ||
        die "Shape '$name' currently supports --tech-anchor bottom-center."
    [[ "$tech_overlap" =~ ^[0-9]+$ ]] ||
        die "Shape '$name' tech overlap must be a non-negative integer."
    [[ -z "${SHAPE_CONFIG[$name.registered]:-}" ]] ||
        die "Shape '$name' is already defined."

    tech_scope="${tech_scope:-$name}"
    canvas_size="${canvas_size:-$(infer_shape_canvas_size \
        "$pixel_map" "$shape_position" "$tech_position" \
        "$tech_overlap" "$tech_offset")}"
    local canvas_width="${canvas_size%x*}"
    local canvas_height="${canvas_size#*x}"
    local default_selected_canvas="$((canvas_width + 4))x$((canvas_height + 4))"
    local shape_x
    local shape_y
    read_layer_position "$shape_position" shape_x shape_y
    local default_selected_position="$((shape_x + 2)) $((shape_y + 2))"

    SHAPES+=("$name")
    SHAPE_CONFIG["$name.registered"]=1
    SHAPE_CONFIG["$name.canvas_size"]="$canvas_size"
    SHAPE_CONFIG["$name.rest.canvas_size"]="${rest_canvas_size:-$canvas_size}"
    SHAPE_CONFIG["$name.over.canvas_size"]="${over_canvas_size:-$canvas_size}"
    SHAPE_CONFIG["$name.selected.canvas_size"]="${selected_canvas_size:-$default_selected_canvas}"
    SHAPE_CONFIG["$name.selectedover.canvas_size"]="${selectedover_canvas_size:-${selected_canvas_size:-$default_selected_canvas}}"
    SHAPE_CONFIG["$name.pixel_map"]="$pixel_map"
    SHAPE_CONFIG["$name.rest.pixel_map"]="${rest_map:-$pixel_map}"
    SHAPE_CONFIG["$name.over.pixel_map"]="${over_map:-$pixel_map}"
    SHAPE_CONFIG["$name.selected.pixel_map"]="${selected_map:-$pixel_map}"
    SHAPE_CONFIG["$name.selectedover.pixel_map"]="${selectedover_map:-$pixel_map}"
    SHAPE_CONFIG["$name.shape_position"]="$shape_position"
    SHAPE_CONFIG["$name.rest.shape_position"]="${rest_shape_position:-$shape_position}"
    SHAPE_CONFIG["$name.over.shape_position"]="${over_shape_position:-$shape_position}"
    SHAPE_CONFIG["$name.selected.shape_position"]="${selected_shape_position:-$default_selected_position}"
    SHAPE_CONFIG["$name.selectedover.shape_position"]="${selectedover_shape_position:-${selected_shape_position:-$default_selected_position}}"
    SHAPE_CONFIG["$name.symbol_position"]="$symbol_position"
    SHAPE_CONFIG["$name.symbol_anchor"]="$symbol_anchor"
    SHAPE_CONFIG["$name.symbol_offset"]="$symbol_offset"
    SHAPE_CONFIG["$name.tech_position"]="$tech_position"
    SHAPE_CONFIG["$name.tech_anchor"]="$tech_anchor"
    SHAPE_CONFIG["$name.tech_overlap"]="$tech_overlap"
    SHAPE_CONFIG["$name.tech_offset"]="$tech_offset"
    SHAPE_CONFIG["$name.tech_scope"]="$tech_scope"
    SHAPE_CONFIG["$name.native_reference"]="$native_reference"
}

# assign_icon_shape --shape NAME --icons "ICON_SET_OR_GLOB ..."
#
# Assignments are checked in declaration order. Keep exceptional exact icon
# sets before broader family globs.
assign_icon_shape() {
    local shape=""
    local icons=""

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for assign_icon_shape option: $1"
        case "$1" in
            --shape) shape="$2" ;;
            --icons|--icon-sets) icons="$2" ;;
            *) die "Unsupported assign_icon_shape option: $1" ;;
        esac
        shift 2
    done

    [[ -n "${SHAPE_CONFIG[$shape.registered]:-}" ]] ||
        die "assign_icon_shape references unknown shape '$shape'."
    [[ -n "$icons" ]] || die "assign_icon_shape '$shape' requires --icons."
    local assignment_id="${#SHAPE_ASSIGNMENTS[@]}"
    SHAPE_ASSIGNMENTS+=("$assignment_id")
    SHAPE_ASSIGNMENT_CONFIG["$assignment_id.shape"]="$shape"
    SHAPE_ASSIGNMENT_CONFIG["$assignment_id.icons"]="$icons"
}

# Prints the explicitly assigned visual shape for one native icon set.
resolve_icon_shape() {
    local icon_set="$1"
    local assignment_id
    local pattern

    for assignment_id in "${SHAPE_ASSIGNMENTS[@]}"; do
        for pattern in ${SHAPE_ASSIGNMENT_CONFIG[$assignment_id.icons]}; do
            if [[ "$icon_set" == $pattern ]]; then
                printf '%s\n' "${SHAPE_ASSIGNMENT_CONFIG[$assignment_id.shape]}"
                return 0
            fi
        done
    done
    return 1
}

# define_border_pattern --name NAME [GEOMETRY OPTIONS]
#
# Registers border geometry independently from its colors. Patterns may use:
#   --pixel-map "A A ... / A X ... / ..."
#       Defines a rectangular local border map. X and "." are transparent.
#       Icons center this map on the shape and reserve any required
#       outside space automatically.
#   --outer-sequence "slot:count ..." [--outer-mode repeat|once]
#   --inner-sequence "slot:count ..." [--inner-mode repeat|once]
#       Walks clockwise around the outer or inner perimeter. "once" must cover
#       that perimeter exactly; "repeat" loops the declared runs.
#   --draw "slot|ImageMagick drawing primitives"
#       Draws literal points, lines, rectangles, or polygons. Coordinates use
#       the 16x20 custom-border canvas. --draw may be specified more than once.
define_border_pattern() {
    local name=""
    local pixel_map=""
    local outer_sequence=""
    local outer_mode="repeat"
    local inner_sequence=""
    local inner_mode="repeat"
    local -a draw_specs=()

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for define_border_pattern option: $1"

        case "$1" in
            --name)
                name="$2"
                ;;
            --pixel-map|--map)
                pixel_map="$2"
                ;;
            --outer-sequence)
                outer_sequence="$2"
                ;;
            --outer-mode)
                outer_mode="$2"
                ;;
            --inner-sequence)
                inner_sequence="$2"
                ;;
            --inner-mode)
                inner_mode="$2"
                ;;
            --draw)
                draw_specs+=("$2")
                ;;
            *)
                die "Unsupported define_border_pattern option: $1"
                ;;
        esac
        shift 2
    done

    [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]] ||
        die "Invalid border pattern name '$name'. Use lowercase letters, numbers, and underscores."
    [[ -z "${BORDER_PATTERN_CONFIG[$name.registered]:-}" ]] ||
        die "Border pattern '$name' is already defined."
    [[ "$outer_mode" == "repeat" || "$outer_mode" == "once" ]] ||
        die "Border pattern '$name' has invalid outer mode '$outer_mode'."
    [[ "$inner_mode" == "repeat" || "$inner_mode" == "once" ]] ||
        die "Border pattern '$name' has invalid inner mode '$inner_mode'."
    [[ -z "$pixel_map" || (-z "$outer_sequence" && -z "$inner_sequence") ]] ||
        die "Border pattern '$name' cannot combine --pixel-map with perimeter sequences."
    if [[ -z "$pixel_map" && -z "$outer_sequence" && -z "$inner_sequence" && ${#draw_specs[@]} -eq 0 ]]; then
        die "Border pattern '$name' does not define any geometry."
    fi

    BORDER_PATTERNS+=("$name")
    BORDER_PATTERN_CONFIG["$name.registered"]=1
    BORDER_PATTERN_CONFIG["$name.pixel_map"]="$pixel_map"
    BORDER_PATTERN_CONFIG["$name.outer_sequence"]="$outer_sequence"
    BORDER_PATTERN_CONFIG["$name.outer_mode"]="$outer_mode"
    BORDER_PATTERN_CONFIG["$name.inner_sequence"]="$inner_sequence"
    BORDER_PATTERN_CONFIG["$name.inner_mode"]="$inner_mode"
    BORDER_PATTERN_CONFIG["$name.draw_count"]="${#draw_specs[@]}"
    if [[ -n "$pixel_map" ]]; then
        local map_width
        local map_height
        read -r map_width map_height < <(get_pixel_map_dimensions "$pixel_map")
        BORDER_PATTERN_CONFIG["$name.map_width"]="$map_width"
        BORDER_PATTERN_CONFIG["$name.map_height"]="$map_height"
    else
        BORDER_PATTERN_CONFIG["$name.map_width"]=0
        BORDER_PATTERN_CONFIG["$name.map_height"]=0
    fi

    local index
    for ((index = 0; index < ${#draw_specs[@]}; index++)); do
        BORDER_PATTERN_CONFIG["$name.draw.$index"]="${draw_specs[$index]}"
    done
}

# define_border_style --name NAME --pattern PATTERN --colors "slot=value ..."
#
# Maps a reusable pattern's symbolic color slots to real colors.
define_border_style() {
    local name=""
    local pattern=""
    local colors=""

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for define_border_style option: $1"

        case "$1" in
            --name)
                name="$2"
                ;;
            --pattern)
                pattern="$2"
                ;;
            --colors)
                colors="$2"
                ;;
            *)
                die "Unsupported define_border_style option: $1"
                ;;
        esac
        shift 2
    done

    [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]] ||
        die "Invalid border style name '$name'. Use lowercase letters, numbers, and underscores."
    [[ -z "${BORDER_STYLE_CONFIG[$name.registered]:-}" ]] ||
        die "Border style '$name' is already defined."

    [[ -n "${BORDER_PATTERN_CONFIG[$pattern.registered]:-}" ]] ||
        die "Border style '$name' references unknown pattern '$pattern'."
    [[ -n "$colors" ]] ||
        die "Border style '$name' requires --colors."

    BORDER_STYLE_CONFIG["$name.pattern"]="$pattern"
    BORDER_STYLE_CONFIG["$name.slots"]=""

    local assignment
    local slot
    local value
    for assignment in $colors; do
        [[ "$assignment" == *=* ]] ||
            die "Invalid color mapping '$assignment' in border style '$name'. Use slot=value."
        slot="${assignment%%=*}"
        value="${assignment#*=}"
        [[ "$slot" =~ ^[A-Za-z][A-Za-z0-9_]*$ && -n "$value" ]] ||
            die "Invalid color mapping '$assignment' in border style '$name'."
        [[ -z "${BORDER_STYLE_CONFIG[$name.slot.$slot]:-}" ]] ||
            die "Border style '$name' assigns '$slot' more than once."
        BORDER_STYLE_CONFIG["$name.slot.$slot"]="$value"
        BORDER_STYLE_CONFIG["$name.slots"]+="${BORDER_STYLE_CONFIG[$name.slots]:+ }$slot"
    done

    BORDER_STYLES+=("$name")
    BORDER_STYLE_CONFIG["$name.registered"]=1
}

# Prints the unique color-slot names referenced by one border pattern.
# Argument: pattern name.
list_border_pattern_slots() {
    local pattern="$1"
    local token
    local sequence
    local draw_index
    local draw_definition

    for token in ${BORDER_PATTERN_CONFIG[$pattern.pixel_map]//\// }; do
        if [[ "$token" != "X" && "$token" != "." ]]; then
            printf '%s\n' "$token"
        fi
    done

    for sequence in \
        "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}" \
        "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}"
    do
        for token in $sequence; do
            printf '%s\n' "${token%%:*}"
        done
    done

    for ((draw_index = 0; draw_index < ${BORDER_PATTERN_CONFIG[$pattern.draw_count]}; draw_index++)); do
        draw_definition="${BORDER_PATTERN_CONFIG[$pattern.draw.$draw_index]}"
        printf '%s\n' "${draw_definition%%|*}"
    done
}

# Prints the number of pixels represented by a slot:count sequence.
# Argument: sequence string. Invalid runs are rejected by configuration validation.
get_border_sequence_pixel_count() {
    local sequence="$1"
    local run
    local count=0

    for run in $sequence; do
        count=$((count + ${run##*:}))
    done

    printf '%s\n' "$count"
}

# define_symbol --name NAME (--pixel-map MAP|--draw SPEC|--file PNG|--mask PNG)
#
# Registers reusable symbol geometry. Pixel maps use X for transparency and
# any other token for an opaque symbol pixel. --aliases accepts comma- or
# space-separated names. This function only stores configuration.

# Returns one property from a registered symbol, or an empty string.
# Arguments: symbol name, property name.
get_symbol_property() {
    local symbol="$1"
    local property="$2"
    local key="${symbol}.${property}"

    printf '%s\n' "${SYMBOL_CONFIG[$key]:-}"
}

# Resolves a canonical symbol or alias and prints its canonical name.
# Argument: requested symbol name. Returns failure when unknown.
resolve_symbol_name() {
    local symbol="$1"

    if [[ -n "${SYMBOL_CONFIG[$symbol.type]:-}" ]]; then
        printf '%s\n' "$symbol"
        return 0
    fi

    if [[ -n "${SYMBOL_ALIASES[$symbol]:-}" ]]; then
        printf '%s\n' "${SYMBOL_ALIASES[$symbol]}"
        return 0
    fi

    return 1
}

# Registers a pixel-map, drawn, alpha, or black/white-mask symbol.
# Arguments: declarative define_symbol options documented in the recipe file.
define_symbol() {
    local name=""
    local source=""
    local type=""
    local draw_spec=""
    local pixel_map=""
    local aliases=""

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for define_symbol option: $1"

        case "$1" in
            --name)
                name="$2"
                ;;
            --file)
                source="$2"
                type="alpha"
                ;;
            --mask)
                source="$2"
                type="copy"
                ;;
            --draw)
                draw_spec="$2"
                type="draw"
                ;;
            --pixel-map)
                pixel_map="$2"
                type="pixelmap"
                ;;
            --aliases)
                aliases="$2"
                ;;
            *)
                die "Unsupported define_symbol option: $1"
                ;;
        esac
        shift 2
    done

    [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]] ||
        die "Invalid symbol name '$name'. Use lowercase letters, numbers, and underscores."
    [[ -n "$type" ]] ||
        die "define_symbol requires --pixel-map, --file, --mask, or --draw for '$name'."
    if [[ -n "${SYMBOL_CONFIG[$name.type]:-}" || -n "${SYMBOL_ALIASES[$name]:-}" ]]; then
        die "Symbol or alias '$name' is already defined."
    fi

    SYMBOLS+=("$name")
    SYMBOL_CONFIG["$name.type"]="$type"
    SYMBOL_CONFIG["$name.output"]="${name}-core.png"
    SYMBOL_CONFIG["$name.source"]="$source"
    SYMBOL_CONFIG["$name.draw"]="$draw_spec"
    SYMBOL_CONFIG["$name.pixel_map"]="$pixel_map"

    local alias
    for alias in ${aliases//,/ }; do
        [[ "$alias" =~ ^[a-z][a-z0-9_]*$ ]] ||
            die "Invalid alias '$alias' for symbol '$name'."
        if [[ -n "${SYMBOL_CONFIG[$alias.type]:-}" || -n "${SYMBOL_ALIASES[$alias]:-}" ]]; then
            die "Symbol or alias '$alias' is already defined."
        fi
        SYMBOL_ALIASES["$alias"]="$name"
    done
}

# create_tech_symbol --techs "1 2" --pixel-map ... --colors ...
#                    [--for-shape SHAPE]
#
# Definitions are global by default. --for-shape registers an exact visual
# override.
create_tech_symbol() {
    local techs=""
    local pixel_map=""
    local colors=""
    local for_shapes=""
    local none_flag=""

    while (($# > 0)); do
        case "$1" in
            --none)
                none_flag=1
                shift
                continue
                ;;
        esac
        (($# >= 2)) || die "Missing value for create_tech_symbol option: $1"
        case "$1" in
            --techs)
                techs="$2"
                ;;
            --pixel-map)
                pixel_map="$2"
                ;;
            --colors)
                colors="$2"
                ;;
            --for-shape)
                for_shapes="$2"
                ;;
            *)
                die "Unsupported create_tech_symbol option: $1"
                ;;
        esac
        shift 2
    done

    [[ -n "$techs" ]] || die "create_tech_symbol requires --techs"
    [[ -n "$none_flag" || -n "$pixel_map" ]] ||
        die "create_tech_symbol requires --pixel-map or --none."
    [[ -n "$none_flag" || -n "$colors" ]] ||
        die "create_tech_symbol with --pixel-map requires --colors."

    # Normalize tech list
    techs="${techs//,/ }"
    local tech
    local shape
    local scope
    # Accept either comma- or space-separated shape override lists.
    IFS=$' ,\t' read -r -a shapes_arr <<< "${for_shapes//\"/}"
    declare -a scopes=()
    declare -A seen_scopes=()
    for shape in "${shapes_arr[@]}"; do
        shape="$(echo "$shape" | tr -d ' \t\"')"
        if [[ -z "$shape" ]]; then
            continue
        fi
        if [[ -n "${SHAPE_CONFIG[$shape.registered]:-}" ]]; then
            scope="$shape"
        else
            case "$shape" in
                diamond) scope=diamond ;;
                square|structure) scope=structure ;;
                *) scope=unit ;;
            esac
        fi
        if [[ -z "${seen_scopes[$scope]:-}" ]]; then
            scopes+=("$scope")
            seen_scopes["$scope"]=1
        fi
    done
    # No shape means one global recipe shared by every geometry.
    if ((${#scopes[@]} == 0)); then
        scopes+=(all)
    fi

    for tech in $techs; do
        for scope in "${scopes[@]}"; do
            # Register TECH symbol directly to avoid subshell/quoting issues
            [[ -z "${TECH_SYMBOL_CONFIG[$scope.$tech.type]:-}" ]] ||
                die "TECH$tech symbol for scope '$scope' is already defined."
            local type="pixelmap"
            [[ -z "$none_flag" ]] || type="none"
            TECH_SYMBOLS+=("$scope:$tech")
            TECH_SYMBOL_CONFIG["$scope.$tech.type"]="$type"
            TECH_SYMBOL_CONFIG["$scope.$tech.output"]="tech${tech}-${scope}-symbol.png"
            TECH_SYMBOL_CONFIG["$scope.$tech.pixel_map"]="$pixel_map"
            TECH_SYMBOL_CONFIG["$scope.$tech.pixel_colors"]="$colors"
            if [[ -n "$pixel_map" ]]; then
                IFS=$'\n' read -r -d '' -a _pm_lines < <(printf '%s' "$pixel_map" | sed -E 's/^[ \t]+//;s/[ \t]+$//' | tr -d '\r' && printf '\0')
                local pm_h=${#_pm_lines[@]}
                local pm_w=0
                if (( pm_h > 0 )); then
                    read -r -a _tokens <<< "${_pm_lines[0]}"
                    pm_w=${#_tokens[@]}
                fi
                TECH_SYMBOL_CONFIG["$scope.$tech.width"]="$pm_w"
                TECH_SYMBOL_CONFIG["$scope.$tech.height"]="$pm_h"
            fi
        done
    done
}

# create_icon --name NAME --shape SHAPE
#                     --techs "1 2 3" --symbol SYMBOL --color COLOR
#                     [--target-categories "CATEGORY ..."]
#                     [--target-icon-names "StrategicIconName ..."]
#                     [--exclude-blueprints "unit_id ..."]
#                     [--border STYLE]
#                     [--border-at-selected-state white-border|player-color-border|none]
#
# Registers an icon family rendered from four independent transparent layers.
# Hover states always recolor the interaction frame to the player color.
create_icon() {
    local name=""
    local shape=""
    local techs=""
    local symbol=""
    local symbol_color=""
    local background_color="$player_color"
    local border_color="$black"
    local border_style=""
    local selected_border="white-border"
    local target_categories=""
    local target_icon_names=""
    local excluded_blueprints=""

    while (($# > 0)); do
        (($# >= 2)) || die "Missing value for create_icon option: $1"
        case "$1" in
            --name) name="$2" ;;
            --shape) shape="$2" ;;
            --techs) techs="$2" ;;
            --symbol) symbol="$2" ;;
            --color|--symbol-color) symbol_color="$2" ;;
            --background-color) background_color="$2" ;;
            --border-color) border_color="$2" ;;
            --border) border_style="$2" ;;
            --border-at-selected-state) selected_border="$2" ;;
            --target-categories) target_categories="$2" ;;
            --target-icon-names) target_icon_names="$2" ;;
            --exclude-blueprints) excluded_blueprints="$2" ;;
            *) die "Unsupported create_icon option: $1" ;;
        esac
        shift 2
    done

    [[ -n "$name" && -n "$shape"
        && -n "$techs" && -n "$symbol" && -n "$symbol_color" ]] ||
        die "create_icon requires name, shape, techs, symbol, and color."
    [[ -n "$target_categories" || -n "$target_icon_names" ]] ||
        die "Icon '$name' requires target-categories or target-icon-names so the generated DDS is assigned in game."
    name="${name#nextui_}"
    [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]] ||
        die "Invalid icon name '$name'."
    [[ -n "${SHAPE_CONFIG[$shape.registered]:-}" ]] ||
        die "Icon '$name' references unknown shape '$shape'."
    if [[ -n "$border_style" ]]; then
        [[ -n "${BORDER_STYLE_CONFIG[$border_style.registered]:-}" ]] ||
            die "Icon '$name' references unknown border style '$border_style'."
    fi
    case "$selected_border" in
        white-border|player-color-border|none) ;;
        *)
            die "Icon '$name' has unsupported selected border '$selected_border'. Use white-border, player-color-border, or none."
            ;;
    esac

    local target
    for target in $target_categories; do
        [[ "$target" =~ ^[A-Z][A-Z0-9_]*$ ]] ||
            die "Icon '$name' has invalid target category '$target'."
    done
    for target in $target_icon_names; do
        [[ "$target" =~ ^[A-Za-z0-9_./-]+$ ]] ||
            die "Icon '$name' has invalid target StrategicIconName '$target'."
    done
    for target in $excluded_blueprints; do
        [[ "$target" =~ ^[A-Za-z0-9_-]+$ ]] ||
            die "Icon '$name' has invalid excluded blueprint '$target'."
    done

    local normalized_techs="${techs//,/ }"
    local -a tech_list=()
    read -r -a tech_list <<< "$normalized_techs"
    ((${#tech_list[@]} > 0)) ||
        die "create_icon requires at least one tech."

    local tech
    local state
    local output_name
    local output_file

    for tech in "${tech_list[@]}"; do
        [[ "$tech" =~ ^[1234]$ ]] ||
            die "Invalid technology '$tech' for icon '$name'."
        output_name="${name}${tech}"
        for state in "${ICON_STATES[@]}"; do
            output_file="nextui_${output_name}_${state}.dds"
            [[ -z "${PLANNED_ICON_OUTPUTS[$output_file]:-}" ]] ||
                die "Two icon definitions generate the same file: $output_file"
            PLANNED_ICON_OUTPUTS["$output_file"]=1
        done
    done

    local definition_id="${#ICON_DEFINITIONS[@]}"
    ICON_DEFINITIONS+=("$definition_id")
    ICON_CONFIG["$definition_id.name"]="$name"
    ICON_CONFIG["$definition_id.shape"]="$shape"
    ICON_CONFIG["$definition_id.techs"]="${tech_list[*]}"
    ICON_CONFIG["$definition_id.symbol"]="$symbol"
    ICON_CONFIG["$definition_id.symbol_color"]="$symbol_color"
    ICON_CONFIG["$definition_id.background_color"]="$background_color"
    ICON_CONFIG["$definition_id.border_color"]="$border_color"
    ICON_CONFIG["$definition_id.border_style"]="$border_style"
    ICON_CONFIG["$definition_id.selected_border"]="$selected_border"
    ICON_CONFIG["$definition_id.target_categories"]="$target_categories"
    ICON_CONFIG["$definition_id.target_icon_names"]="$target_icon_names"
    ICON_CONFIG["$definition_id.excluded_blueprints"]="$excluded_blueprints"
}
