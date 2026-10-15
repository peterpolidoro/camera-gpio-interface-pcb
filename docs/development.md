# Development

Developer-facing notes for this repository: the toolchain the board was drawn
with, the repositories it was developed beside, and the layout and fabrication
record. Nothing here is needed to open the KiCad project or to order boards.

## The Orb Weaver Toolchain

This board was drawn inside the Orb Weaver ecosystem
(https://codeberg.org/orb-weaver). Its KiCad library, `kicad-libs`, supplied
the symbols, footprints, parts database and design blocks, and its
`orb-weaver-kicad-*` tools generate `docs/generated/`, the fabrication package
under `fab/`, the board manifest and the clearance baseline.

The schematic and board carry their own copies of every symbol and footprint,
so KiCad 10 opens, edits, checks and plots the project without the library.
The project-local library tables resolve through `ORB_WEAVER_KICAD_LIBS`; when
that variable is unset KiCad reports the libraries as missing once and carries
on. Without the library the 3D viewer shows only KiCad's stock models, parts
cannot be updated from the library, and the design blocks cannot be
recomposed. The assembled STEP model under `docs/generated/3d/` covers the
mechanical need.

The Makefile prefers a sibling checkout, `../kicad-libs`, through
`ORB_WEAVER_KICAD_LIBS`, and falls back to the packaged tools from the Guix
channel pinned in `.guix/channels.scm`.

## Sibling Repositories

| Repository | Role | Where |
| --- | --- | --- |
| `kicad-libs` | Symbols, footprints, parts, design blocks, documentation and fabrication generators | https://codeberg.org/orb-weaver/kicad-libs |
| `board-interfaces` | Interface contracts, including the instrument port this board taps | https://codeberg.org/orb-weaver/board-interfaces |
| `orb-weaver-context` | Shared architecture and planning documents | https://codeberg.org/orb-weaver/orb-weaver-context |
| `la5032-instrument-port-adapter` | The LA5032 adapter for the instrument port | https://codeberg.org/orb-weaver/la5032-instrument-port-adapter |
| `instrument-control` | Logic-analyzer observation of the rig's boards | https://codeberg.org/orb-weaver/instrument-control |
| `guix-agent-tools` | The Guix channel carrying the agent and KiCad tooling | https://codeberg.org/orb-weaver/guix-agent-tools |
| `mouse-joystick-pcb` | The rig's joystick controller board | https://github.com/peterpolidoro/mouse-joystick-pcb |
| `joystick-rig` | The rig's pyControl tasks and operating notes | https://github.com/sourishmukh/joystick-rig |
| `pycontrol-h7-breakout` | The pyControl breakout whose BNCs feed this board | https://github.com/peterpolidoro/pycontrol-h7-breakout |

Documentation in this repository cites files in these repositories as
`<repository>/<path>`; the Makefile assumes them as sibling checkouts.

## Environment

Managed KiCad targets use `.guix/channels.scm` through `guix time-machine`.
Keep that file pinned to exact commits following
`orb-weaver-context/context/guix-channel-maintenance.md`.

    make help          List the available targets
    make kicad-edits   Open the project in the managed KiCad
    make fab           Generate the JLCPCB fabrication package
    make docs          Regenerate the generated documentation and the README's managed block
    make docs-check    Report whether that documentation is stale

`docs/generated/` and the block between the `BEGIN/END GENERATED BOARD
DOCUMENTATION` markers in `README.md` are written by `make docs`. Never
hand-edit either.

## Layout And Fabrication Record

v1.0, 2026-09-26: four layers, 100 x 60 mm, 158 footprints, `/GND` poured
on every layer. ERC 0; DRC 0 errors, 0 unconnected, 0 schematic differences,
with 144 block-inherited clearance findings accepted as warnings (fab-floor
copper inside the InstrumentPort and USB block layouts, see
`.agents/AGENTS.md`); `make clearance-check` passes against the routing
baseline; `make fab` builds the JLCPCB package with all 151 parts in the BOM
and placement files. **Five assembled boards were ordered from JLCPCB on
2026-09-26 from commit `5ddb425`** ([docs/fabrication-log.md](fabrication-log.md));
the placement preview showed every part oriented correctly, which verifies
the Phoenix MCV 6 vertical and 0402 LED rotation rows for `kicad-libs`.
Bring-up results go in [docs/bringup-log.md](bringup-log.md).

## Developer Documents

- [Rev 0 plan](rev0-plan.md): the whole design record and the resume checklist
- [Observability development plan](observability-plan.md): board workstream, parallel tasks and evidence gates
- [kicad-libs handoff, 2026-09-24](kicad-libs-handoff-2026-09-24.md): what the library prepared for this board
- [Autoroute log](autoroute-log.md): the layout record, run by run, with every hand repair
- [Session handoff, 2026-09-26](session-handoff-2026-09-26.md): where the routed board stood before fabrication
- [Fabrication log](fabrication-log.md): what was ordered, from which commit, with which package hashes

## Agent Guidance

`AGENTS.md` and `.agents/` carry the agent-facing guidance, plans and handoffs
for this repository. They assume the sibling checkouts above.
