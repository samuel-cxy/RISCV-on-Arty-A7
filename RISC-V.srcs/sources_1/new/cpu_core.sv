module cpu_core (
    input logic clk,
    input logic rst_n, // active low reset

    // IMEM 
    output logic [31:0] imem_addr,
    input logic [31:0] imem_rdata,
    
    // DMEM/MMIO
    output logic dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input logic [31:0] dmem_rdata
);

    // ---------- State FSM ----------
    typedef enum logic [2:0] { 
        S_FETCH1 = 3'd0, // present address
        S_FETCH2 = 3'd1, // latch IR, PC+=4
        S_DECODE = 3'd2, 
        S_EXEC = 3'd3, 
        S_MEM = 3'd4,
        S_WB = 3'd5
    } state_t;

    state_t state;
    
    // ---------- Architectural registers ----------
    logic [31:0] pc;
    logic [31:0] pc_ir; // saved pc before +4 (for beq)
    logic [31:0] ir;    // instruction register
    logic [31:0] A, B;  // regfile latched registers
    logic [31:0] alu_out;
    logic [31:0] mdr;
    
    // ---------- Decode ----------
    // opcode: 7 bits
    // register: 5 bits
    // funct3: 3 bits
    // funct7: 7 bits
    
    // R-type(add, sub): funct7/rs2/rs1/funct3/rd/opcode
    // I-type(addi,lw): imm[11:0]/rs1/funct3/rd/opcode
    // S-type(sw): imm[11:5]/rs2/rs1/funct3/imm[4:0]/opcode
    // B-type(beq): imm[12]/imm[10:5]/rs2/rs1/funct3/imm[4:1]/imm[11]/opcode
    // U-type(lui): imm[31:12]/rd/opcode
    
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rs1, rs2, rd;

    assign opcode = ir[6:0];
    assign rd = ir[11:7];
    assign funct3 = ir[14:12];
    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign funct7 = ir[31:25];

    logic [31:0] immI, immS, immB, immU;
    assign immI = {{20{ir[31]}}, ir[31:20]};                                // sign-extend (sign-extend/imm[11:0])
    assign immS = {{20{ir[31]}}, ir[31:25], ir[11:7]};                      // sign-extend/imm[11:5]/imm[4:0]
    assign immB = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0}; // sign-extend/imm[12]/imm[11]/imm[10:5]/imm[4:1]/0
    assign immU = {ir[31:12], 12'b0};                                       // imm[31:12] << 12

    // ---------- Instruction type ----------
    typedef enum logic [3:0] {
        IT_NOP = 4'd0,
        IT_ADDI = 4'd1,
        IT_ADD = 4'd2,
        IT_SUB = 4'd3,
        IT_LW = 4'd4,
        IT_SW = 4'd5,
        IT_BEQ = 4'd6,
        IT_LUI  = 4'd7
    } instr_t;
    
    instr_t itype;

    // ---------- Regfile ----------
    logic rf_we;
    logic [4:0] rf_waddr;
    logic [31:0] rf_wdata;
    logic [31:0] rf_rdata1, rf_rdata2;

    regfile32 u_rf (
        .clk(clk),
        .we(rf_we),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .raddr1(rs1),
        .raddr2(rs2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2)
    );

    // ---------- ALU ----------
    logic [31:0] alu_a, alu_b, alu_y;
    logic alu_sub;

    alu u_alu (
        .a(alu_a),
        .b(alu_b),
        .sub(alu_sub),
        .y(alu_y)
    );

    // ---------- IMEM ----------
    assign imem_addr = pc;

    // ---------- DMEM ----------
    assign dmem_addr = alu_out;
    assign dmem_wdata = B;

    // ---------- Combinational control/defaults ----------
    always_comb begin
        // defaults
        rf_we = 1'b0;
        rf_waddr = rd;
        rf_wdata = alu_out;

        alu_a = A;
        alu_b = B;
        alu_sub = 1'b0;
        
        dmem_we = 1'b0;

        // EXEC: select ALU op
        if (state == S_EXEC) begin
            unique case (itype)
                IT_ADDI: begin
                    alu_a = A;
                    alu_b = immI;
                    alu_sub = 1'b0;
                end
                IT_ADD: begin
                    alu_a = A;
                    alu_b = B;
                    alu_sub = 1'b0;
                end
                IT_SUB: begin
                    alu_a = A;
                    alu_b = B;
                    alu_sub = 1'b1;
                end
                IT_LW: begin 
                    alu_a = A;
                    alu_b = immI; 
                    alu_sub = 1'b0; 
                end 
                IT_SW: begin 
                    alu_a = A;
                    alu_b = immS; 
                    alu_sub = 1'b0; 
                end 
                default: ;
            endcase
        end

        // MEM: enable store
        if (state == S_MEM && itype == IT_SW) begin
            dmem_we = 1'b1;
        end

        // WB: enable reg write 
        if (state == S_WB) begin
            if (itype == IT_ADDI || itype == IT_ADD || itype == IT_SUB) begin
                rf_we = 1'b1;
                rf_wdata = alu_out;
            end else if (itype == IT_LW) begin
                rf_we = 1'b1;
                rf_wdata = mdr;
            end else if (itype == IT_LUI) begin
                rf_we = 1'b1;
                rf_wdata = alu_out; // set alu_out = immU in EXEC
            end
        end
    end

    // ---------- Sequential FSM ----------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // reset
            state <= S_FETCH1;
            pc <= 32'd0;
            pc_ir <= 32'd0;
            ir <= 32'd0;
            A <= 32'd0;
            B <= 32'd0;
            alu_out <= 32'd0;
            mdr <= 32'd0;
            itype <= IT_NOP;
        end else begin
            unique case (state)
                S_FETCH1: begin // present pc on imem_addr 
                    state <= S_FETCH2;
                end
                S_FETCH2: begin       // latch instruction from sync BRAM
                    ir <= imem_rdata; // from prev cycle because imem is synchronous
                    pc_ir <= pc;      // remember this pc (for beq)
                    pc <= pc + 32'd4;
                    state <= S_DECODE;
                end
                S_DECODE: begin // latch regfile outputs
                    A <= rf_rdata1;
                    B <= rf_rdata2;

                    itype <= IT_NOP;
                    if (opcode == 7'b0010011 && funct3 == 3'b000) // addi
                        itype <= IT_ADDI;
                    else if (opcode == 7'b0110011 && funct3 == 3'b000) // add/sub based on funct7
                        itype <= (funct7 == 7'b0100000) ? IT_SUB : IT_ADD;
                    else if (opcode == 7'b0000011 && funct3 == 3'b010) // lw
                        itype <= IT_LW;
                    else if (opcode == 7'b0100011 && funct3 == 3'b010) // sw
                        itype <= IT_SW;
                    else if (opcode == 7'b1100011 && funct3 == 3'b000) // beq
                        itype <= IT_BEQ;
                    else if (opcode == 7'b0110111) // lui
                        itype <= IT_LUI;

                    state <= S_EXEC;
                end
                S_EXEC: begin 
                    // latch ALU result
                    if (itype == IT_LUI) begin
                        alu_out <= immU;
                    end else begin
                        alu_out <= alu_y;
                    end
                    
                    // branch decision (beq)
                    if (itype == IT_BEQ) begin
                        if (A == B) // jump to target pc
                            pc <= pc_ir + immB; 
                    end
                    
                    state <= S_MEM;
                end
                S_MEM: begin // For lw: latch memory data
                    if (itype == IT_LW) 
                        mdr <= dmem_rdata;
                    state <= S_WB;
                end
                S_WB: begin // regfile write happens on this clock edge via rf_we
                    state <= S_FETCH1;
                end
                default: state <= S_FETCH1;
            endcase
        end
    end
    
endmodule