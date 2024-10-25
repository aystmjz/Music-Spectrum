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
// File name:              FFT_control_tb.v
// Last modified Date:     2024/10/14 23:25:52
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/14 23:25:52
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    FFT_control_tb();
    reg                                        rst_n                      ;
    reg                                        fft_clk                    ;
    reg                                        ram_clk                    ;
    reg                                        ram_en                     ;
    reg                       [   9: 0]        ram_addr                   ;
    wire                      [  15: 0]        ram_dout                   ;
    reg                                        fifo_clr                   ;
    reg                                        fifo_clk                   ;
    reg                                        fifo_wren                  ;
    reg                       [  23: 0]        fifo_din                   ;
    wire                                       fifo_full                  ;
    wire                      [  10: 0]        fifo_wr_cnt                ;
    wire                                       fifo_rst_busy           ;



    initial
        begin
            #2
                    rst_n = 0   ;
                    fft_clk = 0     ;
                    ram_clk = 0     ;
                    fifo_clk = 0     ;
            #10
                    rst_n = 1   ;
        end
                                                           
    always # ( 1000/200/2 ) fft_clk = ~fft_clk ;
    always # ( 1000/100/2 ) ram_clk = ~ram_clk ;
    always # ( 1000/50/2 ) fifo_clk = ~fifo_clk ;

    reg                [  23: 0] Time_data_I[1025:0]       ;
    reg                [   12: 0] cnt                 ;
    reg                [   9: 0] addr                 ;

initial begin
    $readmemb("/data_before_fft.txt",Time_data_I);
end
                                                           
FFT_control u_FFT_control(
    .rst_n                              (rst_n                     ),
    .fft_clk                            (fft_clk                   ),
    .ram_clk                            (ram_clk                   ),
    .ram_en                             (ram_en                    ),
    .ram_addr                           (ram_addr                  ),
    .ram_dout                           (ram_dout                  ),
    .fifo_clr                           (fifo_clr                  ),
    .fifo_clk                           (fifo_clk                  ),
    .fifo_wren                          (fifo_wren                 ),
    .fifo_din                           (fifo_din                  ),
    .fifo_full                          (fifo_full                 ),
    .fifo_wr_cnt                        (fifo_wr_cnt               ),
    .fifo_rst_busy                      (fifo_rst_busy          )
);

initial begin
    fifo_clr=0;
    fifo_wren=0;
    cnt=1;
    ram_en=0;
    addr=0;
    fifo_din=Time_data_I[0];
    ram_addr=0;
    #2000;
    fifo_clr=1;
    #20;
    fifo_clr=0;
    #20;
    wait(fifo_rst_busy==0);
    fifo_wren=1;
    fifo_din=cnt;
    repeat(1024*5)begin
        @(posedge fifo_clk);
            #1;
            cnt=cnt+1;
            //fifo_din=Time_data_I[cnt];
            fifo_din=cnt;
    end
    fifo_wren=0;

    #10000;
    ram_en=1;
    repeat (1024) begin
        @(posedge ram_clk);
            #1;
            ram_addr=addr;
            addr=addr+1;
    end
    #100000;
end


endmodule