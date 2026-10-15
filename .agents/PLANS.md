# Camera GPIO Interface PCB Plan

Use this file for multi-step or cross-session work in this repository.

## Current Focus

- 2026-10-15: **v1.0 tagged and documented.** The repository is tagged
  `v1.0` on the documented state of the fabricated revision (the copper is
  the 2026-09-26 order's, `5ddb425`; since then the block sheets were
  regenerated from the library with the copper kept, the PCB changing in
  fields, paths, group ids and the private nets' names). The documentation
  program run from kicad-libs (its PLANS, 2026-10-12 to 2026-10-15) is
  finished here too: a page per placed block with the recorded netlist
  check, `kicad/board.yaml` with the three sheets' recipes and every net's
  meaning (so `docs/interface-map.md` carries meanings and
  `docs/generated/subsystems/` the inputs, outputs and power pages), the
  dimensioned outline and mounting hole drawing, the BOM with its sourcing,
  the board view and the Pages site
  (https://peterpolidoro.github.io/camera-gpio-interface-pcb/). `make docs`
  is a no-op until a KiCad source changes; `make docs-check` gates a tag;
  `make site` builds the site strictly. Next here: the bring-up results in
  `docs/bringup-log.md` once the boards are measured, and the rig software
  changes of `rev0-plan.md`.
- 2026-09-26 (evening): **v1.0 ordered from JLCPCB, five assembled boards**,
  from commit `5ddb425`; the record is `docs/fabrication-log.md`, the
  evidence `docs/evidence/fab-2026-09-26/`. The placement preview showed
  every part oriented correctly, which verifies the MCV 6 vertical and
  0402 LED rotation rows; handed to kicad-libs in
  `../kicad-libs/tmp/camera-gpio-interface-pcb-rotation-evidence-2026-09-26.md`.
  Next here, when the boards arrive: `docs/bringup-log.md` (seeded), then
  the bring-up documents and the rig software changes in `rev0-plan.md`.
- 2026-09-26: fabrication readiness for JLCPCB; the checklist is the
  "Active Task: 2026-09-26 Fabrication readiness" section below, which
  supersedes the Layout item of the Rev 0 task. The three blockers are
  closed (kicad-libs `d50c723` fixed the exporter and added the catalog and
  parity gates; the clearance decision is a `.kicad_dru` rule) and
  `make fab` exits 0 with all 151 parts in the BOM and CPL. Left before the
  order: review in the PCB editor, silkscreen wording, field parity, the
  order options, `make docs`, housekeeping; after the upload, the two
  rotation rows.
- 2026-09-25: repository scaffolded (Makefile, `.guix/`, agent guidance, KiCad
  project in `kicad/` with library tables, `instrument-taps` and
  `hv-power-24v` netclass profiles). Next: the schematic, per the "Schematic
  Structure" section and the resume checklist of `docs/rev0-plan.md`.
- Keep connector contracts in `board-interfaces` and reusable assets in
  `kicad-libs`; record board-specific decisions, validation, fabrication and
  bring-up here.

## Verification

- `make test`
- `make agent-reflection`
- `make validate-db`
- KiCad ERC/DRC when the design is ready; `make docs-check` before tagging

## Active Task: 2026-09-25 Rev 0 schematic and layout

The design record is `docs/rev0-plan.md`; its resume checklist is the task
list. Status here mirrors it.

- [x] Confirm the kicad-libs state (2026-09-25): committed and pushed at
      `4331370`; `blackfly_s_gpio_channel_mcv6_vertical` and
      `quadrature_encoder_input_5v_sn74lvc2g17` pass the single-block check
      with 0 errors and 0 warnings; the other three blocks are unchanged since
      their 2026-09-24 verification.
- [x] Scaffold (2026-09-25): `orb-weaver-kicad-init-repo`,
      `orb-weaver-kicad-create-project --name camera-gpio-interface-pcb`,
      Makefile and `.guix/` aligned with `mouse-joystick-pcb` (no KiCad
      overlay; the pinned channel is 10.0.6), netclass profiles applied. The
      user commits.
- [x] Schematic (2026-09-25): sheets power, inputs (with
      `logic_input_2ch_5v_schmitt_sn74lvc2g17`), outputs, and the three
      camera blocks and the InstrumentPort block on the root; nine ESD arrays
      with `VBUS` on `+5V`; every unused LV541A input to ground; holes and
      fiducials on the root; annotated per sheet (sheet number × 100); ERC 0
      violations; netlist read pin by pin, InstrumentPort channels grouped per
      camera and the plan table rewritten to match.
- [ ] Layout: four layers, 100 × 60 mm outline as placed (the plan
      estimated 120 × 80 mm), `INSTRUMENT`
      class on the `_INST` nets, DRC clean with `rule_severities.clearance`
      at error. Initial placement done 2026-09-25 (158 footprints, block
      layouts applied: 910 track segments, 121 vias, no zones yet).
      Routing helpers from kicad-libs are wired in: `make clearance-baseline`
      saved `kicad/clearance-baseline.json` (256 low-voltage clearance
      advisories inherited from the blocks, 0 voltage-bearing, 116 opens);
      `make export-dsn` wrote `fab/autoroute/camera-gpio-interface-pcb.dsn`
      (737 pre-routed wires, 121 vias, 5 netclasses). Autorouted 2026-09-25, run 1 in
      `docs/autoroute-log.md`: `/GND` poured on In1.Cu (the solid plane) and
      B.Cu; exported with
      `EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"`
      (the new exporter option keeps the router off the plane layer);
      Freerouting 2.4.1 headless, one thread, 46 min; `make import-ses
      IMPORT_SES_OPTIONS="--refill"`; `make clearance-check` unchanged
      against the baseline, opens 116 -> 32, no wire of any net on In1.Cu.
      Run 2 the same day after the user rotated U402: board-local profile
      `kicad/netclass-profiles/camera-gpio-narrow-rails.json` gives `/+5V`
      and `/+3.3V` 0.20 mm classes that fit their SOT-666 and DRY6 pins
      (the user's rule: a class wider than its pin gets a narrower local
      class); re-routed with the run-1 copper protected, opens 34 -> 23;
      the 23 closed by hand with the tracks and vias listed in the log.
      **DRC: 0 unconnected, 146 block-inherited clearance advisories, 6
      block dangling vias; clearance check clean against the baseline.**
      Next: review in the PCB editor; decide the 146 block-inherited
      clearance findings (InstrumentPort and USB block copper at the 0.10 mm
      fab floor against the 0.20 mm default class; see the log's "Next");
      clear the 158 footprint-field parity warnings (`OW_PART` and three
      other symbol fields) with Update PCB from Schematic; silkscreen; `make docs`.
- [ ] Silkscreen wording, the one open design decision.
- [ ] Docs alongside: `docs/interface-map.md`, `docs/design-block-map.md`,
      `docs/harness-pinouts.md`, `docs/validation-plan.md`,
      `docs/bringup-log.md`; then `make docs`.
- [ ] `make fab`; promote the Phoenix MCV 6 vertical rotation row in
      `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv` from the JLCPCB
      placement preview.

## Active Task: 2026-09-26 Fabrication readiness for JLCPCB

Assessed 2026-09-26 from the committed board `c16b534`, in the managed KiCad
10.0.6 shell: ERC 0 violations at all severities (once the kicad-libs catalog
was rebuilt, see below); DRC 0 unconnected, 0 net differences, 146 clearance
errors (all block-inherited), 6 dangling block-stub vias, 158 field-parity
warnings; `make clearance-check` 254 findings against the 256 baseline, 0
voltage-bearing, no regressions. All 158 footprints are on F.Cu; 4 M3 holes
and 3 fiducials are placed; the outline is 100 x 60 mm, 1.6 mm, four layers.
A fab dry run with `--skip-erc --skip-drc` into a scratch directory built
gerbers, drill, BOM and CPL; the first two items came out of it.

Blocking `make fab` and the assembly order:

- [x] **BOM and CPL cover 109 of the 151 electrical parts.**
      `kicad-libs/scripts/export_vendor_bom.py` walks each `*.kicad_sch` file
      once, so the camera block sheet placed three times contributes only its
      7xx instance; `format_jlcpcb_pos.py --bom` then filters the 154-row
      position export to those designators. Camera blocks 2 and 3 (J1201,
      J1401, U12xx, U14xx, R12xx, R14xx, C12xx, C14xx, D1201, D1401) are in
      neither file. Fix in kicad-libs (read instances through
      `kicad-cli sch export bom`, or expand the sheets' `instances`), re-run,
      expect `position_rows=151` and 26 BOM groups with the kicad-cli counts
      (16 x 100 nF, 7 LEDs, 3 MCV 6, 10 USBLC6, 3 x 1G07, ...).
      mouse-joystick-pcb never hit this: each of its blocks is placed once.
      Requested from the kicad-libs session on 2026-09-26 in
      `../kicad-libs/tmp/camera-gpio-interface-pcb-requests-2026-09-26.md`
      (P0-1, with the position-file guard P0-2, the catalog staleness check
      P0-3, `--schematic-parity` in the fab tool P1-4, the pending rotation
      rows P1-5 and the template rule P2-7). Note: this board's `make fab`
      runs the packaged launcher (`FAB_TOOL ?= orb-weaver-kicad-fab`), so a
      launcher change needs a channel-pin bump or `FAB_TOOL` pointed at the
      checkout like `DOCS_TOOL` is.
      Done 2026-09-26 in kicad-libs `d50c723` (reply in
      `../kicad-libs/tmp/kicad-libs-reply-camera-gpio-interface-pcb-2026-09-26.md`):
      the exporter expands `instances/project/path`, the position formatter
      reports and gates dropped rows, the launcher gains the catalog check,
      `--schematic-parity` and a parity gate; this board's Makefile now
      prefers the checkout's launcher (`FAB_TOOL`, the template form).
      `make fab` here: `bom_rows=26 resolved=26 designators=151`,
      `position_rows=151 dropped_by_bom=3=FID101,FID102,FID103
      rotation_corrected=28 footprints_without_rotation_entry=1`,
      `drc_errors=0 parity_differences=0 field_mismatches=158`, exit 0.
- [x] **Rebuild the kicad-libs catalog before every `make fab`.**
      `../kicad-libs/db/build/orb_weaver_parts.sqlite` (gitignored) predated
      the six parts this board added on 2026-09-23/24; with it stale, ERC
      reported 83 library warnings (11 "not found", 72 "doesn't match") and
      the BOM left 11 rows unresolved. `make build-db` in kicad-libs (run
      2026-09-26, no tracked-file changes) cleared both. Repeat after any
      `internal_parts.csv` or vendor-map edit; `make validate-db` here
      requires the file but does not check its age.
      Done 2026-09-26: since kicad-libs `d50c723`, `build_db.py` writes
      `db/build/catalog-manifest.json` and the BOM exporter, `make
      validate-db` and the fab launcher check it (the launcher rebuilds when
      the checkout is writable). Rebuilt here after that commit.
- [x] **Decide the 146 clearance findings.** `make fab` runs
      `kicad-cli pcb drc --severity-error --exit-code-violations`, which
      exits 5 on them. Recommended for this board: a scoped `.kicad_dru`
      rule in the mouse-joystick form (demote `clearance` to warning where
      neither side is a voltage-bearing class; on this board that is every
      pair), keep `rule_severities.clearance` at error so an unmatched
      finding fails loud, keep `make clearance-check` as the gate, and record
      the decision in `.agents/AGENTS.md` (the "stays at error" rule), the
      handoff and the kicad-libs plan. The alternative, re-routing the
      InstrumentPort and USB block layouts at 0.20 mm, is tracked in
      `../kicad-libs/.agents/PLANS.md`.
      Done 2026-09-26: rule "Low-voltage block clearance is advisory" added
      to `kicad/camera-gpio-interface-pcb.kicad_dru` after the SMD pad-to-pad
      rule; managed-shell DRC now 146 clearance warnings, 0 errors, 0
      unconnected; `kicad-cli pcb drc --severity-error --exit-code-violations`
      exits 0; `make clearance-check` 254 findings, 0 voltage-bearing, no
      regressions. Decision recorded in `.agents/AGENTS.md`, the handoff and
      the rev0 plan's 2026-09-26 note.

Before the order:

- [x] **Silkscreen wording.** Present on F.SilkS: title `camera-gpio-interface-pcb
      v1.0 09/26`, `CAMERA 1..3`, the block wire colours BRN..GRN over the
      terminals, `CAMERA n OUT`, `TRIG IN`, `SYNC IN`, `SYNC OUT`, `50-PIN`,
      `+5V`, `+3.3V`. Missing against the plan's recommendation: terminal
      numbers and line numbers (`1 GRN L3` ...), the camera line each input
      reaches (`TRIG IN -> CAM LINE 3`, `SYNC IN -> CAM LINE 0 + SYNC OUT`),
      `3.3 V LOGIC` at the BNC groups, and `DIGITAL-50 / 3.3 V / OBSERVE ONLY`
      with a pin 1 mark at the FFC. Reference designators overlap each other
      in the camera-block rows and the InstrumentPort column; keep, shrink or
      hide them. Silk DRC (text height 1.0 mm, thickness 0.15 mm, silk over
      copper) is clean today.
      Decided 2026-09-26 by Peter: the silk as revised in the PCB editor is
      the v1.0 wording (`CAMn OUT`, `TRIG IN`, `SYNC IN`, `SYNC OUT`,
      `USB 5V`, `+5V`, `+3.3V`, `50-PIN`, title, block wire colours;
      designators hidden). Recorded in `docs/rev0-plan.md`, "Open Item".
- [x] **Field parity.** Update PCB from Schematic with footprint fields
      enabled clears the 158 `footprint_symbol_field_mismatch` warnings
      (`OW_PART` 142, `ow_note` 10, `ReqExactMPN` 4, `ReqMinCurrent` 2).
      Warnings only; `make fab` does not gate on them.
      Done 2026-09-26 by Peter: parity 0. Side effect: the update rewrote
      footprint attributes from the symbols, which carry no
      exclude-from-position flag, so H101-H104 lost `exclude_from_pos_files`
      and the kicad-libs position guard failed `make fab` with
      `dropped_by_bom=H101,H102,H103,H104`; restored with pcbnew. Re-check
      after any future Update PCB from Schematic.
- [ ] **Review in the PCB editor**: the run-2 hand repairs (table in
      `docs/autoroute-log.md`), the protected run-1 copper, the B.Cu pour
      cuts. The 6 dangling block-stub vias (USB_D+ x2, SYNC_IN,
      CAM1_L3_INST, CAM2_L3_INST, CAM2_L0_INST) and the 1 mm `SYNC_IN` stub
      their removal exposed were removed 2026-09-26 with pcbnew in the
      managed shell; coordinates in `docs/autoroute-log.md`, "Cleanup".
      DRC now has 0 dangling items; `make clearance-check` 252 findings, no
      regressions.
      Peter's PCB-editor pass, 2026-09-26: silkscreen revised, `/GND` poured
      on F.Cu and In2.Cu as one zone (0.50 mm clearance, 0.25 mm thermal gap
      and spokes), Update PCB from Schematic. The pour left J404 pad 2's
      In2.Cu spokes on an isolated pocket (`starved_thermal`, error); a
      `/GND` stitching via at (179.0, 93.5) ties the pocket to the In1.Cu
      plane. Table in `docs/autoroute-log.md`, "Peter's PCB-editor pass".
- [x] **`make fab`** once the three blockers are closed, then read
      `fab/camera-gpio-interface-pcb/reports/*-jlcpcb-rotations.txt`. Today's
      dry run: DRY6, SOT-666 and RKS corrected +270 (verified), MCV 6 +180
      (inferred), and `LED_0402-1005_KNB` has **no rotation row**: seven
      polarised LEDs to check in the JLCPCB placement preview. Promote the
      MCV 6 row and add the LED row in
      `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv`.
      Done 2026-09-26: `make fab` exit 0 into `fab/camera-gpio-interface-pcb/`
      (gitignored; regenerate after silkscreen and field-parity edits). The
      rotation report matches the dry run. Still pending, after the upload:
      the two rotation rows (kicad-libs `.agents/PLANS.md` step 0b).
- [x] **Order options to choose**: 4 layers, 1.6 mm, 100 x 60 mm; top-side
      assembly only; through-hole parts are 6 BNC and 3 MCV 6 (the USB-C
      pegs are 0.6 mm slots); surface finish (unspecified in the project, as
      on mouse-joystick-pcb); "Confirm Parts Placement" on, because of the
      inferred MCV 6 row and the unverified LEDs. Every BOM line is in the
      JLCPCB inventory export of 2026-09-24; the 88 BNCs limit a run to 14
      boards, everything else allows more.
      Done 2026-09-26: five boards ordered from commit `5ddb425`
      (`docs/fabrication-log.md`); every part oriented correctly in the
      preview. The finish and the other order-page options are not
      recorded; the log says which to fill in.
- [ ] Housekeeping: `git rm --cached kicad/*.kicad_pcb.pre-ses-*` (two
      94,000-line importer backups are still tracked although now ignored);
      `make docs` (never run: `docs/generated/` is absent and the README
      status still says "routing not started"); `make docs-check` before
      tagging.
      Done 2026-09-26: `make docs` run, `docs-check` up to date, README
      status rewritten for v1.0. The two importer backups are still
      tracked; remove them at the next convenient commit if unwanted.

After the order, not blocking it: `docs/interface-map.md`,
`docs/design-block-map.md`, `docs/harness-pinouts.md`,
`docs/validation-plan.md`; `docs/bringup-log.md` is seeded 2026-09-26 with
the arrival inspection and the plan's bench measurements; the three plugs,
cables and four BNC leads listed in the plan's Sequence step 5 (ordered or
not is unrecorded, see `docs/fabrication-log.md`). After the boards arrive:
tag the ordered commit `5ddb425` as v1.0 if that is the convention.

## Planned Task — OBS-HW-CAMERA: camera electrical observation and native-record correlation (2026-09-29)

The new [board observability plan](../docs/observability-plan.md) owns this
workstream's detailed queue. The [central roadmap](../../orb-weaver-context/context/experimental-system-observability-plan.md)
owns cross-repository gates and parallel workstreams. Existing dated board
decisions and measured bring-up records remain authoritative; this entry
records intent and no new hardware validation.

- [ ] Claim `.1` and prepare overlay, harness and pending validation documents
      from the current design record and camera settings (G0).
- [ ] On actual board arrival, complete `.2` with the existing per-unit
      bring-up procedure and qualified adapter/cable path (G1).
- [ ] Coordinate `.3` with `OBS-HOST`: correlate trigger/camera output edges
      with native frame/acquisition records, including missing-data fixtures
      and timing uncertainty (G4).
- [ ] Hand `.4` to `OBS-RUN` for bounded experiment observations after local
      acceptance. This board has no MCU and needs no QP/debug/trace addition.

Claim file ownership before parallel edits and reserve shared bench resources
through the central session record before measurements. Offline fixture and
documentation work can proceed in parallel. Keep current manufactured-board
qualification separate from future revision design; do not edit `kicad-libs`
for this documentation task. Report evidence-linked results and limits to the
central roadmap owner before marking a gate complete.

## Progress Log

- 2026-10-02: `kicad/board-manifest.yaml` derived (kicad-libs step 6): 7 placements, 3 board sheets, 28 nets, `make board-manifest-check` ok with 7 warnings (the three Blackfly channel blocks are the retired private block, since replaced by the `orb_weaver_blackfly_s_gpio_channel` family; their PCB groups are numbered `_1`..`_3` where the sheets say `name`, `name1`, `name2`; four blocks in the root). First interface map written at `docs/interface-map.md` (a rendering). Makefile and AGENTS gained the manifest, compose, source and refresh targets from the kicad-libs template.

## Pure agent shell update (2026-10-08)

- Pinned guix-agent-tools to published commit
  `788874ea3af208c30d66bd4e415b18e35ec14c2b`; other channel pins are unchanged.
- Task manifests provide Make; the agent manifest also declares Guix so
  nested managed Make targets work without host PATH.
- Verified the final pure agent environment, basic Make entrypoints, and
  both published agent launchers using offline probes and temporary state.
- 4 task manifests passed pure runtime smoke checks.
- Validation logs: `/tmp/pure-rollout`; cross-repository summary in
  guix-agent-tools/.agents/PLANS.md. Changes left uncommitted.
