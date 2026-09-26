# Autoroute Log

Board-side record of Freerouting runs on `camera-gpio-interface-pcb`, kept the
way `mouse-joystick-pcb/docs/autoroute-log.md` is. The shared method, the
router's measured behaviour and the helper commands are in
`../kicad-libs/docs/freerouting-autorouting.md`; this file records what was
done to this board and what the numbers were. Router counts are not KiCad
connectivity: read the "KiCad verification" section of each run before the
router's own tallies.

## Run 1, 2026-09-25: first full-board pass

### Board before routing

- 158 footprints, 790 track segments, 120 vias, no zones. The five design
  block layouts were applied as placed; everything else was unrouted.
- Outline as placed: 100 × 60 mm (x 100–200 mm, y 65–125 mm in board
  coordinates), 5 mm corner radius. The plan's "roughly 120 × 80 mm" was an
  estimate; the placed board is smaller.
- Four copper layers, all typed signal in Board Setup.
- `make clearance-baseline` had saved `kicad/clearance-baseline.json`:
  116 unconnected items, 256 low-voltage clearance advisories inherited from
  the blocks, 0 voltage-bearing findings, 30 dangling-via warnings.

### Steps

1. Poured `/GND` on **In1.Cu**, the solid ground plane the plan asks for, and
   on **B.Cu**, the layer Freerouting barely uses. Both zones cover the whole
   outline (KiCad clips them to the edge clearance): 0.2 mm clearance,
   0.25 mm minimum width, thermal reliefs with 0.5 mm gap and 0.5 mm spokes,
   priority 0. Filled before export.
2. Exported with the kicad-libs exporter:

   ```sh
   make export-dsn EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"
   ```

   384,924 bytes; 5 netclasses; 737 pre-routed wires and 121 vias, 857 items
   marked `protect`; 2 planes rebuilt from the real fills with 214 windows;
   147 GND pins, 22 of them `@`-suffixed duplicates (BNC shells, terminal
   grounds, the LDO thermal pad). For run 1 itself the `--power-layer` edit
   was made by hand in the DSN (`(layer In1.Cu (type signal))` →
   `(type power)`); the option was added to `scripts/export_dsn.py` the same
   evening; re-exporting the pre-routing board with it reproduces the run-1
   DSN exactly, apart from the file path on its first line.
3. Freerouting 2.4.1 (the kicad-libs Guix package, OpenJDK 25), headless, from
   the KiCad manifest shell, stock costs, one thread:

   ```sh
   FREEROUTING_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx4g" \
   freerouting -de fab/autoroute/camera-gpio-interface-pcb.dsn \
               -do fab/autoroute/camera-gpio-interface-pcb.ses \
               -mp 100 -mt 1 -dct 0 -da --gui.enabled=false --router.max_threads=1
   ```

4. `make import-ses IMPORT_SES_OPTIONS="--refill"`, then `make clearance-check`
   and `kicad-cli pcb drc --severity-all` (managed shell) for the item list.

### Why In1.Cu is exported as a power layer

Freerouting does not treat a ground plane on a signal layer as an obstacle.
`BoardRules.ignoreConduction` defaults to true and is settable only from the
GUI, and the ">50 % conduction area" auto-detection in `DsnFile` only fixes
the plane in place; it does not change the layer's `isSignal` flag, so the
router keeps laying traces across the plane and KiCad's refill then cuts it
into islands (the 48-segment result recorded for mouse-joystick-pcb). A
Specctra `(type power)` layer is different: `AutorouteControl` forces it
inactive, `MazeSearchEngine` refuses to expand traces onto it, but a drill
onto it is allowed when the conduction area there belongs to the net being
routed. Result on this board: **0 wires of any net on In1.Cu**, GND reached
through vias. The B.Cu pour stayed a signal layer and took 12 new segments,
which the refill routes around.

### Router numbers (not KiCad opens)

