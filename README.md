# Programmable Alarm Clock SoC (Basys3, Artix-7)

## Overview

This project implements a modular programmable alarm-clock system in Verilog HDL for Basys3 (xc7a35tcpg236-1L). The design keeps the 16-bit Harvard CPU/ISA architecture active while running a mode-constrained alarm UX with dedicated peripherals.

Implemented headline behavior:

- 6 modes with constrained transitions (not a simple linear cycle)
- Up to 10 alarms (HH:MM) with occupancy bitmap and duplicate-time rejection
- RTC timekeeping with set-time commit path
- Ringing flow with ALrM display and full-LED blink
- Snooze operations (+5 and +10 minutes)
- Alarm disable challenge mode using 4-bit hex input
- Status LED error pulses (3 pulses, 1 second ON/OFF timing)

## Mode Contract

Mode IDs:

- `0`: Show Time
- `1`: Show Alarms
- `2`: Set Alarm
- `3`: Set Time
- `4`: Ringing
- `5`: Alarm Disable

Transition rules:

- Normal mode-button cycle: `0 -> 1 -> 3 -> 0`
- Enter mode `2` only from mode `1` (`btnD`)
- Enter mode `4` only on alarm match event
- Enter mode `5` only from mode `4` (`btnC`)

## Active Control Mapping

Board inputs are wired in `ac_basys3_top` as follows:

- `btnU` -> mode button (`btn_mode`)
- `btnR` -> confirm/increase (`btn_confirm`)
- `btnL` -> decrement (`btn_hour_up`)
- `btnD` -> decrement/enter-set-alarm/snooze-10 (`btn_min_up`)
- `btnC` -> save/field action (`btn_field_sel`)
- `sw[15]` -> cancel toggle (edge-detected in modes `2` and `3`)

Important: `reset_sw` is tied low in the Basys3 wrapper so SW15 can be used as a cancel toggle.

## Repository Layout

- `dsd_project.srcs/sources_1/new/top/ac_basys3_top.v`: Basys3 wrapper and control mapping
- `dsd_project.srcs/sources_1/new/top/ac_alarm_clock_soc_top.v`: integrated top-level controller/datapath
- `dsd_project.srcs/sources_1/new/cpu/`: 16-bit CPU, ALU, register file, ROM, RAM
- `dsd_project.srcs/sources_1/new/peripherals/`: RTC, alarms, mode manager, LED/display policy, snooze, LFSR
- `dsd_project.srcs/sources_1/new/primitives/`: low-level gates/arithmetic/decoder/mux/input conditioning
- `dsd_project.srcs/constrs_1/new/basys3.xdc`: Basys3 constraints
- `dsd_project.sim/tb/`: unit/smoke testbenches

## Main RTL Modules

| Group       | Module                            | Purpose                                                  |
| ----------- | --------------------------------- | -------------------------------------------------------- |
| Top         | `ac_basys3_top`                   | Basys3 pin-facing wrapper                                |
| Top         | `ac_alarm_clock_soc_top`          | System integration and mode transaction control          |
| CPU         | `ac_cpu16_core`                   | 16-bit multi-cycle CPU                                   |
| CPU         | `ac_instr_rom16`, `ac_data_ram16` | Harvard instruction/data memories                        |
| Peripherals | `ac_mode_manager`                 | Debounced button pulses and constrained mode-cycle state |
| Peripherals | `ac_rtc_timekeeper`               | HH:MM:SS tracking and set-time load                      |
| Peripherals | `ac_alarm_table10`                | 10-slot alarm store, match, and duplicate checking       |
| Peripherals | `ac_snooze_calc`                  | +5/+10 minute rollover arithmetic                        |
| Peripherals | `ac_lfsr4`                        | 4-bit pseudo-random challenge source                     |
| Peripherals | `ac_display_formatter`            | Symbol/time formatting per mode                          |
| Peripherals | `ac_led_controller`               | Occupancy/mode/ringing/error LED policy                  |
| Primitives  | `ac_symbol_to_7seg`               | Symbol+hex decoder for 7-segment output                  |
| Primitives  | `ac_seg7_mux4`                    | 4-digit scan mux using symbol stream                     |

## Build (Vivado)

1. Open `dsd_project.xpr` in Vivado 2023.1.
2. Ensure source set top is `ac_basys3_top`.
3. Ensure `basys3.xdc` is active in `constrs_1`.
4. Run Synthesis, Implementation, and Bitstream generation.
5. Program Basys3 and validate mode flow and alarm behavior on hardware.

## Simulation Assets

Current testbenches in `dsd_project.sim/tb`:

- `tb_ac_ripple_adder16.v`
- `tb_ac_cpu16_smoke.v`
- `tb_ac_snooze_calc.v`
- `tb_ac_mode_manager_6mode.v`

## Documentation

- `REPORT.md`: full architecture/ISA/FSM report with Graphviz diagrams
- `USER_MANUAL.md`: board-facing operation guide for the implemented control semantics

## Notes

- `ac_qspi_persistence_stub` remains a boundary stub for future non-volatile alarm persistence.
- `alarmClock.v` is retained only as a legacy reference and is not the active top-level implementation.
