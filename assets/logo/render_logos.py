#!/usr/bin/env python3
"""
GlowAI Logo Rendering & Evaluation Script
Renders all 3 concepts at multiple sizes and masks, produces preview sheet.
"""
import subprocess, sys, os, math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ── Install deps ──────────────────────────────────────────────────────────────
def pip_install(*pkgs):
    for p in pkgs:
        try:
            __import__(p.replace('-','_').split('>=')[0])
        except ImportError:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-q', p])

pip_install('cairosvg', 'Pillow')
import cairosvg

ROOT    = Path(__file__).parent.parent.parent
CONCEPTS = ROOT / 'assets/logo/concepts'
ALTS     = ROOT / 'assets/logo/alternatives'
ICONS    = ROOT / 'assets/icon'
LOGO_DIR = ROOT / 'assets/logo'

for d in [CONCEPTS, ALTS, ICONS, LOGO_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Brand colors
PINK_START = (255, 141, 186)   # #FF8DBA
PINK_END   = (229, 72, 138)    # #E5488A
WHITE      = (255, 255, 255, 255)
BG_WHITE   = (255, 255, 255, 255)

CONCEPTS_LIST = [
    ('A', 'concept_a_scan_ring.svg',   'Scan Ring'),
    ('B', 'concept_b_g_monogram.svg',  'G Monogram'),
    ('C', 'concept_c_glow_drop.svg',   'Glow Drop'),
]
SIZES = [1024, 192, 96, 48, 32]


def make_gradient(size: int) -> Image.Image:
    """Pink gradient tile."""
    img = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            r = int(PINK_START[0] + (PINK_END[0] - PINK_START[0]) * t)
            g = int(PINK_START[1] + (PINK_END[1] - PINK_START[1]) * t)
            b = int(PINK_START[2] + (PINK_END[2] - PINK_START[2]) * t)
            draw.point((x, y), fill=(r, g, b, 255))
    return img


def make_squircle_mask(size: int, n: float = 4.0) -> Image.Image:
    """Superellipse (squircle) mask."""
    mask = Image.new('L', (size, size), 0)
    cx = cy = size / 2
    r = size * 0.46
    px = mask.load()
    for y in range(size):
        for x in range(size):
            dx = abs((x - cx) / r)
            dy = abs((y - cy) / r)
            if (dx**n + dy**n) <= 1.0:
                px[x, y] = 255
    return mask


def make_circle_mask(size: int) -> Image.Image:
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size-1, size-1], fill=255)
    return mask


def make_rounded_mask(size: int, radius_pct: float = 0.23) -> Image.Image:
    r = int(size * radius_pct)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=255)
    return mask


def svg_to_png(svg_path: Path, size: int) -> Image.Image:
    """Render SVG at given size using cairosvg."""
    png_bytes = cairosvg.svg2png(url=str(svg_path), output_width=size, output_height=size)
    from io import BytesIO
    return Image.open(BytesIO(png_bytes)).convert('RGBA')


def composite_on_gradient(symbol: Image.Image, size: int) -> Image.Image:
    """Place white symbol on gradient background."""
    bg = make_gradient(size)
    bg.paste(symbol, mask=symbol.split()[3])
    return bg


def apply_mask(img: Image.Image, mask: Image.Image) -> Image.Image:
    """Apply a mask to an image (white BG outside)."""
    white = Image.new('RGBA', img.size, (255, 255, 255, 255))
    out = Image.composite(img, white, mask)
    return out


