module timing_gen #(
	parameter SYS_CLK     = 50_000_000 ,
	parameter SAMPLE_RATE = 48_000     ,
	parameter DEPTH = 16         
)
(
	input      clk_50m                  ,
	input      rst_n                    ,
	output reg BCLK                     ,
	output     ADC_LRC                  ,
	output     DAC_LRC 	                ,
	output     p_bclk                   ,
	output     n_bclk		                   	
);

           
    localparam AV_DIV       = SYS_CLK/(SAMPLE_RATE*DEPTH*2)-1;
    localparam AV_DIV_1     = AV_DIV/2;
    
    reg [9:0] bclk_cnt;
    reg [7:0] rlc_cnt;
    reg rlc;
    
    assign p_bclk= (bclk_cnt==AV_DIV)  ;
    assign n_bclk= (bclk_cnt==AV_DIV_1);
    assign ADC_LRC=rlc               ;
    assign DAC_LRC=rlc               ;
    
    
    //BCLK
    always @(posedge clk_50m) begin
        if(!rst_n) bclk_cnt<=10'd0;
        else if(bclk_cnt==AV_DIV) bclk_cnt<=10'd0;
        else bclk_cnt<=bclk_cnt+10'd1;
    end
    
    always @(posedge clk_50m) begin
        if(!rst_n) BCLK<=1'd0     ;
        else if(p_bclk) BCLK<=1'd1;
        else if(n_bclk) BCLK<=1'd0;
    end
    
    
    //LRC£¨RLC£©
    always @(posedge clk_50m) begin
        if(!rst_n) rlc_cnt<=8'd0;
        else if(rlc_cnt==DEPTH+8'd2&&n_bclk) rlc_cnt<=8'd0;	
        else if(n_bclk) rlc_cnt<=rlc_cnt+8'd1;
    end
    
    always @(posedge clk_50m) begin
        if(!rst_n) rlc<=1'd0;
        else if(rlc_cnt==DEPTH+8'd2&&n_bclk) rlc<=~rlc;
    end

endmodule

