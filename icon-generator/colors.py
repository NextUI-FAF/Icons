# el juego remplaza este color por el color del jugador
player_color = "#7b7d7b"

black = "#000000" # SI Funciona
white = "#ffffff" # SI Funciona
yellow = "#ffff33" # SI Funciona
pure_yellow = "#ffff00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
amber_tactical = "#D97706" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
green = "#4dff70" # SI Funciona
green_pure = "#00ff00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
green_clear = "#bffcff"  # SI Funciona
green_tactical_olive = "#4A5320" # No sirve, lo pinta del color del jugador completamente
green_militar = "#5D6532" # No sirve, lo pinta del color del jugador completamente
orange = "#ff8a00" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
red = "#ff3030"
magenta = "#ff00ff"# No sirve, mancha algunos pixeles que deberian ser del color del jugador
cyan = "#00ffff" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
blue_light = "#27d9ff" # SI Funciona
blue_cobalt_defense = "#00ACFF" # No sirve, mancha algunos pixeles que deberian ser del color del jugador
blue_tactical_navy = "#051C33" # SI funciona, pero se pierde un poco de detalle por ser casi negro

# Los siguientes colores no sirven para los simbolos de los iconos ya que manchan 
# algunos pixeles que deberian ser del color del jugador, pero funcionan bien para los detalles de 
# de los bordes gruesos que estan separados del centro del icono como 

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
