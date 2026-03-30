`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/25 16:33:41
// Design Name: 
// Module Name: tb_top
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


module tb_top;
    logic CLK100MHZ;
    wire [3:0] led;

    top dut (
        .CLK100MHZ(CLK100MHZ),
        .led(led)
    );

    // 100 MHz clock = 10ns period
    initial CLK100MHZ = 1'b0;
    always #5 CLK100MHZ = ~CLK100MHZ;

    initial begin
        // Let it run a few cycles and print fetch behavior
        repeat (20) begin
            @(posedge CLK100MHZ);
            $display("t=%0t ns  pc=%08h  instr=%08h  led0=%0d", $time, dut.u_core.pc, dut.u_core.instr, led[0]);
        end

        $display("Simulation done.");
        $finish;
    end

endmodule
