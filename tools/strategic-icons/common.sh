# Shared paths, constants, state, cache, and generated-file lifecycle.

readonly ROOT="$(cd "$GENERATOR_TOOLS_DIR/.." && pwd)"
readonly ICONS_DIR="$ROOT/custom-strategic-icons"
readonly OVERLAYS_DIR="$ROOT/textures/strategic-overlays"
readonly CONFIG_FILE="$ROOT/tools/strategic_icon_config.sh"
readonly MOD_ICONS_TEMPLATE="$ROOT/tools/mod_icons.lua.template"
readonly MOD_ICONS_FILE="$ROOT/mod_icons.lua"
readonly PREVIEWS_DIR="$ROOT/artwork/strategic-icons/previews"
readonly GENERATED_MANIFEST="$ICONS_DIR/.generated-strategic-icons"
readonly GENERATION_CACHE="$ICONS_DIR/.strategic-icon-cache"

readonly WORK_DIR="${NEXTUI_ICON_WORKDIR:-${TMPDIR:-/tmp}/nextui-icons}"
readonly NATIVE_DIR="$WORK_DIR/native"
readonly MASKS_DIR="$WORK_DIR/masks"
readonly LAYERS_DIR="$WORK_DIR/layers"
readonly CLEAN_ICON_PREVIEWS_DIR="$LAYERS_DIR/preview-icons"
readonly CLEAN_OVERLAY_PREVIEWS_DIR="$LAYERS_DIR/preview-overlays"

# ==============================================================================
# Generator configuration
# ==============================================================================

readonly DDS_COMPRESSION="dxt5"
readonly CUSTOM_BORDER_DDS_COMPRESSION="none"
readonly GENERATOR_CACHE_VERSION="7"
readonly SYMBOL_OUTLINE_COLOR="black"
readonly SYMBOL_OUTLINE_KERNEL="Square:1"
readonly HAZARD_PLAYER_GRAY_RED=90
readonly HAZARD_PLAYER_GRAY_GREEN=87
readonly HAZARD_PLAYER_GRAY_BLUE=90

readonly NORMAL_ICON_SIZE="12x16"
readonly TECH_SYMBOL_SIZE="12x4"
readonly TECH_SYMBOL_HEIGHT=4

readonly SELECTED_ICON_SIZE="16x20"

readonly CUSTOM_BORDER_OUTER_PERIMETER_PIXELS=56
readonly CUSTOM_BORDER_INNER_PERIMETER_PIXELS=48

readonly PREVIEW_BACKGROUND_COLOR="#303030"
readonly ICON_PREVIEW_SCALE="400%"
readonly OVERLAY_PREVIEW_SCALE="800%"
readonly PLAYER_MATRIX_SCALE="400%"
readonly PLAYER_DETAIL_SCALE="800%"

readonly UPGRADING_OVERLAY_COLOR="#39ff59"
readonly UPGRADING_PAUSED_COLOR="#ffb02e"

readonly -a ICON_STATES=(rest over selected selectedover)

readonly -a PLAYER_PREVIEW_COLORS=(
    "#ff0000"
    "#8b0018"
    "#ff8038"
    "#a85a12"
    "#9c9800"
    "#fff200"
    "#8dde00"
    "#42b947"
    "#267a48"
    "#243f3f"
    "#4169e1"
    "#2b19d6"
    "#6900a8"
    "#8f5be8"
    "#59e7c2"
    "#f2f2f2"
    "#707780"
    "#eb75dc"
    "#ff1fe8"
)

# Definitions loaded from the user-facing configuration. Symbols and borders
# are intentionally empty here: the engine provides behavior, not recipes.
declare -a SYMBOLS=()
declare -A SYMBOL_CONFIG=()
declare -A SYMBOL_ALIASES=()
declare -a TECH_SYMBOLS=()
declare -A TECH_SYMBOL_CONFIG=()
declare -a BORDER_PATTERNS=()
declare -A BORDER_PATTERN_CONFIG=()
declare -a BORDER_STYLES=()
declare -A BORDER_STYLE_CONFIG=()
declare -a SHAPES=()
declare -A SHAPE_CONFIG=()
declare -a SHAPE_ASSIGNMENTS=()
declare -A SHAPE_ASSIGNMENT_CONFIG=()