def render_concept_row(letter: str, svg_path: Path, name: str, row_y: int, sheet: Image.Image, cell_w: int, pad: int):
    """Render one concept row on the preview sheet."""
    draw = ImageDraw.Draw(sheet)
    row_h = cell_w + pad * 2

    # Label
    draw.text((pad, row_y + row_h // 2 - 10), f'{letter}', fill=(40, 30, 50, 255))

    col_x = pad + 60
    sizes_to_show = [192, 96, 48, 32]

    for sz in sizes_to_show:
        symbol = svg_to_png(svg_path, sz)

        # 1. White symbol on gradient tile
        on_grad = composite_on_gradient(symbol, sz)
        # 2. Pink symbol on white bg
        pink_sym = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
        r, g, b = 247, 111, 165   # #F76FA5
        for px_x in range(sz):
            for px_y in range(sz):
                alpha = symbol.getpixel((px_x, px_y))[3]
                if alpha > 0:
                    pink_sym.putpixel((px_x, px_y), (r, g, b, alpha))
        on_white_pink = Image.new('RGBA', (sz, sz), (255, 255, 255, 255))
        on_white_pink.paste(pink_sym, mask=pink_sym.split()[3])

        # 3. Circle mask on gradient
        circ = on_grad.copy()
        circ_mask = make_circle_mask(sz)
        circ = apply_mask(circ, circ_mask)

        # 4. Squircle mask on gradient
        sq = on_grad.copy()
        sq_mask = make_squircle_mask(sz)
        sq = apply_mask(sq, sq_mask)

        # 5. Rounded-rect mask on gradient
        rr = on_grad.copy()
        rr_mask = make_rounded_mask(sz)
        rr = apply_mask(rr, rr_mask)

        variants = [on_grad, on_white_pink, circ, sq, rr]
        for vi, variant in enumerate(variants):
            # Scale variant to cell_w for display
            display = variant.resize((cell_w, cell_w), Image.LANCZOS)
            x = col_x + vi * (cell_w + pad)
            y = row_y + (row_h - cell_w) // 2
            # Paste on white background area
            white_cell = Image.new('RGBA', (cell_w, cell_w), (245, 244, 248, 255))
            white_cell.paste(display, mask=display.split()[3] if display.mode == 'RGBA' else None)
            # Actually composite properly
            sheet_rgba = sheet.convert('RGBA')
            sheet_rgba.paste(display.convert('RGBA'), (x, y))
            sheet.paste(sheet_rgba.convert('RGB'), (0, 0))

        col_x += len(variants) * (cell_w + pad) + pad * 2


def build_preview_sheet():
    """Build the full comparison preview sheet."""
    cell = 80
    pad  = 12
    n_variants = 5
    n_sizes    = 4
    label_w    = 60
    cols       = label_w + n_variants * (cell + pad) + pad
    row_h      = cell + pad * 2
    rows       = len(CONCEPTS_LIST)
    header_h   = 40
    total_w    = cols + 20
    total_h    = header_h + rows * row_h + 20

    sheet = Image.new('RGB', (total_w, total_h), (250, 248, 252))
    draw  = ImageDraw.Draw(sheet)

    # Header labels
    headers = ['On Gradient', 'Pink on White', 'Circle', 'Squircle', 'Rounded Sq']
    x = pad + label_w
    for h in headers:
        draw.text((x + 5, 12), h[:12], fill=(100, 90, 110))
        x += cell + pad

    y = header_h
    for letter, fname, name in CONCEPTS_LIST:
        svg_path = CONCEPTS / fname
        if not svg_path.exists():
            print(f"  SKIP {svg_path} (not found)")
            y += row_h
            continue

        draw.text((pad, y + row_h//2 - 8), f'{letter}: {name}', fill=(40, 30, 50))

        col_x = pad + label_w
        sizes_to_show = [192, 96, 48, 32]

        # Use 96px representative rendering per concept row
        sz = 96
        symbol = svg_to_png(svg_path, sz)
        on_grad = composite_on_gradient(symbol, sz)

        # Pink symbol
        pink_sym = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
        for px_x in range(sz):
            for px_y in range(sz):
                alpha = symbol.getpixel((px_x, px_y))[3]
                if alpha > 0:
                    pink_sym.putpixel((px_x, px_y), (247, 111, 165, alpha))
        on_white_pink = Image.new('RGBA', (sz, sz), (255, 255, 255, 255))
        on_white_pink.paste(pink_sym, mask=pink_sym.split()[3])

        circ = apply_mask(on_grad.copy(), make_circle_mask(sz))
        sq   = apply_mask(on_grad.copy(), make_squircle_mask(sz))
        rr   = apply_mask(on_grad.copy(), make_rounded_mask(sz))

        variants = [on_grad, on_white_pink, circ, sq, rr]
        for vi, variant in enumerate(variants):
            display = variant.resize((cell, cell), Image.LANCZOS)
            paste_x = col_x + vi * (cell + pad)
            paste_y = y + pad
            if display.mode == 'RGBA':
                bg = Image.new('RGB', (cell, cell), (250, 248, 252))
                bg.paste(display, mask=display.split()[3])
                display = bg
            sheet.paste(display, (paste_x, paste_y))

        y += row_h

    sheet_path = LOGO_DIR / 'preview_sheet.png'
    sheet.save(str(sheet_path))
    print(f'✓ Preview sheet saved: {sheet_path}')
    return sheet_path


def make_final_assets(chosen_svg: Path):
    """Generate all final production assets from the chosen SVG."""
    print(f'\n── Generating final assets from {chosen_svg.name} ──')

    # 1. icon_foreground.png — white symbol on transparent, in 66% safe zone
    print('  icon_foreground.png...')
    sym_size = int(1024 * 0.66)  # 676px
    symbol = svg_to_png(chosen_svg, sym_size)
    foreground = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    offset = (1024 - sym_size) // 2
    foreground.paste(symbol, (offset, offset), mask=symbol.split()[3])
    foreground.save(str(ICONS / 'icon_foreground.png'))

    # 2. icon_background.png — 1024x1024 pink gradient, no transparency
    print('  icon_background.png...')
    bg = make_gradient(1024).convert('RGB')
    bg.save(str(ICONS / 'icon_background.png'))

    # 3. icon_monochrome.png — same as foreground (single-color, transparent bg)
    print('  icon_monochrome.png...')
    # For Android 13+ themed icons: use the same white symbol on transparent
    foreground.save(str(ICONS / 'icon_monochrome.png'))

    # 4. icon_ios.png — full-bleed square (gradient + symbol), no transparency, no rounded corners
    print('  icon_ios.png...')
    ios_bg = make_gradient(1024)
    ios_sym = svg_to_png(chosen_svg, sym_size)
    ios_bg.paste(ios_sym, (offset, offset), mask=ios_sym.split()[3])
    ios_bg.convert('RGB').save(str(ICONS / 'icon_ios.png'))

    # 5. splash_logo.png — symbol on white bg, fits in 2/3 of 960x960 circle
    #    Safe symbol size: 960 * 0.66 ≈ 634px
    print('  splash_logo.png...')
    splash_sym_size = int(960 * 0.62)  # 595px - fits inside circle with margin
    splash_sym = svg_to_png(chosen_svg, splash_sym_size)
    # Colorize to pink for splash (white bg, pink symbol)
    pink_splash = Image.new('RGBA', (splash_sym_size, splash_sym_size), (0, 0, 0, 0))
    for px_x in range(splash_sym_size):
        for px_y in range(splash_sym_size):
            alpha = splash_sym.getpixel((px_x, px_y))[3]
            if alpha > 0:
                pink_splash.putpixel((px_x, px_y), (247, 111, 165, alpha))
    splash_canvas = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    soff = (1024 - splash_sym_size) // 2
    splash_canvas.paste(pink_splash, (soff, soff), mask=pink_splash.split()[3])
    splash_canvas.save(str(ICONS / 'splash_logo.png'))

    # 6. Master source: copy chosen SVG as glowai_mark.svg
    print('  glowai_mark.svg...')
    import shutil
    shutil.copy(str(chosen_svg), str(LOGO_DIR / 'glowai_mark.svg'))

    print('  ✓ All final assets generated')


def main():
    print('=== GlowAI Logo Rendering Pipeline ===\n')
    print('Step 1: Verify SVGs...')
    for letter, fname, name in CONCEPTS_LIST:
        p = CONCEPTS / fname
        print(f'  {letter}: {"✓" if p.exists() else "✗ MISSING"} {fname}')

    print('\nStep 2: Build preview sheet...')
    sheet_path = build_preview_sheet()

    # Concept B chosen: G Monogram
    # Rationale:
    # - Readable at 32px: the G shape is universally recognised at tiny size
    # - Distinctive: monogram + spark is specific to GlowAI, not generic AI icon
    # - Simple: two geometric pieces (arc + bar) + micro-accent
    chosen_letter = 'B'
    chosen_svg    = CONCEPTS / 'concept_b_g_monogram.svg'

    print(f'\nStep 3: Generate production assets from Concept {chosen_letter}...')
    make_final_assets(chosen_svg)

    # Move alternates
    import shutil
    for letter, fname, name in CONCEPTS_LIST:
        if letter != chosen_letter:
            src = CONCEPTS / fname
            dst = ALTS / fname
            if src.exists():
                shutil.copy(str(src), str(dst))

    print(f'\n✓ Done! Preview: {sheet_path}')
    print('\nCONCEPT CHOICE: B — G Monogram')
    print('  1. Most legible at 32–48px: bold closed arc instantly reads as "G"')
    print('  2. Distinctive: the spark accent on the bar-end is unique to GlowAI, not a generic AI sparkle')
    print('  3. Scalable: two weights (arc + bar) are perfectly balanced; no thin lines at any size')


if __name__ == '__main__':
    main()
