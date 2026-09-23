# Camera GPIO Interface PCB Rev 0 Plan

**Status:** Draft 2026-09-23, revised the same day to design from the camera's
documented electrical behaviour rather than from the lab's harness drawing,
then again once the signal source (pyControl H7 Breakout) and consumer
(Neuropixels OneBox) were identified. No KiCad project yet. The "Open Decisions" section lists what has to be
answered before schematic capture starts.
**Purpose:** Replace the hand-built harness that connects three FLIR Blackfly S
`BFS-U3-20S4M-C` cameras to a sync source and a DAQ with one board that has
pluggable screw-terminal camera connectors, five BNCs, defined logic levels
and drive currents on every camera pin, protection on every field-wired pin,
and an InstrumentPort so every camera line can be watched on a logic analyzer
during an experiment.

Source material: `tmp/BFS-U3-20S4-Datasheet.pdf`,
`tmp/BFS-U3-Getting-Started-1.pdf`, `tmp/General Purpose Input Output
(GPIO).html`, `tmp/onebox-datasheet.pdf`, `tmp/onebox-user-manual.pdf`
(v1.0.1), `~/Repositories/github/pycontrol-h7-breakout/pcb/` (rev 0.8,
2026-08-19), the FLIR pages
`https://softwareservices.flir.com/BFS-U3-20S4/latest/40-Installation/ElectricalGPIO.htm`
and `.../InputOutputControl.htm`, the FLIR multi-camera synchronisation
application note, and (for what exists today only) `tmp/260803_Camera GPIO
Hardwiring-1.pdf`. `tmp/` is gitignored, so the facts that matter are copied
into this document.

## What The Board Is

Three identical camera channels, two shared inputs, one InstrumentPort, USB
power. No MCU, no firmware, no configuration jumpers.

```
EXP/TRIG IN BNC ─ Schmitt ─┬─ 3.3 V driver ─┐
                           ├─ 3.3 V driver ─┼─ camera Line 3 (fast input)
                           └─ 3.3 V driver ─┘
SYNC IN     BNC ─ Schmitt ─┬─ opto driver ──┐
                           ├─ opto driver ──┼─ camera Line 0 (opto input)
                           └─ opto driver ──┘
camera Line 2 (open-drain out) ─ pull-up ─ Schmitt ─ CAMn OUT BNC   (×3)
every camera line ─ 100 Ω tap ─ InstrumentPort-Digital-50
```

Two signals come **from** the pyControl H7 Breakout's two BNC outputs and go
**to** every camera: the exposure/trigger signal (`EXP`) and a sync pulse
(`SYNC`). One signal comes **from** each camera and goes to a Neuropixels
OneBox ADC channel on its own BNC (`CAMn_OUT`). Which BNC reaches which camera
line is fixed and printed on the board; a change of role is a cable swap plus
a SpinView setting, not a rework.

## Source And Consumer

### pyControl H7 Breakout (source of `EXP` and `SYNC`)

Rev 0.8 has two BNC jacks. Traced from `pcb/h7_breakout.kicad_pcb`:

| BNC | Path | Driver |
| --- | --- | --- |
| `BNC_1` (`J2`) | jumper `JP3` → net `1_C` (behaviour port 1 `DIO_C`), or jumper `JP1` → net `D4` | STM32H743 `PA4` through `R11` 100 Ω, or an extra digital I/O through `R33` 100 Ω |
| `BNC_2` (`J3`) | jumper `JP4` → net `6_C` (behaviour port 6 `DIO_C`), or jumper `JP2` → net `D5` | STM32H743 `PA5` through `R12` 100 Ω, or an extra digital I/O through `R42` 100 Ω |

Each `DIO_C` net carries a `D1213A-04TS-7` ESD array clamped to the
breakout's **+3.3 V** rail and ground. So each BNC output is a 3.3 V CMOS
push-pull microcontroller pin, roughly 8 mA of drive, behind 100 Ω, with
clamps that will conduct if anything above about 3.9 V or below −0.6 V is ever
pushed back into the jack. Consequences for this board:

