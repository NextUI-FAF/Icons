from pixelmap import PixelPattern


# Icon geometry ---------------------------------------------------------------

square_pattern = PixelPattern.fill(9, 9)

square_big_pattern = PixelPattern.fill(11, 11)

rectangle_pattern = PixelPattern.fill(13, 7)

hexagon_pattern = PixelPattern.from_text(
    """X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       A A A A A A A A A A A
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X""",
)

diamond_pattern = PixelPattern.from_text(
    """X X X X A X X X X
       X X X A A A X X X
       X X A A A A A X X
       X A A A A A A A X
       A A A A A A A A A
       X A A A A A A A X
       X X A A A A A X X
       X X X A A A X X X
       X X X X A X X X X""",
)

triangle_pattern = PixelPattern.from_text(
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
)

wide_triangle_pattern = PixelPattern.from_text(
    """X X X X X X A X X X X X X
       X X X X X A A A X X X X X
       X X X X A A A A A X X X X
       X X X A A A A A A A X X X
       X X A A A A A A A A A X X
       X A A A A A A A A A A A X
       A A A A A A A A A A A A A""",
)

trapezium_pattern = PixelPattern.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X A A A A A A A X X""",
)

semicircle_pattern = PixelPattern.from_text(
    """X X X X X A X X X X X
       X X X A A A A A X X X
       X X A A A A A A A X X
       X A A A A A A A A A X
       X A A A A A A A A A X
       A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A""",
)

inverted_semicircle_pattern = PixelPattern.from_text(
    """A A A A A A A A A A A
       A A A A A A A A A A A
       A A A A A A A A A A A
       X A A A A A A A A A X
       X A A A A A A A A A X
       X X A A A A A A A X X
       X X X A A A A A X X X
       X X X X X A X X X X X""",
)

circle_pattern = PixelPattern.from_text(
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
)


# Global tech-level symbols ---------------------------------------------------

t2_indicator_pattern = PixelPattern.from_text(
    """X B B B B B X
       X B A B A B X
       X B A B A B X
       X B B B B B X""",
)

t3_indicator_pattern = PixelPattern.from_text(
    """B B B B B B B
       B A B A B A B
       B A B A B A B
       B B B B B B B""",
)

diamond_t3_indicator_pattern = PixelPattern.from_text(
    """B X X X X X B
       B A X X X A B
       B A B X B A B
       B A B A B A B
       B B B B B B B""",
)


# Reusable symbols ------------------------------------------------------------

generic_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X X X X
       X X X X X
       X X X X X
       X X X X X""",
)

directfire_symbol_pattern = PixelPattern.from_text(
    """X X A X X
       X X A X X
       A A X A A
       X X A X X
       X X A X X""",
)



antiartillery_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A X A X
       X X A X X
       X X X X X""",
)

antinavy_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       A A A A A
       X X X X X
       X X A X X
       X X A X X""",
)

antishield_symbol_pattern = PixelPattern.from_text(
    """X X A X A X X
       X X X X X X X
       X A X X X A X
       A A X X X A A""",
)

air_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A X A X
       A X X X A
       X X X X X""",
)

land_symbol_pattern = PixelPattern.from_text(
    """X X A X X
       X A X A X
       A X X X A
       X A X A X
       X X A X X""",
)

naval_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X X X X
       X X X X X
       A X X X A
       X A A A X""",
)

transport_symbol_pattern = PixelPattern.from_text(
    """A A A A A
       A X X X A
       A X X X A
       X X A X X
       X X A X X""",
)

shield_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X A A A X
       A X X X A
       A X X X A
       A X X X A""",
)

counterintel_symbol_pattern = PixelPattern.from_text(
    """A X A X A
       X X X X X
       X A X A X
       X X X X X
       X X A X X""",
)

engineer_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       A A A A A
       X X A X X
       X X A X X
       X X X X X""",
)

bomb_symbol_pattern = PixelPattern.from_text(
    """A X X X A
       X A X A X
       X X X X X
       X A X A X
       A X X X A""",
)

wall_symbol_pattern = PixelPattern.from_text(
    """A A A A A
       A X A X A
       A A A A A
       A X A X A
       A A A A A""",
)

antiair_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A A A X
       A A X A A
       A X X X A""",
)

pgen_symbol_pattern = PixelPattern.from_text(
    """X A X X X
       X X A X X
       X A A A X
       X X A X X
       X X X A X""",
)

mex_symbol_pattern = PixelPattern.from_text(
    """X A A A X
       A X X X A
       A A X A A
       X X X X X
       X X A X X""",
)

intel_symbol_pattern = PixelPattern.from_text(
    """A A A A A
       X X X X X
       X A A A X
       X X X X X
       X X A X X""",
)

missile_symbol_pattern = PixelPattern.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
)

sml_symbol_pattern = PixelPattern.from_text(
    """X X A X X
       X X A X X
       X X A X X
       X X A X X
       X X A X X""",
)

antimissile_symbol_pattern = PixelPattern.from_text(
    """X X A X X
       X X X X X
       X X A X X
       X X X X X
       X X A X X""",
)

artillery_symbol_pattern = PixelPattern.from_text(
    """X X X X X
       X X A X X
       X A A A X
       X X A X X
       X X X X X""",
)

# Reusable borders ------------------------------------------------------------

square_border_corner_pattern = PixelPattern.from_text(
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
)

squarebig_border_corners_pattern = PixelPattern.from_text(
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
)

squarebig_border_hazard_warning_pattern = PixelPattern.from_text(
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
)
