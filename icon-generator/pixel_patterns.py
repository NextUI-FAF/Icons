from pixelmap import PixelPattern
from colors import *


# Icon geometry ---------------------------------------------------------------

square = PixelPattern.fill(9, 9, name="square", A=player_color)

square_big = PixelPattern.fill(11, 11, name="square_big", A=player_color)

rectangle = PixelPattern.fill(13, 7, name="rectangle", A=player_color)

# rectange_with_crown = PixelPattern.from_text(
#     """A A A A A A A A A A A A A"""
# )

hexagon = PixelPattern.from_text(
    """X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       A A A A A A A A A A A
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X""",
    name="hexagon", A=player_color,
)

diamond = PixelPattern.from_text(
    """X X X X A X X X X
       X X X A A A X X X
       X X A A A A A X X
       X A A A A A A A X
       A A A A A A A A A
       X A A A A A A A X
       X X A A A A A X X
       X X X A A A X X X
       X X X X A X X X X""",
    name="diamond", A=player_color,
)

triangle = PixelPattern.from_text(
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
    name="triangle", A=player_color,
)

wide_triangle = PixelPattern.from_text(
    """X X X X X X A X X X X X X
       X X X X X A A A X X X X X
       X X X X A A A A A X X X X
       X X X A A A A A A A X X X
       X X A A A A A A A A A X X
       X A A A A A A A A A A A X
       A A A A A A A A A A A A A""",
    name="wide_triangle", A=player_color,
)

trapezium = PixelPattern.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X A A A A A A A X X""",
    name="trapezium", A=player_color,
)

semicircle = PixelPattern.from_text(
    """X X X X X A X X X X X
       X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       X A A A A A A A A A X
       A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A""",
    name="semicircle", A=player_color,
)

inverted_semicircle = PixelPattern.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X
       X X X X X A X X X X X""",
    name="inverted_semicircle", A=player_color,
)

circle = PixelPattern.from_text(
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
    name="circle", A=player_color,
)


# Global tech-level symbols ---------------------------------------------------

t2_indicator = PixelPattern.from_text(
    """X B B B B B X
       X B A B A B X
       X B A B A B X
       X B B B B B X""",
    name="tech2", A=white, B=black,
)

t3_indicator = PixelPattern.from_text(
    """B B B B B B B
       B A B A B A B
       B A B A B A B
       B B B B B B B""",
    name="tech3", A=white, B=black,
)

diamond_t3_indicator = PixelPattern.from_text(
    """B X X X X X B
       B A X X X A B
       B A B X B A B
       B A B A B A B
       B B B B B B B""",
    name="diamond_tech3", A=white, B=black,
)


# Reusable symbols ------------------------------------------------------------

generic_symbol = PixelPattern.from_text(
    """X X X X X
       X X X X X
       X X X X X
       X X X X X
       X X X X X""",
    name="generic_symbol",
)

directfire_symbol = PixelPattern.from_text(
    """X X A X X
       X X A X X
       A A X A A
       X X A X X
       X X A X X""",
    name="directfire", A=red_orange,
)



antiartillery_symbol = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A X A X
       X X A X X
       X X X X X""",
    name="antiartillery", A=blue_cobalt_defense,
)

antinavy_symbol = PixelPattern.from_text(
    """X X X X X
       A A A A A
       X X X X X
       X X A X X
       X X A X X""",
    name="antinavy", A=cyan,
)

antishield_symbol = PixelPattern.from_text(
    """X X A X A X X
       X X X X X X X
       X A X X X A X
       A A X X X A A""",
    name="antishield", A=magenta,
)

crown_symbol = PixelPattern.from_text(
    """A X A X A
       X A A A X""",
       name="crown", A=gold_bright,
)
crown_symbol_outlined = crown_symbol.outline(1, black)

air_symbol = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A X A X
       A X X X A
       X X X X X""",
    name="air", A=black,
)
air_symbol_outlined = air_symbol.outline(1, black)


