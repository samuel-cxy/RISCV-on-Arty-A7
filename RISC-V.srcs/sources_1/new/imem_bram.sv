module imem_bram #(parameter int WORDS = 64) ( // mem holds WORDS 32-bit instrs 
    input logic clk,
    input logic [31:0] addr,   // byte address
    output logic [31:0] rdata
);

    // Memory array (testbench can poke imem.mem[i])
    logic [31:0] mem [0:WORDS-1];

    initial begin
        $readmemh("C:/Users/samue/Documents/Arty-7-100T/RISC-V/imem.hex", mem);
    end

    // Word address: drop 2 LSBs (4-byte aligned)
    logic [$clog2(WORDS)-1:0] waddr;
    assign waddr = addr[2 +: $clog2(WORDS)]; // take N bits starting from bit 2

    // 1-cycle synchronous read (BRAM-like)
    always_ff @(posedge clk) begin
        rdata <= mem[waddr];
    end

endmodule
