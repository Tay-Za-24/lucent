#!/usr/bin/env python3
"""Create Android launcher resources from the supplied, unchanged logo.png.

Run from the repository root: python3 tool/make_icon.py (requires Pillow).
The original artwork stays intact. Android copies only scale it proportionally
and add padding to fit the required square launcher canvases.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets/brand/logo.png'
RES = ROOT / 'android/app/src/main/res'


def write(relative_path, content):
    target = RES / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)


with Image.open(SOURCE) as original:
    artwork = original.convert('RGBA')
    background = artwork.getpixel((0, 0))

    def square(size, fill):
        canvas = Image.new('RGBA', (size, size), fill)
        scaled = artwork.copy()
        scaled.thumbnail((size, size), Image.Resampling.LANCZOS)
        canvas.alpha_composite(
            scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2)
        )
        return canvas

    for density, size in {
        'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192
    }.items():
        target = RES / f'mipmap-{density}/ic_launcher.png'
        target.parent.mkdir(parents=True, exist_ok=True)
        square(size, background).save(target)

    target = RES / 'drawable-nodpi/ic_launcher_artwork.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    square(1080, (0, 0, 0, 0)).save(target)
    background_hex = '#%02X%02X%02X' % background[:3]

write('drawable/ic_launcher_foreground.xml', '''<?xml version="1.0" encoding="utf-8"?>
<!-- Proportionally scaled original artwork; no tracing or recoloring. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:width="108dp" android:height="108dp" android:gravity="center">
        <bitmap android:src="@drawable/ic_launcher_artwork" android:gravity="fill" />
    </item>
</layer-list>
''')
write('values/ic_launcher_background.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{background_hex}</color>
</resources>
''')
write('mipmap-anydpi-v26/ic_launcher.xml', '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
''')
# A monochrome redraw would change the supplied artwork.
(RES / 'drawable/ic_launcher_monochrome.xml').unlink(missing_ok=True)
print('Android launcher resources generated from assets/brand/logo.png')
