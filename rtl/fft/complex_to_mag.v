module complex_to_mag #(
    parameter integer RE_IM_WIDTH = 24,
    parameter integer MAG_WIDTH   = 24
) (
    input  wire                     clk_50m,
    input  wire                     rst_n,

    // AXIS in: {Re,Im}
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire [2*RE_IM_WIDTH-1:0] s_axis_tdata,
    input  wire                     s_axis_tlast,

    // AXIS out: |X|
    output reg                      m_axis_tvalid,
    input  wire                     m_axis_tready,
    output reg  [MAG_WIDTH-1:0]     m_axis_tdata,
    output reg                      m_axis_tlast
);

    // ===============================================================
    // 1) 握手机制
    // ===============================================================
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;

    // ===============================================================
    // 2) 输入拆分：实部、虚部
    // ===============================================================
    wire signed [RE_IM_WIDTH-1:0] re = s_axis_tdata[2*RE_IM_WIDTH-1:RE_IM_WIDTH];
    wire signed [RE_IM_WIDTH-1:0] im = s_axis_tdata[RE_IM_WIDTH-1:0];

    // ===============================================================
    // 3) 近似幅度计算
    //     近似方式：|Re| + |Im|
    //     （FFT 输出为补码格式，因此需取绝对值）
    // ===============================================================
    wire [RE_IM_WIDTH:0] approx_mag_wide =
        (re > 0 ? re : -re) + (im > 0 ? im : -im);

    // 截位或零扩展到 MAG_WIDTH
    wire [MAG_WIDTH-1:0] approx_mag =
        (RE_IM_WIDTH + 1 > MAG_WIDTH) ?
        approx_mag_wide[RE_IM_WIDTH:RE_IM_WIDTH - MAG_WIDTH + 1] :
        approx_mag_wide[MAG_WIDTH-1:0];

    // ===============================================================
    // 4) 输出寄存
    // ===============================================================
    always @(posedge clk_50m) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
            m_axis_tdata  <= {MAG_WIDTH{1'b0}};
        end
        else begin
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= s_axis_tlast;
                m_axis_tdata  <= approx_mag;
            end
            else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule
