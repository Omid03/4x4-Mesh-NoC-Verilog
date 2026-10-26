module BusyChecker(
    input reqL, reqW, reqN, reqE, reqS,
    input grantL, grantW, grantN, grantE, grantS,
    output reg busy
);
    assign busy = ((reqL & grantL) | (reqW & grantW) | (reqN & grantN) | (reqE & grantE) | (reqS & grantS));
endmodule

module SwitchAllocator #(
    parameter [2:0] PORT_ID = 0
    ) (
        input clk, rst,
        input reqL, reqW, reqN, reqE, reqS,
        input [2:0] RoutLB, RoutWB, RoutNB, RoutEB, RoutSB,
        output reg grantL,  grantW, grantN, grantE, grantS
    );
    wire reqL_in, reqW_in, reqN_in, reqE_in, reqS_in;
    wire RoutL_eq, RoutW_eq, RoutN_eq, RoutE_eq, RoutS_eq;

    BusyChecker BC(
        .reqL(reqL), .reqW(reqW), .reqN(reqN), .reqE(reqE), .reqS(reqS),
        .grantL(grantL), .grantW(grantW), .grantN(grantN), .grantE(grantE), .grantS(grantS),
        .busy(busy)
    );

    flopenr #(1) LocalReqReg(clk, rst, ~busy, reqL, reqL_in);
    flopenr #(1) WestReqReg(clk, rst, ~busy, reqW, reqW_in);
    flopenr #(1) NorthReqReg(clk, rst, ~busy, reqN, reqN_in);
    flopenr #(1) EastReqReg(clk, rst, ~busy, reqE, reqE_in);
    flopenr #(1) SouthReqReg(clk, rst, ~busy, reqS, reqS_in);

    assign RoutL_eq = (RoutLB == PORT_ID);
    assign RoutW_eq = (RoutWB == PORT_ID);
    assign RoutN_eq = (RoutNB == PORT_ID);
    assign RoutE_eq = (RoutEB == PORT_ID);
    assign RoutS_eq = (RoutSB == PORT_ID);

    assign grantL = reqL_in & RoutL_eq;
    assign grantW = reqW_in & RoutW_eq & ~grantL;
    assign grantN = reqN_in & RoutN_eq & ~grantL & ~grantW;
    assign grantE = reqE_in & RoutE_eq & ~grantL & ~grantW & ~grantN;
    assign grantS = reqS_in & RoutS_eq & ~grantL & ~grantW & ~grantN & ~grantE;
endmodule

module Switch #(
    parameter [4:0] DATA_WIDTH = 16,
    parameter [2:0] PORT_ID = 0
    )(
    input clk, rst,
    input reqA_L, reqA_W, reqA_N, reqA_E, reqA_S,
    input [2:0] RoutLB, RoutWB, RoutNB, RoutEB, RoutSB,
    input reqO_L, reqO_W, reqO_N, reqO_E, reqO_S,
    input [DATA_WIDTH+1 : 0] dataLB, dataWB, dataNB, dataEB, dataSB,
    input ackOut,
    output ackA_L, ackA_W, ackA_N, ackA_E, ackA_S, 
    output ackO_L, ackO_W, ackO_N, ackO_E, ackO_S,
    output reqOut,
    output [DATA_WIDTH+1 : 0] dataOut
    );
    SwitchAllocator #(PORT_ID) switch(.clk(clk), .rst(rst), 
                            .reqL(reqA_L), .reqW(reqA_W), .reqN(reqA_N), .reqE(reqA_E), .reqS(reqA_S), 
                            .RoutLB(RoutLB), .RoutWB(RoutWB), .RoutNB(RoutNB), .RoutEB(RoutEB), .RoutSB(RoutSB),
                            .grantL(ackA_L),  .grantW(ackA_W), .grantN(ackA_N), .grantE(ackA_E), .grantS(ackA_S));

    wire [4:0] sel = {ackA_L, ackA_W, ackA_N, ackA_E, ackA_S};

    mux_4to1_onehot #(DATA_WIDTH+3) switchMux(sel, {reqO_S, dataSB}, {reqO_E, dataEB}, {reqO_N, dataNB}, {reqO_W, dataWB}, {reqO_L, dataLB}, {reqOut, dataOut});

    demux_1to4_onehot #(1) switchDeMux(sel, ackOut, ackO_S, ackO_E, ackO_N, ackO_W, ackO_L);
        
endmodule