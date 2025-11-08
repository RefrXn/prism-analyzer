module frame_packer #(
    parameter integer PCM_WIDTH       = 16,
    parameter integer FFT_LEN         = 1024,
    parameter integer FFT_RE_IM_WIDTH = 16
) (
    input  wire                         clk_50m,
    input  wire                         rst_n,

    input  wire                         pcm_in_valid,
    input  wire signed [PCM_WIDTH-1:0]  pcm_in_sample,

    output wire                         s_axis_tvalid,
    input  wire                         s_axis_tready,
    output wire [2*FFT_RE_IM_WIDTH-1:0] s_axis_tdata,   // {Re,Im}
    output wire                         s_axis_tlast
);

    // ===============================================================
    // 1) 实部扩展，虚部清零
    // ===============================================================
    wire signed [FFT_RE_IM_WIDTH-1:0] re_ext  = 
        {{(FFT_RE_IM_WIDTH - PCM_WIDTH){pcm_in_sample[PCM_WIDTH-1]}}, pcm_in_sample};

    wire signed [FFT_RE_IM_WIDTH-1:0] im_zero = {FFT_RE_IM_WIDTH{1'b0}};

    // ===============================================================
    // 2) 简单握手机制，无FIFO，靠FFT端ready backpress
    // ===============================================================
    reg [ $clog2(FFT_LEN):0 ] sample_cnt;

    assign s_axis_tdata  = {re_ext, im_zero};
    assign s_axis_tvalid = (pcm_in_valid && s_axis_tready);
    assign s_axis_tlast  = (sample_cnt == FFT_LEN - 1);

    // ===============================================================
    // 3) 计数逻辑，目前1024点一帧
    // ===============================================================
    always @(posedge clk_50m) begin
        if (!rst_n) begin
            sample_cnt <= 0;
        end 
        else if (pcm_in_valid && s_axis_tready) begin
            if (sample_cnt == FFT_LEN - 1)
                sample_cnt <= 0;
            else
                sample_cnt <= sample_cnt + 1;
        end 
        else begin
            sample_cnt <= sample_cnt;
        end
    end

endmodule
