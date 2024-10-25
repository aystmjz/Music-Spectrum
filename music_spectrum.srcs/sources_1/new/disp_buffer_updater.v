`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            新芯科技
// All rights reserved
// File name:              disp_buffer_updater.v
// Last modified Date:     2024/10/23
// Last Version:           V2.1
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/17
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//


module disp_buffer_updater(
    input                        clk                      ,
    input                        rst_n                    ,
    input              [  15: 0] background_data          ,
    output reg                   background_req           ,
    
    output reg                   ram_fft_en               ,
    output             [   9: 0] ram_fft_addr             ,
    input              [  31: 0] ram_fft_dout             ,
    
    output                       ram_audio_en             ,
    output             [   9: 0] ram_audio_addr           ,
    input              [  23: 0] ram_audio_dout           ,
    
    output                       ram_fir_en               ,
    output             [   9: 0] ram_fir_addr             ,
    input              [  47: 0] ram_fir_dout             ,
    
    output             [  15: 0] buffer_data              ,
    output                       buffer_data_valid        ,
    output                       buffer_clr               ,
    
    input                        update_start             ,
    output reg                   update_done
);
    
    reg                [   4: 0] update_state             ;
    reg                [   6: 0] per_cnt                  ;
    reg                [   3: 0] lsm_cnt                  ;
    reg                [   6: 0] x_cnt                    ;
    reg                [   8: 0] y_cnt                    ;
    reg                [   3: 0] color_spead_cnt          ;
    reg                [   9: 0] audio_cnt                ;
    reg                [  28: 0] hold_cnt                 ;
    reg                [   5: 0] shut_cnt                 ;

    localparam                   FFT_LEN                 = 1024  ;
    localparam                   LSM                     = 10    ;
    localparam                   DISP_W                  = 800   ;
    localparam                   VIRTUAL_DISP_W          = 400   ;
    localparam                   DISP_H                  = 480   ;
    localparam                   COLOR                   = 128   ;
    localparam                   COLOR_SPEAD             = 5     ;
    localparam                   AUDIO_COLOR_OFFSET      = 104   ;
    parameter                    HOLD_TIME               = 28'd150_000_000;
    
    localparam  IDLE      = 4'b0001,
                START_PRE = 4'b0010,
                START     = 4'b0100,
                DONE      = 4'b1000;


    wire               [   6: 0] rainbow_color_addr       ;
    reg                [   6: 0] color_addr_offset        ;
    wire               [  15: 0] rainbow_color            ;
    reg                [  15: 0] rainbow_color_r          ;
    assign                       rainbow_color_addr       = per_cnt==1 ? ((AUDIO_COLOR_OFFSET+color_addr_offset)>COLOR-1 ? (AUDIO_COLOR_OFFSET+color_addr_offset-COLOR)
                                                                                                                          :(AUDIO_COLOR_OFFSET+color_addr_offset))
                                                                        :((x_cnt+color_addr_offset)>COLOR-1 ? (x_cnt+color_addr_offset-COLOR)
                                                                                                             :(x_cnt+color_addr_offset));
    reg                          data_valid               ;
    reg                [   8: 0] ram[DISP_W/LSM-1:0]      ;
    wire               [   8: 0] fft_q_data               ;
    assign                       fft_q_data              = ram[x_cnt];
    wire               [   9: 0] maped_addr               ;
    wire               [   6: 0] raw_addr                 ;
    assign                       ram_fft_addr            = maped_addr;
    assign                       raw_addr                = per_cnt;
    assign                       buffer_clr              = per_cnt==1;
    
    localparam                   THRESHOLD               = 24    ;
    localparam                   DONE_SPEAD              = 12    ;
    localparam                   SHUT_SPEAD              = 6     ;
    localparam                   FFT_Q_LEVEL             = 3     ;
    localparam                   FIR_Q_LEVEL             = 17    ;
    localparam                   FIR_GROUP_DELAY         = 35*2+1;
    localparam                   AUDIO_Q_LEVEL           = 9     ;
    localparam                   AUDIO_WIDTH             = 8     ;
    localparam                   MID_REF                 = 240   ;

    wire               [  23: 0] audio_fir_dout           ;
    assign                       ram_fir_en              = ram_audio_en;
    assign                       ram_fir_addr            = ram_audio_addr;
    assign                       audio_fir_dout          = {ram_fir_dout[47],ram_fir_dout[22+FIR_Q_LEVEL:FIR_Q_LEVEL]};
    
    
    reg                [  23: 0] ram_audio_dout_r         ;
    wire               [   8: 0] audio_q_data             ;
    wire               [   8: 0] audio_q_data_r           ;
    assign                       audio_q_data_r          = ram_audio_dout_r[23]==1 ? (MID_REF-((~(ram_audio_dout_r[22:0]-1))>>AUDIO_Q_LEVEL))>0 ? (MID_REF-((~(ram_audio_dout_r[22:0]-1))>>AUDIO_Q_LEVEL)): 0
                                                                                    :(MID_REF+(ram_audio_dout_r[22:0]>>AUDIO_Q_LEVEL))<DISP_H ?   (MID_REF+(ram_audio_dout_r[22:0]>>AUDIO_Q_LEVEL)):DISP_H;
    assign                       audio_q_data            = ram_audio_dout[23]==1 ? (MID_REF-((~(ram_audio_dout[22:0]-1))>>AUDIO_Q_LEVEL))>0 ? (MID_REF-((~(ram_audio_dout[22:0]-1))>>AUDIO_Q_LEVEL)): 0
                                                                                  :(MID_REF+(ram_audio_dout[22:0]>>AUDIO_Q_LEVEL))<DISP_H ?   (MID_REF+(ram_audio_dout[22:0]>>AUDIO_Q_LEVEL)):DISP_H;
                                                                                                                                             
    reg                [  10: 0] audio_addr_offset        ;
    reg                [   9: 0] ram_audio_test_addr      ;
    reg                          audio_mid_polarity       ;
    wire                         is_audio_positive        ;
    assign                       is_audio_positive       = ~audio_fir_dout[23];
   
    assign                       ram_audio_en            = background_req;
    assign                       ram_audio_addr          = (y_cnt==0&&update_state==START) ? ram_audio_test_addr:((audio_cnt>>1)+(audio_addr_offset>FIR_GROUP_DELAY? (audio_addr_offset-FIR_GROUP_DELAY):0));

    wire                         blend_en                 ;
    wire                         fft_blend_en             ;
    wire                         audio_blend_en           ;
    reg                          hold_state               ;
    wire                         if_hold                  ;
    assign                       if_hold                 = (ram[9]>THRESHOLD||ram[10]>THRESHOLD||ram[11]>THRESHOLD||ram[12]>THRESHOLD);
    assign                       fft_blend_en            = (DISP_H-y_cnt<=2 ? 1
                                                                            :(lsm_cnt>1 ? fft_q_data>(DISP_H-y_cnt+THRESHOLD):0));
    assign                       audio_blend_en          = audio_q_data_r>audio_q_data ? (((DISP_H-y_cnt)<=((audio_q_data_r-audio_q_data)>AUDIO_WIDTH/2 ? audio_q_data_r
                                                                                                                                                        :(audio_q_data+AUDIO_WIDTH/2))
                                                                                       )&&((DISP_H-y_cnt)>=(audio_q_data-AUDIO_WIDTH/2)))
                                                                                        :(((DISP_H-y_cnt)<=(audio_q_data+AUDIO_WIDTH/2))
                                                                                        &&((DISP_H-y_cnt)>=((audio_q_data-audio_q_data_r)>AUDIO_WIDTH/2 ? audio_q_data_r
                                                                                                                                                        :(audio_q_data-AUDIO_WIDTH/2))));
    assign                       blend_en                = (fft_blend_en||audio_blend_en)&&(x_cnt>=(DISP_W/LSM/2-shut_cnt)&&x_cnt<(DISP_W/LSM/2+shut_cnt));

rainbow_colors u_rainbow_colors(
    .rainbow_color_addr          (rainbow_color_addr      ),
    .rainbow_color               (rainbow_color           )
);


FFT_decay_mapper u_FFT_decay_mapper(
    .raw_addr                    (raw_addr                ),
    .maped_addr                  (maped_addr              )
);

image_blender u_image_blender(
    .clk                         (clk                     ),
    .rst_n                       (rst_n                   ),
    .s_rgb565_data_a             (background_data         ),
    .s_rgb565_data_b             (audio_blend_en==1 ? rainbow_color_r:rainbow_color),
    .s_blend_en                  (blend_en                ),
    .s_data_valid                (data_valid              ),
    .m_rgb565_data               (buffer_data             ),
    .m_data_valid                (buffer_data_valid       )
);

    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            shut_cnt <= DISP_W/LSM/2;
        else if (~hold_state&&per_cnt == 1)
            shut_cnt <= shut_cnt >= SHUT_SPEAD ? (shut_cnt-SHUT_SPEAD):0;
        else if (hold_state)
            shut_cnt <= DISP_W/LSM/2;
        else
            shut_cnt <= shut_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            hold_state <= 1;
        else if (hold_cnt == HOLD_TIME-1)
            hold_state <= 0;
        else if (if_hold)
            hold_state <= 1;
        else
            hold_state <= hold_state;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            hold_cnt <= 0;
        else if (if_hold||hold_cnt == HOLD_TIME-1)
            hold_cnt <= 0;
        else
            hold_cnt <= hold_cnt+ 1'b1;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            ram_audio_dout_r <= 0;
        else if (ram_audio_en == 1)
            ram_audio_dout_r <= ram_audio_dout;
        else
            ram_audio_dout_r <= ram_audio_dout_r;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            rainbow_color_r <= 0;
        else if (per_cnt == 1)
            rainbow_color_r <= rainbow_color;
        else
            rainbow_color_r <= rainbow_color_r;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            color_spead_cnt <= 0;
        else if (per_cnt == 1)begin
            if (color_spead_cnt == COLOR_SPEAD-1)
                color_spead_cnt <= 0;
            else
                color_spead_cnt <= color_spead_cnt+1'b1;
        end
        else
            color_spead_cnt <= color_spead_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            color_addr_offset <= 0;
        else if (per_cnt == 1)begin
            if (color_spead_cnt == COLOR_SPEAD-1)
                color_addr_offset <= color_addr_offset+1'b1;
            else
                color_addr_offset <= color_addr_offset;
        end
        else
            color_addr_offset <= color_addr_offset;
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            ram_fft_en <= 0;
        else if (per_cnt == DISP_W/LSM-1)
            ram_fft_en <= 0;
        else if (update_start == 1)
            ram_fft_en <= 1;
        else
            ram_fft_en <= ram_fft_en;
    end
    
    integer i ;
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)begin
            for (i=0; i<DISP_W/LSM;i=i+1) begin
                ram[i]<=0;
            end
        end
        else if (per_cnt>0)begin
            ram[per_cnt-1][8:0]<=ram[per_cnt-1][8:0]<(ram_fft_dout>>FFT_Q_LEVEL) ? ((ram_fft_dout>>FFT_Q_LEVEL)>9'h1FF ? 9'h1FF
                                                                                                                        :(ram_fft_dout>>FFT_Q_LEVEL))
                                                                                  :(ram[per_cnt-1][8:0]>=DONE_SPEAD
                                                                                 &&(ram[per_cnt-1][8:0]-(ram_fft_dout>>FFT_Q_LEVEL))>DONE_SPEAD ? ram[per_cnt-1][8:0]-DONE_SPEAD
                                                                                                                                                 :ram[per_cnt-1][8:0]);
        end
        else begin
            ram[per_cnt-1][8:0]<=ram[per_cnt-1][8:0];
        end
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            per_cnt <= 0;
        else if (per_cnt == DISP_W/LSM)
            per_cnt <= 0;
        else if (update_state == START_PRE)
            per_cnt <= per_cnt + 1'b1;
        else
            per_cnt <= per_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            ram_audio_test_addr <= 0;
        else if (audio_cnt == 0)
            ram_audio_test_addr <= FFT_LEN/2;
        else if (audio_cnt>1&&audio_cnt <= (FFT_LEN-VIRTUAL_DISP_W)/2)
            ram_audio_test_addr <= audio_mid_polarity ? FFT_LEN/2+audio_cnt-1 : FFT_LEN/2-audio_cnt+1;
        else
            ram_audio_test_addr <= ram_audio_test_addr;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            audio_mid_polarity <= 0;
        else if (audio_cnt == 1)
            audio_mid_polarity <= is_audio_positive;
        else
            audio_mid_polarity <= audio_mid_polarity;
    end
    
    reg audio_addr_offset_flag;
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            audio_addr_offset_flag <= 0;
        else if (y_cnt == 0&&audio_cnt == 1)
            audio_addr_offset_flag <= 1;
        else if (y_cnt == 0&&audio_cnt > 2&&(audio_cnt <= ((FFT_LEN-VIRTUAL_DISP_W)/2+1))&&(audio_mid_polarity^is_audio_positive))
            audio_addr_offset_flag <= 0;
        else
            audio_addr_offset_flag <= audio_addr_offset_flag;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            audio_addr_offset <= 0;
        else if (y_cnt == 0&&audio_cnt > 2&&(audio_cnt <= ((FFT_LEN-VIRTUAL_DISP_W)/2+1))&&audio_addr_offset_flag)begin
            audio_addr_offset <= audio_mid_polarity^is_audio_positive ? (audio_mid_polarity ? ((FFT_LEN-VIRTUAL_DISP_W)/2+audio_cnt-2)
                                                                                            : ((FFT_LEN-VIRTUAL_DISP_W)/2-audio_cnt+2))
                                                                       :(audio_mid_polarity ? (FFT_LEN-VIRTUAL_DISP_W):0);
            end
        else
            audio_addr_offset <= audio_addr_offset;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            audio_cnt <= 0;
        else if (lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1)
            audio_cnt <= 0;
        else if (update_state == START)
            audio_cnt <= audio_cnt + 1'b1;
        else
            audio_cnt <= audio_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            lsm_cnt <= 0;
        else if (lsm_cnt == LSM-1)
            lsm_cnt <= 0;
        else if (update_state == START)
            lsm_cnt <= lsm_cnt + 1'b1;
        else
            lsm_cnt <= lsm_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            x_cnt <= 0;
        else if (lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1)
            x_cnt <= 0;
        else if (lsm_cnt == LSM-1)
            x_cnt <= x_cnt + 1'b1;
        else
            x_cnt <= x_cnt;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            y_cnt <= 0;
        else if (y_cnt == DISP_H-1&&lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1)
            y_cnt <= 0;
        else if (lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end
    
    always @(posedge clk)begin
        update_done <= update_state == DONE;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            data_valid <= 0;
        else if (per_cnt == DISP_W/LSM)
            data_valid <= 1;
        else if (lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1&&y_cnt == DISP_H-1)
            data_valid <= 0;
        else
            data_valid <= data_valid;
    end
    
    always@(posedge clk or negedge rst_n)begin
        if (!rst_n)
            background_req <= 0;
        else if (per_cnt == DISP_W/LSM-1)
            background_req <= 1;
        else if (lsm_cnt == LSM-2&&x_cnt == DISP_W/LSM-1&&y_cnt == DISP_H-1)
            background_req <= 0;
        else
            background_req <= background_req;
    end
    
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)begin
            update_state <= IDLE;
        end
        else begin
            case (update_state)
                IDLE:
                begin
                    if (update_start == 1)
                        update_state <= START_PRE;
                    else
                        update_state <= IDLE;
                end
                
                START_PRE:
                begin
                    if (per_cnt == DISP_W/LSM)
                        update_state <= START;
                    else
                        update_state <= START_PRE;
                end
                
                START:
                if (lsm_cnt == LSM-1&&x_cnt == DISP_W/LSM-1&&y_cnt == DISP_H-1)
                    update_state <= DONE;
                else
                    update_state <= START;
                
                DONE:
                update_state <= IDLE;
                
                default: update_state <= IDLE;
            endcase
        end
    end
    
endmodule
