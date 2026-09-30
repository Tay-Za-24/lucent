#!/usr/bin/env python3
"""Generates the Lucent logo, launcher icons and macOS app icon from one geometry.

Run from the repo root:  python3 tool/make_icon.py
Needs rsvg-convert (librsvg2-bin). Writes assets/brand/*, the Android res files,
and (when the macos/ folder exists) the macOS AppIcon.appiconset.

The crystal is a hand trace of the silver faceted gem artwork (hexagon with an
inner diamond cut-out). Points are in the artwork's own pixel space (about
500x440) and are placed into each target with a translate/scale.
"""
import json
import os
import subprocess

# Traced vertices (artwork pixels). Symmetric around x=253.
P = dict(
    T=(253, 20), UR=(385, 157), LR=(385, 316), B=(253, 400), LL=(121, 316), UL=(121, 157),
    M=(253, 124),            # top of the inner diamond
    L=(173, 205), R=(333, 205),  # side points of the inner diamond
    FL=(211, 300), FC=(253, 312), FR=(295, 300),  # "floor" seen through the cut-out
)
CX, CY = 253, 210            # visual centre of the crystal
OUTLINE = 'T UR LR B LL UL'
# (points, fill). Pale silver facets, lit from the top left.
FACETS = [
    ('T UL L', '#F6F7F9'),
    ('T L M', '#FCFCFD'),
    ('T M R', '#ECEFF3'),
    ('T R UR', '#E3E7EC'),
    ('UL L LL', '#EEF0F3'),
    ('UR R LR', '#E1E5EA'),
    ('LL L FL B', '#E2E6EA'),
    ('LL FL B', '#F2F4F6'),
    ('LR R FR B', '#EDF0F3'),
    ('LR FR B', '#F7F8F9'),
    ('FL FC B', '#E4E8EC'),     # floor, left half
    ('FC FR B', '#EDF0F3'),     # floor, right half
]
# Inner lines (the outline is drawn separately, a little heavier).
LINES = ['T L', 'T M', 'T R', 'M L', 'M R', 'UL L', 'UR R', 'L LL', 'R LR', 'L B', 'R B']
STROKE = '#B7BDC5'           # silver
STROKE_HI = '#D3D8DE'        # lighter silver at the top of the gradient
STROKE_LO = '#A3AAB3'
OUTER_W, INNER_W = 11, 8.5   # a touch heavier than the artwork so it holds at 48 px

BG = '#0E0E12'               # near-black "obsidian" tile
BG_HI = '#1C1C24'            # subtle top highlight on rendered tiles

# Monochrome layer (themed icons): facet opacity by lightness, lines cut out.
MONO_ALPHA = {'#FCFCFD': 1.0, '#F7F8F9': 0.95, '#F6F7F9': 0.95, '#F2F4F6': 0.9,
              '#EEF0F3': 0.8, '#EDF0F3': 0.8, '#ECEFF3': 0.8, '#E4E8EC': 0.65,
              '#E3E7EC': 0.7, '#E2E6EA': 0.65, '#E1E5EA': 0.65}


def pts(names):
    return [P[n] for n in names.split()]


def svg_points(names):
    return ' '.join(f'{x},{y}' for x, y in pts(names))


def path_data(names, close=True):
    p = pts(names)
    return 'M' + ' L'.join(f'{x},{y}' for x, y in p) + (' Z' if close else '')


def transform(size_units, height_units, cx, cy):
    """translate/scale that puts the crystal (height incl. stroke) centred at cx,cy."""
    s = height_units / (P['B'][1] - P['T'][1] + OUTER_W)
    return s, cx - CX * s, cy - CY * s


def crystal_svg(s, tx, ty, flat=False):
    """SVG group for the crystal. flat=True avoids gradients (tiny sizes)."""
    stroke = STROKE if flat else 'url(#silver)'
    out = [f'<g transform="translate({tx:.3f},{ty:.3f}) scale({s:.5f})">']
    for names, col in FACETS:
        out.append(f'  <polygon points="{svg_points(names)}" fill="{col}"/>')
    # cut-out stays open: the tile shows through the inner diamond
    out.append(f'  <polygon points="{svg_points("M R FR FC FL L")}" fill="{BG}" fill-opacity="0"/>')
    d = ' '.join(path_data(l, close=False) for l in LINES)
    out.append(f'  <path d="{d}" fill="none" stroke="{stroke}" stroke-width="{INNER_W}" '
               'stroke-linecap="round" stroke-linejoin="round"/>')
    out.append(f'  <polygon points="{svg_points(OUTLINE)}" fill="none" stroke="{stroke}" '
               f'stroke-width="{OUTER_W}" stroke-linejoin="round"/>')
    out.append('</g>')
    return '\n  '.join(out)


