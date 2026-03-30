module cpu_assertions (
  input logic        clk,
  input logic        rst_n,
  input logic [2:0]  state,
  input logic [31:0] pc,
  input logic        rf_we,
  input logic [31:0] x0_val
);

  // x0 must always be 0
  always_ff @(posedge clk) begin
    if (rst_n) begin
      assert (x0_val == 32'd0)
        else $fatal("x0 violated: x0=%h", x0_val);
    end
  end

  // RegWrite only allowed in WB (WB = 3'd4 in our Day2 encoding)
  always_ff @(posedge clk) begin
    if (rst_n && rf_we) begin
      assert (state == 3'd4)
        else $fatal("RegWrite outside WB! state=%0d", state);
    end
  end

  // PC only changes in FETCH2 (FETCH2 = 3'd1)
  logic [31:0] pc_prev;
  // PC should only change on cycles where the PREVIOUS state was FETCH2
  // (FETCH2 = 3'd1)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_prev <= 32'd0;
    end else begin
      if (pc != pc_prev) begin
        assert ($past(state) == 3'd1)
          else $fatal("PC changed but previous state wasn't FETCH2! prev_state=%0d state=%0d pc=%h prev_pc=%h",
                      $past(state), state, pc, pc_prev);
      end
      pc_prev <= pc;
    end
  end


endmodule