| Stage | Result |
| --- | --- |
| Fanout | 513 SMD pins, 317 needing fanout; 20 passes, 423 s; escaped 352/513 (68.6 %) |
| Routing | 128 items entering routing; best score reached at pass 8, stopped by the stagnation rule after pass 18; 75 unrouted, 411 violations; 2234 s |
| Optimizer | 1 pass, 550 s, no change |
| Wall clock | 46 min 40 s, single thread |

Session file: 674 wires on F.Cu, 163 on B.Cu, 43 on In2.Cu (protected block
copper included), 164 vias, **none on In1.Cu**. The router's 75 unrouted were
54 `/GND` (mostly `conductionarea → pad` entries for BNC shells, terminal
grounds and the LDO thermal vias, which KiCad connects through the pours),
11 pin-pair entries inside the camera blocks' USBLC6 arrays (pins 1–6 and 3–4;
KiCad reports none of them, so the block copper joins them and the router's
graph did not see it), 5 `/+5V`, 2 `/+3.3V`, 2 `VBUS`, 1 `SYNC_RAW`.

### Import

Tracks 910 → 1282: F.Cu 632 → 782, In2.Cu 0 → 166, B.Cu 158 → 170; vias
120 → 164. Nine `+5V` vias came back re-drilled at the netclass 0.40 mm and
were restored to 0.60/0.30 mm by the importer. Footprint positions and zone
count unchanged. Backup:
`kicad/camera-gpio-interface-pcb.kicad_pcb.pre-ses-20260925-200715`.

### KiCad verification

- `make clearance-check`: 256 clearance findings across 86 net pairs, equal to
  the baseline; 0 voltage-bearing; no new or worsened findings; unconnected
  **116 → 32**.
- `kicad-cli pcb drc --severity-all` (KiCad 10.0.6): 147 clearance errors
  (the block-inherited 0.10–0.20 mm advisories, counted once per track here
  and per segment by the clearance check), 8 dangling vias (30 before the
  pours; 7 are block escape stubs on `USB_D+`, `SYNC_IN` and `CAMx_*_INST`,
  1 is the `+3.3V` via listed below), 32 unconnected items, 0 schematic
  parity issues. Report: `fab/autoroute/drc-run1.json` (gitignored).

### The 32 remaining opens

All local. `../kicad-libs/scripts/dsn_escape_margin.py` on the exported DSN
explains three of the five groups before any run: `PWR_5V` (0.50 mm /
0.25 mm) has **−0.178 mm** escape margin at a SOT-666 pin 5, `PWR_3V3`
(0.30 / 0.20) has **0.000 mm** at a DRY6 pin, and the default class
(0.20 / 0.20) has 0.049–0.050 mm at every DRY6 and SOT-666 pin.

| Group | Items | Cause | Repair |
| --- | --- | --- | --- |
| LV541A grounded inputs: U504 pads 2–9 and U503 pads 2–7 (x = 183.85 mm, 0.5 mm pitch), plus their two existing GND stubs at x = 184.43 mm | 14 | adjacent same-net fine-pitch pads: the router neither runs a trace along a pad row nor finds room to fan each pad out | one 0.2 mm F.Cu track down each pad column from the first to the last grounded pad, joined to the stub beside it; the end pads keep 0.25 mm to the neighbouring signal pads |
| `+5V` to the ESD arrays U301, U402, U403 and to the three camera blocks (the 0.925 mm block stubs at y = 78.4 mm) | 5 | `PWR_5V` at 0.50 mm cannot enter a 0.5 mm-pitch SOT-666 pad; no layout satisfies it | a decision: the rail carries under 20 mA, so either give it a narrower local class or hand-route 0.3 mm necks from the block stubs and accept the width findings |
| `+3.3V` into U401 pin 6 (162.3, 105.5) and the dangling via at (163.1, 108.6) | 2 | `PWR_3V3` 0.30 mm has zero margin at the DRY6 pin | hand-route the last millimetre straight out of the pad at 0.30 mm; join the via to the B.Cu run |
| Loose board-level GND pads: D201-1, D301-1, D302-1, D401-1, U301-2, U401-1, U402-2, U403-2, U901-2 and the stub near U401 | 10 | 0402 and 0.5 mm-pitch GND pads with no room for the router's 2.5 mm escape stub plus a 0.6 mm via | short F.Cu tracks to the nearest GND copper, or a via into the In1.Cu plane, as the mouse-joystick rescue did |
| `SYNC_RAW`: two F.Cu segments 0.9 mm apart near U301-4 | 1 | fanout stopped short | join the two segments |

