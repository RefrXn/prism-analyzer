// ===============================================================
// - 输入: 16-bit PCM 串流 (pcm_in_valid, pcm_in_sample)
// - 输出: 32 路频带值 (通过 spectrum_out_ram 读口导出)
// ===============================================================
module top_fft #(
    parameter                             PCM_WIDTH           = 16       ,
    parameter                             FFT_LEN             = 1024     ,      
    parameter                             FFT_RE_IM_WIDTH     = 16       ,      // FFT IP 的实虚位宽(每路)
    parameter                             MAG_WIDTH           = 16       ,      // 幅度位宽（内部）
    parameter                             BANDS               = 32       ,      // 目标频带数
    parameter                             PEAK_HOLD_FRAMES    = 3                         // 峰值保持帧数
)(
    input  wire                            clk_50m            ,
    input  wire                            rst_n              ,
        
    // PCM 输入（采样时序：48kHz，有效时拉高1拍即可）
    input  wire                            pcm_in_valid       ,
    input  wire signed [PCM_WIDTH-1:0]     pcm_in_sample      ,

    // 频谱读口（给后续 WS2812 模块或调试）
    input  wire [clog2_fn(BANDS)-1:0]      spec_rd_addr       ,
    input  wire                            spec_rd_en         ,
    output wire [15:0]                     spec_rd_data       ,      // 压缩后输出 16bit
    output wire                            spec_frame_stb     ,      // 每帧（更新完 32 band）打一拍
    output wire                            spec_rd_data_valid
);

    // 1) PCM -> AXIS (complex), 帧打包
    wire                                   s_axis_tvalid      ;
    wire                                   s_axis_tready      ;
    wire [2*FFT_RE_IM_WIDTH-1:0]           s_axis_tdata       ;      // {Re, Im}
    wire                                   s_axis_tlast       ;

    frame_packer #(
        .PCM_WIDTH                         (PCM_WIDTH       )  ,
        .FFT_LEN                           (FFT_LEN         )  ,
        .FFT_RE_IM_WIDTH                   (FFT_RE_IM_WIDTH )
    ) u_frame_packer (
        .clk_50m                           (clk_50m         )  ,
        .rst_n                             (rst_n           )  ,
        .pcm_in_valid                      (pcm_in_valid    )  ,
        .pcm_in_sample                     (pcm_in_sample   )  ,
        .s_axis_tvalid                     (s_axis_tvalid   )  ,
        .s_axis_tready                     (s_axis_tready   )  ,
        .s_axis_tdata                      (s_axis_tdata    )  ,
        .s_axis_tlast                      (s_axis_tlast    )
    );


    // 2) FFT IP 包装 (AXIS in/out)
    wire                                   m_axis_tvalid       ;
    wire                                   m_axis_tready       ;
    wire [2*FFT_RE_IM_WIDTH-1:0]           m_axis_tdata        ;      // {Re, Im}
    wire                                   m_axis_tlast        ;

    fft_wrapper #(
        .FFT_LEN                           (FFT_LEN         )  ,
        .FFT_RE_IM_WIDTH                   (FFT_RE_IM_WIDTH )
    ) u_fft_wrapper (
        // Clock & Reset
        .clk_50m                           (clk_50m         )  ,
        .rst_n                             (rst_n           )  ,
        // S_AXIS (input)
        .s_axis_tvalid                     (s_axis_tvalid   )  ,
        .s_axis_tready                     (s_axis_tready   )  ,
        .s_axis_tdata                      (s_axis_tdata    )  ,
        .s_axis_tlast                      (s_axis_tlast    )  ,
        // M_AXIS (output)
        .m_axis_tvalid                     (m_axis_tvalid   )  ,
        .m_axis_tready                     (m_axis_tready   )  ,
        .m_axis_tdata                      (m_axis_tdata    )  ,
        .m_axis_tlast                      (m_axis_tlast    )
    );


    // 3) 复数 -> 幅度（近似）
    wire                                   mag_tvalid          ;
    wire                                   mag_tready          ;
    wire [MAG_WIDTH-1:0]                   mag_tdata           ;
    wire                                   mag_tlast           ;
    
    assign spec_frame_stb = mag_tlast; // 输出最后一个幅度时update

    complex_to_mag #(
        .RE_IM_WIDTH                       (FFT_RE_IM_WIDTH )  ,
        .MAG_WIDTH                         (MAG_WIDTH       )
    ) u_complex_to_mag (
        // Clock & Reset
        .clk_50m                           (clk_50m         )  ,
        .rst_n                             (rst_n           )  ,
        // S_AXIS (input)
        .s_axis_tvalid                     (m_axis_tvalid   )  ,
        .s_axis_tready                     (m_axis_tready   )  ,
        .s_axis_tdata                      (m_axis_tdata    )  ,  // {Re, Im}
        .s_axis_tlast                      (m_axis_tlast    )  ,
        // M_AXIS (output)
        .m_axis_tvalid                     (mag_tvalid      )  ,
        .m_axis_tready                     (mag_tready      )  ,
        .m_axis_tdata                      (mag_tdata       )  ,
        .m_axis_tlast                      (mag_tlast       )
    );
    
    
    // 4) 频带汇聚 (N/2 -> 32 bands), 线性平均
    //    此处忽略 DC(0) 与 Nyquist(N/2)
    wire                                   band_tvalid         ;
    wire                                   band_tready         ;
    wire [15:0]                            band_tdata          ;   // 先截成16位，后面再做压缩/峰值保持
    wire                                   band_tlast          ;   // 每输出一个 band，打一次 valid；最后一个 band 打 tlast，不是一个band打一次

    band_accum #(
        .FFT_LEN                           (FFT_LEN         )  ,
        .BANDS                             (BANDS           )  ,
        .IN_WIDTH                          (MAG_WIDTH       )  ,
        .OUT_WIDTH                         (16              )
    ) u_band_accum (
        // Clock & Reset
        .clk_50m                           (clk_50m         )  ,
        .rst_n                             (rst_n           )  ,
        // S_AXIS (input)
        .s_axis_tvalid                     (mag_tvalid      )  ,
        .s_axis_tready                     (mag_tready      )  ,
        .s_axis_tdata                      (mag_tdata       )  ,
        .s_axis_tlast                      (mag_tlast       )  ,
        // M_AXIS (output)
        .m_axis_tvalid                     (band_tvalid     )  ,
        .m_axis_tready                     (band_tready     )  ,
        .m_axis_tdata                      (band_tdata      )  ,
        .m_axis_tlast                      (band_tlast      )
    );


    // 5) 峰值保持 + 粗略压缩（log2近似）
    wire                                   comp_tready                   ;
    wire                                   comp_tvalid = band_tvalid     ;
    wire [15:0]                            comp_tdata = band_tdata       ;
    wire                                   comp_tlast = band_tlast       ;
    
    assign                                 band_tready = comp_tready     ;


    // 6) 写入 32×16 RAM，供外部读
    band_buffer #(
        .BANDS                             (BANDS           )  ,
        .DATA_WIDTH                        (16              )
    ) u_band_buffer (
        // Clock & Reset
        .clk_50m                           (clk_50m         )  ,
        .rst_n                             (rst_n           )  ,
    
        // 写：来自 comp 流，每帧依次写 0..BANDS-1
        .s_axis_tvalid                     (comp_tvalid     )  ,
        .s_axis_tready                     (comp_tready     )  ,
        .s_axis_tdata                      (comp_tdata      )  ,
        .s_axis_tlast                      (comp_tlast      )  ,
    
        // 读：异步一拍返回
        .rd_addr                           (spec_rd_addr    )  ,
        .rd_en                             (spec_rd_en      )  ,
        .rd_data                           (spec_rd_data    )  ,
        .frame_stb                         (                )  ,  // 此信号在 FFT 半帧时输出，不能用，应改用 mag_tlast, 之前踩过坑
        .rd_data_valid                     (spec_rd_data_valid)
    );

    
    // 7）近似函数，也可以用CORDIC，但是有延迟
    function   integer clog2_fn ;
        input  integer v        ;
               integer i        ;
        begin
            v = v - 1            ;
            for (i = 0; v > 0; i = i + 1)
                v = v >> 1       ;
            clog2_fn = i         ;
        end
    endfunction


endmodule
