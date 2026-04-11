# User Manual

## Programmable Alarm Clock SoC on Basys3 FPGA

## 1. Purpose

This manual describes how to build and use the current alarm-clock implementation on Basys3 with the new 6-mode behavior.

## 2. Project Summary

The active design includes:

- 16-bit CPU subsystem (Harvard, multi-cycle)
- RTC clock (HH:MM:SS)
- 10-slot alarm table
- 6-mode UI flow with constrained transitions
- Snooze (+5/+10 min) and alarm-disable challenge mode
- 16 LEDs + 4-digit 7-segment output

## 3. Requirements

### 3.1 Hardware

- Digilent Basys3 (xc7a35tcpg236-1L)
- USB cable for programming/power

### 3.2 Software

- Vivado 2023.1

### 3.3 Project Files

- Top wrapper: `dsd_project.srcs/sources_1/new/top/ac_basys3_top.v`
- SoC top: `dsd_project.srcs/sources_1/new/top/ac_alarm_clock_soc_top.v`
- Constraints: `dsd_project.srcs/constrs_1/new/basys3.xdc`
- Project file: `dsd_project.xpr`

## 4. Build and Program

1. Open `dsd_project.xpr` in Vivado.
2. Confirm top module is `ac_basys3_top`.
3. Confirm `basys3.xdc` is active in `constrs_1`.
4. Run Synthesis, Implementation, and Generate Bitstream.
5. Program the Basys3 from Hardware Manager.

## 5. Front Panel Control Map

### 5.1 Inputs

| Board Control | RTL Signal      | Active Use                            |
| ------------- | --------------- | ------------------------------------- |
| 100 MHz clock | `clk`           | Main clock                            |
| SW[15:0]      | `sw`            | mode-dependent input                  |
| BTN U         | `btn_mode`      | mode cycle / minute+ / snooze+5       |
| BTN R         | `btn_confirm`   | slot+ / hour+ / confirm disable       |
| BTN L         | `btn_hour_up`   | slot- / hour-                         |
| BTN D         | `btn_min_up`    | enter set-alarm / minute- / snooze+10 |
| BTN C         | `btn_field_sel` | clear/save/enter-disable              |
| SW15 edge     | cancel toggle   | cancel edit in modes 2 and 3          |

Note: `reset_sw` is tied low in the wrapper, so SW15 is used for cancel-toggle behavior instead of hard reset.

### 5.2 Outputs

| Board Output | RTL Port | Function                         |
| ------------ | -------- | -------------------------------- |
| LED[15:0]    | `led`    | occupancy, mode, ringing, status |
| AN[3:0]      | `an`     | active-low digit enables         |
| SEG[6:0]     | `seg`    | active-low segment outputs       |

## 6. Modes and Behavior

Mode IDs:

- Mode 0: Show Time
- Mode 1: Show Alarms
- Mode 2: Set Alarm
- Mode 3: Set Time
- Mode 4: Ringing
- Mode 5: Alarm Disable

Transition contract:

- Normal cycle with BTN U: `0 -> 1 -> 3 -> 0`
- Mode 2 entry only from mode 1 via BTN D
- Mode 4 entry only when an alarm match occurs
- Mode 5 entry only from mode 4 via BTN C

### 6.1 Mode 0: Show Time

- 7-seg shows current `HHMM`
- LED[9:0] indicate alarm occupancy
- BTN U moves to mode 1

### 6.2 Mode 1: Show Alarms

- Displays selected slot alarm `HHMM` if valid, otherwise `AAAA`
- BTN L selects previous slot (wrap 0<-9)
- BTN R selects next slot (wrap 9->0)
- BTN C clears selected slot
- BTN D enters mode 2 for selected slot

### 6.3 Mode 2: Set Alarm

- Edits selected slot alarm time
- BTN L decrements hour
- BTN R increments hour
- BTN U increments minute
- BTN D decrements minute
- BTN C saves alarm and returns to mode 1
- SW15 toggle cancels edit and returns to mode 1
- Duplicate alarm time is rejected and triggers status LED pulses

