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
// File name:              image_blender_tb.v
// Last modified Date:     2024/10/18 10:03:27
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/18 10:03:27
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    image_blender_tb();
    reg                                        clk                        ;
    reg                                        rst_n                      ;
    reg                       [  15: 0]        s_rgb565_data_a            ;
    reg                       [  15: 0]        s_rgb565_data_b            ;
    reg                                        s_data_valid               ;
    reg                                        s_blend_en                 ;
    wire                      [  15: 0]        m_rgb565_data              ;
    wire                                       m_data_valid               ;



    initial
        begin
            #2
                    rst_n = 0   ;
                    clk = 0     ;
            #10
                    rst_n = 1   ;
        end
                                                           
    parameter   CLK_FREQ = 50;//Mhz
    always # ( 1000/CLK_FREQ/2 ) clk = ~clk ;
                                                           
                                                           
image_blender u_image_blender(
    .clk                                (clk                       ),
    .rst_n                              (rst_n                     ),
    .s_rgb565_data_a                    (s_rgb565_data_a           ),
    .s_rgb565_data_b                    (s_rgb565_data_b           ),
    .s_data_valid                       (s_data_valid              ),
    .s_blend_en                         (s_blend_en                ),
    .m_rgb565_data                      (m_rgb565_data             ),
    .m_data_valid                       (m_data_valid              )
);

initial begin
    s_rgb565_data_a=16'he349;
    s_rgb565_data_b=16'h3d1e;
    s_data_valid=0;
    s_blend_en=1;
    #201;
    s_data_valid=1;
    #20;
    s_rgb565_data_a=16'hffff;
    s_rgb565_data_b=16'h3d1e;
    #20;
    s_rgb565_data_a=16'he3f9;
    s_rgb565_data_b=16'h3d1e;
    #20;
    s_data_valid=0;
    #10000;
end


endmodule