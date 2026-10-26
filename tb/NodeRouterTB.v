`timescale 1ns / 1ps

module NodeRouter_tb ();

    parameter [4:0] DATA_WIDTH = 16;
    parameter [2:0] DEPTH = 4;
    parameter NR_ID1 = 0;
    parameter NR_ID2 = 1;
    parameter [4:0] SIZE = 16;
    reg clk;
    reg rst;
    reg [1:0] startMod1, startMod2;
    reg [DATA_WIDTH+1:0] data_in_to_N,  data_in_to_W, data_in_to_S;
    wire [DATA_WIDTH+1:0] data_in_to_E2, data_in_to_E1;
    reg req_in_to_N, req_in_to_W, req_in_to_S;
    wire req_in_to_E2, req_in_to_E1;
    wire ack_in_from_N1, ack_in_from_E1, ack_in_from_S1;
    wire ack_in_from_N2, ack_in_from_E2, ack_in_from_W2, ack_in_from_S2;
    wire [DATA_WIDTH+1:0] data_out_from_N1, data_out_from_E1, data_out_from_W1, data_out_from_S1;
    wire [DATA_WIDTH+1:0] data_out_from_N2, data_out_from_E2, data_out_from_W2, data_out_from_S2;
    reg ack_out_to_N1, ack_out_to_W1, ack_out_to_S1;
    reg ack_out_to_N2, ack_out_to_W2, ack_out_to_S2;
    wire ack_out_to_E2, ack_out_to_E1;
    wire req_out_from_N1, req_out_from_E1, req_out_from_W1, req_out_from_S1;
    wire req_out_from_N2, req_out_from_E2, req_out_from_W2, req_out_from_S2;

    NodeRouter #(DATA_WIDTH, SIZE, DEPTH, NR_ID1) NR1(
        .clk(clk), .rst(),
        .startMod(startMod1),
        // signals related to North Port
        .data_in_to_N(data_in_to_N),
        .req_in_to_N(req_in_to_N),
        .ack_in_from_N(ack_in_from_N1),
        .data_out_from_N(data_out_from_N1),
        .ack_out_to_N(ack_out_to_N1),
        .req_out_from_N(req_out_from_N1),
        // signals related to South Port
        .data_in_to_S(data_in_to_S),
        .req_in_to_S(req_in_to_S),
        .ack_in_from_S(ack_in_from_S1),
        .data_out_from_S(data_out_from_S1),
        .ack_out_to_S(ack_out_to_S1),
        .req_out_from_S(req_out_from_S1),
        // signals related to East Port
        .data_in_to_E(data_in_to_E1),
        .req_in_to_E(req_in_to_E1),
        .ack_in_from_E(ack_in_from_E1),
        .data_out_from_E(data_out_from_E1),
        .ack_out_to_E(ack_out_to_E1),
        .req_out_from_E(req_out_from_E1),
        // signals related to West Port
        .data_in_to_W(data_in_to_W),
        .req_in_to_W(req_in_to_W),
        .ack_in_from_W(ack_out_to_E2),
        .data_out_from_W(data_in_to_E2),
        .ack_out_to_W(ack_in_from_E2),
        .req_out_from_W(req_in_to_E2)
    );

    NodeRouter #(DATA_WIDTH, SIZE, DEPTH, NR_ID2) NR2(
        .clk(clk), .rst(),
        .startMod(startMod2),
        // signals related to North Port
        .data_in_to_N(data_in_to_N),
        .req_in_to_N(req_in_to_N),
        .ack_in_from_N(ack_in_from_N2),
        .data_out_from_N(data_out_from_N2),
        .ack_out_to_N(ack_out_to_N2),
        .req_out_from_N(req_out_from_N2),
        // signals related to South Port
        .data_in_to_S(data_in_to_S),
        .req_in_to_S(req_in_to_S),
        .ack_in_from_S(ack_in_from_S2),
        .data_out_from_S(data_out_from_S2),
        .ack_out_to_S(ack_out_to_S2),
        .req_out_from_S(req_out_from_S2),
        // signals related to East Port
        .data_in_to_E(data_in_to_E2),
        .req_in_to_E(req_in_to_E2),
        .ack_in_from_E(ack_in_from_E2),
        .data_out_from_E(data_out_from_E2),
        .ack_out_to_E(ack_out_to_E2),
        .req_out_from_E(req_out_from_E2),
        // signals related to West Port
        .data_in_to_W(data_out_from_E1),
        .req_in_to_W(req_out_from_E1),
        .ack_in_from_W(ack_out_to_E1),
        .data_out_from_W(data_in_to_E1),
        .ack_out_to_W(ack_in_from_E1),
        .req_out_from_W(req_in_to_E1)
    );


    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        rst = 1;
        #20 
        rst = 0;
        startMod2 = 0;
        {data_in_to_N,  data_in_to_W, data_in_to_S} = 0;
        {req_in_to_N, req_in_to_W, req_in_to_S} = 0;
        {ack_out_to_N1, ack_out_to_W1, ack_out_to_S1} = 0;
        {ack_out_to_N2, ack_out_to_W2, ack_out_to_S2} = 0;
        @(posedge clk);
        @(posedge clk);
        startMod1 = 2'b11;
        @(posedge clk);
        startMod1 = 2'b00;
        @(posedge clk);
        #100;
        #100;
        $stop;
    end

endmodule