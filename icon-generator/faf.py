from dataclasses import dataclass
from collections.abc import Sequence
from pathlib import Path
from colors import (
    FAF_PLAYER_COLORS,
    black,
    hex_to_rgba,
    player_color,
    white,
    slate_bright
)
from pixelmap import PixelMap, PixelPattern, combine_pixel_maps, generate_previews, generate_pixelmap_preview_gallery
from pixel_patterns import t2_indicator, t3_indicator

original_icons_dir = Path(__file__).with_name("original_icons")
previews_dir = Path(__file__).with_name("previews")
FAF_ICON_SIZE = (12, 16)
FAF_SELECTED_ICON_SIZE = (16, 20)
FAF_LARGE_ICON_SIZE = (16, 20)
FAF_LARGE_SELECTED_ICON_SIZE = (20, 24)
player_colors_quantity = len(FAF_PLAYER_COLORS)


@dataclass(frozen=True)
class FafCanvas:
    rest: tuple[int, int]
    selected: tuple[int, int]


NORMAL_FAF_CANVAS = FafCanvas(
    rest=FAF_ICON_SIZE,
    selected=FAF_SELECTED_ICON_SIZE,
)
LARGE_FAF_CANVAS = FafCanvas(
    rest=FAF_LARGE_ICON_SIZE,
    selected=FAF_LARGE_SELECTED_ICON_SIZE,
)

composed_faf_icons: list[PixelMap] = []
composed_faf_rest_colored_icons: list[PixelMap] = []


def _get_visible_span(icon: PixelMap, y: int) -> tuple[int, int] | None:
    visible_x = [
        x
        for x, pixel in enumerate(icon.pixels[y])
        if pixel[3] > 0
    ]
    if not visible_x:
        return None

    return min(visible_x), max(visible_x)


def _row_looks_like_t1_marker(icon: PixelMap, y: int) -> bool:
    span = _get_visible_span(icon, y)
    if span is None:
        return False

    left, right = span
    visible_width = right - left + 1
    center = (icon.width - 1) / 2
    row_center = (left + right) / 2
    return visible_width <= 3 and abs(row_center - center) <= 1


def _remove_native_t1_marker(icon: PixelMap) -> PixelMap:
    marker_top = None

    for y in range(icon.height - 1, -1, -1):
        if _get_visible_span(icon, y) is None:
            continue
        if _row_looks_like_t1_marker(icon, y):
            marker_top = y
            continue
        break

    if marker_top is None:
        return icon

    return icon.erase_rect(0, marker_top, icon.width, icon.height - marker_top)

def _normalize_faf_canvas(
    canvas: FafCanvas | Sequence[tuple[int, int]],
) -> FafCanvas:
    if isinstance(canvas, FafCanvas):
        return canvas
    if len(canvas) != 2:
        raise ValueError("FAF canvas requires rest and selected sizes")

    rest, selected = canvas
    if len(rest) != 2 or len(selected) != 2:
        raise ValueError("Each FAF canvas size must contain width and height")
    if min(*rest, *selected) < 1:
        raise ValueError("FAF canvas dimensions must be positive")
    return FafCanvas(rest=tuple(rest), selected=tuple(selected))


def compose_faf_icon_with_variants(
    icons: list[PixelMap | PixelPattern],
    name: str,
    techs: list[int] | None = None,
    border_inwards: bool = False,
    canvas: FafCanvas | Sequence[tuple[int, int]] = NORMAL_FAF_CANVAS,
) -> list[PixelMap]:
    canvas = _normalize_faf_canvas(canvas)
    pixel_map = combine_pixel_maps(icons,  name=name)
    faf_icon_with_variants = generate_faf_icon_variants(
        pixel_map,
        techs,
        canvas_size=canvas.rest,
        selected_canvas_size=canvas.selected,
        create_border_inwards=border_inwards,
    )
    composed_faf_icons.extend(faf_icon_with_variants)
    return faf_icon_with_variants

