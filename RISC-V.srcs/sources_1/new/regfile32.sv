module regfile32 (
    input logic clk,
    input logic we,           // write enable
    input logic [4:0] waddr,  // write addr
    input logic [31:0] wdata, // write data
    input logic [4:0] raddr1, 
    input logic [4:0] raddr2,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);

    logic [31:0] regs [31:0];

    // combinational reads (force x0 = 0)
    always_comb begin
        rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];
        rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];
    end

    // synchronous write
    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0)) 
            regs[waddr] <= wdata;
        regs[5'd0] <= 32'd0; // keep x0 hardwired to 0
    end
    
endmodule