- The inputs must be high impedance. A 50 Ω termination would ask a
  microcontroller pin for 66 mA; no termination footprint is fitted.
- 3.3 V is the input high level; the Schmitt buffer's worst-case
  VT+ of 2.0 V leaves 0.9 V of margin after the 100 Ω and the board's own
  4.7 kΩ / 100 kΩ network, which loads the pin by about 30 µA.
- Anything this board might ever hand back to a pyControl BNC has to stay
  inside 0–3.3 V, which is why the outputs below are fixed at 3.3 V
  (`mouse-joystick-pcb` made the same choice for the same reason).
- `PA4`/`PA5` are also the H7's DAC pins, so a future firmware could put an
  analog waveform on these BNCs; the Schmitt input turns that into a clean
  threshold crossing either way.

If the lab also wants the OneBox to record `EXP` or `SYNC` directly, a BNC tee
at the breakout is fine: this board's input (~105 kΩ) plus an ADC input are
both negligible loads for the pin. The board does not duplicate the inputs
on extra BNCs.

### Neuropixels OneBox (consumer of `CAMn_OUT`)

From the technical user manual v1.0.1:

- Auxiliary inputs are twelve **single-ended ADC channels** (AD7616-P) on the
  SDR connector, reached through the SDR breakout board's BNCs; channel 0 is
  also on a front-panel SMA. Input range ±2.5 V, ±5 V (default) or ±10 V.
  Sampled at a fixed **30.3 kHz**, so any edge is timestamped to ±33 µs.
- Each channel has an FPGA comparator whose output can be the acquisition
  trigger or the external SYNC source, with "33 µs jitter on the comparator
  output". Threshold levels are shared across channels.
- Each SDR pin is shared between an ADC input and a DAC output (AD5766,
  ±5 V, 20 mA source/sink) through a software switch. The manual: "in case an
  external signal is connected to an ADC input, it is imperative to
  disconnect the corresponding DAC output."
- The back-panel `SMA1` trigger/SYNC input "requires 5 V TTL signals". It is
  not the target for this board; the camera outputs go to ADC channels, where
  3.3 V into the ±5 V range is comfortable and a comparator threshold near
  1.6 V is unambiguous.

Consequences for this board: 3.3 V outputs into a high-impedance load, a
series resistor sized so that an accidentally enabled ±5 V DAC on the far end
cannot destroy the driver, and an ESD array on the output BNCs. The OneBox's
33 µs sampling grid, not this board, sets the timing resolution of the frame
record; the 1 µs Line 2 output keeps the board out of that error budget where
the 36 µs opto output would have doubled it.

## Camera GPIO Facts (BFS-U3-20S4, cased)

Connector on the camera: Hirose `HR10A-7R-6PB`. Mating plug: `HR10A-7P-6S(73)`.
Flying-lead cable: FLIR `ACC-01-3009` (1 m) or the longer FLIR GPIO cable; the
wire colours below are the FLIR cable-assembly colours.

| Pin | Wire | Line | Function | Electrical (FLIR) |
| --- | --- | --- | --- | --- |
| 1 | Green | 3 | `GPI` non-isolated input; dual-function `VAUX` 8–24 V camera power input | Low 0–1.4 V, **high 2.6–3.6 V**, ≤1 µs propagation |
| 2 | Black | 0 | `OPTOIN` opto-isolated input | Low 0–1.4 V, high 2.6–30 V, **input current 3.5–7 mA**, ≤18 µs L→H, ≤9 µs H→L |
| 3 | Red | 2 | `GPIO` non-isolated in/out, open-drain output; dual-function `VOUT` 3.3 V 120 mA out (`V3_3Enable`) | In: low 0–1.4 V, high 2.6–24 V, ≤1 µs. Out: open drain, 25 mA sink, pull-up ≤24 V |
| 4 | White | 1 | `OPTOOUT` opto-isolated output | Open collector, 25 mA, pull-up ≤24 V, ≤36 µs L→H, ≤18 µs H→L |
| 5 | Blue | — | Opto GND | Return for Line 0 and Line 1 |
| 6 | Brown | — | GND | Camera/USB ground, return for Line 2 and Line 3 |

