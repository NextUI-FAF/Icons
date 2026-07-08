# ImageMagick rendering primitives and per-state icon composition.

# Renders one registered symbol into the canonical 12x16 black/white mask.
# Argument: symbol name. Output: $MASKS_DIR/<configured output>.
make_symbol_mask() {
    local symbol="$1"
    local type
    local output_name
    local output

    type="$(get_symbol_property "$symbol" type)"
    output_name="$(get_symbol_property "$symbol" output)"

    [[ -n "$type" ]] || die "Missing mask type for symbol: $symbol"
    [[ -n "$output_name" ]] || output_name="${symbol}-core.png"

    output="$MASKS_DIR/$output_name"

    case "$type" in
        pixelmap)
            local pixel_map
            local width
            local height
            local row
            local column
            local -a rows=()
            local -a cells=()
            local -a draw_args=()
            pixel_map="$(get_symbol_property "$symbol" pixel_map)"
            read -r width height < <(get_pixel_map_dimensions "$pixel_map")
            IFS=$'\n' read -r -d '' -a rows < <(
                printf '%s' "$pixel_map" |
                    sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                    tr -d '\r'
                printf '\0'
            )
            for ((row = 0; row < ${#rows[@]}; row++)); do
                read -r -a cells <<< "${rows[$row]}"
                for ((column = 0; column < ${#cells[@]}; column++)); do
                    if [[ "${cells[$column]}" != "X" && "${cells[$column]}" != "." ]]; then
                        draw_args+=(-draw "point $column,$row")
                    fi
                done
            done
            magick -size "${width}x${height}" xc:black -fill white \
                "${draw_args[@]}" "$output"
            ;;

        draw)
            local draw_spec
            draw_spec="$(get_symbol_property "$symbol" draw)"
            [[ -n "$draw_spec" ]] || die "Missing draw specification for symbol: $symbol"

            magick \
                -size "$NORMAL_ICON_SIZE" \
                xc:black \
                -fill white \
                -draw "$draw_spec" \
                "$output"
            ;;

        extract)
            local source
            local expression
            source="$(get_symbol_property "$symbol" source)"
            expression="$(get_symbol_property "$symbol" expression)"

            [[ -n "$source" ]] || die "Missing source file configuration for symbol: $symbol"
            [[ -n "$expression" ]] || die "Missing extraction expression for symbol: $symbol"
            require_file "$source" "Missing artwork master for $symbol"

            magick "$source" \
                -alpha off \
                -fx "$expression" \
                "$output"
            ;;

        copy)
            local source
            source="$(get_symbol_property "$symbol" source)"

            [[ -n "$source" ]] || die "Missing source mask configuration for symbol: $symbol"
            require_file "$source" "Missing custom mask for $symbol"
            magick "$source" \
                -alpha off -colorspace Gray -threshold 50% \
                "$output"
            ;;

        alpha)
            local source
            local opaque
            source="$(get_symbol_property "$symbol" source)"

            [[ -n "$source" ]] || die "Missing symbol artwork for $symbol"
            require_file "$source" "Missing custom symbol for $symbol"
            opaque="$(magick identify -format '%[opaque]' "$source")"
            [[ "$opaque" == "False" ]] ||
                die "Custom symbol '$symbol' has no transparency. Use --mask for a black/white mask."
            magick "$source" -alpha extract "$output"
            ;;

        *)
            die "Unsupported mask type '$type' for symbol: $symbol"
            ;;
    esac

    local dimensions
    dimensions="$(magick identify -format '%wx%h' "$output")"
    [[ "$type" == "pixelmap" || "$dimensions" == "$NORMAL_ICON_SIZE" ]] ||
        die "Symbol '$symbol' must use a $NORMAL_ICON_SIZE canvas; got $dimensions."
}

# Renders masks for every registered symbol.
create_symbol_masks() {
    local symbol

    for symbol in "${SYMBOLS[@]}"; do
        make_symbol_mask "$symbol"
    done
}

# Resolves one letter from a pixel-map palette such as "A=#ffffff B=#000000".
# Arguments: palette string, slot letter. Prints the configured color.
get_pixel_map_color() {
    local palette="$1"
    local requested_slot="$2"
    local assignment
    local slot

    for assignment in $palette; do
        slot="${assignment%%=*}"
        if [[ "$slot" == "$requested_slot" ]]; then
            printf '%s\n' "${assignment#*=}"
            return 0
        fi
    done

    return 1
}

