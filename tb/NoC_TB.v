`timescale 1ns / 1ps
module NoC_TB();
    parameter [4:0] DATA_WIDTH = 16;
    parameter [2:0] DEPTH = 4;
    parameter [4:0] SIZE = 16;
    reg clk, rst;
    wire [2*SIZE-1:0] flat_startMod;
    reg [1:0] startMod [0: SIZE -1];
    NoC #(DATA_WIDTH , SIZE, DEPTH) NoC_UT(.clk(clk), .rst(rst), .startMod_flat(flat_startMod));

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : unpack_startMod
            assign flat_startMod[2*i+1:2*i] = startMod[i];
        end
    endgenerate

    initial begin : INITIALIZING
        integer j;
        for(j = 0; j < SIZE; j = j+1) begin
            startMod[j] = 2'b00;
        end
        rst = 1;
        #20 
        rst = 0;
        startMod[8] = 2'b01;
        @(posedge clk);
        startMod[8] = 2'b00;
        startMod[6] = 2'b10;
        @(posedge clk);
        startMod[6] = 2'b00;
        startMod[7] = 2'b11;
        @(posedge clk);
        startMod[7] = 2'b00;
        #1000;
        $stop;
    end
endmodule