from __future__ import annotations
from pathlib import Path

from faf import (
    LARGE_FAF_CANVAS,
    create_t1_icons_without_tech_marker,
    compose_faf_icon_with_variants,
    generate_faf_icons_previews,
    export_faf_icons_with_variants
)
from pixel_patterns import *
from pixelmap import combine_pixel_maps


main_icons_dir = Path(__file__).resolve().parent / '..' / "custom-strategic-icons"

def create_faf_custom_icons() -> None:
    compose_faf_icon_with_variants([commander_shape_uef,],"icon_commander_uef", canvas=LARGE_FAF_CANVAS, border_inwards=True)
    compose_faf_icon_with_variants([commander_shape_aeon,],"icon_commander_aeon", canvas=LARGE_FAF_CANVAS, border_inwards=True)
    compose_faf_icon_with_variants([commander_shape_cybran,],"icon_commander_cybran", canvas=LARGE_FAF_CANVAS, border_inwards=True)
    compose_faf_icon_with_variants([commander_shape_seraphim,],"icon_commander_seraphim", canvas=LARGE_FAF_CANVAS, border_inwards=True)
    compose_faf_icon_with_variants([square, pgen_symbol_outlined], "icon_structure[T]_energy", [2, 3])
    compose_faf_icon_with_variants([square, mex_symbol_outlined], "icon_structure[T]_mass", [1, 2, 3])
    compose_faf_icon_with_variants([square, intel_symbol_outlined], "icon_structure[T]_intel", [1, 2, 3])
    compose_faf_icon_with_variants([square, antiair_symbol], "icon_structure[T]_antiair", [1, 2, 3])
    air_hq_symbol = combine_pixel_maps([air_factoryhq_symbol, crown_symbol_outlined], offset=(0, -3))
    land_hq_symbol = combine_pixel_maps([land_factoryhq_symbol, crown_symbol_outlined], offset=(0, -3))
    naval_hq_symbol = combine_pixel_maps([naval_factoryhq_symbol, crown_symbol_outlined], offset=(0, -3))
    compose_faf_icon_with_variants([rectangle, air_hq_symbol], "icon_factoryhq[T]_air", [2, 3], canvas=[(16, 12), (20, 16)])
    compose_faf_icon_with_variants([rectangle, land_hq_symbol], "icon_factoryhq[T]_land", [2, 3], canvas=[(16, 12), (20, 16)])
    compose_faf_icon_with_variants([rectangle, naval_hq_symbol], "icon_factoryhq[T]_naval", [2, 3], canvas=[(16, 12), (20, 16)])
    compose_faf_icon_with_variants([square_big, square_border_corner, missile_symbol_outlined], "icon_structure[T]_missile", [2], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, squarebig_border_hazard_warning, sml_symbol_outlined], "icon_structure[T]_missile", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, squarebig_border_hazard_warning, artillery_symbol_outlined], "icon_structure[T]_artillery", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)
    compose_faf_icon_with_variants([square_big, squarebig_border_corners, antimissile_symbol_outlined], "icon_structure[T]_antimissile", [3], border_inwards=True, canvas=LARGE_FAF_CANVAS)

def main() -> int:
    create_t1_icons_without_tech_marker()
    create_faf_custom_icons()
    generate_faf_icons_previews()
    export_faf_icons_with_variants(main_icons_dir)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
