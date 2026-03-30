module tb_cpu_day4;
  logic clk = 1'b0;
  logic rst_n = 1'b0;

  logic [31:0] imem_addr, imem_rdata;

  logic        dmem_we;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

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

  dmem_bram #(.WORDS(256)) dmem (
    .clk  (clk),
    .we   (dmem_we),
    .addr (dmem_addr),
    .wdata(dmem_wdata),
    .rdata(dmem_rdata)
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

    // init imem to NOP
    for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0013;
    // init dmem to 0
    for (i = 0; i < 256; i++) dmem.mem[i] = 32'd0;

    // program
    imem.mem[0] = 32'h0640_0093; // addi x1,x0,100
    imem.mem[1] = 32'h0010_2023; // sw x1,0(x0)
    imem.mem[2] = 32'h0000_2103; // lw x2,0(x0)

    reset_cpu();
    repeat (120) @(posedge clk);

    $display("x1=%0d x2=%0d mem0=%0d",
      dut.u_rf.regs[1], dut.u_rf.regs[2], dmem.mem[0]);

    if (dut.u_rf.regs[1] !== 32'd100) $fatal("x1 wrong");
    if (dmem.mem[0]       !== 32'd100) $fatal("mem[0] wrong");
    if (dut.u_rf.regs[2] !== 32'd100) $fatal("x2 wrong");

    $display("DAY4 PASS");
    $finish;
  end
endmodule
