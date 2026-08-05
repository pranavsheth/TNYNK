"""
Builds water_cycle.sb3 — a Scratch 3 project that animates the water cycle.

Design (v3 — sequential, no restart-on-rebroadcast bug):

    The Stage drives the cycle in a forever loop using `broadcast [..] and wait`.
    Each phase therefore fully completes before the next is triggered.

        Stage (forever)
            ├── broadcast EVAPORATE and wait  ─► WaterDrop rises, then returns
            ├── drops += 1
            ├── broadcast CONDENSE and wait   ─► Cloud says + grows
            └── if drops > 2:
                    broadcast PRECIPITATE and wait ─► RainDrop spawns 8 clones
                    Cycle += 1
                    drops = 0

    Sun has its OWN forever pulse loop — purely decorative now (no broadcasts).

Run:  python build_water_cycle_sb3.py
Out:  water_cycle.sb3   (open in Scratch 3 / scratch.mit.edu)
"""

import hashlib
import json
import os
import zipfile

# ----------------------------------------------------------------------------
# Costume SVGs
# ----------------------------------------------------------------------------

SVG_BACKDROP = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="360" viewBox="0 0 480 360">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#B9E3FB"/>
      <stop offset="1" stop-color="#E7F5FF"/>
    </linearGradient>
    <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3BA7E4"/>
      <stop offset="1" stop-color="#1E6FB8"/>
    </linearGradient>
  </defs>
  <rect width="480" height="240" fill="url(#sky)"/>
  <path d="M0 240 Q 120 220 240 240 T 480 240 L 480 360 L 0 360 Z" fill="url(#sea)"/>
  <path d="M0 252 Q 120 234 240 252 T 480 252 L 480 360 L 0 360 Z" fill="#1E6FB8" opacity="0.45"/>
  <path d="M0 268 Q 120 252 240 268 T 480 268 L 480 360 L 0 360 Z" fill="#16538A" opacity="0.35"/>
</svg>"""

SVG_SUN = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
  <g stroke="#FFCC33" stroke-width="5" stroke-linecap="round">
    <line x1="50" y1="5"  x2="50" y2="20"/>
    <line x1="50" y1="80" x2="50" y2="95"/>
    <line x1="5"  y1="50" x2="20" y2="50"/>
    <line x1="80" y1="50" x2="95" y2="50"/>
    <line x1="18" y1="18" x2="28" y2="28"/>
    <line x1="72" y1="72" x2="82" y2="82"/>
    <line x1="18" y1="82" x2="28" y2="72"/>
    <line x1="72" y1="28" x2="82" y2="18"/>
  </g>
  <circle cx="50" cy="50" r="28" fill="#FFCC33"/>
  <circle cx="42" cy="44" r="6" fill="#FFE680" opacity="0.8"/>
</svg>"""

SVG_WATERDROP = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="40" height="60" viewBox="0 0 40 60">
  <path d="M20 4 C 6 24, 4 42, 20 56 C 36 42, 34 24, 20 4 Z"
        fill="#3BA7E4" stroke="#1E6FB8" stroke-width="2"/>
  <ellipse cx="14" cy="34" rx="4" ry="7" fill="#CCEAF8" opacity="0.85"/>
</svg>"""

SVG_CLOUD = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="140" height="80" viewBox="0 0 140 80">
  <g fill="#FFFFFF" stroke="#B7D9EC" stroke-width="2">
    <ellipse cx="70" cy="55" rx="58" ry="20"/>
    <circle cx="38" cy="48" r="22"/>
    <circle cx="70" cy="32" r="28"/>
    <circle cx="102" cy="46" r="24"/>
  </g>
</svg>"""

SVG_RAINDROP = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="32" viewBox="0 0 20 32">
  <path d="M10 2 C 4 12, 2 22, 10 30 C 18 22, 16 12, 10 2 Z"
        fill="#4C97FF" stroke="#1E6FB8" stroke-width="1.5"/>
