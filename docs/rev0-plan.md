# Camera GPIO Interface PCB Rev 0 Plan

**Status:** Draft 2026-09-23. Revised the same day three times: to design from
the camera's documented electrical behaviour rather than the lab's harness
drawing; to fold in the signal source (pyControl breakout BNCs) and consumer
(Neuropixels OneBox); and to fold in the rig's actual configuration from
`~/Repositories/github/joystick-rig/` plus Peter's decisions on ground,
orientation, cable, parts, block authoring and camera model. No KiCad
project yet. The only open item is the silkscreen wording.
**Purpose:** Replace the hand-built harness (BNC tees, minigrabber clips and a
hand-soldered pull-up per camera) that connects three FLIR Blackfly S
`BFS-U3-20S4M-C` cameras to a pyControl breakout and a Neuropixels OneBox
with one board that has pluggable screw-terminal camera connectors, six BNCs,
defined logic levels and drive currents on every camera pin, protection on
every field-wired pin, and an InstrumentPort so every camera line can be
watched on a logic analyzer during an experiment.

Source material: `tmp/BFS-U3-20S4-Datasheet.pdf`,
`tmp/BFS-U3-Getting-Started-1.pdf`, `tmp/General Purpose Input Output
(GPIO).html`, `tmp/onebox-datasheet.pdf`, `tmp/onebox-user-manual.pdf`
(v1.0.1), `~/Repositories/github/pycontrol-h7-breakout/pcb/` (rev 0.8,
2026-08-19), `~/Repositories/github/joystick-rig/` (notably
`pycontrol/hardware_definitions/hardware_definition_joystick.py`,
`notes/README_Cams_260804.txt`, `channel_maps/260804_onebox_aux_map.md`,
`scripts/rig1_common.py`, `Hardware/rig1_wiring_sheet_20260828.png`), the
FLIR pages
`https://softwareservices.flir.com/BFS-U3-20S4/latest/40-Installation/ElectricalGPIO.htm`
and `.../InputOutputControl.htm`, and the FLIR multi-camera synchronisation
application note. `tmp/` is gitignored, so the facts that matter are copied
into this document.

## What The Board Is

Three identical camera channels, two shared inputs, one buffered sync copy
for the OneBox, one InstrumentPort, USB power. No MCU, no firmware, no
configuration jumpers.

```
pyControl BNC_1  ─ TRIG IN BNC ─ Schmitt ─┬─ 3.3 V driver ─┐
  (150 Hz)                                ├─ 3.3 V driver ─┼─ camera Line 3 (fast input)
                                          └─ 3.3 V driver ─┘
pyControl DAC_2  ─ SYNC IN BNC ─ Schmitt ─┬─ opto driver ──┐
  (Rsync)                                 ├─ opto driver ──┼─ camera Line 0 (opto input)
                                          ├─ opto driver ──┘
                                          └─ 3.3 V driver ─── SYNC OUT BNC ─ OneBox ADC0
camera Line 2 (open-drain out) ─ pull-up ─ Schmitt ─ CAMn OUT BNC ─ OneBox ADC1..3   (×3)
every camera line ─ 100 Ω tap ─ InstrumentPort-Digital-50
```

Which BNC reaches which camera line is fixed and printed on the board; a
change of role is a cable swap plus a SpinView setting, not a rework.

## The Rig As It Runs Today (2026-08, from `joystick-rig`)

| Item | Today |
| --- | --- |
| Controller | pyControl **Breakout Board 1.2** (STM32F405 pyboard). The H7 Breakout (rev 0.8) is the planned replacement. Both put bare 3.3 V microcontroller pins on their BNCs. |
| Frame trigger | `Frame_trigger(pin=board.BNC_1, pulse_rate=150)`: 150 Hz square wave, 50 % duty from the timer ISR. Pyboard pin `X12`. → 3-way BNC tee → both cameras **Line 0**. |
| Rsync | `Rsync(pin=board.DAC_2, mean_IPI=1000, pulse_dur=25)`: 25 ms pulses, gaps uniform 100–1900 ms. Pyboard pin `X6`, "NOT 5 V tolerant". → 4-way tee → both cameras **Line 3** and **OneBox ADC0**. |
| Camera output | **Line 1** `OPTOOUT`, `LineSource = ExposureActive`, 10 kΩ hand-soldered pull-up to Line 2 with `V3_3Enable = true`. → OneBox **ADC1** (cam 1), **ADC2** (cam 2). ADC3 reserved for cam 3. |
| Camera settings | `ExposureMode = Timed`, `ExposureTime = 3998 µs`, `TriggerSelector = FrameStart`, `TriggerSource = Line0`, `RisingEdge`, `TriggerOverlap = ReadOut`, `AcquisitionFrameRateEnable` off, `ChunkModeActive` with `FrameID`, `Timestamp`, `ExposureEndLineStatusAll`; saved as `UserSet0` and made default. |
| Rsync on the camera side | `ExposureEndLineStatusAll` bit 3 (Line 3) sampled once per frame; `RSYNC_BIT = 3` in `scripts/rig1_common.py`. |
| Grounds | Camera pins 5 and 6 bonded to the CAM IN BNC shell; other BNC shells floating. The hardware definition itself flags the CAM OUT shell as an open item. |
| Third output | `BNC_2` (`X11`) drives the Plexon LD-1 opto gate. Not this board's business, but note the H7 rev 0.8 has only two BNC jacks for three BNC-type uses, so one will move to its terminal block or an RJ45 port — still a 3.3 V pin. |

