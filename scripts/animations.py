#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile

W, H, FPS, END = 320, 180, 60, 150
CX, CY = W / 2, H / 2
ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "animations")
SWIFT = os.path.join(ROOT, "..", "IPAKit/Sources/IPAResource/IPAResourceAnimation.swift")
PREVIEW = os.path.join(ROOT, "animations-preview.html")
SYMBOL_SOURCE = os.path.join(ROOT, "symbols.swift")
SYMBOL_MAP = os.path.join(ROOT, "symbols-map.json")

# EASE is a fluid ease-in-out with a soft landing; SNAP leaves quickly; FALL accelerates like gravity.
EASE = ((0.2, 1.0), (0.4, 0.0))
SNAP = ((0.1, 1.0), (0.6, 0.0))
FALL = ((0.9, 0.7), (0.6, 0.0))
KAPPA = 0.5523

PALETTE = {
    "olive": (0x5F, 0x7A, 0x2E), "mustard": (0xB8, 0x84, 0x1C), "rust": (0xA6, 0x3D, 0x2C),
    "orange": (0xC2, 0x60, 0x2A), "teal": (0x2A, 0x70, 0x69), "denim": (0x3D, 0x5F, 0x86),
    "plum": (0x74, 0x41, 0x5F), "brown": (0x7E, 0x55, 0x36), "tint": (0xC2, 0x60, 0x2A),
    "ink": (0x1C, 0x1C, 0x1E), "paper": (0xFF, 0xFF, 0xFF), "cream": (0xF0, 0xE6, 0xD2),
}

GLYPHS = {}
MISSING = set()


# --- SF Symbol outlines ---------------------------------------------------------------------


def symbols_binary():
    binary = os.path.join(tempfile.gettempdir(), "ipa-symbols")
    if not os.path.exists(binary) or os.path.getmtime(binary) < os.path.getmtime(SYMBOL_SOURCE):
        subprocess.run(["swiftc", "-O", "-o", binary, SYMBOL_SOURCE], check=True)
    return binary


def load_glyphs(weight, names):
    with tempfile.NamedTemporaryFile(suffix=".json") as handle:
        subprocess.run([symbols_binary(), weight, SYMBOL_MAP, handle.name, *sorted(names)], check=True)
        with open(handle.name) as output:
            GLYPHS.setdefault(weight, {}).update(json.load(output))


def scaled_path(part, factor):
    def points(values):
        return [[round(x * factor, 2), round(y * factor, 2)] for x, y in values]
    return {"c": part["c"], "v": points(part["v"]), "i": points(part["i"]), "o": points(part["o"])}


def symbol(name, color, height, weight="Semibold", opacity=100, position=(0, 0), rotation=0, flip=False):
    glyph = GLYPHS.get(weight, {}).get(name)
    if glyph is None:
        MISSING.add((weight, name))
        return group([], name)
    factor = height / glyph["h"]
    shapes = [{"ty": "sh", "d": 1, "ks": const(scaled_path(part, factor))} for part in glyph["paths"]]
    scale = const([-100 if flip else 100, 100])
    return group(shapes + [fill(color, opacity), transform(position, scale=scale, rotation=const(rotation))], name)


# --- Lottie primitives ----------------------------------------------------------------------


def rgb(name):
    r, g, b = PALETTE[name]
    return [r / 255, g / 255, b / 255, 1]


def const(value):
    return {"a": 0, "k": value}


def anim(frames, ease=EASE):
    keys = []
    for index, frame in enumerate(frames):
        time, value = frame[0], frame[1]
        segment = frame[2] if len(frame) > 2 else ease
        values = value if isinstance(value, list) else [value]
        key = {"t": round(time), "s": values}
        if index < len(frames) - 1:
            key["i"] = {"x": [segment[0][0]] * len(values), "y": [segment[0][1]] * len(values)}
            key["o"] = {"x": [segment[1][0]] * len(values), "y": [segment[1][1]] * len(values)}
        keys.append(key)
    return {"a": 1, "k": keys}


def move(frames, ease=EASE):
    return anim([(frame[0], [frame[1][0], frame[1][1], 0], *frame[2:]) for frame in frames], ease)


def fill(color, opacity=100):
    return {"ty": "fl", "c": const(rgb(color)), "o": const(opacity), "r": 1}