### Files

`fab/autoroute/` (gitignored): `run1.dsn`, `run1.ses`, `freerouting-run1.log`,
`drc-run1.json`. The board and project in `kicad/` are the imported result.

## Run 2, 2026-09-25: narrower rail classes, then local repairs

### Board before routing

The run-1 result plus one user edit: U402 (the CAM1/CAM2 output ESD array)
rotated by 180 degrees with its tracks deleted. 34 unconnected items, one
dangling 0.46 mm `CAM1_OUT_BNC` stub, 147 clearance advisories.

### Decision: narrower local classes where a class cannot reach its pins

The escape-margin analysis of run 1 said `PWR_5V` (0.50 / 0.25 mm) could not
enter a SOT-666 pin 5 (-0.178 mm) and `PWR_3V3` (0.30 / 0.20 mm) had zero
margin at a DRY6 pin. The user's rule for this board: when a net's class is
wider than the pin it must connect to, use a narrower local class rather
than a hand-routed neck. Both rails feed logic and ESD arrays only.

Implemented as the board-local profile
`kicad/netclass-profiles/camera-gpio-narrow-rails.json`, applied with
`orb-weaver-kicad-apply-netclasses`: `PWR_5V_NARROW` (priority 9, pattern
`/+5V`) and `PWR_3V3_NARROW` (priority 19, pattern `/+3.3V`), each 0.20 mm
track, 0.20 mm clearance, 0.6/0.3 mm via. They sit one priority step above
the shared `PWR_5V`/`PWR_3V3`, so KiCad's aggregate class for the two root
nets takes their geometry while `hv-power-24v` and `instrument-taps` still
pass `--check`. The exported DSN then shows
`PWR_5V_NARROW,PWR_5V,PWR_5V_LOCAL (width 200) (clearance 200)`, and every
net has positive escape margin (smallest: `/+5V` at 0.022 mm, U301-5).

### Steps

1. `make export-dsn EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"`
   from the run-1 board: 1013 pre-routed wires and 164 vias, 1176 items
   protected (block copper and the run-1 routing the user kept).
2. Freerouting as in run 1 plus `--router.optimizer.enabled=false` (the
   run-1 optimizer pass changed nothing in 9 minutes).
3. `make import-ses IMPORT_SES_OPTIONS="--refill"`, `make clearance-check`,
   kicad-cli DRC.
4. Local repairs with a pcbnew script in the managed KiCad 10.0.6 shell
   (listed below), refill, DRC again.

### Router numbers (not KiCad opens)

| Stage | Result |
| --- | --- |
| Fanout | 513 SMD pins, 246 needing fanout; escaped 376/513 (73.3 %, run 1: 68.6 %); 150 s |
| Routing | 90 items entering routing (run 1: 128); 67 unrouted, 387 violations; 2637 s |
| Wall clock | 44 min 5 s, single thread, no optimizer |

Session file: 732 wires on F.Cu, 165 on B.Cu, 146 on In2.Cu, 172 vias,
none on In1.Cu. Of the 67 router residuals, 49 were `/GND`
`conductionarea` entries KiCad resolves through the pours, 3 were the
camera block's USBLC6 pin pairs KiCad already sees connected, and the rest
`VBUS` and `TRIG_RAW` block-internal pairs. `/+5V`, `/+3.3V` and `SYNC_RAW`
no longer appear.

### Import and KiCad verification

