from pixelmap import PixelMap
from colors import *


# Icon geometry ---------------------------------------------------------------

square = PixelMap.fill(9, 9, player_color, name="square")
outlined_square = square.outline(color=black, width=1)

square_big = PixelMap.fill(11, 11, player_color, name="square_big")

rectangle = PixelMap.fill(13, 7, player_color, name="rectangle")

hexagon = PixelMap.from_text(
    """X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       A A A A A A A A A A A
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X""",
    colors={"A": player_color},
    name="hexagon",
)

diamond = PixelMap.from_text(
    """X X X X A X X X X
       X X X A A A X X X
       X X A A A A A X X
       X A A A A A A A X
       A A A A A A A A A
       X A A A A A A A X
       X X A A A A A X X
       X X X A A A X X X
       X X X X A X X X X""",
    colors={"A": player_color},
    name="diamond",
)

triangle = PixelMap.from_text(
    """X X X X A X X X X
       X X X X A X X X X
       X X X A A A X X X
       X X X A A A X X X
       X X A A A A A X X
       X X A A A A A X X
       X A A A A A A A X
       X A A A A A A A X
       A A A A A A A A A
       A A A A A A A A A""",
    colors={"A": player_color},
    name="triangle",
)

wide_triangle = PixelMap.from_text(
    """X X X X X X A X X X X X X
       X X X X X A A A X X X X X
       X X X X A A A A A X X X X
       X X X A A A A A A A X X X
       X X A A A A A A A A A X X
       X A A A A A A A A A A A X
       A A A A A A A A A A A A A""",
    colors={"A": player_color},
    name="wide_triangle",
)

trapezium = PixelMap.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X A A A A A A A X X""",
    colors={"A": player_color},
    name="trapezium",
)

semicircle = PixelMap.from_text(
    """X X X X X A X X X X X
       X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       X A A A A A A A A A X
       A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A""",
    colors={"A": player_color},
    name="semicircle",
)

inverted_semicircle = PixelMap.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X
       X X X X X A X X X X X""",
    colors={"A": player_color},
    name="inverted_semicircle",
)

circle = PixelMap.from_text(
    """X X X A A A X X X
       X X X A A A X X X
       X X A A A A A X X
       X A A A A A A A X
       A A A A A A A A A
       A A A A A A A A A
       A A A A A A A A A
       X A A A A A A A X
       X X A A A A A X X
       X X X A A A X X X""",
    colors={"A": player_color},
    name="circle",
)


# Global tech-level symbols ---------------------------------------------------

t2_indicator = PixelMap.from_text(
    """X B B B B B X
       X B A B A B X
       X B A B A B X
       X B B B B B X""",
    colors={"A": white, "B": black},
    name="tech2",
)

t3_indicator = PixelMap.from_text(
    """B B B B B B B
       B A B A B A B
       B A B A B A B
       B B B B B B B""",
    colors={"A": white, "B": black},
    name="tech3",
)

diamond_t3_indicator = PixelMap.from_text(
    """B X X X X X B
       B A X X X A B
       B A B X B A B
       B A B A B A B
       B B B B B B B""",
    colors={"A": white, "B": black},
    name="diamond_tech3",
)


# Reusable symbols ------------------------------------------------------------

generic_symbol = PixelMap.from_text(
    """X X X X X
       X X X X X
       X X X X X
       X X X X X
       X X X X X""",
    colors={"A": white},
    name="generic",
)

directfire_symbol = PixelMap.from_text(
    """X X A X X
       X X A X X
       A A X A A
       X X A X X
       X X A X X""",
    colors={"A": red},
    name="directfire",
)

antiair_symbol = PixelMap.from_text(
    """X X X X X
       X A A A X
       A X X X A
       X X X X X
       X X X X X""",
    colors={"A": blue_cobalt_defense},
    name="antiair",
)

outlined_antiair_symbol = PixelMap.from_text(
    """X X B B B X X
       X B B A B B X
       B B A B A B B
       B A B B B A B
       B B B X B B B""",
    colors={"A": blue_cobalt_defense, "B": black},
    name="outlined_antiair",
)

antiartillery_symbol = PixelMap.from_text(
    """X X X X X
       X X A X X
       X A X A X
       X X A X X
       X X X X X""",
    colors={"A": blue_cobalt_defense},
    name="antiartillery",
)

antinavy_symbol = PixelMap.from_text(
    """X X X X X
       A A A A A
       X X X X X
       X X A X X
       X X A X X""",
    colors={"A": cyan},
    name="antinavy",
)