# Icon definitions are also collected as data so validation and listing modes
# never need to create files.
declare -a ICON_DEFINITIONS=()
declare -A ICON_CONFIG=()
declare -A PLANNED_ICON_OUTPUTS=()
declare -a GLOBAL_TECH_ICON_SETS=()
declare -A PREVIOUS_ICON_FINGERPRINTS=()
declare -A NEXT_ICON_FINGERPRINTS=()
declare -A TECH_RENDER_FINGERPRINTS=()

# Set by locate_textures_archive().
archive=""
archive_fingerprint=""
border_config_fingerprint=""
generated_icon_count=0
skipped_icon_count=0

# Resolved per-icon geometry. Authored shapes remain local; this layout is
# recalculated for each state so borders that extend beyond the shape are never
# clipped and every layer receives exactly the same translation.
icon_layout_size=""
icon_layout_shape_x=0
icon_layout_shape_y=0
icon_layout_border_offset_x=0
icon_layout_border_offset_y=0

# ==============================================================================
# Error handling
# ==============================================================================

# Prints an error message to stderr and exits unsuccessfully.
# Arguments: message fragments.
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# Fails unless a file exists.
# Arguments: path, optional human-readable description.
require_file() {
    local path="$1"
    local description="${2:-Required file is missing}"

    [[ -f "$path" ]] || die "$description: $path"
}

# Fails unless an executable is available through PATH.
# Argument: command name.
require_command() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1 ||
        die "Required command is not installed: $command_name"
}

# Prints a stable SHA-256 fingerprint for an ordered list of values.
hash_values() {
    printf '%s\0' "$@" | sha256sum | cut -d ' ' -f 1
}

# Prints a simple status message to stdout.
# Arguments: message fragments.
print_status() {
    printf '[nextui] %s\n' "$*"
}

# Loads fingerprints from the last successful generation.
load_generation_cache() {
    local filename
    local fingerprint

    [[ -f "$GENERATION_CACHE" ]] || return 0

    while IFS=$'\t' read -r filename fingerprint; do
        [[ -n "$filename" && -n "$fingerprint" ]] || continue
        [[ "$filename" == "${filename##*/}" && "$filename" == nextui_*.dds ]] ||
            die "Unsafe entry in strategic icon cache: $filename"
        [[ "$fingerprint" =~ ^[0-9a-f]{64}$ ]] ||
            die "Invalid fingerprint in strategic icon cache for $filename."
        PREVIOUS_ICON_FINGERPRINTS["$filename"]="$fingerprint"
    done < "$GENERATION_CACHE"
}

# Initializes shared archive, recipe, and per-tech fingerprints.
initialize_generation_fingerprints() {
    local entry
    local tech
    local scope
    local key

    archive_fingerprint="$(stat -c '%n:%s:%Y' "$archive")"
    border_config_fingerprint="$(
        {
            for key in $(printf '%s\n' "${!BORDER_PATTERN_CONFIG[@]}" | sort); do
                printf 'pattern:%s=%s\0' "$key" "${BORDER_PATTERN_CONFIG[$key]}"
            done
            for key in $(printf '%s\n' "${!BORDER_STYLE_CONFIG[@]}" | sort); do
                printf 'style:%s=%s\0' "$key" "${BORDER_STYLE_CONFIG[$key]}"
            done
        } | sha256sum | cut -d ' ' -f 1
    )"

    for entry in "${TECH_SYMBOLS[@]}"; do
        scope="${entry%%:*}"
        tech="${entry#*:}"

        TECH_RENDER_FINGERPRINTS["$scope.$tech"]="$(hash_values \
            "$scope" \
            "${TECH_SYMBOL_CONFIG[$scope.$tech.type]}" \
            "${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_map]}" \
            "${TECH_SYMBOL_CONFIG[$scope.$tech.pixel_colors]}" \
            "${SHAPE_CONFIG[$scope.tech_overlap]:-}" \
            "$(get_shape_native_reference "$scope")")"
    done
}

