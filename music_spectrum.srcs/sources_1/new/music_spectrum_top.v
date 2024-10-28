`timescale 1ns / 1ps

module music_spectrum_top(
  //user
    input                        key_pl                  ,
    output                       led                      ,
  //TFT Interface
    output             [  15: 0] TFT_rgb                  ,//TFT数据输出
    output                       TFT_hs                   ,//TFT行同步信号
    output                       TFT_vs                   ,//TFT场同步信号
    output                       TFT_clk                  ,//TFT像素时钟
    output                       TFT_de                   ,//TFT数据使能
    output reg                   TFT_pwm                  ,//TFT背光控制
  //Rx uart Interface
    input                        uart_rx                  ,
  //ov5640 init IIC interface
    output                       sclk                     ,
    inout                        sdat                     ,
    output                       I2S_MCLK                 ,
    input                        I2S_BCLK                 ,
    input                        I2S_ADCLRC               ,
    input                        I2S_ADCDAT               ,
  //DDR3 Interface
  // Inouts
    inout              [  31: 0] ddr3_dq                  ,
    inout              [   3: 0] ddr3_dqs_n               ,
    inout              [   3: 0] ddr3_dqs_p               ,
  // Outputs
    output             [  14: 0] ddr3_addr                ,
    output             [   2: 0] ddr3_ba                  ,
    output                       ddr3_ras_n               ,
    output                       ddr3_cas_n               ,
    output                       ddr3_we_n                ,
    output                       ddr3_reset_n             ,
    output             [   0: 0] ddr3_ck_p                ,
    output             [   0: 0] ddr3_ck_n                ,
    output             [   0: 0] ddr3_cke                 ,
    output             [   0: 0] ddr3_cs_n                ,
    output             [   3: 0] ddr3_dm                  ,
    output             [   0: 0] ddr3_odt                 ,
    inout                        FIXED_IO_ddr_vrn         ,
    inout                        FIXED_IO_ddr_vrp         ,
    inout              [  53: 0] FIXED_IO_mio             ,
    inout                        FIXED_IO_ps_clk          ,
    inout                        FIXED_IO_ps_porb         ,
    inout                        FIXED_IO_ps_srstb
);

//Resolution_800x480  像素时钟为33MHz
    parameter                    IMAGE_WIDTH             = 800   ;
    parameter                    IMAGE_HEIGHT            = 480   ;

//PL使用DDR的基地址，留一定空间给PS用
    parameter                    DDR_BASE_ADDR           = 32'h1800000;

//*********************************
//Internal connect
//*********************************
  //clock
    wire                         ps2pl_clk50m_0           ;//系统时钟输入，50MHz
    wire                         ps2pl_resetn_0           ;//复位信号输入
    wire                         pll_locked               ;
    wire                         loc_clk50m               ;
    wire                         loc_clk100m              ;
    wire                         disp_clk                 ;
    wire                         disp_clk5x               ;
    wire                         reset                    ;
  //
    wire               [  15: 0] image_data               ;
    wire                         image_data_valid         ;
    wire                         image_data_hs            ;
    wire                         image_data_vs            ;
  //tft
    wire                         frame_begin              ;
    wire                         disp_data_req            ;
    wire               [  15: 0] disp_data                ;
  //VGA
    wire               [   4: 0] Disp_Red                 ;
    wire               [   5: 0] Disp_Green               ;
    wire               [   4: 0] Disp_Blue                ;
  //wr_fifo Interface
    wire                         wrfifo_clr_0             ;
    wire               [  15: 0] wrfifo_din_0             ;
    wire                         wrfifo_wren_0            ;
  //rd_fifo Interface
    wire                         rdfifo_clr_0             ;
    wire                         rdfifo_rden_0            ;
    wire               [  15: 0] rdfifo_dout_0            ;
  //axi
    wire               [   3: 0] s_axi_awid_0             ;
    wire               [  31: 0] s_axi_awaddr_0           ;
    wire               [   7: 0] s_axi_awlen_0            ;
    wire               [   2: 0] s_axi_awsize_0           ;
    wire               [   1: 0] s_axi_awburst_0          ;
    wire               [   0: 0] s_axi_awlock_0           ;
    wire               [   3: 0] s_axi_awcache_0          ;
    wire               [   2: 0] s_axi_awprot_0           ;
    wire               [   3: 0] s_axi_awqos_0            ;
    wire               [   3: 0] s_axi_awregion_0         ;
    wire                         s_axi_awvalid_0          ;
    wire                         s_axi_awready_0          ;
  //
    wire               [  63: 0] s_axi_wdata_0            ;
    wire               [   7: 0] s_axi_wstrb_0            ;
    wire                         s_axi_wlast_0            ;
    wire                         s_axi_wvalid_0           ;
    wire                         s_axi_wready_0           ;
  //
    wire               [   3: 0] s_axi_bid_0              ;
    wire               [   1: 0] s_axi_bresp_0            ;
    wire                         s_axi_bvalid_0           ;
    wire                         s_axi_bready_0           ;
  //
    wire               [   3: 0] s_axi_arid_0             ;
    wire               [  31: 0] s_axi_araddr_0           ;
    wire               [   7: 0] s_axi_arlen_0            ;
    wire               [   2: 0] s_axi_arsize_0           ;
    wire               [   1: 0] s_axi_arburst_0          ;
    wire               [   0: 0] s_axi_arlock_0           ;
    wire               [   3: 0] s_axi_arcache_0          ;
    wire               [   2: 0] s_axi_arprot_0           ;
    wire               [   3: 0] s_axi_arqos_0            ;
    wire               [   3: 0] s_axi_arregion_0         ;
    wire                         s_axi_arvalid_0          ;
    wire                         s_axi_arready_0          ;
  //
    wire               [   3: 0] s_axi_rid_0              ;
    wire               [  63: 0] s_axi_rdata_0            ;
    wire               [   1: 0] s_axi_rresp_0            ;
    wire                         s_axi_rlast_0            ;
    wire                         s_axi_rvalid_0           ;
    wire                         s_axi_rready_0           ;
  //
    wire                         s_axi_aclk               ;
    wire                         s_axi_resetn             ;
  //

  //wr_fifo Interface
    wire                         wrfifo_clr_1             ;
    wire               [  15: 0] wrfifo_din_1             ;
    wire                         wrfifo_wren_1            ;
  //rd_fifo Interface
    wire                         rdfifo_clr_1             ;
    wire                         rdfifo_rden_1            ;
    wire               [  15: 0] rdfifo_dout_1            ;
  //axi
    wire               [   3: 0] s_axi_awid_1             ;
    wire               [  31: 0] s_axi_awaddr_1           ;
    wire               [   7: 0] s_axi_awlen_1            ;
    wire               [   2: 0] s_axi_awsize_1           ;
    wire               [   1: 0] s_axi_awburst_1          ;
    wire               [   0: 0] s_axi_awlock_1           ;
    wire               [   3: 0] s_axi_awcache_1          ;
    wire               [   2: 0] s_axi_awprot_1           ;
    wire               [   3: 0] s_axi_awqos_1            ;
    wire               [   3: 0] s_axi_awregion_1         ;
    wire                         s_axi_awvalid_1          ;
    wire                         s_axi_awready_1          ;
  //
    wire               [  63: 0] s_axi_wdata_1            ;
    wire               [   7: 0] s_axi_wstrb_1            ;
    wire                         s_axi_wlast_1            ;
    wire                         s_axi_wvalid_1           ;
    wire                         s_axi_wready_1           ;
  //
    wire               [   3: 0] s_axi_bid_1              ;
    wire               [   1: 0] s_axi_bresp_1            ;
    wire                         s_axi_bvalid_1           ;
    wire                         s_axi_bready_1           ;
  //
    wire               [   3: 0] s_axi_arid_1             ;
    wire               [  31: 0] s_axi_araddr_1           ;
    wire               [   7: 0] s_axi_arlen_1            ;
    wire               [   2: 0] s_axi_arsize_1           ;
    wire               [   1: 0] s_axi_arburst_1          ;
    wire               [   0: 0] s_axi_arlock_1           ;
    wire               [   3: 0] s_axi_arcache_1          ;
    wire               [   2: 0] s_axi_arprot_1           ;
    wire               [   3: 0] s_axi_arqos_1            ;
    wire               [   3: 0] s_axi_arregion_1         ;
    wire                         s_axi_arvalid_1          ;
    wire                         s_axi_arready_1          ;
  //
    wire               [   3: 0] s_axi_rid_1              ;
    wire               [  63: 0] s_axi_rdata_1            ;
    wire               [   1: 0] s_axi_rresp_1            ;
    wire                         s_axi_rlast_1            ;
    wire                         s_axi_rvalid_1           ;
    wire                         s_axi_rready_1           ;
 

    wire               [   7: 0] uart_byte                ;
    wire                         uart_byte_vaild          ;

    assign                       loc_clk50m              = ps2pl_clk50m_0;
    assign                       s_axi_aclk              = loc_clk100m;


    wire                         pl_reset_n               ;
    wire                         reset_pre                ;
    reg                [  19: 0] reset_sync               ;
    assign                       pl_reset_n              = ps2pl_resetn_0;
    assign                       reset_pre               = ~pll_locked;
  
  //PS先释放复位，PL的逻辑复位释放往后延迟20个时钟周期
  always@(posedge loc_clk100m or posedge reset_pre)
  begin
    if(reset_pre)
      reset_sync <= {20{1'b1}};
    else
      reset_sync <= reset_sync << 1;
  end

    assign                       reset                   = reset_sync[19];
    assign                       s_axi_resetn            = ~reset;

  uart_byte_rx#(
    .CLK_FRQ                     (100_000_000             )
  )
  uart_byte_rx(
    .Clk                         (loc_clk100m             ),
    .Reset_n                     (!reset                  ),
    
    .Baud_Set                    (3'd5                    ),//1562500bps
    .uart_rx                     (uart_rx                 ),
    
    .Data                        (uart_byte               ),
    .Rx_Done                     (uart_byte_vaild         )
  );
  
  bit8_trans_bit16 bit8_trans_bit16
  (
    .clk                         (loc_clk100m             ),
    .reset_p                     (reset                   ),

    .bit8_in                     (uart_byte               ),
    .bit8_in_valid               (uart_byte_vaild         ),

    .bit16_out                   (image_data              ),
    .bit16_out_valid             (image_data_valid        )
  );

  pll pll
  (
    // Clock out ports
    .clk_out1                    (loc_clk100m             ),// output clk_out1
    .clk_out2                    (disp_clk                ),// output clk_out2
    .clk_out3                    (I2S_MCLK                ),// output clk_out3
    // Status and control signals
    .resetn                      (pl_reset_n              ),// input reset
    .locked                      (pll_locked              ),// output locked
    // Clock in ports
    .clk_in1                     (ps2pl_clk50m_0          ) // input clk_in1
  );

    wire               [  15: 0] buffer_data              ;
    wire                         buffer_data_valid        ;
    wire                         buffer_clr               ;
    wire               [  15: 0] background_data          ;
    wire                         background_req           ;

    assign                       wrfifo_clr_1            = reset || buffer_clr;
    assign                       wrfifo_wren_1           = buffer_data_valid;
    assign                       wrfifo_din_1            = buffer_data;

    assign                       rdfifo_clr_1            = reset|| frame_begin;
    assign                       rdfifo_rden_1           = disp_data_req;
    assign                       disp_data               = rdfifo_dout_1;

    assign                       wrfifo_clr_0            = reset;
    assign                       wrfifo_wren_0           = image_data_valid;
    assign                       wrfifo_din_0            = image_data;

    assign                       rdfifo_clr_0            = reset || buffer_clr;
    assign                       rdfifo_rden_0           = background_req;
    assign                       background_data         = rdfifo_dout_0;

    wire                         ram_fft_en               ;
    wire               [   9: 0] ram_fft_addr             ;
    wire               [  31: 0] ram_fft_dout             ;
    wire                         ram_audio_en             ;
    wire               [   9: 0] ram_audio_addr           ;
    wire               [  23: 0] ram_audio_dout           ;
    wire                         ram_fir_en               ;
    wire               [   9: 0] ram_fir_addr             ;
    wire               [  47: 0] ram_fir_dout             ;
    wire                         fft_done                 ;
    wire                         fifo_rst_busy            ;
    wire                         fifo_wren                ;

disp_buffer_updater u_disp_buffer_updater(
    .clk                         (disp_clk                ),
    .rst_n                       (~reset                  ),
    .background_data             (background_data         ),
    .background_req              (background_req          ),
    .ram_fft_en                  (ram_fft_en              ),
    .ram_fft_addr                (ram_fft_addr            ),
    .ram_fft_dout                (ram_fft_dout            ),
    .ram_audio_en                (ram_audio_en            ),
    .ram_audio_addr              (ram_audio_addr          ),
    .ram_audio_dout              (ram_audio_dout          ),
    .ram_fir_en                  (ram_fir_en              ),
    .ram_fir_addr                (ram_fir_addr            ),
    .ram_fir_dout                (ram_fir_dout            ),
    .buffer_data                 (buffer_data             ),
    .buffer_data_valid           (buffer_data_valid       ),
    .buffer_clr                  (buffer_clr              ),
    .update_start                (fft_done                ),
    .update_done                 (                        )
);

  //显示模块
  disp_driver #(
    .AHEAD_CLK_CNT               (1                       )
  )disp_driver(
    .ClkDisp                     (disp_clk                ),
    .Rst_n                       (~reset                  ),

    .Data                        (disp_data               ),
    .DataReq                     (disp_data_req           ),

    .H_Addr                      (                        ),
    .V_Addr                      (                        ),

    .Disp_HS                     (TFT_hs                  ),
    .Disp_VS                     (TFT_vs                  ),
    .Disp_Red                    (Disp_Red                ),
    .Disp_Green                  (Disp_Green              ),
    .Disp_Blue                   (Disp_Blue               ),
    .Disp_Sof                    (frame_begin             ),
    .Disp_DE                     (TFT_de                  ),
    .Disp_PCLK                   (TFT_clk                 )
  );
    assign                       TFT_rgb                 = {Disp_Red,Disp_Green,Disp_Blue};

    wire                         Key_P                    ;
    reg                [   1: 0] pwm_mod                  ;
    reg                [  20: 0] pwm_cnt                  ;
    parameter                    PWM_CNT                 = 500_000;
    parameter                    PWM_MOD_INIT            = 1     ;
    parameter                    PWM_MOD_1               = 0     ;
    parameter                    PWM_MOD_2               = PWM_CNT/2/2;
    parameter                    PWM_MOD_3               = PWM_CNT/2;
    parameter                    PWM_MOD_4               = PWM_CNT;
    
  always @(*)
  begin
    case (pwm_mod)
      0: TFT_pwm = pwm_cnt<=PWM_MOD_1 ? 1 : 0;
      1: TFT_pwm = pwm_cnt<=PWM_MOD_2 ? 1 : 0;
      2: TFT_pwm = pwm_cnt<=PWM_MOD_3 ? 1 : 0;
      3: TFT_pwm = pwm_cnt<=PWM_MOD_4 ? 1 : 0;
      default: TFT_pwm=0;
    endcase
  end
    
key u_key(
    .clk                         (loc_clk100m             ),
    .rst_n                       (pl_reset_n              ),
    .Key                         (key_pl                  ),
    .Key_P                       (Key_P                   ),
    .Key_R                       (                        )
);

always @(posedge loc_clk100m or negedge pl_reset_n)
begin
    if(!pl_reset_n)
      pwm_mod <= PWM_MOD_INIT;
    else if(Key_P == 1)
      pwm_mod <= pwm_mod+1;
    else
      pwm_mod <= pwm_mod;
end

always @(posedge loc_clk100m or negedge pl_reset_n)
begin
    if(!pl_reset_n)
      pwm_cnt <= 1;
    else if(pwm_cnt==PWM_CNT)
      pwm_cnt <= 1;
    else
      pwm_cnt <= pwm_cnt+1;
end


  fifo_axi4_adapter #(
    .FIFO_DW                     (16                      ),
    .WR_AXI_BYTE_ADDR_BEGIN      (DDR_BASE_ADDR           ),
    .WR_AXI_BYTE_ADDR_END        (DDR_BASE_ADDR  + IMAGE_WIDTH*IMAGE_HEIGHT*2 - 1),
    .RD_AXI_BYTE_ADDR_BEGIN      (DDR_BASE_ADDR           ),
    .RD_AXI_BYTE_ADDR_END        (DDR_BASE_ADDR + IMAGE_WIDTH*IMAGE_HEIGHT*2 - 1),

    .AXI_DATA_WIDTH              (64                      ),
    .AXI_ADDR_WIDTH              (32                      ),
    .AXI_ID                      (4'b0000                 ),
    .AXI_BURST_LEN               (8'd15                   ),//axi burst length = 16
    .FIFO_ADDR_DEPTH             (64                      )
  )fifo_axi4_adapter_inst_0
  (
    //clock reset
    .clk                         (loc_clk100m             ),
    .reset                       (reset                   ),
    //wr_fifo Interface
    .wrfifo_clr                  (wrfifo_clr_0            ),
    .wrfifo_clk                  (loc_clk100m             ),
    .wrfifo_wren                 (wrfifo_wren_0           ),
    .wrfifo_din                  (wrfifo_din_0            ),
    .wrfifo_full                 (                        ),
    .wrfifo_wr_cnt               (                        ),
    //rd_fifo Interface
    .rdfifo_clr                  (rdfifo_clr_0            ),
    .rdfifo_clk                  (disp_clk                ),
    .rdfifo_rden                 (rdfifo_rden_0           ),
    .rdfifo_dout                 (rdfifo_dout_0           ),
    .rdfifo_empty                (                        ),
    .rdfifo_rd_cnt               (                        ),
    // Master Interface Write Address Ports
    .m_axi_awid                  (s_axi_awid_0            ),
    .m_axi_awaddr                (s_axi_awaddr_0          ),
    .m_axi_awlen                 (s_axi_awlen_0           ),
    .m_axi_awsize                (s_axi_awsize_0          ),
    .m_axi_awburst               (s_axi_awburst_0         ),
    .m_axi_awlock                (s_axi_awlock_0          ),
    .m_axi_awcache               (s_axi_awcache_0         ),
    .m_axi_awprot                (s_axi_awprot_0          ),
    .m_axi_awqos                 (s_axi_awqos_0           ),
    .m_axi_awregion              (s_axi_awregion_0        ),
    .m_axi_awvalid               (s_axi_awvalid_0         ),
    .m_axi_awready               (s_axi_awready_0         ),
    // Master Interface Write Data Ports
    .m_axi_wdata                 (s_axi_wdata_0           ),
    .m_axi_wstrb                 (s_axi_wstrb_0           ),
    .m_axi_wlast                 (s_axi_wlast_0           ),
    .m_axi_wvalid                (s_axi_wvalid_0          ),
    .m_axi_wready                (s_axi_wready_0          ),
    // Master Interface Write Response Ports
    .m_axi_bid                   (4'b0000                 ),
    .m_axi_bresp                 (s_axi_bresp_0           ),
    .m_axi_bvalid                (s_axi_bvalid_0          ),
    .m_axi_bready                (s_axi_bready_0          ),
    // Master Interface Read Address Ports
    .m_axi_arid                  (s_axi_arid_0            ),
    .m_axi_araddr                (s_axi_araddr_0          ),
    .m_axi_arlen                 (s_axi_arlen_0           ),
    .m_axi_arsize                (s_axi_arsize_0          ),
    .m_axi_arburst               (s_axi_arburst_0         ),
    .m_axi_arlock                (s_axi_arlock_0          ),
    .m_axi_arcache               (s_axi_arcache_0         ),
    .m_axi_arprot                (s_axi_arprot_0          ),
    .m_axi_arqos                 (s_axi_arqos_0           ),
    .m_axi_arregion              (s_axi_arregion_0        ),
    .m_axi_arvalid               (s_axi_arvalid_0         ),
    .m_axi_arready               (s_axi_arready_0         ),
    // Master Interface Read Data Ports
    .m_axi_rid                   (4'b0000                 ),
    .m_axi_rdata                 (s_axi_rdata_0           ),
    .m_axi_rresp                 (s_axi_rresp_0           ),
    .m_axi_rlast                 (s_axi_rlast_0           ),
    .m_axi_rvalid                (s_axi_rvalid_0          ),
    .m_axi_rready                (s_axi_rready_0          )
  );


  fifo_axi4_adapter #(
    .FIFO_DW                     (16                      ),
    .WR_AXI_BYTE_ADDR_BEGIN      (DDR_BASE_ADDR + 1024 + IMAGE_WIDTH*IMAGE_HEIGHT*2),
    .WR_AXI_BYTE_ADDR_END        (DDR_BASE_ADDR + 1024 + IMAGE_WIDTH*IMAGE_HEIGHT*4 - 1),
    .RD_AXI_BYTE_ADDR_BEGIN      (DDR_BASE_ADDR + 1024 + IMAGE_WIDTH*IMAGE_HEIGHT*2),
    .RD_AXI_BYTE_ADDR_END        (DDR_BASE_ADDR + 1024 + IMAGE_WIDTH*IMAGE_HEIGHT*4 - 1),

    .AXI_DATA_WIDTH              (64                      ),
    .AXI_ADDR_WIDTH              (32                      ),
    .AXI_ID                      (4'b0001                 ),
    .AXI_BURST_LEN               (8'd15                   ),//axi burst length = 16
    .FIFO_ADDR_DEPTH             (64                      )
  )fifo_axi4_adapter_inst_1
  (
    //clock reset
    .clk                         (loc_clk100m             ),
    .reset                       (reset                   ),
    //wr_fifo Interface
    .wrfifo_clr                  (wrfifo_clr_1            ),
    .wrfifo_clk                  (disp_clk                ),
    .wrfifo_wren                 (wrfifo_wren_1           ),
    .wrfifo_din                  (wrfifo_din_1            ),
    .wrfifo_full                 (                        ),
    .wrfifo_wr_cnt               (                        ),
    //rd_fifo Interface
    .rdfifo_clr                  (rdfifo_clr_1            ),
    .rdfifo_clk                  (disp_clk                ),
    .rdfifo_rden                 (rdfifo_rden_1           ),
    .rdfifo_dout                 (rdfifo_dout_1           ),
    .rdfifo_empty                (                        ),
    .rdfifo_rd_cnt               (                        ),
    // Master Interface Write Address Ports
    .m_axi_awid                  (s_axi_awid_1            ),
    .m_axi_awaddr                (s_axi_awaddr_1          ),
    .m_axi_awlen                 (s_axi_awlen_1           ),
    .m_axi_awsize                (s_axi_awsize_1          ),
    .m_axi_awburst               (s_axi_awburst_1         ),
    .m_axi_awlock                (s_axi_awlock_1          ),
    .m_axi_awcache               (s_axi_awcache_1         ),
    .m_axi_awprot                (s_axi_awprot_1          ),
    .m_axi_awqos                 (s_axi_awqos_1           ),
    .m_axi_awregion              (s_axi_awregion_1        ),
    .m_axi_awvalid               (s_axi_awvalid_1         ),
    .m_axi_awready               (s_axi_awready_1         ),
    // Master Interface Write Data Ports
    .m_axi_wdata                 (s_axi_wdata_1           ),
    .m_axi_wstrb                 (s_axi_wstrb_1           ),
    .m_axi_wlast                 (s_axi_wlast_1           ),
    .m_axi_wvalid                (s_axi_wvalid_1          ),
    .m_axi_wready                (s_axi_wready_1          ),
    // Master Interface Write Response Ports
    .m_axi_bid                   (4'b0001                 ),
    .m_axi_bresp                 (s_axi_bresp_1           ),
    .m_axi_bvalid                (s_axi_bvalid_1          ),
    .m_axi_bready                (s_axi_bready_1          ),
    // Master Interface Read Address Ports
    .m_axi_arid                  (s_axi_arid_1            ),
    .m_axi_araddr                (s_axi_araddr_1          ),
    .m_axi_arlen                 (s_axi_arlen_1           ),
    .m_axi_arsize                (s_axi_arsize_1          ),
    .m_axi_arburst               (s_axi_arburst_1         ),
    .m_axi_arlock                (s_axi_arlock_1          ),
    .m_axi_arcache               (s_axi_arcache_1         ),
    .m_axi_arprot                (s_axi_arprot_1          ),
    .m_axi_arqos                 (s_axi_arqos_1           ),
    .m_axi_arregion              (s_axi_arregion_1        ),
    .m_axi_arvalid               (s_axi_arvalid_1         ),
    .m_axi_arready               (s_axi_arready_1         ),
    // Master Interface Read Data Ports
    .m_axi_rid                   (4'b0001                 ),
    .m_axi_rdata                 (s_axi_rdata_1           ),
    .m_axi_rresp                 (s_axi_rresp_1           ),
    .m_axi_rlast                 (s_axi_rlast_1           ),
    .m_axi_rvalid                (s_axi_rvalid_1          ),
    .m_axi_rready                (s_axi_rready_1          )
  );


  system_wrapper system_wrapper
  (
    .DDR_addr                    (ddr3_addr               ),
    .DDR_ba                      (ddr3_ba                 ),
    .DDR_cas_n                   (ddr3_cas_n              ),
    .DDR_ck_n                    (ddr3_ck_n               ),
    .DDR_ck_p                    (ddr3_ck_p               ),
    .DDR_cke                     (ddr3_cke                ),

    .DDR_cs_n                    (ddr3_cs_n               ),
    .DDR_dm                      (ddr3_dm                 ),
    .DDR_dq                      (ddr3_dq                 ),
    .DDR_dqs_n                   (ddr3_dqs_n              ),
    .DDR_dqs_p                   (ddr3_dqs_p              ),
    .DDR_odt                     (ddr3_odt                ),
    .DDR_ras_n                   (ddr3_ras_n              ),
    .DDR_reset_n                 (ddr3_reset_n            ),
    .DDR_we_n                    (ddr3_we_n               ),
    .FIXED_IO_ddr_vrn            (FIXED_IO_ddr_vrn        ),
    .FIXED_IO_ddr_vrp            (FIXED_IO_ddr_vrp        ),
    .FIXED_IO_mio                (FIXED_IO_mio            ),
    .FIXED_IO_ps_clk             (FIXED_IO_ps_clk         ),
    .FIXED_IO_ps_porb            (FIXED_IO_ps_porb        ),
    .FIXED_IO_ps_srstb           (FIXED_IO_ps_srstb       ),

    //Slave Interface Read Address Ports
    .pl2ps_axi_0_araddr          (s_axi_araddr_0          ),
    .pl2ps_axi_0_arburst         (s_axi_arburst_0         ),
    .pl2ps_axi_0_arcache         (s_axi_arcache_0         ),
    .pl2ps_axi_0_arlen           (s_axi_arlen_0           ),
    .pl2ps_axi_0_arlock          (s_axi_arlock_0          ),
    .pl2ps_axi_0_arprot          (s_axi_arprot_0          ),
    .pl2ps_axi_0_arqos           (s_axi_arqos_0           ),
//    .pl2ps_axi_0_arregion(s_axi_arregion_0      ),
    .pl2ps_axi_0_arready         (s_axi_arready_0         ),
    .pl2ps_axi_0_arsize          (s_axi_arsize_0          ),
    .pl2ps_axi_0_arvalid         (s_axi_arvalid_0         ),
    //Slave Interface Write Address Ports
    .pl2ps_axi_0_awaddr          (s_axi_awaddr_0          ),
    .pl2ps_axi_0_awburst         (s_axi_awburst_0         ),
    .pl2ps_axi_0_awcache         (s_axi_awcache_0         ),
    .pl2ps_axi_0_awlen           (s_axi_awlen_0           ),
    .pl2ps_axi_0_awlock          (s_axi_awlock_0          ),
    .pl2ps_axi_0_awprot          (s_axi_awprot_0          ),
    .pl2ps_axi_0_awqos           (s_axi_awqos_0           ),
//    .pl2ps_axi_0_awregion(s_axi_awregion_0      ),
    .pl2ps_axi_0_awready         (s_axi_awready_0         ),
    .pl2ps_axi_0_awsize          (s_axi_awsize_0          ),
    .pl2ps_axi_0_awvalid         (s_axi_awvalid_0         ),
    //Slave Interface Write Response Ports
    .pl2ps_axi_0_bready          (s_axi_bready_0          ),
    .pl2ps_axi_0_bresp           (s_axi_bresp_0           ),
    .pl2ps_axi_0_bvalid          (s_axi_bvalid_0          ),
    //Slave Interface Read Data Ports
    .pl2ps_axi_0_rdata           (s_axi_rdata_0           ),
    .pl2ps_axi_0_rlast           (s_axi_rlast_0           ),
    .pl2ps_axi_0_rready          (s_axi_rready_0          ),
    .pl2ps_axi_0_rresp           (s_axi_rresp_0           ),
    .pl2ps_axi_0_rvalid          (s_axi_rvalid_0          ),
    //Slave Interface Write Data Ports
    .pl2ps_axi_0_wdata           (s_axi_wdata_0           ),
    .pl2ps_axi_0_wlast           (s_axi_wlast_0           ),
    .pl2ps_axi_0_wready          (s_axi_wready_0          ),
    .pl2ps_axi_0_wstrb           (s_axi_wstrb_0           ),
    .pl2ps_axi_0_wvalid          (s_axi_wvalid_0          ),

    //Slave Interface Read Address Ports
    .pl2ps_axi_1_araddr          (s_axi_araddr_1          ),
    .pl2ps_axi_1_arburst         (s_axi_arburst_1         ),
    .pl2ps_axi_1_arcache         (s_axi_arcache_1         ),
    .pl2ps_axi_1_arlen           (s_axi_arlen_1           ),
    .pl2ps_axi_1_arlock          (s_axi_arlock_1          ),
    .pl2ps_axi_1_arprot          (s_axi_arprot_1          ),
    .pl2ps_axi_1_arqos           (s_axi_arqos_1           ),
//    .pl2ps_axi_1_arregion(s_axi_arregion_1      ),
    .pl2ps_axi_1_arready         (s_axi_arready_1         ),
    .pl2ps_axi_1_arsize          (s_axi_arsize_1          ),
    .pl2ps_axi_1_arvalid         (s_axi_arvalid_1         ),
    //Slave Interface Write Address Ports
    .pl2ps_axi_1_awaddr          (s_axi_awaddr_1          ),
    .pl2ps_axi_1_awburst         (s_axi_awburst_1         ),
    .pl2ps_axi_1_awcache         (s_axi_awcache_1         ),
    .pl2ps_axi_1_awlen           (s_axi_awlen_1           ),
    .pl2ps_axi_1_awlock          (s_axi_awlock_1          ),
    .pl2ps_axi_1_awprot          (s_axi_awprot_1          ),
    .pl2ps_axi_1_awqos           (s_axi_awqos_1           ),
//    .pl2ps_axi_1_awregion(s_axi_awregion_1      ),
    .pl2ps_axi_1_awready         (s_axi_awready_1         ),
    .pl2ps_axi_1_awsize          (s_axi_awsize_1          ),
    .pl2ps_axi_1_awvalid         (s_axi_awvalid_1         ),
    //Slave Interface Write Response Ports
    .pl2ps_axi_1_bready          (s_axi_bready_1          ),
    .pl2ps_axi_1_bresp           (s_axi_bresp_1           ),
    .pl2ps_axi_1_bvalid          (s_axi_bvalid_1          ),
    //Slave Interface Read Data Ports
    .pl2ps_axi_1_rdata           (s_axi_rdata_1           ),
    .pl2ps_axi_1_rlast           (s_axi_rlast_1           ),
    .pl2ps_axi_1_rready          (s_axi_rready_1          ),
    .pl2ps_axi_1_rresp           (s_axi_rresp_1           ),
    .pl2ps_axi_1_rvalid          (s_axi_rvalid_1          ),
    //Slave Interface Write Data Ports
    .pl2ps_axi_1_wdata           (s_axi_wdata_1           ),
    .pl2ps_axi_1_wlast           (s_axi_wlast_1           ),
    .pl2ps_axi_1_wready          (s_axi_wready_1          ),
    .pl2ps_axi_1_wstrb           (s_axi_wstrb_1           ),
    .pl2ps_axi_1_wvalid          (s_axi_wvalid_1          ),

    //Slave Interface ACLK RESET
    .pl2ps_axi_aclk_0            (s_axi_aclk              ),
    .pl2ps_axi_resetn_0          (s_axi_resetn            ),

    .ps2pl_clk50m_0              (ps2pl_clk50m_0          ),
    .ps2pl_resetn_0              (ps2pl_resetn_0          )
  );
  


  
  reg [26:0]cnt;
  reg Go_WM8960;
  reg Go_SiI9022;
    
  always@(posedge ps2pl_clk50m_0 or negedge ps2pl_resetn_0)
  if(!ps2pl_resetn_0)
      cnt <= 0;
  else if(cnt == 999999+50000000)
      cnt <= 999999+1;
  else
      cnt <= cnt + 1 ;
       
  always@(posedge ps2pl_clk50m_0 or negedge ps2pl_resetn_0)begin
    if(!ps2pl_resetn_0)begin
      Go_WM8960 <= 0;
      Go_SiI9022<=0;
    end
    else if(cnt == 499999)
      Go_SiI9022 <= 1'b1;
    else if(cnt == 999999)
       Go_WM8960<= 1'b1;
    else begin
      Go_WM8960 <= 0;
      Go_SiI9022 <=0;
    end
  end

  
    wire                         SiI9022_Init_Done        ;
    wire                         SiI9022_sclk             ;
    wire                         SiI9022_sdat             ;
    wire                         WM8960_Init_Done         ;
    wire                         WM8960_sclk              ;
    wire                         WM8960_sdat              ;
    assign                       led                     = WM8960_Init_Done&&SiI9022_Init_Done ? (cnt<26000000 ? 1:0):0;

    assign                       sdat                    = cnt < 999999 ? SiI9022_sdat:WM8960_sdat;
    assign                       sclk                    = cnt < 999999 ? SiI9022_sclk:WM8960_sclk;

  SiI9022_Init SiI9022_Init(
    .Clk                         (ps2pl_clk50m_0          ),
    .Rst_n                       (ps2pl_resetn_0          ),
        
    .Go                          (Go_SiI9022              ),
    .device_id                   (8'h72                   ),
    .Init_Done                   (SiI9022_Init_Done       ),
        
    .i2c_sclk                    (SiI9022_sclk            ),
    .i2c_sdat                    (SiI9022_sdat            )
  );

  WM8960_Init WM8960_Init(
    .Clk                         (ps2pl_clk50m_0          ),
    .Rst_n                       (ps2pl_resetn_0          ),
        
    .Go                          (Go_WM8960               ),
    .device_id                   (8'h34                   ),
    .Init_Done                   (WM8960_Init_Done        ),
        
    .i2c_sclk                    (WM8960_sclk             ),
    .i2c_sdat                    (WM8960_sdat             )
  );

    wire               [  23: 0] adc_data                 ;
    wire                         l_rcv_done               ;

audio_rcv u_audio_rcv(
    .audio_bclk                  (I2S_BCLK                ),// WM8960输出的位时钟
    .sys_rst_n                   (WM8960_Init_Done        ),// 系统复位，低有效
    .audio_lrc                   (I2S_ADCLRC              ),// WM8960输出的数据左/右对齐时钟
    .audio_adcdat                (I2S_ADCDAT              ),// WM8960ADC数据输出
    .adc_data                    (adc_data                ),// 一次接收的数据
    .l_rcv_done                  (l_rcv_done              ),// 左声道一次数据接收完成
    .r_rcv_done                  (                        ) // 右声道一次数据接收完成
);

    assign                       fifo_wren               = l_rcv_done&&!fifo_full&&!fifo_rst_busy;

FFT_control u_FFT_control(
    .rst_n                       (!reset                  ),
    .fft_clk                     (loc_clk100m             ),
    .fft_done                    (fft_done                ),
    .ram_fft_clk                 (disp_clk                ),
    .ram_fft_en                  (ram_fft_en              ),
    .ram_fft_addr                (ram_fft_addr            ),
    .ram_fft_dout                (ram_fft_dout            ),
    .ram_audio_clk               (disp_clk                ),
    .ram_audio_en                (ram_audio_en            ),
    .ram_audio_addr              (ram_audio_addr          ),
    .ram_audio_dout              (ram_audio_dout          ),
    .ram_fir_clk                 (disp_clk                ),
    .ram_fir_en                  (ram_fir_en              ),
    .ram_fir_addr                (ram_fir_addr            ),
    .ram_fir_dout                (ram_fir_dout            ),
    .fifo_clr                    (!WM8960_Init_Done       ),
    .fifo_clk                    (I2S_BCLK                ),
    .fifo_wren                   (fifo_wren               ),
    .fifo_din                    (adc_data                ),
    .fifo_full                   (fifo_full               ),
    .fifo_empty                  (                        ),
    .fifo_rst_busy               (fifo_rst_busy           )
);

ila_adc ila_adc (
    .clk                         (ps2pl_clk50m_0          ),// input wire clk
    .probe0                      (l_rcv_done              ),// input wire [0:0]  probe0
    .probe1                      (adc_data                ) // input wire [23:0]  probe1
);


endmodule

