# el juego remplaza este color por el color del jugador
player_color = "#7b7d7b"

# Working colors with DXT5 compression, tested in-game.
# These colors are safe for strategic icon symbols in the tested layouts.
black = "#000000" # SI Funciona
white = "#ffffff" # SI Funciona
yellow = "#ffff33" # SI Funciona
green = "#4dff70" # SI Funciona
green_clear = "#bffcff"  # SI Funciona
blue_light = "#27d9ff" # SI Funciona
blue_tactical_navy = "#051C33" # SI funciona, pero se pierde un poco de detalle por ser casi negro
red_signal = "#ff4d57"
coral_warning = "#ff6b57"
orange_safety = "#ff9f43"
gold_bright = "#ffd84d"
lime_energy = "#b8ff4d"
green_neon = "#39ff88"
mint_bright = "#66ffd1"
turquoise_bright = "#33e6c4"
cyan_ice = "#66f2ff"
blue_electric = "#4d9dff"
pink_signal = "#ff5ccf"

# DXT5 candidates for the next in-game test pass. These stay close to color
# families that already work, while exploring additional useful shades.
red_bright = "#ff3855"
red_orange = "#ff594d"
peach_bright = "#ffad80"
orange_bright = "#ffb347"
yellow_soft = "#fff066"
chartreuse_bright = "#c8ff57"
green_spring = "#57ff7a"
emerald_bright = "#4dff9a"
seafoam_bright = "#8affd1"
teal_neon = "#33ffd6"
sky_bright = "#66d9ff"
blue_ice = "#8abfff"
rose_bright = "#ff6ba8"
pink_soft = "#ff8fd8"

# Los siguientes colores no sirven para los simbolos de los iconos ya que manchan
# algunos pixeles que deberian ser del color del jugador, pero tal vez funcionan bien para los detalles de
# de los bordes gruesos que estan separados del centro del icono gracias a una linea negra que los separa
# del color del jugador
pure_yellow = "#ffff00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
amber_tactical = "#D97706" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
green_pure = "#00ff00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
green_tactical_olive = "#4A5320" # No sirve, lo pinta del color del jugador completamente
green_militar = "#5D6532" # No sirve, lo pinta del color del jugador completamente
orange = "#ff8a00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
magenta = "#ff00ff"# No sirve, mancha algunos pixeles que deberian ser del color del jugador
cyan = "#00ffff" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
blue_cobalt_defense = "#00ACFF" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
violet_energy = "#a66bff" # No sirve en DXT5; el simbolo toma el color del jugador

# FAF player colors from /lua/GameColors.lua.
# Do not use these for strategic icon symbols: they are actual player colors,
# so they can be confusing in-game or visually disappear against player-owned units.
FAF_PLAYER_COLORS = {
    "cybran_red": "#e80a0a",
    "dark_red": "#901427",
    "nomads_orange": "#ff873e",
    "brown": "#b76518",
    "sera_golden": "#a79602",
    "yellow": "#fafa00",
    "order_green": "#9fd802",
    "mid_green": "#40bf40",
    "green": "#2e8b57",
    "olive_dark_green": "#2f4f4f",
    "blue": "#436eee",
    "uef_blue": "#2929e1",
    "dark_purple": "#5f01a7",
    "purple": "#9161ff",
    "aqua": "#66ffcc",
    "white": "#ffffff",
    "grey": "#616d7e",
    "pink": "#ff88ff",
    "fuschia": "#ff32ff",
}

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
