# Session handoff, 2026-09-26: the routed board

Written at the end of the 2026-09-25/26 routing session for whoever opens
this board next. Read it after `.agents/AGENTS.md`. The routing record, run
by run, is [autoroute-log.md](autoroute-log.md); the design record is
[rev0-plan.md](rev0-plan.md), whose dated notes at the top are current.

## Where the board stands

- Fully connected. `kicad-cli pcb drc --severity-all` (KiCad 10.0.6, the
  managed shell): 0 unconnected items, 0 net differences against the
  schematic, 146 clearance findings, 6 dangling vias, 158 footprint-field
  parity warnings. `make clearance-check`: 254 findings against the 256
  baseline, 0 voltage-bearing, unconnected 116 -> 0, no regressions.
- Copper: In1.Cu carries the `/GND` plane and nothing else; B.Cu carries a
  second `/GND` pour and 177 segments (mostly block copper); F.Cu 810 and
  In2.Cu 172 segments; 171 vias. Both zones are full-outline rectangles,
  0.20 mm clearance, 0.25 mm minimum width, thermal reliefs 0.5/0.5 mm,
  priority 0, created through the KiCad MCP server.
- Netclasses: `instrument-taps`, `hv-power-24v` and the board-local
  `kicad/netclass-profiles/camera-gpio-narrow-rails.json`. All three pass
  `orb-weaver-kicad-apply-netclasses --check`. The narrow-rail profile is
  Peter's decision of 2026-09-25: on this board `/+5V` and `/+3.3V` carry
  milliamps, so a 0.20 mm class is right and the shared 0.50/0.30 mm widths,
  which cannot enter SOT-666 or DRY6 pads, are not.
- Committed as `3c479ea` "Found a routing solution": board, project, profile,
  log and guidance. That commit also carries the two importer backups
  `kicad/camera-gpio-interface-pcb.kicad_pcb.pre-ses-*` (94,000 lines);
  `git rm --cached` them if they are not wanted in history. `.gitignore`
  now ignores the pattern for future imports.
- Left uncommitted by the session, all documentation: this file,
  `docs/evidence/freerouting-run{1,2}.log`, the update note in
  `docs/rev0-plan.md`, the "Next" section of `docs/autoroute-log.md`,
  `.agents/PLANS.md`, `.agents/AGENTS.md`, the Makefile help text and
  `.gitignore`.
- **Later on 2026-09-26:** the 146 clearance findings are accepted by a
  `.kicad_dru` rule (open item 2 below); the six dangling vias and one
  stub are removed (`autoroute-log.md`, "Cleanup"); kicad-libs `d50c723`
  fixed the BOM/CPL exporter for repeated sheets and added catalog and
  parity gates; the Makefile's `FAB_TOOL` prefers the checkout's launcher;
  `make fab` exits 0 with all 151 parts. The current task list is
  `.agents/PLANS.md`, "Fabrication readiness".
