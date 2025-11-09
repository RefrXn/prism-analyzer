module top_led #(
    parameter                        BANDS  = 32,
    parameter                        HEIGHT = 8
)(
    input  wire                       clk_50m,
    input  wire                       rst_n,

    input  wire [15:0]                spec_rd_data,
    input  wire [clog2_fn(BANDS)-1:0] spec_rd_addr,
    input  wire                       spec_rd_en,
    input  wire                       spec_rd_data_valid,
    input  wire                       spec_frame_stb,

    output wire                       dout
);

    wire [23:0] led_data;
    wire        led_data_valid, led_data_start;
    wire        done_bit, done_dz;

    spectrum_to_led #(
        .BANDS              (BANDS)             ,
        .HEIGHT             (HEIGHT)
    ) u_spectrum_to_led (
        .clk_50m            (clk_50m)           ,
        .rst_n              (rst_n)             ,
        .spec_frame_stb     (spec_frame_stb)    ,
        .spec_rd_data       (spec_rd_data)      ,
        .spec_rd_addr       (spec_rd_addr)      ,
        .spec_rd_en         (spec_rd_en)        ,
        .spec_rd_data_valid (spec_rd_data_valid),
        .led_data           (led_data)          ,
        .valid              (led_data_valid)    ,
        .start              (led_data_start)    ,
        .done_bit_in        (done_bit)          ,
        .done_dz_in         (done_dz)
    );

    ws2812_dri u_ws2812_dri (
        .clk_50m            (clk_50m)           ,
        .rst_n              (rst_n)             ,
        .start              (led_data_start)    ,
        .valid              (led_data_valid)    ,
        .din                (led_data)          ,
        .dout               (dout)              ,
        .done_bit           (done_bit)          ,
        .done_dz            (done_dz)
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
