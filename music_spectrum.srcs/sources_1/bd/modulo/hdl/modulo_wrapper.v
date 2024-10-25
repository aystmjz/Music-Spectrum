//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Fri Oct 18 23:07:18 2024
//Host        : Dell-G15 running 64-bit major release  (build 9200)
//Command     : generate_target modulo_wrapper.bd
//Design      : modulo_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module modulo_wrapper
   (aclk,
    arsetn,
    s_axis_data_im_tdata,
    s_axis_data_im_tvalid,
    s_axis_data_re_tdata,
    s_axis_data_re_tvalid,
    s_axis_data_result_tdata,
    s_axis_data_result_tvalid);
  input aclk;
  input arsetn;
  input [31:0]s_axis_data_im_tdata;
  input s_axis_data_im_tvalid;
  input [31:0]s_axis_data_re_tdata;
  input s_axis_data_re_tvalid;
  output [31:0]s_axis_data_result_tdata;
  output s_axis_data_result_tvalid;

  wire aclk;
  wire arsetn;
  wire [31:0]s_axis_data_im_tdata;
  wire s_axis_data_im_tvalid;
  wire [31:0]s_axis_data_re_tdata;
  wire s_axis_data_re_tvalid;
  wire [31:0]s_axis_data_result_tdata;
  wire s_axis_data_result_tvalid;

  modulo modulo_i
       (.aclk(aclk),
        .arsetn(arsetn),
        .s_axis_data_im_tdata(s_axis_data_im_tdata),
        .s_axis_data_im_tvalid(s_axis_data_im_tvalid),
        .s_axis_data_re_tdata(s_axis_data_re_tdata),
        .s_axis_data_re_tvalid(s_axis_data_re_tvalid),
        .s_axis_data_result_tdata(s_axis_data_result_tdata),
        .s_axis_data_result_tvalid(s_axis_data_result_tvalid));
endmodule
