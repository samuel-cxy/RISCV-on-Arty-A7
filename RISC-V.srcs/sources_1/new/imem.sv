`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/25 16:29:24
// Design Name: 
// Module Name: imem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module imem #(parameter int unsigned WORDS = 64)( // WORDS: #32b-words in instr mem
    input logic [$clog2(WORDS)-1:0] addr_word, // WORDS entries in bits
    output logic [31:0] instr
);

    logic [31:0] rom [0:WORDS-1]; // WORDS-entries array with 32b

    // Initialize with a tiny "program"
    // 0x00000013 = ADDI x0,x0,0 (RISC-V NOP)
    initial begin
        int i;
        for (i = 0; i < WORDS; i++) rom[i] = 32'h0000_0013; // initialize with NOP

        // Put some recognizable patterns so you can confirm fetch in waves
        rom[0] = 32'h0000_0013; // NOP
        rom[1] = 32'h1111_1111;
        rom[2] = 32'h2222_2222;
        rom[3] = 32'h3333_3333;
        rom[4] = 32'h4444_4444;
        rom[5] = 32'h5555_5555;
        rom[6] = 32'h6666_6666;
        rom[7] = 32'h7777_7777;
    end

    // Combinational read (easy for Day-1)
    // update instr when addr_word changes
    always_comb begin 
        if (addr_word < WORDS) // prevent out-of-range
            instr = rom[addr_word];
        else
            instr = 32'h0000_0013; // default NOP
    end
    
endmodule