The hardware definition already records the planned change "Swap trigger
onto Line 3 (Green) and rsync onto Line 0 (Black)" with the same reasoning
this plan uses, and lists the software steps: `TriggerSource Line0 → Line3`
and the Rsync bit index. This board implements that swap in copper.

## Source And Consumer

### pyControl breakout BNCs (source of `TRIG` and `SYNC`)

Today: Breakout 1.2, pyboard pins straight to the BNC centre pins. Planned:
H7 Breakout rev 0.8, traced from `pcb/h7_breakout.kicad_pcb`: `BNC_1` (`J2`)
via jumper `JP3` to port-1 `DIO_C` (`PA4`, through `R11` 100 Ω) or via `JP1`
to `D4`; `BNC_2` (`J3`) via `JP4` to port-6 `DIO_C` (`PA5`, `R12` 100 Ω) or
via `JP2` to `D5`; each `DIO_C` net has a `D1213A-04TS-7` ESD array clamped
to the breakout's **+3.3 V**.

Either way each BNC is a 3.3 V CMOS push-pull microcontroller pin, roughly
8 mA of drive, possibly behind 100 Ω, with clamps to 3.3 V. Consequences:

- Inputs must be high impedance. A 50 Ω termination would ask a
  microcontroller pin for 66 mA; no termination footprint is fitted.
- 3.3 V is the input high level; the Schmitt buffer's worst-case VT+ of
  2.0 V leaves 0.9 V of margin. The board's 4.7 kΩ / 100 kΩ network loads the
  pin by about 30 µA.
- Anything this board might ever hand back to a pyControl BNC has to stay
  inside 0–3.3 V, which is why every output below is fixed at 3.3 V
  (`mouse-joystick-pcb` made the same choice for the same reason).

### Neuropixels OneBox (consumer of `SYNC OUT` and `CAMn OUT`)

From the technical user manual v1.0.1 and the rig's channel map:

- Auxiliary inputs are twelve **single-ended ADC channels** (AD7616-P) on the
  SDR connector, reached through the SDR breakout board's BNCs `IO0`–`IO11`.
  Range ±2.5 V, ±5 V (default) or ±10 V. Sampled at a fixed **30.3 kHz**, so
  any edge is timestamped to ±33 µs. SpikeGLX names them `XA0`–`XA11`.
- Each channel has an FPGA comparator usable as trigger or external SYNC
  source, "33 µs jitter". `ADC0` is the rig's master sync reference; TPrime
  realigns everything to it.
- Each SDR pin is shared between an ADC input and a DAC output (AD5766, ±5 V,
  20 mA) through a software switch. The manual: "imperative to disconnect the
  corresponding DAC output." The rig already enforces this for `IO0`–`IO2`;
  with this board it applies to `IO0`–`IO3`.
- The back-panel `SMA1` input wants 5 V TTL. Not targeted.

Consequences: 3.3 V outputs into high-impedance loads, series resistors sized
so an accidentally enabled ±5 V DAC on the far end cannot destroy the driver,
and an ESD array on the output BNCs. **The OneBox's 33 µs sampling grid, not
this board, sets the timing resolution of the frame record.** The 1 µs Line 2
output keeps the board out of that error budget where the 36 µs opto output
would have doubled it.

### The tees go away

Today Rsync reaches the OneBox through the fourth leg of a BNC tee, and the
trigger reaches two cameras through a three-way tee. With this board
pyControl's two BNCs each go to one input BNC here, the cameras hang off
their screw plugs, and the OneBox gets four direct cables from this board:
`SYNC OUT → IO0`, `CAM1 OUT → IO1`, `CAM2 OUT → IO2`, `CAM3 OUT → IO3`. No
tees, no minigrabbers, and every BNC shell is grounded.

## Camera GPIO Facts (BFS-U3-20S4, cased)

Connector on the camera: Hirose `HR10A-7R-6PB`. Mating plug: `HR10A-7P-6S(73)`.
Cable: 1 m FLIR GPIO cable with flying leads, terminated at this end in a
Phoenix `MC 1,5/6-ST-3,5` screw plug. Wire colours are the FLIR
cable-assembly colours.

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
  instead of guessing at it. (The rig drives Line 0 today straight from a
  3.3 V pin with no resistor and it works; the board keeps the documented
  condition rather than the empirical one.)
- `OPTOOUT` low level is **0.92 V** with 5 V / 1 kΩ and **1.47 V** with
  3.3 V / 200 Ω: the opto transistor has roughly 200 Ω of internal drop plus
  saturation. A weak pull-up is required if anything reads it at 3.3 V logic.
- Non-isolated open-drain output: 3.3 V through 1 kΩ sinks 3.1 mA, i.e. a
  real FET with about 0.2 V low level.
