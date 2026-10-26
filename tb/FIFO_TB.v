module fifo_tb;
    parameter DATA_WIDTH = 16;
    parameter DEPTH = 4;

    reg clk;
    reg reqI;
    reg ackO;
    reg ackA;
    reg [DATA_WIDTH+1:0] data_in;
    wire [DATA_WIDTH+1:0] data_out;
    wire reqO;
    wire reqA;
    wire ackI;
    wire [3:0] dest;

    fifo #(DATA_WIDTH, DEPTH) DUT (
        .clk(clk),
        .reqI(reqI),
        .ackO(ackO),
        .ackA(ackA),
        .data_in(data_in),
        .data_out(data_out),
        .reqO(reqO),
        .reqA(reqA),
        .ackI(ackI),
        .dest(dest)
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        reqI = 0;
        ackO = 0;
        ackA = 0;
        data_in = 0;

        #10;
        @(posedge clk);
        reqI = 1'b1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        reqI = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        write_data(18'b01_0000_0100_0011_0001);
        write_data(18'b00_1010_0010_0011_0110);
        write_data(18'b00_0011_0110_0101_1010);
        write_data(18'b10_1111_0010_1010_1111);

        #100;
        read_data();

        #1000;
        $stop;
    end

    task write_data(input [DATA_WIDTH+1:0] data);
        begin
            data_in = data;
            @(posedge clk);
        end
    endtask

    task read_data;
        begin
            @(posedge clk);
            ackO = 1'b0;
            ackA = 1'b1;
            @(posedge clk);
            ackA = 1'b0;
            @(posedge clk);
            ackO = 1'b1;
            @(posedge clk);
            @(posedge clk);
            ackO = 1'b0;
            @(posedge clk);
        end
    endtask

endmodule
