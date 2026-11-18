#!/usr/bin/env python3
"""Generate the placeholder Zoix app icon.

The mark is an original letter Z on a gold circle. It is not copied from
another design. Replace the PNG this writes before a public App Store release.
"""

import math
import os
import struct
import zlib

SIZE = 1024
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Zoix",
    "Assets.xcassets",
    "AppIcon.appiconset",
    "AppIcon.png",
)


def dist_to_segment(px, py, ax, ay, bx, by):
    abx, aby = bx - ax, by - ay
    denom = abx * abx + aby * aby
    if denom == 0:
        t = 0.0
    else:
        t = ((px - ax) * abx + (py - ay) * aby) / denom
        t = max(0.0, min(1.0, t))
    cx, cy = ax + t * abx, ay + t * aby
    return math.hypot(px - cx, py - cy)


def on_z(px, py):
    # Bars overlap the diagonal so the letter reads as one stroke.
    if dist_to_segment(px, py, 390, 388, 634, 388) <= 40:
        return True
    if dist_to_segment(px, py, 390, 636, 634, 636) <= 40:
        return True
    if dist_to_segment(px, py, 628, 388, 396, 636) <= 36:
        return True
    return False


def pixel(x, y):
    bg = (18, 48, 62)
    gold = (232, 196, 122)
    ink = (18, 48, 62)
    circle = 0
    mark = 0
    for oy in (-0.25, 0.25):
        for ox in (-0.25, 0.25):
            px = x + ox + 0.5
            py = y + oy + 0.5
            dx, dy = px - 512, py - 512
            if dx * dx + dy * dy <= 312 * 312:
                circle += 1
                if on_z(px, py):
                    mark += 1
    c = circle / 4
    z = mark / 4
    r, g, b = bg
    r = r + (gold[0] - r) * c
    g = g + (gold[1] - g) * c
    b = b + (gold[2] - b) * c
    r = r + (ink[0] - r) * z
    g = g + (ink[1] - g) * z
    b = b + (ink[2] - b) * z
    return bytes((int(r + 0.5), int(g + 0.5), int(b + 0.5)))


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def main():
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)
        for x in range(SIZE):
            raw.extend(pixel(x, y))
    # Color type 2 is RGB with no alpha. App Store icons must not have an alpha channel.
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as handle:
        handle.write(png)
    print(f"wrote {OUT} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