Measured combinations FLIR publishes that this design leans on:

- Opto-isolated I/O test condition is **5 V through 1 kΩ**; the input current
  spec (3.5–7 mA) is stated under that condition. FLIR does not publish the
  input's internal circuit, so the board reproduces the test condition
  instead of guessing at it.
- `OPTOOUT` low level is **0.92 V** with 5 V / 1 kΩ and **1.47 V** with
  3.3 V / 200 Ω: the opto transistor has roughly 200 Ω of internal drop plus
  saturation. A stiff pull-up raises its low level above a 3.3 V logic
  threshold. A weak pull-up is required if anything reads it.
- Non-isolated open-drain output: 3.3 V through 1 kΩ sinks 3.1 mA, i.e. a
  real FET with about 0.2 V low level.
- "Both the opto-isolated input and output have over current protection. To
  avoid damage, connect the OPTO_GND pin first before applying voltage to the
  GPIO line." A pluggable plug mates all six contacts at once.

Software (Digital IO Control / Acquisition Control): every line is a valid
`TriggerSource`; `LineSource` for outputs includes `ExposureActive`,
`FrameTriggerWait`, `UserOutput0-3`, `Counter0/1Active`, `LogicBlock0/1`;
`LineInverter` and deglitch/debounce filters exist per line; `ExposureMode` is
`Timed` or `TriggerWidth`; chunk data can carry line status and counter
values. So the board decides speed and voltage tolerance per physical line;
function is set in SpinView.

## Camera Line Assignment

Two inputs and one output are needed per camera. The camera offers two inputs
(Line 3 fast, Line 0 opto), one output (Line 1 opto) and one bidirectional line
(Line 2, which is also the only fast output). The assignment follows from
that:

| Board signal | Camera line | Why |
| --- | --- | --- |
| `EXP` (exposure/trigger; timing-critical) | **Line 3** (`GPI`, pin 1, green) | ≤1 µs, symmetric. On the opto input the 18 µs / 9 µs asymmetry would shorten a `TriggerWidth` exposure by up to ~9 µs and delay every frame by up to 18 µs. |
| `SYNC` (sync marker) | **Line 0** (`OPTOIN`, pin 2, black) | Current-driven and 30 V tolerant, robust on a long unshielded lead; its delay is a constant offset that a marker does not care about. |
| `CAMn_OUT` (frame/exposure active) | **Line 2** (`GPIO`, pin 3, red) as open-drain output, pulled up on the board | ≤1 µs and a clean FET low level, versus ≤36 µs and a 1 V low on `OPTOOUT`. Costs the camera's `VOUT`, which a USB-powered board does not need. |
| — | Line 1 (`OPTOOUT`, pin 4, white) | Not used for the BNC. Pulled up weakly and buffered to the InstrumentPort only, so a second camera output (e.g. `FrameTriggerWait`) can be watched when diagnosing missed triggers. |

There are no swap jumpers. Both input BNCs have identical conditioning, so if
the lab ever wants the roles reversed they swap the two cables and change
`TriggerSource`. The BNC silkscreen names the camera line each one reaches.

### Camera settings that go with this board (SpinView / Spinnaker)

| Line | Setting |
| --- | --- |
| Line 3 | `LineMode = Input`. `TriggerSelector = FrameStart`, `TriggerSource = Line3`, `TriggerActivation = RisingEdge`, `TriggerMode = On`. `ExposureMode = TriggerWidth` if the pulse width is the exposure, else `Timed`. `TriggerOverlap = ReadOut` for maximum rate. Optional `LineInputFilterSelector = Deglitch`. |
| Line 0 | `LineMode = Input`. Consumed however the sync is meant to be recorded: `ChunkLineStatusAll` per frame, or `Counter0` with `CounterEventSource = Line0` and `ChunkCounterValue`, or as the `AcquisitionStart` trigger. |
| Line 2 | `LineMode = Output`, `LineSource = ExposureActive` (or `FrameTriggerWait` etc.), **`V3_3Enable = false`**. |
| Line 1 | `LineSource = Off`, or a second diagnostic source; visible on the InstrumentPort only. |

