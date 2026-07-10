from __future__ import annotations

from pathlib import Path
import struct

RGBA = tuple[int, int, int, int]
RGB = tuple[int, int, int]


def _pack_rgb565(pixel: RGBA) -> int:
    r, g, b, _ = pixel
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)


def _unpack_rgb565(value: int) -> RGB:
    r = (value >> 11) & 0x1F
    g = (value >> 5) & 0x3F
    b = value & 0x1F
    return (
        (r << 3) | (r >> 2),
        (g << 2) | (g >> 4),
        (b << 3) | (b >> 2),
    )


def _color_distance(a: RGB, b: RGB) -> int:
    return sum((a[i] - b[i]) ** 2 for i in range(3))


def _encode_dxt_color_block(block: list[RGBA]) -> bytes:
    opaque_colors = sorted({pixel[:3] for pixel in block if pixel[3] > 0})
    if not opaque_colors:
        return struct.pack("<HHI", 0, 0, 0)

    if len(opaque_colors) == 1:
        color0 = color1 = _pack_rgb565((*opaque_colors[0], 255))
    else:
        endpoint_a = opaque_colors[0]
        endpoint_b = opaque_colors[1]
        max_distance = -1
        for a in opaque_colors:
            for b in opaque_colors:
                distance = _color_distance(a, b)
                if distance > max_distance:
                    endpoint_a = a
                    endpoint_b = b
                    max_distance = distance

        color0 = _pack_rgb565((*endpoint_a, 255))
        color1 = _pack_rgb565((*endpoint_b, 255))
        if color0 <= color1:
            color0, color1 = color1, color0

    c0 = _unpack_rgb565(color0)
    c1 = _unpack_rgb565(color1)
    palette = [
        c0,
        c1,
        tuple((2 * c0[i] + c1[i]) // 3 for i in range(3)),
        tuple((c0[i] + 2 * c1[i]) // 3 for i in range(3)),
    ]

    indices = 0
    for i, pixel in enumerate(block):
        if pixel[3] == 0:
            index = 0
        else:
            rgb = pixel[:3]
            index = min(range(4), key=lambda candidate: _color_distance(rgb, palette[candidate]))
        indices |= index << (2 * i)

    return struct.pack("<HHI", color0, color1, indices)


def _encode_dxt5_alpha_block(block: list[RGBA]) -> bytes:
    alpha0 = max(pixel[3] for pixel in block)
    alpha1 = min(pixel[3] for pixel in block)
    if alpha0 == alpha1:
        alpha1 = 0 if alpha0 == 255 else 255

    if alpha0 > alpha1:
        palette = [
            alpha0,
            alpha1,
            (6 * alpha0 + alpha1) // 7,
            (5 * alpha0 + 2 * alpha1) // 7,
            (4 * alpha0 + 3 * alpha1) // 7,
            (3 * alpha0 + 4 * alpha1) // 7,
            (2 * alpha0 + 5 * alpha1) // 7,
            (alpha0 + 6 * alpha1) // 7,
        ]
    else:
        palette = [
            alpha0,
            alpha1,
            (4 * alpha0 + alpha1) // 5,
            (3 * alpha0 + 2 * alpha1) // 5,
            (2 * alpha0 + 3 * alpha1) // 5,
            (alpha0 + 4 * alpha1) // 5,
            0,
            255,
        ]

    indices = 0
    for i, pixel in enumerate(block):
        alpha = pixel[3]
        index = min(range(8), key=lambda candidate: abs(alpha - palette[candidate]))
        indices |= index << (3 * i)

    return bytes([alpha0, alpha1]) + indices.to_bytes(6, "little")


def save_dxt5_dds(
    output_file: str | Path,
    width: int,
    height: int,
    pixels: tuple[tuple[RGBA, ...], ...],
    transparent: RGBA = (0, 0, 0, 0),
) -> None:
    output_file = Path(output_file)
    block_width = (width + 3) // 4
    block_height = (height + 3) // 4
    linear_size = block_width * block_height * 16

    with open(output_file, "wb") as f:
        f.write(b"DDS ")
        f.write(struct.pack("<I", 124))
        f.write(struct.pack("<I", 0x00081007))
        f.write(struct.pack("<I", height))
        f.write(struct.pack("<I", width))
        f.write(struct.pack("<I", linear_size))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<11I", *([0] * 11)))
        f.write(struct.pack("<I", 32))
        f.write(struct.pack("<I", 0x00000004))
        f.write(b"DXT5")
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0x00001000))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))

        for block_y in range(block_height):
            for block_x in range(block_width):
                block = []
                for y in range(block_y * 4, block_y * 4 + 4):
                    for x in range(block_x * 4, block_x * 4 + 4):
                        if x < width and y < height:
                            block.append(pixels[y][x])
                        else:
                            block.append(transparent)
                f.write(_encode_dxt5_alpha_block(block))
                f.write(_encode_dxt_color_block(block))
