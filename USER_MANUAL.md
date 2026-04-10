# User Manual

## Programmable Alarm Clock SoC on Basys3 FPGA

## 1. Purpose

This manual explains how to build, program, and use the programmable alarm clock project on a Basys3 board.

It is written for:

- Lab users demonstrating functionality on hardware
- Reviewers validating project behavior
- Developers testing the current RTL build

## 2. Project Summary

The design is a modular FPGA system with:

- 16-bit custom CPU subsystem
- Real-time clock (HH:MM:SS)
- 10-slot alarm table
- 5 operating modes
- 16 LEDs + 4-digit 7-segment display interface
- 4-bit random challenge to dismiss alarms

## 3. Requirements

## 3.1 Hardware

- Digilent Basys3 FPGA board (xc7a35tcpg236-1)
- USB cable for power and programming

## 3.2 Software

- Vivado 2023.1 (recommended to match project file)

## 3.3 Project Files

- Top module: dsd_project.srcs/sources_1/new/top/ac_basys3_top.v
- Constraints: dsd_project.srcs/constrs_1/new/basys3.xdc
- Vivado project: dsd_project.xpr

## 4. Build and Program

1. Open dsd_project.xpr in Vivado.
2. Confirm top module is ac_basys3_top.
3. Confirm constraints set includes basys3.xdc.
4. Run Synthesis.
5. Run Implementation.
6. Generate Bitstream.
7. Open Hardware Manager and program the Basys3.

## 5. Front Panel Control Map

## 5.1 Inputs

| Board Control | RTL Port      | Function                               |
| ------------- | ------------- | -------------------------------------- |
| 100 MHz clock | clk           | Main system clock                      |
| SW[15]        | reset_sw      | System reset (active high)             |
| SW[15:0]      | sw            | Mode-dependent data entry              |
| BTN U         | btn_mode      | Cycle mode                             |
| BTN R         | btn_confirm   | Confirm/apply action                   |
| BTN L         | btn_hour_up   | Reserved in current top-level behavior |
| BTN D         | btn_min_up    | Reserved in current top-level behavior |
| BTN C         | btn_field_sel | Reserved in current top-level behavior |

## 5.2 Outputs

| Board Output | RTL Port | Function                            |
| ------------ | -------- | ----------------------------------- |
| LED[15:0]    | led      | Alarm status and ring indication    |
| AN[3:0]      | an       | 7-segment digit anodes (active low) |
| SEG[6:0]     | seg      | 7-segment segments (active low)     |

## 6. Modes and Behavior

The system defines 5 modes and cycles with BTN U.

Mode sequence:
TIME -> SET_ALARM -> SHOW_ALARM -> RINGING -> SET_TIME -> TIME

## 6.1 Mode 0: TIME

Purpose:

- Display current time in HH:MM

Display:

- 7-seg shows current hour and minute

## 6.2 Mode 1: SET_ALARM

Purpose:

- Write alarm time into selected slot

Inputs:

- Slot index: SW[3:0] (valid slots 0..9)
- Alarm hour: SW[15:11]
- Alarm minute: SW[10:5]
- Commit: BTN R

Result:

- Selected alarm slot is marked valid

## 6.3 Mode 2: SHOW_ALARM

Purpose:

- View stored alarm in selected slot

Inputs:

- Slot index: SW[3:0]

Display:

- If slot valid: HH:MM of that alarm
- If slot invalid: blank pattern (decoder default)

LEDs:

- LED[9:0] show valid slot bitmap
- Selected valid slot LED blinks

## 6.4 Mode 3: RINGING

Entry conditions:

- Automatically entered when current HH:MM matches an active alarm
- Also reachable in cycle path via BTN U

Behavior:

- All LEDs blink
- 7-seg shows random challenge value (00XY format)

Dismiss condition:

- Set SW[3:0] equal to current challenge value
- Matching clears the triggered alarm slot and exits ringing latch

## 6.5 Mode 4: SET_TIME

Purpose:

- Set RTC hour/minute directly from switches

Inputs:

- Hour: SW[15:11]
- Minute: SW[10:5]
- Commit: BTN R

Result:

- RTC time loaded and seconds reset to 00

## 7. Typical User Workflows

## 7.1 Power-up and Reset