- "Both the opto-isolated input and output have over current protection. To
  avoid damage, connect the OPTO_GND pin first before applying voltage to the
  GPIO line." A pluggable plug mates all six contacts at once.

## Camera Line Assignment

| Board signal | Camera line | Why |
| --- | --- | --- |
| `TRIG` (150 Hz frame trigger) | **Line 3** (`GPI`, pin 1, green) | ≤1 µs, symmetric. The timing-critical edge belongs on the fast input. This is the swap the hardware definition already planned. |
| `SYNC` (Rsync, 25 ms pulses) | **Line 0** (`OPTOIN`, pin 2, black) | Sampled once per frame at exposure end; identity matters, not microseconds, so the 18 µs delay costs nothing. Current-driven and 30 V tolerant. |
| `CAMn_OUT` (`ExposureActive`) | **Line 2** (`GPIO`, pin 3, red) as open-drain output, 1 kΩ pull-up on the board | ≤1 µs and a clean FET low level, versus ≤36 µs / 18 µs and a ~1 V low on `OPTOOUT`. Costs the camera's `VOUT`, which a USB-powered board does not need. |
| — | Line 1 (`OPTOOUT`, pin 4, white) | Not used for the BNC. Pulled up weakly and buffered to the InstrumentPort only, so a second camera output (e.g. `FrameTriggerWait`) can be watched when diagnosing missed triggers. |

No swap jumpers. Both input BNCs have identical conditioning; reversing roles
is a cable swap plus `TriggerSource`.

### Software changes that go with this board

| Where | Today | With this board |
| --- | --- | --- |
| Camera `TriggerSource` | `Line0` | **`Line3`** |
| Camera Line 3 | `LineMode = Input` (Rsync) | `LineMode = Input` (trigger). Optional `LineInputFilterSelector = Deglitch`. |
| Camera Line 0 | `Input` (trigger) | `Input` (Rsync) |
| Camera Line 2 | `V3_3Enable = true` | **`V3_3Enable = false`**, `LineMode = Output`, `LineSource = ExposureActive` |
| Camera Line 1 | `Output`, `ExposureActive` | `LineSource = Off` (or a diagnostic source; InstrumentPort only) |
| `scripts/rig1_common.py` | `RSYNC_BIT = 3` | **`RSYNC_BIT = 0`**; add `CH_CAM3 = 3`; `CAMERA_SERIALS` gains the third camera |
| `channel_maps/…onebox_aux_map.md` | ADC0 Rsync via tee, ADC1–2 strobes from Line 1 | ADC0 `SYNC OUT` from this board, ADC1–3 `CAMn OUT` from this board (Line 2) |
| SpikeGLX Obx Setup | IO0–IO2 as ADC inputs | **IO0–IO3** as ADC inputs, DACs disconnected |
| `hardware_definition_joystick.py` pin map comments | tees, minigrabbers, 10 kΩ | this board; the "planned change" block becomes done |

Apply with `TriggerMode = Off` first and re-save `UserSet0` with
`UserSetDefault = UserSet0`, exactly as the rig's README already instructs. If
`V3_3Enable` is left on nothing is damaged: the camera's 3.3 V holds the Line 2
node high through the board's 1 kΩ until it is switched off.

## Ground

One board ground — Peter's decision 2026-09-23, matching how the rig already
runs. Camera pins 5 and 6 both land on it at each connector, every BNC shell
lands on it, the USB shell lands on it. If ground-loop noise ever shows up on
the probe, the fix is a later isolated variant (Line 0 in, Line 1 out, Line 3
in through a one-channel digital isolator powered from the camera's `VOUT`,
pin 6 never touching the board); it is not in Rev 0.

## Signal Chains

### Inputs (`TRIG IN`, `SYNC IN`), one chain each

1. BNC, shell to ground. No termination footprint.
2. `USBLC6-2P6` ESD array (one part covers both inputs), `VBUS` pin on
   `+5V_USB` so the clamp sits above a 5 V logic high and never conducts on a
   3.3 V signal.
3. Series 4.7 kΩ, 47 pF to ground (≈700 kHz corner), 100 kΩ pull-down on the
   BNC side, into an `SN74LVC2G17` Schmitt buffer at 3.3 V; 100 kΩ pull-down on
   each buffer output for Ioff. This is the circuit of the existing
   `quadrature_encoder_input_5v_sn74lvc2g17` block. An unplugged BNC reads low,
   so the cameras receive nothing rather than noise.
4. Result: `TRIG_IN`, `SYNC_IN`, 3.3 V logic. The chain also tolerates a 5 V
   source or a ±5 V OneBox DAC output plugged in by mistake (LVC inputs are
   5.5 V tolerant; the 4.7 kΩ bounds the negative-side clamp current to about
   1 mA). Hysteresis is ≥0.4 V, so a slow or noisy edge cannot double-trigger.
5. `TRIG_IN` feeds the three Line 3 drivers; `SYNC_IN` feeds the three Line 0
   drivers and the `SYNC OUT` driver. Each has an activity LED (0402, ~1.8 mA
   through 680 Ω) and an InstrumentPort tap. A 25 ms Rsync pulse once a second
   will be a visible blink; the 150 Hz trigger will look steadily half-lit.

### `SYNC OUT` (to OneBox `IO0`)