def transform(position=(0, 0), scale=None, rotation=None, opacity=None, anchor=(0, 0)):
    return {
        "ty": "tr", "p": position if isinstance(position, dict) else const(list(position)),
        "a": const(list(anchor)), "s": scale if scale is not None else const([100, 100]),
        "r": rotation if rotation is not None else const(0),
        "o": opacity if opacity is not None else const(100),
    }


def rect(size, radius=0, position=(0, 0)):
    return {"ty": "rc", "d": 1, "s": const(list(size)), "p": const(list(position)), "r": const(radius)}


def ellipse(diameter, position=(0, 0)):
    return {"ty": "el", "d": 1, "s": const([diameter, diameter]), "p": const(list(position))}


def group(items, name="group"):
    return {"ty": "gr", "nm": name, "it": items}


def box_path(x0, y0, x1, y1):
    return {"c": True, "v": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "i": [[0, 0]] * 4, "o": [[0, 0]] * 4}


def pocket_path(width, height, radius, lip, dip):
    w, h, k = width / 2, height / 2, KAPPA
    vertices = [
        ((-w, -h + lip), (0, 0), (0, -lip * k)), ((-w + lip, -h), (-lip * k, 0), (0, 0)),
        ((-dip, -h), (0, 0), (0, dip * k)), ((0, -h + dip), (-dip * k, 0), (dip * k, 0)), ((dip, -h), (0, dip * k), (0, 0)),
        ((w - lip, -h), (0, 0), (lip * k, 0)), ((w, -h + lip), (0, -lip * k), (0, 0)),
        ((w, h - radius), (0, 0), (0, radius * k)), ((w - radius, h), (radius * k, 0), (0, 0)),
        ((-w + radius, h), (0, 0), (-radius * k, 0)), ((-w, h - radius), (0, radius * k), (0, 0)),
    ]
    path = {"c": True, "v": [list(v) for v, _, _ in vertices], "i": [list(i) for _, i, _ in vertices], "o": [list(o) for _, _, o in vertices]}
    return {"ty": "sh", "d": 1, "ks": const(path)}


def wipe(delay, length, size, direction="right", ease=EASE):
    w, h = size[0] / 2 + 2, size[1] / 2 + 2
    full = box_path(-w, -h, w, h)
    start = {
        "right": box_path(-w, -h, -w, h), "left": box_path(w, -h, w, h),
        "up": box_path(-w, h, w, h), "down": box_path(-w, -h, w, -h),
    }[direction]
    path = {"a": 1, "k": [
        {"t": delay, "s": [start], "i": {"x": [ease[0][0]], "y": [ease[0][1]]}, "o": {"x": [ease[1][0]], "y": [ease[1][1]]}},
        {"t": delay + length, "s": [full]},
    ]}
    return {"inv": False, "mode": "a", "pt": path, "o": const(100), "x": const(0), "nm": "wipe"}


def layer(name, shapes, position=(CX, CY), scale=None, rotation=None, opacity=None, anchor=(0, 0), mask=None):
    item = {
        "ddd": 0, "ind": 1, "ty": 4, "nm": name, "sr": 1, "ao": 0, "ip": 0, "op": END, "st": 0, "bm": 0,
        "ks": {
            "o": opacity if opacity is not None else const(100),
            "r": rotation if rotation is not None else const(0),
            "p": position if isinstance(position, dict) else const([position[0], position[1], 0]),
            "a": const([anchor[0], anchor[1], 0]),
            "s": scale if scale is not None else const([100, 100, 100]),
        },
        "shapes": shapes,
    }
    if mask is not None:
        item["hasMask"] = True
        item["masksProperties"] = [mask]
    return item


def animation(name, layers):
    layers = list(reversed(layers))
    for index, item in enumerate(layers):
        item["ind"] = index + 1
    return {"v": "5.9.0", "fr": FPS, "ip": 0, "op": END, "w": W, "h": H, "nm": name, "ddd": 0, "assets": [], "layers": layers}


# --- Motion language --------------------------------------------------------------------------


def appear(delay, length=28, overshoot=104, start=60):
    peak = delay + round(length * 0.65)
    return anim([(delay, [start, start, 100]), (peak, [overshoot, overshoot, 100]), (delay + length, [100, 100, 100])])


def fade(delay, length=14):
    return anim([(delay, 0), (delay + length, 100)])


def wave(start, values, step, end=END):
    frames = [(start + index * step, value) for index, value in enumerate(values)]
    if frames[-1][0] < end:
        frames.append((end, values[0]))
    return frames


