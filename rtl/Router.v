module Router #(
    parameter [4:0] DATA_WIDTH = 16, SIZE = 16,
    parameter [2:0] DEPTH = 4,
    parameter [3:0] ROUTER_ID = 15
) (
    input clk, rst,
    input [DATA_WIDTH+1:0] data_in_L, data_in_W, data_in_N, data_in_E, data_in_S,
    input reqI_L, reqI_W, reqI_N, reqI_E, reqI_S,
    input ackOut_LS, ackOut_WS, ackOut_NS, ackOut_ES, ackOut_SS,
    output ackI_LB, ackI_WB, ackI_NB, ackI_EB, ackI_SB,
    output reqOut_LS, reqOut_WS, reqOut_NS, reqOut_ES, reqOut_SS,
    output [DATA_WIDTH+1:0] data_out_LS, data_out_WS, data_out_NS, data_out_ES, data_out_SS
);

    localparam [2:0] LOCAL = 3'b000, WEST = 3'b001, NORTH = 3'b010, EAST = 3'b011, SOUTH = 3'b100;

    wire [DATA_WIDTH+1:0] data_out_LB, data_out_WB, data_out_NB, data_out_EB, data_out_SB;
    wire reqO_L, reqO_W, reqO_N, reqO_E, reqO_S;
    wire reqA_L, reqA_W, reqA_N, reqA_E, reqA_S;
    wire ackO_L, ackO_W, ackO_N, ackO_E, ackO_S;
    wire ackA_L, ackA_W, ackA_N, ackA_E, ackA_S;
    wire [3:0] destL, destW, destN, destE, destS;
    wire [2:0] Rout_L, Rout_W, Rout_N, Rout_E, Rout_S;

    wire ackA_LL, ackA_WL, ackA_NL, ackA_EL, ackA_SL;
    wire ackA_LW, ackA_WW, ackA_NW, ackA_EW, ackA_SW;
    wire ackA_LN, ackA_WN, ackA_NN, ackA_EN, ackA_SN;
    wire ackA_LE, ackA_WE, ackA_NE, ackA_EE, ackA_SE;
    wire ackA_LS, ackA_WS, ackA_NS, ackA_ES, ackA_SS;

    wire ackO_LL, ackO_WL, ackO_NL, ackO_EL, ackO_SL;
    wire ackO_LW, ackO_WW, ackO_NW, ackO_EW, ackO_SW;
    wire ackO_LN, ackO_WN, ackO_NN, ackO_EN, ackO_SN;
    wire ackO_LE, ackO_WE, ackO_NE, ackO_EE, ackO_SE;
    wire ackO_LS, ackO_WS, ackO_NS, ackO_ES, ackO_SS;

    fifo #(DATA_WIDTH, DEPTH) LocalBuffer(.clk(clk), .data_in(data_in_L), .data_out(data_out_LB),
                                         .reqI(reqI_L), .reqO(reqO_L), .reqA(reqA_L), .ackI(ackI_LB), .ackO(ackO_L), .ackA(ackA_L), .dest(destL));

    fifo #(DATA_WIDTH, DEPTH) WestBuffer(.clk(clk), .data_in(data_in_W), .data_out(data_out_WB), 
                                         .reqI(reqI_W), .reqO(reqO_W), .reqA(reqA_W), .ackI(ackI_WB), .ackO(ackO_W), .ackA(ackA_W), .dest(destW));

    fifo #(DATA_WIDTH, DEPTH) NorthBuffer(.clk(clk), .data_in(data_in_N), .data_out(data_out_NB),
                                         .reqI(reqI_N), .reqO(reqO_N), .reqA(reqA_N), .ackI(ackI_NB), .ackO(ackO_N), .ackA(ackA_N), .dest(destN));

    fifo #(DATA_WIDTH, DEPTH) EastBuffer(.clk(clk), .data_in(data_in_E), .data_out(data_out_EB), 
                                         .reqI(reqI_E), .reqO(reqO_E), .reqA(reqA_E), .ackI(ackI_EB), .ackO(ackO_E), .ackA(ackA_E), .dest(destE));

    fifo #(DATA_WIDTH, DEPTH) SouthBuffer(.clk(clk), .data_in(data_in_S), .data_out(data_out_SB),
                                         .reqI(reqI_S), .reqO(reqO_S), .reqA(reqA_S), .ackI(ackI_SB), .ackO(ackO_S), .ackA(ackA_S), .dest(destS));

    RoutingUnit #(ROUTER_ID, SIZE) RU(.destLB(destL), .destWB(destW), .destNB(destN), .destEB(destE), .destSB(destS),
                                     .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S));
    
    Switch #(DATA_WIDTH, LOCAL) LocalSwtich(.clk(clk), .rst(rst),
                                            .reqA_L(reqA_L), .reqA_W(reqA_W), .reqA_N(reqA_N), .reqA_E(reqA_E), .reqA_S(reqA_S),
                                            .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S),
                                            .reqO_L(reqO_L), .reqO_W(reqO_W), .reqO_N(reqO_N), .reqO_E(reqO_E), .reqO_S(reqO_S),
                                            .dataLB(data_out_LB), .dataWB(data_out_WB), .dataNB(data_out_NB), .dataEB(data_out_EB), .dataSB(data_out_SB),
                                            .ackOut(ackOut_LS),
                                            .ackA_L(ackA_LL), .ackA_W(ackA_WL), .ackA_N(ackA_NL), .ackA_E(ackA_EL), .ackA_S(ackA_SL), 
                                            .ackO_L(ackO_LL), .ackO_W(ackO_WL), .ackO_N(ackO_NL), .ackO_E(ackO_EL), .ackO_S(ackO_SL),
                                            .reqOut(reqOut_LS),
                                            .dataOut(data_out_LS));

    Switch #(DATA_WIDTH, WEST) WestSwtich(.clk(clk), .rst(rst),
                                          .reqA_L(reqA_L), .reqA_W(reqA_W), .reqA_N(reqA_N), .reqA_E(reqA_E), .reqA_S(reqA_S),
                                          .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S),
                                          .reqO_L(reqO_L), .reqO_W(reqO_W), .reqO_N(reqO_N), .reqO_E(reqO_E), .reqO_S(reqO_S),
                                          .dataLB(data_out_LB), .dataWB(data_out_WB), .dataNB(data_out_NB), .dataEB(data_out_EB), .dataSB(data_out_SB),
                                          .ackOut(ackOut_WS),
                                          .ackA_L(ackA_LW), .ackA_W(ackA_WW), .ackA_N(ackA_NW), .ackA_E(ackA_EW), .ackA_S(ackA_SW), 
                                          .ackO_L(ackO_LW), .ackO_W(ackO_WW), .ackO_N(ackO_NW), .ackO_E(ackO_EW), .ackO_S(ackO_SW),
                                          .reqOut(reqOut_WS),
                                          .dataOut(data_out_WS));

    Switch #(DATA_WIDTH, NORTH) NorthSwtich(.clk(clk), .rst(rst),
                                            .reqA_L(reqA_L), .reqA_W(reqA_W), .reqA_N(reqA_N), .reqA_E(reqA_E), .reqA_S(reqA_S),
                                            .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S),
                                            .reqO_L(reqO_L), .reqO_W(reqO_W), .reqO_N(reqO_N), .reqO_E(reqO_E), .reqO_S(reqO_S),
                                            .dataLB(data_out_LB), .dataWB(data_out_WB), .dataNB(data_out_NB), .dataEB(data_out_EB), .dataSB(data_out_SB),
                                            .ackOut(ackOut_NS),
                                            .ackA_L(ackA_LN), .ackA_W(ackA_WN), .ackA_N(ackA_NN), .ackA_E(ackA_EN), .ackA_S(ackA_SN), 
                                            .ackO_L(ackO_LN), .ackO_W(ackO_WN), .ackO_N(ackO_NN), .ackO_E(ackO_EN), .ackO_S(ackO_SN),
                                            .reqOut(reqOut_NS),
                                            .dataOut(data_out_NS));

    Switch #(DATA_WIDTH, EAST) EastSwtich(.clk(clk), .rst(rst),
                                          .reqA_L(reqA_L), .reqA_W(reqA_W), .reqA_N(reqA_N), .reqA_E(reqA_E), .reqA_S(reqA_S),
                                          .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S),
                                          .reqO_L(reqO_L), .reqO_W(reqO_W), .reqO_N(reqO_N), .reqO_E(reqO_E), .reqO_S(reqO_S),
                                          .dataLB(data_out_LB), .dataWB(data_out_WB), .dataNB(data_out_NB), .dataEB(data_out_EB), .dataSB(data_out_SB),
                                          .ackOut(ackOut_ES),
                                          .ackA_L(ackA_LE), .ackA_W(ackA_WE), .ackA_N(ackA_NE), .ackA_E(ackA_EE), .ackA_S(ackA_SE), 
                                          .ackO_L(ackO_LE), .ackO_W(ackO_WE), .ackO_N(ackO_NE), .ackO_E(ackO_EE), .ackO_S(ackO_SE),
                                          .reqOut(reqOut_ES),
                                          .dataOut(data_out_ES));

    Switch #(DATA_WIDTH, SOUTH) SouthSwtich(.clk(clk), .rst(rst),
                                            .reqA_L(reqA_L), .reqA_W(reqA_W), .reqA_N(reqA_N), .reqA_E(reqA_E), .reqA_S(reqA_S),
                                            .RoutLB(Rout_L), .RoutWB(Rout_W), .RoutNB(Rout_N), .RoutEB(Rout_E), .RoutSB(Rout_S),
                                            .reqO_L(reqO_L), .reqO_W(reqO_W), .reqO_N(reqO_N), .reqO_E(reqO_E), .reqO_S(reqO_S),
                                            .dataLB(data_out_LB), .dataWB(data_out_WB), .dataNB(data_out_NB), .dataEB(data_out_EB), .dataSB(data_out_SB),
                                            .ackOut(ackOut_SS),
                                            .ackA_L(ackA_LS), .ackA_W(ackA_WS), .ackA_N(ackA_NS), .ackA_E(ackA_ES), .ackA_S(ackA_SS), 
                                            .ackO_L(ackO_LS), .ackO_W(ackO_WS), .ackO_N(ackO_NS), .ackO_E(ackO_ES), .ackO_S(ackO_SS),
                                            .reqOut(reqOut_SS),
                                            .dataOut(data_out_SS));
    
    assign ackA_L = (ackA_LL | ackA_LW | ackA_LN | ackA_LE | ackA_LS);
    assign ackA_W = (ackA_WL | ackA_WW | ackA_WN | ackA_WE | ackA_WS);
    assign ackA_N = (ackA_NL | ackA_NW | ackA_NN | ackA_NE | ackA_NS);
    assign ackA_E = (ackA_EL | ackA_EW | ackA_EN | ackA_EE | ackA_ES);
    assign ackA_S = (ackA_SL | ackA_SW | ackA_SN | ackA_SE | ackA_SS);

    assign ackO_L = (ackO_LL | ackO_LW | ackO_LN | ackO_LE | ackO_LS);
    assign ackO_W = (ackO_WL | ackO_WW | ackO_WN | ackO_WE | ackO_WS);
    assign ackO_N = (ackO_NL | ackO_NW | ackO_NN | ackO_NE | ackO_NS);
    assign ackO_E = (ackO_EL | ackO_EW | ackO_EN | ackO_EE | ackO_ES);
    assign ackO_S = (ackO_SL | ackO_SW | ackO_SN | ackO_SE | ackO_SS);
endmodule