# Renders configured TECH pixel maps.
create_tech_symbol_masks() {
    local entry
    local tech
    local scope
    local type
    local output

    for entry in "${TECH_SYMBOLS[@]}"; do
        scope="${entry%%:*}"
        tech="${entry#*:}"
        type="${TECH_SYMBOL_CONFIG[$scope.$tech.type]}"
        [[ "$type" == "none" ]] && continue

        output="$MASKS_DIR/${TECH_SYMBOL_CONFIG[$scope.$tech.output]}"
        local pixel_map="${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_map]}"
        local pixel_colors="${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_colors]}"
        local width="${TECH_SYMBOL_CONFIG[$scope.$tech.width]}"
        local height="${TECH_SYMBOL_CONFIG[$scope.$tech.height]}"
        local -a rows=()
        local -a cells=()
        local -a draw_args=()
        local row
        local column
        local slot
        local color
        IFS=$'\n' read -r -d '' -a rows < <(
            printf '%s' "$pixel_map" |
                sed -E 's/^[ \t]+//;s/[ \t]+$//' |
                tr -d '\r'
            printf '\0'
        )
        for ((row = 0; row < ${#rows[@]}; row++)); do
            read -r -a cells <<< "${rows[$row]}"
            for ((column = 0; column < ${#cells[@]}; column++)); do
                slot="${cells[$column]}"
                if [[ "$slot" != "X" && "$slot" != "." ]]; then
                    color="$(get_pixel_map_color "$pixel_colors" "$slot")" ||
                        die "TECH$tech/$scope pixel map uses slot '$slot' without assigning it in --colors."
                    draw_args+=(-fill "$color" -draw "point $column,$row")
                fi
            done
        done
        magick -size "${width}x${height}" xc:none "${draw_args[@]}" "$output"
    done
}

# Adds one configured tech marker to an icon, or copies it unchanged when that
# tech deliberately uses --none.
# Arguments: input icon, tech, output icon, requested scope, marker canvas Y.
apply_tech_symbol() {
    local input="$1"
    local tech="$2"
    local output="$3"
    local requested_scope="${4:-all}"
    local marker_y="${5:-}"
    local scope
    scope="$(resolve_tech_symbol_scope "$tech" "$requested_scope")" ||
        die "No TECH$tech symbol is defined for scope '$requested_scope'."
    local type="${TECH_SYMBOL_CONFIG[$scope.$tech.type]:-}"

    if [[ "$type" == "none" || -z "$type" ]]; then
        magick "$input" "$output"
        return
    fi

    local size
    local mask="$MASKS_DIR/${TECH_SYMBOL_CONFIG[$scope.$tech.output]}"
    local placed_mask="$MASKS_DIR/$(basename "$output" .png)-tech-mask.png"
    local target_width
    local target_height
    local offset_x
    local symbol_width
    local symbol_height

    size="$(magick identify -format '%wx%h' "$input")"
    target_width="${size%x*}"
    target_height="${size#*x}"
    symbol_width="${TECH_SYMBOL_CONFIG[$scope.$tech.width]}"
    symbol_height="${TECH_SYMBOL_CONFIG[$scope.$tech.height]}"
    offset_x=$(((target_width - symbol_width) / 2))
    marker_y="${marker_y:-$((target_height - symbol_height))}"

    magick -size "$size" xc:none \
        "$mask" -geometry "+${offset_x}+${marker_y}" -compose SrcOver -composite \
        "$placed_mask"
    magick "$input" "$placed_mask" -composite "$output"
}

# Prints the mask path for a canonical symbol, alias, or direct mask name.
# Argument: requested symbol.
resolve_symbol_mask() {
    local requested_symbol="$1"
    local canonical_symbol
    local output_name

    if canonical_symbol="$(resolve_symbol_name "$requested_symbol")"; then
        output_name="$(get_symbol_property "$canonical_symbol" output)"
        [[ -n "$output_name" ]] || output_name="${canonical_symbol}-core.png"
        printf '%s\n' "$MASKS_DIR/$output_name"
    else
        # An unknown symbol is treated as a custom mask path.
        printf '%s\n' "$requested_symbol"
    fi
}

# Prints a stable fingerprint for a configured symbol recipe or direct mask.
# Generated PNG metadata is intentionally excluded so identical artwork does
# not become stale merely because its intermediate file was recreated.
get_symbol_recipe_fingerprint() {
    local requested_symbol="$1"
    local canonical_symbol
    local source
    local source_fingerprint=""

    if canonical_symbol="$(resolve_symbol_name "$requested_symbol")"; then
        source="$(get_symbol_property "$canonical_symbol" source)"
        if [[ -n "$source" && -f "$source" ]]; then
            source_fingerprint="$(sha256sum "$source" | cut -d ' ' -f 1)"
        fi

        hash_values \
            "$canonical_symbol" \
            "$(get_symbol_property "$canonical_symbol" type)" \
            "$(get_symbol_property "$canonical_symbol" draw)" \
            "$(get_symbol_property "$canonical_symbol" pixel_map)" \
            "$source_fingerprint"
    else
        sha256sum "$requested_symbol" | cut -d ' ' -f 1
    fi
}

# ==============================================================================
# Image and color helpers
# ==============================================================================

# Creates a solid RGBA layer through a grayscale mask.
# Arguments: size, color, mask path, output path.
make_color_layer() {
    local size="$1"
    local color="$2"
    local mask="$3"
    local output="$4"

    magick -size "$size" "xc:$color" "$mask" \
        -alpha off -compose CopyOpacity -composite \
        "$output"
}

# Prints a color interpolated toward another color by a percentage.
# Arguments: source color, target color, percentage.
shade_color() {
    local color="$1"
    local numerator="$2"
    local denominator="$3"
    local hex="${color#\#}"
    local red=$((16#${hex:0:2}))
    local green=$((16#${hex:2:2}))
    local blue=$((16#${hex:4:2}))

    red=$((red * numerator / denominator))
    green=$((green * numerator / denominator))
    blue=$((blue * numerator / denominator))

    ((red > 255)) && red=255
    ((green > 255)) && green=255
    ((blue > 255)) && blue=255

    printf '#%02x%02x%02x\n' "$red" "$green" "$blue"
}

# Prints the deterministic dark companion for a hazard-border color.
# Argument: bright hazard color.
derive_hazard_dark_color() {
    local bright_color="$1"
    local red
    local green
    local blue

    read -r red green blue < <(
        magick -size 1x1 "xc:$bright_color" -colorspace sRGB \
            -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]' \
            info:
    )

    # BC3 interpolates two additional RGB colors between each block's endpoint
    # colors. Choose the dark endpoint so one interpolation lands on FAF's
    # native dark player-color gray:
    #
    #     player_gray = (bright + 2 * dark) / 3
    #
    # This is a compression companion, not a conventional artistic complement.
    red=$(((3 * HAZARD_PLAYER_GRAY_RED - red + 1) / 2))
    green=$(((3 * HAZARD_PLAYER_GRAY_GREEN - green + 1) / 2))
    blue=$(((3 * HAZARD_PLAYER_GRAY_BLUE - blue + 1) / 2))

    ((red < 0)) && red=0
    ((green < 0)) && green=0
    ((blue < 0)) && blue=0
    ((red > 255)) && red=255
    ((green > 255)) && green=255
    ((blue > 255)) && blue=255

    printf '#%02x%02x%02x\n' "$red" "$green" "$blue"
}

# Recolors only FAF's player-color field in a rendered PNG.
# Arguments: source PNG, player color, output PNG.
recolor_player_pixels() {
    local source="$1"
    local color="$2"
    local output="$3"
    local light
    local dark
    local selected_dark

    light="$(shade_color "$color" 126 123)"
    dark="$(shade_color "$color" 90 123)"
    selected_dark="$(shade_color "$color" 85 123)"

    # BC3 stores one RGB palette per 4x4 block. These gray values are the
    # native FAF player-color shades that must be replaced together.
    magick "$source" \
        -fill "$color" -opaque "#7B7D7B" \
        -fill "$light" -opaque "#7E7F7E" \
        -fill "$dark" -opaque "#5A575A" \
        -fill "$dark" -opaque "#5A555A" \
        -fill "$dark" -opaque "#5A565A" \
        -fill "$selected_dark" -opaque "#555555" \
        "$output"
}

# ==============================================================================
# Border masks and styling
# ==============================================================================

# Prints the concrete color assigned to one slot in a pattern-based style.
# The value "auto" derives a companion from color_1; "transparent" becomes none.
# Arguments: style name, slot name.
resolve_border_slot_color() {
    local style="$1"
    local slot="$2"
    local color="${BORDER_STYLE_CONFIG[$style.slot.$slot]:-}"

    [[ -n "$color" ]] ||
        die "Border style '$style' does not assign pattern slot '$slot'."

    case "$color" in
        auto)
            local primary_color="${BORDER_STYLE_CONFIG[$style.slot.color_1]:-}"
            [[ -n "$primary_color" && "$primary_color" != "auto" ]] ||
                die "Border style '$style' needs a concrete color_1 before another slot can use auto."
            derive_hazard_dark_color "$primary_color"
            ;;
        transparent|none)
            printf 'none\n'
            ;;
        *)
            printf '%s\n' "$color"
            ;;
    esac
}

# Appends clockwise perimeter coordinates to a named output array.
# Arguments: output array name, left, top, right, bottom.
append_perimeter_coordinates() {
    local -n output_coordinates="$1"
    local left="$2"
    local top="$3"
    local right="$4"
    local bottom="$5"
    local coordinate

    for ((coordinate = left; coordinate <= right; coordinate++)); do
        output_coordinates+=("$coordinate,$top")
    done
    for ((coordinate = top + 1; coordinate <= bottom; coordinate++)); do
        output_coordinates+=("$right,$coordinate")
    done
    for ((coordinate = right - 1; coordinate >= left; coordinate--)); do
        output_coordinates+=("$coordinate,$bottom")
    done
    for ((coordinate = bottom - 1; coordinate > top; coordinate--)); do
        output_coordinates+=("$left,$coordinate")
    done
}

# Appends colored point commands for a repeatable or exact perimeter sequence.
# Arguments: command variable, style, sequence, mode, bounds, description.
append_border_sequence_draw_commands() {
    local -n output_commands="$1"
    local style="$2"
    local sequence="$3"
    local mode="$4"
    local left="$5"
    local top="$6"
    local right="$7"
    local bottom="$8"
    local description="$9"
    local -a coordinates=()
    local -a slots=()
    local run
    local slot
    local count
    local index
    local repetition
    local color

    append_perimeter_coordinates coordinates "$left" "$top" "$right" "$bottom"

    for run in $sequence; do
        [[ "$run" =~ ^([A-Za-z][A-Za-z0-9_]*):([1-9][0-9]*)$ ]] ||
            die "Invalid run '$run' in $description. Use slot:positive_pixel_count."
        slot="${BASH_REMATCH[1]}"
        count="${BASH_REMATCH[2]}"
        for ((repetition = 0; repetition < count; repetition++)); do
            slots+=("$slot")
        done
    done

    ((${#slots[@]} > 0)) ||
        die "$description does not contain any pixel runs."
    if [[ "$mode" == "once" && ${#slots[@]} -ne ${#coordinates[@]} ]]; then
        die "$description uses ${#slots[@]} pixels but this perimeter requires ${#coordinates[@]}."
    fi

    for ((index = 0; index < ${#coordinates[@]}; index++)); do
        if [[ "$mode" == "once" ]]; then
            slot="${slots[$index]}"
        else
            slot="${slots[$((index % ${#slots[@]}))]}"
        fi
        color="$(resolve_border_slot_color "$style" "$slot")"
        output_commands+=" fill $color point ${coordinates[$index]}"
    done
}

# Renders a visual border map at the requested local origin.
# X and "." are transparent. Map dimensions are inferred from the recipe.
# Arguments: pattern, style, canvas size, output layer, X offset, Y offset.
make_border_pixel_map_layer() {
    local pattern="$1"
    local style="$2"
    local size="$3"
    local output="$4"
    local offset_x="${5:-0}"
    local offset_y="${6:-0}"
    local pixel_map="${BORDER_PATTERN_CONFIG[$pattern.pixel_map]}"
    local -a slots=()
    local index
    local x
    local y
    local slot
    local color
    local draw_commands=""
    local map_width="${BORDER_PATTERN_CONFIG[$pattern.map_width]}"
    local map_height="${BORDER_PATTERN_CONFIG[$pattern.map_height]}"

    pixel_map="${pixel_map//$'\n'/ }"
    read -r -a slots <<< "${pixel_map//\// }"
    ((${#slots[@]} == map_width * map_height)) ||
        die "Border pattern '$pattern' map dimensions changed after registration."

    for ((index = 0; index < ${#slots[@]}; index++)); do
        slot="${slots[$index]}"
        if [[ "$slot" == "X" || "$slot" == "." ]]; then
            continue
        fi
        [[ "$slot" =~ ^[A-WY-Z]$ ]] ||
            die "Invalid cell '$slot' in border pattern '$pattern'. Use A-W, Y-Z, X, or '.'."
        color="$(resolve_border_slot_color "$style" "$slot")"
        x=$((offset_x + index % map_width))
        y=$((offset_y + 1 + index / map_width))
        draw_commands+=" fill $color point $x,$y"
    done

    magick -size "$size" xc:none -type TrueColorAlpha \
        -draw "$draw_commands" "$output"
}

# Renders a configured pixel map, perimeter sequences, and free drawing commands.
# Arguments: output/state names, geometry, style name, offsets, output layer.
make_pattern_border_layer() {
    local output_name="$1"
    local state="$2"
    local size="$3"
    local frame_right="$4"
    local frame_bottom="$5"
    local style="$6"
    local offset_x="$7"
    local offset_y="$8"
    local output="$9"
    local pattern="${BORDER_STYLE_CONFIG[$style.pattern]}"
    local map_layer="$LAYERS_DIR/${output_name}-${state}-pattern-map.png"
    local draw_layer="$LAYERS_DIR/${output_name}-${state}-pattern-draw.png"
    local draw_commands=""
    local outer_sequence="${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}"
    local inner_sequence="${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}"
    local draw_count="${BORDER_PATTERN_CONFIG[$pattern.draw_count]}"
    local draw_index
    local draw_definition
    local slot
    local draw_spec
    local color
    local has_output=false

    if [[ -n "${BORDER_PATTERN_CONFIG[$pattern.pixel_map]}" ]]; then
        make_border_pixel_map_layer \
            "$pattern" "$style" "$size" "$map_layer" "$offset_x" "$offset_y"
        magick "$map_layer" "$output"
        has_output=true
    fi

    if [[ -n "$outer_sequence" ]]; then
        append_border_sequence_draw_commands \
            draw_commands "$style" "$outer_sequence" \
            "${BORDER_PATTERN_CONFIG[$pattern.outer_mode]}" \
            "$offset_x" "$((offset_y + 1))" \
            "$((offset_x + frame_right))" "$((offset_y + frame_bottom))" \
            "outer sequence of border pattern '$pattern'"
    fi

    if [[ -n "$inner_sequence" ]]; then
        append_border_sequence_draw_commands \
            draw_commands "$style" "$inner_sequence" \
            "${BORDER_PATTERN_CONFIG[$pattern.inner_mode]}" \
            "$((offset_x + 1))" "$((offset_y + 2))" \
            "$((offset_x + frame_right - 1))" "$((offset_y + frame_bottom - 1))" \
            "inner sequence of border pattern '$pattern'"
    fi

    for ((draw_index = 0; draw_index < draw_count; draw_index++)); do
        draw_definition="${BORDER_PATTERN_CONFIG[$pattern.draw.$draw_index]}"
        [[ "$draw_definition" == *"|"* ]] ||
            die "Invalid draw definition in border pattern '$pattern'. Use slot|drawing primitives."
        slot="${draw_definition%%|*}"
        draw_spec="${draw_definition#*|}"
        [[ "$slot" =~ ^[A-Za-z][A-Za-z0-9_]*$ && -n "$draw_spec" ]] ||
            die "Invalid draw definition '$draw_definition' in border pattern '$pattern'."
        color="$(resolve_border_slot_color "$style" "$slot")"
        draw_commands+=" fill $color $draw_spec"
    done

    if [[ -n "$draw_commands" ]]; then
        magick -size "$size" xc:none -type TrueColorAlpha \
            -draw "$draw_commands" "$draw_layer"
        if [[ "$has_output" == true ]]; then
            magick "$output" "$draw_layer" -composite "$output"
        else
            magick "$draw_layer" "$output"
        fi
        has_output=true
    fi

    [[ "$has_output" == true ]] ||
        die "Border pattern '$pattern' produced no drawable layers."
}

# Parses an "X Y" or "X,Y" coordinate pair.
read_layer_position() {
    local value="$1"
    local -n output_x_ref="$2"
    local -n output_y_ref="$3"
    local parsed_x
    local parsed_y

    read -r parsed_x parsed_y _ <<< "${value//,/ }"
    [[ "$parsed_x" =~ ^-?[0-9]+$ && "$parsed_y" =~ ^-?[0-9]+$ ]] ||
        die "Invalid layer position '$value'. Use integer X Y coordinates."
    output_x_ref="$parsed_x"
    output_y_ref="$parsed_y"
}

# Prints the width and height of one rectangular shape map.
get_shape_map_dimensions() {
    local shape="$1"
    local state="$2"
    get_pixel_map_dimensions "${SHAPE_CONFIG[$shape.$state.pixel_map]}"
}

# Resolves one icon onto a non-negative, DDS-sized canvas.
#
# Shape maps keep local coordinates. Custom pixel-map borders are center-aligned
# with the shape map. If a border or interaction frame extends left or above
# the local origin, every layer is translated together. Horizontal padding
# introduced by four-pixel DDS rounding is shared as evenly as integer pixels
# allow; vertical padding stays below the artwork to preserve FAF placement.
resolve_icon_layout() {
    local definition_id="$1"
    local tech="$2"
    local state="$3"
    local shape="${ICON_CONFIG[$definition_id.shape]}"
    local border_style="${ICON_CONFIG[$definition_id.border_style]}"
    local configured_size="${SHAPE_CONFIG[$shape.$state.canvas_size]}"
    local configured_width="${configured_size%x*}"
    local configured_height="${configured_size#*x}"
    local shape_x
    local shape_y
    local shape_width
    local shape_height
    if [[ "$state" == "rest" ]]; then
        read_layer_position \
            "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
    else
        # Rest defines the stable normal-state envelope. Hover reuses it
        # exactly; selected states derive FAF's two-pixel inset and four-pixel
        # larger canvas from it so changing state never moves the artwork.
        resolve_icon_layout "$definition_id" "$tech" rest
        local normal_width="${icon_layout_size%x*}"
        local normal_height="${icon_layout_size#*x}"
        if [[ "$state" == "over" ]]; then
            if ((configured_width < normal_width)); then
                configured_width="$normal_width"
            fi
            if ((configured_height < normal_height)); then
                configured_height="$normal_height"
            fi
            shape_x="$icon_layout_shape_x"
            shape_y="$icon_layout_shape_y"
        else
            if ((configured_width < normal_width + 4)); then
                configured_width=$((normal_width + 4))
            fi
            if ((configured_height < normal_height + 4)); then
                configured_height=$((normal_height + 4))
            fi
            shape_x=$((icon_layout_shape_x + 2))
            shape_y=$((icon_layout_shape_y + 2))
        fi
    fi
    read -r shape_width shape_height < <(get_shape_map_dimensions "$shape" "$state")

    local min_x="$shape_x"
    local min_y="$shape_y"
    local max_x=$((shape_x + shape_width - 1))
    local max_y=$((shape_y + shape_height - 1))

    if [[ "$state" == "selected" || "$state" == "selectedover" ]]; then
        ((shape_x - 2 < min_x)) && min_x=$((shape_x - 2))
        ((shape_y - 2 < min_y)) && min_y=$((shape_y - 2))
        ((shape_x + shape_width + 1 > max_x)) &&
            max_x=$((shape_x + shape_width + 1))
        ((shape_y + shape_height + 1 > max_y)) &&
            max_y=$((shape_y + shape_height + 1))
    fi

    local requested_scope="${SHAPE_CONFIG[$shape.tech_scope]}"
    local scope
    scope="$(resolve_tech_symbol_scope "$tech" "$requested_scope")" ||
        die "No TECH$tech symbol is defined for shape '$shape' scope '$requested_scope'."
    if [[ "${TECH_SYMBOL_CONFIG[$scope.$tech.type]}" != "none" ]]; then
        local tech_width="${TECH_SYMBOL_CONFIG[$scope.$tech.width]:-${TECH_SYMBOL_SIZE%x*}}"
        local tech_height="${TECH_SYMBOL_CONFIG[$scope.$tech.height]:-${TECH_SYMBOL_SIZE#*x}}"
        local tech_x
        local tech_y
        local tech_offset_x
        local tech_offset_y
        if [[ -n "${SHAPE_CONFIG[$shape.tech_position]}" ]]; then
            read_layer_position "${SHAPE_CONFIG[$shape.tech_position]}" tech_x tech_y
        else
            read_layer_position "${SHAPE_CONFIG[$shape.tech_offset]}" \
                tech_offset_x tech_offset_y
            tech_x=$((shape_x + (shape_width - tech_width) / 2 + tech_offset_x))
            tech_y=$((shape_y + shape_height
                - ${SHAPE_CONFIG[$shape.tech_overlap]} + tech_offset_y))
        fi
        ((tech_x < min_x)) && min_x="$tech_x"
        ((tech_y < min_y)) && min_y="$tech_y"
        ((tech_x + tech_width - 1 > max_x)) &&
            max_x=$((tech_x + tech_width - 1))
        ((tech_y + tech_height - 1 > max_y)) &&
            max_y=$((tech_y + tech_height - 1))
    fi

    icon_layout_border_offset_x="$shape_x"
    icon_layout_border_offset_y="$shape_y"
    if [[ -n "$border_style"
        && ("$state" == "rest" || "$state" == "over")
    ]]; then
        local pattern="${BORDER_STYLE_CONFIG[$border_style.pattern]}"
        if [[ -n "${BORDER_PATTERN_CONFIG[$pattern.pixel_map]}" ]]; then
            local border_width="${BORDER_PATTERN_CONFIG[$pattern.map_width]}"
            local border_height="${BORDER_PATTERN_CONFIG[$pattern.map_height]}"
            local border_x
            local border_y
            (( (shape_width - border_width) % 2 == 0
                && (shape_height - border_height) % 2 == 0 )) ||
                die "Border pattern '$pattern' cannot center its ${border_width}x${border_height} map on ${shape_width}x${shape_height} shape '$shape'; both dimensions must have matching odd/even parity."
            border_x=$((shape_x + (shape_width - border_width) / 2))
            border_y=$((shape_y + (shape_height - border_height) / 2))
            # Pixel-map border rendering historically treats offset_y as the
            # row immediately above the map. Keep that API detail internal.
            icon_layout_border_offset_x="$border_x"
            icon_layout_border_offset_y=$((border_y - 1))
            ((border_x < min_x)) && min_x="$border_x"
            ((border_y < min_y)) && min_y="$border_y"
            ((border_x + border_width - 1 > max_x)) &&
                max_x=$((border_x + border_width - 1))
            ((border_y + border_height - 1 > max_y)) &&
                max_y=$((border_y + border_height - 1))
        elif [[ -n "${BORDER_PATTERN_CONFIG[$pattern.outer_sequence]}"
            || -n "${BORDER_PATTERN_CONFIG[$pattern.inner_sequence]}"
        ]]; then
            # make_pattern_border_layer uses an outer one-pixel outset and a
            # second inward perimeter for sequence-authored borders.
            icon_layout_border_offset_x=$((shape_x - 1))
            icon_layout_border_offset_y=$((shape_y - 2))
            ((shape_x - 1 < min_x)) && min_x=$((shape_x - 1))
            ((shape_y - 1 < min_y)) && min_y=$((shape_y - 1))
            ((shape_x + shape_width > max_x)) &&
                max_x=$((shape_x + shape_width))
            ((shape_y + shape_height > max_y)) &&
                max_y=$((shape_y + shape_height))
        fi
    fi

    local content_width=$((max_x - min_x + 1))
    local content_height=$((max_y - min_y + 1))
    local canvas_width
    local canvas_height
    canvas_width="$(round_canvas_extent "$content_width")"
    canvas_height="$(round_canvas_extent "$content_height")"
    ((canvas_width < configured_width)) && canvas_width="$configured_width"
    ((canvas_height < configured_height)) && canvas_height="$configured_height"

    local translation_x=$((-min_x + (canvas_width - content_width) / 2))
    local translation_y=$((-min_y))
    icon_layout_shape_x=$((shape_x + translation_x))
    icon_layout_shape_y=$((shape_y + translation_y))
    icon_layout_border_offset_x=$((icon_layout_border_offset_x + translation_x))
    icon_layout_border_offset_y=$((icon_layout_border_offset_y + translation_y))
    icon_layout_size="${canvas_width}x${canvas_height}"
}

# Renders F and B cells from one shape state into independent grayscale masks.
render_shape_region_masks() {
    local shape="$1"
    local state="$2"
    local background_mask="$3"
    local border_mask="$4"
    local size="${5:-${SHAPE_CONFIG[$shape.$state.canvas_size]}}"
    local pixel_map="${SHAPE_CONFIG[$shape.$state.pixel_map]}"
    local -a rows=()
    local -a background_draw=()
    local -a border_draw=()
    local -a cells=()
    local row
    local column
    local shape_x="${6:-}"
    local shape_y="${7:-}"
    if [[ -z "$shape_x" || -z "$shape_y" ]]; then
        read_layer_position \
            "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
    fi

    IFS=$'\n' read -r -d '' -a rows < <(
        printf '%s' "$pixel_map" |
            sed -E 's/^[ \t]+//;s/[ \t]+$//' |
            tr -d '\r'
        printf '\0'
    )
    for ((row = 0; row < ${#rows[@]}; row++)); do
        read -r -a cells <<< "${rows[$row]}"
        for ((column = 0; column < ${#cells[@]}; column++)); do
            case "${cells[$column]}" in
                F) background_draw+=(-draw "point $((column + shape_x)),$((row + shape_y))") ;;
                B) border_draw+=(-draw "point $((column + shape_x)),$((row + shape_y))") ;;
            esac
        done
    done

    magick -size "$size" xc:black -fill white \
        "${background_draw[@]}" "$background_mask"
    magick -size "$size" xc:black -fill white \
        "${border_draw[@]}" "$border_mask"
}

# Combines a shape's background and built-in border into one silhouette mask.
make_shape_silhouette_mask() {
    local background_mask="$1"
    local border_mask="$2"
    local output="$3"

    magick "$background_mask" "$border_mask" \
        -compose Lighten -composite "$output"
}

# Expands a shape silhouette by the requested number of pixels.
make_expanded_shape_mask() {
    local silhouette_mask="$1"
    local pixels="$2"
    local output="$3"

    magick "$silhouette_mask" \
        -morphology Dilate "Square:$pixels" "$output"
}

# Produces only the pixels added around an expanded shape silhouette.
make_external_frame_mask() {
    local silhouette_mask="$1"
    local pixels="$2"
    local output="$3"
    local expanded_mask="${output%.png}-expanded.png"

    make_expanded_shape_mask "$silhouette_mask" "$pixels" "$expanded_mask"
    magick "$expanded_mask" "$silhouette_mask" \
        -fx 'u > 0.5 && v < 0.5 ? 1 : 0' "$output"
}

# Creates one complete symbol layer at the shape's explicit position.
make_symbol_layer() {
    local shape="$1"
    local symbol_mask="$2"
    local symbol_color="$3"
    local output_name="$4"
    local state="$5"
    local output="$6"
    local size="${7:-${SHAPE_CONFIG[$shape.$state.canvas_size]}}"
    local resolved_shape_x="${8:-}"
    local resolved_shape_y="${9:-}"
    local x
    local y
    local offset_x
    local offset_y
    local shape_x
    local shape_y
    local shape_width
    local shape_height
    local trimmed_width
    local trimmed_height

    local core_mask="$MASKS_DIR/${output_name}-${state}-symbol-core.png"
    local trimmed_mask="$MASKS_DIR/${output_name}-${state}-symbol-trimmed.png"
    local outline_mask="$MASKS_DIR/${output_name}-${state}-symbol-outline.png"
    local outline_layer="$LAYERS_DIR/${output_name}-${state}-symbol-outline.png"
    local color_layer="$LAYERS_DIR/${output_name}-${state}-symbol-color.png"

    # Force black to be the trim background. ImageMagick otherwise samples the
    # top-left pixel, which discards symbols whose artwork touches that corner.
    magick "$symbol_mask" -bordercolor black -border 1 \
        -trim +repage "$trimmed_mask"
    read -r trimmed_width trimmed_height < <(
        magick "$trimmed_mask" -format '%w %h\n' info:
    )
    if [[ -n "${SHAPE_CONFIG[$shape.symbol_position]}" ]]; then
        read_layer_position "${SHAPE_CONFIG[$shape.symbol_position]}" x y
        if [[ -n "$resolved_shape_x" && -n "$resolved_shape_y" ]]; then
            read_layer_position \
                "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
            x=$((x + resolved_shape_x - shape_x))
            y=$((y + resolved_shape_y - shape_y))
        fi
    else
        if [[ -n "$resolved_shape_x" && -n "$resolved_shape_y" ]]; then
            shape_x="$resolved_shape_x"
            shape_y="$resolved_shape_y"
        else
            read_layer_position \
                "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
        fi
        read -r shape_width shape_height < <(get_shape_map_dimensions "$shape" "$state")
        read_layer_position "${SHAPE_CONFIG[$shape.symbol_offset]}" offset_x offset_y
        x=$((shape_x + (shape_width - trimmed_width) / 2 + offset_x))
        y=$((shape_y + (shape_height - trimmed_height) / 2 + offset_y))
    fi

    magick -size "$size" xc:black \
        "$trimmed_mask" -geometry "+${x}+${y}" -compose Lighten -composite \
        "$core_mask"
    magick "$core_mask" -morphology Dilate "$SYMBOL_OUTLINE_KERNEL" "$outline_mask"
    make_color_layer "$size" "$SYMBOL_OUTLINE_COLOR" "$outline_mask" "$outline_layer"
    make_color_layer "$size" "$symbol_color" "$core_mask" "$color_layer"
    magick -size "$size" xc:none \
        "$outline_layer" -composite "$color_layer" -composite "$output"
}

# Creates literal tech artwork at the shape's configured anchor.
make_tech_layer() {
    local shape="$1"
    local tech="$2"
    local output_name="$3"
    local state="$4"
    local output="$5"
    local size="${6:-${SHAPE_CONFIG[$shape.$state.canvas_size]}}"
    local resolved_shape_x="${7:-}"
    local resolved_shape_y="${8:-}"
    local requested_scope="${SHAPE_CONFIG[$shape.tech_scope]}"
    local scope
    scope="$(resolve_tech_symbol_scope "$tech" "$requested_scope")" ||
        die "No TECH$tech symbol is defined for shape '$shape' scope '$requested_scope'."
    local type="${TECH_SYMBOL_CONFIG[$scope.$tech.type]}"

    if [[ "$type" == "none" ]]; then
        magick -size "$size" xc:none "$output"
        return
    fi

    local source="$MASKS_DIR/${TECH_SYMBOL_CONFIG[$scope.$tech.output]}"
    local x
    local y
    local offset_x
    local offset_y
    local shape_x
    local shape_y
    local shape_width
    local shape_height
    local tech_width
    local tech_height
    if [[ -n "${SHAPE_CONFIG[$shape.tech_position]}" ]]; then
        read_layer_position "${SHAPE_CONFIG[$shape.tech_position]}" x y
        if [[ -n "$resolved_shape_x" && -n "$resolved_shape_y" ]]; then
            read_layer_position \
                "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
            x=$((x + resolved_shape_x - shape_x))
            y=$((y + resolved_shape_y - shape_y))
        fi
    else
        if [[ -n "$resolved_shape_x" && -n "$resolved_shape_y" ]]; then
            shape_x="$resolved_shape_x"
            shape_y="$resolved_shape_y"
        else
            read_layer_position \
                "${SHAPE_CONFIG[$shape.$state.shape_position]}" shape_x shape_y
        fi
        read -r shape_width shape_height < <(get_shape_map_dimensions "$shape" "$state")
        read -r tech_width tech_height < <(magick "$source" -format '%w %h\n' info:)
        read_layer_position "${SHAPE_CONFIG[$shape.tech_offset]}" offset_x offset_y
        x=$((shape_x + (shape_width - tech_width) / 2 + offset_x))
        y=$((shape_y + shape_height - ${SHAPE_CONFIG[$shape.tech_overlap]} + offset_y))
    fi

    magick -size "$size" xc:none \
        "$source" -geometry "+${x}+${y}" -compose SrcOver -composite \
        "$output"
}

# Composes the four icon layers in their fixed visual order.
compose_icon_layers() {
    local symbol_layer="$1"
    local background_layer="$2"
    local border_layer="$3"
    local tech_layer="$4"
    local size="$5"
    local output="$6"

    magick -size "$size" xc:none \
        "$border_layer" -composite \
        "$background_layer" -composite \
        "$tech_layer" -composite \
        "$symbol_layer" -composite \
        "$output"
}

# Splits marker-free native art into the same symbol/background/border layers
# used by authored icons. F selects the interior; pixels outside F belong to
# the border layer, including native selected-state frames.
split_native_icon_layers() {
    local input="$1"
    local shape="$2"
    local state="$3"
    local output_name="$4"
    local symbol_layer="$5"
    local background_layer="$6"
    local border_layer="$7"
    local size
    size="$(magick "$input" -format '%wx%h' info:)"

    local background_region="$MASKS_DIR/${output_name}-${state}-native-background-region.png"
    local border_region="$MASKS_DIR/${output_name}-${state}-native-border-region.png"
    local native_alpha="$MASKS_DIR/${output_name}-${state}-native-alpha.png"
    local inside_mask="$MASKS_DIR/${output_name}-${state}-native-inside.png"
    local dark_mask="$MASKS_DIR/${output_name}-${state}-native-dark.png"
    local final_background_mask="$MASKS_DIR/${output_name}-${state}-native-background-mask.png"
    local symbol_mask="$MASKS_DIR/${output_name}-${state}-native-symbol-mask.png"
    local border_mask="$MASKS_DIR/${output_name}-${state}-native-border-mask.png"

    render_shape_region_masks \
        "$shape" "$state" "$background_region" "$border_region" "$size"
    magick "$input" -alpha extract -threshold 50% "$native_alpha"
    magick "$native_alpha" "$background_region" \
        -compose Multiply -composite "$inside_mask"
    magick "$input" -alpha off -colorspace Gray \
        -threshold 25% -negate "$dark_mask"
    magick "$inside_mask" "$dark_mask" \
        -compose Multiply -composite "$symbol_mask"
    magick "$inside_mask" "$symbol_mask" \
        -fx 'u > 0.5 && v < 0.5 ? 1 : 0' "$final_background_mask"
    magick "$native_alpha" "$background_region" \
        -fx 'u > 0.5 && v < 0.5 ? 1 : 0' "$border_mask"

    magick "$input" "$symbol_mask" \
        -alpha off -compose CopyOpacity -composite "$symbol_layer"
    magick "$input" "$final_background_mask" \
        -alpha off -compose CopyOpacity -composite "$background_layer"
    magick "$input" "$border_mask" \
        -alpha off -compose CopyOpacity -composite "$border_layer"
}

# Generates one state through the four-layer renderer.
generate_icon_state() {
    local definition_id="$1"
    local output_name="$2"
    local tech="$3"
    local state="$4"
    local name="${ICON_CONFIG[$definition_id.name]}"
    local shape="${ICON_CONFIG[$definition_id.shape]}"
    local symbol="${ICON_CONFIG[$definition_id.symbol]}"
    local symbol_color="${ICON_CONFIG[$definition_id.symbol_color]}"
    local background_color="${ICON_CONFIG[$definition_id.background_color]}"
    local border_color="${ICON_CONFIG[$definition_id.border_color]}"
    local border_style="${ICON_CONFIG[$definition_id.border_style]}"
    local selected_border="${ICON_CONFIG[$definition_id.selected_border]}"
    resolve_icon_layout "$definition_id" "$tech" "$state"
    local size="$icon_layout_size"
    local resolved_shape_x="$icon_layout_shape_x"
    local resolved_shape_y="$icon_layout_shape_y"
    local resolved_border_offset_x="$icon_layout_border_offset_x"
    local resolved_border_offset_y="$icon_layout_border_offset_y"
    local output_filename="nextui_${output_name}_${state}.dds"
    local output_file="$ICONS_DIR/$output_filename"
    local preview_png="$CLEAN_ICON_PREVIEWS_DIR/nextui_${output_name}_${state}.png"
    local dds_compression="$DDS_COMPRESSION"
    if [[ -n "$border_style" ]]; then
        dds_compression="$CUSTOM_BORDER_DDS_COMPRESSION"
    fi
    local fingerprint

    fingerprint="$(hash_values \
        "$GENERATOR_CACHE_VERSION" "icon-v5" "$output_filename" \
        "$name" "$shape" "$tech" "$state" "$symbol" \
        "$symbol_color" "$background_color" "$border_color" "$border_style" \
        "$selected_border" \
        "${SHAPE_CONFIG[$shape.$state.canvas_size]}" \
        "${SHAPE_CONFIG[$shape.$state.pixel_map]}" \
        "${SHAPE_CONFIG[$shape.$state.shape_position]}" \
        "$size" "$resolved_shape_x" "$resolved_shape_y" \
        "$resolved_border_offset_x" "$resolved_border_offset_y" \
        "${SHAPE_CONFIG[$shape.symbol_position]}" \
        "${SHAPE_CONFIG[$shape.symbol_anchor]}" \
        "${SHAPE_CONFIG[$shape.symbol_offset]}" \
        "${SHAPE_CONFIG[$shape.tech_position]}" \
        "${SHAPE_CONFIG[$shape.tech_anchor]}" \
        "${SHAPE_CONFIG[$shape.tech_overlap]}" \
        "${SHAPE_CONFIG[$shape.tech_offset]}" \
        "$(get_symbol_recipe_fingerprint "$symbol")" \
        "$(get_tech_render_fingerprint "$tech" "${SHAPE_CONFIG[$shape.tech_scope]}")" \
        "$border_config_fingerprint" "$dds_compression")"
    if ! icon_needs_generation "$output_filename" "$fingerprint" "$preview_png"; then
        return
    fi

    local background_mask="$MASKS_DIR/${output_name}-${state}-shape-background.png"
    local built_in_border_mask="$MASKS_DIR/${output_name}-${state}-shape-border.png"
    local silhouette_mask="$MASKS_DIR/${output_name}-${state}-shape-silhouette.png"
    local background_layer="$LAYERS_DIR/${output_name}-${state}-layer-background.png"
    local border_layer="$LAYERS_DIR/${output_name}-${state}-layer-border.png"
    local symbol_layer="$LAYERS_DIR/${output_name}-${state}-layer-symbol.png"
    local tech_layer="$LAYERS_DIR/${output_name}-${state}-layer-tech.png"
    render_shape_region_masks \
        "$shape" "$state" "$background_mask" "$built_in_border_mask" \
        "$size" "$resolved_shape_x" "$resolved_shape_y"
    make_shape_silhouette_mask \
        "$background_mask" "$built_in_border_mask" "$silhouette_mask"

    case "$state" in
        rest)
            make_color_layer \
                "$size" "$background_color" "$background_mask" "$background_layer"
            make_color_layer \
                "$size" "$border_color" "$built_in_border_mask" "$border_layer"
            ;;
        over)
            make_color_layer \
                "$size" "$background_color" "$silhouette_mask" "$background_layer"
            magick -size "$size" xc:none "$border_layer"
            ;;
        selected)
            local selected_frame_mask="$MASKS_DIR/${output_name}-${state}-interaction-frame.png"
            make_color_layer \
                "$size" "$background_color" "$silhouette_mask" "$background_layer"
            case "$selected_border" in
                white-border)
                    make_external_frame_mask \
                        "$silhouette_mask" 2 "$selected_frame_mask"
                    make_color_layer \
                        "$size" "$white" "$selected_frame_mask" "$border_layer"
                    ;;
                player-color-border)
                    make_external_frame_mask \
                        "$silhouette_mask" 2 "$selected_frame_mask"
                    make_color_layer \
                        "$size" "$background_color" "$selected_frame_mask" "$border_layer"
                    ;;
                none)
                    magick -size "$size" xc:none "$border_layer"
                    ;;
            esac
            ;;
        selectedover)
            local selected_hover_mask="$MASKS_DIR/${output_name}-${state}-interaction-fill.png"
            make_expanded_shape_mask \
                "$silhouette_mask" 2 "$selected_hover_mask"
            make_color_layer \
                "$size" "$background_color" "$selected_hover_mask" "$background_layer"
            magick -size "$size" xc:none "$border_layer"
            ;;
    esac

    if [[ -n "$border_style" && "$state" == "rest" ]]; then
        local custom_border="$LAYERS_DIR/${output_name}-${state}-layer-custom-border.png"
        local shape_width
        local shape_height
        read -r shape_width shape_height < <(
            get_shape_map_dimensions "$shape" "$state"
        )
        make_pattern_border_layer \
            "$output_name" "$state" "$size" \
            "$((shape_width + 1))" "$((shape_height + 2))" \
            "$border_style" \
            "$resolved_border_offset_x" "$resolved_border_offset_y" \
            "$custom_border"
        # A black built-in border is commonly stored as grayscale. Promote it
        # before compositing so colored custom-border pixels stay colored.
        magick "$border_layer" -colorspace sRGB -type TrueColorAlpha \
            "$custom_border" -colorspace sRGB -composite "$border_layer"
    fi

    make_symbol_layer \
        "$shape" "$(resolve_symbol_mask "$symbol")" "$symbol_color" \
        "$output_name" "$state" "$symbol_layer" \
        "$size" "$resolved_shape_x" "$resolved_shape_y"
    make_tech_layer \
        "$shape" "$tech" "$output_name" "$state" "$tech_layer" \
        "$size" "$resolved_shape_x" "$resolved_shape_y"
    compose_icon_layers \
        "$symbol_layer" "$background_layer" "$border_layer" "$tech_layer" \
        "$size" "$preview_png"
    magick "$preview_png" \
        -define "dds:compression=$dds_compression" \
        "$output_file"
}
