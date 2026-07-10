from __future__ import annotations
from pathlib import Path

from faf import create_faf_icon_variants, create_t1_icons_without_tech_marker
from graphics import (
    antimissile_symbol,
    artillery_symbol,
    corners_blue_border,
    corners_yellow_border,
    hazard_warning_border,
    intel_symbol,
    mex_symbol_outlined,
    missile_symbol,
    outlined_antiair_symbol,
    pgen_symbol,
    sml_symbol,
    square,
    square_big,
)
from pixelmap import PixelMap, export_pixel_maps, generate_previews


previews_dir = Path(__file__).with_name("previews")
main_icons_dir = Path(__file__).resolve().parent / '..' / "custom-strategic-icons"



def create_custom_icons() -> list[PixelMap]:
    icons = []

    pgen_icon = square.combine_pixel_map(pgen_symbol, "center", name="icon_structure[T]_energy")
    icons.extend(create_faf_icon_variants(pgen_icon, [2, 3]))

    mex_icon = square.combine_pixel_map(mex_symbol_outlined, "center", name="icon_structure[T]_mass")
    icons.extend(create_faf_icon_variants(mex_icon, [1, 2, 3]))

    intel_icon = square.combine_pixel_map(intel_symbol, "center", name="icon_structure[T]_intel")
    icons.extend(create_faf_icon_variants(intel_icon, [1, 2, 3]))

    tml_icon = corners_yellow_border.combine_pixel_map(square_big, "center")
    tml_icon = tml_icon.combine_pixel_map(missile_symbol, "center", name="icon_structure[T]_missile")
    icons.extend(create_faf_icon_variants(tml_icon, [2]))

    sml_icon = hazard_warning_border.combine_pixel_map(square_big, "center")
    sml_icon = sml_icon.combine_pixel_map(sml_symbol, "center", name="icon_structure[T]_missile")
    icons.extend(create_faf_icon_variants(sml_icon, [3]))

    artillery_icon = hazard_warning_border.combine_pixel_map(square_big, "center")
    artillery_icon = artillery_icon.combine_pixel_map(artillery_symbol, "center", name="icon_structure[T]_artillery")
    icons.extend(create_faf_icon_variants(artillery_icon, [3]))

    smd_icon = corners_blue_border.combine_pixel_map(square_big, "center")
    smd_icon = smd_icon.combine_pixel_map(antimissile_symbol, "center", name="icon_structure[T]_antimissile")
    icons.extend(create_faf_icon_variants(smd_icon, [3]))

    AA__structure_icon = square.combine_pixel_map(outlined_antiair_symbol, "center", name="icon_structure[T]_antiair")
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
