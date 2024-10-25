`timescale 1ns / 1ps


module FFT_tb();

reg clk;
reg rst_n;
reg signed [31:0] Time_data_I[1023:0];
reg data_finish_flag;

wire              fft_s_config_tready;

reg signed [63:0] fft_s_data_tdata;
reg               fft_s_data_tvalid;
wire              fft_s_data_tready;
reg               fft_s_data_tlast;

wire signed [63 : 0] fft_m_data_tdata;
wire signed [15:0]  fft_m_data_tuser;
wire               fft_m_data_tvalid;
reg                fft_m_data_tready;
wire               fft_m_data_tlast;

wire          fft_event_frame_started;
wire          fft_event_tlast_unexpected;
wire          fft_event_tlast_missing;
wire          fft_event_status_channel_halt;
wire          fft_event_data_in_channel_halt;
wire          fft_event_data_out_channel_halt;

reg [10:0]     count;

reg signed [31:0] fft_i_out;
reg signed [31:0] fft_q_out;
reg signed [31:0] fft_abs;

initial begin
    clk <= 1'b1;
    rst_n <= 1'b0;
    fft_m_data_tready <= 1'b1;
end

initial begin
    $readmemb("/data_before_fft.txt",Time_data_I);
end

always #5 clk = ~clk;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tdata  <= 32'd0;
        fft_s_data_tlast  <= 1'b0;
        data_finish_flag  <= 1'b0;
        count <= 10'd0;
        rst_n = 1'b1;
    end
    else if (fft_s_data_tready&&!data_finish_flag) begin 
        if(count == 1024) begin
            fft_s_data_tvalid <= 1'b0;
            fft_s_data_tlast  <= 1'b1;//要提前一拍才正确
            data_finish_flag <= 1'b1;
            fft_s_data_tdata  <= {32'd0,Time_data_I[count]};
            count <= 10'd0;
        end
        else begin
            fft_s_data_tvalid <= 1'b1;
            fft_s_data_tlast  <= 1'b0;
            fft_s_data_tdata  <= {32'd0,Time_data_I[count]};
            count <= count + 1'b1;
        end
    end
    else begin
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tlast  <= 1'b0;
        fft_s_data_tdata <= fft_s_data_tdata;
    end
end

always @ (posedge clk) begin
    if(fft_m_data_tvalid) begin
        fft_i_out <= fft_m_data_tdata[63:32];
        fft_q_out <= fft_m_data_tdata[31:0];
    end
end

always @ (posedge clk) begin
    fft_abs <= $signed(fft_i_out)* $signed(fft_i_out)+ $signed(fft_q_out)* $signed(fft_q_out);
end


//fft ip核例化
FFT u_FFT(
    .aclk(clk),                                                // 时钟信号（input）
    .aresetn(rst_n),                                           // 复位信号，低有效（input）
    .s_axis_config_tdata         ({5'b0,10'b1010101010,1'b1}),// ip核设置参数内容[15:0]，[10:1]scale设置，[0:0]为1时做FFT运算，为0时做IFFT运算（input）
    .s_axis_config_tvalid        (1'b1                    ),// ip核配置输入有效，可直接设置为1（input）
    .s_axis_config_tready(fft_s_config_tready),                // output wire s_axis_config_tready
    //作为接收时域数据时是从设备
    .s_axis_data_tdata(fft_s_data_tdata),                      // 把时域信号往FFT IP核传输的数据通道,[31:16]为虚部，[15:0]为实部（input，主->从）
    .s_axis_data_tvalid(fft_s_data_tvalid),                    // 表示主设备正在驱动一个有效的传输（input，主->从）
    .s_axis_data_tready(fft_s_data_tready),                    // 表示从设备已经准备好接收一次数据传输（output，从->主），当tvalid和tready同时为高时，启动数据传输
    .s_axis_data_tlast(fft_s_data_tlast),                      // 主设备向从设备发送传输结束信号（input，主->从，拉高为结束）
    //作为发送频谱数据时是主设备
    .m_axis_data_tdata(fft_m_data_tdata),                      // FFT输出的频谱数据，[47:24]对应的是虚部数据，[23:0]对应的是实部数据(output，主->从)。
    .m_axis_data_tuser(fft_m_data_tuser),                      // 输出频谱的索引(output，主->从)，该值*fs/N即为对应频点；
    .m_axis_data_tvalid(fft_m_data_tvalid),                    // 表示主设备正在驱动一个有效的传输（output，主->从）
    .m_axis_data_tready(fft_m_data_tready),                    // 表示从设备已经准备好接收一次数据传输（input，从->主），当tvalid和tready同时为高时，启动数据传输
    .m_axis_data_tlast(fft_m_data_tlast),                      // 主设备向从设备发送传输结束信号（output，主->从，拉高为结束）
    //其他输出数据
    .event_frame_started(fft_event_frame_started),                  // output wire event_frame_started
    .event_tlast_unexpected(fft_event_tlast_unexpected),            // output wire event_tlast_unexpected
    .event_tlast_missing(fft_event_tlast_missing),                  // output wire event_tlast_missing
    .event_status_channel_halt(fft_event_status_channel_halt),      // output wire event_status_channel_halt
    .event_data_in_channel_halt(fft_event_data_in_channel_halt),    // output wire event_data_in_channel_halt
    .event_data_out_channel_halt(fft_event_data_out_channel_halt)   // output wire event_data_out_channel_halt
  );
    
    
endmodule
