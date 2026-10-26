module NodeRouter #(
    parameter [4:0] DATA_WIDTH = 16, SIZE = 16, 
    parameter [2:0] DEPTH = 4,
    parameter [3:0] ROUTER_ID = 15
) (
    input clk, rst,
    input [1:0] startMod,
    // signals related to North Port
    input [DATA_WIDTH+1 : 0] data_in_to_N,
    input req_in_to_N,
    output ack_in_from_N,
    output [DATA_WIDTH+1 : 0] data_out_from_N,
    input ack_out_to_N,
    output req_out_from_N,

    // signals related to South Port
    input [DATA_WIDTH+1 : 0] data_in_to_S,
    input req_in_to_S,
    output ack_in_from_S,
    output [DATA_WIDTH+1 : 0] data_out_from_S,
    input ack_out_to_S,
    output req_out_from_S,

    // signals related to East Port
    input [DATA_WIDTH+1 : 0] data_in_to_E,
    input req_in_to_E,
    output ack_in_from_E,
    output [DATA_WIDTH+1 : 0] data_out_from_E,
    input ack_out_to_E,
    output req_out_from_E,

    // signals related to West Port
    input [DATA_WIDTH+1 : 0] data_in_to_W,
    input req_in_to_W,
    output ack_in_from_W,
    output [DATA_WIDTH+1 : 0] data_out_from_W,
    input ack_out_to_W,
    output req_out_from_W
);
    wire [DATA_WIDTH+1 : 0] data_in_to_L;
    wire req_in_to_L;
    wire ack_in_from_L;
    wire [DATA_WIDTH+1 : 0] data_out_from_L;
    wire ack_out_to_L;
    wire req_out_from_L;

    Router #(DATA_WIDTH, SIZE, DEPTH, ROUTER_ID) router(        
        .clk(clk),
        .rst(rst),
        .data_in_L(data_in_to_L),
        .data_in_W(data_in_to_W),
        .data_in_N(data_in_to_N),
        .data_in_E(data_in_to_E),
        .data_in_S(data_in_to_S),
        .reqI_L(req_in_to_L),
        .reqI_W(req_in_to_W),
        .reqI_N(req_in_to_N),
        .reqI_E(req_in_to_E),
        .reqI_S(req_in_to_S),
        .ackOut_LS(ack_out_to_L),
        .ackOut_WS(ack_out_to_W),
        .ackOut_NS(ack_out_to_N),
        .ackOut_ES(ack_out_to_E),
        .ackOut_SS(ack_out_to_S),
        .ackI_LB(ack_in_from_L),
        .ackI_WB(ack_in_from_W),
        .ackI_NB(ack_in_from_N),
        .ackI_EB(ack_in_from_E),
        .ackI_SB(ack_in_from_S),
        .reqOut_LS(req_out_from_L),
        .reqOut_WS(req_out_from_W),
        .reqOut_NS(req_out_from_N),
        .reqOut_ES(req_out_from_E),
        .reqOut_SS(req_out_from_S),
        .data_out_LS(data_out_from_L),
        .data_out_WS(data_out_from_W),
        .data_out_NS(data_out_from_N),
        .data_out_ES(data_out_from_E),
        .data_out_SS(data_out_from_S)
        );

        Node #(DATA_WIDTH) node (
                        .clk(clk),
                        .startMod(startMod),
                        .reqLB_O(req_out_from_L), .ackLB_I(ack_in_from_L),
                        .dataLB_O(data_out_from_L),
                        .Node_ID(ROUTER_ID),
                        .ackLB_O(ack_out_to_L), .reqLB_I(req_in_to_L),
                        .dataLB_I(data_in_to_L)
                        );


endmodule