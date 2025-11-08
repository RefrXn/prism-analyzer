module fft_wrapper #(
    parameter integer FFT_LEN = 1024,
    parameter integer FFT_RE_IM_WIDTH = 24
)(
    input  wire                        clk_50m,
    input  wire                        rst_n,  // 外部低有效复位

    // S_AXIS data in
    input  wire                        s_axis_tvalid,
    output wire                        s_axis_tready,
    input  wire [2*FFT_RE_IM_WIDTH-1:0] s_axis_tdata, // {Re,Im}
    input  wire                        s_axis_tlast,

    // M_AXIS data out
    output wire                        m_axis_tvalid,
    input  wire                        m_axis_tready,
    output wire [2*FFT_RE_IM_WIDTH-1:0] m_axis_tdata, // {Re,Im}
    output wire                        m_axis_tlast
);

    // ===============================================
    // CONFIG 通道：一次性发送配置（forward FFT）
    // ===============================================
    reg cfg_sent;
    reg cfg_tvalid;
    wire cfg_tready;
    wire [7:0] cfg_tdata = 8'h01; // bit0=1 → forward FFT

    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            cfg_sent   <= 1'b0;
            cfg_tvalid <= 1'b0;
        end else begin
            if (!cfg_sent) begin
                cfg_tvalid <= 1'b1;
                if (cfg_tvalid && cfg_tready) begin
                    cfg_sent   <= 1'b1;
                    cfg_tvalid <= 1'b0;
                end
            end
        end
    end

    // ===============================================
    // Status / Event 端口定义
    // ===============================================
    wire [7:0] m_axis_status_tdata;
    wire       m_axis_status_tvalid;
    wire       m_axis_status_tready;
    wire       event_frame_started;
    wire       event_tlast_unexpected;
    wire       event_tlast_missing;
    wire       event_status_channel_halt;
    wire       event_data_in_channel_halt;
    wire       event_data_out_channel_halt;

    // // 必须拉高 tready，否则会出现 LUT 未连接告警
    // assign m_axis_status_tready = 1'b1;

    // ===============================================
    // FFT IP 实例
    // ===============================================

    xfft_0 u_xfft (
        .aclk                      (clk_50m),
        .aresetn                   (rst_n),

        // Config 通道
        .s_axis_config_tdata       (cfg_tdata),
        .s_axis_config_tvalid      (cfg_tvalid),
        .s_axis_config_tready      (cfg_tready),

        // Data 输入
        .s_axis_data_tdata         (s_axis_tdata),
        .s_axis_data_tvalid        (s_axis_tvalid),
        .s_axis_data_tready        (s_axis_tready),
        .s_axis_data_tlast         (s_axis_tlast),

        // Data 输出
        .m_axis_data_tdata         (m_axis_tdata),
        .m_axis_data_tvalid        (m_axis_tvalid),
        .m_axis_data_tready        (m_axis_tready),
        .m_axis_data_tlast         (m_axis_tlast),

        // Events
        .event_frame_started       (event_frame_started),
        .event_tlast_unexpected    (event_tlast_unexpected),
        .event_tlast_missing       (event_tlast_missing),
        .event_status_channel_halt (event_status_channel_halt),
        .event_data_in_channel_halt(event_data_in_channel_halt),
        .event_data_out_channel_halt(event_data_out_channel_halt)
    );

endmodule