def generate_faf_icons_previews(output_dir: Path = previews_dir, preview_gallery_background_color="#303030", horizontal_spacing = 6, vertical_spacing=8) -> None:
    generate_previews(composed_faf_icons, output_dir)
    colored_icon_columns = len(composed_faf_rest_colored_icons) // player_colors_quantity
    generate_pixelmap_preview_gallery(
        composed_faf_rest_colored_icons,
        filename=output_dir / "gallery_custom_colored_icons.png",
        rows=player_colors_quantity,
        columns=colored_icon_columns,
        arrange="top-to-bottom",
        background_color=preview_gallery_background_color,
        vertical_spacing=vertical_spacing,
        horizontal_spacing=horizontal_spacing
    )

def export_faf_icons_with_variants(output_dir: Path) -> None:
    for icon in composed_faf_icons:
        icon.export(output_path=output_dir)

def generate_faf_icon_variants(
    icon: PixelMap,
    techs: list[int] | None = None,
    canvas_size: tuple[int, int] = FAF_ICON_SIZE,
    selected_canvas_size: tuple[int, int] = FAF_SELECTED_ICON_SIZE,
    create_border_inwards: bool = False,
) -> list[PixelMap]:
    icon_states = []
    
    if not create_border_inwards:
        icon_states.append(icon.outline(1, black).add_suffix_to_the_name("_rest").set_canvas_size(canvas_size))
    else:
        icon_states.append(icon.add_suffix_to_the_name("_rest").set_canvas_size(canvas_size))
    composed_faf_rest_colored_icons.extend(
        generate_faf_icons_with_player_color_variants(icon_states[0])
    )
    icon_states.append(icon.outline(1, player_color, create_inwards=create_border_inwards).add_suffix_to_the_name("_over").set_canvas_size(canvas_size))
    icon_states.append(icon.outline(2, white, create_inwards=create_border_inwards).add_suffix_to_the_name("_selected").set_canvas_size(selected_canvas_size))
    icon_states.append(icon.outline(2, player_color, create_inwards=create_border_inwards).add_suffix_to_the_name("_selectedover").set_canvas_size(selected_canvas_size))

    variants = []
    variant_techs: list[int | None] = [None] if techs is None else techs
    for icon_state in icon_states:
        for tech in variant_techs:
            if tech is None:
                variant = icon_state
            elif tech == 1:
                variant = icon_state.replace_placeholder_in_the_name("[T]", "1")
            elif tech == 2:
                variant = icon_state.combine_pixel_map(t2_indicator, "center-bottom", offset=(0, -1), zindex=-1).replace_placeholder_in_the_name("[T]", "2")
            elif tech == 3:
                variant = icon_state.combine_pixel_map(t3_indicator, "center-bottom", offset=(0, -1), zindex=-1).replace_placeholder_in_the_name("[T]", "3")
            else:
                raise ValueError(f"Unsupported FAF tech level: {tech}")
            variants.append(variant.fit_to())

    return variants

def load_original_faf_icons_as_pixel_maps(tech: int | str = "") -> list[PixelMap]:
    icons = []
    for original_icon in sorted(original_icons_dir.glob(f"icon_*{tech}_*.dds")):
        icon_name = original_icon.stem
        icon = PixelMap.from_image(original_icon, name=icon_name)
        icons.append(icon)
    return icons

def create_t1_icons_without_tech_marker() -> list[PixelMap]:
    icons = []
    for original_icon in load_original_faf_icons_as_pixel_maps(tech=1):
        icons.append(_remove_native_t1_marker(original_icon))
    composed_faf_icons.extend(icons)
    return icons

def generate_faf_icons_with_player_color_variants(
    pixel_map: PixelMap,
) -> list[PixelMap]:
    player_rgb = hex_to_rgba(player_color)[:3]
    variants = []

    for color_name, color in FAF_PLAYER_COLORS.items():
        replacement_rgb = hex_to_rgba(color)[:3]

        pixels = tuple(
            tuple(
                (*replacement_rgb, pixel[3])
                if pixel[:3] == player_rgb
                else pixel
                for pixel in row
            )
            for row in pixel_map.pixels
        )

        variant_name = (
            f"{pixel_map.name}_{color_name}"
            if pixel_map.name is not None
            else color_name
        )

        variants.append(
            PixelMap(
                width=pixel_map.width,
                height=pixel_map.height,
                pixels=pixels,
                name=variant_name,
                canvas_size=pixel_map.canvas_size,
            )
        )

    return variants
