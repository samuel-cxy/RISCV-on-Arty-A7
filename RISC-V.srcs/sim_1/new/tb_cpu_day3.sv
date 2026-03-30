module tb_cpu_day3;
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

  // assertions (Day3)
  logic [2:0]  state_val;
  logic [31:0] pc_val;
  logic        rf_we_val;
  logic [31:0] x0_val;

  assign state_val = dut.state;
  assign pc_val    = dut.pc;
  assign rf_we_val = dut.rf_we;
  assign x0_val    = dut.u_rf.regs[0];

  cpu_assertions asrt (
    .clk    (clk),
    .rst_n  (rst_n),
    .state  (state_val),
    .pc     (pc_val),
    .rf_we  (rf_we_val),
    .x0_val (x0_val)
  );

  imem_bram #(.WORDS(64)) imem (
    .clk  (clk),
    .addr (imem_addr),
    .rdata(imem_rdata)
  );

  always #5 clk = ~clk;

  task automatic reset_cpu();
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (1) @(posedge clk);
  endtask

  task automatic fill_nops();
    integer i;
    for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0013; // addi x0,x0,0
  endtask

  task automatic run_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  initial begin
    // ---------------- Test 1: addi/add/sub ----------------
    fill_nops();

    // addi x1, x0, 5   = 0x00500093
    // addi x2, x0, 7   = 0x00700113
    // add  x3, x1, x2  = 0x002081B3
    // sub  x4, x2, x1  = 0x40110233
    imem.mem[0] = 32'h0050_0093;
    imem.mem[1] = 32'h0070_0113;
    imem.mem[2] = 32'h0020_81B3;
    imem.mem[3] = 32'h4011_0233;

    reset_cpu();
    run_cycles(60);

    if (dut.u_rf.regs[1] !== 32'd5)  $fatal("T1 x1 wrong: %0d", dut.u_rf.regs[1]);
    if (dut.u_rf.regs[2] !== 32'd7)  $fatal("T1 x2 wrong: %0d", dut.u_rf.regs[2]);
    if (dut.u_rf.regs[3] !== 32'd12) $fatal("T1 x3 wrong: %0d", dut.u_rf.regs[3]);
    if (dut.u_rf.regs[4] !== 32'd2)  $fatal("T1 x4 wrong: %0d", dut.u_rf.regs[4]);
    $display("TEST1 PASS");

    // ---------------- Test 2: negative imm + sub ----------------
    fill_nops();

    // addi x1, x0, -1  = 0xFFF00093
    // addi x2, x1, 2   = 0x00208113   (x2 = 1)
    // sub  x3, x2, x1  = 0x401101B3   (x3 = 1 - (-1) = 2)
    imem.mem[0] = 32'hFFF0_0093;
    imem.mem[1] = 32'h0020_8113;
    imem.mem[2] = 32'h4011_01B3;

    reset_cpu();
    run_cycles(60);

    if (dut.u_rf.regs[1] !== 32'hFFFF_FFFF) $fatal("T2 x1 wrong: %h", dut.u_rf.regs[1]);
    if (dut.u_rf.regs[2] !== 32'd1)         $fatal("T2 x2 wrong: %0d", dut.u_rf.regs[2]);
    if (dut.u_rf.regs[3] !== 32'd2)         $fatal("T2 x3 wrong: %0d", dut.u_rf.regs[3]);
    $display("TEST2 PASS");

    $display("DAY3 PASS");
    $finish;
  end
endmodule