air_factoryhq_symbol = PixelPattern.from_text(
    """X X X X X X X X X X X
       A X X X X A X X X X A
       A X X X A X A X X X A
       A X X A X X X A X X A
       X X X X X X X X X X X""",
    name="air", A=black,
)
air_factoryhq_symbol_outlined = air_factoryhq_symbol.outline(1, black)

land_symbol = PixelPattern.from_text(
    """X X A X X
       X A X A X
       A X X X A
       X A X A X
       X X A X X""",
    name="land", A=black,
)
land_symbol_outlined = land_symbol.outline(1, black)

land_factoryhq_symbol = PixelPattern.from_text(
    """X X X X A X X X X
       A X X A X A X X A
       A X A X X X A X A
       A X X A X A X X A
       X X X X A X X X X""",
    name="land", A=black,
)

naval_factoryhq_symbol = PixelPattern.from_text(
    """X X X X X X X X X
       A X X X X X X X A
       A X A X X X A X A
       A X X A A A X X A
       X X X X X X X X X""",
    name="naval", A=black,
)
naval_factoryhq_symbol_outlined = naval_factoryhq_symbol.outline(1, black)

naval_symbol = PixelPattern.from_text(
    """X X X X X
       A X X X A
       X A A A X
       X X X X X
       X X X X X""",
    name="naval", A=black,
)
naval_symbol_outlined = naval_symbol.outline(1, black)

transport_symbol = PixelPattern.from_text(
    """A A A A A
       A X X X A
       A X X X A
       X X A X X
       X X A X X""",
    name="transport", A=cyan_pale,
)

shield_symbol = PixelPattern.from_text(
    """X X X X X
       X A A A X
       A X X X A
       A X X X A
       A X X X A""",
    name="shield", A=blue_cobalt_defense,
)

counterintel_symbol = PixelPattern.from_text(
    """A X A X A
       X X X X X
       X A X A X
       X X X X X
       X X A X X""",
    name="counterintel", A=cyan,
)

engineer_symbol = PixelPattern.from_text(
    """X X X X X
       A A A A A
       X X A X X
       X X A X X
       X X X X X""",
    name="engineer", A=green,
)

bomb_symbol = PixelPattern.from_text(
    """A X X X A
       X A X A X
       X X X X X
       X A X A X
       A X X X A""",
    name="bomb", A=orange,
)

wall_symbol = PixelPattern.from_text(
    """A A A A A
       A X A X A
       A A A A A
       A X A X A
       A A A A A""",
    name="wall", A=player_color,
)

antiair_symbol = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A X A X
       A X X X A
       X X X X X""",
    name="antiair", A=blue_light,
)

pgen_symbol = PixelPattern.from_text(
    """X A X X X
       X X A X X
       X A A A X
       X X A X X
       X X X A X""",
    name="pgen", A=yellow,
)

mex_symbol = PixelPattern.from_text(
    """X A A A X
       A X X X A
       A A X A A
       X X X X X
       X X A X X""",
    name="mex", A=green_neon,
)

intel_symbol = PixelPattern.from_text(
    """A A A A A
       X X X X X
       X A A A X
       X X X X X
       X X A X X""",
    name="intel", A=silver_bright,
)

missile_symbol = PixelPattern.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
    name="missile", A=peach_bright,
)

sml_symbol = PixelPattern.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
    name="sml", A=red_signal,
)

antimissile_symbol = PixelPattern.from_text(
    """X X A X X
       X X X X X
       X X A X X
       X X X X X
       X X A X X""",
    name="antimissile", A=indigo_bright,
)

artillery_symbol = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A A A X
       X X A X X
       X X X X X""",
    name="artillery", A=red_orange,
)

# Reusable borders ------------------------------------------------------------

square_border_corner = PixelPattern.from_text(
    """A A A B B B B B B B A A A
       A C C C C C C C C C C C A
       A C X X X X X X X X X C A
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       B C X X X X X X X X X C B
       A C X X X X X X X X X C A
       A C C C C C C C C C C C A
       A A A C C C C C C C A A A""",
    name="corners_border", A=yellow, B=black, C=black,
)

