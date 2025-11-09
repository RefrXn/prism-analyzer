module top (
    input  wire clk_50m,
    input  wire rst_n,
    input  wire ADC_DAT,
    output wire BCLK,
    output wire ADC_LRC,
    output wire DAC_LRC,
    output wire DAC_DAT,
    output wire I2C_SCLK,
    inout  wire I2C_SDAT,
    output wire WS2812_DOUT
);


    top_codec u_codec (
        .clk_50m   (clk_50m),
        .rst_n     (rst_n),
        .ADC_DAT(ADC_DAT),
        .BCLK (BCLK),
        .ADC_LRC (ADC_LRC),
        .DAC_LRC (DAC_LRC),
        .DAC_DAT(DAC_DAT),
        .I2C_SCLK (I2C_SCLK),
        .I2C_SDAT (I2C_SDAT)
    );


    wire sample_valid;
    wire signed [15:0] adc_l_data;
    assign sample_valid = u_codec.u_i2s.u_rx.o_rx_done;
    assign adc_l_data   = u_codec.u_i2s.u_rx.o_rx_data;


    //增益控制
    wire signed [15:0] amp_data = adc_l_data <<< 1;


    // FFT 与 WS2812 连线
    wire [clog2_fn(BANDS)-1:0] spec_rd_addr;
    wire                       spec_rd_en;
    wire [15:0]                spec_rd_data;
    wire                       spec_frame_stb;
    wire                       spec_rd_data_valid;

    localparam PCM_WIDTH         = 16;
    localparam FFT_LEN           = 1024;
    localparam FFT_RE_IM_WIDTH   = 16;
    localparam MAG_WIDTH         = 16;
    localparam BANDS             = 32;
    localparam HEIGHT            = 8;
    localparam PEAK_HOLD_FRAMES  = 3;


    top_fft #(
        .PCM_WIDTH(PCM_WIDTH),
        .FFT_LEN(FFT_LEN),
        .FFT_RE_IM_WIDTH(FFT_RE_IM_WIDTH),
        .MAG_WIDTH(MAG_WIDTH),
        .BANDS(BANDS),
        .PEAK_HOLD_FRAMES(PEAK_HOLD_FRAMES)
    ) u_fft (
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .pcm_in_valid(sample_valid),
        .pcm_in_sample(amp_data),
        .spec_rd_addr(spec_rd_addr),
        .spec_rd_en(spec_rd_en),
        .spec_rd_data(spec_rd_data),
        .spec_frame_stb(spec_frame_stb),
        .spec_rd_data_valid(spec_rd_data_valid)
    );


    top_led #(
        .BANDS(BANDS),
        .HEIGHT(HEIGHT)
    ) u_led (
        .clk(clk_50m),
        .rstn(rst_n),
        .spec_rd_data(spec_rd_data),
        .spec_rd_addr(spec_rd_addr),
        .spec_rd_en(spec_rd_en),
        .spec_rd_data_valid(spec_rd_data_valid),
        .spec_frame_stb(spec_frame_stb),
        
        .dout(WS2812_DOUT)
    );

    function integer clog2_fn;
        input integer v;
        integer i;
        begin
            v = v - 1;
            for (i = 0; v > 0; i = i + 1)
                v = v >> 1;
            clog2_fn = i;
        end
    endfunction
    
endmodule
