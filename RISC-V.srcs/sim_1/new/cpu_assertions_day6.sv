module cpu_assertions_day6 (
  input  logic        clk,
  input  logic        rst_n,

  input  logic [2:0]  state,
  input  logic [31:0] pc,

  input  logic        rf_we,
  input  logic [3:0]  itype,

  input  logic        dmem_we,

  input  logic [31:0] x0_val
);
  // ---- State encodings (match your cpu_core typedef enum) ----
  localparam logic [2:0] S_FETCH2 = 3'd1;
  localparam logic [2:0] S_EXEC   = 3'd3;
  localparam logic [2:0] S_MEM    = 3'd4;
  localparam logic [2:0] S_WB     = 3'd5;

  // ---- Instruction encodings (match your cpu_core instr_t enum) ----
  localparam logic [3:0] IT_SW  = 4'd5;
  localparam logic [3:0] IT_BEQ = 4'd6;

  // 1) x0 must always be 0
  always_ff @(posedge clk) begin
    if (rst_n) begin
      assert (x0_val == 32'd0)
        else $fatal("x0 violated: x0=%h", x0_val);
    end
  end

  // 2) RegWrite only allowed in WB
  always_ff @(posedge clk) begin
    if (rst_n && rf_we) begin
      assert (state == S_WB)
        else $fatal("RegWrite outside WB! state=%0d", state);
    end
  end

  // 3) Store enable only in MEM and only for SW
  always_ff @(posedge clk) begin
    if (rst_n && dmem_we) begin
      assert (state == S_MEM)
        else $fatal("dmem_we asserted outside MEM! state=%0d", state);
      assert (itype == IT_SW)
        else $fatal("dmem_we asserted but itype != SW! itype=%0d", itype);
    end
  end

  // 4) PC change legality:
  //    - sequential PC+4 happens in FETCH2
  //    - branch redirect can happen in EXEC when itype==BEQ (taken branch)
  logic [31:0] pc_prev;
  logic [2:0]  state_prev;
  logic [3:0]  itype_prev;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_prev    <= 32'd0;
      state_prev <= 3'd0;
      itype_prev <= 4'd0;
    end else begin
      if (pc != pc_prev) begin
        assert ( (state_prev == S_FETCH2) ||
                 (state_prev == S_EXEC && itype_prev == IT_BEQ) )
          else $fatal("PC changed illegally! prev_state=%0d prev_itype=%0d state=%0d pc=%h prev_pc=%h",
                      state_prev, itype_prev, state, pc, pc_prev);
      end
      pc_prev    <= pc;
      state_prev <= state;
      itype_prev <= itype;
    end
  end

endmodule
