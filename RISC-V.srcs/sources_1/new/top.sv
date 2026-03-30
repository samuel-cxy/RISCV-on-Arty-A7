`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/25 16:28:40
// Design Name: 
// Module Name: top
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


module top (
    input  logic CLK100MHZ,
    output logic [3:0] led
);

    logic [31:0] pc;
    logic [31:0] instr;

    cpu_core u_core (
        .clk(CLK100MHZ),
        .pc(pc),
        .instr(instr)
    );

    // Heartbeat LED: use a slow bit of PC so it visibly toggles
    // pc increments by 4 each cycle, so pc[25] will blink at a human-visible rate.
    always_comb begin
        led = 4'b0000;
        led[0] = pc[25];
        // Optional debug (won't be visible but keeps signals "used"):
        // led[1]  = instr[0];
        // led[2]  = instr[1];
        // led[3]  = instr[2];
    end

endmodule
