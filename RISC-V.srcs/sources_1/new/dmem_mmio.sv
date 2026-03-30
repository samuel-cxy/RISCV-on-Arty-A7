// Need lui to reach LED addr
module dmem_mmio #(parameter int WORDS = 256, parameter logic [31:0] LED_ADDR = 32'h4000_0000) ( 
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic [31:0] led_reg
);
    
    logic [31:0] mem [0:WORDS-1];

    // word address for normal RAM
    logic [$clog2(WORDS)-1:0] waddr;
    assign waddr = addr[2 +: $clog2(WORDS)]; // ignore 2 LSBs

    logic is_led;
    assign is_led = (addr == LED_ADDR);

    // If is LED addr, update or get LED register; else do normal mem operations
    always_ff @(posedge clk) begin 
        // store/write
        if (we) begin
            if (is_led) 
                led_reg <= wdata;
            else 
                mem[waddr] <= wdata;
        end

        // load/read 
        if (is_led) 
            rdata <= led_reg;
        else
            rdata <= mem[waddr];
    end

endmodule 