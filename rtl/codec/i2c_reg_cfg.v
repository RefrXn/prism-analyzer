module i2c_reg_cfg (
    input                clk_i2c  ,     // i2c_reg_cfg驱动时钟
    input                rst_n    ,     // 复位信号
    input                i2c_done ,     // I2C一次操作完成反馈信号
    output  reg          i2c_exec ,     // I2C触发执行信号
    output  reg          cfg_done ,     // WM8978配置完成
    output  reg  [15:0]  i2c_data       // 寄存器数据（7位地址+9位数据）
);

    localparam REG_NUM      = 5'd11;        // 总共需要配置的寄存器个数
    localparam PHONE_LVOLUME = 7'd0;        // 左声道耳机输出音量大小参数（0~127）
    localparam PHONE_RVOLUME = 7'd120;        // 左声道耳机输出音量大小参数（0~127）
    
    
    
    //reg define
    reg    [7:0]  start_init_cnt;           // 初始化延时计数器
    reg    [4:0]  init_reg_cnt  ;           // 寄存器配置个数计数器
    
    //*****************************************************
    //**                    main code
    //*****************************************************
    
    //上电或复位后延时一段时间
    always @(posedge clk_i2c or negedge rst_n) begin
        if(!rst_n)
            start_init_cnt <= 8'd0;
        else if(start_init_cnt < 8'hff)
            start_init_cnt <= start_init_cnt + 1'b1;
    end
    
    //触发I2C操作
    always @(posedge clk_i2c or negedge rst_n) begin
        if(!rst_n)
            i2c_exec <= 1'b0;
        else if(init_reg_cnt == 5'd0 & start_init_cnt == 8'hfe)
            i2c_exec <= 1'b1;
        else if(i2c_done && init_reg_cnt < REG_NUM)
            i2c_exec <= 1'b1;
        else
            i2c_exec <= 1'b0;
    end
    
    //配置寄存器计数
    always @(posedge clk_i2c or negedge rst_n) begin
        if(!rst_n)
            init_reg_cnt <= 5'd0;
        else if(i2c_exec)
            init_reg_cnt <= init_reg_cnt + 1'b1;
    end
    
    //寄存器配置完成信号
    always @(posedge clk_i2c or negedge rst_n) begin
        if(!rst_n)
            cfg_done <= 1'b0;
        else if(i2c_done & (init_reg_cnt == REG_NUM) )
            cfg_done <= 1'b1;
    end
    
    //配置I2C器件内寄存器地址及其数据
    always @(posedge clk_i2c or negedge rst_n) begin
        if(!rst_n)
            i2c_data <= 16'b0;
        else begin
            case(init_reg_cnt)                    
                5'd0 : i2c_data <= {7'h0f ,9'b0};					// R15,软复位                    
                5'd1 : i2c_data <= {7'h00 ,9'b0_0001_0111};			// R0,未用到                   
                5'd2 : i2c_data <= {7'h01 ,9'b0_0001_0111};			// R1,未用到                 
                5'd3:  i2c_data <= {7'h02 ,{2'b01,PHONE_LVOLUME}};	// R2,耳机左声道音量                   
                5'd4 : i2c_data <= {7'h03 ,{2'b01,PHONE_RVOLUME}};	// R3,耳机右声道音量     
                5'd5 : i2c_data <= {7'h04 ,9'b0_0001_0100};         // R4,使能麦克风，关闭mic侧音(类似于bypass),取消mic输入的增益
                5'd6 : i2c_data <= {7'h05 ,9'b0000_00110};			// R5,数字音频输出配置,关闭adc静音
                5'd7 : i2c_data <= {7'h06 ,9'b0_0000_0000};			// R6,power down
                5'd8 : i2c_data <= {7'h07 ,9'b0_0001_0010};			// R7,I2S,16bit,LRC(H)-->right ch,slave
                5'd9 : i2c_data <= {7'h08 ,9'b0_0000_0000};			// R8,ADC-->48K  DAC-->48K
                5'd10: i2c_data <= {7'h09 ,9'b0_0000_0001};			//ACTIVE
                default : ;
            endcase
        end
    end

endmodule 