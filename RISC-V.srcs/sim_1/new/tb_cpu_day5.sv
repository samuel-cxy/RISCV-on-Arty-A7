module tb_cpu_day5;
  logic clk = 1'b0;
  logic rst_n = 1'b0;

  logic [31:0] imem_addr, imem_rdata;
  logic        dmem_we;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

  logic [31:0] led_reg;

  cpu_core dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_we   (dmem_we),
    .dmem_addr (dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_rdata(dmem_rdata)
  );

  imem_bram #(.WORDS(64)) imem (
    .clk  (clk),
    .addr (imem_addr),
    .rdata(imem_rdata)
  );

  dmem_mmio #(.WORDS(256), .LED_ADDR(32'h4000_0000)) dmem (
    .clk     (clk),
    .we      (dmem_we),
    .addr    (dmem_addr),
    .wdata   (dmem_wdata),
    .rdata   (dmem_rdata),
    .led_reg (led_reg)
  );

  always #5 clk = ~clk;

  task automatic reset_cpu();
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (1) @(posedge clk);
  endtask

  initial begin
    integer i;

    // init imem with NOPs
    for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0013;

    // program
    imem.mem[0] = 32'h4000_02B7; // lui  x5,0x40000   -> x5=0x4000_0000
    imem.mem[1] = 32'h0000_0093; // addi x1,x0,0
    imem.mem[2] = 32'h0010_8093; // addi x1,x1,1
    imem.mem[3] = 32'h0012_A023; // sw   x1,0(x5)
    imem.mem[4] = 32'hFE00_0CE3; // beq  x0,x0,-8 (back to imem[2])

    reset_cpu();

    // run some cycles and watch led_reg change
    repeat (200) @(posedge clk);

    $display("led_reg=%0d (0x%h)", led_reg, led_reg);
    if (led_reg === 32'hX || led_reg === 32'd0) $fatal("LED MMIO didn't update!");
    $display("DAY5 PASS");
    $finish;
  end
endmodule