### 6.4 Mode 3: Set Time

- Edits RTC time staging values
- BTN L decrements hour
- BTN D decrements minute
- BTN C commits edited time and returns to mode 0
- SW15 toggle cancels and returns to mode 0
- BTN U still follows normal cycle path from mode 3 to mode 0

### 6.5 Mode 4: Ringing

- Entered automatically on alarm match
- 7-seg shows `ALrM`
- All LEDs blink
- BTN U snoozes +5 minutes and returns to mode 0
- BTN D snoozes +10 minutes and returns to mode 0
- BTN C enters mode 5 (alarm disable challenge)

### 6.6 Mode 5: Alarm Disable

- 7-seg shows challenge format `[blank][HEX][O][F]`
- User enters HEX value with `SW[3:0]`
- BTN R confirms challenge
- Correct value clears the active alarm and returns to mode 0
- Wrong value triggers status LED pulses, regenerates challenge, stays in mode 5
- BTN U/BTN D provide snooze +5/+10 and return to mode 0

## 7. Typical Workflows

### 7.1 Set Current Time

1. Press BTN U until mode 3.
2. Adjust values with BTN L and BTN D.
3. Press BTN C to commit.

### 7.2 Browse and Edit an Alarm

1. Press BTN U to reach mode 1.
2. Use BTN L/BTN R to pick slot.
3. Press BTN D to enter mode 2.
4. Adjust time with BTN L/BTN R/BTN U/BTN D.
5. Press BTN C to save.

### 7.3 Clear an Alarm Slot

1. In mode 1, select slot.
2. Press BTN C to clear it.

### 7.4 Handle Ringing

1. On alarm trigger, mode 4 starts (`ALrM` display).
2. Choose snooze (BTN U or BTN D) or disable path (BTN C).
3. If disabling, enter challenge value on SW[3:0] and press BTN R.

## 8. Display and LED Reference

### 8.1 7-Segment Output

| Mode | Display                         |
| ---- | ------------------------------- |
| 0    | current time `HHMM`             |
| 1    | selected alarm `HHMM` or `AAAA` |
| 2    | edited alarm time `HHMM`        |
| 3    | edited time `HHMM`              |
| 4    | `ALrM`                          |
| 5    | `[blank][HEX][O][F]`            |

### 8.2 LED Policy

| LED Bits | Meaning                            |
| -------- | ---------------------------------- |
| LED[9:0] | alarm occupancy map (slot 0..9)    |
| LED[10]  | mode 0 indicator                   |
| LED[11]  | mode 1 indicator                   |
| LED[12]  | mode 2 indicator                   |
| LED[13]  | mode 3 indicator                   |
| LED[14]  | mode 4 indicator; blinks in mode 5 |
| LED[15]  | status/error indicator             |

Special behavior:

- Mode 1: selected slot LED blinks
- Mode 4: all LEDs blink
- Error condition: LED[15] pulses three times

## 9. Current Build Notes

1. QSPI persistence remains a stub boundary module.
2. Alarm matching is minute-level (`HH:MM`).
3. SW15 is consumed as cancel-toggle input in edit modes.

## 10. Troubleshooting

### 10.1 No board activity

- Verify board power and programming success.
- Confirm top module and constraints are correct.

### 10.2 Cannot enter Set Alarm mode

- You must be in mode 1 first.
- Press BTN D to enter mode 2.

### 10.3 Alarm disable challenge fails repeatedly

- Ensure SW[3:0] matches displayed HEX digit.
- Press BTN R to confirm.

### 10.4 Status LED blinks 3 pulses

- In mode 2: likely duplicate alarm time.
- In mode 5: wrong challenge input.

## 11. Demo Checklist

- Clock runs in mode 0
- Alarm browse/select works in mode 1
- Save/cancel path works in modes 2 and 3
- Ringing enters mode 4 on match
- Snooze +5/+10 paths work
- Disable challenge clears alarm on correct HEX input

## 12. Revision

- Manual version: 2.0
- Date: 2026-04-11
- Target top: `ac_basys3_top`
