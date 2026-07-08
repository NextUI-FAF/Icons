# FAF native-icon discovery, extraction, and TECH source validation.

# Resolves visual geometry exclusively from the user-facing assignments.
get_native_icon_scope() {
    local assigned
    if assigned="$(resolve_icon_shape "$1")"; then
        printf '%s\n' "$assigned"
        return
    fi
    die "Native icon '$1' has no assign_icon_shape recipe."
}

# Prints the unnumbered counterpart of a numbered native icon set.
get_marker_free_icon_set() {
    local icon_set="$1"

    if [[ "$icon_set" =~ ^(icon_[a-z]+)[123](_.*)$ ]]; then
        printf '%s%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi
    return 1
}

# Extracts one native strategic-icon state into the generator workspace and
# prints its path.
extract_native_icon_set_state() {
    local icon_set="$1"
    local state="$2"
    local output="$NATIVE_DIR/set-${icon_set}-${state}.dds"

    if [[ ! -f "$output" ]]; then
        unzip -p "$archive" \
            "textures/ui/common/game/strategicicons/${icon_set}_${state}.dds" \
            > "$output"
    fi
    printf '%s\n' "$output"
}

# Prints how many rows above the bottom edge the native resting marker begins.
# Resting icons have no white selection frame, so the near-white component in
# the lower half is the tech marker even for air and diamond geometries.
get_native_marker_bottom_offset() {
    local icon_set="$1"
    local native
    local width
    local height
    local lower_height
    local lower_top
    local marker_mask="$MASKS_DIR/${icon_set}-rest-white-tech-marker.png"
    local relative_y
    local marker_y

    native="$(extract_native_icon_set_state "$icon_set" rest)"
    read -r width height < <(magick "$native" -format '%w %h\n' info:)
    lower_top=$((height / 2))
    lower_height=$((height - lower_top))

    magick "$native" \
        -fx '(a > 0.5 && r > 0.8 && g > 0.8 && b > 0.8) ? 1 : 0' \
        -crop "${width}x${lower_height}+0+${lower_top}" +repage \
        "$marker_mask"
    relative_y="$(
        magick "$marker_mask" -threshold 50% txt:- |
            awk -F '[:,]' '
                /#FFFFFF([^F]|$)|#FFFFFFFF|gray\\(255\\)/ {
                    y = $2 + 0
                    if (!seen || y < minimum) {
                        minimum = y
                    }
                    seen = 1
                }
                END {
                    if (seen) {
                        print minimum
                    }
                }
            '
    )"

    if [[ -n "$relative_y" ]]; then
        marker_y=$((lower_top + relative_y))
        printf '%s\n' "$((height - marker_y))"
    else
        printf '%s\n' "$TECH_SYMBOL_HEIGHT"
    fi
}

# Prints the final opaque row of an image, or its last canvas row when empty.
get_alpha_bottom_row() {
    local image="$1"
    local canvas_height
    local bottom
    canvas_height="$(magick "$image" -format '%h' info:)"
    bottom="$(
        magick "$image" -alpha extract -threshold 50% txt:- |
            awk -F '[:,]' '
                /#FFFFFF|gray\\(255\\)/ {
                    y = $2 + 0
                    if (!seen || y > maximum) {
                        maximum = y
                    }
                    seen = 1
                }
                END {
                    if (seen) {
                        print maximum
                    }
                }
            '
    )"
    if [[ -n "$bottom" ]]; then
        printf '%s\n' "$bottom"
    else
        printf '%s\n' "$((canvas_height - 1))"
    fi
}

# Prints the first opaque row of an image, or zero when the canvas is empty.
get_alpha_top_row() {
    local image="$1"
    local top
    top="$(
        magick "$image" -alpha extract -threshold 50% txt:- |
            awk -F '[:,]' '
                /#FFFFFF|gray\(255\)/ {
                    y = $2 + 0
                    if (!seen || y < minimum) {
                        minimum = y
                    }
                    seen = 1
                }
                END {
                    if (seen) {
                        print minimum
                    } else {
                        print 0
                    }
                }
            '
    )"
    printf '%s\n' "$top"
}