antishield_symbol = PixelMap.from_text(
    """X X A X A X X
       X X X X X X X
       X A X X X A X
       A A X X X A A""",
    colors={"A": magenta},
    name="antishield",
)

air_symbol = PixelMap.from_text(
    """X X X X X
       X X A X X
       X A X A X
       A X X X A
       X X X X X""",
    colors={"A": cyan},
    name="air",
)

land_symbol = PixelMap.from_text(
    """X X A X X
       X A X A X
       A X X X A
       X A X A X
       X X A X X""",
    colors={"A": green},
    name="land",
)

naval_symbol = PixelMap.from_text(
    """X X X X X
       X X X X X
       X X X X X
       A X X X A
       X A A A X""",
    colors={"A": cyan},
    name="naval",
)

transport_symbol = PixelMap.from_text(
    """A A A A A
       A X X X A
       A X X X A
       X X A X X
       X X A X X""",
    colors={"A": green_clear},
    name="transport",
)

shield_symbol = PixelMap.from_text(
    """X X X X X
       X A A A X
       A X X X A
       A X X X A
       A X X X A""",
    colors={"A": blue_cobalt_defense},
    name="shield",
)

counterintel_symbol = PixelMap.from_text(
    """A X A X A
       X X X X X
       X A X A X
       X X X X X
       X X A X X""",
    colors={"A": cyan},
    name="counterintel",
)

engineer_symbol = PixelMap.from_text(
    """X X X X X
       A A A A A
       X X A X X
       X X A X X
       X X X X X""",
    colors={"A": green},
    name="engineer",
)

bomb_symbol = PixelMap.from_text(
    """A X X X A
       X A X A X
       X X X X X
       X A X A X
       A X X X A""",
    colors={"A": orange},
    name="bomb",
)

wall_symbol = PixelMap.from_text(
    """A A A A A
       A X A X A
       A A A A A
       A X A X A
       A A A A A""",
    colors={"A": player_color},
    name="wall",
)

pgen_symbol = PixelMap.from_text(
    """X A X X X
       X X A X X
       X A A A X
       X X A X X
       X X X A X""",
    colors={"A": yellow},
    name="pgen",
)

mex_symbol = PixelMap.from_text(
    """X A A A X
       A X X X A
       A A X A A
       X X X X X
       X X A X X""",
    colors={"A": green},
    name="mex",
)
mex_symbol_outlined = mex_symbol.outline(color=black, width=1)

intel_symbol = PixelMap.from_text(
    """A A A A A
       X X X X X
       X A A A X
       X X X X X
       X X A X X""",
    colors={"A": cyan},
    name="intel",
)

missile_symbol = PixelMap.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
    colors={"A": green_clear},
    name="missile",
)

sml_symbol = PixelMap.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
    colors={"A": magenta},
    name="sml",
)

antimissile_symbol = PixelMap.from_text(
    """X X A X X
       X X X X X
       X X A X X
       X X X X X
       X X A X X""",
    colors={"A": blue_cobalt_defense},
    name="antimissile",
)

artillery_symbol = PixelMap.from_text(
    """X X X X X
       X X A X X
       X A A A X
       X X A X X
       X X X X X""",
    colors={"A": magenta},
    name="artillery",
)

# Reusable borders ------------------------------------------------------------

corners_yellow_border = PixelMap.from_text(
    """B B B A A A A A A A B B B
       B C C C C C C C C C C C B
       B C X X X X X X X X X C B
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       A C X X X X X X X X X C A
       B C X X X X X X X X X C B
       B C C C C C C C C C C C B
       B B B A A A A A A A B B B""",
    colors={"A": black, "B": yellow, "C": black},
    name="corners_yellow_border",
)

corners_blue_border = PixelMap.from_text(
    """B B B A A A A A A A A A B B B
       B C C C C C C C C C C C C C B
       B C X X X X X X X X X X X C B
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C A
       B C X X X X X X X X X X X C B
       B C C C C C C C C C C C C C B
       B B B A A A A A A A A A B B B""",
    colors={"A": black, "B": blue_cobalt_defense, "C": black},
    name="corners_blue_border",
)

hazard_warning_border = PixelMap.from_text(
    """A A B B A A B B A A B B A A B
       A C C C C C C C C C C C C C B
       B C X X X X X X X X X X X C A
       B C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C B
       A C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C A
       B C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C B
       A C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C A
       B C X X X X X X X X X X X C A
       A C X X X X X X X X X X X C B
       A C C C C C C C C C C C C C B
       B B A A B B A A B B A A B B A""",
    colors={"A": yellow, "B": black, "C": black},
    name="hazard_warning_border",
)
