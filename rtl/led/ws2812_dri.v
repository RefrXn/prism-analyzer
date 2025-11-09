`timescale 1ns / 1ps
module ws2812_dri (
    input              clk_50m      ,     // 50MHz 时钟输入
    input              rst_n        ,     // 复位信号（低有效）
    input  wire        start        ,     // 帧开始（打一拍）
    input  wire        valid        ,     // 数据有效（持续，高期间每个像素打一拍 done_bit）
    input  wire [23:0] din          ,     // GRB 数据输入
    output reg         dout         ,     // WS2812 数据线
    output reg         done_bit     ,     // 单个像素传输完成（打一拍）
    output reg         done_dz            // 全部传输完成（复位时序结束打一拍）
);

    // WS2812B 时序参数 (50MHz，周期20ns)
    parameter T0H = 17              ;     // 0 高电平 ~340ns
    parameter T1H = 45              ;     // 1 高电平 ~900ns
    parameter T0L = 35              ;     // 0 低电平 ~700ns
    parameter T1L = 27              ;     // 1 低电平 ~540ns
    parameter RESET_CYCLES = 14000  ;     // >280us 复位

    reg [13:0] cnt                   ;     // 周期计数
    reg [ 4:0] cnt_bit               ;     // 24bit计数
    reg [ 8:0] cnt_bety              ;     // 256颗灯计数
    reg [23:0] data_reg              ;     // 当前像素数据寄存
    reg [ 6:0] cur_state, next_state ;

    // FSM 状态定义
    localparam  IDLE = 7'b0000001    , 
                START = 7'b0000010   , 
                DATA0 = 7'b0000100   , 
                DATA1 = 7'b0001000   , 
                ACK = 7'b0010000     , 
                STOP = 7'b0100000    , 
                RES = 7'b1000000     ;

    // 状态机时序
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) cur_state <= IDLE;
        else cur_state <= next_state;
    end

    // 状态机组合
    always @(*) begin
        if (!rst_n) next_state = IDLE;
        else begin
            case (cur_state)
                IDLE  : next_state = (start || valid) ? START : IDLE;
                START : next_state = (data_reg[23-cnt_bit]==1'b0) ? DATA0 : DATA1;
                DATA0 : next_state = (cnt==T0H+T0L-1) ? ACK : DATA0;
                DATA1 : next_state = (cnt==T1H+T1L-1) ? ACK : DATA1;
                ACK   : next_state = (cnt_bit==5'd23) ? STOP : START;
                STOP  : next_state = (cnt_bety==9'd255) ? RES : IDLE;
                RES   : next_state = (cnt==RESET_CYCLES-1) ? IDLE : RES;
                default: next_state = IDLE;
            endcase
        end
    end

    // 输出与计数
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 24'd0;
            cnt      <= 14'd0;
            cnt_bit  <= 5'd0;
            cnt_bety <= 9'd0;
            dout     <= 1'b0;
            done_bit <= 1'b0;
            done_dz  <= 1'b0;
        end else begin
            case (cur_state)
                IDLE: begin
                    data_reg <= din;  // 在进入 START 前抓取新像素
                    cnt_bety <= start ? 'b0 : cnt_bety;
                    cnt      <= 14'd0;
                    cnt_bit  <= 5'd0;
                    dout     <= 1'b0;
                    done_bit <= 1'b0;
                    done_dz  <= 1'b0;
                end

                START: begin
                    cnt      <= 14'd0;
                    dout     <= 1'b0;
                    done_bit <= 1'b0;
                    done_dz  <= 1'b0;
                end

                DATA0: begin
                    cnt      <= (cnt == T0H + T0L - 1) ? 14'd0 : cnt + 14'd1;
                    dout     <= (cnt < T0H);
                    done_bit <= 1'b0;
                    done_dz  <= 1'b0;
                end

                DATA1: begin
                    cnt      <= (cnt == T1H + T1L - 1) ? 14'd0 : cnt + 14'd1;
                    dout     <= (cnt < T1H);
                    done_bit <= 1'b0;
                    done_dz  <= 1'b0;
                end

                ACK: begin
                    cnt      <= 14'd0;
                    dout     <= 1'b0;
                    cnt_bit  <= (cnt_bit == 5'd23) ? 5'd0 : (cnt_bit + 5'd1);
                    done_dz  <= 1'b0;
                    done_bit <= 1'b0;
                end

                STOP: begin
                    cnt      <= 14'd0;
                    cnt_bety <= (cnt_bety == 9'd255) ? 9'd0 : (cnt_bety + 9'd1);
                    cnt_bit  <= 5'd0;
                    dout     <= 1'b0;
                    done_bit <= 1'b1;  // 告知上游"当前像素发送完毕"
                    done_dz  <= 1'b0;
                end

                RES: begin
                    if (cnt == RESET_CYCLES - 1) begin
                        cnt     <= 14'd0;
                        done_dz <= 1'b1;  // 全帧复位完成
                    end else begin
                        cnt     <= cnt + 14'd1;
                        done_dz <= 1'b0;
                    end
                    cnt_bety <= 9'd0;
                    cnt_bit  <= 5'd0;
                    dout     <= 1'b0;
                    done_bit <= 1'b0;
                end

                default: begin
                    data_reg <= 24'd0;
                    cnt      <= 14'd0;
                    cnt_bety <= 9'd0;
                    cnt_bit  <= 5'd0;
                    dout     <= 1'b0;
                    done_bit <= 1'b0;
                    done_dz  <= 1'b0;
                end
            endcase
        end
    end

endmodule
