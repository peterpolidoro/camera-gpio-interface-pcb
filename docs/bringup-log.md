# Bring-Up Log

Record measured behaviour of real boards here, one section set per board
serial, numbers with units, not pass/fail marks. The design record and the
values every measurement is compared against are in
[rev0-plan.md](rev0-plan.md); the order that produced these boards is
[fabrication-log.md](fabrication-log.md). Bench results that change a
decision go back into the plan as dated notes.

## Boards

Five v1.0 boards ordered assembled from JLCPCB on 2026-09-26 (order 1). Give
each a serial when it arrives and mark it on the bare copper or a label;
the silk carries no unit identifier.

| Serial | Received | Location / rig | Notes |
| --- | --- | --- | --- |
| | | | |

## Inspection on arrival (per board)

- [ ] Photograph top and bottom before power.
- [ ] `DRY6` packages (U401, U701-U703, U1101, U1201-U1203, U1401-U1403):
      first use of this land pattern on an assembled board from this library;
      look for tombstoning, bridging, and pad 1 orientation against the
      package dot.
- [ ] `USBLC6-2P6` SOT-666 (10): orientation and the paired-pad jumpers.
- [ ] `J501` FH12-50 FFC: all 50 contacts wetted, hinged lid intact.
- [ ] LEDs D201, D301, D302, D401, D701, D1201, D1401: cathode toward the
      footprint's K mark (first verified rotation of this footprint).
- [ ] Phoenix MCV 6 headers: terminal 1 (green wire, Line 3) at the GRN
      end of each block's colour silk; all six pins soldered.
- [ ] BNC shells and USB-C shell continuous with board ground.

## First power (per board)

Plan reference: `rev0-plan.md`, "Power" and "Signal Chains".

| Measurement | Expected | Serial | Measured |
| --- | --- | --- | --- |
| USB input current, nothing connected | well under 100 mA | | |
| `+5V` at the LDO input | 4.5-5.2 V (behind the USB block's Schottky) | | |
| `+3.3V` at the LDO output | 3.3 V ±2 % | | |
| Power LED D201 | lit | | |
| Every `_INST` net idle level | 0 V or 3.3 V, none floating | | |

## Camera channel checks (per board, per channel)

From `rev0-plan.md`, "Sequence" step 6. Drive `TRIG IN` and `SYNC IN`
from a pyControl breakout running `camera_sync_test.py`, or from a
function generator at 3.3 V.

| Measurement | Expected | Serial / channel | Measured |
| --- | --- | --- | --- |
| Line 0 LED current at the plug, `SYNC IN` high | 3.5-7 mA (FLIR spec; ~4 mA by design) | | |
| Line 0 node voltage, `SYNC IN` low | ≤ 0.2 V | | |
| Line 3 level at the plug, `TRIG IN` high / low | 3.3 V / 0 V through 220 Ω | | |
| Line 2 low level with camera driving `ExposureActive` | ≤ 0.4 V (1 kΩ pull-up) | | |
| Line 1 (`OPTOOUT`) low level with 4.7 kΩ pull-up | < 0.8 V, the Schmitt VT- worst case | | |
| `CAMn OUT` BNC swing into a 1 MΩ load | 0-3.3 V | | |
| `SYNC OUT` BNC swing | 0-3.3 V, follows `SYNC IN` | | |
| Activity LEDs | trigger LED half-lit at 150 Hz, sync LED blinks on 25 ms pulses | | |

## InstrumentPort capture

All 18 live channels through the `la5032-instrument-port-adapter` with the
mapping table in `rev0-plan.md`, "InstrumentPort". Record the capture file
name, the adapter version, and which `DIG` channels showed the trigger,
Rsync and each camera's five lines.

## Rig integration

Apply the software change table in `rev0-plan.md`, "Software changes that
go with this board" (`TriggerSource Line3`, `V3_3Enable false`,
`RSYNC_BIT = 0`, OneBox `IO0`-`IO3` as ADC inputs), then run the rig's
`rig1_check.py` against a OneBox recording. Record the result and the
commit of `joystick-rig` it was run with.
