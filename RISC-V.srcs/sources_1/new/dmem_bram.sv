module dmem_bram #(parameter int WORDS = 256) (
    input logic clk,
    input logic we,
    input logic [31:0] addr, 
    input logic [31:0] wdata,
    output logic [31:0] rdata
);
    
    logic [31:0] mem [0:WORDS-1];

    // word address (drop 2 LSBs)
    logic [$clog2(WORDS)-1:0] waddr;
    assign waddr = addr[2 +: $clog2(WORDS)];

    always_ff @(posedge clk) begin
        if (we) 
            mem[waddr] <= wdata;
        rdata <= mem[waddr]; // synchronous read
    end
    
endmodule