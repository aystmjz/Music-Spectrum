/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : bit8_trans_bit16
// Description   : 数据位宽转换，8bit输入转16bit输出
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

module bit8_trans_bit16(
  input            clk,
  input            reset_p,

  input      [7:0] bit8_in,
  input            bit8_in_valid,

  output reg [15:0]bit16_out,
  output reg       bit16_out_valid
);

  reg bit8_cnt;

  always@(posedge clk or posedge reset_p)
  begin
    if(reset_p)
      bit8_cnt <= 1'b0;
    else if(bit8_in_valid)
      bit8_cnt <= bit8_cnt + 1'b1;
    else
      bit8_cnt <= bit8_cnt;
  end

  always@(posedge clk or posedge reset_p)
  begin
    if(reset_p)
      bit16_out <= 16'h0000;
    else if(bit8_in_valid)
      bit16_out <= {bit16_out[7:0],bit8_in};
    else
      bit16_out <= bit16_out;
  end

  always@(posedge clk or posedge reset_p)
  begin
    if(reset_p)
      bit16_out_valid <= 1'b0;
    else if(bit8_in_valid && bit8_cnt)
      bit16_out_valid <= 1'b1;
    else
      bit16_out_valid <= 1'b0;
  end

endmodule 