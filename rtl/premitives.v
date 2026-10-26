module flopenr #(parameter WIDTH = 8)
            (input clk, rst, en,
            input [WIDTH-1:0] d,
            output reg [WIDTH-1:0] q);
    always @(posedge clk, posedge rst) begin
        if (rst) q <= {WIDTH{1'bz}};
        else if (en) q <= d;
    end
endmodule

module mux_4to1_onehot #(parameter WIDTH = 8)(
    input [4:0] sel,    
    input [WIDTH-1:0] in0,    
    input [WIDTH-1:0] in1,    
    input [WIDTH-1:0] in2,    
    input [WIDTH-1:0] in3,
    input [WIDTH-1:0] in4,    
    output reg [WIDTH-1:0] out
);

always @(*) begin
    out = {WIDTH{1'bz}};
    case (sel)
        5'b00001: out = in0;
        5'b00010: out = in1;
        5'b00100: out = in2;
        5'b01000: out = in3;
        5'b10000: out = in4;
        default: out = {WIDTH{1'bz}};
    endcase
end

endmodule

module demux_1to4_onehot #(parameter WIDTH = 8)(
    input [4:0] sel,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out0,
    output reg [WIDTH-1:0] out1,
    output reg [WIDTH-1:0] out2,
    output reg [WIDTH-1:0] out3,
    output reg [WIDTH-1:0] out4
);

always @(*) begin
    {out0,out1,out2,out3,out4} = {5*WIDTH{1'b0}};
    case (sel)
        5'b00001: out0 = in; 
        5'b00010: out1 = in; 
        5'b00100: out2 = in; 
        5'b01000: out3 = in; 
        5'b10000: out4 = in; 
        default: {out0,out1,out2,out3,out4} = {5*WIDTH{1'b0}};
    endcase
end

endmodule