- **Later still, 2026-09-26:** Peter revised the silkscreen (the v1.0
  wording, `rev0-plan.md` "Open Item"), ran Update PCB from Schematic (field
  parity 0) and poured `/GND` on F.Cu and In2.Cu, so all four layers carry a
  pour. Two repairs followed (`autoroute-log.md`, "Peter's PCB-editor
  pass"): a `/GND` stitching via at (179.0, 93.5) for the `starved_thermal`
  error at J404 pad 2, and the `exclude_from_pos_files` attribute restored
  on H101-H104, which the update had cleared. Every gate passes: ERC 0, DRC
  0 errors / 0 unconnected / 0 parity, 144 clearance warnings,
  `make clearance-check` 252 with no regressions, `make fab` exit 0 with
  151 designators in BOM and CPL. Open items 1-5 below are closed except the
  bring-up documents (6) and the two rotation rows after the first upload.
- **Ordered, 2026-09-26:** five assembled boards from JLCPCB, from commit
  `5ddb425` (`docs/fabrication-log.md`, evidence in
  `docs/evidence/fab-2026-09-26/`). The placement preview showed every part
  oriented correctly; the two rotation rows are verified and handed to
  kicad-libs. `docs/bringup-log.md` is seeded for the arrival.

## What happened, in order

1. `/GND` poured on In1.Cu and B.Cu, filled.
2. `make export-dsn EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"`.
   The `--power-layer` option was added to the kicad-libs exporter this
   session; it keeps Freerouting off the plane layer while GND vias still
   reach the plane.
3. Run 1, Freerouting 2.4.1 headless, one thread, 46 min: KiCad opens
   116 -> 32.
4. Peter rotated U402 by 180 degrees and deleted its tracks (34 opens).
5. The narrow-rail profile, applied; every net then had positive escape
   margin (`../kicad-libs/scripts/dsn_escape_margin.py` on the DSN).
6. Run 2 with the run-1 copper protected, 44 min: opens 34 -> 23.
7. The 23 closed with 17 hand-placed 0.20 mm segments and 5 GND vias from a
   pcbnew script in the managed shell; the dangling `CAM1_OUT_BNC` stub and
   one router-added dangling via removed. Every coordinate is tabulated in
   the log. The scripts were session scratch and were not kept; the log is
   the record.

## How to repeat any step

```sh
make clearance-check                       # gate: compares against kicad/clearance-baseline.json
make export-dsn EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"
FREEROUTING_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx4g" \
  freerouting -de fab/autoroute/<board>.dsn -do fab/autoroute/<board>.ses \
              -mp 100 -mt 1 -dct 0 -da --gui.enabled=false \
              --router.max_threads=1 --router.optimizer.enabled=false   # inside make kicad-shell
make import-ses IMPORT_SES_OPTIONS="--refill"
kicad-cli pcb drc --severity-all --schematic-parity --format json -o fab/autoroute/drc.json kicad/<board>.kicad_pcb
```

Freerouting's own unrouted count is not KiCad connectivity: its
`conductionarea -> pad` entries are pads KiCad connects through the pours.
Import, refill, then read the DRC.

The MCP server was used for inspection and for creating the zones. Writes
that had to match KiCad 10.0.6 exactly (the session import, the repairs)
went through pcbnew in the managed shell, the same mechanism as the
kicad-libs helpers, and were checked with kicad-cli DRC afterwards.

## Open items, in priority order

1. **Review in the PCB editor.** The hand repairs (table in the log), the
   run-1 copper Peter kept, which was protected in run 2 and never
   re-optimised, and the places where router traces cut the B.Cu pour.
2. **Decide the 146 clearance findings.** All require 0.20 mm; 90 sit at
   0.10 mm, the rest 0.11-0.19 mm; all are inside the InstrumentPort block
   (R5xx, U5xx, J5xx) or the USB block (J9xx), i.e. block layouts authored to
   the 0.10 mm fab floor meeting this board's 0.20 mm default class. The
   board rule keeps clearance at error, so DRC cannot come out clean until
   the block layouts are re-routed at 0.20 mm in kicad-libs, or this board
   records that fab-floor copper inside blocks is accepted (mouse-joystick's
   precedent: severity ignore, `make clearance-check` as the gate). Tracked
   in `../kicad-libs/.agents/PLANS.md`.
   **Decided later on 2026-09-26:** accepted as fab-floor copper inside
   blocks. The `.kicad_dru` rule "Low-voltage block clearance is advisory"
   (the mouse-joystick demote form, not severity ignore) turns the 146 into
   warnings; `kicad-cli pcb drc --severity-error` exits 0 and
   `make clearance-check` still counts 254 findings, 0 voltage-bearing, no
   regressions. Recorded in `.agents/AGENTS.md`; the re-route stays a
   kicad-libs task.
3. **Field parity.** 158 `footprint_symbol_field_mismatch` warnings:
   `OW_PART` missing on 142 footprints, `ow_note` on 10, `ReqExactMPN` on 4,
   `ReqMinCurrent` on 2. Update PCB from Schematic with footprint fields
   enabled, then re-run the parity check. No nets differ.
4. **Silkscreen wording**, the plan's one open design decision (recommended
   text in `rev0-plan.md`, "Open Item").
5. `make docs`, `make fab`; promote the Phoenix MCV 6 vertical rotation row
   in `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv` from the
   first JLCPCB placement preview.
6. The bring-up documents the plan lists: `docs/interface-map.md`,
   `docs/design-block-map.md`, `docs/harness-pinouts.md`,
   `docs/validation-plan.md`, `docs/bringup-log.md`.

## Do not

- Re-run the autorouter on the finished board without a reason. With
  everything protected it can only add copper, and it takes 45 minutes.
- Re-apply a netclass profile with `--replace-profile-patterns` here; the
  three profiles compose and all pass `--check`.
- Treat the kicad-libs pin-neck work as this board's problem. It is a
  kicad-libs task; this board is its validation target through a copy with
  the narrow-rail profile reverted, nothing more.
