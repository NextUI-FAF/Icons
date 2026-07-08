# DDS generation, overlays, previews, and player-color review assets.

# Generates every configured icon family.
generate_all_icons() {
    local definition_id
    local tech
    local state
    local output_name
    local -a tech_list=()

    print_status "Generating icon families..."
    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        read -r -a tech_list <<< "${ICON_CONFIG[$definition_id.techs]}"
        for tech in "${tech_list[@]}"; do
            output_name="${ICON_CONFIG[$definition_id.name]}${tech}"
            for state in "${ICON_STATES[@]}"; do
                print_status "Generating icon $output_name $tech $state"
                generate_icon_state "$definition_id" "$output_name" "$tech" "$state"
            done
        done
    done
}

# Generates global marker variants while preserving each native symbol and
# border. For T1-T3 the native four-pixel marker strip is cleared before the
# configured marker is composited. TECH4 extends marker-free experimental art.
generate_global_tech_icons() {
    local entry
    local icon_set
    local tech
    local state
    local source_dds
    local marker_free_png
    local final_png
    local output_base
    local output_file
    local target_size
    local source_width
    local source_height
    local scope
    local resolved_scope
    local tech_type
    local tech_fingerprint
    local marker_y

    print_status "Generating global tech icon variants..."
    for entry in "${GLOBAL_TECH_ICON_SETS[@]}"; do
        if [[ "$entry" == *:* ]]; then
            tech="${entry%%:*}"
            icon_set="${entry#*:}"
            output_base="nextui_tech${tech}_${icon_set}"
        else
            icon_set="$entry"
            [[ "$icon_set" =~ ^(icon_[a-z]+)([123])(_.*)$ ]] ||
                die "Unable to infer tech for native icon '$icon_set'."
            tech="${BASH_REMATCH[2]}"
            output_base="nextui_tech_${icon_set}"
        fi
        scope="$(get_native_icon_scope "$icon_set")"
        resolved_scope="$(resolve_tech_symbol_scope "$tech" "$scope")" ||
            die "No TECH$tech symbol is defined for scope '$scope'."
        tech_type="${TECH_SYMBOL_CONFIG[$resolved_scope.$tech.type]}"
        tech_fingerprint="$(get_tech_render_fingerprint "$tech" "$scope")"

        for state in "${ICON_STATES[@]}"; do
            print_status "Generating global tech icon $output_base $state"
            output_file="$ICONS_DIR/${output_base}_${state}.dds"
            local output_filename="${output_base}_${state}.dds"
            local fingerprint
            fingerprint="$(hash_values \
                "$GENERATOR_CACHE_VERSION" \
                "global" \
                "$archive_fingerprint" \
                "$tech_fingerprint" \
                "$scope" \
                "$entry" \
                "$state" \
                "shape-marker-v10" \
                "none")"

            if ! icon_needs_generation "$output_filename" "$fingerprint"; then
                continue
            fi

            if [[ "$entry" == *:* ]]; then
                source_dds="$(extract_native_icon_set_state "$icon_set" "$state")"
                read -r source_width source_height < <(
                    magick "$source_dds" -format '%w %h\n' info:
                )
                if [[ "$tech_type" == "none" ]]; then
                    target_size="${source_width}x${source_height}"
                else
                    target_size="${source_width}x$((source_height + TECH_SYMBOL_HEIGHT))"
                fi
                marker_y="$source_height"
                marker_free_png="$LAYERS_DIR/${output_base}-${state}-marker-free.png"
                magick "$source_dds" \
                    -background none -gravity north -extent "$target_size" \
                    "$marker_free_png"
            else
                read -r marker_free_png target_size marker_y < <(
                    prepare_marker_free_native_icon \
                        "$icon_set" "$tech" "$state" "$output_base"
                )
            fi

            final_png="$LAYERS_DIR/${output_base}-${state}-final.png"
            local native_symbol_layer="$LAYERS_DIR/${output_base}-${state}-native-symbol-layer.png"
            local native_background_layer="$LAYERS_DIR/${output_base}-${state}-native-background-layer.png"
            local native_border_layer="$LAYERS_DIR/${output_base}-${state}-native-border-layer.png"
            local native_tech_layer="$LAYERS_DIR/${output_base}-${state}-native-tech-layer.png"
            local transparent_layer="$LAYERS_DIR/${output_base}-${state}-transparent.png"
            magick -size "$target_size" xc:none "$transparent_layer"
            apply_tech_symbol \
                "$transparent_layer" "$tech" "$native_tech_layer" "$scope" "$marker_y"
            split_native_icon_layers \
                "$marker_free_png" "$scope" "$state" "$output_base" \
                "$native_symbol_layer" "$native_background_layer" "$native_border_layer"
            compose_icon_layers \
                "$native_symbol_layer" "$native_background_layer" \
                "$native_border_layer" "$native_tech_layer" \
                "$target_size" "$final_png"

            magick "$final_png" \
                -define "dds:compression=none" \
                "$output_file"
        done
    done
}

