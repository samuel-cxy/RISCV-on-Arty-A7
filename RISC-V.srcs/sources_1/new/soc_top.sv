module soc_top (
    input logic CLK100MHZ,
    input logic [3:0] btn, // btn[0] used for reset on Arty
    output logic [3:0] led
);
    logic clk;
    assign clk = CLK100MHZ;

    // Active-high button -> active-low reset for CPU
    logic rst_n;
    assign rst_n = ~btn[0];

    // IMEM
    logic [31:0] imem_addr, imem_rdata;

    // DMEM/MMIO
    logic dmem_we;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    logic [31:0] led_reg;

    cpu_core u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_we(dmem_we),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata)
    );

    imem_bram #(.WORDS(256)) u_imem (
        .clk(clk),
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    dmem_mmio #(.WORDS(256), .LED_ADDR(32'h4000_0000)) u_dmem (
        .clk(clk),
        .we(dmem_we),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata),
        .led_reg(led_reg)
    );

    // Show lowest 4 bits on board LEDs
    assign led = led_reg[3:0];

endmodule
