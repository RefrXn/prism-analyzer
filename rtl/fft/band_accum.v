module band_accum #(
    parameter integer FFT_LEN   = 1024,  // FFT 点数（必须是 2 的幂）
    parameter integer BANDS     = 32,    // 输出频带数
    parameter integer IN_WIDTH  = 24,    // 输入幅度位宽
    parameter integer OUT_WIDTH = 16     // 输出幅度位宽
) (
    input  wire                     clk_50m,
    input  wire                     rst_n,

    // 输入：每帧 N 点的幅度（与 FFT 输出对齐），只统计 [0 .. N/2-1] 共 N/2 点
    // NOTE: FFT 输出的 DC 分量在 tdata[0] 将被忽略
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire [IN_WIDTH-1:0]      s_axis_tdata,
    input  wire                     s_axis_tlast,

    // 输出：每帧产生 BANDS 个值（线性求和后截位），最后一个打 tlast
    output reg                      m_axis_tvalid,
    input  wire                     m_axis_tready,
    output      [OUT_WIDTH-1:0]     m_axis_tdata,
    output reg                      m_axis_tlast
);

    // ===============================================================
    // 1) 参数与局部常量
    // ===============================================================
    localparam integer HALF_N       = FFT_LEN / 2;
    localparam integer BAND_SAMPLES = HALF_N / BANDS;

    // ===============================================================
    // 2) 寄存器定义
    // ===============================================================
    reg [$clog2(BAND_SAMPLES):0]            band_sample_idx;  // 当前 band 内采样点索引
    reg [$clog2(BANDS):0]                   band_idx;         // 当前累加到第几个 band
    reg [IN_WIDTH+$clog2(BAND_SAMPLES)-1:0] acc, acc_r;       // 累加器
    reg                                     frame_done;

    // 输出截位映射
    assign m_axis_tdata = acc_r[IN_WIDTH+$clog2(BAND_SAMPLES)-1-:OUT_WIDTH];

    // 上游 ready 控制
    assign s_axis_tready = (!m_axis_tvalid) || m_axis_tready;

    // ===============================================================
    // 3) 主时序逻辑
    // ===============================================================
    always @(posedge clk_50m) begin
        if (!rst_n) begin
            band_sample_idx <= 0;
            band_idx        <= 0;
            acc             <= 0;
            acc_r           <= 0;
            m_axis_tvalid   <= 0;
            m_axis_tlast    <= 0;
            frame_done      <= 0;
        end
        else begin
            // -------------------------------------------------------
            // 下游握手后清 valid
            // -------------------------------------------------------
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end

            // -------------------------------------------------------
            // 输入处理
            // -------------------------------------------------------
            if (s_axis_tvalid && s_axis_tready) begin
                if (!frame_done) begin
                    // =======================
                    // 当前 band 采样累加
                    // =======================
                    if (band_sample_idx == BAND_SAMPLES - 1) begin
                        // 当前 band 累加完成，输出结果
                        acc             <= 'b0;
                        acc_r           <= acc + s_axis_tdata;
                        m_axis_tvalid   <= 1'b1;
                        m_axis_tlast    <= (band_idx == BANDS - 1) ? 1'b1 : 1'b0;
                        band_sample_idx <= 0;
                        band_idx        <= band_idx + 1;
                        frame_done      <= (band_idx == BANDS - 1) ? 1'b1 : 1'b0;
                    end
                    else begin
                        // 继续累加当前 band
                        acc             <= (band_sample_idx == 0 && band_idx == 0) ?
                                            s_axis_tdata : acc + s_axis_tdata;
                        band_sample_idx <= band_sample_idx + 1;
                    end
                end
                else begin
                    // =======================
                    // 帧结束复位状态
                    // =======================
                    if (s_axis_tlast) begin
                        band_sample_idx <= 'b0;
                        band_idx        <= 'b0;
                        acc             <= 'b0;
                        frame_done      <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