squarebig_border_corners = PixelPattern.from_text(
    """A A A B B B B B B B B B A A A
       A C C C C C C C C C C C C C A
       A C X X X X X X X X X X X C A
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       B C X X X X X X X X X X X C B
       A C X X X X X X X X X X X C A
       A C C C C C C C C C C C C C A
       A A A C C C C C C C C C A A A""",
    name="corners_big_border", A=blue_electric, B=black, C=black,
)

squarebig_border_hazard_warning = PixelPattern.from_text(
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
    name="hazard_warning_border", A=red_bright, B=black, C=black,
)


# Prepared pattern variants ---------------------------------------------------

outlined_square = square.outline(width=1, color=black)
antiair_symbol_outlined = antiair_symbol.outline(width=1, color=black)
pgen_symbol_outlined = pgen_symbol.outline(width=1, color=black)
mex_symbol_outlined = mex_symbol.outline(width=1, color=black)
intel_symbol_outlined = intel_symbol.outline(width=1, color=black)
missile_symbol_outlined = missile_symbol.outline(width=1, color=black)
sml_symbol_outlined = sml_symbol.outline(width=1, color=black)
antimissile_symbol_outlined = antimissile_symbol.outline(width=1, color=black)
artillery_symbol_outlined = artillery_symbol.outline(width=1, color=black)
directfire_symbol_outlined = directfire_symbol.outline(width=1, color=black)

# Full Icons

commander_shape_original = PixelPattern.from_text(
    """X X X X X X X X X X X X
       X X X X X A A X X X X X
       X X A A X A A X A A X X
       X X A A A A A A A A X X
       X X A X X A A X X A X X
       X A A X A A A A X A A X
       X A X X A X X A X X A X
       X A X X A X X A X X A X
       X X X A A X X A A X X X
       X X X A A X X A A X X X
       X X X A A X X A A X X X
       X X X X X X X X X X X X""",
    name="commander_shape",
    A=player_color,
)

commander_shape_cybran = PixelPattern.from_text(
    """X X X X A X X A X X X X
       X X X X X A A X X X X X
       X A X A X A A X A X A X
       X X A A A A A A A A X X
       X X A X X A A X X A X X
       X A A X A A A A X A A X
       X A X X A X X A X X A X
       X A X X A X X A X X A X
       X X X A A X X A A X X X
       X X X A A X X A A X X X
       X X X A A X X A A X X X
       X X X X X X X X X X X X""",
    name="commander_shape",
    A=player_color,
)

commander_shape_seraphim = PixelPattern.from_text(
    """X X X X X A X X X X X 
       X X A X X A X X A X X  
       X X A X A A A X A X X 
       X X A A A A A A A X X  
       X X A X A A A X A X X 
       X X A X X A X X A A X 
       X A A X A A A X X A X 
       X A X X A X A X X A X 
       X X X X A X A X X X X 
       X X X A A X A A X X X 
       X X A X A X A X A X X 
       X X X X X X X X X X X """,
    name="commander_shape_seraphim",
    A=player_color,
)

commander_shape_aeon = PixelPattern.from_text(
    """X X X X X X X X X X X 
       X X X X A A A X X X X  
       X X A X X A X X A X X 
       X A A A A A A A A A X  
       X X A X X A X X A X X 
       X X A X A A A X A A X 
       X A A X A X A X X A X 
       X A X X A X A X X A X 
       X X X X A X A X X X X 
       X X X A A X A A X X X 
       X X X A A X A A X X X 
       X X X X X X X X X X X """,
    name="commander_shape_aeon",
    A=player_color,
)

commander_shape_aeon = commander_shape_aeon.outline(width=1, color=black).outline(width=1, color=player_color).outline(width=1, color=black)
commander_shape_uef = commander_shape_original.outline(width=1, color=black).outline(width=1, color=player_color).outline(width=1, color=black)
commander_shape_cybran = commander_shape_cybran.outline(width=1, color=black).outline(width=1, color=player_color).outline(width=1, color=black)
commander_shape_seraphim = commander_shape_seraphim.outline(width=1, color=black).outline(width=1, color=player_color).outline(width=1, color=black)