def breathe(start=0, amount=3, step=37, until=END):
    frames = wave(start, [100, 100 + amount], step, until)
    return anim([(time, [value, value, 100]) for time, value in frames])


def float_y(x, y, amount, start=0, step=37, until=END):
    return move([(time, (x, y + offset)) for time, offset in wave(start, [0, -amount], step, until)])


def settle(delay, angles, step=14):
    return anim([(delay + index * step, angle) for index, angle in enumerate(angles + [0])])


def icon(name, color, height, position, delay=None, weight="Semibold", alpha=100, flip=False, **keys):
    if delay is not None:
        keys.setdefault("scale", appear(delay))
        keys.setdefault("opacity", fade(delay))
    return layer(color, [symbol(name, color, height, weight, alpha, flip=flip)], position=position, **keys)


def bar(color, center, ratio, delay, width=120, height=12, length=40, track="ink"):
    x, y = center
    track_layer = layer(track, [group([rect((width, height), height / 2), fill(track, 12), transform()])], position=(x, y))
    grow = anim([(delay, [0, 100]), (delay + length, [ratio * 100, 100])])
    fill_layer = layer(color, [group([rect((width, height), height / 2, (width / 2, 0)), fill(color), transform(scale=grow)])], position=(x - width / 2, y))
    return [track_layer, fill_layer]


def dot(color, diameter, opacity=100):
    return group([ellipse(diameter), fill(color, opacity), transform()])


# --- Animations ------------------------------------------------------------------------------


def computer():
    laptop = icon("laptopcomputer", "tint", 88, (122, 90), delay=0)
    laptop["ks"]["s"] = appear(0, 30, overshoot=106, start=50)
    phone = icon("iphone", "ink", 72, (262, 92), delay=14, alpha=35)
    cable = icon("cable.connector", "ink", 32, (206, 112), delay=30, alpha=55)
    cable["ks"]["s"] = appear(30, overshoot=112, start=40)
    check = icon("checkmark.circle.fill", "olive", 28, (284, 130), delay=96)
    check["ks"]["s"] = appear(96, overshoot=116, start=40)
    return [phone, laptop, cable, check]


def direct():
    phone = icon("iphone", "ink", 84, (86, 90), delay=0, alpha=35)
    server = icon("server.rack", "teal", 72, (238, 90), delay=12)
    server["ks"]["s"] = appear(12, overshoot=108, start=40)
    arrows = icon("arrow.left.arrow.right", "tint", 34, (162, 82), delay=34, scale=breathe(60, 6, step=40))
    lock = icon("lock.fill", "olive", 26, (162, 124), delay=70)
    lock["ks"]["s"] = appear(70, overshoot=116, start=40)
    return [phone, server, arrows, lock]


def find():
    glass = icon("magnifyingglass", "tint", 72, move([(0, (110, 96)), (50, (128, 84)), (100, (110, 96)), (END, (110, 96))]))
    app = icon("app.fill", "denim", 56, (214, 78), delay=20)
    app["ks"]["s"] = appear(20, overshoot=108, start=40)
    arrow = icon("arrow.down.circle.fill", "olive", 34, move([(56, (214, 92)), (92, (214, 136))]), delay=56)
    arrow["ks"]["s"] = appear(56, overshoot=114, start=40)
    return [glass, app, arrow]


def setup():
    person = icon("person.crop.circle.fill", "tint", 80, (124, 90), delay=0)
    person["ks"]["s"] = appear(0, 30, overshoot=106, start=50)
    gear = icon("gearshape.fill", "denim", 50, (220, 76), delay=26, rotation=anim([(26, -40), (90, 0)]))
    gear["ks"]["s"] = appear(26, overshoot=110, start=40)
    check = icon("checkmark.circle.fill", "olive", 28, (236, 128), delay=84)
    check["ks"]["s"] = appear(84, overshoot=116, start=40)
    return [person, gear, check]