# ==============================================================================
# Dynamic state overlays
# ==============================================================================

# Draws one animation frame of the upgrading overlay.
# Arguments: vertical offset, output PNG, optional color.
make_upgrading_overlay_frame() {
    local offset="$1"
    local output="$2"
    local color="${3:-$UPGRADING_OVERLAY_COLOR}"
    local top=$((5 - offset))
    local mid=$((6 - offset))
    local low=$((7 - offset))
    local foot=$((8 - offset))

    magick -size 12x12 canvas:none -fill "$color" \
        -draw "point 6,${top} rectangle 5,${mid} 7,${mid} rectangle 4,${low} 5,${low} rectangle 7,${low} 8,${low} point 4,${foot} point 8,${foot}" \
        "$output"
}

# Encodes a transparent overlay PNG as DXT5 DDS.
# Arguments: source PNG, output DDS.
write_overlay_dds() {
    local source_png="$1"
    local output_dds="$2"

    magick "$source_png" \
        -define "dds:compression=$DDS_COMPRESSION" \
        "$output_dds"
}

# Generates upgrading, animated, and paused strategic overlays.
generate_upgrading_overlays() {
    local frame
    local preview_png

    print_status "Generating upgrading overlay textures..."
    for frame in 0 1 2; do
        local suffix=""
        ((frame > 0)) && suffix="_$frame"

        preview_png="$CLEAN_OVERLAY_PREVIEWS_DIR/upgrading${suffix}.png"
        make_upgrading_overlay_frame "$frame" "$preview_png"
        write_overlay_dds "$preview_png" "$OVERLAYS_DIR/upgrading${suffix}.dds"
    done

    preview_png="$CLEAN_OVERLAY_PREVIEWS_DIR/upgrading_paused.png"
    make_upgrading_overlay_frame 0 "$preview_png" "$UPGRADING_PAUSED_COLOR"
    write_overlay_dds "$preview_png" "$OVERLAYS_DIR/upgrading_paused.dds"
}

# ==============================================================================
# Preview generation
# ==============================================================================

