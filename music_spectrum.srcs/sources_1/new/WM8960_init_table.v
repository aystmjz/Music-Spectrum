`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            新芯科技
// All rights reserved
// File name:              FFT_decay_mapper.v
// Last modified Date:     2024/10/15
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/15
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module WM8960_init_table
#(parameter DATA_WIDTH=16, parameter ADDR_WIDTH=8)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk,
	output reg [(DATA_WIDTH-1):0] q
);

	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	initial begin
		rom[00] =  {7'h0f,9'b0};//重置
		rom[01] =  {7'h19,9'b1_1111_1100};//设置电源 VREF AINL AINR ADCL ADCR
		rom[02] =  {7'h1a,9'b0_0110_0000};//设置电源LOUT1 ROUT1
		rom[03] =  {7'h2F,9'b0_0000_1100};//设置电源LOMIX ROMIX
		rom[04] =  {7'h04,9'b0_0000_0000};//设置时钟
		//Mclk--div1-->SYSCLK---DIV256--->DAC/ADC sample Freq=11.289(MCLK)/256=44.1KHZ
		rom[05] =  {7'h07,9'b0_0100_1010};//设置Digital Audio Interface
		//ALRSWAP-> Output left and right data as normal
		//BCLKINV-> BCLK not inverted
		//MS-> Enable master mode
		//DLRSWAP-> Output left and right data as normal
		//LRP-> normal LRCLK polarity
		//WL-> 24 bits
		//FORMAT-> I2S Format
		rom[06] =  {7'h02,9'b1_1111_1001};//设置LOUT1 Volume->+0dB (1dB steps)
		rom[07] =  {7'h03,9'b1_1111_1001};//设置ROUT1 Volume->+0dB (1dB steps)
		rom[08] =  {7'h15,9'b1_1100_0011};//设置ADC VOLUME Left ADC Volume-> 0dB (0.5dB steps)
		rom[09] =  {7'h16,9'b1_1100_0011};//设置ADC VOLUME Right ADC Volume-> 0dB (0.5dB steps)
		rom[10] =  {7'h2D,9'b0_1000_0000};//设置mixer输入通道 Left Bypass -> 0dB
		rom[11] =  {7'h2E,9'b0_1000_0000};//设置mixer输入通道 Right Bypass -> 0dB
		rom[12] =  {7'h2B,9'b0_0101_0000};//设置ADC输入通道 Input Boost Mixer 1 LIN3BOOST-> +0dB (3dB steps)
		rom[13] =  {7'h2C,9'b0_0000_1010};//设置ADC输入通道 Input Boost Mixer 2 RIN2BOOST-> +0dB (3dB steps)
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end
endmodule
