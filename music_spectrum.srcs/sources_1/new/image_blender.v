`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Copyright(C)            新芯科技
// All rights reserved
// File name:              FFT_decay_mapper.v
// Last modified Date:     2024/10/17
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             aystmjz
// Created date:           2024/10/17
// Version:                V1.0
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//


module image_blender(
    input                        clk                      ,
    input                        rst_n                    ,
    input              [  15: 0] s_rgb565_data_a          ,
    input              [  15: 0] s_rgb565_data_b          ,
    input                        s_blend_en               ,
    input                        s_data_valid             ,
    output             [  15: 0] m_rgb565_data            ,
    output reg                   m_data_valid
    );
    reg                [  15: 0] s_rgb565_data_a_r        ;
    reg                [  15: 0] s_rgb565_data_b_r        ;
    reg                          s_blend_en_r             ;

    wire               [   7: 0] s_rgb888_r_a             ;
    wire               [   7: 0] s_rgb888_g_a             ;
    wire               [   7: 0] s_rgb888_b_a             ;
    wire               [   7: 0] s_rgb888_r_b             ;
    wire               [   7: 0] s_rgb888_g_b             ;
    wire               [   7: 0] s_rgb888_b_b             ;

    assign                       s_rgb888_r_a              = {s_rgb565_data_a_r[15:11], 3'b000};
    assign                       s_rgb888_g_a              = {s_rgb565_data_a_r[10:5], 2'b00};
    assign                       s_rgb888_b_a              = {s_rgb565_data_a_r[4:0], 3'b000};
    assign                       s_rgb888_r_b              = {s_rgb565_data_b_r[15:11], 3'b000};
    assign                       s_rgb888_g_b              = {s_rgb565_data_b_r[10:5], 2'b00};
    assign                       s_rgb888_b_b              = {s_rgb565_data_b_r[4:0], 3'b000};

    reg                [   7: 0] s_rgb888_r_a_r           ;
    reg                [   7: 0] s_rgb888_g_a_r           ;
    reg                [   7: 0] s_rgb888_b_a_r           ;
    reg                [   7: 0] s_rgb888_r_b_r           ;
    reg                [   7: 0] s_rgb888_g_b_r           ;
    reg                [   7: 0] s_rgb888_b_b_r           ;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)begin
            s_rgb888_r_a_r<=0;
            s_rgb888_g_a_r<=0;
            s_rgb888_b_a_r<=0;
            s_rgb888_r_b_r<=0;
            s_rgb888_g_b_r<=0;
            s_rgb888_b_b_r<=0;
        end
        else begin
            s_rgb888_r_a_r<=s_rgb888_r_a;
            s_rgb888_g_a_r<=s_rgb888_g_a;
            s_rgb888_b_a_r<=s_rgb888_b_a;
            s_rgb888_r_b_r<=s_rgb888_r_b;
            s_rgb888_g_b_r<=s_rgb888_g_b;
            s_rgb888_b_b_r<=s_rgb888_b_b;
        end
    end

    wire                [   7: 0] m_rgb888_r               ;
    wire                [   7: 0] m_rgb888_g               ;
    wire                [   7: 0] m_rgb888_b               ;

    assign                       m_rgb565_data           = {{m_rgb888_r[7:3], m_rgb888_g[7:2], m_rgb888_b[7:3]}};

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)begin
            s_rgb565_data_a_r<=0;
            s_rgb565_data_b_r<=0;
            s_blend_en_r<=0;
        end
        else if(s_data_valid==1) begin
            s_rgb565_data_a_r<=s_rgb565_data_a;
            s_rgb565_data_b_r<=s_rgb565_data_b;
            s_blend_en_r<=s_blend_en;
        end
    end

    reg blend_en;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)begin
            blend_en<=0;
        end
        else begin
            blend_en<=s_blend_en_r;
        end
    end

    reg m_data_valid_r;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)begin
            m_data_valid_r<=0;
        end
        else begin
            m_data_valid_r<=s_data_valid;
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            m_data_valid<=0;
        else
            m_data_valid<=m_data_valid_r;
    end

    wire               [   7: 0] mult_r_A                 ;
    wire               [   7: 0] mult_r_B                 ;
    wire               [  15: 0] mult_r_P                 ;
    wire               [   7: 0] mult_g_A                 ;
    wire               [   7: 0] mult_g_B                 ;
    wire               [  15: 0] mult_g_P                 ;
    wire               [   7: 0] mult_b_A                 ;
    wire               [   7: 0] mult_b_B                 ;
    wire               [  15: 0] mult_b_P                 ;

    assign                       mult_r_A                = s_rgb888_r_b<=8'd128 ? s_rgb888_r_a:(8'd255-s_rgb888_r_a);
    assign                       mult_r_B                = s_rgb888_r_b<=8'd128 ? s_rgb888_r_b:(8'd255-s_rgb888_r_b);
    assign                       mult_g_A                = s_rgb888_g_b<=8'd128 ? s_rgb888_g_a:(8'd255-s_rgb888_g_a);
    assign                       mult_g_B                = s_rgb888_g_b<=8'd128 ? s_rgb888_g_b:(8'd255-s_rgb888_g_b);
    assign                       mult_b_A                = s_rgb888_b_b<=8'd128 ? s_rgb888_b_a:(8'd255-s_rgb888_b_a);
    assign                       mult_b_B                = s_rgb888_b_b<=8'd128 ? s_rgb888_b_b:(8'd255-s_rgb888_b_b);

    assign                       m_rgb888_r              = blend_en ? (s_rgb888_r_b_r<=8'd128 ? mult_r_P>>7:8'd255-(mult_r_P>>7)):s_rgb888_r_a_r;
    assign                       m_rgb888_g              = blend_en ? (s_rgb888_g_b_r<=8'd128 ? mult_g_P>>7:8'd255-(mult_g_P>>7)):s_rgb888_g_a_r;
    assign                       m_rgb888_b              = blend_en ? (s_rgb888_b_b_r<=8'd128 ? mult_b_P>>7:8'd255-(mult_b_P>>7)):s_rgb888_b_a_r;


    multiplier multiplier_r (
    .CLK                         (clk                     ),// input wire CLK
    .A                           (mult_r_A                ),// input wire [7 : 0] A
    .B                           (mult_r_B                ),// input wire [7 : 0] B
    .P                           (mult_r_P                ) // output wire [15 : 0] P
);

    multiplier multiplier_g (
    .CLK                         (clk                     ),// input wire CLK
    .A                           (mult_g_A                ),// input wire [7 : 0] A
    .B                           (mult_g_B                ),// input wire [7 : 0] B
    .P                           (mult_g_P                ) // output wire [15 : 0] P
);

    multiplier multiplier_b (
    .CLK                         (clk                     ),// input wire CLK
    .A                           (mult_b_A                ),// input wire [7 : 0] A
    .B                           (mult_b_B                ),// input wire [7 : 0] B
    .P                           (mult_b_P                ) // output wire [15 : 0] P
);


endmodule