# Builds review sheets for generated icon states and overlays.
generate_previews() {
    local preview_work="$LAYERS_DIR/previews"
    local png
    local scaled_png
    local base
    local -a icon_pngs=()
    local -a overlay_pngs=()

    print_status "Generating preview images..."
    mkdir -p "$preview_work"

    for png in "$CLEAN_ICON_PREVIEWS_DIR"/*.png; do
        [[ -e "$png" ]] || continue
        base="$(basename "$png" .png)"
        scaled_png="$preview_work/${base}.png"
        magick "$png" -filter point -resize "$ICON_PREVIEW_SCALE" "$scaled_png"
        icon_pngs+=("$scaled_png")
    done

    if ((${#icon_pngs[@]} > 0)); then
        magick montage "${icon_pngs[@]}" \
            -background none -bordercolor none -border 8 \
            -tile 4x -geometry +8+8 \
            "$PREVIEWS_DIR/generated-custom-strategic-icons.png"
    fi

    for png in "$CLEAN_OVERLAY_PREVIEWS_DIR"/*.png; do
        [[ -e "$png" ]] || continue
        base="$(basename "$png" .png)"
        scaled_png="$preview_work/${base}.png"
        magick "$png" -filter point -resize "$OVERLAY_PREVIEW_SCALE" "$scaled_png"
        overlay_pngs+=("$scaled_png")
    done

    if ((${#overlay_pngs[@]} > 0)); then
        magick montage "${overlay_pngs[@]}" \
            -background none -bordercolor none -border 8 \
            -tile x1 -geometry +8+8 \
            "$PREVIEWS_DIR/generated-strategic-overlays.png"
    fi
}

# Builds a compact sample sheet instead of placing all ~200 automatic icon sets
# in the normal custom-family preview.
generate_global_tech_preview() {
    local preview_work="$LAYERS_DIR/global-tech-preview"
    local tech
    local sample
    local scaled
    local -a samples=()

    mkdir -p "$preview_work"

    for tech in 1 2 3; do
        sample="$LAYERS_DIR/nextui_tech_icon_structure${tech}_generic-rest-final.png"
        if [[ ! -f "$sample" ]]; then
            sample="$ICONS_DIR/nextui_tech_icon_structure${tech}_generic_rest.dds"
        fi
        [[ -f "$sample" ]] || continue
        scaled="$preview_work/tech${tech}.png"
        magick "$sample" -filter point -resize "$ICON_PREVIEW_SCALE" "$scaled"
        samples+=("$scaled")
    done

    if resolve_tech_symbol_scope 4 unit >/dev/null 2>&1; then
        sample="$LAYERS_DIR/nextui_tech4_icon_experimental_generic-rest-final.png"
        if [[ ! -f "$sample" ]]; then
            sample="$ICONS_DIR/nextui_tech4_icon_experimental_generic_rest.dds"
        fi
        if [[ -f "$sample" ]]; then
            scaled="$preview_work/tech4.png"
            magick "$sample" -filter point -resize "$ICON_PREVIEW_SCALE" "$scaled"
            samples+=("$scaled")
        fi
    fi

    if ((${#samples[@]} > 0)); then
        magick montage "${samples[@]}" \
            -background "$PREVIEW_BACKGROUND_COLOR" \
            -bordercolor "$PREVIEW_BACKGROUND_COLOR" \
            -border 8 -tile x1 -geometry +8+8 \
            "$PREVIEWS_DIR/generated-global-tech-symbols.png"
    fi
}

# Appends generated resting-state preview paths to a named array.
# Argument: output array variable name.
collect_player_preview_icons() {
    local -n output_array="$1"
    local icon

    for icon in "$CLEAN_ICON_PREVIEWS_DIR"/nextui_*_rest.png; do
        [[ -f "$icon" ]] || continue
        output_array+=("$icon")
    done
}

# Prints the human-facing icon name derived from a preview basename.
# Argument: preview basename without extension.
preview_label_for_icon() {
    local base="$1"
    local label="${base#nextui_}"

    # Keep preview names aligned with their generated icon names.
    # Example: nextui_pgen2_rest.png -> icon-pgen2-player-colors.png
    label="${label%_rest}"

    printf '%s\n' "$label"
}

# Builds per-icon and all-icon player-color preview sheets.
generate_player_color_previews() {
    local preview_work="$LAYERS_DIR/player-color-previews"
    local color
    local icon
    local base
    local label
    local recolored
    local scaled
    local row
    local index=0
    local -a matrix_rows=()
    local -a rest_icons=()

    mkdir -p "$preview_work"
    find "$preview_work" -type f -name '*.png' -delete

    collect_player_preview_icons rest_icons
    ((${#rest_icons[@]} > 0)) || return 0

    for color in "${PLAYER_PREVIEW_COLORS[@]}"; do
        row="$preview_work/matrix-row-${index}.png"
        local -a row_icons=()

        for icon in "${rest_icons[@]}"; do
            base="$(basename "$icon" .png)"
            recolored="$preview_work/${base}-${index}.png"
            scaled="$preview_work/${base}-${index}-matrix.png"

            recolor_player_pixels "$icon" "$color" "$recolored"
            magick "$recolored" -filter point \
                -resize "$PLAYER_MATRIX_SCALE" "$scaled"
            row_icons+=("$scaled")
        done

        magick montage "${row_icons[@]}" \
            -background "$PREVIEW_BACKGROUND_COLOR" \
            -bordercolor "$PREVIEW_BACKGROUND_COLOR" \
            -border 4 -tile x1 -geometry +8+8 \
            "$row"

        matrix_rows+=("$row")
        index=$((index + 1))
    done

    if ((${#matrix_rows[@]} > 0)); then
        magick "${matrix_rows[@]}" -append +repage \
            "$PREVIEWS_DIR/player-color-matrix.png"
    fi

    for icon in "${rest_icons[@]}"; do
        base="$(basename "$icon" .png)"
        label="$(preview_label_for_icon "$base")"

        local -a icon_variants=()
        index=0

        for color in "${PLAYER_PREVIEW_COLORS[@]}"; do
            recolored="$preview_work/${base}-${index}.png"
            scaled="$preview_work/${base}-${index}-${label}.png"
            magick "$recolored" -filter point \
                -resize "$PLAYER_DETAIL_SCALE" "$scaled"
            icon_variants+=("$scaled")
            index=$((index + 1))
        done

        magick montage "${icon_variants[@]}" \
            -background "$PREVIEW_BACKGROUND_COLOR" \
            -bordercolor "$PREVIEW_BACKGROUND_COLOR" \
            -border 8 -tile 5x -geometry +12+16 \
            "$PREVIEWS_DIR/icon-${label}-player-colors.png"
    done
}
