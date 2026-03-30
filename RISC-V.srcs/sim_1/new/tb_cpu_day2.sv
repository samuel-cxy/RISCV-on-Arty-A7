module tb_cpu_day2;
  logic clk = 1'b0;
  logic rst_n = 1'b0;

  logic [31:0] imem_addr;
  logic [31:0] imem_rdata;

  cpu_core dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .imem_addr (imem_addr),
    .imem_rdata(imem_rdata)
  );

  imem_bram #(.WORDS(64)) imem (
    .clk  (clk),
    .addr (imem_addr),
    .rdata(imem_rdata)
  );

  // 10ns period
  always #5 clk = ~clk;

  initial begin
    integer i;

    // init whole memory to NOP to avoid X's
    for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0013; // addi x0,x0,0

    // program:
    // addi x1, x0, 5   = 0x00500093
    // addi x2, x0, 7   = 0x00700113
    // add  x3, x1, x2  = 0x002081B3
    // sub  x4, x2, x1  = 0x40110233
    imem.mem[0] = 32'h0050_0093;
    imem.mem[1] = 32'h0070_0113;
    imem.mem[2] = 32'h0020_81B3;
    imem.mem[3] = 32'h4011_0233;

    // reset
    #20;
    rst_n = 1'b1;

    // run enough cycles: each instruction takes ~4-5 cycles here
    repeat (40) @(posedge clk);

    $display("x1=%0d x2=%0d x3=%0d x4=%0d",
      dut.u_rf.regs[1], dut.u_rf.regs[2], dut.u_rf.regs[3], dut.u_rf.regs[4]);

    // checks
    if (dut.u_rf.regs[1] !== 32'd5)  $fatal("x1 wrong");
    if (dut.u_rf.regs[2] !== 32'd7)  $fatal("x2 wrong");
    if (dut.u_rf.regs[3] !== 32'd12) $fatal("x3 wrong");
    if (dut.u_rf.regs[4] !== 32'd2)  $fatal("x4 wrong");

    $display("DAY2 PASS");
    $finish;
  end
endmodule
