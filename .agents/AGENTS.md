# Camera GPIO Interface PCB Agent Guidance

This file is the canonical project guidance for agent sessions in this
repository.

## Session Start

Read this file first.

If `AGENT_MEMORY_REPO` is set and points at a directory, read
`$AGENT_MEMORY_REPO/AGENTS.md` before planning or editing.

Then read, in this order:

- `docs/rev0-plan.md`: the whole design record, with the resume checklist at
  the end. Its dated update notes at the top supersede older statements below
  them.
- `docs/kicad-libs-handoff-2026-09-24.md`: what `kicad-libs` prepared for this
  board and which plan statements it corrected.

If sibling checkouts exist, also read:

- `../orb-weaver-context/context/agent-index.md`
- `../orb-weaver-context/context/kicad-agent-context.md`
- `../board-interfaces/docs/instrument-port-digital.md`
- `../kicad-libs/docs/design-blocks.md`
- `../kicad-libs/docs/blackfly-s-gpio-channel-design-block.md`
- `../kicad-libs/docs/instrument-port-netclasses.md`

If `.agents/handoff.local.md` exists, read it before planning or editing.

If the task is multi-step, risky, or likely to span more than one session, read
`.agents/PLANS.md` and keep it updated as work progresses.

## Repository Purpose

This repository owns the KiCad implementation and board-specific notes for
`camera-gpio-interface-pcb`: three FLIR Blackfly S GPIO channels on pluggable
screw terminals, two BNC inputs from a pyControl breakout, four 3.3 V BNC
outputs to a Neuropixels OneBox, an InstrumentPort-Digital-50 with every camera
line tapped, and USB power. No MCU, no firmware.

## Board Rules

- `kicad-libs` owns the shared symbols, footprints, internal parts, vendor
  mappings and design blocks; `board-interfaces` owns the InstrumentPort
  contract. Do not copy library assets here. A placed block is a board-owned
  copy; re-annotate copies into 4-digit bands as `mouse-joystick-pcb` does.
- Blocks placed, all from `orb_weaver_private`:
  `blackfly_s_gpio_channel_mcv6_vertical` three times,
  `logic_input_2ch_5v_schmitt_sn74lvc2g17` for the two BNC inputs,
  `usb2_vertical`, `5v_to_3v3_tps73733`,
  `instrument_port_digital_50_dut_ffc_boundary_vertical`.
- Every BNC output is fixed at 3.3 V through 470 Ω. There is no 5 V option;
  the plan records why.
- `USBLC6-2P6` is a two-line array: pins 1 and 6 are one node, 3 and 4 the
  other. Nine on the board: one for the two inputs, two for the four outputs,
  two inside each camera block. Use only `orb_weaver_smd:USBLC6-2P6_SOT-666`.
- Instrument tap nets end in `_INST` and take the `INSTRUMENT` netclass from
  the `instrument-taps` profile. Every unused LV541A input is tied to ground at
  the board.
- `+5V_USB` is the opto drive level and the ESD clamp reference. It must stay
  a 5 V rail.
- Fab floors (0.1 mm clearance and track width) live in Board Setup >
  Constraints, never as unconditional `.kicad_dru` rules; such a rule replaces
  every netclass clearance instead of flooring it. `rule_severities.clearance`
  stays at error.
- A JLCPCB placement rotation correction goes in
  `kicad-libs/vendor_specs/jlcpcb/footprint-rotations.csv`, never in a
  footprint. This board is the first to place the Phoenix MCV 6 vertical;
  promote its inferred row from the first placement preview.
- Mark unverified pinouts, cable orientation and electrical limits as open
  decisions. Record bench results in `docs/bringup-log.md`.

## Development Environment

Prefer Makefile targets:

- `make test`: guidance and scaffold presence check
- `make kicad-edits`: open the project in the managed KiCad
- `make kicad-shell`, `make kicad-version`
- `make codex` / `make claude`: agent sessions with sibling checkouts added
- `make agent-reflection`
- `make validate-db`, `make check-kicad-libs`
- `make fab`, `make docs`, `make docs-check`
- `make clearance-baseline` before routing, then `make export-dsn` or
  `make freeroute`, `make import-ses`, `make clearance-check`: the shared
  kicad-libs routing helpers, described in
  `../kicad-libs/docs/freerouting-autorouting.md`

The pinned Guix channel in `.guix/channels.scm` carries KiCad 10.0.6, the
version the design blocks were saved with, so this repository has no local
KiCad overlay. The sibling `../kicad-libs` checkout is used through
`ORB_WEAVER_KICAD_LIBS` when present; the `orb-weaver-kicad-libs` channel pin
only selects the packaged helper commands. Bump pins deliberately, not as
cleanup.

`docs/generated/` and the block between the
`<!-- BEGIN/END GENERATED BOARD DOCUMENTATION -->` markers in `README.md` are
written by `make docs`. Never hand-edit either.

Netclass profiles applied 2026-09-25 with
`../kicad-libs/bin/orb-weaver-kicad-apply-netclasses`: `instrument-taps` and
`hv-power-24v` (its HV classes match nothing here; it supplies `PWR_5V`,
`PWR_3V3` and the `_LOCAL` variants). Re-apply if `--check` reports drift; the
helper preserves unrelated classes and patterns.

## Validation

For schematic and layout work, run KiCad ERC and DRC through the managed
environment once the design is mature enough for them to be meaningful, and
compare the exported netlist against the plan's tables after edits; ERC alone
did not catch earlier electrical findings on `mouse-joystick-pcb`.

`ORB_WEAVER_KICAD_LIBS` must resolve for KiCad to find the database, footprint
and design-block libraries.
