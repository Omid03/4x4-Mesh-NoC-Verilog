module Node #(parameter DATA_WIDTH = 16) (
    input clk,
    input [1:0] startMod,
    input reqLB_O, ackLB_I,
    input [DATA_WIDTH+1 : 0] dataLB_O,
    input [3:0] Node_ID,
    output reg ackLB_O, reqLB_I,
    output reg [DATA_WIDTH+1 : 0] dataLB_I
    );

    initial begin
        {ackLB_O, reqLB_I, dataLB_I} = {(DATA_WIDTH + 4){1'b0}};
    end

    always @(posedge clk) begin
        case (startMod)
            1: begin
                while (~ackLB_I) begin
                    reqLB_I = 1'b1;
                    @(posedge clk);
                end
                reqLB_I = 1'b0;
                @(posedge clk);
                @(posedge clk);
                @(posedge clk);
                write_data_LB({2'b01, 8'b0010_0010, Node_ID, 4'b0001});
                write_data_LB(18'b00_1010_0010_0011_0110);
                write_data_LB(18'b00_0011_0110_0101_1010);
                write_data_LB(18'b10_1111_0010_1010_1111);
            end
            2: begin
                while (~ackLB_I) begin
                    reqLB_I = 1'b1;
                    @(posedge clk);
                end
                reqLB_I = 1'b0;
                @(posedge clk);
                @(posedge clk);
                @(posedge clk);
                write_data_LB({2'b01, 8'b1000_0010, Node_ID, 4'b0100});
                write_data_LB(18'b00_1010_1111_0111_0100);
                write_data_LB(18'b00_0111_0000_0101_1110);
                write_data_LB(18'b10_1001_0010_1000_1011);
            end
            3: begin
                while (~ackLB_I) begin
                    reqLB_I = 1'b1;
                    @(posedge clk);
                end
                reqLB_I = 1'b0;
                @(posedge clk);
                @(posedge clk);
                @(posedge clk);
                write_data_LB({2'b01, 8'b0000_0010, Node_ID, 4'b0101});
                write_data_LB(18'b00_1011_0011_1111_0111);
                write_data_LB(18'b00_1011_0111_1101_1010);
                write_data_LB(18'b10_1111_0011_1110_1111);
            end
        endcase
    end

    always @(posedge clk, posedge reqLB_O) begin
        if(reqLB_O) begin
            @(posedge clk);
            @(posedge clk);
            while (reqLB_O) begin
                    ackLB_O = 1'b1;
                    @(posedge clk);
            end
            ackLB_O = 1'b0;
            @(posedge clk);
        end
    end

    task write_data_LB(input [DATA_WIDTH+1:0] data);
        begin
            dataLB_I = data;
            @(posedge clk);
        end
    endtask
endmodule