def done():
    check = icon("checkmark.circle.fill", "olive", 96, (160, 90), delay=0)
    check["ks"]["s"] = appear(0, 34, overshoot=110, start=40)
    layers = []
    for index, (name, dx, dy) in enumerate([("tint", -94, -46), ("mustard", 98, -40), ("mustard", -90, 50), ("tint", 96, 54)]):
        delay = 24 + index * 4
        path = move([(delay, (160 + dx * 0.4, 90 + dy * 0.4)), (delay + 36, (160 + dx, 90 + dy))])
        layers.append(layer(name, [dot(name, 12)], position=path, scale=appear(delay, 16, overshoot=120, start=0),
                            opacity=anim([(delay, 100), (delay + 40, 100), (delay + 60, 0)])))
    sparks = [icon("sparkles", "mustard", 44, (90, 54), delay=30), icon("sparkles", "mustard", 44, (232, 60), delay=42, flip=True)]
    for index, spark in enumerate(sparks):
        spark["ks"]["s"] = appear(30 + index * 12, 26, overshoot=120, start=40)
    return [check] + layers + sparks


def download():
    arrow = icon("arrow.down.circle.fill", "tint", 84, (108, 90), delay=0)
    arrow["ks"]["s"] = appear(0, 30, overshoot=108, start=50)
    box = icon("shippingbox.fill", "mustard", 46, (222, 66), delay=22)
    box["ks"]["s"] = appear(22, overshoot=110, start=40)
    layers = [arrow, box] + bar("olive", (222, 120), 1.0, 40, width=96, length=70)
    check = icon("checkmark.circle.fill", "olive", 28, (290, 120), delay=112)
    check["ks"]["s"] = appear(112, overshoot=116, start=40)
    return layers + [check]


def identity():
    cycle = icon("arrow.counterclockwise", "tint", 84, (118, 90), delay=0, rotation=anim([(0, 180), (80, 0)]))
    cycle["ks"]["s"] = appear(0, 30, overshoot=106, start=50)
    phone = icon("iphone", "ink", 88, (232, 90), delay=10, alpha=35)
    number = icon("number", "mustard", 30, (232, 88), delay=56)
    number["ks"]["s"] = appear(56, overshoot=118, start=40)
    return [phone, cycle, number]


def install():
    package = icon("shippingbox.fill", "tint", 84, move([(0, (110, 84)), (70, (110, 84)), (110, (150, 96))]))
    package["ks"]["s"] = appear(0, 30, overshoot=108, start=50)
    phone = icon("iphone", "ink", 96, (220, 90), delay=0, alpha=35)
    check = icon("checkmark.circle.fill", "olive", 30, (246, 128), delay=110)
    check["ks"]["s"] = appear(110, overshoot=116, start=40)
    return [phone, package, check]


def jit():
    chip = icon("cpu.fill", "tint", 84, (132, 90), delay=0)
    chip["ks"]["s"] = appear(0, 30, overshoot=106, start=50)
    bolt = icon("bolt.fill", "mustard", 46, (218, 70), delay=30, scale=breathe(70, 6, step=40))
    lock = icon("lock.open.fill", "ink", 28, (226, 124), delay=80, alpha=55)
    lock["ks"]["s"] = appear(80, overshoot=116, start=40)
    return [chip, bolt, lock]


def launch():
    card = icon("app.fill", "tint", 84, float_y(150, 92, 5, step=75), scale=breathe(0, 3, step=75))
    star = icon("star.fill", "mustard", 36, move([(0, (204, 120)), (75, (220, 42)), (END, (204, 120))]),
                rotation=anim([(0, -14), (75, 10), (END, -14)]))
    spark_right = icon("sparkles", "ink", 36, (250, 60), alpha=45, scale=breathe(0, -20, step=75),
                       opacity=anim([(0, 0), (30, 100), (90, 100), (120, 0), (END, 0)]))
    spark_left = icon("sparkles", "ink", 26, (70, 126), alpha=45, scale=breathe(0, -20, step=75),
                      opacity=anim([(0, 100), (40, 100), (70, 0), (110, 0), (END, 100)]))
    return [spark_left, star, card, spark_right]

def privacy():
    shield = icon("lock.shield.fill", "tint", 88, (130, 90), delay=0)
    shield["ks"]["s"] = appear(0, 32, overshoot=106, start=50)
    face = icon("faceid", "ink", 46, (236, 90), alpha=55, scale=breathe(70, 4, step=40),
                opacity=anim([(36, 0), (48, 100), (100, 100), (112, 55), (124, 100)]))
    return [shield, face]


def share():
    phone = icon("iphone", "ink", 72, (70, 92), delay=0, alpha=35)
    laptop = icon("laptopcomputer", "ink", 72, (262, 96), delay=8, alpha=35)
    waves = icon("dot.radiowaves.left.and.right", "tint", 84, (162, 88), delay=0, scale=breathe(60, 6, step=40))
    package = icon("shippingbox.fill", "mustard", 28, move([(36, (92, 34)), (110, (236, 34))]), delay=36)
    return [phone, laptop, waves, package]


