`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE plug-in
// VSCODE plug-in version: Verilog-Hdl-Format-2.8.20240817
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            新芯科技
// All rights reserved
// File name:              fir_tb_tb.v
// Last modified Date:     2024/10/22 23:54:42
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/22 23:54:42
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    fir_tb();
    reg                          rst_n                    ;
    reg                          clk                      ;
    reg                          s_axis_data_tvalid       ;
    reg                [  23: 0] s_axis_data_tdata        ;
    wire               [  47: 0] m_axis_data_tdata        ;
    wire                         m_axis_data_tvalid       ;


    initial
        begin
            #2
                    rst_n = 0   ;
                    clk = 0     ;
            #10
                    rst_n = 1   ;
        end
                                                           
    parameter   CLK_FREQ = 100;//Mhz
    always # ( 1000/CLK_FREQ/2 ) clk = ~clk ;
                                                           

fir your_instance_name (
  .aclk(clk),                              // input wire aclk
  .s_axis_data_tvalid(s_axis_data_tvalid),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(),  // output wire s_axis_data_tready
  .s_axis_data_tdata(s_axis_data_tdata),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(m_axis_data_tdata)    // output wire [47 : 0] m_axis_data_tdata
);


integer i=0;
reg [23:0] signal[1023:0];

initial begin
    $readmemb("/fir_data.txt", signal);
    s_axis_data_tvalid=0;
    s_axis_data_tdata=0;
    #201;
    forever
    begin
        @(negedge clk)
        begin
            if(i<1024)
                begin
                    s_axis_data_tvalid=1;
                    s_axis_data_tdata = signal[i];
                    i =i + 1;
                end
            else
                begin
                    s_axis_data_tvalid=0;
                    s_axis_data_tdata = 0;
                end
        end
    end
end

endmodule