If `V3_3Enable` is left on from an older configuration nothing is damaged:
the camera's 3.3 V simply holds the Line 2 node high through the board's 1 kΩ
until it is switched off.

## Ground And Isolation

One board ground. Camera pins 5 and 6 both land on it at each connector, every
BNC shell lands on it, the USB shell lands on it. Using Line 2 or Line 3 at
all requires camera ground on the board, and the cameras already share ground
with the host through USB, so the board adds no isolation that the system
would otherwise have.

A galvanically isolated variant is possible later: Line 0 in, Line 1 out,
Line 3 in through a one-channel digital isolator powered from the camera's
`VOUT`, pin 6 never touching the board. It costs three isolators and gives up
the fast Line 2 output. Only worth doing if the ephys rig shows a ground-loop
problem through the camera USB cables (Open Decision 1).

## Signal Chains

### Inputs (`EXP/TRIG IN`, `SYNC IN`), one chain each

1. BNC, shell to ground. No termination footprint: the source is a
   microcontroller pin behind 100 Ω (see above).
2. `USBLC6-2P6` ESD array (one part covers both inputs), `VBUS` pin on
   `+5V_USB` so the clamp sits above a 5 V logic high and never conducts on
   a 3.3 V signal.
3. Series 4.7 kΩ, 47 pF to ground (≈700 kHz corner), 100 kΩ pull-down on the
   BNC side, into an `SN74LVC2G17` Schmitt buffer at 3.3 V; 100 kΩ pull-down
   on each buffer output for Ioff. This is the circuit of the existing
   `quadrature_encoder_input_5v_sn74lvc2g17` block. An unplugged BNC reads low,
   so the cameras receive nothing rather than noise.
4. Result: `EXP_IN`, `SYNC_IN`, 3.3 V logic. The chain also tolerates a
   5 V source or a ±5 V OneBox DAC output plugged in by mistake (LVC inputs
   are 5.5 V tolerant; the 4.7 kΩ bounds the negative-side clamp current to
   about 1 mA). Hysteresis is ≥0.4 V, so a slow or noisy edge cannot
   double-trigger.
5. `EXP_IN` feeds the three Line 3 drivers, `SYNC_IN` the three Line 0
   drivers, an activity LED each (0402, ~1.8 mA through 680 Ω), and one
   InstrumentPort tap each.

### Per camera (×3) — one proposed new design block