</svg>"""


def md5_of(text: str) -> str:
    return hashlib.md5(text.encode("utf-8")).hexdigest()


# ----------------------------------------------------------------------------
# Block builder
# ----------------------------------------------------------------------------

class ScriptBuilder:
    def __init__(self, prefix: str):
        self.prefix = prefix
        self.counter = 0
        self.blocks: dict[str, dict] = {}

    def new_id(self) -> str:
        self.counter += 1
        return f"{self.prefix}-b{self.counter}"

    @staticmethod
    def num_input(val) -> list:
        return [1, [4, str(val)]]

    @staticmethod
    def text_input(val) -> list:
        return [1, [10, str(val)]]

    @staticmethod
    def broadcast_input(name: str, bid: str) -> list:
        return [1, [11, name, bid]]

    @staticmethod
    def block_input(block_id: str, fallback=None) -> list:
        if fallback is None:
            fallback = [4, "0"]
        return [3, block_id, fallback]

    @staticmethod
    def variable_input(name: str, vid: str, default=None) -> list:
        if default is None:
            default = [10, ""]
        return [3, [12, name, vid], default]

    @staticmethod
    def substack_input(block_id: str) -> list:
        return [2, block_id]

    def add(
        self,
        opcode: str,
        inputs: dict | None = None,
        fields: dict | None = None,
        shadow: bool = False,
        top_level: bool = False,
        x: int = 0,
        y: int = 0,
    ) -> str:
        bid = self.new_id()
        b = {
            "opcode": opcode,
            "next": None,
            "parent": None,
            "inputs": inputs or {},
            "fields": fields or {},
            "shadow": shadow,
            "topLevel": top_level,
        }
        if top_level:
            b["x"] = x
            b["y"] = y
        self.blocks[bid] = b
        return bid

    def link(self, *ids: str) -> None:
        for i, bid in enumerate(ids):
            if i + 1 < len(ids):
                self.blocks[bid]["next"] = ids[i + 1]
            if i > 0:
                self.blocks[bid]["parent"] = ids[i - 1]

    def set_parent(self, child_id: str, parent_id: str) -> None:
        self.blocks[child_id]["parent"] = parent_id


# ----------------------------------------------------------------------------
# Shared IDs
# ----------------------------------------------------------------------------

BC_EVAPORATE = "bc-evaporate"
BC_CONDENSE  = "bc-condense"
BC_PRECIP    = "bc-precipitate"

VAR_CYCLE = "var-cycle"
VAR_DROPS = "var-drops"


# ----------------------------------------------------------------------------
# STAGE — drives the cycle with broadcast-and-wait
# ----------------------------------------------------------------------------

def build_stage_blocks() -> dict:
    s = ScriptBuilder("stg")

    flag       = s.add("event_whenflagclicked", top_level=True, x=40, y=40)
    init_drops = s.add(
        "data_setvariableto",
        inputs={"VALUE": ScriptBuilder.text_input("0")},
        fields={"VARIABLE": ["drops", VAR_DROPS]},
    )
    init_cycle = s.add(
        "data_setvariableto",
        inputs={"VALUE": ScriptBuilder.text_input("0")},
        fields={"VARIABLE": ["Cycle", VAR_CYCLE]},
    )

    forever = s.add("control_forever", inputs={})

    cast_evap = s.add(
        "event_broadcastandwait",
        inputs={"BROADCAST_INPUT": ScriptBuilder.broadcast_input("evaporate", BC_EVAPORATE)},
    )
    inc_drops = s.add(
        "data_changevariableby",
        inputs={"VALUE": ScriptBuilder.text_input("1")},
        fields={"VARIABLE": ["drops", VAR_DROPS]},
    )
    cast_cond = s.add(
        "event_broadcastandwait",
        inputs={"BROADCAST_INPUT": ScriptBuilder.broadcast_input("condense", BC_CONDENSE)},
    )

    gt = s.add(
        "operator_gt",
        inputs={
            "OPERAND1": ScriptBuilder.variable_input("drops", VAR_DROPS),
            "OPERAND2": ScriptBuilder.text_input("2"),
        },
    )
    if_blk = s.add(
        "control_if",
        inputs={"CONDITION": ScriptBuilder.block_input(gt)},
    )
    s.set_parent(gt, if_blk)

    cast_prec = s.add(
        "event_broadcastandwait",
        inputs={"BROADCAST_INPUT": ScriptBuilder.broadcast_input("precipitate", BC_PRECIP)},
    )
    inc_cycle = s.add(
        "data_changevariableby",
        inputs={"VALUE": ScriptBuilder.text_input("1")},
        fields={"VARIABLE": ["Cycle", VAR_CYCLE]},
    )
    reset_drops = s.add(
        "data_setvariableto",
        inputs={"VALUE": ScriptBuilder.text_input("0")},
        fields={"VARIABLE": ["drops", VAR_DROPS]},
    )
    s.link(cast_prec, inc_cycle, reset_drops)
    s.set_parent(cast_prec, if_blk)
    s.blocks[if_blk]["inputs"]["SUBSTACK"] = ScriptBuilder.substack_input(cast_prec)

    s.link(cast_evap, inc_drops, cast_cond, if_blk)
    s.set_parent(cast_evap, forever)
    s.blocks[forever]["inputs"]["SUBSTACK"] = ScriptBuilder.substack_input(cast_evap)

    s.link(flag, init_drops, init_cycle, forever)
    return s.blocks


# ----------------------------------------------------------------------------
# SUN — decorative pulse only
# ----------------------------------------------------------------------------

def build_sun_blocks() -> dict:
    s = ScriptBuilder("sun")

    flag     = s.add("event_whenflagclicked", top_level=True, x=40, y=40)
    goto     = s.add("motion_gotoxy",
                     inputs={"X": ScriptBuilder.num_input(180),
                             "Y": ScriptBuilder.num_input(130)})
    set_size = s.add("looks_setsizeto",
                     inputs={"SIZE": ScriptBuilder.num_input(80)})
    show_sun = s.add("looks_show")

    forever = s.add("control_forever", inputs={})
    grow    = s.add("looks_changesizeby", inputs={"CHANGE": ScriptBuilder.num_input(12)})
    wait1   = s.add("control_wait",       inputs={"DURATION": ScriptBuilder.num_input(0.25)})
    shrink  = s.add("looks_changesizeby", inputs={"CHANGE": ScriptBuilder.num_input(-12)})
    wait2   = s.add("control_wait",       inputs={"DURATION": ScriptBuilder.num_input(0.25)})
    s.link(grow, wait1, shrink, wait2)
    s.set_parent(grow, forever)
    s.blocks[forever]["inputs"]["SUBSTACK"] = ScriptBuilder.substack_input(grow)

    s.link(flag, goto, set_size, show_sun, forever)
    return s.blocks


# ----------------------------------------------------------------------------
# WATER DROP — rises on `evaporate`
# ----------------------------------------------------------------------------

def build_waterdrop_blocks() -> dict:
    s = ScriptBuilder("wd")

    flag  = s.add("event_whenflagclicked", top_level=True, x=40, y=40)
    hide0 = s.add("looks_hide")
    s.link(flag, hide0)

    recv = s.add(
        "event_whenbroadcastreceived",
        fields={"BROADCAST_OPTION": ["evaporate", BC_EVAPORATE]},
        top_level=True, x=40, y=180,
    )
    rand_x = s.add(
        "operator_random",
        inputs={"FROM": ScriptBuilder.num_input(-150),
                "TO":   ScriptBuilder.num_input(150)},
    )
    goto = s.add(
        "motion_gotoxy",
        inputs={"X": ScriptBuilder.block_input(rand_x),
                "Y": ScriptBuilder.num_input(-120)},
    )
    s.set_parent(rand_x, goto)
    show = s.add("looks_show")
    say  = s.add(
        "looks_sayforsecs",
        inputs={"MESSAGE": ScriptBuilder.text_input("Evaporation!"),
                "SECS":    ScriptBuilder.num_input(0.5)},
    )
    glide = s.add(
        "motion_glidesecstoxy",
        inputs={"SECS": ScriptBuilder.num_input(1.5),
                "X":    ScriptBuilder.num_input(-100),
                "Y":    ScriptBuilder.num_input(100)},
    )
    hide = s.add("looks_hide")
    s.link(recv, goto, show, say, glide, hide)
    return s.blocks


# ----------------------------------------------------------------------------
# CLOUD — grows on `condense`, resets on `precipitate`
# ----------------------------------------------------------------------------

def build_cloud_blocks() -> dict:
    s = ScriptBuilder("cl")

    flag = s.add("event_whenflagclicked", top_level=True, x=40, y=40)
    goto = s.add(
        "motion_gotoxy",
        inputs={"X": ScriptBuilder.num_input(-100),
                "Y": ScriptBuilder.num_input(130)},
    )
    sz   = s.add("looks_setsizeto", inputs={"SIZE": ScriptBuilder.num_input(60)})
    show = s.add("looks_show")
    s.link(flag, goto, sz, show)

    recv_c = s.add(
        "event_whenbroadcastreceived",
        fields={"BROADCAST_OPTION": ["condense", BC_CONDENSE]},
        top_level=True, x=40, y=200,
    )
    say_c = s.add(
        "looks_sayforsecs",
        inputs={"MESSAGE": ScriptBuilder.text_input("Condensation!"),
                "SECS":    ScriptBuilder.num_input(0.5)},
    )
    grow = s.add("looks_changesizeby", inputs={"CHANGE": ScriptBuilder.num_input(15)})
    s.link(recv_c, say_c, grow)

    recv_p = s.add(
        "event_whenbroadcastreceived",
        fields={"BROADCAST_OPTION": ["precipitate", BC_PRECIP]},
        top_level=True, x=40, y=360,
    )
    say_p = s.add(
        "looks_sayforsecs",
        inputs={"MESSAGE": ScriptBuilder.text_input("Precipitation!"),
                "SECS":    ScriptBuilder.num_input(0.5)},
    )
    reset_sz = s.add("looks_setsizeto", inputs={"SIZE": ScriptBuilder.num_input(60)})
    s.link(recv_p, say_p, reset_sz)

    return s.blocks


# ----------------------------------------------------------------------------
# RAIN DROP — spawns 8 falling clones on `precipitate`
# ----------------------------------------------------------------------------

def build_raindrop_blocks() -> dict:
    s = ScriptBuilder("rd")

    flag  = s.add("event_whenflagclicked", top_level=True, x=40, y=40)
    hide0 = s.add("looks_hide")
    s.link(flag, hide0)

    recv = s.add(
        "event_whenbroadcastreceived",
        fields={"BROADCAST_OPTION": ["precipitate", BC_PRECIP]},
        top_level=True, x=40, y=160,
    )
    repeat = s.add("control_repeat", inputs={"TIMES": ScriptBuilder.num_input(8)})

    menu = s.add(
        "control_create_clone_of_menu",
        fields={"CLONE_OPTION": ["_myself_", None]},
        shadow=True,
    )
    clone = s.add("control_create_clone_of", inputs={"CLONE_OPTION": [1, menu]})
    s.set_parent(menu, clone)
    wait = s.add("control_wait", inputs={"DURATION": ScriptBuilder.num_input(0.08)})
    s.link(clone, wait)
    s.set_parent(clone, repeat)
    s.blocks[repeat]["inputs"]["SUBSTACK"] = ScriptBuilder.substack_input(clone)
    s.link(recv, repeat)

    start_clone = s.add("control_start_as_clone", top_level=True, x=40, y=320)
    rx = s.add(
        "operator_random",
        inputs={"FROM": ScriptBuilder.num_input(-140),
                "TO":   ScriptBuilder.num_input(-60)},
    )
    goto_top = s.add(
        "motion_gotoxy",
        inputs={"X": ScriptBuilder.block_input(rx),
                "Y": ScriptBuilder.num_input(120)},
    )
    s.set_parent(rx, goto_top)
    show = s.add("looks_show")
    xpos = s.add("motion_xposition")
    glide = s.add(
        "motion_glidesecstoxy",
        inputs={"SECS": ScriptBuilder.num_input(0.8),
                "X":    ScriptBuilder.block_input(xpos),
                "Y":    ScriptBuilder.num_input(-120)},
    )
    s.set_parent(xpos, glide)
    delete = s.add("control_delete_this_clone")
    s.link(start_clone, goto_top, show, glide, delete)

    return s.blocks


# ----------------------------------------------------------------------------
# Costume / target helpers
# ----------------------------------------------------------------------------

def costume(name: str, svg_text: str, cx: float, cy: float):
    md5 = md5_of(svg_text)
    fname = f"{md5}.svg"
    return (
        {
            "assetId": md5,
            "name": name,
            "bitmapResolution": 1,
            "md5ext": fname,
            "dataFormat": "svg",
            "rotationCenterX": cx,
            "rotationCenterY": cy,
        },
        fname,
        svg_text,
    )


def build_project():
    bg_c, bg_f, bg_s    = costume("backdrop1", SVG_BACKDROP, 240, 180)
    sun_c, sun_f, sun_s = costume("sun",  SVG_SUN, 50, 50)
    wd_c, wd_f, wd_s    = costume("drop", SVG_WATERDROP, 20, 30)
    cl_c, cl_f, cl_s    = costume("cloud", SVG_CLOUD, 70, 40)
    rd_c, rd_f, rd_s    = costume("rain", SVG_RAINDROP, 10, 16)

    stage = {
        "isStage": True,
        "name": "Stage",
        "variables": {
            VAR_CYCLE: ["Cycle", 0],
            VAR_DROPS: ["drops", 0],
        },
        "lists": {},
        "broadcasts": {
            BC_EVAPORATE: "evaporate",
            BC_CONDENSE:  "condense",
            BC_PRECIP:    "precipitate",
        },
        "blocks": build_stage_blocks(),
        "comments": {},
        "currentCostume": 0,
        "costumes": [bg_c],
        "sounds": [],
        "volume": 100,
        "layerOrder": 0,
        "tempo": 60,
        "videoTransparency": 50,
        "videoState": "on",
        "textToSpeechLanguage": None,
    }

    def make_sprite(name, blocks, costume_dict, x, y, size, visible, layer):
        return {
            "isStage": False,
            "name": name,
            "variables": {},
            "lists": {},
            "broadcasts": {},
            "blocks": blocks,
            "comments": {},
            "currentCostume": 0,
            "costumes": [costume_dict],
            "sounds": [],
            "volume": 100,
            "layerOrder": layer,
            "visible": visible,
            "x": x, "y": y,
            "size": size,
            "direction": 90,
            "draggable": False,
            "rotationStyle": "all around",
        }

    sun_sprite   = make_sprite("Sun", build_sun_blocks(),
                               sun_c, 180, 130, 80, True, 4)
    water_sprite = make_sprite("WaterDrop", build_waterdrop_blocks(),
                               wd_c, 0, -120, 100, False, 2)
    cloud_sprite = make_sprite("Cloud", build_cloud_blocks(),
                               cl_c, -100, 130, 60, True, 3)
    rain_sprite  = make_sprite("RainDrop", build_raindrop_blocks(),
                               rd_c, -100, 120, 100, False, 1)

    project = {
        "targets": [stage, sun_sprite, water_sprite, cloud_sprite, rain_sprite],
        "monitors": [
            {
                "id": VAR_CYCLE, "mode": "default",
                "opcode": "data_variable",
                "params": {"VARIABLE": "Cycle"},
                "spriteName": None, "value": 0,
                "width": 0, "height": 0,
                "x": 5, "y": 5, "visible": True,
                "sliderMin": 0, "sliderMax": 100, "isDiscrete": True,
            },
            {
                "id": VAR_DROPS, "mode": "default",
                "opcode": "data_variable",
                "params": {"VARIABLE": "drops"},
                "spriteName": None, "value": 0,
                "width": 0, "height": 0,
                "x": 5, "y": 32, "visible": True,
                "sliderMin": 0, "sliderMax": 100, "isDiscrete": True,
            },
        ],
        "extensions": [],
        "meta": {
            "semver": "3.0.0",
            "vm": "2.3.0",
            "agent": "thynk-water-cycle-builder",
        },
    }
    assets = {
        bg_f: bg_s, sun_f: sun_s, wd_f: wd_s, cl_f: cl_s, rd_f: rd_s,
    }
    return project, assets


def main() -> None:
    project, assets = build_project()
    project_json = json.dumps(project, separators=(",", ":"))
    out_path = os.path.join(os.path.dirname(__file__), "water_cycle.sb3")
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("project.json", project_json)
        for fname, content in assets.items():
            zf.writestr(fname, content)
    print(f"Wrote {out_path}")
    print(f"  project.json size : {len(project_json):,} bytes")
    print(f"  assets            : {len(assets)} SVG file(s)")


if __name__ == "__main__":
    main()
