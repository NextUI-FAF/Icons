from pathlib import Path

from pixelmap import PixelMap
from colors import black, player_color, white
from graphics import t2_indicator, t3_indicator

original_icons_dir = Path(__file__).with_name("original_icons")
FAF_ICON_SIZE = (12, 16)
FAF_SELECTED_ICON_SIZE = (16, 20)


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


def create_faf_icon_variants(
    icon: PixelMap,
    techs: list[int],
) -> list[PixelMap]:
    icon_states = []
    icon_states.append(icon.outline(1, black).add_suffix_to_the_name("_rest").set_canvas_size(FAF_ICON_SIZE))
    icon_states.append(icon.outline(1, player_color).add_suffix_to_the_name("_over").set_canvas_size(FAF_ICON_SIZE))
    icon_states.append(icon.outline(2, white).add_suffix_to_the_name("_selected").set_canvas_size(FAF_SELECTED_ICON_SIZE))
    icon_states.append(icon.outline(2, player_color).add_suffix_to_the_name("_selectedover").set_canvas_size(FAF_SELECTED_ICON_SIZE))

    variants = []
    for icon_state in icon_states:
        for tech in techs:
            if tech == 1:
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

    return icons
