from colors import *
from pixel_patterns import *


# Icon geometry ---------------------------------------------------------------

square = square_pattern.color({"A": player_color}, name="square")
outlined_square = square.outline(color=black, width=1)
square_big = square_big_pattern.color({"A": player_color}, name="square_big")
rectangle = rectangle_pattern.color({"A": player_color}, name="rectangle")
hexagon = hexagon_pattern.color({"A": player_color}, name="hexagon")
diamond = diamond_pattern.color({"A": player_color}, name="diamond")
triangle = triangle_pattern.color({"A": player_color}, name="triangle")
wide_triangle = wide_triangle_pattern.color({"A": player_color}, name="wide_triangle")
trapezium = trapezium_pattern.color({"A": player_color}, name="trapezium")
semicircle = semicircle_pattern.color({"A": player_color}, name="semicircle")
inverted_semicircle = inverted_semicircle_pattern.color(
    {"A": player_color},
    name="inverted_semicircle",
)
circle = circle_pattern.color({"A": player_color}, name="circle")


# Global tech-level symbols ---------------------------------------------------

t2_indicator = t2_indicator_pattern.color(
    {"A": white, "B": black},
    name="tech2",
)
t3_indicator = t3_indicator_pattern.color(
    {"A": white, "B": black},
    name="tech3",
)
diamond_t3_indicator = diamond_t3_indicator_pattern.color(
    {"A": white, "B": black},
    name="diamond_tech3",
)


# Reusable symbols ------------------------------------------------------------

generic_symbol = generic_symbol_pattern.color({}, name="generic")
directfire_symbol = directfire_symbol_pattern.color({"A": black}, name="directfire")
antiartillery_symbol = antiartillery_symbol_pattern.color(
    {"A": blue_cobalt_defense},
    name="antiartillery",
)
antinavy_symbol = antinavy_symbol_pattern.color({"A": cyan}, name="antinavy")
antishield_symbol = antishield_symbol_pattern.color({"A": magenta}, name="antishield")
air_symbol = air_symbol_pattern.color({"A": cyan}, name="air")
land_symbol = land_symbol_pattern.color({"A": green}, name="land")
naval_symbol = naval_symbol_pattern.color({"A": cyan}, name="naval")
transport_symbol = transport_symbol_pattern.color({"A": cyan_pale}, name="transport")
shield_symbol = shield_symbol_pattern.color({"A": blue_cobalt_defense}, name="shield",)
counterintel_symbol = counterintel_symbol_pattern.color(
    {"A": cyan},
    name="counterintel",
)
engineer_symbol = engineer_symbol_pattern.color({"A": green}, name="engineer")
bomb_symbol = bomb_symbol_pattern.color({"A": orange}, name="bomb")
wall_symbol = wall_symbol_pattern.color({"A": player_color}, name="wall")

antiair_symbol = antiair_symbol_pattern.color({"A": blue_light}, name="antiair")
antiair_symbol_outlined = antiair_symbol.outline(color=black, width=1)

pgen_symbol = pgen_symbol_pattern.color({"A": yellow}, name="pgen")
pgen_symbol_outlined = pgen_symbol.outline(color=black, width=1)

mex_symbol = mex_symbol_pattern.color({"A": green_neon}, name="mex")
mex_symbol_outlined = mex_symbol.outline(color=black, width=1)

intel_symbol = intel_symbol_pattern.color({"A": blue_electric}, name="intel")
intel_symbol_outlined = intel_symbol.outline(color=black, width=1)

missile_symbol = missile_symbol_pattern.color({"A": peach_bright}, name="missile")
missile_symbol_outlined = missile_symbol.outline(color=black, width=1)

sml_symbol = sml_symbol_pattern.color({"A": red_signal}, name="sml")
sml_symbol_outlined = sml_symbol.outline(color=black, width=1)

antimissile_symbol = antimissile_symbol_pattern.color({"A": indigo_bright},name="antimissile",)
antimissile_symbol_outlined = antimissile_symbol.outline(color=black, width=1)

artillery_symbol = artillery_symbol_pattern.color({"A": red_orange},name="artillery",)
artillery_symbol_outlined = artillery_symbol.outline(color=black, width=1)


# Reusable borders ------------------------------------------------------------

square_border_corner_yellow = square_border_corner_pattern.color({"A": black, "B": yellow, "C": black}, name="corners_yellow_border",)
squarebig_border_corners_yellow = squarebig_border_corners_pattern.color({"A": black, "B": pure_yellow, "C": black}, name="corners_blue_border",)
squarebig_border_corners_blue = squarebig_border_corners_pattern.color({"A": black, "B": blue_electric, "C": black}, name="corners_blue_border",)
squarebig_border_hazard_warning_yellow = squarebig_border_hazard_warning_pattern.color({"A": yellow, "B": black, "C": black}, name="hazard_warning_border",)
squarebig_border_hazard_warning_red = squarebig_border_hazard_warning_pattern.color({"A": red_bright, "B": black, "C": black}, name="hazard_warning_border",)
