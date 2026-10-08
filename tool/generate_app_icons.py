"""Package assets/applogo.png for the app launchers. Requires ImageMagick 7.

Run from any directory: python3 tool/generate_app_icons.py
The selected artwork is preserved; only launcher sizes and masks are derived.
"""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/applogo.png"
MAGICK = shutil.which("magick")
if not MAGICK:
    raise SystemExit("Install ImageMagick 7 to regenerate launcher icons.")


def convert(*args):
    subprocess.run([MAGICK, *map(str, args)], check=True)


def resize(path, size):
    convert(SOURCE, "-resize", f"{size}x{size}!", "-alpha", "off", path)


# Adaptive icons have a 108dp canvas with a central 72dp launcher viewport.
# Put the complete selected artwork in that viewport and extend its edge colors
# into the motion margins. This retains the original background and silhouette.
# The artwork is in the background layer; a transparent foreground avoids a
# second emblem. A separate alpha mask supports Android's themed icons.
with tempfile.TemporaryDirectory(prefix="alcademy-icons-") as temporary:
    mask = Path(temporary) / "mark-mask.png"
    convert(
        SOURCE, "-colorspace", "sRGB", "-alpha", "off",
        "-fx", "max(0,min(1,(min(r,min(g,b))-0.78)/0.18))", mask,
    )
    for density, scale in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2,
                           "xxhdpi": 3, "xxxhdpi": 4}.items():
        folder = ROOT / f"android/app/src/main/res/mipmap-{density}"
        canvas = int(108 * scale)
        viewport = int(72 * scale)
        margin = (canvas - viewport) // 2
        resize(folder / "ic_launcher.png", int(48 * scale))
        convert(
            SOURCE, "-resize", f"{viewport}x{viewport}!",
            "-virtual-pixel", "edge", "-set", "option:distort:viewport",
            f"{canvas}x{canvas}-{margin}-{margin}", "-distort", "SRT", "0",
            "+repage", "-alpha", "off", folder / "ic_launcher_background.png",
        )
        convert(
            mask, "-fill", "white", "-colorize", "100", mask,
            "-compose", "CopyOpacity", "-composite",
            "-resize", f"{viewport}x{viewport}!", "-background", "none",
            "-gravity", "center", "-extent", f"{canvas}x{canvas}",
            folder / "ic_launcher_monochrome.png",
        )
        obsolete = folder / "ic_launcher_foreground.png"
        obsolete.unlink(missing_ok=True)

for platform in ("ios", "macos"):
    folder = ROOT / f"{platform}/Runner/Assets.xcassets/AppIcon.appiconset"
    manifest = json.loads((folder / "Contents.json").read_text())
    for item in manifest["images"]:
        if "filename" in item:
            size = round(float(item["size"].split("x")[0]) *
                         float(item["scale"].removesuffix("x")))
            resize(folder / item["filename"], size)

resize(ROOT / "web/favicon.png", 32)
for size in (192, 512):
    for name in (f"Icon-{size}.png", f"Icon-maskable-{size}.png"):
        resize(ROOT / "web/icons" / name, size)
convert(SOURCE, "-alpha", "off", "-define", "icon:auto-resize=256,128,64,48,32,16",
        ROOT / "windows/runner/resources/app_icon.ico")
print("Updated Android, iOS, macOS, Windows and web icons from assets/applogo.png.")
