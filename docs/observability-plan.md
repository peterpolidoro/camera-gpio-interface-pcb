# Camera GPIO observability development plan

**Workstream:** `OBS-HW-CAMERA` (board slice of `OBS-HW`).
**Status:** Planned, 2026-09-29. All new work below is pending.

The system architecture (`orb-weaver-context/context/experimental-system-observability.md`)
and development roadmap (`orb-weaver-context/context/experimental-system-observability-plan.md`)
own the cross-repository intent, gate definitions, and workstream dependencies.
This document owns only this board's contribution. It records planned work,
not new electrical measurements, hardware validation, or deployment approval.

## Current evidence and board boundary

The dated updates in the [design record](rev0-plan.md), [session handoff](session-handoff-2026-09-26.md),
and [fabrication log](fabrication-log.md) describe the v1.0 board. Five assembled
boards were ordered on 2026-09-26. The [bring-up log](bringup-log.md) contains
the arrival, power and per-channel measurement procedure; its results remain
pending. Confirm actual arrival and unit identity before scheduling tests.
Completed routing/fabrication checks are not evidence of electrical behavior.

This board has no MCU or firmware. It exposes electrical observations of the
three camera channels, trigger/sync inputs and output copies through
InstrumentPort-Digital-50. It receives no QP, SWD/JTAG, command-UART or firmware
trace implementation. Keep the existing fixed 3.3 V output contract and actual
channel allocation in the design record authoritative.

A camera signal such as `ExposureActive` is evidence about that output and the
camera's configured behavior. It does not by itself establish that a usable
frame reached disk, that the frame contents are correct, or that all intended
experimental data were recorded. Native camera, pyControl and OneBox records
supply the complementary evidence.

## Independent execution paths

| Path | Ready now | Waiting condition and exit evidence |
| --- | --- | --- |
| `OBS-HW-CAMERA.1`: qualification preparation | Extract the actual 18-channel overlay, channel roles and expected polarity/timing from the design record; coordinate fixtures with `OBS-IF`/`OBS-HOST` | G0: versioned overlay and referenced electrical/timing criteria; record configuration-dependent meanings |
| `OBS-HW-CAMERA.2`: current-board bring-up | Prepare inspection, power and per-channel worksheets independently of QP | Arrived board, camera/test fixture and qualified `OBS-HW-ADAPTER` path; G1: actual per-unit electrical and capture measurements |
| `OBS-HW-CAMERA.3`: correlated camera operation | Define checks across trigger, camera output and native frame/acquisition records | G1 and `OBS-HOST` G2 monitors; G4 contribution: replayable capture/log bundle with latency, loss, timing uncertainty and coverage |
| `OBS-HW-CAMERA.4`: bounded experiment observation | Prepare configuration manifest and observation-window requirements with `OBS-RUN` | G4 and laboratory acceptance; G5: agreed trial windows, anomaly reports and archived native evidence without altered experimental control |

All preparation can run alongside the firmware and QP tracks. This board's
G1/G2 contribution does not wait for G3, and its electrical monitoring does not
require adding any processor or a new board revision.

## Planned tasks and acceptance

- [ ] `.1` Reconcile the installed camera model, channel configuration, cables,
      BNC destinations, InstrumentPort overlay and actual board revision.
      Preserve shared contract ownership in `board-interfaces`; derive test
      expectations from the current design record and device documentation.
- [ ] `.1` Prepare the remaining local interface/harness/validation documents
      already queued in `.agents/PLANS.md`, linking the existing design tables
      instead of creating competing pin assignments. Assign missing tolerance
      or latency requirements to the appropriate rig/device owner.
- [ ] `.2` Perform the existing arrival, first-power and per-camera-channel
      bring-up sequence on each identified unit. Record voltages, currents,
      polarity, load, ground paths and actual camera settings against the
      existing stated limits; keep failed and incomplete checks visible.
- [ ] `.2` Qualify all 18 used Digital-50 channels through the actual adapter
      and cable. Identify unused grounded channels, measured propagation delay
      and skew, pulse fidelity and limits under simultaneous switching. Record
      power-off/loading behavior; use a scope/meter where digital samples alone
      cannot establish amplitude or electrical integrity.
- [ ] `.3` Capture a known trigger/sync sequence, camera outputs and the
      corresponding native frame/OneBox/pyControl records. Measure latency,
      pulse widths, sequence/count agreement and clock-alignment uncertainty.
      Record the camera configuration that gives each observed line its meaning.
- [ ] `.3` Supply positive and intentionally incomplete or anomalous bench
      fixtures to `OBS-HOST`: missing trigger/output, missing stored frame,
      changed channel mapping and capture gaps. State which cases a monitor can
      identify, which are ambiguous and which require additional evidence.
- [ ] `.4` With `OBS-RUN`, document finite observation windows, raw-evidence
      retention and anomaly handling. LA5032 capture/upload gaps remain gaps;
      don't claim continuous electrical coverage from separate windows.
      Experiment sequencing remains in the researcher's existing tools.

Use the manufactured v1.0 board for these checks. A new revision is a separate
proposal only if measured limits or an agreed new requirement justify it.
No schematic, layout, BOM, fabrication package or shared design block changes
are implied by this plan.

## Evidence, ownership and handoff

For each bench session, record the board revision and unit identity, source
commit and dirty state, exact adapter and cable, connector views, instrument
identity/settings, channel-map version, stimulus, units, uncertainty, and raw
capture location/hash. Link measurements from the existing bring-up log; do not
copy another board's or revision's results into a new acceptance record.
Preserve unsuccessful and incomplete captures and state their limits.

Before measurements, claim the physical DUT, analyzer, cable, power supply,
and time window in the shared session record described by the central roadmap.
Only one agent/operator controls a claimed instrument or DUT at a time.
Offline documentation, fixture review, and saved-capture analysis may run in
parallel. A reservation records coordination; it does not authorize motion,
reset, stimulus, programming, or a change to a live experiment.

Use `docs/bringup-log.md` for per-unit measurements and
`docs/evidence/observability/<session-id>/` for new retained board captures and
manifests (create it when evidence exists). Keep native experimental data in
the laboratory's owning destination and link its identified artifacts from the
correlated session record; preserve camera/rig software commits and settings.

One camera-board agent owns this plan, its `.agents/PLANS.md` entry and the
local evidence record. Claim each pending interface/harness/validation document
before concurrent edits. `OBS-HW-ADAPTER` owns adapter qualification,
`OBS-HOST` owns decoding and monitor software, and `OBS-RUN` owns the actual
experiment pilot. No agent in this workstream edits `kicad-libs`.

Close steps only with evidence and limitations, then send gate contributions
to the central roadmap owner. Documentation checks are relative-link review,
`git diff --check`, and `make test`; preserve the generated README block and
`docs/generated/`. Those checks establish no new electrical or rig validation.
