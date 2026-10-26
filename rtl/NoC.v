module NoC #(
    parameter [4:0] DATA_WIDTH = 16, SIZE = 16, 
    parameter [2:0] DEPTH = 4
)(
    input clk, rst,
    input [2*SIZE-1:0] startMod_flat
);
    localparam DIMENSION = $sqrt(SIZE);

    wire [1:0] startMod [0: SIZE -1];
    wire [DATA_WIDTH+1 : 0] data_to_up [0 : DIMENSION][0 : DIMENSION];
    wire req_to_up [0 : DIMENSION][0 : DIMENSION];
    wire ack_to_up [0 : DIMENSION][0 : DIMENSION];

    wire [DATA_WIDTH+1 : 0] data_to_down [0 : DIMENSION][0 : DIMENSION];
    wire req_to_down [0 : DIMENSION][0 : DIMENSION];
    wire ack_to_down [0 : DIMENSION][0 : DIMENSION];

    wire [DATA_WIDTH+1 : 0] data_to_left [0 : DIMENSION][0 : DIMENSION];
    wire req_to_left [0 : DIMENSION][0 : DIMENSION];
    wire ack_to_left [0 : DIMENSION][0 : DIMENSION];

    wire [DATA_WIDTH+1 : 0] data_to_right [0 : DIMENSION][0 : DIMENSION];
    wire req_to_right [0 : DIMENSION][0 : DIMENSION];
    wire ack_to_right [0 : DIMENSION][0 : DIMENSION];

    genvar k;
    generate
        for (k = 0; k < SIZE; k = k + 1) begin : unpack_startMod
            assign startMod[k] = startMod_flat[2*k+1:2*k];
        end
    endgenerate

    genvar i , j;
    generate
        for(i = 0; i < DIMENSION; i = i + 1) begin : GENERATING_NODE_ROUTERS_IN_ROWS
            for(j = 0; j < DIMENSION; j = j + 1) begin : GENERATING_NODE_ROUTERS_IN_COLUMNS
                NodeRouter #(DATA_WIDTH, SIZE, DEPTH, (DIMENSION*i +j)) node_routers(
                    .clk(clk), .rst(rst),
                    .startMod(startMod[(DIMENSION*i +j)]),
                    // signals related to North Port
                    .data_in_to_N(data_to_down[i][j]),
                    .req_in_to_N(req_to_down[i][j]),
                    .ack_in_from_N(ack_to_up[i][j]),
                    .data_out_from_N(data_to_up[i][j]),
                    .ack_out_to_N(ack_to_down[i][j]),
                    .req_out_from_N(req_to_up[i][j]),
                    // signals related to South Port
                    .data_in_to_S(data_to_up[i+1][j]),
                    .req_in_to_S(req_to_up[i+1][j]),
                    .ack_in_from_S(ack_to_down[i+1][j]),
                    .data_out_from_S(data_to_down[i+1][j]),
                    .ack_out_to_S(ack_to_up[i+1][j]),
                    .req_out_from_S(req_to_down[i+1][j]),
                    // signals related to East Port
                    .data_in_to_E(data_to_left[i][j+1]),
                    .req_in_to_E(req_to_left[i][j+1]),
                    .ack_in_from_E(ack_to_right[i][j+1]),
                    .data_out_from_E(data_to_right[i][j+1]),
                    .ack_out_to_E(ack_to_left[i][j+1]),
                    .req_out_from_E(req_to_right[i][j+1]),
                    // signals related to West Port
                    .data_in_to_W(data_to_right[i][j]),
                    .req_in_to_W(req_to_right[i][j]),
                    .ack_in_from_W(ack_to_left[i][j]),
                    .data_out_from_W(data_to_left[i][j]),
                    .ack_out_to_W(ack_to_right[i][j]),
                    .req_out_from_W(req_to_left[i][j])
                );
            end
        end
    endgenerate
endmodule