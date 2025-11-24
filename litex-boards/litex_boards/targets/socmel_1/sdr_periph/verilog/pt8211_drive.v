//pt8211驱动
module pt8211_drive(
    input        clk_1p536m,//bit clock, each sampling point occupies 32 clk_1p536m (16 for left and right channels)
    input        rst_n     ,//Active low asynchronous reset signal
    //用户数据接口
    input [15:0] idata_right     ,
    input [15:0] idata_left     ,
    output       req       ,//Data request signal, which can be connected to the read request of the external FIFO (to avoid empty reading, try to combine it with !fifo_empty and use it as fifo_rd)
    //pt8211接口
    output       HP_BCK   ,//Same as clk_1p536m
    output       HP_WS    ,//Left and right channel switching signal, low level corresponds to the left channel
    output       HP_DIN    //dac serial data input signal
);
reg [4:0] b_cnt;
reg       req_r,req_r1;//req_r1 delays req_r by one clock
reg [15:0] idata_r;//Temporary idata, used as an intermediate variable when shifting from parallel to string
reg HP_WS_r,HP_DIN_r;
assign HP_BCK = clk_1p536m;
assign HP_WS  = HP_WS_r   ;
assign HP_DIN = HP_DIN_r  ;
assign req    = req_r     ;
//b_cnt
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    b_cnt    <= 5'd0;
else
    b_cnt <= b_cnt+1'b1;
end
//req_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    req_r <= 1'b0;
else
    req_r <= (b_cnt == 5'd1) || (b_cnt == 5'd17);//Read one data every 16 clocks
end
//idata_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    begin
    req_r1  <= 1'b0;
    idata_r <= 16'd0;
    end
else
    begin
    req_r1  <= req_r;
    if (req_r1)
        if (HP_WS)
            idata_r <= idata_left;
        else   
            idata_r <= idata_right;
    else
        idata_r <= idata_r<<1;
    end
end
//HP_DIN_r
always@(negedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    HP_DIN_r <= 1'b0;
else
    HP_DIN_r <= idata_r[15];
end
//HP_WS_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    HP_WS_r <= 1'b0;
else
    HP_WS_r <= (b_cnt == 5'd3)?1'b0: ((b_cnt == 5'd19)?1'b1:HP_WS_r);//align data
end
endmodule

/*

//pt8211驱动
module pt8211_drive(
    input        clk_1p536m,//bit clock, each sampling point occupies 32 clk_1p536m (16 for left and right channels)
    input        rst_n     ,//Active low asynchronous reset signal
    //用户数据接口
    input [15:0] idata     ,
    output       req       ,//Data request signal, which can be connected to the read request of the external FIFO (to avoid empty reading, try to combine it with !fifo_empty and use it as fifo_rd)
    //pt8211接口
    output       HP_BCK   ,//Same as clk_1p536m
    output       HP_WS    ,//Left and right channel switching signal, low level corresponds to the left channel
    output       HP_DIN    //dac serial data input signal
);
reg [4:0] b_cnt;
reg       req_r,req_r1;//req_r1 delays req_r by one clock
reg [15:0] idata_r;//Temporary idata, used as an intermediate variable when shifting from parallel to string
reg HP_WS_r,HP_DIN_r;
assign HP_BCK = clk_1p536m;
assign HP_WS  = HP_WS_r   ;
assign HP_DIN = HP_DIN_r  ;
assign req    = req_r     ;
//b_cnt
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    b_cnt    <= 5'd0;
else
    b_cnt <= b_cnt+1'b1;
end
//req_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    req_r <= 1'b0;
else
    req_r <= (b_cnt == 5'd1) || (b_cnt == 5'd17);//Read one data every 16 clocks
end
//idata_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    begin
    req_r1  <= 1'b0;
    idata_r <= 16'd0;
    end
else
    begin
    req_r1  <= req_r;
    idata_r <= req_r1?idata:idata_r<<1;
    end
end
//HP_DIN_r
always@(negedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    HP_DIN_r <= 1'b0;
else
    HP_DIN_r <= idata_r[15];
end
//HP_WS_r
always@(posedge clk_1p536m or negedge rst_n)
begin
if(!rst_n)
    HP_WS_r <= 1'b0;
else
    HP_WS_r <= (b_cnt == 5'd3)?1'b0: ((b_cnt == 5'd19)?1'b1:HP_WS_r);//align data
end
endmodule

*/