player_color = "#7b7d7b"

black = "#000000"
white = "#ffffff"
yellow = "#ffff33" # funciona
pure_yellow = "#ffff00"
amber_tactical = "#D97706"
green = "#4dff70" # funciona
green_pure = "#00ff00"
green_clear = "#bffcff"
green_tactical_olive = "#4A5320"
green_militar = "#5D6532"
cyan = "#27d9ff" # Funciona
orange = "#ff8a00"
red = "#ff3030"
magenta = "#ff00ff"
blue_cobalt_defense = "#00ACFF"
blue_tactical_navy = "#051C33"

TRANSPARENT = (0, 0, 0, 0)

def hex_to_rgba(color: str) -> tuple[int, int, int, int]:
    color = color.removeprefix("#")
    if len(color) != 6:
        raise ValueError(f"Expected #RRGGBB color, got {color!r}")
    return (
        int(color[0:2], 16),
        int(color[2:4], 16),
        int(color[4:6], 16),
        255,
    )