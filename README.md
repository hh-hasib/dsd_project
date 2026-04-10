# Programmable Alarm Clock SoC (Basys3, Artix-7)

## Overview

This project implements a modular programmable alarm clock digital system in Verilog HDL for the Basys3 FPGA (xc7a35tcpg236-1). The architecture follows a CPU-driven SoC style with a 16-bit custom core, dedicated peripherals, and a strict low-level module decomposition (gates, adders, comparator, decoders, muxes, and controllers).

The system target features are:

- 5 user modes: Time, Set Alarm, Show Alarm, Ringing, Set Time
- Up to 10 alarms (HH:MM)
- Real-time clock tracking
- Alarm match detection and arbitration (lowest slot first)
- Ringing challenge using pseudo-random 4-bit code
- 16 LEDs and 4-digit 7-segment UI behavior
- Basys3-ready top-level wrapper
- Verification with module and subsystem testbenches

## Current Repository Layout

- dsd_project.srcs/sources_1/new/top/ac_basys3_top.v: Basys3 board-facing top module
- dsd_project.srcs/sources_1/new/top/ac_alarm_clock_soc_top.v: SoC integration top module
- dsd_project.srcs/sources_1/new/cpu/: 16-bit CPU core, ALU, register file, ROM, RAM
- dsd_project.srcs/sources_1/new/peripherals/: RTC, alarm table, mode manager, display/LED control, LFSR, persistence boundary
- dsd_project.srcs/sources_1/new/primitives/: gate-level and arithmetic building blocks
- dsd_project.sim/tb/: starter testbenches
- REPORT.md: complete formal report with tables and Graphviz figures

## Main RTL Modules

| Group       | Module                        | Purpose                                                        |
| ----------- | ----------------------------- | -------------------------------------------------------------- |
| Top         | ac_basys3_top                 | Basys3 IO mapping and wrapper                                  |
| Top         | ac_alarm_clock_soc_top        | Full SoC integration                                           |
| CPU         | ac_cpu16_core                 | 16-bit multi-cycle CPU (Fetch/Decode/Execute/Memory/Writeback) |
| CPU         | ac_alu16                      | ALU operations and flags                                       |
| CPU         | ac_register_file16            | 8x16 register bank                                             |
| CPU         | ac_instr_rom16                | Instruction memory model                                       |
| CPU         | ac_data_ram16                 | Data memory model                                              |
| Peripherals | ac_clock_divider              | 1 Hz and scan tick generation                                  |
| Peripherals | ac_rtc_timekeeper             | HH:MM:SS time counter                                          |
| Peripherals | ac_alarm_table10              | 10-slot alarm storage and match detect                         |
| Peripherals | ac_mode_manager               | 5-mode UI control and debounced button pulses                  |
| Peripherals | ac_lfsr4                      | 4-bit pseudo-random challenge source                           |
| Peripherals | ac_display_formatter          | 7-seg display content selection per mode                       |
| Peripherals | ac_led_controller             | LED policy per mode                                            |
| Peripherals | ac_qspi_persistence_stub      | Persistence interface boundary (stub)                          |
| Primitives  | ac_half_adder / ac_full_adder | Required low-level arithmetic blocks                           |
| Primitives  | ac_ripple_adder16             | 16-bit adder chain                                             |
| Primitives  | ac_adder_subtractor16         | Add/sub unit from low-level blocks                             |
| Primitives  | ac_comparator16               | Compare unit                                                   |
| Primitives  | ac_seg7_mux4 / ac_bcd_to_7seg | Display decode and multiplexing                                |
| Primitives  | ac_debouncer / ac_edge_pulse  | Input conditioning                                             |

## Build and Run (Vivado)

1. Open project file dsd_project.xpr in Vivado.
2. Add all new Verilog files from:
   - dsd_project.srcs/sources_1/new/primitives
   - dsd_project.srcs/sources_1/new/cpu
   - dsd_project.srcs/sources_1/new/peripherals
   - dsd_project.srcs/sources_1/new/top
3. Set top module to ac_basys3_top.
4. Add/create Basys3 XDC constraints (clock, switches, buttons, LEDs, 7-segment pins).
5. Run Synthesis -> Run Implementation -> Generate Bitstream.
6. Program FPGA and validate mode transitions, display behavior, and alarm flow.

## Simulation

Starter testbenches:

- dsd_project.sim/tb/tb_ac_ripple_adder16.v
- dsd_project.sim/tb/tb_ac_cpu16_smoke.v

Recommended progression:

1. Primitive unit tests
2. CPU opcode regression
3. Peripheral tests (RTC, alarm table, mode manager)
4. Full integration tests

## Documentation

See REPORT.md for the complete project report, including:

- requirements and architecture
- ISA and instruction format
- control FSMs
- memory/register organization
- verification matrix
- Graphviz DOT figures with captions

## Notes

- The persistence block is currently modeled with a stub boundary module and is ready for replacement by a full QSPI controller implementation.
- The original prototype file dsd_project.srcs/sources_1/new/alarmClock.v is kept in the repository for reference while the new architecture is implemented in the structured hierarchy above.
