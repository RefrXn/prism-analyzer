module i2s #(
    parameter SYS_CLK     = 50_000_000,  // 系统参考时钟
    parameter SAMPLE_RATE = 48_000,      // I2S采样率
    parameter DEPTH       = 16           // 采样位宽配置
)(
    input                    clk_50m,     // 输入参考时钟
    input                    rst_n,       // 低电平复位
    input                    ADC_DAT,     // 输入音频ADC串行数据
    output                   BCLK,        // 输出i2s音频时钟
    output                   ADC_LRC,     // 输出ADC左右声道信号
    output                   DAC_LRC,     // 输出DAC左右声道信号
    output [31:0]            o_rx_data    // 并行ADC数据（保持32位接口不变）
);

    // BLCK差分信号
    wire p_bclk;
    wire n_bclk;

    // i2s时序生成模块（主机），WM8731为从机
    timing_gen #(
        .SYS_CLK             (SYS_CLK)     ,
        .SAMPLE_RATE         (SAMPLE_RATE) ,
        .DEPTH               (DEPTH)
    ) u_timing_gen (
        .clk_50m             (clk_50m)     ,
        .rst_n               (rst_n)       ,
        .BCLK                (BCLK)        ,
        .ADC_LRC             (ADC_LRC)     ,
        .DAC_LRC             (DAC_LRC)     ,
        .p_bclk              (p_bclk)      ,
        .n_bclk              (n_bclk)
    );

    // 音频接收串转并
    rx #(
        .DEPTH (DEPTH)
    ) u_rx (
        .clk_50m             (clk_50m)     ,
        .rst_n               (rst_n)       ,
        .ADC_LRC             (ADC_LRC)     ,
        .ADC_DAT             (ADC_DAT)     ,
        .i_p_bclk            (p_bclk)      ,
        .i_n_bclk            (n_bclk)      ,
        .o_rx_data           (o_rx_data)
    );

endmodule
