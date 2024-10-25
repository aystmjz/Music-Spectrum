`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            新芯科技
// All rights reserved
// File name:              FFT_control.v
// Last modified Date:     2024/10/23
// Last Version:           V2.1
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/13
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module FFT_control(
    input                        rst_n                    ,
    input                        fft_clk                  ,
    output                       fft_done                 ,

    input                        ram_fft_clk              ,
    input                        ram_fft_en               ,
    input              [   9: 0] ram_fft_addr             ,
    output             [  31: 0] ram_fft_dout             ,

    input                        ram_audio_clk            ,
    input                        ram_audio_en             ,
    input              [   9: 0] ram_audio_addr           ,
    output             [  23: 0] ram_audio_dout           ,
    
    input                        ram_fir_clk            ,
    input                        ram_fir_en             ,
    input              [   9: 0] ram_fir_addr           ,
    output             [  47: 0] ram_fir_dout           ,

    input                        fifo_clr                 ,
    input                        fifo_clk                 ,
    input                        fifo_wren                ,
    input              [  23: 0] fifo_din                 ,
    output                       fifo_full                ,
    output                       fifo_empty               ,
    output                       fifo_rst_busy
    );

    reg                [   2: 0] fft_rd_state             ;
    reg                [   9: 0] rd_cnt                   ;
    reg                [   9: 0] wr_cnt                   ;
    reg                [   9: 0] fir_cnt                  ;
    
    localparam  FFT_LEN = 1024;
    localparam  RD_IDLE      = 3'b001,
                RD_DATA_PRE  = 3'b010,
                RD_DATA      = 3'b100;
   
    reg                          fft_s_data_tlast         ;
    reg                          fft_s_data_tvalid        ;
    wire                         fft_s_data_tready        ;
    wire               [  23: 0] fft_s_data_tdata         ;
    wire               [  63: 0] fft_m_data_tdata         ;
    wire                         fft_m_data_tvalid        ;
    wire               [  31: 0] fft_s_float_data_tdata   ;
    wire                         fft_s_float_data_tvalid  ;
    wire                         fft_s_float_data_tlast   ;

    wire                         fir_m_data_tvalid        ;
    wire               [  47: 0] fir_m_data_tdata         ;

fixed_to_float u_fixed_to_float (
    .aclk                        (fft_clk                 ),// input wire aclk
    .s_axis_a_tvalid             (fft_s_data_tvalid       ),// input wire s_axis_a_tvalid
    .s_axis_a_tdata              (fft_s_data_tdata        ),// input wire [23 : 0] s_axis_a_tdata
    .s_axis_a_tlast              (fft_s_data_tlast        ),// input wire s_axis_a_tlast
    .m_axis_result_tvalid        (fft_s_float_data_tvalid ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata         (fft_s_float_data_tdata  ),// output wire [31 : 0] m_axis_result_tdata
    .m_axis_result_tlast         (fft_s_float_data_tlast  ) // output wire m_axis_result_tlast
);

FFT u_FFT(
    .aclk                        (fft_clk                 ),// 时钟信号（input）
    .aresetn                     (rst_n                   ),// 复位信号，低有效（input）
    .s_axis_config_tdata         ({5'b0,10'b1010101010,1'b1}),// ip核设置参数内容[15:0]，[10:1]scale设置，[0:0]为1时做FFT运算，为0时做IFFT运算（input）
    .s_axis_config_tvalid        (1'b1                    ),// ip核配置输入有效，可直接设置为1（input）
    .s_axis_config_tready        (                        ),// output wire s_axis_config_tready
    //作为接收时域数据时是从设备
    .s_axis_data_tdata           ({32'd0,fft_s_float_data_tdata}),// 把时域信号往FFT IP核传输的数据通道,[63:32]为虚部，[31:0]为实部（input，主->从）
    .s_axis_data_tvalid          (fft_s_float_data_tvalid ),// 表示主设备正在驱动一个有效的传输（input，主->从）
    .s_axis_data_tready          (fft_s_data_tready       ),// 表示从设备已经准备好接收一次数据传输（output，从->主），当tvalid和tready同时为高时，启动数据传输
    .s_axis_data_tlast           (fft_s_float_data_tlast  ),// 主设备向从设备发送传输结束信号（input，主->从，拉高为结束）
    //作为发送频谱数据时是主设备
    .m_axis_data_tdata           (fft_m_data_tdata        ),// FFT输出的频谱数据，[63:32]对应的是虚部数据，[31:0]对应的是实部数据(output，主->从)。
    .m_axis_data_tuser           (fft_m_data_tuser        ),// 输出频谱的索引[15:0] 有效 [9:0](output，主->从)，该值*fs/N即为对应频点；
    .m_axis_data_tvalid          (fft_m_data_tvalid       ),// 表示主设备正在驱动一个有效的传输（output，主->从）
    .m_axis_data_tready          (1'b1                    ),// 表示从设备已经准备好接收一次数据传输（input，从->主），当tvalid和tready同时为高时，启动数据传输
    .m_axis_data_tlast           (                        ),// 主设备向从设备发送传输结束信号（output，主->从，拉高为结束）
    //其他输出数据
    .event_frame_started         (                        ),// output wire event_frame_started
    .event_tlast_unexpected      (                        ),// output wire event_tlast_unexpected
    .event_tlast_missing         (                        ),// output wire event_tlast_missing
    .event_status_channel_halt   (                        ),// output wire event_status_channel_halt
    .event_data_in_channel_halt  (                        ),// output wire event_data_in_channel_halt
    .event_data_out_channel_halt (                        ) // output wire event_data_out_channel_halt
  );

   
    reg                          fifo_rden                ;
    wire               [  10: 0] fifo_rd_cnt              ;
    wire               [  10: 0] fifo_wr_cnt              ;
    wire                         fifo_rd_rst_busy         ;
    wire                         fifo_wr_rst_busy         ;

    assign                       fifo_rst_busy           = fifo_rd_rst_busy||fifo_wr_rst_busy;

audio_fft_fifo u_audio_fft_fifo (
    .rst                         (fifo_clr                ),// input wire rst
    .wr_clk                      (fifo_clk                ),// input wire wr_clk
    .rd_clk                      (fft_clk                 ),// input wire rd_clk
    .din                         (fifo_din                ),// input wire [15 : 0] din
    .wr_en                       (fifo_wren               ),// input wire wr_en
    .rd_en                       (fifo_rden               ),// input wire rd_en
    .dout                        (fft_s_data_tdata        ),// output wire [15 : 0] dout
    .full                        (fifo_full               ),// output wire full
    .empty                       (fifo_empty              ),// output wire empty
    .rd_data_count               (fifo_rd_cnt             ),// output wire [10 : 0] rd_data_count
    .wr_data_count               (fifo_wr_cnt             ),// output wire [10 : 0] wr_data_count
    .wr_rst_busy                 (fifo_wr_rst_busy        ),// output wire wr_rst_busy
    .rd_rst_busy                 (fifo_rd_rst_busy        ) // output wire rd_rst_busy
);

    wire               [  31: 0] modulo_data_result_tdata  ;
    wire                         modulo_data_result_tvalid ;

modulo_wrapper modulo_wrapper(
    .aclk                        (fft_clk                 ),
    .arsetn                      (rst_n                   ),
    .s_axis_data_im_tdata        (fft_m_data_tdata[63:32] ),
    .s_axis_data_im_tvalid       (fft_m_data_tvalid       ),
    .s_axis_data_re_tdata        (fft_m_data_tdata[31:0]  ),
    .s_axis_data_re_tvalid       (fft_m_data_tvalid       ),
    .s_axis_data_result_tdata    (modulo_data_result_tdata),
    .s_axis_data_result_tvalid   (modulo_data_result_tvalid));


fft_ram u_fft_ram (
    .clka                        (fft_clk                 ),// input wire clka
    .ena                         (modulo_data_result_tvalid),// input wire ena
    .wea                         (1'b1                    ),// input wire [0 : 0] wea
    .addra                       (wr_cnt                  ),// input wire [9 : 0] addra
    .dina                        (modulo_data_result_tdata),// input wire [31 : 0] dina
    .clkb                        (ram_fft_clk             ),// input wire clkb
    .enb                         (ram_fft_en              ),// input wire enb
    .addrb                       (ram_fft_addr            ),// input wire [9 : 0] addrb
    .doutb                       (ram_fft_dout            ) // output wire [31 : 0] doutb
);

audio_ram u_audio_ram (
    .clka                        (fft_clk                 ),// input wire clka
    .ena                         (fft_s_data_tvalid       ),// input wire ena
    .wea                         (1'b1                    ),// input wire [0 : 0] wea
    .addra                       (rd_cnt                  ),// input wire [9 : 0] addra
    .dina                        (fft_s_data_tdata        ),// input wire [23 : 0] dina
    .clkb                        (ram_audio_clk           ),// input wire clkb
    .enb                         (ram_audio_en            ),// input wire enb
    .addrb                       (ram_audio_addr          ),// input wire [9 : 0] addrb
    .doutb                       (ram_audio_dout          ) // output wire [23 : 0] doutb
);

fir_ram u_fir_ram (
    .clka                        (fft_clk                 ),// input wire clka
    .ena                         (fir_m_data_tvalid       ),// input wire ena
    .wea                         (1                       ),// input wire [0 : 0] wea
    .addra                       (fir_cnt                 ),// input wire [9 : 0] addra
    .dina                        (fir_m_data_tdata        ),// input wire [47 : 0] dina
    .clkb                        (ram_fir_clk             ),// input wire clkb
    .enb                         (ram_fir_en              ),// input wire enb
    .addrb                       (ram_fir_addr            ),// input wire [9 : 0] addrb
    .doutb                       (ram_fir_dout            ) // output wire [47 : 0] doutb
);


fir u_fir (
    .aclk                        (fft_clk                 ),// input wire aclk
    .s_axis_data_tvalid          (fft_s_data_tvalid       ),// input wire s_axis_data_tvalid
    .s_axis_data_tready          (                        ),// output wire s_axis_data_tready
    .s_axis_data_tdata           (fft_s_data_tdata        ),// input wire [23 : 0] s_axis_data_tdata
    .m_axis_data_tvalid          (fir_m_data_tvalid       ),// output wire m_axis_data_tvalid
    .m_axis_data_tdata           (fir_m_data_tdata        ) // output wire [47 : 0] m_axis_data_tdata
);

    always @(posedge fft_clk or negedge rst_n)
    begin
        if(!rst_n)
            fir_cnt<=0;
        else if (fir_cnt==FFT_LEN-1)
            fir_cnt<=0;
        else if(fft_s_data_tvalid)
            fir_cnt<=fir_cnt+1;
        else
            fir_cnt<=fir_cnt;
    end

    assign                       fft_done                = rd_cnt>=FFT_LEN-10;//确保disp时钟能采集到

  //**********************************
  //读FIFO状态机
  //**********************************
    always @(posedge fft_clk or negedge rst_n)
        begin
            if(!rst_n)
                fifo_rden<=0;
            else if(fifo_rd_cnt>=FFT_LEN&&fft_s_data_tready)
                fifo_rden<=1;
            else if(rd_cnt==FFT_LEN-2)
                fifo_rden<=0;
            else
                fifo_rden<=fifo_rden;
        end

    always @(posedge fft_clk or negedge rst_n)
        begin
            if(!rst_n)
                fft_s_data_tvalid<=0;
            else if(fft_rd_state==RD_DATA_PRE)
                fft_s_data_tvalid<=1;
            else if(fft_rd_state==RD_DATA&&rd_cnt==FFT_LEN-1)
                fft_s_data_tvalid<=0;
            else
                fft_s_data_tvalid<=fft_s_data_tvalid;
        end

    always @(posedge fft_clk or negedge rst_n)
        begin
            if(!rst_n)
                rd_cnt<=0;
            else if(fft_rd_state==RD_DATA)
                rd_cnt<=rd_cnt+1;
            else if (rd_cnt==FFT_LEN-1)
                rd_cnt<=0;
            else
                rd_cnt<=rd_cnt;
        end


    always @(posedge fft_clk ) begin
        fft_s_data_tlast<=(fft_rd_state==RD_DATA&&rd_cnt==FFT_LEN-2);
    end
                          
    always @(posedge fft_clk or negedge rst_n)
    begin
        if(!rst_n)begin
            fft_rd_state<=RD_IDLE;
        end
        else begin
            case (fft_rd_state)
                RD_IDLE:
                begin
                    if(fifo_rd_cnt>=FFT_LEN&&fft_s_data_tready)
                        fft_rd_state<=RD_DATA_PRE;
                    else
                        fft_rd_state <= RD_IDLE;
                end

                RD_DATA_PRE:
                    fft_rd_state <= RD_DATA;

                RD_DATA:
                begin
                    if(rd_cnt==FFT_LEN-1)
                        fft_rd_state <= RD_IDLE;
                    else
                        fft_rd_state <= RD_DATA;
                end
                default: fft_rd_state <= RD_IDLE;
            endcase
        end
    end

    always @(posedge fft_clk or negedge rst_n)begin
        if(!rst_n)
            wr_cnt<=0;
        else if(fft_s_data_tlast==1)
            wr_cnt<=0;
        else if(modulo_data_result_tvalid==1)
            wr_cnt<=wr_cnt+1;
        else
            wr_cnt<=wr_cnt;
    end


ila_fir_fft your_instance_name (
    .clk                         (fft_clk                 ),// input wire clk
    .probe0                      (modulo_data_result_tvalid),// input wire [0:0]  probe0
    .probe1                      (modulo_data_result_tdata),// input wire [31:0]  probe1
    .probe2                      (fir_m_data_tvalid       ),// input wire [0:0]  probe2
    .probe3                      (fir_m_data_tdata        ) // input wire [47:0]  probe3
);

endmodule