1. Program bitstream.
2. Put SW15 low for normal operation.
3. If needed, set SW15 high briefly to reset, then return low.

## 7.2 Set Current Time

1. Press BTN U until SET_TIME mode.
2. Set hour on SW[15:11], minute on SW[10:5].
3. Press BTN R to commit.
4. Return to TIME mode to monitor clock.

## 7.3 Add an Alarm

1. Press BTN U until SET_ALARM mode.
2. Select slot on SW[3:0] (0..9).
3. Set alarm hour on SW[15:11], minute on SW[10:5].
4. Press BTN R.
5. Go to SHOW_ALARM to confirm.

## 7.4 Browse Alarms

1. Press BTN U until SHOW_ALARM mode.
2. Move SW[3:0] to desired slot.
3. Read HH:MM on display; check LED bitmap for valid slots.

## 7.5 Dismiss Ringing Alarm

1. Wait until ringing occurs (or enter mode path for demo).
2. Read challenge value on display (low two digits).
3. Set SW[3:0] to match challenge nibble.
4. Alarm clears and ringing stops.

## 8. Display and LED Reference

## 8.1 7-Segment Display

| Mode       | Display Content                            |
| ---------- | ------------------------------------------ |
| TIME       | Current HH:MM                              |
| SET_ALARM  | Selected alarm HH:MM if valid/just written |
| SHOW_ALARM | Selected alarm HH:MM (or blank if invalid) |
| RINGING    | 00 + challenge value                       |
| SET_TIME   | Current HH:MM after commit                 |

## 8.2 LED Behavior

| Condition                         | LED Output                      |
| --------------------------------- | ------------------------------- |
| Normal (non-ringing)              | LED[9:0] show valid alarm slots |
| SHOW_ALARM on valid selected slot | Selected LED blinks             |
| RINGING                           | All LEDs blink                  |

## 9. Current Build Notes and Limitations

1. BTN L, BTN D, BTN C are debounced and pulse-generated but not yet consumed by top-level set logic.
2. QSPI persistence block is currently a stub boundary module; alarms are not truly non-volatile yet.
3. SW15 is mapped to reset and also overlaps the hour-entry field SW[15:11]. Keep SW15 low during normal entry to avoid unintended reset.
4. Alarm matching compares at minute resolution (HH:MM) using current design logic.

## 10. Troubleshooting

## 10.1 No activity on board

- Verify USB cable and board power.
- Confirm bitstream programming succeeded.
- Confirm SW15 is low after reset.

## 10.2 Vivado reports port or constraint mismatch

- Confirm top module is ac_basys3_top.
- Confirm basys3.xdc is active in constrs_1.
- Re-run Synthesis after project refresh.

## 10.3 Time/alarm not setting

- Ensure you are in correct mode.
- After setting switches, press BTN R to commit.
- Keep SW15 low to avoid reset interruption.

## 10.4 Alarm does not clear in ringing mode

- Match SW[3:0] exactly to displayed challenge nibble.
- Wait for challenge update if blinking/stepping.

## 10.5 Old warnings referencing top_clock

- Ensure legacy alarmClock.v is not active in source set.
- Confirm project top is ac_basys3_top.

## 11. Verification Checklist for Demo Day

- System enters TIME mode and clock runs
- SET_TIME commit updates HH:MM
- SET_ALARM writes slots 0..9
- SHOW_ALARM displays selected slot and occupancy LEDs
- Ringing activates on match
- Challenge-match clears alarm and stops ringing
- No critical synthesis/implementation errors

## 12. Safety and Good Practice

- Do not rapidly toggle reset during programming.
- Keep one known-good bitstream checkpoint for fallback.
- Save Vivado run logs and timing reports for lab submission.

## 13. Quick Reference Card

| Action            | Control              |
| ----------------- | -------------------- |
| Cycle mode        | BTN U                |
| Confirm action    | BTN R                |
| Reset system      | SW15 high            |
| Select alarm slot | SW[3:0]              |
| Set hour          | SW[15:11]            |
| Set minute        | SW[10:5]             |
| Stop ringing      | SW[3:0] == challenge |

## 14. Revision

- Manual version: 1.0
- Date: 2026-04-10
- Target design top: ac_basys3_top
