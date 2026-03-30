A 5-state RV32I multicycle CPU: supporting 7 instructions, memory interfaces, and LED MMIO.
- Included a SystemVerilog testbench executing 8 programs with assertions for x0=0, RegWrite-in-WB, and
store/PC safety.
- Runs an LED counter loop loading through a HEX file.
- Met timing at 100 MHz on Arty A7 FPGA (+3.568 ns WNS) using 321 LUTs and 328 FFs.
