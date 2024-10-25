`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/04/14 09:59:20
// Design Name:
// Module Name: bit8_trans_bit16_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module bit8_trans_bit16_tb();
    reg clk;
    reg reset_n;
    
    reg [7:0]data;
    reg data_valid;
    wire [15:0]out_data;
    wire out_data_valid;
    
    bit8_trans_bit16 bit8_trans_bit16(
        .clk(clk),
        .reset_p(!reset_n),
        
        .bit8_in(data),
        .bit8_in_valid(data_valid),
        
        .bit16_out(out_data),
        .bit16_out_valid(out_data_valid)
    );
    
    initial clk = 1;
	always #10 clk = !clk;
    
    initial begin
        reset_n = 0;
        data = 0;
        #201;
        reset_n = 1;
        #201
        data = 8'b0000_0001;
        data_valid = 1'b1;
        #20;
        data = 8'b0000_0010;
        #20;
        data = 8'b0000_0100;
        #20;
        data = 8'b0000_1000;
        #20;
        data = 8'b0001_0000;
        #20;
        data = 8'b0010_0000;
        #20;
        data = 8'b0100_0000;
        #20;
        data = 8'b1000_0000;
        #20;
        data_valid = 1'b0;
        #2000;
        $stop;
    end
    
endmodule