DEFS = f'''<defs>
    <linearGradient id="silver" gradientUnits="userSpaceOnUse" x1="0" y1="{P['T'][1]}" x2="0" y2="{P['B'][1]}">
      <stop offset="0" stop-color="{STROKE_HI}"/>
      <stop offset="0.55" stop-color="{STROKE}"/>
      <stop offset="1" stop-color="{STROKE_LO}"/>
    </linearGradient>
    <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{BG_HI}"/>
      <stop offset="1" stop-color="{BG}"/>
    </linearGradient>
  </defs>'''


def write(path, text):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w') as f:
        f.write(text)


def render(svg, png, size):
    os.makedirs(os.path.dirname(png), exist_ok=True)
    subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size), svg, '-o', png], check=True)


def tile_svg(px, crystal_h, radius, inset=0):
    """Square icon: rounded dark tile (inset from the canvas edge) with the crystal."""
    side = px - 2 * inset
    s, tx, ty = transform(px, crystal_h, px / 2, px / 2)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" viewBox="0 0 {px} {px}">
  {DEFS}
  <rect x="{inset}" y="{inset}" width="{side}" height="{side}" rx="{radius}" fill="url(#tile)"/>
  {crystal_svg(s, tx, ty)}
</svg>
'''


# 1) Logo tile (in-app and legacy launcher icon): 1024 canvas, crystal 70% tall.
write('assets/brand/logo.svg', tile_svg(1024, 716, 228))
render('assets/brand/logo.svg', 'assets/brand/logo-1024.png', 1024)
render('assets/brand/logo.svg', 'assets/brand/logo-256.png', 256)

# 2) Crystal alone on transparent (reference, previews).
s, tx, ty = transform(1024, 1000, 512, 512)
write('assets/brand/crystal.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  {DEFS}
  {crystal_svg(s, tx, ty)}
</svg>
''')
render('assets/brand/crystal.svg', 'assets/brand/crystal-1024.png', 1024)

res = 'android/app/src/main/res'
for d, px in dict(mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192).items():
    render('assets/brand/logo.svg', f'{res}/mipmap-{d}/ic_launcher.png', px)

# 3) Adaptive icon: 108dp grid, safe zone r=33. Crystal 56 units tall.
s, tx, ty = transform(108, 56, 54, 54)


def vector(body, comment):
    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- {comment} Generated by tool/make_icon.py. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group android:translateX="{tx:.3f}" android:translateY="{ty:.3f}"
        android:scaleX="{s:.5f}" android:scaleY="{s:.5f}">
{body}
    </group>
</vector>
'''


lines_d = ' '.join(path_data(l, close=False) for l in LINES)
fg = [f'        <path android:fillColor="{c}" android:pathData="{path_data(n)}" />' for n, c in FACETS]
fg.append(f'        <path android:strokeColor="{STROKE}" android:strokeWidth="{INNER_W}" '
          f'android:strokeLineCap="round" android:strokeLineJoin="round" android:pathData="{lines_d}" />')
fg.append(f'        <path android:strokeColor="{STROKE}" android:strokeWidth="{OUTER_W}" '
          f'android:strokeLineJoin="round" android:pathData="{path_data(OUTLINE)}" />')
mono = [f'        <path android:fillColor="#FFFFFF" android:fillAlpha="{MONO_ALPHA[c]}" '
        f'android:pathData="{path_data(n)}" />' for n, c in FACETS if not n.startswith('F')]
mono.append(f'        <path android:strokeColor="#FFFFFF" android:strokeWidth="{OUTER_W}" '
            f'android:strokeLineJoin="round" android:pathData="{path_data(OUTLINE)}" />')
write(f'{res}/drawable/ic_launcher_foreground.xml',
      vector('\n'.join(fg), 'Lucent silver crystal inside the adaptive safe zone.'))
write(f'{res}/drawable/ic_launcher_monochrome.xml',
      vector('\n'.join(mono), 'Single-colour crystal for themed icons (facets by opacity).'))
write(f'{res}/values/ic_launcher_background.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{BG}</color>
</resources>
''')
write(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
''')

# Adaptive foreground as SVG for previews (full 108 grid, transparent).
write('build/icon/foreground.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">
  {DEFS}
  {crystal_svg(s, tx, ty)}
</svg>
''')
render('build/icon/foreground.svg', 'build/icon/foreground.png', 1080)

# 4) macOS app icon (Big Sur grid: 824 tile inset 100 on a 1024 canvas).
mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
if os.path.isdir(mac):
    write('build/icon/macos.svg', tile_svg(1024, 590, 185, inset=100))
    for px in (16, 32, 64, 128, 256, 512, 1024):
        render('build/icon/macos.svg', f'{mac}/app_icon_{px}.png', px)
print('ok')
