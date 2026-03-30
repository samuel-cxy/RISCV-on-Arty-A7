module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic sub, // 0 = add, 1 = sub
    output logic [31:0] y
);

    always_comb begin
        y = sub ? (a - b) : (a + b);
    end
    
endmodule
