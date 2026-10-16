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

PROFILES = {
    "iphone": {
        "size": (1320, 2868), "title": 116, "sub": 50, "eyebrow": 40, "copy": 150, "hero_copy": 1070,
        "device": (900, 1956, 800, 150, 22, 130), "island": True, "icon": (520, 420), "badges": 1820,
        "resize": ("-6.3", 1206, 2622),
    },
    "ipad": {
        "size": (2064, 2752), "title": 130, "sub": 56, "eyebrow": 44, "copy": 150, "hero_copy": 1060,
        "device": (1440, 1920, 760, 92, 30, 64), "island": False, "icon": (560, 400), "badges": 1760,
        "resize": None,
    },
}

BANNERS = {"header": (3840, 1646), "search-results": (3840, 2560)}

STYLE = """
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: __W__px; height: __H__px; overflow: hidden; }
body {
  background: #120e0c; color: #f0e6d2; position: relative;
  font-family: "SF Pro Rounded", "SF Pro Display", -apple-system, sans-serif;
}
.glow { position: absolute; inset: 0; }
.copy { position: absolute; left: 100px; right: 100px; text-align: center; }
.eyebrow {
  display: inline-flex; align-items: center; gap: 24px;
  font-size: __EYEBROW__px; font-weight: 700; letter-spacing: 8px; text-transform: uppercase; color: #e3b04b;
}
.eyebrow i { font-style: normal; font-size: 0.85em; color: #e38049; }
h1 { margin-top: 36px; font-size: __TITLE__px; line-height: 1.04; font-weight: 800; letter-spacing: -3px; color: #f7efe0; }
h1 em { font-style: normal; color: #e38049; }
.sub { margin: 40px auto 0; max-width: 1100px; font-size: __SUB__px; line-height: 1.3; font-weight: 500; color: rgba(240, 230, 210, 0.7); }
.device {
  position: absolute; left: 50%; transform: translateX(-50%);
  background: linear-gradient(150deg, #4a3d35, #17110e 35%, #2a211c 70%, #4a3d35);
  box-shadow: 0 0 0 3px #5a4a40, 0 90px 180px rgba(0, 0, 0, 0.65), 0 0 260px rgba(227, 128, 73, 0.28);
}
.screen { width: 100%; height: 100%; overflow: hidden; position: relative; background: #000; }
.screen img { width: 100%; height: 100%; object-fit: cover; object-position: top; display: block; }
.island { position: absolute; top: 29px; left: 50%; transform: translateX(-50%); width: 266px; height: 78px; border-radius: 39px; background: #000; }
.icon { position: absolute; left: 50%; transform: translateX(-50%); filter: drop-shadow(0 60px 120px rgba(227, 128, 73, 0.6)); }
.icon img { width: 100%; height: 100%; }
.badges { position: absolute; left: 0; right: 0; display: flex; flex-direction: column; align-items: center; gap: 32px; }
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
    "banner": "radial-gradient(1500px 1100px at 70% 55%, rgba(227,128,73,.55), transparent 70%),"
    "radial-gradient(1300px 900px at 8% 10%, rgba(184,132,28,.22), transparent 70%),"
    "radial-gradient(1200px 900px at 40% 120%, rgba(116,65,95,.4), transparent 70%)",
}


def image(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()


def style(profile: dict) -> str:
    width, height = profile["size"]
    values = {"W": width, "H": height, "TITLE": profile["title"], "SUB": profile["sub"], "EYEBROW": profile["eyebrow"]}
    css = STYLE
    for key, value in values.items():
        css = css.replace(f"__{key}__", str(value))
    return css


def copy(slide: dict, top: int) -> str:
    sub = f'<p class="sub">{slide["subtitle"]}</p>' if slide.get("subtitle") else ""
    return (
        f'<div class="copy" style="top:{top}px">'
        f'<div class="eyebrow"><i>✦</i>{slide["eyebrow"]}<i>✦</i></div>'
        f'<h1>{slide["title"]}</h1>{sub}</div>'
    )


def device(capture: Path, profile: dict, extra: str = "") -> str:
    width, height, top, radius, padding, inner = profile["device"]
    island = '<div class="island"></div>' if profile["island"] else ""
    return (
        f'<div class="device" style="width:{width}px;height:{height}px;top:{top}px;'
        f'border-radius:{radius}px;padding:{padding}px;{extra}">'
        f'<div class="screen" style="border-radius:{inner}px"><img src="{image(capture)}">{island}</div></div>'
    )


def page(slide: dict, captures: Path, profile: dict) -> str:
    if slide.get("capture"):
        glow = GLOWS["device"]
        content = copy(slide, profile["copy"]) + device(captures / slide["capture"], profile)
    else:
        glow = GLOWS["hero"]
        size, top = profile["icon"]
        badges = "".join(f'<div class="badge">{badge}</div>' for badge in slide["badges"])
        content = (
            f'<div class="icon" style="width:{size}px;height:{size}px;top:{top}px"><img src="{image(ICON)}"></div>'
            + copy(slide, profile["hero_copy"])
            + f'<div class="badges" style="top:{profile["badges"]}px">{badges}</div>'
            + (f'<div class="laurel">{slide["footer"]}</div>' if slide.get("footer") else "")
        )
    return document(style(profile), glow, content)


def banner(width: int, height: int, captures: Path) -> str:
    phone = min(height * 0.78, 1282)
    phone_width = phone * 0.46
    middle = (height - phone) / 2
    profile = {"device": (phone_width, phone, middle, phone_width * 0.17, 15, phone_width * 0.145), "island": True}
    left = width * 0.51
    step = phone_width * 0.97
    tilts = [(-6, 48), (0, 0), (6, 48)]
    devices = "".join(
        device(captures / name, profile, f"left:{left + index * step}px;transform:rotate({tilt}deg);top:{middle + drop}px;"
               + ("z-index:2;" if tilt == 0 else ""))
        for index, (name, (tilt, drop)) in enumerate(zip(["search.png", "app.png", "appearance.png"], tilts))
    )
    icon = min(height * 0.18, 330)
    title = min(height * 0.103, 175)
    css = style({"size": (width, height), "title": int(title), "sub": int(title * 0.36), "eyebrow": int(title * 0.26)})
    content = (
        f'<div class="icon" style="left:{icon / 2 + 300}px;width:{icon}px;height:{icon}px;top:{height * 0.5 - icon * 2.1}px">'
        f'<img src="{image(ICON)}"></div>'
        f'<div class="copy" style="left:300px;right:auto;width:1700px;text-align:left;top:{height * 0.5 - icon * 0.75}px">'
        '<div class="eyebrow">IPA<i>✦</i>134 Stores<i>✦</i>Private by design</div>'
        '<h1>The App Store,<br><em>decoded.</em></h1><p class="sub" style="margin-left:0">'
        "Every country. Every detail. One search.</p></div>" + devices
    )
    return document(css, GLOWS["banner"], content)


def document(css: str, glow: str, content: str) -> str:
    return (
        f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>'
        f'<div class="glow" style="background:{glow}"></div>{content}</body></html>'
    )


def render(html: str, size: tuple, output: Path) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as file:
        file.write(html)
    try:
        subprocess.run(
            [
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", f"--window-size={size[0]},{size[1]}",
                f"--screenshot={output}", f"file://{file.name}",
            ],
            check=True, capture_output=True,
        )
    finally:
        Path(file.name).unlink()


def screenshots(locale: str, kind: str) -> None:
    profile = PROFILES[kind]
    key = locale if kind == "iphone" else f"{locale}-{kind}"
    slides = json.loads((STORE / "screenshots.json").read_text())[key]
    captures = STORE / "captures" / key
    output = STORE / "screenshots" / key
    output.mkdir(parents=True, exist_ok=True)
    for index, slide in enumerate(slides, start=1):
        target = output / f"{index:02d}-{slide['name']}.png"
        render(page(slide, captures, profile), profile["size"], target)
        if profile["resize"]:
            suffix, width, height = profile["resize"]
            resized = STORE / "screenshots" / f"{key}{suffix}"
            resized.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["sips", "-z", str(height), str(width), str(target), "--out", str(resized / target.name)],
                check=True, capture_output=True,
            )
        print(target.relative_to(ROOT))


def banners(locale: str) -> None:
    captures = STORE / "captures" / locale
    for name, size in BANNERS.items():
        target = STORE / "screenshots" / f"{name}-{locale}.png"
        render(banner(*size, captures), size, target)
        print(target.relative_to(ROOT))


def main() -> None:
    locale = sys.argv[1] if len(sys.argv) > 1 else "en-US"
    screenshots(locale, "iphone")
    screenshots(locale, "ipad")
    banners(locale)


if __name__ == "__main__":
    main()
