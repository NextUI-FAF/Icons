from __future__ import annotations
from pathlib import Path

from faf import (
    FAF_LARGE_ICON_SIZE,
    FAF_LARGE_SELECTED_ICON_SIZE,
    create_faf_icon_variants,
    create_t1_icons_without_tech_marker,
)
from graphics import *
from pixelmap import PixelMap, export_pixel_maps, generate_previews


previews_dir = Path(__file__).with_name("previews")
main_icons_dir = Path(__file__).resolve().parent / '..' / "custom-strategic-icons"



def create_custom_icons() -> list[PixelMap]:
    icons = []
    large_canvas = {
        "canvas_size": FAF_LARGE_ICON_SIZE,
        "selected_canvas_size": FAF_LARGE_SELECTED_ICON_SIZE,
    }

    pgen_icon = square.combine_pixel_map(pgen_symbol_outlined, "center", name="icon_structure[T]_energy")
    icons.extend(create_faf_icon_variants(pgen_icon, [2, 3]))

    mex_icon = square.combine_pixel_map(mex_symbol_outlined, "center", name="icon_structure[T]_mass")
    icons.extend(create_faf_icon_variants(mex_icon, [1, 2, 3]))

    intel_icon = square.combine_pixel_map(intel_symbol_outlined, "center", name="icon_structure[T]_intel")
    icons.extend(create_faf_icon_variants(intel_icon, [1, 2, 3]))

    tml_icon = square.combine_pixel_map(corners_yellow_border, "center")
    tml_icon = tml_icon.combine_pixel_map(missile_symbol_outlined, "center", name="icon_structure[T]_missile")
    icons.extend(create_faf_icon_variants(tml_icon, [2], canvas_size=(16, 20), selected_canvas_size=(16, 20), create_border_inwards=True))

    sml_icon = hazard_warning_border.combine_pixel_map(square_big, "center")
    sml_icon = sml_icon.combine_pixel_map(sml_symbol_outlined, "center", name="icon_structure[T]_missile")
    icons.extend(create_faf_icon_variants(sml_icon, [3], canvas_size=FAF_LARGE_ICON_SIZE, selected_canvas_size=FAF_LARGE_SELECTED_ICON_SIZE, create_border_inwards=True))

    artillery_icon = hazard_warning_border.combine_pixel_map(square_big, "center")
    artillery_icon = artillery_icon.combine_pixel_map(artillery_symbol_outlined, "center", name="icon_structure[T]_artillery")
    icons.extend(create_faf_icon_variants(artillery_icon, [3], canvas_size=FAF_LARGE_ICON_SIZE, selected_canvas_size=FAF_LARGE_SELECTED_ICON_SIZE, create_border_inwards=True))

    smd_icon = corners_blue_border.combine_pixel_map(square_big, "center")
    smd_icon = smd_icon.combine_pixel_map(antimissile_symbol_outlined, "center", name="icon_structure[T]_antimissile")
    icons.extend(create_faf_icon_variants(smd_icon, [3], FAF_LARGE_ICON_SIZE, FAF_LARGE_SELECTED_ICON_SIZE, create_border_inwards=True))

    AA__structure_icon = square.combine_pixel_map(antiair_symbol_outlined, "center", name="icon_structure[T]_antiair")
    icons.extend(create_faf_icon_variants(AA__structure_icon, [1, 2, 3]))


    return icons





def main() -> int:
    t1_icons = create_t1_icons_without_tech_marker()
    custom_icons = create_custom_icons()

    generate_previews(t1_icons + custom_icons, previews_dir)
    export_pixel_maps(t1_icons, main_icons_dir)
    export_pixel_maps(custom_icons, main_icons_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
