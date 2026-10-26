module CordinateChecker #(
    parameter [3:0] X_CORDINATE, Y_CORDINATE,
    parameter [4:0] BIT_SIZE
) (
    input [3:0] dest,
    output reg [2:0] rout
);
    localparam [2:0] LOCAL = 3'b000, WEST = 3'b001, NORTH = 3'b010, EAST = 3'b011, SOUTH = 3'b100;
    reg [3:0] xd, yd;
    assign xd = dest % BIT_SIZE;
    assign yd = dest / BIT_SIZE;
    always @(*) begin
        if((xd == X_CORDINATE) && (yd == Y_CORDINATE))
            rout = LOCAL;
            else if(xd < X_CORDINATE)
                rout = WEST;
            else if(xd > X_CORDINATE)
                rout = EAST;
            else if(yd < Y_CORDINATE)
                rout = NORTH;
            else if(yd > Y_CORDINATE)
                rout = SOUTH;
    end
endmodule

module RoutingUnit #(
    parameter [3:0] ROUTER_ID = 15, 
    parameter [4:0] SIZE = 16
) (
    input [3:0] destLB, destWB, destNB, destEB, destSB,
    output [2:0] RoutLB, RoutWB, RoutNB, RoutEB, RoutSB
);
    localparam [3:0] BIT_SIZE = $clog2(SIZE);
    localparam [3:0] X_CORDINATE = ROUTER_ID % BIT_SIZE, Y_CORDINATE = ROUTER_ID / BIT_SIZE;

    CordinateChecker #(X_CORDINATE, Y_CORDINATE, BIT_SIZE) LBC (destLB, RoutLB);
    CordinateChecker #(X_CORDINATE, Y_CORDINATE, BIT_SIZE) WBC (destWB, RoutWB);
    CordinateChecker #(X_CORDINATE, Y_CORDINATE, BIT_SIZE) NBC (destNB, RoutNB);
    CordinateChecker #(X_CORDINATE, Y_CORDINATE, BIT_SIZE) EBC (destEB, RoutEB);
    CordinateChecker #(X_CORDINATE, Y_CORDINATE, BIT_SIZE) SBC (destSB, RoutSB);
endmodule