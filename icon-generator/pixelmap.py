from math import ceil
from typing import Iterable, Literal
from dataclasses import dataclass
from colors import *
from dds import save_argb8888_dds, save_dxt5_dds
from PIL import Image
from pathlib import Path


@dataclass(frozen=True)
class PixelMap:
    width: int
    height: int
    pixels: tuple[tuple[tuple[int, int, int, int], ...], ...]
    name: str | None = None
    canvas_size: tuple[int, int] | None = None

    @classmethod
    def from_text(
        cls,
        pixels: str,
        colors: dict[str, str],
        *,
        transparent_tokens: Iterable[str] = ("X", ".", "_"),
        name: str | None = None,
    ) -> "PixelMap":
        rows = [
            [token.strip() for token in line.split()]
            for line in pixels.strip().splitlines()
            if line.strip()
        ]
        if not rows:
            raise ValueError("Pixel map cannot be empty")

        width = len(rows[0])
        if any(len(row) != width for row in rows):
            raise ValueError("All pixel-map rows must have the same width")

        transparent = set(transparent_tokens)
        palette = {key: hex_to_rgba(value) for key, value in colors.items()}
        parsed_rows = []
        for row in rows:
            parsed_row = []
            for token in row:
                if token in transparent:
                    parsed_row.append(TRANSPARENT)
                    continue
                if token not in palette:
                    raise ValueError(f"Token {token!r} is missing from the color map")
                parsed_row.append(palette[token])
            parsed_rows.append(tuple(parsed_row))

        return cls(width, len(parsed_rows), tuple(parsed_rows), name=name)

    @classmethod
    def fill(cls, width: int, height: int, color: str, *, name: str | None = None) -> "PixelMap":
        rgba = hex_to_rgba(color)
        return cls(width, height, tuple(tuple(rgba for _ in range(width)) for _ in range(height)), name=name)

    @classmethod
    def from_image(cls, filename: str | Path, *, name: str | None = None) -> "PixelMap":
        image = Image.open(filename).convert("RGBA")
        pixels = tuple(
            tuple(image.getpixel((x, y)) for x in range(image.width))
            for y in range(image.height)
        )
        if name is None:
            name = Path(filename).stem
        return cls(image.width, image.height, pixels, name=name)

    @classmethod
    def empty(cls, width: int, height: int) -> "PixelMap":
        return cls(
            width,
            height,
            tuple(tuple(TRANSPARENT for _ in range(width)) for _ in range(height)),
        )
    
    def crop_border(self, amount: int) -> "PixelMap":
        """
        Elimina una orilla de 'amount' píxeles en todos los lados de la imagen.

        Args:
            amount: Número de píxeles a eliminar de cada borde.
                    Debe ser >= 0 y menor que la mitad del ancho y alto.

        Returns:
            Una nueva PixelMap con las dimensiones reducidas.

        Raises:
            ValueError: Si amount es negativo o si el recorte resultante
                        tendría dimensión cero o negativa.
        """
        if amount < 0:
            raise ValueError("El valor de amount debe ser no negativo")
        if amount * 2 >= self.width or amount * 2 >= self.height:
            raise ValueError(
                f"amount={amount} es demasiado grande para una imagen de {self.width}x{self.height}"
            )

        new_width = self.width - 2 * amount
        new_height = self.height - 2 * amount

        # Extraer la región interior
        new_pixels = tuple(
            tuple(self.pixels[y][x] for x in range(amount, amount + new_width))
            for y in range(amount, amount + new_height)
        )

        # Conservar el nombre y el canvas_size (si existen)
        return PixelMap(
            new_width,
            new_height,
            new_pixels,
            name=self.name,
            canvas_size=self.canvas_size,
        )

    def outline(self, width: int, color: str, create_inwards: bool = False) -> "PixelMap":
        if width < 1:
            return self

        outline_color = hex_to_rgba(color)

        if create_inwards:
            # 1. Recortar la orilla (eliminar los bordes exteriores)
            inner = self.crop_border(width)  # Asegúrate de tener este método
            # 2. Expandir la imagen recortada con padding para que vuelva al tamaño original
            expanded = inner.pad(width)
            # 3. La máscara se construye a partir de la imagen recortada (desplazada por width)
            mask = {
                (x + width, y + width)
                for y, row in enumerate(inner.pixels)
                for x, pixel in enumerate(row)
                if pixel[3] > 0
            }
        else:
            # Caso normal: expandir la imagen original y usar su máscara
            expanded = self.pad(width)
            mask = {
                (x + width, y + width)
                for y, row in enumerate(self.pixels)
                for x, pixel in enumerate(row)
                if pixel[3] > 0
            }

        # Convertir a lista mutable para pintar
        outlined = [list(row) for row in expanded.pixels]

        # Dibujar el borde alrededor de la máscara
        for x, y in mask:
            for outline_y in range(y - width, y + width + 1):
                for outline_x in range(x - width, x + width + 1):
                    if (outline_x, outline_y) in mask:
                        continue
                    if not (0 <= outline_x < expanded.width and 0 <= outline_y < expanded.height):
                        continue
                    if outlined[outline_y][outline_x][3] == 0:
                        outlined[outline_y][outline_x] = outline_color

        return PixelMap(
            expanded.width,
            expanded.height,
            tuple(tuple(row) for row in outlined),
            name=self.name,
            canvas_size=self.canvas_size,
        )

    def pad(self, size: int) -> "PixelMap":
        padded = PixelMap.empty(self.width + size * 2, self.height + size * 2)
        return padded.combine_pixel_map(self, (size, size)).set_canvas_size(self.canvas_size)

    def set_canvas_size(self, canvas_size: tuple[int, int] | None) -> "PixelMap":
        return PixelMap(self.width, self.height, self.pixels, name=self.name, canvas_size=canvas_size)

    def fit_to(self, target_width: int | None = None, target_height: int | None = None) -> "PixelMap":
        """Return a PixelMap padded or cropped to exactly target dimensions.

        Uses the PixelMap canvas_size when no explicit dimensions are provided.
        Centers the image when padding or cropping.
        """
        if target_width is None and target_height is None:
            if self.canvas_size is None:
                return self
            target_width, target_height = self.canvas_size
        elif target_width is None or target_height is None:
            raise ValueError("Both target_width and target_height must be provided")

        if target_width == self.width and target_height == self.height:
            return self

        source_left = max(0, (self.width - target_width) // 2)
        source_top = max(0, (self.height - target_height) // 2)
        paste_x = max(0, (target_width - self.width) // 2)
        paste_y = max(0, (target_height - self.height) // 2)
        copy_width = min(self.width, target_width)
        copy_height = min(self.height, target_height)

        canvas = [list(row) for row in PixelMap.empty(target_width, target_height).pixels]
        for y in range(copy_height):
            for x in range(copy_width):
                canvas[paste_y + y][paste_x + x] = self.pixels[source_top + y][source_left + x]

        return PixelMap(target_width, target_height, tuple(tuple(row) for row in canvas), name=self.name, canvas_size=self.canvas_size)

    def erase_rect(self, x: int, y: int, width: int, height: int) -> "PixelMap":
        if width < 0 or height < 0:
            raise ValueError("Erase rectangle width and height must be positive")
        if not (0 <= x <= self.width and 0 <= y <= self.height):
            raise ValueError("Erase rectangle origin is outside the pixel map bounds")

        max_x = min(self.width, x + width)
        max_y = min(self.height, y + height)
        canvas = [list(row) for row in self.pixels]
        for erase_y in range(y, max_y):
            for erase_x in range(x, max_x):
                canvas[erase_y][erase_x] = TRANSPARENT
        return PixelMap(self.width, self.height, tuple(tuple(row) for row in canvas), name=self.name, canvas_size=self.canvas_size)

    def combine_pixel_map(
        self,
        pixel_map: "PixelMap",
        position: tuple[int, int] | str,
        offset: tuple[int, int] = (0, 0),
        zindex: int = 0,
        name: str | None = None,
    ) -> "PixelMap":
        if isinstance(position, str):
            if position == "center":
                position_x = (self.width - pixel_map.width) // 2
                position_y = (self.height - pixel_map.height) // 2
            elif position == "center-bottom":
                position_x = (self.width - pixel_map.width) // 2
                position_y = self.height
            else:
                raise ValueError(f"Unsupported position: {position}")
        else:
            position_x, position_y = position

        position_x += offset[0]
        position_y += offset[1]

        min_x = min(0, position_x)
        min_y = min(0, position_y)
        max_x = max(self.width, position_x + pixel_map.width)
        max_y = max(self.height, position_y + pixel_map.height)

        result = PixelMap.empty(max_x - min_x, max_y - min_y)
        canvas = [list(row) for row in result.pixels]

        def paste(source: "PixelMap", paste_x: int, paste_y: int) -> None:
            for y, row in enumerate(source.pixels):
                for x, pixel in enumerate(row):
                    if pixel[3] == 0:
                        continue
                    canvas[paste_y + y][paste_x + x] = pixel

        if zindex < 0:
            paste(pixel_map, position_x - min_x, position_y - min_y)
            paste(self, -min_x, -min_y)
        else:
            paste(self, -min_x, -min_y)
            paste(pixel_map, position_x - min_x, position_y - min_y)

        return PixelMap(result.width, result.height, tuple(tuple(row) for row in canvas), name=name or self.name, canvas_size=self.canvas_size)

    def replace_placeholder_in_the_name(self, placeholder: str, replacement: str) -> "PixelMap":
        if self.name is None:
            return self
        return PixelMap(
            self.width,
            self.height,
            self.pixels,
            name=self.name.replace(placeholder, replacement),
            canvas_size=self.canvas_size,
        )
    
    def add_suffix_to_the_name(self, suffix: str) -> "PixelMap":
        if self.name is None:
            return self
        return PixelMap(self.width, self.height, self.pixels, name=f"{self.name}{suffix}", canvas_size=self.canvas_size)

    def _to_image(self) -> Image.Image:
        image = Image.new("RGBA", (self.width, self.height), TRANSPARENT)
        image.putdata([pixel for row in self.pixels for pixel in row])
        return image

    def _resolve_output_file(
        self,
        filename: str | None,
        output_path: str | Path | None,
        suffix: str,
    ) -> Path:
        if self.name is not None and filename is None:
            filename = f"{self.name}{suffix}"
        elif filename is None:
            raise ValueError("Either filename or name must be provided")

        output_file = Path(filename)
        if output_file.suffix == "":
            output_file = output_file.with_suffix(suffix)

        if output_path is not None:
            output_path = Path(output_path)
            output_path.mkdir(parents=True, exist_ok=True)
            return output_path / output_file.name

        output_file.parent.mkdir(parents=True, exist_ok=True)
        return output_file

    def export(
        self,
        filename: str | None = None,
        output_path: str | Path | None = None,
        format: str = "DDS",
        compression: str = "DXT5",
    ) -> None:
        output_file = self._resolve_output_file(filename, output_path, ".dds")
        image = self._to_image()

        if format.upper() == "DDS":
            normalized_compression = compression.upper()
            if normalized_compression == "DXT5":
                save_dxt5_dds(output_file, self.width, self.height, self.pixels, TRANSPARENT)
            elif normalized_compression in {"ARGB8888", "NONE", "UNCOMPRESSED"}:
                save_argb8888_dds(output_file, self.width, self.height, self.pixels)
            else:
                raise ValueError(
                    f"Unsupported DDS compression {compression!r}; expected DXT5 or ARGB8888"
                )
        else:
            image.save(output_file, format=format)

    def generate_preview(
        self,
        filename: str | None = None,
        preview_path: str | Path | None = None,
        scale: int = 4,
    ) -> None:
        output_file = self._resolve_output_file(filename, preview_path, ".png")
        image = self._to_image()
        if scale != 1:
            image = image.resize((self.width * scale, self.height * scale), Image.Resampling.NEAREST)
        image.save(output_file)


def generate_previews(
    pixel_maps: list[PixelMap],
    preview_path: str | Path,
    *,
    scale: int = 4,
) -> None:
    for pixel_map in pixel_maps:
        pixel_map.generate_preview(preview_path=preview_path, scale=scale)


def generate_pixelmap_gallery(
    pixel_maps: list[PixelMap],
    *,
    columns: int,
    rows: int | None = None,
    arrange: Literal["left-to-right", "top-to-bottom"] = "left-to-right",
    horizontal_spacing: int = 1,
    vertical_spacing: int = 1,
    background_color: str | None = None,
    name: str = "pixelmap-gallery",
) -> PixelMap:
    """Arrange pixel maps in a row-first or column-first gallery."""
    if not pixel_maps:
        raise ValueError("Cannot generate a gallery without pixel maps")
    if columns < 1:
        raise ValueError("Gallery columns must be at least 1")
    if rows is not None and rows < 1:
        raise ValueError("Gallery rows must be at least 1")
    if horizontal_spacing < 0 or vertical_spacing < 0:
        raise ValueError("Gallery spacing cannot be negative")
    if arrange not in {"left-to-right", "top-to-bottom"}:
        raise ValueError(
            "Gallery arrange must be 'left-to-right' or 'top-to-bottom'"
        )

    gallery_rows = rows if rows is not None else ceil(len(pixel_maps) / columns)
    capacity = columns * gallery_rows
    if capacity < len(pixel_maps):
        raise ValueError(
            f"The gallery has space for {capacity} pixel maps, "
            f"but {len(pixel_maps)} were provided"
        )

    cell_width = max(pixel_map.width for pixel_map in pixel_maps)
    cell_height = max(pixel_map.height for pixel_map in pixel_maps)
    gallery_width = columns * cell_width + (columns - 1) * horizontal_spacing
    gallery_height = gallery_rows * cell_height + (gallery_rows - 1) * vertical_spacing
    gallery = (
        PixelMap.empty(gallery_width, gallery_height)
        if background_color is None
        else PixelMap.fill(gallery_width, gallery_height, background_color)
    )

    for index, pixel_map in enumerate(pixel_maps):
        if arrange == "left-to-right":
            row, column = divmod(index, columns)
        else:
            column, row = divmod(index, gallery_rows)
        cell_x = column * (cell_width + horizontal_spacing)
        cell_y = row * (cell_height + vertical_spacing)
        icon_x = cell_x + (cell_width - pixel_map.width) // 2
        icon_y = cell_y + (cell_height - pixel_map.height) // 2
        gallery = gallery.combine_pixel_map(pixel_map, (icon_x, icon_y))

    return PixelMap(
        gallery.width,
        gallery.height,
        gallery.pixels,
        name=name,
    )


def generate_pixelmap_preview_gallery(
    pixel_maps: list[PixelMap],
    filename: str | Path,
    *,
    columns: int,
    rows: int | None = None,
    arrange: Literal["left-to-right", "top-to-bottom"] = "left-to-right",
    horizontal_spacing: int = 1,
    vertical_spacing: int = 1,
    background_color: str | None = None,
    scale: int = 4,
) -> None:
    """Generate a PNG preview containing a grid of pixel maps."""
    gallery = generate_pixelmap_gallery(
        pixel_maps,
        columns=columns,
        rows=rows,
        arrange=arrange,
        horizontal_spacing=horizontal_spacing,
        vertical_spacing=vertical_spacing,
        background_color=background_color,
    )
    gallery.generate_preview(filename=str(filename), scale=scale)


def export_pixel_maps(
    pixel_maps: list[PixelMap],
    output_path: str | Path,
    *,
    compression: str = "DXT5",
) -> None:
    for pixel_map in pixel_maps:
        pixel_map.export(output_path=output_path, compression=compression)

def combine_pixel_maps(
    pixel_maps: list[PixelMap],
    position: tuple[int, int] | str = "center",
    offset: tuple[int, int] = (0, 0),
    name: str | None = None,
) -> PixelMap:
    if not pixel_maps:
        raise ValueError("Cannot combine an empty list of pixel maps")

    combined = pixel_maps[0]
    for pixel_map in pixel_maps[1:]:
        combined = combined.combine_pixel_map(pixel_map, position, offset=offset, zindex=1)

    return PixelMap(combined.width, combined.height, combined.pixels, name=name or combined.name, canvas_size=combined.canvas_size)
