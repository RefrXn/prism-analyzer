module band_buffer #(
    parameter integer BANDS      = 32,
    parameter integer DATA_WIDTH = 16
) (
    input  wire                        clk_50m,
    input  wire                        rst_n,

    // 写：一帧依次写 0..BANDS-1；最后一个 tlast=1
    input  wire                        s_axis_tvalid,
    output wire                        s_axis_tready,
    input  wire [DATA_WIDTH-1:0]       s_axis_tdata,
    input  wire                        s_axis_tlast,

    // 读：异步地址，同拍读出（1 阶寄存）
    input  wire [$clog2(BANDS)-1:0]    rd_addr,
    input  wire                        rd_en,
    output reg  [DATA_WIDTH-1:0]       rd_data,
    output reg                         rd_data_valid,

    output reg                         frame_stb
);

    // ===============================================================
    // 1) 写端简单握手：恒 ready，不 Backpressure
    // ===============================================================
    assign s_axis_tready = 1'b1;

    // ===============================================================
    // 2) 内部存储及地址控制
    // ===============================================================
    reg [$clog2(BANDS)-1:0] waddr;
    reg [DATA_WIDTH-1:0]    mem [0:BANDS-1];

    integer i;

    // ===============================================================
    // 3) 主时序逻辑
    // ===============================================================
    always @(posedge clk_50m) begin
        if (!rst_n) begin
            waddr         <= 0;
            frame_stb     <= 1'b0;
            rd_data       <= 0;
            rd_data_valid <= 1'b0;
            for (i = 0; i < BANDS; i = i + 1)
                mem[i] <= 0;
        end
        else begin
            frame_stb <= 1'b0;

            // ----------------------------
            // 写入路径（带衰减效果）
            // ----------------------------
            if (s_axis_tvalid) begin
                mem[waddr] <= (s_axis_tdata > mem[waddr]) ?
                              s_axis_tdata :
                              ((mem[waddr] > 300) ? (mem[waddr] - 300) : 0);

                if (waddr == BANDS - 1)
                    waddr <= 0;
                else
                    waddr <= waddr + 1;

                if (s_axis_tlast)
                    frame_stb <= 1'b1;  // 每帧最后一个 band 写完打一拍
            end

            // ----------------------------
            // 读出路径（异步地址读，同拍输出）
            // ----------------------------
            if (rd_en) begin
                rd_data       <= mem[rd_addr];
                rd_data_valid <= 1'b1;
            end
            else begin
                rd_data_valid <= 1'b0;
            end
        end
    end

endmodule
