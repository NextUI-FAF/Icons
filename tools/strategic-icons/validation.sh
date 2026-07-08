# Configuration loading, structural validation, and read-only listing modes.

# Sources the user-editable recipe file after checking that it exists.
load_icon_config() {
    require_file "$CONFIG_FILE" "Missing strategic icon config"
    require_file "$MOD_ICONS_TEMPLATE" "Missing mod_icons.lua template"

    # The config defines colors and calls create_icon.
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
}

# Validates recipe structure and referenced source-file availability.
validate_configuration() {
    local symbol
    local type
    local source
    local definition_id
    local requested_symbol
    local symbol_mask
    local pattern
    local pixel_map
    local -a map_cells=()
    local map_index
    local map_row
    local map_column
    local map_cell
    local border_map_width
    local border_map_height
    local border_row
    local -a border_map_rows=()
    local -a border_map_cells=()

    [[ "$(grep -c '^-- BEGIN GENERATED ICON RULES$' "$MOD_ICONS_TEMPLATE")" == "1"
        && "$(grep -c '^-- END GENERATED ICON RULES$' "$MOD_ICONS_TEMPLATE")" == "1"
    ]] || die "mod_icons.lua template must contain exactly one generated-rules block."
    local sequence
    local run
    local draw_index
    local draw_definition
    local slot
    local style
    local outer_pixel_count
    local inner_pixel_count
    local pixel_colors
    local color_assignment
    local color_slot
    local color_value
    local tech_row_width
    local -a tech_map_rows=()
    local -a tech_map_cells=()
    local -A tech_pixel_palette=()

    local tech
    for tech in 1 2 3; do
        # Ensure at least one TECH symbol is defined for this tech (any scope).
        local found=0
        for k in "${!TECH_SYMBOL_CONFIG[@]}"; do
            if [[ "$k" == *."${tech}".type ]]; then
                found=1
                break
            fi
        done
        [[ $found -eq 1 ]] || die "The strategic icon config must define TECH$tech (use --none to hide it)."
    done

    [[ "${global_tech_icons:-true}" == "true" || "${global_tech_icons:-true}" == "false" ]] ||
        die "global_tech_icons must be true or false."

    local -a symbol_rows=()
    local -a symbol_cells=()
    local symbol_width
    local symbol_row
    local symbol_cell
    local symbol_has_pixels
    for symbol in "${SYMBOLS[@]}"; do
        [[ "$(get_symbol_property "$symbol" type)" == "pixelmap" ]] || continue
        pixel_map="$(get_symbol_property "$symbol" pixel_map)"
        IFS=$'\n' read -r -d '' -a symbol_rows < <(
            printf '%s' "$pixel_map" |
                sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                tr -d '\r'
            printf '\0'
        )
        ((${#symbol_rows[@]} > 0)) ||
            die "Symbol '$symbol' pixel map is empty."
        symbol_width=0
        symbol_has_pixels=false
        for ((symbol_row = 0; symbol_row < ${#symbol_rows[@]}; symbol_row++)); do
            read -r -a symbol_cells <<< "${symbol_rows[$symbol_row]}"
            if ((symbol_width == 0)); then
                symbol_width="${#symbol_cells[@]}"
                ((symbol_width > 0)) ||
                    die "Symbol '$symbol' pixel map has an empty first row."
            else
                ((${#symbol_cells[@]} == symbol_width)) ||
                    die "Symbol '$symbol' pixel-map rows must all contain $symbol_width cells."
            fi
            for symbol_cell in "${symbol_cells[@]}"; do
                if [[ "$symbol_cell" != "X" && "$symbol_cell" != "." ]]; then
                    symbol_has_pixels=true
                fi
            done
        done
        [[ "$symbol_has_pixels" == true ]] ||
            die "Symbol '$symbol' pixel map contains no visible pixels."
    done

    local shape
    local state
    local canvas_width
    local canvas_height
    local -a shape_rows=()
    local -a shape_cells=()
    local shape_row
    local shape_column
    local position_x
    local position_y
    local shape_width
    local shape_height
    for shape in "${SHAPES[@]}"; do
        for state in "${ICON_STATES[@]}"; do
            [[ "${SHAPE_CONFIG[$shape.$state.canvas_size]}" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]] ||
                die "Shape '$shape' has invalid $state canvas size."
            canvas_width="${SHAPE_CONFIG[$shape.$state.canvas_size]%x*}"
            canvas_height="${SHAPE_CONFIG[$shape.$state.canvas_size]#*x}"
            read_layer_position "${SHAPE_CONFIG[$shape.$state.shape_position]}" position_x position_y
            pixel_map="${SHAPE_CONFIG[$shape.$state.pixel_map]}"
            IFS=$'\n' read -r -d '' -a shape_rows < <(
                printf '%s' "$pixel_map" |
                    sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                    tr -d '\r'
                printf '\0'
            )
            ((${#shape_rows[@]} > 0)) ||
                die "Shape '$shape' $state map is empty."
            shape_height="${#shape_rows[@]}"
            shape_width=0
            visible_left=false
            visible_right=false
            for ((shape_row = 0; shape_row < ${#shape_rows[@]}; shape_row++)); do
                read -r -a shape_cells <<< "${shape_rows[$shape_row]}"
                if ((shape_width == 0)); then
                    shape_width="${#shape_cells[@]}"
                else
                    ((${#shape_cells[@]} == shape_width)) ||
                        die "Shape '$shape' $state rows must all contain $shape_width cells."
                fi
                for ((shape_column = 0; shape_column < ${#shape_cells[@]}; shape_column++)); do
                    [[ "${shape_cells[$shape_column]}" =~ ^[XFB]$ ]] ||
                        die "Shape '$shape' uses '${shape_cells[$shape_column]}' at $state column $((shape_column + 1)), row $((shape_row + 1)); use X, F, or B."
                done
                if [[ "${shape_cells[0]}" =~ ^[FB]$ ]]; then
                    visible_left=true
                fi
                if [[ "${shape_cells[$((shape_width - 1))]}" =~ ^[FB]$ ]]; then
                    visible_right=true
                fi
            done
            [[ "${shape_rows[0]}" =~ (^|[[:space:]])[FB]([[:space:]]|$) ]] ||
                die "Shape '$shape' $state map has transparent padding on top; shape maps must use a tight local bounding box."
            [[ "${shape_rows[$((shape_height - 1))]}" =~ (^|[[:space:]])[FB]([[:space:]]|$) ]] ||
                die "Shape '$shape' $state map has transparent padding on bottom; shape maps must use a tight local bounding box."
            [[ "$visible_left" == true ]] ||
                die "Shape '$shape' $state map has transparent padding on the left; shape maps must use a tight local bounding box."
            [[ "$visible_right" == true ]] ||
                die "Shape '$shape' $state map has transparent padding on the right; shape maps must use a tight local bounding box."
            ((position_x >= 0 && position_y >= 0
                && position_x + shape_width <= canvas_width
                && position_y + shape_height <= canvas_height)) ||
                die "Shape '$shape' $state map falls outside its $canvas_width x $canvas_height canvas."
        done
        read_layer_position "${SHAPE_CONFIG[$shape.symbol_offset]}" position_x position_y
        read_layer_position "${SHAPE_CONFIG[$shape.tech_offset]}" position_x position_y
        if [[ -n "${SHAPE_CONFIG[$shape.symbol_position]}" ]]; then
            read_layer_position "${SHAPE_CONFIG[$shape.symbol_position]}" position_x position_y
        fi
        if [[ -n "${SHAPE_CONFIG[$shape.tech_position]}" ]]; then
            read_layer_position "${SHAPE_CONFIG[$shape.tech_position]}" position_x position_y
        fi
    done

    local entry
    local scope
    for entry in "${TECH_SYMBOLS[@]}"; do
        scope="${entry%%:*}"
        tech="${entry#*:}"
        type="${TECH_SYMBOL_CONFIG[$scope.$tech.type]}"
        case "$type" in
            copy|alpha)
                source="${TECH_SYMBOL_CONFIG[$scope.$tech.source]}"
                require_file "$source" "Missing source for TECH$tech/$scope symbol"
                ;;
            pixelmap)
                pixel_map="${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_map]}"
                pixel_colors="${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_colors]}"
                tech_pixel_palette=()

                for color_assignment in $pixel_colors; do
                    [[ "$color_assignment" =~ ^([A-WY-Z])=(.+)$ ]] ||
                        die "Invalid TECH$tech/$scope color assignment '$color_assignment'. Use LETTER=color and reserve X for transparency."
                    color_slot="${BASH_REMATCH[1]}"
                    color_value="${BASH_REMATCH[2]}"
                    [[ -z "${tech_pixel_palette[$color_slot]:-}" ]] ||
                        die "TECH$tech/$scope assigns pixel-map slot '$color_slot' more than once."
                    tech_pixel_palette["$color_slot"]="$color_value"
                done

                IFS=$'\n' read -r -d '' -a tech_map_rows < <(
                    printf '%s' "$pixel_map" |
                        sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                        tr -d '\r'
                    printf '\0'
                )
                ((${#tech_map_rows[@]} > 0)) ||
                    die "TECH$tech/$scope pixel-map is empty."

                tech_row_width=0
                for map_row in "${tech_map_rows[@]}"; do
                    read -r -a tech_map_cells <<< "$map_row"
                    if ((tech_row_width == 0)); then
                        tech_row_width=${#tech_map_cells[@]}
                    elif ((${#tech_map_cells[@]} != tech_row_width)); then
                        die "TECH$tech/$scope pixel-map rows must all contain $tech_row_width cells."
                    fi

                    for map_cell in "${tech_map_cells[@]}"; do
                        [[ "$map_cell" == "X" || "$map_cell" == "." ]] && continue
                        [[ "$map_cell" =~ ^[A-WY-Z]$ ]] ||
                            die "TECH$tech/$scope pixel-map has invalid cell '$map_cell'. Use one letter, X, or '.'."
                        [[ -n "${tech_pixel_palette[$map_cell]:-}" ]] ||
                            die "TECH$tech/$scope pixel-map uses slot '$map_cell' without assigning it in --colors."
                    done
                done
                ;;
        esac
    done

    for symbol in "${SYMBOLS[@]}"; do
        type="$(get_symbol_property "$symbol" type)"
        case "$type" in
            copy|alpha|extract)
                source="$(get_symbol_property "$symbol" source)"
                require_file "$source" "Missing source for symbol '$symbol'"
                ;;
        esac
    done

    for pattern in "${BORDER_PATTERNS[@]}"; do
        pixel_map="${BORDER_PATTERN_CONFIG[$pattern.pixel_map]}"
        if [[ -n "$pixel_map" ]]; then
            pixel_map="${pixel_map//\//$'\n'}"
            IFS=$'\n' read -r -d '' -a border_map_rows < <(
                printf '%s' "$pixel_map" |
                    sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                    tr -d '\r'
                printf '\0'
            )
            border_map_width="${BORDER_PATTERN_CONFIG[$pattern.map_width]}"
            border_map_height="${BORDER_PATTERN_CONFIG[$pattern.map_height]}"
            ((${#border_map_rows[@]} == border_map_height)) ||
                die "Border pattern '$pattern' map height changed after registration."

            for ((map_row = 0; map_row < border_map_height; map_row++)); do
                border_row="${border_map_rows[$map_row]}"
                read -r -a border_map_cells <<< "$border_row"
                ((${#border_map_cells[@]} == border_map_width)) ||
                    die "Border pattern '$pattern' row $((map_row + 1)) must contain $border_map_width cells."
                for ((map_column = 0; map_column < border_map_width; map_column++)); do
                    map_cell="${border_map_cells[$map_column]}"
                    [[ "$map_cell" == "X" || "$map_cell" == "."
                        || "$map_cell" =~ ^[A-WY-Z]$ ]] ||
                        die "Border pattern '$pattern' has invalid cell '$map_cell' at column $((map_column + 1)), row $((map_row + 1)). Use A-W, Y-Z, X, or '.'."
                done
            done
        fi

        for sequence in \
            "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}" \
            "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}"
        do
            for run in $sequence; do
                [[ "$run" =~ ^[A-Za-z][A-Za-z0-9_]*:[1-9][0-9]*$ ]] ||
                    die "Invalid run '$run' in border pattern '$pattern'. Use slot:positive_pixel_count."
            done
        done

        if [[ "${BORDER_PATTERN_CONFIG[$pattern.outer_mode]}" == "once"
            && -n "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}"
        ]]; then
            outer_pixel_count="$(get_border_sequence_pixel_count "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}")"
            ((outer_pixel_count == CUSTOM_BORDER_OUTER_PERIMETER_PIXELS)) ||
                die "Border pattern '$pattern' outer sequence uses $outer_pixel_count pixels; once mode requires $CUSTOM_BORDER_OUTER_PERIMETER_PIXELS."
        fi

        if [[ "${BORDER_PATTERN_CONFIG[$pattern.inner_mode]}" == "once"
            && -n "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}"
        ]]; then
            inner_pixel_count="$(get_border_sequence_pixel_count "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}")"
            ((inner_pixel_count == CUSTOM_BORDER_INNER_PERIMETER_PIXELS)) ||
                die "Border pattern '$pattern' inner sequence uses $inner_pixel_count pixels; once mode requires $CUSTOM_BORDER_INNER_PERIMETER_PIXELS."
        fi

        for ((draw_index = 0; draw_index < ${BORDER_PATTERN_CONFIG[$pattern.draw_count]}; draw_index++)); do
            draw_definition="${BORDER_PATTERN_CONFIG[$pattern.draw.$draw_index]}"
            [[ "$draw_definition" =~ ^[A-Za-z][A-Za-z0-9_]*\|.+$ ]] ||
                die "Invalid draw definition '$draw_definition' in border pattern '$pattern'."
        done
    done

    for style in "${BORDER_STYLES[@]}"; do
        pattern="${BORDER_STYLE_CONFIG[$style.pattern]}"
        while IFS= read -r slot; do
            [[ -n "$slot" ]] || continue
            [[ -n "${BORDER_STYLE_CONFIG[$style.slot.$slot]:-}" ]] ||
                die "Border style '$style' does not assign required slot '$slot' from pattern '$pattern'."
        done < <(list_border_pattern_slots "$pattern" | sort -u)
    done

    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        requested_symbol="${ICON_CONFIG[$definition_id.symbol]}"
        symbol_mask="$(resolve_symbol_mask "$requested_symbol")"

        if ! resolve_symbol_name "$requested_symbol" >/dev/null; then
            require_file "$symbol_mask" \
                "Missing custom symbol mask for '${ICON_CONFIG[$definition_id.name]}'"
        fi
    done

    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        requested_symbol="${ICON_CONFIG[$definition_id.symbol]}"
        symbol_mask="$(resolve_symbol_mask "$requested_symbol")"
        if ! resolve_symbol_name "$requested_symbol" >/dev/null; then
            require_file "$symbol_mask" \
                "Missing custom symbol mask for icon '${ICON_CONFIG[$definition_id.name]}'"
        fi
        shape="${ICON_CONFIG[$definition_id.shape]}"
        local icon_tech
        local icon_scope
        local icon_type
        local icon_width
        local icon_height
        for icon_tech in ${ICON_CONFIG[$definition_id.techs]}; do
            icon_scope="$(resolve_tech_symbol_scope \
                "$icon_tech" "${SHAPE_CONFIG[$shape.tech_scope]}")" ||
                die "No TECH$icon_tech symbol for shape '$shape'."
            icon_type="${TECH_SYMBOL_CONFIG[$icon_scope.$icon_tech.type]}"
            [[ "$icon_type" == "none" ]] && continue
            icon_width="${TECH_SYMBOL_CONFIG[$icon_scope.$icon_tech.width]:-${TECH_SYMBOL_SIZE%x*}}"
            icon_height="${TECH_SYMBOL_CONFIG[$icon_scope.$icon_tech.height]:-${TECH_SYMBOL_SIZE#*x}}"
            for state in "${ICON_STATES[@]}"; do
                canvas_width="${SHAPE_CONFIG[$shape.$state.canvas_size]%x*}"
                canvas_height="${SHAPE_CONFIG[$shape.$state.canvas_size]#*x}"
                local shape_x
                local shape_y
                local tech_offset_x
                local tech_offset_y
                read_layer_position "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
                read -r shape_width shape_height < <(get_shape_map_dimensions "$shape" "$state")
                read_layer_position "${SHAPE_CONFIG[$shape.tech_offset]}" tech_offset_x tech_offset_y
                if [[ -n "${SHAPE_CONFIG[$shape.tech_position]}" ]]; then
                    read_layer_position "${SHAPE_CONFIG[$shape.tech_position]}" position_x position_y
                else
                    position_x=$((shape_x + (shape_width - icon_width) / 2 + tech_offset_x))
                    position_y=$((shape_y + shape_height - ${SHAPE_CONFIG[$shape.tech_overlap]} + tech_offset_y))
                fi
                resolve_icon_layout \
                    "$definition_id" "$icon_tech" "$state"
            done
        done
    done
}

# Fails unless ImageMagick accepts a configured color value.
# Arguments: color value, human-readable property description.
validate_color_value() {
    local color="$1"
    local description="$2"

    magick -size 1x1 "xc:$color" null: 2>/dev/null ||
        die "Invalid $description '$color'."
}

# Uses ImageMagick to validate colors, dimensions, and drawing expressions.
validate_image_configuration() {
    local symbol
    local type
    local source
    local draw_spec
    local expression
    local dimensions
    local opaque
    local definition_id
    local property
    local color
    local requested_symbol
    local symbol_mask
    local style
    local slot
    local pattern
    local draw_index
    local draw_definition
    local tech

    for style in "${BORDER_STYLES[@]}"; do
        for slot in ${BORDER_STYLE_CONFIG[$style.slots]}; do
            color="${BORDER_STYLE_CONFIG[$style.slot.$slot]}"
            case "$color" in
                auto|transparent|none) ;;
                *) validate_color_value "$color" "color for slot '$slot' in border style '$style'" ;;
            esac
        done
    done

    for pattern in "${BORDER_PATTERNS[@]}"; do
        for ((draw_index = 0; draw_index < ${BORDER_PATTERN_CONFIG[$pattern.draw_count]}; draw_index++)); do
            draw_definition="${BORDER_PATTERN_CONFIG[$pattern.draw.$draw_index]}"
            draw_spec="${draw_definition#*|}"
            magick -size "$SELECTED_ICON_SIZE" xc:none \
                -fill white -draw "$draw_spec" null: ||
                die "Invalid draw instructions in border pattern '$pattern'."
        done
    done

    for symbol in "${SYMBOLS[@]}"; do
        type="$(get_symbol_property "$symbol" type)"
        source="$(get_symbol_property "$symbol" source)"

        case "$type" in
            draw)
                draw_spec="$(get_symbol_property "$symbol" draw)"
                magick -size "$NORMAL_ICON_SIZE" xc:black \
                    -fill white -draw "$draw_spec" null: ||
                    die "Invalid draw instructions for symbol '$symbol'."
                ;;
            copy)
                dimensions="$(magick identify -format '%wx%h' "$source")"
                [[ "$dimensions" == "$NORMAL_ICON_SIZE" ]] ||
                    die "Symbol '$symbol' must use a $NORMAL_ICON_SIZE canvas; got $dimensions."
                ;;
            alpha)
                dimensions="$(magick identify -format '%wx%h' "$source")"
                [[ "$dimensions" == "$NORMAL_ICON_SIZE" ]] ||
                    die "Symbol '$symbol' must use a $NORMAL_ICON_SIZE canvas; got $dimensions."
                opaque="$(magick identify -format '%[opaque]' "$source")"
                [[ "$opaque" == "False" ]] ||
                    die "Custom symbol '$symbol' has no transparency. Use --mask for a black/white mask."
                ;;
            extract)
                expression="$(get_symbol_property "$symbol" expression)"
                magick "$source" -alpha off -fx "$expression" null: ||
                    die "Invalid extraction expression for symbol '$symbol'."
                ;;
        esac
    done

    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        for property in symbol_color background_color border_color; do
            color="${ICON_CONFIG[$definition_id.$property]}"
            validate_color_value \
                "$color" \
                "$property for icon '${ICON_CONFIG[$definition_id.name]}'"
        done
    done
}

# Prints command-line usage without loading or generating recipes.
print_help() {
    cat <<'EOF'
Usage: tools/generate_strategic_icons.sh [OPTION]

Generate the strategic icons declared in tools/strategic_icon_config.sh.

Options:
  --check               validate dependencies and recipes without writing files
  --list-symbols        list reusable symbols and their native FAF roles
  --list-shapes         list shape geometry and anchors
  --list-border-patterns
                        list reusable border geometry
  --list-border-styles  list reusable border recipes
  --list-icons          list configured icon families and resolved properties
  -h, --help            show this help

Run tools/strategic_icon_config.sh directly for the same interface.
EOF
}

# Prints registered symbols, their base role, and aliases.
list_symbols() {
    local symbol
    local aliases
    local alias

    printf '%-14s %-10s %s\n' "SYMBOL" "BASE ROLE" "ALIASES"
    for symbol in "${SYMBOLS[@]}"; do
        aliases=""
        for alias in "${!SYMBOL_ALIASES[@]}"; do
            if [[ "$alias" != "$symbol" && "${SYMBOL_ALIASES[$alias]}" == "$symbol" ]]; then
                aliases+="${aliases:+, }$alias"
            fi
        done
        printf '%-14s %-10s %s\n' \
            "$symbol" \
            "$(get_symbol_property "$symbol" role)" \
            "${aliases:--}"
    done
}

# Prints reusable border styles after configuration has been loaded.
list_border_styles() {
    local style
    local pattern
    local palette
    local slot

    printf '%-24s %-20s %s\n' "STYLE" "PATTERN" "PALETTE"
    for style in "${BORDER_STYLES[@]}"; do
        pattern="${BORDER_STYLE_CONFIG[$style.pattern]}"
        palette=""
        for slot in ${BORDER_STYLE_CONFIG[$style.slots]}; do
            palette+="${palette:+, }$slot=${BORDER_STYLE_CONFIG[$style.slot.$slot]}"
        done
        printf '%-24s %-20s %s\n' "$style" "$pattern" "$palette"
    done
}

# Prints registered border geometry independently from style colors.
list_border_patterns() {
    local pattern
    local geometry

    printf '%-24s %s\n' "PATTERN" "GEOMETRY"
    for pattern in "${BORDER_PATTERNS[@]}"; do
        geometry=""
        if [[ -n "${BORDER_PATTERN_CONFIG[$pattern.pixel_map]}" ]]; then
            geometry="${BORDER_PATTERN_CONFIG[$pattern.map_width]}x${BORDER_PATTERN_CONFIG[$pattern.map_height]} pixel map"
        elif [[ -n "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}" ]]; then
            geometry="outer ${BORDER_PATTERN_CONFIG[$pattern.outer_mode]}"
        fi
        if [[ -n "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}" ]]; then
            geometry+="${geometry:+ + }inner ${BORDER_PATTERN_CONFIG[$pattern.inner_mode]}"
        fi
        if ((${BORDER_PATTERN_CONFIG[$pattern.draw_count]} > 0)); then
            geometry+="${geometry:+ + }${BORDER_PATTERN_CONFIG[$pattern.draw_count]} draw layer(s)"
        fi
        printf '%-24s %s\n' "$pattern" "$geometry"
    done
}

# Prints configured shapes.
list_shapes() {
    local shape
    printf '%-18s %-12s %-14s %s\n' \
        "SHAPE" "BASE CANVAS" "SYMBOL AT" "TECH AT"
    for shape in "${SHAPES[@]}"; do
        printf '%-18s %-12s %-14s %s\n' \
            "$shape" \
            "${SHAPE_CONFIG[$shape.canvas_size]}" \
            "${SHAPE_CONFIG[$shape.symbol_position]}" \
            "${SHAPE_CONFIG[$shape.tech_position]}"
    done
}

# Prints the resolved icon-family recipes without generating image files.
list_icons() {
    local definition_id
    local targets

    printf '%-16s %-9s %-12s %-22s %-24s %-20s %-22s %s\n' \
        "ICON" "TECHS" "SYMBOL" "BASE ROLE" "REST BORDER" \
        "SELECTED BORDER" "TARGETS" "SYMBOL COLOR"
    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        targets="${ICON_CONFIG[$definition_id.target_categories]}"
        if [[ -n "${ICON_CONFIG[$definition_id.target_icon_names]}" ]]; then
            targets+="${targets:+; }${ICON_CONFIG[$definition_id.target_icon_names]}"
        fi
        printf '%-16s %-9s %-12s %-22s %-24s %-20s %-22s %s\n' \
            "${ICON_CONFIG[$definition_id.name]}" \
            "${ICON_CONFIG[$definition_id.techs]}" \
            "${ICON_CONFIG[$definition_id.symbol]}" \
            "shape:${ICON_CONFIG[$definition_id.shape]}" \
            "${ICON_CONFIG[$definition_id.border_style]:-shape}" \
            "${ICON_CONFIG[$definition_id.selected_border]}" \
            "$targets" \
            "${ICON_CONFIG[$definition_id.symbol_color]}"
    done
}