Tracks 1275 -> 1331 (F.Cu 778 -> 810, In2.Cu 166 -> 172, B.Cu 168 -> 177),
vias 163 -> 172, placement unchanged. DRC: 146 clearance advisories, 7
dangling vias, 1 dangling track (the user's stub), **23 unconnected items**
(run 1: 32). `make clearance-check`: 254 findings, no new or worsened, the
only regression being the dangling-track warning from the user's edit.

### The 23 remaining opens and their repairs

Each was read from the copper around it (pads, tracks, vias, all layers)
before the segment was placed. All new tracks are 0.20 mm; all new vias are
0.6/0.3 mm through-vias into the In1.Cu plane. Widths and clearances were
checked by hand against the 0.20 mm netclass floor and confirmed by DRC.

| Open | Repair |
| --- | --- |
| D201-1 and the C1001-2/C1002-2 GND cluster (power LED, LDO caps) | F.Cu (109.550, 84.055) -> (109.514, 83.250) -> (109.480, 82.500); via at (109.514, 83.250) |
| D301-1 (126.000, 110.450), D302-1 (150.000, 110.450) | F.Cu stub 0.85 mm outward, via at (126.000, 111.300) and (150.000, 111.300) |
| U402-2 (138.000, 95.925), after the rotation | F.Cu to (138.000, 97.000), via there |
| U301-2 (138.000, 119.925) | F.Cu to (138.000, 121.000), via there |
| U403-2 (176.075, 106.000) | F.Cu (176.075, 106.000) -> (175.750, 106.000) -> (175.510, 106.240) -> the router's GND via at (174.498, 106.007), skirting the CAM3_OUT_BNC via and the SYNC_OUT_BNC track; pad 3 sits 0.197 mm below pad 2, so the exit had to be sideways |
| U504 pads 2-9, U503 pads 2-7 (LV541A grounded inputs, 0.5 mm pitch) | one F.Cu track down each pad column, (183.850, 87.500)->(183.850, 91.000) and (183.850, 94.000)->(183.850, 96.500), plus a link between two GND pads into the thermal pad 21: (183.850, 89.250)->(185.000, 89.250) and (183.850, 95.250)->(185.000, 95.250) |
| `SYNC_RAW`: U301-4 to the input block's R1102-1 | F.Cu (138.537, 118.150) -> (138.537, 115.350) -> (138.500, 114.760); 0.236 mm from the `+5V` via at (137.901, 117.239) |
| `+5V` islands: camera block 1 (U704) vs block 2 (U1205) | In2.Cu (132.000, 77.500) -> (150.000, 77.500) between the two blocks' through-vias; the corridor held nothing else |
| `+5V` islands: USB/LDO vs U402/U301 | In2.Cu (112.990, 88.726) -> (122.572, 92.133) between two through-vias, clearing the J402 shell pad by 2.5 mm and the `+3.3V` In2 run by 0.43 mm |
| dangling `CAM1_OUT_BNC` stub (137.462, 94.975) -> (137.922, 94.975) | removed |
| router-added dangling via on `CAM2_L2_INST` at (183.094, 103.027), mid-track on F.Cu | removed; the F.Cu path through that point is continuous |

### Result

- kicad-cli DRC, all severities: **0 unconnected items**, 0 schematic
  parity issues, 146 clearance advisories (all block-inherited 0.10-0.20 mm
  pairs in the InstrumentPort and camera blocks; the count is unchanged by
  the repairs and every item sits on block copper), 6 dangling vias, all six
  block escape stubs that were on the board before routing.
- `make clearance-check`: 254 findings against a 256 baseline, 0
  voltage-bearing, unconnected 116 -> 0, no new or worsened findings.
- In1.Cu carries the `/GND` plane and nothing else; B.Cu carries the second
  pour and 177 segments, mostly block copper.

### Files

`fab/autoroute/` (gitignored): `run2.dsn`, `run2.ses`, `freerouting-run2.log`,
`drc-run2.json` (after import), `drc-run2-repaired.json`, `drc-final.json`.
Importer backups `kicad/*.kicad_pcb.pre-ses-*` hold the board before each
import. The repair script's coordinates are the table above.

### Next

1. Review in the PCB editor: the hand repairs above, the run-1 copper the user
   kept (never re-optimised), and the B.Cu pour where router traces cut it.
2. **The 146 remaining clearance findings.** All require 0.20 mm (the default
   class); 90 sit at 0.10 mm, the rest between 0.11 and 0.19 mm. Every one is
   inside the InstrumentPort block (R5xx, U5xx, J5xx: `+3.3V`/`GND`/`~OEn`
   and `DIGn_BUF` pairs) or the USB block (J9xx). They are the block layouts'
   0.10 mm authoring floor meeting this board's 0.20 mm class, not routing.
   This board's rules keep `rule_severities.clearance` at error, so they
   block a clean DRC until either the block layouts are re-routed at 0.20 mm
   in kicad-libs or this board records a decision to accept the fab-floor
   copper (the mouse-joystick precedent is the clearance check as the gate).
3. Schematic parity: `kicad-cli pcb drc --schematic-parity` reports 158
   `footprint_symbol_field_mismatch` items ("Missing symbol field ... in
   footprint": `OW_PART` on 142 footprints, `ow_note` on 10, `ReqExactMPN` on
   4, `ReqMinCurrent` on 2) and no net differences. Update PCB from
   Schematic with footprint fields enabled clears them.
4. Silkscreen wording, `make docs`, `make fab`; promote the Phoenix MCV 6
   vertical rotation row from the first JLCPCB preview.
5. Housekeeping: the importer backups `kicad/*.kicad_pcb.pre-ses-*` are not
   ignored by `.gitignore`; delete them or add the pattern before committing.
6. Feed back to kicad-libs: the LV541A grounded-input pattern and the
   0402/SOT-666 GND pads next to BNCs are the two things this router cannot
   fan out; a block-level GND via per package would remove most of them. The
   pin-neck proposal that would let the shared rail classes stay wide is
   recorded in kicad-libs (`docs/freerouting-autorouting.md`, "Pin necks",
   and its `.agents/PLANS.md`).

## Cleanup, 2026-09-26: unused block escape vias

After the fabrication-readiness assessment (`.agents/PLANS.md`) and per the
kicad-libs layout convention written the same day (block port stubs must not
leave dangling vias on a board), the six `via_dangling` items, all
block-authored port escape vias the router did not use, were removed with a
pcbnew script in the managed KiCad 10.0.6 shell. Each was checked to meet
tracks on F.Cu only before removal. Removing the `SYNC_IN` via left its
1.00 mm F.Cu stub with an open end, which was removed the same way; the
stub's far end at (139.500, 109.000) is a junction of two other segments.
Zones refilled and the board saved by pcbnew. The scripts were session
scratch; this table is the record.

| Item | Net | Position (mm) |
| --- | --- | --- |
| via 0.6/0.3 | `/power/usb2_vertical/USB_D+` | (106.500, 93.500) |
| via 0.6/0.3 | `/power/usb2_vertical/USB_D+` | (105.500, 94.500) |
| via 0.6/0.3 | `/SYNC_IN` | (138.500, 109.000) |
| via 0.6/0.3 | `/CAM2_L3_INST` | (157.500, 82.250) |
| via 0.6/0.3 | `/CAM2_L0_INST` | (156.500, 82.250) |
| via 0.6/0.3 | `/CAM1_L3_INST` | (132.500, 82.250) |
| 0.20 mm F.Cu segment | `/SYNC_IN` | (138.500, 109.000) -> (139.500, 109.000) |

Result: 170 vias, 1174 segments. kicad-cli DRC at all severities: 144
clearance warnings (under the "Low-voltage block clearance is advisory"
rule of the same day), 0 dangling items, 0 unconnected, 0 net differences,
158 field-parity warnings. `make clearance-check`: 252 findings against the
256 baseline, 0 voltage-bearing, no new or worsened findings. `make fab`:
exit 0, `bom_rows=26 resolved=26 designators=151`, `position_rows=151`.