# Prints the configured native reference for a visual scope. Built-in FAF
# scopes use internal defaults; --native-reference remains an advanced override.
get_shape_native_reference() {
    local scope="$1"
    local configured="${SHAPE_CONFIG[$scope.native_reference]:-}"

    if [[ -n "$configured" ]]; then
        printf '%s\n' "$configured"
        return
    fi

    case "$scope" in
        square) printf 'icon_structure_energy\n' ;;
        rectangle) printf 'icon_factory_generic\n' ;;
        hexagon) printf 'icon_bot_generic\n' ;;
        diamond) printf 'icon_land_generic\n' ;;
        triangle) printf 'icon_fighter_generic\n' ;;
        wide_triangle) printf 'icon_bomber_generic\n' ;;
        trapezium) printf 'icon_gunship_generic\n' ;;
        semicircle) printf 'icon_ship_generic\n' ;;
        inverted_semicircle) printf 'icon_sub_generic\n' ;;
        circle) printf 'icon_experimental_generic\n' ;;
        *) printf '\n' ;;
    esac
}

# Builds marker-free native art and discovers the native marker's vertical
# anchor. Exact unnumbered counterparts are preferred; rare special sets use a
# family reference mask so their unique central art remains intact.
# Prints: clean PNG path, target size, marker canvas Y.
prepare_marker_free_native_icon() {
    local icon_set="$1"
    local tech="$2"
    local state="$3"
    local label="$4"
    local numbered
    local base_set
    local base
    local target_size
    local clean="$LAYERS_DIR/${label}-${state}-native-without-tech.png"
    local marker_y
    local marker_bottom_offset
    local scope
    local member
    local reference_set

    numbered="$(extract_native_icon_set_state "$icon_set" "$state")"
    target_size="$(magick "$numbered" -format '%wx%h' info:)"
    scope="$(get_native_icon_scope "$icon_set")"
    reference_set="$(get_shape_native_reference "$scope")"
    marker_bottom_offset="$(get_native_marker_bottom_offset "$icon_set")"
    marker_y=$((${target_size#*x} - marker_bottom_offset))
    base_set="$(get_marker_free_icon_set "$icon_set")" ||
        die "Unable to infer marker-free native icon for '$icon_set'."
    member="textures/ui/common/game/strategicicons/${base_set}_${state}.dds"

    if unzip -Z1 "$archive" "$member" >/dev/null 2>&1; then
        base="$(extract_native_icon_set_state "$base_set" "$state")"
        magick "$base" \
            -background none -gravity north -extent "$target_size" \
            "$clean"
    elif [[ -n "$reference_set" ]]; then
        local clean_alpha="$MASKS_DIR/${label}-${state}-clean-alpha.png"
        local reference
        local reference_top
        local numbered_top
        local reference_offset_y
        local reference_geometry_y
        reference="$(extract_native_icon_set_state "$reference_set" "$state")"
        reference_top="$(get_alpha_top_row "$reference")"
        numbered_top="$(get_alpha_top_row "$numbered")"
        reference_offset_y=$((numbered_top - reference_top))
        printf -v reference_geometry_y '%+d' "$reference_offset_y"
        magick -size "$target_size" xc:none \
            "$reference" -geometry "+0${reference_geometry_y}" -composite \
            -alpha extract "$clean_alpha"
        magick "$numbered" "$clean_alpha" \
            -alpha off -compose CopyOpacity -composite \
            "$clean"
    else
        local original_alpha="$MASKS_DIR/${label}-${state}-original-alpha.png"
        local clean_alpha="$MASKS_DIR/${label}-${state}-clean-alpha.png"
        local keep_mask="$MASKS_DIR/${label}-${state}-keep-without-tech.png"
        local target_width="${target_size%x*}"
        local target_height="${target_size#*x}"
        local left=$((target_width / 2 - 5))
        local right=$((target_width / 2 + 4))

        marker_bottom_offset="$(get_native_marker_bottom_offset "$icon_set")"
        marker_y=$((target_height - marker_bottom_offset))
        ((left < 0)) && left=0
        ((right >= target_width)) && right=$((target_width - 1))

        magick -size "$target_size" xc:white -fill black \
            -draw "rectangle ${left},$((marker_y > 0 ? marker_y - 1 : 0)) ${right},$((target_height - 1))" \
            "$keep_mask"
        magick "$numbered" -alpha extract "$original_alpha"
        magick "$original_alpha" "$keep_mask" \
            -compose Multiply -composite "$clean_alpha"
        magick "$numbered" "$clean_alpha" \
            -alpha off -compose CopyOpacity -composite \
            "$clean"
    fi

    # DDS files can retain RGB with a one-bit-looking but nonzero fringe in
    # nominally transparent pixels. Normalize alpha before stacking layers so
    # that fringe cannot cover the tech layer underneath.
    local normalized_alpha="$MASKS_DIR/${label}-${state}-normalized-alpha.png"
    local normalized_clean="$LAYERS_DIR/${label}-${state}-native-normalized.png"
    magick "$clean" -alpha extract -threshold 50% "$normalized_alpha"
    magick "$clean" "$normalized_alpha" \
        -alpha off -compose CopyOpacity -composite "$normalized_clean"
    magick "$normalized_clean" "$clean"

    local clean_marker_y="$marker_y"
    if [[ -n "${SHAPE_CONFIG[$scope.tech_overlap]:-}" ]]; then
        local overlap="${SHAPE_CONFIG[$scope.tech_overlap]}"
        clean_marker_y="$(get_alpha_bottom_row "$clean")"
        clean_marker_y=$((clean_marker_y - overlap + 1))
    fi

    local resolved_scope
    resolved_scope="$(resolve_tech_symbol_scope "$tech" "$scope")" ||
        die "No TECH$tech symbol is defined for shape '$scope'."
    if [[ "${TECH_SYMBOL_CONFIG[$resolved_scope.$tech.type]}" != "none" ]]; then
        # Consume only transparent padding above the native art when the
        # complete marker would otherwise extend beyond the DDS canvas.
        local tech_height="${TECH_SYMBOL_CONFIG[$resolved_scope.$tech.height]:-${TECH_SYMBOL_SIZE#*x}}"
        local target_width="${target_size%x*}"
        local target_height="${target_size#*x}"
        local top_padding
        top_padding="$(get_alpha_top_row "$clean")"
        local required_shift=$((clean_marker_y + tech_height - target_height))
        if ((required_shift <= top_padding)); then
            marker_y="$clean_marker_y"
        else
            required_shift=$((marker_y + tech_height - target_height))
        fi
        if ((required_shift > 0)); then
            ((required_shift <= top_padding)) ||
                die "TECH$tech marker for '$icon_set' needs $required_shift rows, but its native $state icon has only $top_padding transparent rows above it."
            magick "$clean" \
                -crop "${target_width}x$((target_height - required_shift))+0+${required_shift}" \
                +repage -background none -gravity north -extent "$target_size" \
                "$clean"
            marker_y=$((marker_y - required_shift))
        fi
    fi

    printf '%s %s %s\n' "$clean" "$target_size" "$marker_y"
}

# Lists every numbered FAF strategic-icon set. These are the T1/T2/T3 unit,
# structure, factory, air, and navy icons that receive the global marker.
list_numbered_native_icon_sets() {
    unzip -Z1 "$archive" \
        'textures/ui/common/game/strategicicons/*_rest.dds' |
        sed 's#.*/##; s/_rest\.dds$//' |
        grep -E '^icon_[a-z]+[123]_' |
        sort -u
}

# Lists native icon sets that have no numbered equivalent at any tech. This
# includes commander, subcommander, wall, energy-storage, experimental, and
# objective art. Generating tech-specific variants for this small remainder
# closes the coverage gap without guessing blueprint roles.
list_orphan_native_icon_sets() {
    comm -23 \
        <(
            unzip -Z1 "$archive" \
                'textures/ui/common/game/strategicicons/icon_*_rest.dds' |
                sed 's#.*/##; s/_rest\.dds$//' |
                grep -Ev '^icon_[a-z]+[123]_' |
                sort -u
        ) \
        <(
            unzip -Z1 "$archive" \
                'textures/ui/common/game/strategicicons/icon_*_rest.dds' |
                sed 's#.*/##; s/_rest\.dds$//' |
                grep -E '^icon_[a-z]+[123]_' |
                sed -E 's/^(icon_[a-z]+)[123](_.*)$/\1\2/' |
                sort -u
        )
}

# Reserves the automatically generated global icon sets after the source
# archive is known. TECH4 is optional and applies to explicitly listed native
# icon sets because FAF does not encode "4" in their filenames.
register_global_tech_outputs() {
    local icon_set
    local scope
    local tech
    local state
    local output_file

    [[ "${global_tech_icons:-true}" == "true" ]] || return 0

    while IFS= read -r icon_set; do
        [[ -n "$icon_set" ]] || continue
        GLOBAL_TECH_ICON_SETS+=("$icon_set")
        for state in "${ICON_STATES[@]}"; do
            output_file="nextui_tech_${icon_set}_${state}.dds"
            [[ -z "${PLANNED_ICON_OUTPUTS[$output_file]:-}" ]] ||
                die "Two icon definitions generate the same file: $output_file"
            PLANNED_ICON_OUTPUTS["$output_file"]=1
        done
    done < <(list_numbered_native_icon_sets)

    for tech in 1 2 3 4; do
        while IFS= read -r icon_set; do
            [[ -n "$icon_set" ]] || continue
            scope="$(get_native_icon_scope "$icon_set")"
            resolve_tech_symbol_scope "$tech" "$scope" >/dev/null 2>&1 ||
                continue
            GLOBAL_TECH_ICON_SETS+=("$tech:$icon_set")
            for state in "${ICON_STATES[@]}"; do
                output_file="nextui_tech${tech}_${icon_set}_${state}.dds"
                [[ -z "${PLANNED_ICON_OUTPUTS[$output_file]:-}" ]] ||
                    die "Two icon definitions generate the same file: $output_file"
                PLANNED_ICON_OUTPUTS["$output_file"]=1
            done
        done < <(list_orphan_native_icon_sets)
    done
}

# Verifies that every automatic icon exists in the selected texture archive.
validate_global_tech_sources() {
    local entry
    local icon_set
    local tech
    local scope
    local state
    local member

    for entry in "${GLOBAL_TECH_ICON_SETS[@]}"; do
        if [[ "$entry" == *:* ]]; then
            tech="${entry%%:*}"
            icon_set="${entry#*:}"
        else
            icon_set="$entry"
            [[ "$icon_set" =~ ^(icon_[a-z]+)([123])(_.*)$ ]] ||
                die "Unable to infer tech for native icon '$icon_set'."
            tech="${BASH_REMATCH[2]}"
        fi

        scope="$(get_native_icon_scope "$icon_set")"
        resolve_tech_symbol_scope "$tech" "$scope" >/dev/null ||
            die "No TECH$tech symbol is defined for scope '$scope' (required by '$icon_set')."

        for state in "${ICON_STATES[@]}"; do
            member="textures/ui/common/game/strategicicons/${icon_set}_${state}.dds"
            unzip -Z1 "$archive" "$member" >/dev/null 2>&1 ||
                die "Missing native strategic icon: $member"
        done
    done
}
