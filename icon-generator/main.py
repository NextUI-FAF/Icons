from __future__ import annotations
from pathlib import Path

from faf import (
    LARGE_FAF_CANVAS,
    create_t1_icons_without_tech_marker,
    compose_faf_icon_with_variants,
    generate_faf_icons_previews,
    export_faf_icons_with_variants
)
from graphics import *
from pixelmap import generate_pixelmap_gallery


main_icons_dir = Path(__file__).resolve().parent / '..' / "custom-strategic-icons"

def create_faf_custom_icons() -> None:
    compose_faf_icon_with_variants([square, pgen_symbol_outlined], "icon_structure[T]_energy", [2, 3])
    compose_faf_icon_with_variants([square, mex_symbol_outlined], "icon_structure[T]_mass", [1, 2, 3])
    compose_faf_icon_with_variants([square, intel_symbol_outlined], "icon_structure[T]_intel", [1, 2, 3])
    compose_faf_icon_with_variants([square_big, corners_yellow_border, missile_symbol_outlined], "icon_structure[T]_missile", [2], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, corners_blue_border, sml_symbol_outlined], "icon_structure[T]_missile", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, hazard_warning_border, artillery_symbol_outlined], "icon_structure[T]_artillery", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, corners_blue_border, antimissile_symbol_outlined], "icon_structure[T]_antimissile", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, corners_blue_border, antiair_symbol], "icon_structure[T]_antiair", [1, 2, 3], border_inwards=True, canvas=LARGE_FAF_CANVAS)

def main() -> int:
    create_t1_icons_without_tech_marker()
    create_faf_custom_icons()
    generate_faf_icons_previews()
    export_faf_icons_with_variants(main_icons_dir)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
