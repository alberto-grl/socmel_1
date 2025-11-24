module SinCos (
    input wire        Clock,
    input wire        ClkEn,
    input wire        Reset,
    input wire [9:0]  Theta,   // 10-bit angle (0-1023 = 0-2π)
    output reg [9:0]  Sine,    // 10-bit signed (-512 to 511)
    output reg [9:0]  Cosine   // 10-bit signed (-512 to 511)
);

//----------------------------------------------------------
// Phase Mapping:
//   Theta[9:8] determines the quadrant:
//     00: Quadrant 1 (0° to 90°)
//     01: Quadrant 2 (90° to 180°)
//     10: Quadrant 3 (180° to 270°)
//     11: Quadrant 4 (270° to 360°)
//
// Theta[7:0] is the angle within the quadrant (0-255)
//----------------------------------------------------------

// Quadrant signals
wire [1:0] quad = Theta[9:8];       // Quadrant index
wire [7:0] phase = Theta[7:0];      // Phase within quadrant
wire [7:0] lut_addr;                // Address for LUT (0-255)
reg [9:0] lut_value;               // Raw LUT output

// LUT address logic (exploits mirror symmetry in quadrants 2 and 4)
assign lut_addr = (quad == 2'b01 || quad == 2'b11) ? (8'd255 - phase) : phase;

//----------------------------------------------------------
// Sine LUT (256 entries, covers 0° to 90°)
// Stored as unsigned 0-511 (sin(0)=0, sin(π/2)=511)
//----------------------------------------------------------
reg [9:0] sin_lut [0:255];
initial begin
        sin_lut[0] = 10'd0;
        sin_lut[1] = 10'd3;
        sin_lut[2] = 10'd6;
        sin_lut[3] = 10'd9;
        sin_lut[4] = 10'd12;
        sin_lut[5] = 10'd15;
        sin_lut[6] = 10'd18;
        sin_lut[7] = 10'd21;
        sin_lut[8] = 10'd25;
        sin_lut[9] = 10'd28;
        sin_lut[10] = 10'd31;
        sin_lut[11] = 10'd34;
        sin_lut[12] = 10'd37;
        sin_lut[13] = 10'd40;
        sin_lut[14] = 10'd43;
        sin_lut[15] = 10'd46;
        sin_lut[16] = 10'd50;
        sin_lut[17] = 10'd53;
        sin_lut[18] = 10'd56;
        sin_lut[19] = 10'd59;
        sin_lut[20] = 10'd62;
        sin_lut[21] = 10'd65;
        sin_lut[22] = 10'd68;
        sin_lut[23] = 10'd71;
        sin_lut[24] = 10'd74;
        sin_lut[25] = 10'd78;
        sin_lut[26] = 10'd81;
        sin_lut[27] = 10'd84;
        sin_lut[28] = 10'd87;
        sin_lut[29] = 10'd90;
        sin_lut[30] = 10'd93;
        sin_lut[31] = 10'd96;
        sin_lut[32] = 10'd99;
        sin_lut[33] = 10'd102;
        sin_lut[34] = 10'd105;
        sin_lut[35] = 10'd108;
        sin_lut[36] = 10'd111;
        sin_lut[37] = 10'd115;
        sin_lut[38] = 10'd118;
        sin_lut[39] = 10'd121;
        sin_lut[40] = 10'd124;
        sin_lut[41] = 10'd127;
        sin_lut[42] = 10'd130;
        sin_lut[43] = 10'd133;
        sin_lut[44] = 10'd136;
        sin_lut[45] = 10'd139;
        sin_lut[46] = 10'd142;
        sin_lut[47] = 10'd145;
        sin_lut[48] = 10'd148;
        sin_lut[49] = 10'd151;
        sin_lut[50] = 10'd154;
        sin_lut[51] = 10'd157;
        sin_lut[52] = 10'd160;
        sin_lut[53] = 10'd163;
        sin_lut[54] = 10'd166;
        sin_lut[55] = 10'd169;
        sin_lut[56] = 10'd172;
        sin_lut[57] = 10'd175;
        sin_lut[58] = 10'd178;
        sin_lut[59] = 10'd180;
        sin_lut[60] = 10'd183;
        sin_lut[61] = 10'd186;
        sin_lut[62] = 10'd189;
        sin_lut[63] = 10'd192;
        sin_lut[64] = 10'd195;
        sin_lut[65] = 10'd198;
        sin_lut[66] = 10'd201;
        sin_lut[67] = 10'd204;
        sin_lut[68] = 10'd207;
        sin_lut[69] = 10'd209;
        sin_lut[70] = 10'd212;
        sin_lut[71] = 10'd215;
        sin_lut[72] = 10'd218;
        sin_lut[73] = 10'd221;
        sin_lut[74] = 10'd224;
        sin_lut[75] = 10'd226;
        sin_lut[76] = 10'd229;
        sin_lut[77] = 10'd232;
        sin_lut[78] = 10'd235;
        sin_lut[79] = 10'd238;
        sin_lut[80] = 10'd240;
        sin_lut[81] = 10'd243;
        sin_lut[82] = 10'd246;
        sin_lut[83] = 10'd249;
        sin_lut[84] = 10'd251;
        sin_lut[85] = 10'd254;
        sin_lut[86] = 10'd257;
        sin_lut[87] = 10'd260;
        sin_lut[88] = 10'd262;
        sin_lut[89] = 10'd265;
        sin_lut[90] = 10'd268;
        sin_lut[91] = 10'd270;
        sin_lut[92] = 10'd273;
        sin_lut[93] = 10'd276;
        sin_lut[94] = 10'd278;
        sin_lut[95] = 10'd281;
        sin_lut[96] = 10'd283;
        sin_lut[97] = 10'd286;
        sin_lut[98] = 10'd289;
        sin_lut[99] = 10'd291;
        sin_lut[100] = 10'd294;
        sin_lut[101] = 10'd296;
        sin_lut[102] = 10'd299;
        sin_lut[103] = 10'd301;
        sin_lut[104] = 10'd304;
        sin_lut[105] = 10'd306;
        sin_lut[106] = 10'd309;
        sin_lut[107] = 10'd311;
        sin_lut[108] = 10'd314;
        sin_lut[109] = 10'd316;
        sin_lut[110] = 10'd319;
        sin_lut[111] = 10'd321;
        sin_lut[112] = 10'd324;
        sin_lut[113] = 10'd326;
        sin_lut[114] = 10'd328;
        sin_lut[115] = 10'd331;
        sin_lut[116] = 10'd333;
        sin_lut[117] = 10'd336;
        sin_lut[118] = 10'd338;
        sin_lut[119] = 10'd340;
        sin_lut[120] = 10'd343;
        sin_lut[121] = 10'd345;
        sin_lut[122] = 10'd347;
        sin_lut[123] = 10'd350;
        sin_lut[124] = 10'd352;
        sin_lut[125] = 10'd354;
        sin_lut[126] = 10'd356;
        sin_lut[127] = 10'd359;
        sin_lut[128] = 10'd361;
        sin_lut[129] = 10'd363;
        sin_lut[130] = 10'd365;
        sin_lut[131] = 10'd367;
        sin_lut[132] = 10'd370;
        sin_lut[133] = 10'd372;
        sin_lut[134] = 10'd374;
        sin_lut[135] = 10'd376;
        sin_lut[136] = 10'd378;
        sin_lut[137] = 10'd380;
        sin_lut[138] = 10'd382;
        sin_lut[139] = 10'd384;
        sin_lut[140] = 10'd386;
        sin_lut[141] = 10'd388;
        sin_lut[142] = 10'd391;
        sin_lut[143] = 10'd393;
        sin_lut[144] = 10'd395;
        sin_lut[145] = 10'd396;
        sin_lut[146] = 10'd398;
        sin_lut[147] = 10'd400;
        sin_lut[148] = 10'd402;
        sin_lut[149] = 10'd404;
        sin_lut[150] = 10'd406;
        sin_lut[151] = 10'd408;
        sin_lut[152] = 10'd410;
        sin_lut[153] = 10'd412;
        sin_lut[154] = 10'd414;
        sin_lut[155] = 10'd415;
        sin_lut[156] = 10'd417;
        sin_lut[157] = 10'd419;
        sin_lut[158] = 10'd421;
        sin_lut[159] = 10'd423;
        sin_lut[160] = 10'd424;
        sin_lut[161] = 10'd426;
        sin_lut[162] = 10'd428;
        sin_lut[163] = 10'd430;
        sin_lut[164] = 10'd431;
        sin_lut[165] = 10'd433;
        sin_lut[166] = 10'd435;
        sin_lut[167] = 10'd436;
        sin_lut[168] = 10'd438;
        sin_lut[169] = 10'd439;
        sin_lut[170] = 10'd441;
        sin_lut[171] = 10'd443;
        sin_lut[172] = 10'd444;
        sin_lut[173] = 10'd446;
        sin_lut[174] = 10'd447;
        sin_lut[175] = 10'd449;
        sin_lut[176] = 10'd450;
        sin_lut[177] = 10'd452;
        sin_lut[178] = 10'd453;
        sin_lut[179] = 10'd455;
        sin_lut[180] = 10'd456;
        sin_lut[181] = 10'd457;
        sin_lut[182] = 10'd459;
        sin_lut[183] = 10'd460;
        sin_lut[184] = 10'd461;
        sin_lut[185] = 10'd463;
        sin_lut[186] = 10'd464;
        sin_lut[187] = 10'd465;
        sin_lut[188] = 10'd467;
        sin_lut[189] = 10'd468;
        sin_lut[190] = 10'd469;
        sin_lut[191] = 10'd470;
        sin_lut[192] = 10'd472;
        sin_lut[193] = 10'd473;
        sin_lut[194] = 10'd474;
        sin_lut[195] = 10'd475;
        sin_lut[196] = 10'd476;
        sin_lut[197] = 10'd477;
        sin_lut[198] = 10'd478;
        sin_lut[199] = 10'd480;
        sin_lut[200] = 10'd481;
        sin_lut[201] = 10'd482;
        sin_lut[202] = 10'd483;
        sin_lut[203] = 10'd484;
        sin_lut[204] = 10'd485;
        sin_lut[205] = 10'd486;
        sin_lut[206] = 10'd487;
        sin_lut[207] = 10'd488;
        sin_lut[208] = 10'd488;
        sin_lut[209] = 10'd489;
        sin_lut[210] = 10'd490;
        sin_lut[211] = 10'd491;
        sin_lut[212] = 10'd492;
        sin_lut[213] = 10'd493;
        sin_lut[214] = 10'd494;
        sin_lut[215] = 10'd494;
        sin_lut[216] = 10'd495;
        sin_lut[217] = 10'd496;
        sin_lut[218] = 10'd497;
        sin_lut[219] = 10'd497;
        sin_lut[220] = 10'd498;
        sin_lut[221] = 10'd499;
        sin_lut[222] = 10'd499;
        sin_lut[223] = 10'd500;
        sin_lut[224] = 10'd501;
        sin_lut[225] = 10'd501;
        sin_lut[226] = 10'd502;
        sin_lut[227] = 10'd502;
        sin_lut[228] = 10'd503;
        sin_lut[229] = 10'd504;
        sin_lut[230] = 10'd504;
        sin_lut[231] = 10'd504;
        sin_lut[232] = 10'd505;
        sin_lut[233] = 10'd505;
        sin_lut[234] = 10'd506;
        sin_lut[235] = 10'd506;
        sin_lut[236] = 10'd507;
        sin_lut[237] = 10'd507;
        sin_lut[238] = 10'd507;
        sin_lut[239] = 10'd508;
        sin_lut[240] = 10'd508;
        sin_lut[241] = 10'd508;
        sin_lut[242] = 10'd509;
        sin_lut[243] = 10'd509;
        sin_lut[244] = 10'd509;
        sin_lut[245] = 10'd509;
        sin_lut[246] = 10'd510;
        sin_lut[247] = 10'd510;
        sin_lut[248] = 10'd510;
        sin_lut[249] = 10'd510;
        sin_lut[250] = 10'd510;
        sin_lut[251] = 10'd510;
        sin_lut[252] = 10'd510;
        sin_lut[253] = 10'd510;
        sin_lut[254] = 10'd510;
        sin_lut[255] = 10'd510;

end

// LUT output (registered for timing)
always @(posedge Clock) begin
    if (ClkEn) lut_value <= sin_lut[lut_addr];
end

//----------------------------------------------------------
// Quadrant Handling Logic
//   Quadrant 1:  sin = +LUT,  cos = +LUT(256-phase)
//   Quadrant 2:  sin = +LUT,  cos = -LUT(phase)
//   Quadrant 3:  sin = -LUT,  cos = -LUT(256-phase)
//   Quadrant 4:  sin = -LUT,  cos = +LUT(phase)
//----------------------------------------------------------
wire [9:0] sin_raw = lut_value;
wire [9:0] cos_raw = sin_lut[8'd255 - lut_addr];

always @(posedge Clock) begin
    if (Reset) begin
        Sine   <= 10'd0;
        Cosine <= 10'd511; // cos(0) = 1.0
    end
    else if (ClkEn) begin
        // Sine output (positive in Q1/Q2, negative in Q3/Q4)
        case (quad)
            2'b00: Sine <=  sin_raw;       // Q1
            2'b01: Sine <=  sin_raw;       // Q2
            2'b10: Sine <= -sin_raw;       // Q3
            2'b11: Sine <= -sin_raw;       // Q4
        endcase

        // Cosine output (positive in Q1/Q4, negative in Q2/Q3)
        case (quad)
            2'b00: Cosine <=  cos_raw;     // Q1
            2'b01: Cosine <= -cos_raw;     // Q2
            2'b10: Cosine <= -cos_raw;     // Q3
            2'b11: Cosine <=  cos_raw;     // Q4
        endcase
    end
end

endmodule