# Resolves a shape-specific TECH override, then the shared global recipe.
resolve_tech_symbol_scope() {
    local tech="$1"
    local requested_scope="$2"

    if [[ -n "${TECH_SYMBOL_CONFIG[$requested_scope.$tech.type]:-}" ]]; then
        printf '%s\n' "$requested_scope"
    elif [[ -n "${TECH_SYMBOL_CONFIG[all.$tech.type]:-}" ]]; then
        printf 'all\n'
    else
        return 1
    fi
}

get_tech_render_fingerprint() {
    local tech="$1"
    local requested_scope="$2"
    local resolved_scope

    resolved_scope="$(resolve_tech_symbol_scope "$tech" "$requested_scope")" ||
        die "No TECH$tech symbol is defined for scope '$requested_scope'."
    printf '%s\n' "${TECH_RENDER_FINGERPRINTS[$resolved_scope.$tech]}"
}

# Returns success when an output must be regenerated. The optional third
# argument is a clean preview that must also exist before a custom icon can be
# skipped.
icon_needs_generation() {
    local filename="$1"
    local fingerprint="$2"
    local preview="${3:-}"

    NEXT_ICON_FINGERPRINTS["$filename"]="$fingerprint"

    if [[ -f "$ICONS_DIR/$filename"
        && "${PREVIOUS_ICON_FINGERPRINTS[$filename]:-}" == "$fingerprint"
        && ( -z "$preview" || -f "$preview" )
    ]]; then
        skipped_icon_count=$((skipped_icon_count + 1))
        return 1
    fi

    generated_icon_count=$((generated_icon_count + 1))
    return 0
}

# ==============================================================================
# General helpers
# ==============================================================================

