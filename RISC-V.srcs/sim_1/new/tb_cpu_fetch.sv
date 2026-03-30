module tb_cpu_fetch;
    logic clk = 1'b0;
    logic rst_n = 1'b1;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    // DUT (device under test)
    cpu_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata)
    );

    // IMEM
    imem_bram #(.WORDS(64)) imem (
        .clk(clk),
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    // 100MHz clock: 10ns period
    always #5 clk = ~clk; // toggle every 5ns

    initial begin
        // Fill a few instructions (NOP = addi x0,x0,0 = 0x00000013)
        
        integer i; 
        for (i = 0; i < 64; i++) imem.mem[i] = 32'h0000_0000;
        
        imem.mem[0] = 32'h1111_1111;
        imem.mem[1] = 32'h2222_2222;
        imem.mem[2] = 32'h3333_3333;
        imem.mem[3] = 32'h4444_4444;

        // Reset
        #5;
        rst_n = 1'b0;
        
        #10;
        rst_n = 1'b1;

        // Run a bit
        repeat (12) begin
            @(posedge clk);
            $display("t=%0t  pc=%08h  imem_addr=%08h  ir=%08h", $time, dut.pc, imem_addr, dut.ir);
        end

        $finish;
    end
endmodule