| Camera pin | Board circuit |
| --- | --- |
| 1 (Line 3, green) | `SN74LVC1G125` at 3.3 V, `~OE` tied to ground, input `EXP_IN`, output through **220 Ω** to the pin. A per-camera buffer means a shorted cable pulls one channel down, not all three; 220 Ω bounds that fault to 15 mA and slows the edge to ~100 ns into a ~500 pF lead, which is plenty fast against a 1 µs input and kinder to the unshielded harness than a bare CMOS edge. |
| 2 (Line 0, black) | `SN74LVC1G07` open-drain buffer at 3.3 V, input `SYNC_IN`, output node pulled up through **820 Ω to `+5V_USB`** (≈4.7 V after the USB block's Schottky) and wired to the pin. Signal high → buffer off → the opto LED sees the same drive as FLIR's 5 V / 1 kΩ test condition, ≈4 mA. Signal low → buffer sinks the 820 Ω, LED off. LVC1G07's open-drain output is rated to 5.5 V. Rising edge is 820 Ω × ~500 pF ≈ 0.4 µs against an 18 µs input. |
| 3 (Line 2, red) | **1 kΩ pull-up to `+3.3V`**, node `CAMn_L2`: 3.1 mA when the camera pulls low, ~0.5 µs rise into ~500 pF. Into channel A of an `SN74LVC2G17` Schmitt → `CAMn_OUT`. |
| 4 (Line 1, white) | **4.7 kΩ pull-up to `+3.3V`**, node `CAMn_L1`. Weak on purpose: ~0.6 mA keeps the opto transistor's low level near 0.4 V, under the Schmitt's worst-case VT− of 0.8 V. Into channel B of the same `SN74LVC2G17` → `CAMn_L1_BUF`, InstrumentPort only. |
| 5, 6 (blue, brown) | Ground, both. |
| pins 1–4 | One `USBLC6-2P6` per connector, four lines, `VBUS` pin on `+5V_USB` (the Line 0 node swings to ~4.7 V, so the clamp has to reference 5 V, not 3.3 V). |

`CAMn_OUT` drives the BNC through 220 Ω, an activity LED through 680 Ω, and
an InstrumentPort tap. A shorted BNC costs 15 mA at the Schmitt output, and
an OneBox DAC left enabled at −5 V on the far end is held at the ESD clamp
and costs about 18 mA — both inside the LVC2G17's ±50 mA absolute maximum —
and either way the LED and the tap stay alive.

Block ports: `EXP_IN`, `SYNC_IN` in; `CAM_OUT` out; `+3.3V`, `+5V`, `GND`;
taps `L3_INST`, `L0_INST`, `L2_INST`, `L1_INST`, `OUT_INST` (100 Ω each, T-tap
in the branch, following the `mouse-joystick-pcb` tap rules: 100 Ω on timing
signals, `_INST` suffix on block pins and board nets alike).

Fallback if adding `SN74LVC1G07` to `kicad-libs` is unwelcome: a second
`SN74LVC1G125` with its input grounded and the signal on `~OE`, output pulled
to 5 V (LVC three-state outputs are rated to 5.5 V). It works but reads badly
in a schematic; the 1G07 is preferred.

### Outputs (`CAM1..3 OUT` BNC)

**Fixed at 3.3 V.** The OneBox ADC input is high impedance with a ±5 V
range, and a signal that may one day be fed back into a pyControl BNC has to
stay under that board's 3.3 V clamps; `mouse-joystick-pcb` is 0–3.3 V for the
same reason. There is no 5 V option.

3.3 V CMOS through **220 Ω** into the coax. Not 50 Ω, because a shorted BNC
would then draw 66 mA from a part rated for 50 mA; and 220 Ω rather than
100 Ω so that the OneBox's shared DAC/ADC pin, if its ±5 V DAC is left
switched in, cannot push more than ~18 mA through the driver via the ESD
clamp. The mismatch costs a few tens of nanoseconds of settling on a 2 m
cable, three orders of magnitude under the OneBox's 33 µs sample period. One
`USBLC6-2P6` covers the three output BNCs, `VBUS` pin on `+5V_USB`.

If the lab ever wants a camera output on the OneBox `SMA1` (5 V TTL) input
instead of an ADC channel, that is a separate 5 V driver and a separate
decision; it is not provided here.

## InstrumentPort

Block: `instrument_port_digital_50_dut_ffc_boundary_vertical` from
`orb_weaver_private` (Hirose `FH12-50S-0.5SVA(54)`, four `SN74LV541A`, 100 Ω
source damping, `~OE` pulled low, no disable, supplied from the always-on
3.3 V rail). Contract: `board-interfaces/docs/instrument-port-digital.md`.
Adapter: `la5032-instrument-port-adapter` v2.0 (ordered, untested).

Allocation: one subsystem per octal package, 17 of 32 channels used. Every
tap is 100 Ω because every signal here is a timing edge. Every functional node
already has a DC definition (pull-up, pull-down, or driven), so no `_INST` net
needs its own pull. Every unused buffer input is tied to ground at the board.

| Strand | Package | Net | What it witnesses |
| --- | --- | --- | --- |
| `DIG0` | A | `EXP_IN_INST` | Conditioned exposure/trigger input, after the Schmitt |
| `DIG1` | A | `SYNC_IN_INST` | Conditioned sync input, after the Schmitt |
| `DIG2` | A | `CAM1_L3_INST` | Camera 1 pin 1 node, after the 220 Ω |
| `DIG3` | A | `CAM1_L0_INST` | Camera 1 pin 2 node, 0–4.7 V open-drain node (LV541A inputs are 5.5 V tolerant; the cable side is 3.3 V) |
| `DIG4` | A | `CAM2_L3_INST` | |
| `DIG5` | A | `CAM2_L0_INST` | |
| `DIG6` | A | `CAM3_L3_INST` | |
| `DIG7` | A | `CAM3_L0_INST` | |
| `DIG8` | B | `CAM1_L2_INST` | Camera 1 Line 2 raw open-drain node |
| `DIG9` | B | `CAM1_L1_INST` | Camera 1 `OPTOOUT`, Schmitt-buffered |
| `DIG10` | B | `CAM2_L2_INST` | |
| `DIG11` | B | `CAM2_L1_INST` | |
| `DIG12` | B | `CAM3_L2_INST` | |
| `DIG13` | B | `CAM3_L1_INST` | |
| `DIG14`, `DIG15` | B | `GND` | spare |
| `DIG16` | C | `CAM1_OUT_INST` | What the `CAM1 OUT` BNC carries |
| `DIG17` | C | `CAM2_OUT_INST` | |
| `DIG18` | C | `CAM3_OUT_INST` | |
| `DIG19`–`DIG23` | C | `GND` | spare |
| `DIG24`–`DIG31` | D | `GND` | spare |

`DIG0`/`DIG1` are the marker pair on `mouse-joystick-pcb`; this board has no
firmware beacon, so its two board-level inputs take the first pair. The first
sixteen channels hold everything except the three BNC-out copies, so a future
Digital-25 adapter still sees inputs, drives and raw camera outputs.

Netclass: `INSTRUMENT`, pattern `/*_INST`, as on `mouse-joystick-pcb`.

## Power

`usb2_vertical` (or `usb2` horizontal; the vertical block's PCB side is
schematic-only as of 2026-09-23 and its layout would be done on this board, as
`mouse-joystick-pcb` did) → `+5V_USB` → `5v_to_3v3_tps73733` → `+3.3V`.
`+3.3V` is the only logic rail and is always-on by construction, which is what
the InstrumentPort block requires. `+5V_USB` is used only for the three Line 0
pull-ups and the ESD-array clamp references. Budget is well under 100 mA:
five `LV541A`, four `LVC2G17`, three `LVC1G125`, three `LVC1G07`, six LEDs,
pull-ups. Any USB port or wall adapter works; nothing reads the CC
advertisement. Power LED on `+3.3V`.

Not chosen: taking 3.3 V from a camera's `VOUT`. It would force Line 2 back to
`VOUT`, push the frame output onto the 36 µs opto line, and make the board
depend on which camera is plugged in.

## Connectors, Mechanical, Silkscreen

| Function | Part | Library item |
| --- | --- | --- |
| Camera ×3 | Phoenix MCV 1,5/6-G-3,5 (1843648), vertical | `OW-CONN-TBH-1X06-3P5-VERT`, symbol `orb_weaver_connectors:Conn_01x06_P3.5mm_TBH_Vertical_Screw`, footprint `orb_weaver_tht:PhoenixContact_MCV_1,5_6-G-3.5_1x06_P3.50mm_Vertical` |
| Camera plug (lab buys 3, not on the PCB BOM) | Phoenix MC 1,5/6-ST-3,5 (1840405) | no 3D model vendored yet |
| BNC ×5 | HenryTech `HL-BNC-KHDA` vertical, 24 mm pitch as on `mouse-joystick-pcb` | `OW-CONN-HL-BNC-KHDA`. Right-angle alternative: `OW-CONN-DOSIN-801-0050` |
| InstrumentPort | Hirose `FH12-50S-0.5SVA(54)` | inside the DUT block |
| Power | USB-C, GCT `USB4145-03-0070-C` vertical | inside `usb2_vertical` |
| Mounting | 4× M3, 3.2 mm | `OW-MECH-MH-*` |
| Fiducials | 3× | `OW-MECH-FID-1MM-MASK2MM` or similar |

Terminal numbering equals Hirose pin numbering, so the lab wires colours by
position. Silkscreen at every terminal: `1 GRN L3 IN`, `2 BLK L0 IN`,
`3 RED L2 OUT`, `4 WHT L1`, `5 BLU OGND`, `6 BRN GND`. BNC labels:
`EXP/TRIG IN → LINE 3`, `SYNC IN → LINE 0` (both "from pyControl BNC"),
`CAM1 OUT`, `CAM2 OUT`, `CAM3 OUT` ("to OneBox ADC"), `3.3 V LOGIC`. Mark the FFC `DIGITAL-50 / 3.3 V / OBSERVE ONLY` and pin 1.

Footprint budget: a 6-position plug is ~22 mm wide, so headers at ≥25 mm pitch
(~75 mm for three); five BNCs at 24 mm need ~120 mm in a row or two edges (two
inputs on one edge, three outputs on another). Expect roughly 100 × 80 mm to
120 × 80 mm. Four layers, to reuse the design-block layouts unchanged and give
the BNC returns and the FFC block a solid ground plane.

## Parts Summary

Existing in `kicad-libs`:

| Qty | Part | Role |
| --- | --- | --- |
| 3 | `OW-CONN-TBH-1X06-3P5-VERT` | camera connectors |
| 5 | `OW-CONN-HL-BNC-KHDA` | BNCs |
| 1 | `usb2_vertical` block (`OW-CONN-USB-C-USB2-SMD-VERT`, `USBLC6-2P6`, `MBR120VLSFT1G`) | power entry |
| 1 | `5v_to_3v3_tps73733` block (`OW-PWR-TPS73733QDRBRQ1`) | 3.3 V rail |
| 1 | `instrument_port_digital_50_dut_ffc_boundary_vertical` block (`OW-CONN-FH12-50S-0-5SVA-54`, 4× `OW-MISC-SN74LV541ARKSR`, 32× 100 Ω) | InstrumentPort |
| 1 | `quadrature_encoder_input_5v_sn74lvc2g17` block, or a generically named sibling (`OW-MISC-SN74LVC2G17DRYR`) | the two BNC inputs |
| 3 | `OW-MISC-SN74LVC2G17DRYR` | per-camera output Schmitts |
| 3 | `OW-MISC-SN74LVC1G125DRYR` | per-camera Line 3 drivers |
| 5 | `OW-MISC-USBLC6-2P6` | ESD: inputs, outputs, three camera connectors |
| 6 | `OW-MISC-APHHS1005CGCK` / `SYCK` / `SURCK` 0402 LEDs | power, 2 inputs, 3 outputs |
| ~30 | 0402 resistors: `OW-PASS-0402WGF1000TCE` 100 Ω (taps), `OW-PASS-RC0402FR-071KL` 1 kΩ (Line 2 pull-ups), `OW-RES-4K7-0402` (Line 1 pull-ups, input series), `OW-RES-10K-0402`, 100 kΩ | |

To add to `kicad-libs` (coordinate with the agent currently working there):

1. `SN74LVC1G07DRYR` open-drain buffer, same DRY6 footprint family as the
   existing `1G125`/`2G17`, plus `internal_parts.csv` and
   `vendor_map_jlcpcb.csv` rows. Three used.
2. 0402 resistor rows for **220 Ω** (Line 3 series and BNC output series),
   **680 Ω** (LEDs) and **820 Ω** (Line 0 pull-up) if absent. Acceptable
   substitutes from stock: 100 Ω for the Line 3 series (not for the BNC
   outputs, see the DAC back-drive case), 1 kΩ for the LEDs, 1 kΩ for the
   Line 0 pull-up (≈3.4 mA into the opto LED, inside 3.5–7 mA once the
   LVC1G07's own drop is counted, but closer to the edge).
3. New design block `blackfly_s_gpio_channel_mcv6_vertical` (the per-camera
   circuit above, connector inside because the pinout is the camera's).
4. Optionally a generically named sibling of the quadrature block
   (`logic_input_5v_tolerant_sn74lvc2g17`) so the input sheet does not say
   `ENC_A_RAW`. Reusing the encoder block with renamed board nets is
   acceptable for Rev 0; capacitor value 47 pF either way.

No solder jumpers, no DIP switches, no headers with shunts.

## Schematic Structure

Repo scaffold from `kicad-libs`: `orb-weaver-kicad-init-repo`, then
`orb-weaver-kicad-create-project` (project in `kicad/`, basename
`camera-gpio-interface-pcb`), library tables via `${ORB_WEAVER_KICAD_LIBS}` as
in the two reference repos, `make docs` for `docs/generated/` and the README
block.

Root sheet with board-authored wrapper sheets (wrappers hold the BNCs,
terminations, LEDs and taps; blocks are copies, re-annotated into 4-digit
bands as on `mouse-joystick-pcb`):

```
camera-gpio-interface-pcb (root)
├── power            → usb2_vertical, 5v_to_3v3_tps73733, power LED
├── inputs           → 2× BNC, USBLC6, input Schmitt block,
│                      2 LEDs, EXP_IN/SYNC_IN taps
├── camera_1         → blackfly_s_gpio_channel_mcv6_vertical, CAM1 OUT BNC, output USBLC6 (shared)
├── camera_2         → same
├── camera_3         → same
└── instrument_port  → instrument_port_digital_50_dut_ffc_boundary_vertical, unused inputs to GND
```

Docs to create alongside: `docs/interface-map.md` (connector pinouts,
InstrumentPort table above, Silk Map), `docs/design-block-map.md`,
`docs/harness-pinouts.md` (camera cable colours and plug wiring for the lab,
plus the SpinView table above), `docs/validation-plan.md`,
`docs/bringup-log.md`.

## What The Board Replaces

For the record only. The lab's drawing shows, per camera: green (Line 3)
straight to an `RSync` BNC centre with the shield unconnected; black (Line 0)
to a `Cam IN` BNC centre with blue and brown both on that BNC's shield, the
only ground return in the harness; white (`OPTOOUT`) to a `Cam OUT` BNC with a
hand-soldered 10 kΩ to red (`VOUT`) and the shield unconnected. The drawing is
not trusted as a specification, but its symptoms — floating BNC shields, a
3.6 V-max input driven straight from an unknown source, the slow opto output —
are what the sections above are designed against.

## Decided By The Source And Consumer

- Source level and drive: 3.3 V CMOS microcontroller pins behind 100 Ω, so
  high-impedance inputs, no termination, 3.3 V thresholds. Decided.
- Consumer: OneBox ADC channels via the SDR breakout BNCs, high impedance,
  ±5 V range. Outputs fixed at 3.3 V through 220 Ω. Decided.

## Open Decisions Before Schematic Capture

1. **Isolation.** Accept one common ground (recommended for Rev 0), or fund
   the isolated variant now for the ephys rig? The OneBox, the pyControl
   breakout and the camera USB hosts will all share this board's ground.
2. **Orientation and enclosure.** Vertical BNC/terminal/USB (top-entry, as on
   `mouse-joystick-pcb`) versus right-angle at the board edge for a panel box.
3. **Library additions.** Approve `SN74LVC1G07`, the resistor rows, the
   per-camera design block, and whether to author the generically named input
   block; sequence them with the in-flight `kicad-libs` cleanup.
4. **Cable.** Which FLIR GPIO cable length the lab buys; the plan assumes
   flying leads screwed into Phoenix `MC 1,5/6-ST-3,5` plugs.
5. **How the cameras consume `SYNC`.** Not a board question (Line 0 is an
   input either way), but the SpinView table above should name the exact
   feature — chunk line status, counter, or `AcquisitionStart` trigger — once
   known. Likewise whether the OneBox records `SYNC` through a tee at the
   breakout or only through the camera outputs.

## Sequence

1. Answer the open decisions (one message from the lab covers 1 and 5).
2. Land the `kicad-libs` additions and the per-camera design block, run
   `make design-blocks-check DESIGN_BLOCK_CHECK_ARGS="--jobs 1"`.
3. Scaffold this repo, place blocks, wire wrappers, ERC clean.
4. Layout, four layers, apply the `INSTRUMENT` netclass, DRC clean, `make docs`.
5. `make fab` for JLCPCB; order with three `MC 1,5/6-ST-3,5` plugs and the
   camera cables.
6. Bring-up: measure Line 0 LED current at the plug against 3.5–7 mA, Line 2
   and `OPTOOUT` low levels against the Schmitt thresholds, and capture all
   17 channels through the LA5032 adapter with one camera in `TriggerWidth`
   mode.
