`timescale 1ns / 1ps

module audio_rcv
(
input  audio_bclk , //WM8960输出的位时钟
input  sys_rst_n , //系统复位，低有效
input  audio_lrc , //WM8960输出的数据左/右对齐时钟
input  audio_adcdat , //WM8960ADC数据输出

output reg [23:0] adc_data , //一次接收的数据
output  l_rcv_done, //左声道一次数据接收完成
output  r_rcv_done //右声道一次数据接收完成
 );

 ////
 //\* Parameter and Internal Signal \//
 ////

 //reg define
 reg rcv_done;
 reg audio_lrc_d1; //对齐时钟打一拍信号
 reg [4:0] adcdat_cnt ; //WM8960ADC数据输出位数计数器
 reg [23:0] data_reg ; //adc_data数据寄存器

 //wire define
 wire lrc_edge ; //对齐时钟信号沿标志信号


 ////
 //\* Main Code \//
 ////

 //使用异或运算符产生信号沿标志信号
 assign lrc_edge = audio_lrc ^ audio_lrc_d1;
 assign l_rcv_done= rcv_done&&!audio_lrc;
 assign r_rcv_done= rcv_done&&audio_lrc;

 //对audio_lrc信号打一拍以方便获得信号沿标志信号
 always@(posedge audio_bclk or negedge sys_rst_n)
 if(sys_rst_n == 1'b0)
 audio_lrc_d1 <= 1'b0;
 else
 audio_lrc_d1 <= audio_lrc;

 //adcdat_cnt:当信号沿标志信号为高电平时，计数器清零
 always@(posedge audio_bclk or negedge sys_rst_n)
 if(sys_rst_n == 1'b0)
 adcdat_cnt <= 5'b0;
 else if(lrc_edge == 1'b1)
 adcdat_cnt <= 5'b0;
 else if(adcdat_cnt < 5'd26)
 adcdat_cnt <= adcdat_cnt + 1'b1;
 else
 adcdat_cnt <= adcdat_cnt;

 //将WM8960输出的ADC数据寄存在data_reg中，一次寄存24位
 always@(posedge audio_bclk or negedge sys_rst_n)
 if(sys_rst_n == 1'b0)
 data_reg <= 24'b0;
 else if(adcdat_cnt <= 5'd23)
 data_reg[23-adcdat_cnt] <= audio_adcdat;
 else
 data_reg <= data_reg;

 //当最后一位数据传完之后，读出寄存器的值给adc_data
 always@(posedge audio_bclk or negedge sys_rst_n)
 if(sys_rst_n == 1'b0)
 adc_data <= 24'b0;
 else if(adcdat_cnt == 5'd24)
 adc_data <= data_reg;
 else
 adc_data <= adc_data;

 //当最后一位数据传完之后，输出一个时钟的完成标志信号
 always@(posedge audio_bclk or negedge sys_rst_n)
 if(sys_rst_n == 1'b0)
 rcv_done <= 1'b0;
 else if(adcdat_cnt == 5'd24)
 rcv_done <= 1'b1;
 else
 rcv_done <= 1'b0;

 endmodule