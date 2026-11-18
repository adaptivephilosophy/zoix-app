#!/usr/bin/env python3
"""Build the Zoix app icon from the foundation logo.

Source image: scripts/brand/adaptive-philosophy-logo.png
That file is https://zoix.ai/25341.png (the Adaptive Philosophy logo).

The wordmark is not drawn. The icon keeps the central tree above the
wordmark, on the logo's navy field, and maps the painted branches onto
two logo colors:

- navy  #06182C  logo pixel (507, 99), the field
- cyan  #1BBCE3  logo pixel (328, 460), bright branch sample
- ivory #FDFDCE  logo pixel (478, 509), wordmark sample, used for the warm cores

The PNG is 1024x1024 RGB with no alpha. App Store icons cannot be transparent.
"""

import os
import struct
import zlib

SIZE = 1024
# Square crop of the central tree. The wordmark begins just below y=436.
CROP = (342, 96, 682, 436)
MARK = 880

NAVY = (6, 24, 44)
CYAN = (27, 188, 227)
IVORY = (253, 253, 206)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "scripts", "brand", "adaptive-philosophy-logo.png")
OUT = os.path.join(ROOT, "Zoix", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_rgba(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path} is not a PNG")
    pos = 8
    width = height = None
    idat = b""
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
            if (width, height, bit_depth, color_type, interlace) != (1024, 1024, 8, 6, 0):
                raise SystemExit("logo must be a non-interlaced 1024x1024 8-bit RGBA PNG")
        elif kind == b"IDAT":
            idat += chunk
        elif kind == b"IEND":
            break
    raw = zlib.decompress(idat)
    stride = width * 4
    rows = []
    index = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[index]
        index += 1
        row = bytearray(raw[index : index + stride])
        index += stride
        if filter_type == 1:
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                row[x] = (row[x] + left) & 255
        elif filter_type == 2:
            for x in range(stride):
                row[x] = (row[x] + previous[x]) & 255
        elif filter_type == 3:
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                row[x] = (row[x] + ((left + previous[x]) // 2)) & 255
        elif filter_type == 4:
            for x in range(stride):
                left = row[x - 4] if x >= 4 else 0
                up = previous[x]
                up_left = previous[x - 4] if x >= 4 else 0
                row[x] = (row[x] + paeth(left, up, up_left)) & 255
        elif filter_type != 0:
            raise SystemExit(f"unsupported PNG filter {filter_type}")
        rows.append(row)
        previous = row
    return width, height, rows


def lum(r, g, b):
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def mix(a, b, t):
    if t < 0:
        t = 0.0
    elif t > 1:
        t = 1.0
    return tuple(int(a[i] + (b[i] - a[i]) * t + 0.5) for i in range(3))


def recolor(r, g, b, a):
    """Map a logo pixel onto navy, cyan, and ivory. No other hues."""
    if a < 20:
        return NAVY
    light = lum(r, g, b)
    if light < 32:
        return NAVY
    warm = r > b + 25 and r > 90 and r >= g - 10
    if warm:
        return mix(NAVY, IVORY, min(1.0, (light - 32) / 170))
    peak = max(r, g, b)
    chroma = 0 if peak == 0 else (peak - min(r, g, b)) / peak
    if light > 210 and chroma < 0.25:
        return mix(CYAN, IVORY, min(1.0, (light - 180) / 70))
    return mix(NAVY, CYAN, min(1.0, (light - 32) / 150))


def sample(rows, x, y, width, height):
    x = 0 if x < 0 else width - 1 if x >= width else x
    y = 0 if y < 0 else height - 1 if y >= height else y
    i = x * 4
    row = rows[y]
    return row[i], row[i + 1], row[i + 2], row[i + 3]


def icon_pixels(rows):
    left, top, right, bottom = CROP
    crop_w = right - left
    crop_h = bottom - top
    origin = (SIZE - MARK) // 2
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            if not (origin <= x < origin + MARK and origin <= y < origin + MARK):
                row.append(NAVY)
                continue
            fx = left + (x - origin + 0.5) * crop_w / MARK - 0.5
            fy = top + (y - origin + 0.5) * crop_h / MARK - 0.5
            x0, y0 = int(fx), int(fy)
            tx, ty = fx - x0, fy - y0
            c00 = recolor(*sample(rows, x0, y0, 1024, 1024))
            c10 = recolor(*sample(rows, x0 + 1, y0, 1024, 1024))
            c01 = recolor(*sample(rows, x0, y0 + 1, 1024, 1024))
            c11 = recolor(*sample(rows, x0 + 1, y0 + 1, 1024, 1024))
            color = []
            for channel in range(3):
                top_edge = c00[channel] * (1 - tx) + c10[channel] * tx
                bottom_edge = c01[channel] * (1 - tx) + c11[channel] * tx
                color.append(int(top_edge * (1 - ty) + bottom_edge * ty + 0.5))
            row.append(tuple(color))
        pixels.append(row)
    return pixels


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_rgb(path, pixels):
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b in row:
            raw.extend((r, g, b))
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(png)
    print(f"wrote {path} ({len(png)} bytes)")


def main():
    if not os.path.exists(SOURCE):
        raise SystemExit(f"missing logo: {SOURCE}")
    _, _, rows = read_rgba(SOURCE)
    write_rgb(OUT, icon_pixels(rows))


if __name__ == "__main__":
    main()
