module spectrum_to_led #(
    parameter integer BANDS      = 32,
    parameter integer HEIGHT     = 8,
    parameter integer SERPENTINE = 1       // 1 开启蛇形：0-based 奇数行(1,3,5,7)反向 => 1-based 的 2/4/6/8 行
)(
    input  wire        clk_50m,
    input  wire        rst_n,
    input  wire        spec_frame_stb,     // 开始一帧
    input  wire [15:0] spec_rd_data,
    output reg  [ 4:0] spec_rd_addr,       // 32 bands -> 5 bits
    output reg         spec_rd_en,
    input  wire        spec_rd_data_valid,

    // WS2812 上层接口
    output reg [23:0]  led_data,           // GRB
    output reg         valid,
    output reg         start,
    input  wire        done_bit_in,
    input  wire        done_dz_in
);


endmodule


