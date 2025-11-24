//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Thu Apr 24 23:17:45 2025

module Gowin_MULT (dout, a, b, ce, clk, reset);

output [19:0] dout;
input [9:0] a;
input [9:0] b;
input ce;
input clk;
input reset;

wire [15:0] dout_w;
wire [17:0] soa_w;
wire [17:0] sob_w;
wire gw_vcc;
wire gw_gnd;

assign gw_vcc = 1'b1;
assign gw_gnd = 1'b0;

MULT18X18 mult18x18_inst (
    .DOUT({dout_w[15:0],dout[19:0]}),
    .SOA(soa_w),
    .SOB(sob_w),
    .A({a[9],a[9],a[9],a[9],a[9],a[9],a[9],a[9],a[9:0]}),
    .B({b[9],b[9],b[9],b[9],b[9],b[9],b[9],b[9],b[9:0]}),
    .ASIGN(gw_vcc),
    .BSIGN(gw_vcc),
    .SIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .SIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .CE(ce),
    .CLK(clk),
    .RESET(reset),
    .ASEL(gw_gnd),
    .BSEL(gw_gnd)
);

defparam mult18x18_inst.AREG = 1'b1;
defparam mult18x18_inst.BREG = 1'b1;
defparam mult18x18_inst.OUT_REG = 1'b1;
defparam mult18x18_inst.PIPE_REG = 1'b0;
defparam mult18x18_inst.ASIGN_REG = 1'b0;
defparam mult18x18_inst.BSIGN_REG = 1'b0;
defparam mult18x18_inst.SOA_REG = 1'b0;
defparam mult18x18_inst.MULT_RESET_MODE = "SYNC";

endmodule //Gowin_MULT
