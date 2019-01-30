# Cortex-M0 implementation on a Kintex-7 FPGA

## Overview
Soft-microcontroller implementation of an ARM Cortex-M0 into a KC705. This project implements a design that contains the following components:

- **Cortex-M0 obfuscated core**: core provided by the ARM DesignStart website
- **RAM memory**: implementation of a RAM memory that accepts an initialization file
- **AHB3-lite interconnection**: interconnection responsible for allowing the communication between masters and slaves in AHB3-lite protocol 
- **Pattern detector**: Core that implements a simple state machine that toggles its output when the pattern "f0f0f0f0" is seen on its input bus

When the board is turned on, the cortex-m0 reads the RAM memory, which was synthesized with a program that counts up to a fixed number and then puts the pattern "f0f0f0f0" at the bus. This causes the pattern detector to toggle its output, which it connected to an LED. For the synthesis, the program is defined to count up to 10,000,000. For simulation purposes, a memory file with a program that counts up to 200 is available. 

## Requirements
The tools used in this project are listed below. However, it can be ported to different vendor/boards thanks to the flexibility provided by [hdlmake](https://www.ohwr.org/projects/hdl-make).
- Vivado
- KC705 Evaluation board
- Hdlmake
- ARM Cortex-M0 DesignStart processor, available at [ARM Design Start website](https://www.arm.com/resources/designstart)

## Instructions

- Clone the repository with its submodules:
```sh
$ git clone --recurse-submodules git@github.com:vfinotti/cortex-m0-soft-microcontroller.git
```

- Change the directory to the synthesis folder
```sh
$ cd ./syn/kc705_blinky/verilog/
```
- Copy the files "cortexm0ds_logic.v" and "CORTEXM0INTEGRATION.v" (obtained from the ARM DesignStart website) to *modules/cortex-m0/verilog/*

- run hdlmake to generate the Makefile, and then make the project
```sh
$ hdlmake
$ make
```
<!-- Include instructions for generating the memory file with arm-gcc -->

## References
1. <http://web.fi.uba.ar/~pmartos/publicaciones/ApplicationNoteCortexM0.pdf>: Project which inspired this work
2. <https://static.docs.arm.com/ddi0432/c/DDI0432C_cortex_m0_r0p0_trm.pdf>: Cortex-M0 Technical Reference Manual
3. <https://silver.arm.com/download/download.tm?pv=1085658>: AMBA 3 AHB-Lite Protocol Specification