# Prints the best strategic-icon archive found in common FAF / Steam locations.
# Returns failure without output when no archive is found.
find_textures_archive() {
    local home="${HOME:-}"
    local candidate
    local -a candidates=()

    if [[ -n "$home" ]]; then
        candidates+=(
            "$home/.faforever/gamedata/textures.nx2"
            "$home/.steam/steam/steamapps/common/Supreme Commander Forged Alliance/gamedata/textures.scd"
            "$home/.local/share/Steam/steamapps/common/Supreme Commander Forged Alliance/gamedata/textures.scd"
        )
    fi

    candidates+=(
        "/mnt/1C7025DA7025BC00/SteamLibrary/steamapps/common/Supreme Commander Forged Alliance/gamedata/textures.scd"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

# Resolves an explicit or installed strategic-icon archive into $archive.
locate_textures_archive() {
    archive="${FA_TEXTURES_ARCHIVE:-}"

    if [[ -z "$archive" ]]; then
        archive="$(find_textures_archive || true)"
    fi

    if [[ ! -f "$archive" ]]; then
        die "Unable to find FAF/FA strategic icon textures. Set FA_TEXTURES_ARCHIVE to the full archive path."
    fi
}

# Creates all generated-output and temporary working directories.
prepare_directories() {
    mkdir -p \
        "$ICONS_DIR" \
        "$OVERLAYS_DIR" \
        "$PREVIEWS_DIR" \
        "$NATIVE_DIR" \
        "$MASKS_DIR" \
        "$LAYERS_DIR" \
        "$CLEAN_ICON_PREVIEWS_DIR" \
        "$CLEAN_OVERLAY_PREVIEWS_DIR"
}

# Removes only preview files owned by this generator.
clean_generated_previews() {
    find "$PREVIEWS_DIR" -maxdepth 1 -type f \( \
        -name 'generated-custom-strategic-icons.png' \
        -o -name 'generated-global-tech-symbols.png' \
        -o -name 'generated-strategic-overlays.png' \
        -o -name 'player-color-matrix.png' \
        -o -name 'icon-*-player-colors.png' \
    \) -delete

    # Clean icon intermediates are cache dependencies. Keep current ones so an
    # unchanged custom icon can be skipped, but discard previews for recipes
    # that no longer exist.
    local png
    local output
    for png in "$CLEAN_ICON_PREVIEWS_DIR"/*.png; do
        [[ -e "$png" ]] || continue
        output="$(basename "$png" .png).dds"
        if [[ -z "${PLANNED_ICON_OUTPUTS[$output]:-}" ]]; then
            rm -f "$png"
        fi
    done

    find "$CLEAN_OVERLAY_PREVIEWS_DIR" -type f -name '*.png' -delete
}

# Deletes manifest-owned DDS outputs that are absent from the current plan.
remove_obsolete_icon_outputs() {
    local previous_file
    local basename

    [[ -f "$GENERATED_MANIFEST" ]] || return 0

    while IFS= read -r previous_file; do
        [[ -n "$previous_file" ]] || continue
        basename="${previous_file##*/}"

        # A manifest is data, not a license to delete arbitrary paths.
        [[ "$previous_file" == "$basename" ]] ||
            die "Unsafe entry in generated icon manifest: $previous_file"
        [[ "$basename" == nextui_*.dds ]] ||
            die "Unexpected entry in generated icon manifest: $basename"

        if [[ -z "${PLANNED_ICON_OUTPUTS[$basename]:-}" ]]; then
            rm -f "$ICONS_DIR/$basename"
        fi
    done < "$GENERATED_MANIFEST"
}

# Atomically writes the sorted generated-output manifest.
write_generated_manifest() {
    local temporary_manifest="$GENERATED_MANIFEST.tmp"
    local output

    : > "$temporary_manifest"
    for output in "${!PLANNED_ICON_OUTPUTS[@]}"; do
        printf '%s\n' "$output"
    done | sort > "$temporary_manifest"

    mv "$temporary_manifest" "$GENERATED_MANIFEST"
}

# Regenerates FAF's blueprint-to-IconSet bridge from the targets declared by
# each user-facing create_icon recipe.
write_mod_icons_file() {
    local temporary_file="$MOD_ICONS_FILE.tmp"
    local definition_id
    local tech
    local value

    require_file "$MOD_ICONS_TEMPLATE" "Missing mod_icons.lua template"
    [[ "$(grep -c '^-- BEGIN GENERATED ICON RULES$' "$MOD_ICONS_TEMPLATE")" == "1"
        && "$(grep -c '^-- END GENERATED ICON RULES$' "$MOD_ICONS_TEMPLATE")" == "1"
    ]] || die "mod_icons.lua template must contain exactly one generated-rules block."

    sed -n '1,/^-- BEGIN GENERATED ICON RULES$/p' "$MOD_ICONS_TEMPLATE" \
        > "$temporary_file"

    for definition_id in "${ICON_DEFINITIONS[@]}"; do
        {
            printf '    {\n'
            printf '        name = "%s",\n' "${ICON_CONFIG[$definition_id.name]}"
            printf '        techs = {'
            for tech in ${ICON_CONFIG[$definition_id.techs]}; do
                printf ' [%s] = true,' "$tech"
            done
            printf ' },\n'

            printf '        categories = {'
            for value in ${ICON_CONFIG[$definition_id.target_categories]}; do
                printf ' "%s",' "$value"
            done
            printf ' },\n'

            printf '        strategicIconNames = {'
            for value in ${ICON_CONFIG[$definition_id.target_icon_names]}; do
                printf ' "%s",' "$value"
            done
            printf ' },\n'

            printf '        excludedBlueprints = {'
            for value in ${ICON_CONFIG[$definition_id.excluded_blueprints]}; do
                printf ' "%s",' "${value,,}"
            done
            printf ' },\n'
            printf '    },\n'
        } >> "$temporary_file"
    done

    sed -n '/^-- END GENERATED ICON RULES$/,$p' "$MOD_ICONS_TEMPLATE" \
        >> "$temporary_file"

    if [[ -f "$MOD_ICONS_FILE" ]] && cmp -s "$temporary_file" "$MOD_ICONS_FILE"; then
        rm -f "$temporary_file"
    else
        mv "$temporary_file" "$MOD_ICONS_FILE"
    fi
}

# Atomically records fingerprints only after a completely successful run.
write_generation_cache() {
    local temporary_cache="$GENERATION_CACHE.tmp"
    local output

    : > "$temporary_cache"
    for output in "${!NEXT_ICON_FINGERPRINTS[@]}"; do
        printf '%s\t%s\n' "$output" "${NEXT_ICON_FINGERPRINTS[$output]}"
    done | sort > "$temporary_cache"

    mv "$temporary_cache" "$GENERATION_CACHE"
}