`SN74LVC1G125` at 3.3 V, `~OE` tied to ground, input `SYNC_IN`, output through
**470 Ω, 0603** to its own BNC. A dedicated driver so a fault on the OneBox cable
cannot disturb the three camera drivers sharing `SYNC_IN`. Shares the output
ESD array below.

### Per camera (×3) — one proposed new design block

| Camera pin | Board circuit |
| --- | --- |
| 1 (Line 3, green) | `SN74LVC1G125` at 3.3 V, `~OE` tied to ground, input `TRIG_IN`, output through **220 Ω, 0603** to the pin. A per-camera buffer means a shorted cable pulls one channel down, not all three; 220 Ω bounds that fault to 15 mA (50 mW, so a 1/10 W 0603 rather than a 1/16 W 0402) and slows the edge to ~25 ns into the ~100 pF of a 1 m lead, still far faster than the camera's 1 µs input and kinder to an unshielded harness than a bare CMOS edge. |
| 2 (Line 0, black) | `SN74LVC1G07` open-drain buffer at 3.3 V, input `SYNC_IN`, output node pulled up through **820 Ω to `+5V_USB`** (≈4.7 V after the USB block's Schottky) and wired to the pin. Signal high → buffer off → the opto LED sees the same drive as FLIR's 5 V / 1 kΩ test condition, ≈4 mA. Signal low → buffer sinks the 820 Ω, LED off. LVC1G07's open-drain output is rated to 5.5 V. |
| 3 (Line 2, red) | **1 kΩ pull-up to `+3.3V`**, node `CAMn_L2`: 3.1 mA when the camera pulls low, ~0.1 µs rise into ~100 pF. Into channel A of an `SN74LVC2G17` Schmitt → `CAMn_OUT`. |
| 4 (Line 1, white) | **4.7 kΩ pull-up to `+3.3V`**, node `CAMn_L1`. Weak on purpose: ~0.6 mA keeps the opto transistor's low level near 0.4 V, under the Schmitt's worst-case VT− of 0.8 V. Into channel B of the same `SN74LVC2G17` → `CAMn_L1_BUF`, InstrumentPort only. |
| 5, 6 (blue, brown) | Ground, both. |
| pins 1–4 | One `USBLC6-2P6` per connector, four lines, `VBUS` pin on `+5V_USB` (the Line 0 node swings to ~4.7 V, so the clamp has to reference 5 V, not 3.3 V). |

`CAMn_OUT` drives its BNC through **470 Ω, 0603**, an activity LED through
680 Ω, and an InstrumentPort tap. A shorted BNC costs 7 mA at the Schmitt
output. An OneBox DAC left enabled on the far end is held at the ESD clamp
(about −0.8 V or +5.5 V) and costs 9–12 mA through the driver, inside the
LVC2G17's 24 mA recommended sink at 3 V, and at most 64 mW in the resistor
continuously, inside a 1/10 W 0603. Either way the LED and the tap stay alive.
(220 Ω was the first choice; it would have put 25 mA through the driver and
137 mW through the resistor in the +5 V case, which for `SYNC OUT`, low 97 %
of the time, is continuous.)

Block ports: `TRIG_IN`, `SYNC_IN` in; `CAM_OUT` out; `+3.3V`, `+5V`, `GND`;
taps `L3_INST`, `L0_INST`, `L2_INST`, `L1_INST`, `OUT_INST` (100 Ω each, T-tap
in the branch, following the `mouse-joystick-pcb` tap rules: 100 Ω on timing
signals, `_INST` suffix on block pins and board nets alike).

Fallback if `SN74LVC1G07` is unwelcome: a second `SN74LVC1G125` with its
input grounded and the signal on `~OE`, output pulled to 5 V (LVC three-state
outputs are rated to 5.5 V). It works but reads badly in a schematic.

#### Design block specification: `blackfly_s_gpio_channel_mcv6_vertical`

Authored in `kicad-libs/design_blocks/orb_weaver_private.kicad_blocks/`
before this schematic starts (Peter, 2026-09-23), placed three times here.
Everything camera-specific lives inside so the board sheet is just wiring.

| Item | Content |
| --- | --- |
| Connector | `J` — `OW-CONN-TBH-1X06-3P5-VERT`, pins 1–6 = camera pins 1–6. Inside the block because the pinout is the camera's, following the `limit_switch_debounced_input_vertical` precedent. |
| Line 3 driver | `U` — `OW-MISC-SN74LVC1G125DRYR`, `~OE` to `GND`, `A` = `TRIG_IN`, `Y` → 220 Ω (0603) → pin 1 node `L3`. |
| Line 0 driver | `U` — `SN74LVC1G07DRYR` (new part; pins 1 NC, 2 A, 3 GND, 4 Y, 5 NC, 6 VCC on the existing `orb_weaver_smd:DRY6` footprint), `A` = `SYNC_IN`, `Y` = pin 2 node `L0`, 820 Ω (0402) from `L0` to `+5V`. |
| Line 2 / Line 1 | 1 kΩ from pin 3 node `L2` to `+3.3V`; 4.7 kΩ from pin 4 node `L1` to `+3.3V`. |
| Output Schmitt | `U` — `OW-MISC-SN74LVC2G17DRYR`, `1A` = `L2` → `1Y` = `CAM_OUT`; `2A` = `L1` → `2Y` = `L1_BUF`. |
| BNC drive | 470 Ω (0603) from `CAM_OUT` to port `CAM_OUT_BNC` (the BNC itself stays on the board sheet, as `mouse-joystick-pcb` does). |
| LED | `OW-MISC-APHHS1005CGCK` + 680 Ω from `CAM_OUT`. |
| ESD | `OW-MISC-USBLC6-2P6` across pins 1–4 nodes, `VBUS` = `+5V`, `GND`. |
| Decoupling | 100 nF at each of the three logic packages. |
| Taps | 100 Ω `OW-PASS-0402WGF1000TCE` T-taps from `L3`, `L0`, `L2`, `L1_BUF`, `CAM_OUT` to ports `L3_INST`, `L0_INST`, `L2_INST`, `L1_INST`, `OUT_INST`. |
| Ports | in: `TRIG_IN`, `SYNC_IN`, `+3.3V`, `+5V`, `GND`. out: `CAM_OUT_BNC`, `L3_INST`, `L0_INST`, `L2_INST`, `L1_INST`, `OUT_INST`. |
| Grounds | Camera pins 5 and 6 both to `GND` inside the block. |
| Refdes band | Pick the next free 5-digit band in `orb_weaver_private` (39xxx is the digital-50 port, 40xxx the RP2040 isolation block); the board re-annotates to 4 digits as usual. |
| Layout notes | Connector on one block edge with the ESD array hard against it; the three DRY6 packages and pull-ups behind it; the five taps and the two inputs on the opposite, board-facing edge. The 820 Ω / `L0` node and the 220 Ω / `L3` node are the only nets leaving toward the connector besides `L2`, `L1`, ground. |
| Description must state | line assignment and why; the 5 V / 1 kΩ opto drive rationale; the weak Line 1 pull-up rationale (`OPTOOUT` ~1 V low at 4 mA); that `+5V` must be a 5 V rail (clamp reference and opto drive both assume it); that `V3_3Enable` must be off on Line 2; that the block is common to all cased BFS-U3 models. |
| Check | `make design-blocks-check DESIGN_BLOCK_CHECK_ARGS="--jobs 1"` and a pin-by-pin netlist read before the first board placement. |

The two BNC inputs reuse `quadrature_encoder_input_5v_sn74lvc2g17` as-is,
with the board binding `ENC_A_RAW`/`ENC_B_RAW` to `TRIG_RAW`/`SYNC_RAW` and
the outputs to `TRIG_IN`/`SYNC_IN`; a generically named copy is optional and
only cosmetic.

### Outputs (`SYNC OUT`, `CAM1..3 OUT`)

**Fixed at 3.3 V.** OneBox ADC inputs are high impedance with a ±5 V range,
and a signal that may one day be fed back into a pyControl BNC has to stay
under that board's 3.3 V clamps. There is no 5 V option.

3.3 V CMOS through **470 Ω (0603, 1/10 W)** into the coax. Not 50 Ω, because
a shorted BNC would draw 66 mA from a part rated for 50 mA. Sized for the
OneBox fault case: if the ±5 V, 20 mA DAC sharing the ADC pin is left
switched in, the ESD clamp holds the node near −0.8 V or +5.5 V and the
resistor sees up to 5.5 V continuously. At 470 Ω that is 12 mA through the
driver (recommended sink limit 24 mA) and 64 mW in the resistor (0603 is
100 mW). At 220 Ω it would have been 25 mA and 137 mW; at 470 Ω on a 1/16 W
0402 it would have been over rating. Into a ~1 MΩ ADC input the 470 Ω costs
0.05 % of amplitude and ~140 ns of edge into a 2 m cable, three orders of
magnitude under the OneBox's 33 µs sample period. One `USBLC6-2P6` covers the
four output BNCs, `VBUS` pin on `+5V_USB`.

## InstrumentPort

Block: `instrument_port_digital_50_dut_ffc_boundary_vertical` from
`orb_weaver_private` (Hirose `FH12-50S-0.5SVA(54)`, four `SN74LV541A`, 100 Ω
source damping, `~OE` pulled low, no disable, supplied from the always-on
3.3 V rail). Contract: `board-interfaces/docs/instrument-port-digital.md`.
Adapter: `la5032-instrument-port-adapter` v2.0 (ordered, untested).

Allocation: one subsystem per octal package, 18 of 32 channels used. Every
tap is 100 Ω because every signal here is a timing edge. Every functional node
already has a DC definition (pull-up, pull-down, or driven), so no `_INST` net
needs its own pull. Every unused buffer input is tied to ground at the board.

| Strand | Package | Net | What it witnesses |
| --- | --- | --- | --- |
| `DIG0` | A | `TRIG_IN_INST` | Conditioned 150 Hz trigger, after the Schmitt |
| `DIG1` | A | `SYNC_IN_INST` | Conditioned Rsync, after the Schmitt |
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
| `DIG19` | C | `SYNC_OUT_INST` | What the `SYNC OUT` BNC carries |
| `DIG20`–`DIG23` | C | `GND` | spare |
| `DIG24`–`DIG31` | D | `GND` | spare |

`DIG0`/`DIG1` are the marker pair on `mouse-joystick-pcb`; this board has no
firmware beacon, so its two board-level inputs take the first pair. The first
sixteen channels hold everything except the four BNC-out copies, so a future
Digital-25 adapter still sees inputs, drives and raw camera outputs.

Netclass: `INSTRUMENT`, pattern `/*_INST`, as on `mouse-joystick-pcb`.

## Power

`usb2_vertical` → `+5V_USB` → `5v_to_3v3_tps73733` → `+3.3V`. `+3.3V` is the
only logic rail and is always-on by construction, which is what the
InstrumentPort block requires. `+5V_USB` is used only for the three Line 0
pull-ups and the ESD-array clamp references. Budget is well under 100 mA:
five `LV541A`, four `LVC2G17`, four `LVC1G125`, three `LVC1G07`, seven LEDs,
pull-ups. Any USB port or wall adapter works; nothing reads the CC
advertisement. Power LED on `+3.3V`.

The `usb2_vertical` block's PCB side is schematic-only as of 2026-09-23; its
layout is done on this board, as `mouse-joystick-pcb` did.

Not chosen: taking 3.3 V from a camera's `VOUT`. It would force Line 2 back to
`VOUT`, push the frame output onto the 36 µs opto line, and make the board
depend on which camera is plugged in.

## Connectors, Mechanical, Silkscreen

Vertical, top-entry parts throughout — Peter's decision 2026-09-23, matching
`mouse-joystick-pcb`. No enclosure in Rev 0; one can be added later.

| Function | Part | Library item |
| --- | --- | --- |
| Camera ×3 | Phoenix MCV 1,5/6-G-3,5 (1843648), vertical | `OW-CONN-TBH-1X06-3P5-VERT`, symbol `orb_weaver_connectors:Conn_01x06_P3.5mm_TBH_Vertical_Screw`, footprint `orb_weaver_tht:PhoenixContact_MCV_1,5_6-G-3.5_1x06_P3.50mm_Vertical` |
| Camera plug ×3 (on the cable, not the PCB BOM) | Phoenix MC 1,5/6-ST-3,5 (1840405) | no 3D model vendored yet |
| BNC ×6 | HenryTech `HL-BNC-KHDA` vertical, 24 mm pitch as on `mouse-joystick-pcb` | `OW-CONN-HL-BNC-KHDA` |
| InstrumentPort | Hirose `FH12-50S-0.5SVA(54)` | inside the DUT block |
| Power | USB-C, GCT `USB4145-03-0070-C` vertical | inside `usb2_vertical` |
| Mounting | 4× M3, 3.2 mm | `OW-MECH-MH-*` |
| Fiducials | 3× | `OW-MECH-FID-1MM-MASK2MM` or similar |

Terminal numbering equals Hirose pin numbering, so the lab wires colours by
position. Silkscreen wording is the one open item; the recommended text is
in the "Open Item" section at the end. Whatever the wording, each camera
terminal carries its pin number and wire colour, the two input BNCs name the
camera line they reach, and the BNC groups are marked `3.3 V LOGIC`.

Mark the FFC `DIGITAL-50 / 3.3 V / OBSERVE ONLY` and pin 1.

Footprint budget: a 6-position plug is ~22 mm wide, so headers at ≥25 mm
pitch (~75 mm for three); six BNCs at 24 mm pitch are ~145 mm in one row, so
split them: two inputs on one edge, four outputs on another. Expect roughly
120 × 80 mm. Four layers, to reuse the design-block layouts unchanged and give
the BNC returns and the FFC block a solid ground plane.

## Parts Summary

Existing in `kicad-libs`:

| Qty | Part | Role |
| --- | --- | --- |
| 3 | `OW-CONN-TBH-1X06-3P5-VERT` | camera connectors |
| 6 | `OW-CONN-HL-BNC-KHDA` | BNCs |
| 1 | `usb2_vertical` block (`OW-CONN-USB-C-USB2-SMD-VERT`, `USBLC6-2P6`, `MBR120VLSFT1G`) | power entry |
| 1 | `5v_to_3v3_tps73733` block (`OW-PWR-TPS73733QDRBRQ1`) | 3.3 V rail |
| 1 | `instrument_port_digital_50_dut_ffc_boundary_vertical` block (`OW-CONN-FH12-50S-0-5SVA-54`, 4× `OW-MISC-SN74LV541ARKSR`, 32× 100 Ω) | InstrumentPort |
| 1 | `quadrature_encoder_input_5v_sn74lvc2g17` block, or a generically named sibling (`OW-MISC-SN74LVC2G17DRYR`) | the two BNC inputs |
| 3 | `OW-MISC-SN74LVC2G17DRYR` | per-camera output Schmitts |
| 4 | `OW-MISC-SN74LVC1G125DRYR` | per-camera Line 3 drivers, `SYNC OUT` driver |
| 5 | `OW-MISC-USBLC6-2P6` | ESD: inputs, outputs, three camera connectors |
| 7 | `OW-MISC-APHHS1005CGCK` / `SYCK` / `SURCK` 0402 LEDs | power, 2 inputs, 3 camera outputs, sync out |
| ~32 | 0402 resistors: `OW-PASS-0402WGF1000TCE` 100 Ω (taps), `OW-PASS-RC0402FR-071KL` 1 kΩ (Line 2 pull-ups), `OW-RES-4K7-0402` (Line 1 pull-ups, input series), `OW-RES-10K-0402`, 100 kΩ | |

To buy and add to `kicad-libs` (Peter, 2026-09-23). Checked: none of these
exist there today, and nothing open-drain exists at all.

| Qty on board | Part | Notes |
| --- | --- | --- |
| 3 | `SN74LVC1G07DRYR` | Open-drain buffer, DRY0006A, same DRY6 land pattern as the existing `SN74LVC1G125DRYR` / `SN74LVC2G17DRYR`. Datasheet checked 2026-09-23 (`tmp/sn74lvc1g07.pdf`, SCES296 rev. Oct 2025), see below. Needs symbol, `internal_parts.csv` and `vendor_map_jlcpcb.csv` rows. **JLCPCB stock unverified**: the LCSC/JLC search pages could not be read; if the DRY part is not stocked, `SN74LVC1G07DCKR` (SC-70-5, LCSC C7830, ~16 k in stock) is the fallback and needs the official `SOT-353_SC-70-5` footprint instead of DRY6. `SN74LVC2G07DRYR` (C2682101) was out of stock. |
| 3 | 220 Ω **0603** 1 % | Line 3 series. 50 mW in a shorted-cable fault, so 1/10 W. |
| 4 | 470 Ω **0603** 1 % | BNC output series. Up to 64 mW continuous in the OneBox DAC fault, so 1/10 W. |
| 6 | 680 Ω 0402 1 % | LEDs, ~3 mW. |
| 3 | 820 Ω 0402 1 % | Line 0 pull-ups to `+5V_USB`, 27 mW continuous while Rsync is low. |

All resistors are ordinary 1 % thick film; nothing needs a tolerance,
temperature coefficient or voltage rating beyond that. Only the two series
values carry a power requirement, hence 0603.

#### `SN74LVC1G07DRYR` datasheet check (2026-09-23)

Against the design's assumptions, from SCES296 (Chinese edition ZHCSM01AG):

| Assumption | Datasheet | OK |
| --- | --- | --- |
| Runs at 3.3 V | VCC 1.65–5.5 V recommended | yes |
| Open-drain output may be pulled to ~4.7 V while VCC = 3.3 V | VO recommended 0–5.5 V independent of VCC; absolute max 6.5 V; "inputs and open-drain output support up to 5.5 V" | yes |
| Sinks the 820 Ω pull-up, ~5.7 mA | IOL 24 mA at VCC = 3 V (32 mA at 4.5 V); VOL ≤ 0.55 V at 24 mA, so ≈0.15 V at 5.7 mA — well under the camera's 1.4 V input-low ceiling | yes |
| Non-inverting: `SYNC_IN` high → opto LED on | Function table A = L → Y = L, A = H → Y = Z (pull-up drives the LED) | yes |
| Driven from the Schmitt output | VIH 2.0 V / VIL 0.8 V at 3–3.6 V; input transition rate must be ≤ 10 ns/V at 3.3 V, which the LVC2G17 output satisfies and a raw BNC would not — the Schmitt stage stays in front of it | yes |
| Ioff, partial power-down | ±10 µA Ioff at VI or VO = 5.5 V with VCC = 0 | yes |
| Speed | tpd ≤ 4.2 ns at 3.3 V | irrelevant against an 18 µs opto input |
| Fits `orb_weaver_smd:DRY6` | DRY0006A USON, 1.0 × 1.45 mm body, 0.5 mm pitch, two rows 0.6 mm apart, TI land example 0.2 × 0.35 mm pads; the DRY6 footprint's 0.3 × 0.4 mm pads at ±0.3 mm, 0.5 mm pitch enclose it. Pinout 1 NC, 2 A, 3 GND, 4 Y, 5 NC, 6 VCC matches the `1G125DRYR` layout (1 `~OE`, 2 A, 3 GND, 4 Y, 5 NC, 6 VCC) pad for pad | yes — but note DRY6 is itself unproven until the ordered `mouse-joystick-pcb` arrives |
| Temperature, orderable | −40 to 125 °C, `SN74LVC1G07DRYR` active, 5000 per reel, Level-1-260C | yes |
| Thermal | RθJA 439 °C/W in DRY; dissipation here ≈ 1 mW | yes |
| — | design block `blackfly_s_gpio_channel_mcv6_vertical` | specified above; authored in `kicad-libs` before this schematic starts. |

Stock substitutes if a value is unavailable: 100 Ω for the Line 3 series
(not for BNC outputs, see the DAC back-drive case), 1 kΩ for LEDs, 1 kΩ for
the Line 0 pull-up (≈3.4 mA into the opto LED, inside 3.5–7 mA once the
LVC1G07's own drop is counted, but closer to the edge).

No solder jumpers, no DIP switches, no headers with shunts.

## Schematic Structure

Repo scaffold from `kicad-libs`: `orb-weaver-kicad-init-repo`, then
`orb-weaver-kicad-create-project` (project in `kicad/`, basename
`camera-gpio-interface-pcb`), library tables via `${ORB_WEAVER_KICAD_LIBS}` as
in the two reference repos, `make docs` for `docs/generated/` and the README
block.

Root sheet with board-authored wrapper sheets (wrappers hold the BNCs, LEDs,
the `SYNC OUT` driver and taps; blocks are copies, re-annotated into 4-digit
bands as on `mouse-joystick-pcb`):

```
camera-gpio-interface-pcb (root)
├── power            → usb2_vertical, 5v_to_3v3_tps73733, power LED
├── inputs           → 2× BNC, USBLC6, input Schmitt block, 2 LEDs,
│                      TRIG_IN/SYNC_IN taps
├── sync_out         → SN74LVC1G125, 470 Ω, BNC, LED, tap (shares the output USBLC6)
├── camera_1         → blackfly_s_gpio_channel_mcv6_vertical, CAM1 OUT BNC
├── camera_2         → same
├── camera_3         → same
└── instrument_port  → instrument_port_digital_50_dut_ffc_boundary_vertical, unused inputs to GND
```

Docs to create alongside: `docs/interface-map.md` (connector pinouts,
InstrumentPort table above, Silk Map), `docs/design-block-map.md`,
`docs/harness-pinouts.md` (camera cable colours, plug wiring, the software
change table above, and the OneBox channel map v2), `docs/validation-plan.md`,
`docs/bringup-log.md`.

## What The Board Replaces

For the record. Per the rig's own notes and the whiteboard photo in
`joystick-rig/notes/assets/06_whiteboard_camera_gpio.jpg`: pyControl `BNC_1`
→ 3-way tee → each camera's black lead (Line 0); pyControl `DAC_2` → 4-way tee
→ each camera's green lead (Line 3) and OneBox `IO0`; each camera's white lead
(Line 1) with a hand-soldered 10 kΩ to its red lead (Line 2 as `VOUT`) →
OneBox `IO1`/`IO2`; blue and brown bonded to the CAM IN BNC shell; other BNC
shells floating; minigrabber clips on flying leads. The rig's hardware
definition flags the floating CAM OUT shell as an open item and lists the
Line 3 / Line 0 swap as planned. This board closes both.

## Decisions Recorded 2026-09-23

- Common ground; isolators only if the rig shows a problem.
- Vertical connectors throughout, matching `mouse-joystick-pcb`; enclosure
  later if needed.
- Camera cable: 1 m FLIR flying-lead GPIO cable into a Phoenix
  `MC 1,5/6-ST-3,5` plug.
- All three cameras are `BFS-U3-20S4M-C`. A different camera later means a
  new board iteration, not a jumper.
- The per-camera design block is authored in `kicad-libs` first; the new
  parts are ordered after those library changes are finished.
- Source is the pyControl breakout's BNCs (Breakout 1.2 today, H7 later);
  consumer is the OneBox ADC via the SDR breakout; outputs fixed at 3.3 V.

## Open Item

**Silkscreen wording** (Peter undecided). Recommendation: label by function
and camera line, never by controller pin name, because the pin names change
with the H7 migration while the function does not:

| BNC | Recommended silk |
| --- | --- |
| input | `TRIG IN  →  CAM LINE 3` |
| input | `SYNC IN  →  CAM LINE 0  +  SYNC OUT` |
| output | `SYNC OUT` |
| output ×3 | `CAM1 OUT`, `CAM2 OUT`, `CAM3 OUT` |
| board | `3.3 V LOGIC` near the BNC group; `IN` and `OUT` groups on different edges |

Camera terminals: `1 GRN L3`, `2 BLK L0`, `3 RED L2`, `4 WHT L1`, `5 BLU`,
`6 BRN`. Which pyControl pin and which OneBox `IO` each cable goes to belongs
in `docs/harness-pinouts.md` and on cable labels, not in copper.

## Sequence

1. In `kicad-libs`: add `SN74LVC1G07DRYR` (or the DCKR fallback), the 220 Ω and 470 Ω 0603 rows and the 680 Ω and 820 Ω 0402 rows,
   author `blackfly_s_gpio_channel_mcv6_vertical` to the specification above,
   run `make design-blocks-check DESIGN_BLOCK_CHECK_ARGS="--jobs 1"`.
2. Order the new parts.
3. Scaffold this repo, place blocks, wire wrappers, ERC clean.
4. Layout, four layers, vertical parts, apply the `INSTRUMENT` netclass, DRC
   clean, `make docs`. Settle the silkscreen wording here.
5. `make fab` for JLCPCB; order with three `MC 1,5/6-ST-3,5` plugs, three 1 m
   FLIR GPIO cables and four BNC cables for the OneBox.
6. Bring-up: measure Line 0 LED current at the plug against 3.5–7 mA, Line 2
   and `OPTOOUT` low levels against the Schmitt thresholds, capture all 18
   channels through the LA5032 adapter with pyControl running
   `camera_sync_test.py`, then apply the software change table and run the
   rig's `rig1_check.py` against a OneBox recording.
