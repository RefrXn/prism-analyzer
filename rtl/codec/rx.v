module rx #(
    parameter DEPTH = 16                        // 每声道采样位宽
)(
    input  wire             clk_50m    ,        // 系统时钟（与 BCLK 同步）
    input  wire             rst_n      ,        // 异步复位，低电平有效
    input  wire             ADC_LRC    ,        // LRCLK：左右声道选择信号
    input  wire             ADC_DAT    ,        // 串行 ADC 音频输入
    input  wire             i_p_bclk   ,        // BCLK 正沿标志
    input  wire             i_n_bclk   ,        // BCLK 负沿标志

    output reg  [DEPTH-1:0] o_rx_data  ,        // 输出：接收的并行音频数据
    output reg              o_rx_done           // 输出：一帧采样完成标志（1clk 有效）
);

    //============================================================
    // 内部信号定义
    //============================================================
    reg [7:0] rx_cnt;                           // bit 位计数器
    reg [DEPTH-1:0] r_rx_data;                  // 串行移位寄存器
    reg r_adc_rlc;                              // LRCLK 延迟寄存器
    wire adc_rlc_edge;                          // LRCLK 翻转检测信号

    assign adc_rlc_edge = ADC_LRC ^ r_adc_rlc;  // 异或检测翻转沿

    //============================================================
    // LRCLK 边沿检测
    //============================================================
    // 捕获 i_adc_rlc 的前一拍，用于检测左右声道切换时刻
    always @(posedge clk_50m) begin
        if (!rst_n)
            r_adc_rlc <= 1'b0;
        else if (i_n_bclk)
            r_adc_rlc <= ADC_LRC;
    end

    //============================================================
    // bit 计数逻辑
    //============================================================
    // 每帧采样位数 = SAMPLE_DEEP
    // LRCLK 翻转后重新计数
    always @(posedge clk_50m) begin
        if (!rst_n)
            rx_cnt <= 8'd0;
        else if (adc_rlc_edge)
            rx_cnt <= 8'd0;
        else if (rx_cnt < DEPTH + 8'd3 && i_p_bclk)
            rx_cnt <= rx_cnt + 8'd1;
    end

    //============================================================
    // 串行数据移位寄存器
    //============================================================
    // 在 BCLK 正沿采样输入的串行数据
    always @(posedge clk_50m) begin
        if (!rst_n)
            r_rx_data <= {DEPTH{1'b0}};
        else if (rx_cnt < DEPTH && i_p_bclk)
            r_rx_data <= {r_rx_data[DEPTH-2:0], ADC_DAT};
    end

    //============================================================
    // 并行输出寄存器
    //============================================================
    // 当计数到达 SAMPLE_DEEP 时锁存数据
    always @(posedge clk_50m) begin
        if (!rst_n)
            o_rx_data <= {DEPTH{1'b0}};
        else if (rx_cnt == DEPTH && i_p_bclk)
            o_rx_data <= r_rx_data;
    end

    //============================================================
    // 采样完成信号
    //============================================================
    // o_rx_done 在每帧接收结束时拉高一个时钟周期
    always @(posedge clk_50m) begin
        if (!rst_n)
            o_rx_done <= 1'b0;
        else if (rx_cnt == DEPTH && i_p_bclk)
            o_rx_done <= 1'b1;
        else
            o_rx_done <= 1'b0;
    end

endmodule
