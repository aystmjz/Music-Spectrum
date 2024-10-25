`timescale 1ns / 1ps


module WM8960_Init(
	Clk,
	Rst_n,
	
	Go,
	device_id,
	Init_Done,
	
	i2c_sclk,
	i2c_sdat
);

	input Clk;
	input Rst_n;
	input Go;
	input [15:0]device_id;
	output reg Init_Done;
	
	output i2c_sclk;
	inout i2c_sdat;
	
	wire [7:0]addr;
	reg wrreg_req;
	reg rdreg_req;
    reg [7:0]cnt;
	wire [7:0]wrdata;
	
	wire [7:0]rddata;
	wire RW_Done;
	wire ack;

	wire [15:0]lut;
	localparam lut_size = 14;
	localparam addr_mode = 1'b0;
	WM8960_init_table #(
        .ADDR_WIDTH (7)
    )WM8960_init_table
    (
		.addr(cnt),
		.clk(Clk),
		.q(lut)
	);
	assign addr = lut[15:8];
	assign wrdata = lut[7:0];
	
	
	i2c_control i2c_control(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.wrreg_req(wrreg_req),
		.rdreg_req(0),
		.addr(addr),
		.addr_mode(addr_mode),
		.wrdata(wrdata),
		.rddata(rddata),
		.device_id(device_id),
		.RW_Done(RW_Done),
		.ack(ack),
		.dly_cnt_max(0),
		.i2c_sclk(i2c_sclk),
		.i2c_sdat(i2c_sdat)
	);
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		cnt <= 0;
	else if(Go)
		cnt <= 0;
	else if(cnt < lut_size)begin
		if(RW_Done && (!ack))
			cnt <= cnt + 1'b1;
		else
			cnt <= cnt;
	end
	else
		cnt <= 0;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Init_Done <= 0;
	else if(Go)
		Init_Done <= 0;
	else if(cnt == lut_size)
		Init_Done <= 1;

	reg [1:0]state;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		state <= 0;
		wrreg_req <= 1'b0;
	end
	else if(cnt < lut_size)begin
		case(state)
			0:
				if(Go)
					state <= 1;
				else
					state <= 0;
			
			1:
				begin
					wrreg_req <= 1'b1;
					state <= 2;
				end
				
			2:
				begin
					wrreg_req <= 1'b0;
					if(RW_Done)
						state <= 1;
					else
						state <= 2;
				end
				
			default:state <= 0;
		endcase
	end
	else
		state <= 0;

endmodule
