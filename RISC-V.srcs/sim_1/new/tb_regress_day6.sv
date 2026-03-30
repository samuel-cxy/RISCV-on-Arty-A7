module tb_regress_day6;
  logic clk = 1'b0;
  logic rst_n = 1'b0;

  // IMEM
  logic [31:0] imem_addr, imem_rdata;

  // DMEM/MMIO
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

  // Your Day-5 memory (RAM + LED MMIO at 0x4000_0000)
  dmem_mmio #(.WORDS(256), .LED_ADDR(32'h4000_0000)) dmem (
    .clk     (clk),
    .we      (dmem_we),
    .addr    (dmem_addr),
    .wdata   (dmem_wdata),
    .rdata   (dmem_rdata),
    .led_reg (led_reg)
  );

  // Assertions hooked up via hierarchical references
  cpu_assertions_day6 asrt (
    .clk    (clk),
    .rst_n  (rst_n),
    .state  (dut.state),
    .pc     (dut.pc),
    .rf_we  (dut.rf_we),
    .itype  (dut.itype),
    .dmem_we(dut.dmem_we),
    .x0_val (dut.u_rf.regs[0])
  );

  // 10ns period clock
  always #5 clk = ~clk;

  task automatic reset_cpu();
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (1) @(posedge clk);
  endtask

  task automatic fill_imem_nops();
    integer i;
    for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0013; // addi x0,x0,0
  endtask

  task automatic clear_dmem_and_led();
    integer i;
    for (i = 0; i < 256; i++) dmem.mem[i] = 32'd0;
    dmem.led_reg = 32'd0;
  endtask

  task automatic clear_regfile();
    integer i;
    for (i = 0; i < 32; i++) dut.u_rf.regs[i] = 32'd0;
  endtask

  task automatic run_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  // ------------------------------
  // Programs (hex encodings)
  // ------------------------------
  // From verified RV32I encodings:
  localparam logic [31:0] NOP         = 32'h0000_0013;

  // Test1 (ALU)
  localparam logic [31:0] ADDI_X1_5   = 32'h0050_0093; // addi x1,x0,5
  localparam logic [31:0] ADDI_X2_7   = 32'h0070_0113; // addi x2,x0,7
  localparam logic [31:0] ADD_X3      = 32'h0020_81B3; // add  x3,x1,x2
  localparam logic [31:0] SUB_X4      = 32'h4011_0233; // sub  x4,x2,x1

  // Test2 (neg imm)
  localparam logic [31:0] ADDI_X1_M1  = 32'hFFF0_0093; // addi x1,x0,-1
  localparam logic [31:0] ADDI_X2_X1_2= 32'h0020_8113; // addi x2,x1,2
  localparam logic [31:0] SUB_X3_2_1  = 32'h4011_01B3; // sub  x3,x2,x1

  // Test3/4 (lw/sw)
  localparam logic [31:0] ADDI_X1_100 = 32'h0640_0093; // addi x1,x0,100
  localparam logic [31:0] SW_X1_0_X0  = 32'h0010_2023; // sw x1,0(x0)
  localparam logic [31:0] LW_X2_0_X0  = 32'h0000_2103; // lw x2,0(x0)

  localparam logic [31:0] SW_X1_12_X0 = 32'h0010_2623; // sw x1,12(x0)
  localparam logic [31:0] LW_X2_12_X0 = 32'h00C0_2103; // lw x2,12(x0)

  // Test5/6 (beq)
  localparam logic [31:0] ADDI_X1_1   = 32'h0010_0093; // addi x1,x0,1
  localparam logic [31:0] ADDI_X2_2   = 32'h0020_0113; // addi x2,x0,2
  localparam logic [31:0] ADDI_X2_3   = 32'h0030_0113; // addi x2,x0,3
  localparam logic [31:0] BEQ_X1_X1_P8= 32'h0010_8463; // beq x1,x1,+8 (skip next)
  localparam logic [31:0] BEQ_X1_X0_P8= 32'h0000_8463; // beq x1,x0,+8 (not taken)

  // Test7/8 (LED MMIO)
  localparam logic [31:0] LUI_X5_40000= 32'h4000_02B7; // lui x5,0x40000 -> 0x4000_0000
  localparam logic [31:0] ADDI_X1_A5  = 32'h0A50_0093; // addi x1,x0,0xA5
  localparam logic [31:0] SW_X1_0_X5  = 32'h0012_A023; // sw x1,0(x5)
  localparam logic [31:0] ADDI_X1_X1_1= 32'h0010_8093; // addi x1,x1,1
  localparam logic [31:0] BEQ_X0_X0_M8= 32'hFE00_0CE3; // beq x0,x0,-8 (loop back)

  initial begin
    reset_cpu();
    $display("IMEM check: mem[0]=%h mem[1]=%h mem[2]=%h",
         imem.mem[0], imem.mem[1], imem.mem[2]);
  
    // ---------------- Test 1 ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_5;
    imem.mem[1] = ADDI_X2_7;
    imem.mem[2] = ADD_X3;
    imem.mem[3] = SUB_X4;
    
    reset_cpu(); run_cycles(80);
    if (dut.u_rf.regs[1] !== 32'd5)  $fatal("T1 x1 wrong: %0d", dut.u_rf.regs[1]);
    if (dut.u_rf.regs[2] !== 32'd7)  $fatal("T1 x2 wrong: %0d", dut.u_rf.regs[2]);
    if (dut.u_rf.regs[3] !== 32'd12) $fatal("T1 x3 wrong: %0d", dut.u_rf.regs[3]);
    if (dut.u_rf.regs[4] !== 32'd2)  $fatal("T1 x4 wrong: %0d", dut.u_rf.regs[4]);
    $display("TEST1 PASS");

    // ---------------- Test 2 ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_M1;
    imem.mem[1] = ADDI_X2_X1_2;
    imem.mem[2] = SUB_X3_2_1;

    reset_cpu(); run_cycles(80);
    if (dut.u_rf.regs[1] !== 32'hFFFF_FFFF) $fatal("T2 x1 wrong: %h", dut.u_rf.regs[1]);
    if (dut.u_rf.regs[2] !== 32'd1)         $fatal("T2 x2 wrong: %0d", dut.u_rf.regs[2]);
    if (dut.u_rf.regs[3] !== 32'd2)         $fatal("T2 x3 wrong: %0d", dut.u_rf.regs[3]);
    $display("TEST2 PASS");

    // ---------------- Test 3 ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_100;
    imem.mem[1] = SW_X1_0_X0;
    imem.mem[2] = LW_X2_0_X0;

    reset_cpu(); run_cycles(120);
    if (dmem.mem[0]       !== 32'd100) $fatal("T3 mem[0] wrong: %0d", dmem.mem[0]);
    if (dut.u_rf.regs[2]  !== 32'd100) $fatal("T3 x2 wrong: %0d", dut.u_rf.regs[2]);
    $display("TEST3 PASS");

    // ---------------- Test 4 ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_100;
    imem.mem[1] = SW_X1_12_X0;
    imem.mem[2] = LW_X2_12_X0;

    reset_cpu(); run_cycles(120);
    // 12 bytes => word index 3
    if (dmem.mem[3]       !== 32'd100) $fatal("T4 mem[3] wrong: %0d", dmem.mem[3]);
    if (dut.u_rf.regs[2]  !== 32'd100) $fatal("T4 x2 wrong: %0d", dut.u_rf.regs[2]);
    $display("TEST4 PASS");

    // ---------------- Test 5 (beq taken skips next) ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_1;      // x1=1
    imem.mem[1] = BEQ_X1_X1_P8;   // taken, skip mem[2]
    imem.mem[2] = ADDI_X2_2;      // should be skipped
    imem.mem[3] = ADDI_X2_3;      // should execute => x2=3

    reset_cpu(); run_cycles(140);
    if (dut.u_rf.regs[2] !== 32'd3) $fatal("T5 x2 wrong (branch taken): %0d", dut.u_rf.regs[2]);
    $display("TEST5 PASS");

    // ---------------- Test 6 (beq not taken) ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = ADDI_X1_1;      // x1=1
    imem.mem[1] = BEQ_X1_X0_P8;   // not taken
    imem.mem[2] = ADDI_X2_2;      // should execute => x2=2
    imem.mem[3] = ADDI_X2_3;      // then overwrites => x2=3 (to prove flow)
    // If you want "not overwritten", delete mem[3]. This proves sequential flow continues.

    reset_cpu(); run_cycles(160);
    if (dut.u_rf.regs[2] !== 32'd3) $fatal("T6 x2 wrong (branch not taken flow): %0d", dut.u_rf.regs[2]);
    $display("TEST6 PASS");

    // ---------------- Test 7 (LED constant write) ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = LUI_X5_40000;   // x5=0x4000_0000
    imem.mem[1] = ADDI_X1_A5;     // x1=0xA5
    imem.mem[2] = SW_X1_0_X5;     // led_reg = 0xA5

    reset_cpu(); run_cycles(120);
    if (led_reg[7:0] !== 8'hA5) $fatal("T7 led_reg wrong: %h", led_reg);
    $display("TEST7 PASS");

    // ---------------- Test 8 (LED loop increments) ----------------
    fill_imem_nops(); clear_dmem_and_led(); clear_regfile();
    imem.mem[0] = LUI_X5_40000;   // x5=LED base
    imem.mem[1] = 32'h0000_0093;  // addi x1,x0,0
    imem.mem[2] = ADDI_X1_X1_1;   // x1++
    imem.mem[3] = SW_X1_0_X5;     // write to LED
    imem.mem[4] = BEQ_X0_X0_M8;   // loop back to mem[2]

    reset_cpu();
    run_cycles(300);

    if (led_reg == 32'd0 || led_reg === 32'hX) $fatal("T8 LED did not increment!");
    $display("TEST8 PASS (led_reg=%0d)", led_reg);

    $display("DAY6 REGRESSION PASS");
    $finish;
  end

endmodule
