module top_codec( 
    input  clk_50m                      ,    // 输入参考时钟   
    input  rst_n                        ,    // 低电平复位     
    input  ADC_DAT                      ,    // 输入音频ADC串行数据   
    output BCLK                         ,    // 输出i2s音频时钟       
    output ADC_LRC                      ,    // 输出ADC左右声道信号       
    output DAC_LRC                      ,    // 输出DAC左右声道信号       
    output DAC_DAT                      ,    // 输出音频DAC串行数据（保持原端口，未驱动）
    output I2C_SCLK                     ,    // i2c配置 SCL
    inout  I2C_SDAT                          // i2c配置 SDA
);

    // 并行接收数据
    wire [31:0] o_rx_data;

    i2s #(
        .SYS_CLK      (50_000_000)      ,
        .SAMPLE_RATE  (48_000)          ,
        .DEPTH        (16)
    ) u_i2s (
        .clk_50m      (clk_50m)         ,
        .rst_n        (rst_n)           ,
        .ADC_DAT      (ADC_DAT)         ,
        .BCLK         (BCLK)            ,
        .ADC_LRC      (ADC_LRC)         ,
        .DAC_LRC      (DAC_LRC)         ,
        .o_rx_data    (o_rx_data)
    );


    i2c u_i2c(
        .clk_50m      (clk_50m)         ,
        .rst_n        (rst_n)           ,
        .I2C_SCLK     (I2C_SCLK)        ,
        .I2C_SDAT     (I2C_SDAT)
    );


endmodule
