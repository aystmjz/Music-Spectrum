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
// File name:              disp_buffer_updater_tb.v
// Last modified Date:     2024/10/18 15:31:56
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/18 15:31:56
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    disp_buffer_updater_tb();
    reg                          clk                      ;
    reg                          rst_n                    ;
    reg                [  15: 0] background_data          ;
    wire                         background_req           ;
    wire                         ram_fft_en               ;
    wire               [   9: 0] ram_fft_addr             ;
    reg                [  31: 0] ram_fft_dout             ;
    wire                         ram_audio_en             ;
    wire               [   9: 0] ram_audio_addr           ;
    reg                [  23: 0] ram_audio_dout           ;
    wire               [  15: 0] buffer_data              ;
    wire                         buffer_data_valid        ;
    wire                         buffer_clr               ;
    reg                          update_start             ;
    wire                         update_done              ;



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
                                                           
                                                           
disp_buffer_updater #(
    .HOLD_TIME (150_00)
)u_disp_buffer_updater(
    .clk                         (clk                     ),
    .rst_n                       (rst_n                   ),
    .background_data             (background_data         ),
    .background_req              (background_req          ),
    .ram_fft_en                  (ram_fft_en              ),
    .ram_fft_addr                (ram_fft_addr            ),
    .ram_fft_dout                (ram_fft_dout            ),
    .ram_audio_en                (ram_audio_en            ),
    .ram_audio_addr              (ram_audio_addr          ),
    .ram_audio_dout              (ram_audio_dout          ),
    .buffer_data                 (buffer_data             ),
    .buffer_data_valid           (buffer_data_valid       ),
    .buffer_clr                  (buffer_clr              ),
    .update_start                (update_start            ),
    .update_done                 (update_done             ) 
);

initial begin
    background_data=16'h0;
    update_start=0;
    #201;
    update_start=1;
    #20;
    update_start=0;
    while (1) begin
        wait(update_done==1);
        #100;
        update_start=1;
        #20;
        update_start=0;
    end
end

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            ram_fft_dout=0;
        else
            ram_fft_dout=ram_fft_dout;
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            ram_audio_dout=0;
        else
            ram_audio_dout=ram_audio_dout+1;
    end

endmodule