# Camera GPIO Interface PCB Plan

Use this file for multi-step or cross-session work in this repository.

## Current Focus

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
- [ ] Layout: four layers, 120 × 80 mm outline per the plan, `INSTRUMENT`
      class on the `_INST` nets, DRC clean with `rule_severities.clearance`
      at error.
- [ ] Silkscreen wording, the one open design decision.
- [ ] Docs alongside: `docs/interface-map.md`, `docs/design-block-map.md`,
      `docs/harness-pinouts.md`, `docs/validation-plan.md`,
      `docs/bringup-log.md`; then `make docs`.
- [ ] `make fab`; promote the Phoenix MCV 6 vertical rotation row in
      `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv` from the JLCPCB
      placement preview.
