#!/usr/bin/env python3
import base64
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "docs" / "store"
ICON = ROOT / "IPAKit/Sources/IPAResource/Assets/Media.xcassets/AppIcon/IPAIcon.imageset/IPAIcon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WIDTH, HEIGHT = 1320, 2868

STYLE = """
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 1320px; height: 2868px; overflow: hidden; }
body {
  background: #120e0c; color: #f0e6d2; position: relative;
  font-family: "SF Pro Rounded", "SF Pro Display", -apple-system, sans-serif;
}
.glow { position: absolute; inset: 0; }
.copy { position: absolute; left: 100px; right: 100px; text-align: center; }
.eyebrow {
  display: inline-flex; align-items: center; gap: 24px;
  font-size: 40px; font-weight: 700; letter-spacing: 8px; text-transform: uppercase; color: #e3b04b;
}
.eyebrow i { font-style: normal; font-size: 34px; color: #e38049; }
h1 { margin-top: 36px; font-size: 116px; line-height: 1.04; font-weight: 800; letter-spacing: -3px; color: #f7efe0; }
h1 em { font-style: normal; color: #e38049; }
.sub { margin: 40px auto 0; max-width: 1040px; font-size: 50px; line-height: 1.3; font-weight: 500; color: rgba(240, 230, 210, 0.7); }
.device {
  position: absolute; left: 50%; transform: translateX(-50%); top: 800px;
  width: 900px; height: 1956px; border-radius: 150px; padding: 22px;
  background: linear-gradient(150deg, #4a3d35, #17110e 35%, #2a211c 70%, #4a3d35);
  box-shadow: 0 0 0 3px #5a4a40, 0 90px 180px rgba(0, 0, 0, 0.65), 0 0 260px rgba(227, 128, 73, 0.28);
}
.screen { width: 100%; height: 100%; border-radius: 130px; overflow: hidden; position: relative; background: #000; }
.screen img { width: 100%; height: 100%; display: block; }
.island { position: absolute; top: 29px; left: 50%; transform: translateX(-50%); width: 266px; height: 78px; border-radius: 39px; background: #000; }
.icon { position: absolute; left: 50%; transform: translateX(-50%); top: 420px; width: 520px; height: 520px; filter: drop-shadow(0 60px 120px rgba(227, 128, 73, 0.6)); }
.icon img { width: 100%; height: 100%; }
.badges { position: absolute; left: 0; right: 0; top: 1820px; display: flex; flex-direction: column; align-items: center; gap: 32px; }
.badge {
  font-size: 48px; font-weight: 700; padding: 28px 60px; border-radius: 64px;
  background: rgba(240, 230, 210, 0.07); border: 2px solid rgba(240, 230, 210, 0.16);
}
.badge b { color: #e38049; font-weight: 800; }
.laurel { position: absolute; left: 0; right: 0; bottom: 190px; text-align: center; font-size: 38px; font-weight: 600; letter-spacing: 6px; text-transform: uppercase; color: rgba(240, 230, 210, 0.45); }
"""

GLOWS = {
    "device": "radial-gradient(1100px 1000px at 50% 70%, rgba(227,128,73,.5), transparent 70%),"
    "radial-gradient(900px 700px at 10% 5%, rgba(184,132,28,.22), transparent 70%),"
    "radial-gradient(900px 800px at 95% 100%, rgba(116,65,95,.4), transparent 70%)",
    "hero": "radial-gradient(1000px 900px at 50% 24%, rgba(227,128,73,.6), transparent 70%),"
    "radial-gradient(1000px 800px at 0% 100%, rgba(116,65,95,.35), transparent 70%),"
    "radial-gradient(900px 800px at 100% 70%, rgba(184,132,28,.2), transparent 70%)",
}


def image(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()


def copy(slide: dict, top: int) -> str:
    sub = f'<p class="sub">{slide["subtitle"]}</p>' if slide.get("subtitle") else ""
    return (
        f'<div class="copy" style="top:{top}px">'
        f'<div class="eyebrow"><i>✦</i>{slide["eyebrow"]}<i>✦</i></div>'
        f'<h1>{slide["title"]}</h1>{sub}</div>'
    )


def page(slide: dict, captures: Path) -> str:
    if slide.get("capture"):
        glow = GLOWS["device"]
        content = copy(slide, 150) + (
            f'<div class="device"><div class="screen"><img src="{image(captures / slide["capture"])}">'
            '<div class="island"></div></div></div>'
        )
    else:
        glow = GLOWS["hero"]
        badges = "".join(f'<div class="badge">{badge}</div>' for badge in slide["badges"])
        content = (
            f'<div class="icon"><img src="{image(ICON)}"></div>'
            + copy(slide, 1070)
            + f'<div class="badges">{badges}</div>'
            + (f'<div class="laurel">{slide["footer"]}</div>' if slide.get("footer") else "")
        )
    return (
        f'<!doctype html><html><head><meta charset="utf-8"><style>{STYLE}</style></head><body>'
        f'<div class="glow" style="background:{glow}"></div>{content}</body></html>'
    )


def render(html: str, output: Path) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as file:
        file.write(html)
    try:
        subprocess.run(
            [
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", f"--window-size={WIDTH},{HEIGHT}",
                f"--screenshot={output}", f"file://{file.name}",
            ],
            check=True, capture_output=True,
        )
    finally:
        Path(file.name).unlink()


def main() -> None:
    locale = sys.argv[1] if len(sys.argv) > 1 else "en-US"
    slides = json.loads((STORE / "screenshots.json").read_text())[locale]
    captures = STORE / "captures" / locale
    output = STORE / "screenshots" / locale
    output.mkdir(parents=True, exist_ok=True)
    medium = STORE / "screenshots" / f"{locale}-6.3"
    medium.mkdir(parents=True, exist_ok=True)
    for index, slide in enumerate(slides, start=1):
        target = output / f"{index:02d}-{slide['name']}.png"
        render(page(slide, captures), target)
        subprocess.run(
            ["sips", "-z", "2622", "1206", str(target), "--out", str(medium / target.name)],
            check=True, capture_output=True,
        )
        print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
