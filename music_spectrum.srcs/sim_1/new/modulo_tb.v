`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/10/14 21:56:48
// Design Name:
// Module Name: modulo_tb
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


module modulo_tb(

    );

  reg aclk;
  reg arsetn;
  reg [26:0]s_axis_data_im_tdata;
  reg s_axis_data_im_tvalid;
  reg [26:0]s_axis_data_re_tdata;
  reg s_axis_data_re_tvalid;
  wire [15:0]s_axis_data_result_tdata;
  wire s_axis_data_result_tvalid;

    initial
        begin
            #2
                    arsetn = 0   ;
                    aclk = 0     ;
            #10
                    arsetn = 1   ;
        end
                                                           
    parameter   CLK_FREQ = 100;//Mhz
    always # ( 1000/CLK_FREQ/2 ) aclk = ~aclk ;

modulo modulo_wrapper
       (.aclk(aclk),
        .arsetn(arsetn),
        .s_axis_data_im_tdata(s_axis_data_im_tdata),
        .s_axis_data_im_tvalid(s_axis_data_im_tvalid),
        .s_axis_data_re_tdata(s_axis_data_re_tdata),
        .s_axis_data_re_tvalid(s_axis_data_re_tvalid),
        .s_axis_data_result_tdata(s_axis_data_result_tdata),
        .s_axis_data_result_tvalid(s_axis_data_result_tvalid));
initial begin
    s_axis_data_im_tdata=27'b100000000000_111111111111111;
    s_axis_data_re_tdata=27'b100000000000_111111111111111;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #200;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b100000000000_111111111111111;
    s_axis_data_re_tdata=27'b000000000000_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b100000000000_111111111111111;
    s_axis_data_re_tdata=27'b111111111111_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b000000000000_111111111111111;
    s_axis_data_re_tdata=27'b000000001000_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b000000001000_111111111111111;
    s_axis_data_re_tdata=27'b000000000000_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b000000000001_111111111111111;
    s_axis_data_re_tdata=27'b000000000001_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10;
    s_axis_data_im_tdata=27'b111111111111_111111111111111;
    s_axis_data_re_tdata=27'b111111111111_111111111111111;
    s_axis_data_re_tvalid=1;
    s_axis_data_im_tvalid=1;
    #10;
    s_axis_data_re_tvalid=0;
    s_axis_data_im_tvalid=0;
    #10000;

end

endmodule
