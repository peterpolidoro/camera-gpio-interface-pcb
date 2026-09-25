# camera-gpio-interface-pcb

Interface board for the three FLIR Blackfly S cameras in the Janelia Dudman lab
joystick rig: pluggable screw-terminal camera connectors, two BNC inputs from
the pyControl breakout, four 3.3 V BNC outputs to a Neuropixels OneBox, an
InstrumentPort-Digital-50 with every camera line tapped, and USB power. No
MCU, no firmware, no configuration jumpers.

**Status, 2026-09-25:** the design record is complete in
[docs/rev0-plan.md](docs/rev0-plan.md) and the KiCad project is scaffolded in
`kicad/`; the schematic has not been started. Read the plan first, then
[docs/kicad-libs-handoff-2026-09-24.md](docs/kicad-libs-handoff-2026-09-24.md),
then the plan's resume checklist.

## The Board

The block below is written by `make docs` from the KiCad sources: renders, key
dimensions, and links to the schematic, BOM, STEP model and enclosure geometry.
Do not edit between the markers; run `make docs` instead.

<!-- BEGIN GENERATED BOARD DOCUMENTATION -->
<!-- END GENERATED BOARD DOCUMENTATION -->

## Status

Rev 0, not yet drawn. The five design blocks it places exist in `kicad-libs`
and pass their standalone checks; the new parts are purchased and in the
catalog. The one open design decision is the silkscreen wording.

## Environment

    make help          List the available targets
    make kicad-edits   Open the project in the managed KiCad
    make fab           Generate the JLCPCB fabrication package
    make docs          Regenerate the documentation above
    make docs-check    Report whether that documentation is stale

## Key Documents

- [Rev 0 plan](docs/rev0-plan.md): the whole design record and the resume checklist
- [kicad-libs handoff, 2026-09-24](docs/kicad-libs-handoff-2026-09-24.md): what the library prepared for this board
- [Generated board documentation](docs/generated/README.md): written by `make docs`, not yet generated
