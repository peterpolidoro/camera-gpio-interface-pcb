# kicad-libs handoff for the camera board, 2026-09-24

Written from the kicad-libs session that prepared the library for this board.
Read it before the resume checklist in `rev0-plan.md`; the last section lists
the statements in that plan it corrects.

## Ready in kicad-libs

- Block `orb_weaver_private:blackfly_s_gpio_channel_mcv6_vertical`: 21 parts,
  designators in the 23xxx band, ports in `TRIG_IN`, `SYNC_IN`, `+3.3V`,
  `+5V`, `GND`; out `CAM_OUT_BNC`, `L3_INST`, `L0_INST`, `L2_INST`, `L1_INST`,
  `OUT_INST`. Schematic verified pin by pin against the plan, layout verified
  pad by pad, standalone check `ok ports=11 errors=0 warnings=0`. Terminal
  numbers are the Hirose pin numbers; the block silk carries the wire colours
  over the terminals. Specification and verification record:
  `kicad-libs/docs/blackfly-s-gpio-channel-design-block.md`. Description and
  keywords are in the block JSON, including the camera settings that go with
  it. Confirm kicad-libs is committed at or after the block before scaffolding.
- The five parts bought 2026-09-23 exist: `OW-MISC-SN74LVC1G07DRYR`, 220 Ω 0603
  `OW-PASS-0603WAF2200T5E`, 470 Ω 0603 `OW-PASS-0603WAF4700T5E`, 680 Ω
  `OW-PASS-RC0402FR-07680RL`, 820 Ω `OW-PASS-FRC0402F8200TS`.
- The other four blocks this board places (`usb2_vertical`,
  `5v_to_3v3_tps73733`, `quadrature_encoder_input_5v_sn74lvc2g17`,
  `instrument_port_digital_50_dut_ffc_boundary_vertical`) pass the check with
  zero errors and were refreshed from the catalog on 2026-09-23.
- Netclass profile `kicad-libs/kicad/netclass-profiles/instrument-taps.json`:
  class `INSTRUMENT`, patterns `/*_INST` and `*/*_INST`, 0.15 mm track and
  clearance, via 0.6/0.3 mm equal to the template Default. Apply with
  `orb-weaver-kicad-apply-netclasses --profile instrument-taps kicad/<project>.kicad_pro`.
  For `PWR_5V`/`PWR_3V3` classes, `hv-power-24v` supplies them; its HV classes
  match nothing on this board and are harmless.
- Project templates fixed 2026-09-24: `orb-weaver-kicad-create-project` now
  writes Board Setup floors of 0.1 mm and a DRU without the two unconditional
  clearance/track rules that silently disabled netclass clearances. Scaffold
  from the current kicad-libs, not from an older checkout.

## Corrections to rev0-plan.md

1. **USBLC6-2P6 is a two-line array.** Pins 1 and 6 are one internal node and
   pins 3 and 4 the other. The plan's one array across four camera lines, and
   one across the four output BNCs, would short lines in pairs. The block
   carries two (Line 3 with Line 0, Line 2 with Line 1). The four output BNCs
   need two arrays and the two input BNCs one: nine on the board, not the five
   in the parts summary. Wire both pins of each pair to the node, as the USB
   block does.
2. `usb2_vertical` has a layout (6 footprints, 55 tracks, 8 vias). The note
   that its PCB side is schematic-only is stale.
3. The five new parts are in the catalog; "still to be added" is stale.
4. The block's designators are 23xxx; the board re-annotates to four digits.

## Sequence for this session

1. `git -C ../kicad-libs log --oneline -5`: the block, the `instrument-taps`
   profile and the mining-project changes must be committed.
2. Scaffold with `orb-weaver-kicad-init-repo`, then
   `orb-weaver-kicad-create-project` with the project in `kicad/` and basename
   `camera-gpio-interface-pcb`. Commit the generated tables.
3. Apply `instrument-taps` to the project.
4. Schematic per the plan's "Schematic Structure": three instances of the
   camera block, `SYNC OUT` driver, the input block, the DUT block with every
   unused LV541A input tied to ground, nine ESD arrays board-wide. ERC clean.
5. Layout, four layers, DRC, `make docs`, `make fab`. The first JLCPCB
   placement preview promotes the inferred MCV 6 vertical rotation row in
   `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv`.