ANIMATIONS = {
    "computer": computer,
    "direct": direct,
    "done": done,
    "download": download,
    "find": find,
    "identity": identity,
    "install": install,
    "jit": jit,
    "launch": launch,
    "privacy": privacy,
    "setup": setup,
    "share": share,
}


# --- Output ----------------------------------------------------------------------------------


def build_all():
    documents = {name: animation(name, build()) for name, build in ANIMATIONS.items()}
    while MISSING:
        by_weight = {}
        for weight, name in MISSING:
            by_weight.setdefault(weight, set()).add(name)
        MISSING.clear()
        for weight, names in by_weight.items():
            load_glyphs(weight, names)
        documents = {name: animation(name, build()) for name, build in ANIMATIONS.items()}
    return documents


def write_swift(texts):
    lines = ["import Foundation", "", "public enum IPAResourceAnimation {",
             "    public static func json(named name: String) -> String? {", "        switch name {"]
    for name, text in texts.items():
        lines += [f'        case "{name}":', f'            #"{text}"#']
    lines += ["        default: nil", "        }", "    }", "}", ""]
    with open(SWIFT, "w") as handle:
        handle.write("\n".join(lines))


def write_preview(texts):
    cards = "\n".join(f'<figure><div class="stage" data-name="{name}"></div><figcaption>{name}</figcaption></figure>' for name in texts)
    data = json.dumps(texts, separators=(",", ":")).replace("</", "<\\/")
    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>IPA animations</title>
<style>
  :root {{ --bg: #F5F1EA; --fg: #1C1C1E; --card: #FFFFFF; }}
  body.dark {{ --bg: #1C1C1E; --fg: #F5F1EA; --card: #2C2C2E; }}
  body {{ margin: 0; padding: 24px; background: var(--bg); color: var(--fg); font: 14px -apple-system, system-ui, sans-serif; }}
  header {{ display: flex; gap: 16px; align-items: center; margin-bottom: 20px; }}
  button {{ font: inherit; padding: 6px 12px; border-radius: 8px; border: 1px solid currentColor; background: transparent; color: inherit; }}
  main {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 20px; }}
  figure {{ margin: 0; }}
  .stage {{ aspect-ratio: 16 / 9; background: var(--card); border-radius: 16px; overflow: hidden; }}
  figcaption {{ margin-top: 8px; font-family: ui-monospace, monospace; }}
</style>
</head>
<body>
<header><strong>IPA animations</strong><button id="theme">Dark</button><button id="restart">Restart</button></header>
<main>
{cards}
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>
<script>
const animations = {data};
const ink = {{ light: [0.11, 0.11, 0.12, 1], dark: [0.96, 0.95, 0.92, 1] }};
let players = [];
function recolor(items, color) {{
  items.forEach((item) => {{
    if (item.ty === "fl" || item.ty === "st") item.c.k = color;
    if (item.it) recolor(item.it, color);
  }});
}}
function load() {{
  players.forEach((player) => player.destroy());
  players = [];
  const theme = document.body.classList.contains("dark") ? "dark" : "light";
  document.querySelectorAll(".stage").forEach((stage) => {{
    const data = JSON.parse(animations[stage.dataset.name]);
    data.layers.filter((item) => item.nm === "ink").forEach((item) => recolor(item.shapes, ink[theme]));
    players.push(lottie.loadAnimation({{ container: stage, renderer: "svg", loop: true, autoplay: true, animationData: data }}));
  }});
}}
load();
document.getElementById("theme").addEventListener("click", () => {{ document.body.classList.toggle("dark"); load(); }});
document.getElementById("restart").addEventListener("click", () => players.forEach((player) => player.goToAndPlay(0, true)));
</script>
</body>
</html>
"""
    with open(PREVIEW, "w") as handle:
        handle.write(page)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    texts = {}
    for name, document in build_all().items():
        text = json.dumps(document, separators=(",", ":"))
        with open(os.path.join(OUT, name + ".json"), "w") as handle:
            handle.write(text + "\n")
        texts[name] = text
    write_swift(texts)
    write_preview(texts)
    print(f"{len(ANIMATIONS)} animations written to {os.path.abspath(OUT)}, {os.path.abspath(SWIFT)} and {os.path.abspath(PREVIEW)}")
