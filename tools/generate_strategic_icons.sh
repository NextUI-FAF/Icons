#!/usr/bin/env bash
set -euo pipefail

# Strategic-icon generator entry point.
#
# Contributor contract:
#   * tools/strategic_icon_config.sh is the user-facing recipe file. Colors,
#     symbols, reusable border styles, and icon families belong there.
#   * tools/strategic-icons/ contains the internal implementation, grouped by
#     responsibility. This file only loads those modules and runs the CLI.
#   * Configuration API functions collect data only. They must not write files,
#     which keeps --check and the listing commands safe and predictable.
#   * Keep ImageMagick details out of the recipe file whenever a declarative
#     option can express the same intent.

readonly GENERATOR_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=tools/strategic-icons/common.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/common.sh"
# shellcheck source=tools/strategic-icons/config_api.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/config_api.sh"
# shellcheck source=tools/strategic-icons/rendering.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/rendering.sh"
# shellcheck source=tools/strategic-icons/native_icons.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/native_icons.sh"
# shellcheck source=tools/strategic-icons/outputs.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/outputs.sh"
# shellcheck source=tools/strategic-icons/validation.sh
source "$GENERATOR_TOOLS_DIR/strategic-icons/validation.sh"

# Parses the command line and runs one read-only or generating mode.
main() {
    local mode="generate"

    while (($# > 0)); do
        case "$1" in
            --check)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode: --check or --list-symbols."
                mode="check"
                ;;
            --list-symbols)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode."
                mode="list-symbols"
                ;;
            --list-shapes)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode."
                mode="list-shapes"
                ;;
            --list-border-styles)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode."
                mode="list-border-styles"
                ;;
            --list-border-patterns)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode."
                mode="list-border-patterns"
                ;;
            --list-icons)
                [[ "$mode" == "generate" ]] ||
                    die "Choose only one mode."
                mode="list-icons"
                ;;
            -h|--help)
                print_help
                return 0
                ;;
            *)
                die "Unknown option: $1. Use --help for usage."
                ;;
        esac
        shift
    done

    load_icon_config
    validate_configuration

    if [[ "$mode" == "list-symbols" ]]; then
        list_symbols
        return 0
    fi

    if [[ "$mode" == "list-shapes" ]]; then
        list_shapes
        return 0
    fi

    if [[ "$mode" == "list-border-styles" ]]; then
        list_border_styles
        return 0
    fi

    if [[ "$mode" == "list-border-patterns" ]]; then
        list_border_patterns
        return 0
    fi

    if [[ "$mode" == "list-icons" ]]; then
        list_icons
        return 0
    fi

    require_command magick
    require_command unzip
    require_command awk
    require_command sha256sum
    require_command stat
    validate_image_configuration
    locate_textures_archive
    register_global_tech_outputs
    validate_global_tech_sources

    if [[ "$mode" == "check" ]]; then
        printf 'Strategic icon configuration is valid.\n'
        printf 'Planned icon files: %s\n' "${#PLANNED_ICON_OUTPUTS[@]}"
        return 0
    fi

    prepare_directories
    load_generation_cache
    initialize_generation_fingerprints
    clean_generated_previews
    create_symbol_masks
    create_tech_symbol_masks
    generate_all_icons
    generate_global_tech_icons
    generate_upgrading_overlays
    generate_previews
    generate_global_tech_preview
    generate_player_color_previews
    remove_obsolete_icon_outputs
    write_mod_icons_file
    write_generated_manifest
    write_generation_cache

    printf 'Generated native-style strategic icons in %s\n' "$ICONS_DIR"
    printf 'Regenerated icon files: %s; unchanged icon files: %s\n' \
        "$generated_icon_count" "$skipped_icon_count"
    printf 'Kept generator workspace in %s\n' "$WORK_DIR"
    printf 'Generated icon previews in %s\n' "$PREVIEWS_DIR"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
