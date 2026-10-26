module fifo_datapath #(parameter DATA_WIDTH = 16, DEPTH = 4) (
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] data_in,
    input [1:0] flitID_in,
    input read_en,
    input write_en,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [1:0] flitID_out,
    output [3:0] dest,
    output reg empty,
    output reg full
);

    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [1:0] flitID_mem [0:DEPTH-1];
    reg [3:0] read_ptr, write_ptr;
    reg [4:0] fifo_count;
    reg destEN;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            fifo_count <= 0;
            full <= 0;
        end else begin
            if (write_en && ~full) begin
                fifo_mem[write_ptr] <= data_in;
                flitID_mem[write_ptr] <= flitID_in;
                write_ptr <= write_ptr + 1;
                if (write_ptr == DEPTH) begin
                    write_ptr <= 0;
                end
                fifo_count <= fifo_count + 1;
            end
            
            if (read_en && ~empty) begin
                data_out <= fifo_mem[read_ptr];
                flitID_out <= flitID_mem[read_ptr];
                read_ptr <= read_ptr + 1;
                if (read_ptr == DEPTH) begin
                    read_ptr <= 0;
                end
                fifo_count <= fifo_count - 1;
            end
        end
    end
    assign empty = (fifo_count == 0);
    assign full = (fifo_count == DEPTH);
    assign destEN = (flitID_mem[0] == 2'b01);
    flopenr #(4) DestReg(clk, reset, destEN, fifo_mem[0][3:0], dest);
endmodule

module fifo_control (
    input clk, reqI, ackO, ackA, full, empty, 
    input [1:0] flitID_in, flitID_out,
    output reg ackI, reqO, reqA, rst, write_en, read_en
);
    reg [3:0] ps, ns;
    parameter [3:0] WRI = 0, GAI = 1, WAIT1 = 2, WAIT2 = 3, RDI = 4, RP = 5, GRO = 6, WAO = 7, WAIT3 = 8, SDO = 9;
    always @(*) begin
        ns = WRI;
        case (ps)
            WRI : ns = reqI ? GAI : WRI;
            GAI : ns = reqI ? GAI : WAIT1;
            WAIT1 : ns = WAIT2;
            WAIT2 : ns = RDI;
            RDI : ns = (flitID_in == 2'b10) ? RP : RDI;
            RP : ns = ackA ? GRO : RP;
            GRO : ns = ackO ? WAO : GRO;
            WAO : ns = ackO ? WAO : WAIT3;
            WAIT3: ns = SDO;
            SDO : ns = (flitID_out == 2'b10) ? WRI : SDO; 
        endcase
    end

    always @(ps) begin
        {ackI, reqO, reqA, rst, write_en, read_en} = 6'b0;
        case (ps)
            WRI : begin
                rst = 1'b1;
            end
            GAI : begin
                ackI = 1'b1;
            end
            RDI : begin
                write_en = 1'b1;
            end
            RP : begin
                reqA = 1'b1;
            end
            GRO : begin
                reqO = 1'b1;
                reqA = 1'b1;
            end
            WAO : begin
                reqO = 1'b0;
                reqA = 1'b1;
            end
            WAIT3 : begin
                read_en = 1'b1;
                reqA = 1'b1;
            end
            SDO : begin
                read_en = 1'b1;
                reqA = 1'b1;
            end
        endcase
    end

    always @(posedge clk) begin
        ps <= ns;
    end

endmodule

module fifo #(
    parameter [4:0] DATA_WIDTH = 16,
    parameter [2:0] DEPTH = 4
    ) (
    input clk, reqI, ackO, ackA,
    input [DATA_WIDTH+1:0] data_in,
    output reg [DATA_WIDTH+1:0] data_out,
    output reqO, reqA, ackI,
    output [3:0] dest
    );
    wire rst, read_en, write_en, empty, full;
    wire [DATA_WIDTH-1:0] body;
    wire [1:0] ID;
    fifo_datapath #(16,4) DP(
    .clk(clk),
    .reset(rst),
    .data_in(data_in[DATA_WIDTH-1:0]),
    .flitID_in(data_in[DATA_WIDTH+1:DATA_WIDTH]),
    .read_en(read_en),
    .write_en(write_en),
    .data_out(body),
    .flitID_out(ID),
    .empty(empty),
    .full(full),
    .dest(dest)
    );

    fifo_control C(
    .clk(clk),
    .reqI(reqI),
    .ackO(ackO),
    .ackA(ackA),
    .full(full),
    .empty(empty), 
    .flitID_in(data_in[DATA_WIDTH+1:DATA_WIDTH]),
    .flitID_out(ID),
    .ackI(ackI),
    .reqO(reqO),
    .reqA(reqA),
    .rst(rst),
    .write_en(write_en),
    .read_en(read_en)
    );

    assign data_out = {ID, body};
endmodule