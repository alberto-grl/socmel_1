/*
Standalone test of NCO for FPGARX
*/

// IP Express reference : https://www.latticesemi.com/-/media/LatticeSemi/Documents/UserManuals/EI2/FPGA-IPUG-02032-1-0-Arithmetic-Modules.ashx?document_id=52235

// with BIT_1_ADC RF_IN and RF_OUT should be enabled in .cst file   
`define BIT_1_ADC
`define ENABLE_HILBERT
`define LED_CONTROL_SDR_PERIPH

module sdr_periph 
  (
  input rst    , 
	output TX,
	//output clk_adc,
	output TX_NCO,
	input  RFIn_p,
  input  RFIn_n,
	output wire RFOut,
	input clk,

  `ifdef LED_CONTROL_SDR_PERIPH
  output wire [5:0]  leds,
  `endif

/*output MOSI_I,
	input MISO_I,
	output SCK_I,
	output SSEL_I,
	output MOSI_Q,
	input MISO_Q,
	output SCK_Q,
	output SSEL_Q,
*/
	//output PWMOut
 //pt8211接口
    output       HP_BCK   , //同clk_1p536m
    output       HP_WS    , //Left and right channel switching signal, low level corresponds to the left channel
    output       HP_DIN   , //dac串行数据输入信号
    output       PA_EN    ,//音频功放使能，高电平有效

    input  wire        csr_sdr_we,
    input  wire [127:0] csr_sdr_wdata, // 4 registers x 32 bits
    output reg  [127:0] csr_sdr_rdata, // 4 registers x 32 bits
    input  wire [3:0]  csr_sdr_addr    // optional
	);



`ifdef BIT_1_ADC
wire RFIn;
// LVDS Input Buffer
TLVDS_IBUF  lvds_ibuf (
  .I(RFIn_p),
  .IB(RFIn_n),
  .O(RFIn)
);
`endif

`ifndef BIT_1_ADC
reg signed[9:0] RFIn;
`endif


wire rst_n;
reg signed[9:0] LOSine;
reg signed[9:0] LOCosine;
wire signed[9:0] sine_o;
wire signed[9:0] cosine_o;
reg signed[63:0] phase_inc_carrGen;
reg signed[63:0] phase_inc_carrGen1;
wire signed[9:0] LOSine_test_gen;
wire signed[9:0] LOCosine_test_gen;
reg signed[63:0] phase_inc_testGen;
reg signed[63:0] phase_inc_testGen1;
//end signed
wire [63:0] phase_accum;
wire [63:0] phase_accum_test_gen;
reg clk_adc;  //60 MHz to ADC, mixer, CIC
wire CIC_out_clkI;  // 60 MHz / CIC decimation, eg. 234375 Hz
wire CIC_out_clkQ;
reg [7:0] CICGain;
`ifdef BIT_1_ADC
reg signed [19:0] MixerOutI;
reg signed [19:0] MixerOutQ;	
`endif
`ifndef BIT_1_ADC
wire signed [19:0] MixerOutI;
wire signed [19:0] MixerOutQ;	
`endif
reg [1:0] clk_adc_counter;
wire [127:0] Registers_I; //will store 8 registers 16 bit wide. 16 * 8 = 128   
wire [127:0] Registers_Q; //will store 8 registers 16 bit wide. 16 * 8 = 128   
wire [31:0] MOSI_Val_I;	
wire [31:0] MOSI_Val_Q;
reg StartSPI_I;
wire [31:0] data_out_I;
reg StartSPI_Q;
wire [31:0] data_out_Q;
reg RFInR;
reg RFInR1;
wire signed [31:0] I_out;
wire signed [31:0] Q_out;
reg signed [32:0] audio_out_l;
reg signed [32:0] audio_out_r;
reg signed [32:0] audio_out;
wire req_w;
reg [3:0] dac_clk_div;
wire dac_clk;
reg [31:0] regtest;
wire hilbert_data_out_valid;
reg [0:3] audio_vol;
reg lsb_rx;

assign rst_n = ~rst;

// inc = 2^64 * Fout / Fclock
// Python: print(hex(pow(2,64) * 1359000 // 64000000))



`ifdef BIT_1_ADC
  always @(posedge clk)
    begin 
      RFInR1 <= RFIn;
      RFInR <= RFInR1;	
    end

  assign RFOut = RFInR1;

  always @(posedge clk)
    begin
      if (RFInR == 1'b 0)
        begin
          MixerOutI <= LOSine <<< 10;
          MixerOutQ <= LOCosine <<< 10;
        end
      else
        begin
          MixerOutI <= -LOSine <<< 10;
          MixerOutQ <= -LOCosine <<< 10;				
        end
    end
`endif 


wire signed [79:0] gw_cic_out_i;
wire signed [79:0] gw_cic_out_q;

CIC_Fliter_Top  CIC_Fliter_gw_cic_i(
    .clk(clk), //input clk
    .rstn(rst_n), //input rstn
    .in_valid(1'b1), //input in_valid
    .in_data(MixerOutI), //input [19:0] in_data
    .out_valid(CIC_out_clkI), //output out_valid
    .out_data(gw_cic_out_i) //output [79:0] out_data
  );

CIC_Fliter_Top  CIC_Fliter_gw_cic_Q(
    .clk(clk), //input clk
    .rstn(rst_n), //input rstn
    .in_valid(1'b1), //input in_valid
    .in_data(MixerOutQ), //input [19:0] in_data
    .out_valid(CIC_out_clkQ), //output out_valid
    .out_data(gw_cic_out_q) //output [79:0] out_data
  );


assign    MOSI_Val_I =  gw_cic_out_i[79:48];
assign    MOSI_Val_Q =  gw_cic_out_q[79:48];

SinCos SinCos_test_gen (
.Clock (clk),
.ClkEn (1'b 1),
.Reset (1'b 0),
.Theta (phase_accum_test_gen[63:54]),
.Sine (LOSine_test_gen),
.Cosine (LOCosine_test_gen)
);

nco_sig nco_test_gen  (
.clk (clk),
.phase_inc_carr ( phase_inc_testGen1),
.phase_accum (phase_accum_test_gen)
);

wire data_valid;

DDS_II_Top DDS_lo(
    .clk_i(clk), //input clk_i
    .rst_n_i(rst_n), //input rst_n_i
    .config_valid_i(1'b1), //input config_valid_i
    .config_inc_i(phase_inc_carrGen1[63:32]), //input [31:0] config_inc_i
    .cosine_o(cosine_o), //output [9:0] cosine_o
    .sine_o(sine_o), //output [9:0] sine_o
    .data_valid_o(data_valid_o) //output data_valid_o
  );
always @(posedge clk) begin
    LOSine <=  sine_o;
    LOCosine <=  cosine_o;
end




`ifndef BIT_1_ADC
/*
Multiplier MixerI  (
	.Clock (clk),
    .ClkEn (1'b1),
    .Aclr (1'b 0),
    .DataA (-LOSine[9:0]),
//	.DataA (511),
    .DataB (RFIn[9:0]),
	// .DataB (10'b1),
    .Result (MixerOutI[19:0])
);
*/
  Gowin_MULT MixerI(
        .dout(MixerOutI[19:0]), //output [19:0] dout
        .a(LOSine[9:0]), //input [9:0] a
        .b(RFIn[9:0]), //input [9:0] b
        .ce(1'b1), //input ce
        .clk(clk), //input clk
        .reset(1'b0) //input reset
        );

  Gowin_MULT1 MixerQ(
        .dout(MixerOutQ[19:0]), //output [19:0] dout
        .a(LOCosine[9:0]), //input [9:0] a
        .b(RFIn[9:0]), //input [9:0] b
        .ce(1'b1), //input ce
        .clk(clk), //input clk
        .reset(1'b0) //input reset
        );
`endif

`ifdef ENABLE_HILBERT
Hilbert Hilbert (
.clk (clk),
.rst_n (rst_n),
.I_in (MOSI_Val_I[31:0]),
.Q_in (MOSI_Val_Q[31:0]),
.data_valid (CIC_out_clkI),
.I_out (I_out[31:0]),
.Q_out (Q_out[31:0]),
.data_out_valid (hilbert_data_out_valid)
);
`endif

`ifndef ENABLE_HILBERT
assign I_out[31:0] = MOSI_Val_I[31:0];
assign Q_out[31:0] = MOSI_Val_Q[31:0];
`endif 



always @(posedge clk or posedge rst)
begin // Counter block
    if (rst)
        dac_clk_div <= 4'd0;
    else 
        dac_clk_div <= dac_clk_div + 1'b1;
end

assign dac_clk = dac_clk_div[3];

//assign TX = phase_accum[63];
assign TX_NCO = phase_accum[43];
assign PA_EN = 1'b1;//PA Normally Open


`ifdef LED_CONTROL_SDR_PERIPH
//  assign leds[2:0] = 3'b 101;  //phase_inc_carrGen[4:0];
  assign leds[0] = lsb_rx;
  assign leds[1] = 1'b1;
  assign leds[2] = 1'b1;
  assign leds[3] = 1'b0;
  assign leds[4] = 1'b1;
`endif


always @ (posedge (clk /*clk_adc*/))
	begin
	phase_inc_testGen1 <= phase_inc_testGen;	
	phase_inc_carrGen1 <= phase_inc_carrGen;
	`ifndef BIT_1_ADC
	RFIn <=  (LOSine_test_gen)/32; // >>> sign extends when registers are signed
	`endif
	clk_adc_counter <= clk_adc_counter+ 2'b1;
	clk_adc <= clk_adc_counter[0];
	CICGain <= 1;  //2 is full out with maximum in. Higher values increase gain
  if (lsb_rx)
    	audio_out <= (I_out - Q_out) >>> audio_vol;  // audio_out <= Q_out - I_Out for LSB
  else
      audio_out <= (I_out + Q_out) >>> audio_vol;  // audio_out <= Q_out + I_Out for USB   
  
// inc = 2^64 * Fout / Fclock
// Python: print(hex(pow(2,64) * 1359000 // 64800000))
 // phase_inc_carrGen <= 64'h 800000000000000; // 2 MHz
 //  phase_inc_carrGen <= Registers_I[63:0];

//	          phase_inc_carrGen <= 64'h 1c4ccccccccccccc; // 7075 KHz 
//			  phase_inc_carrGen <= 64'h 1c4c49ba5e353f7c; // 7074.5 KHz
//		      phase_inc_carrGen <= 64'h 1ba781948b0fcd6e; // 7000 kHz	@64.8 MHz
//			  phase_inc_carrGen <= 64'h 1c2786c226809d49; // 7038.6 KH	(WSPR2)	
//			  phase_inc_carrGen <= 64'h 1bf258bf258bf258; // 7074 kHz (FT8) @64.8 MHz
//			  phase_inc_carrGen <= 64'h 384bc6a7ef9db22d; // 14074 kHz (FT8)

//	          phase_inc_testGen <= 64'h 1ba8847ce7186625; // 7001 KHz @64.8 MHz
            phase_inc_testGen <= 64'h 25ba5e353f7ced91; // 7074 KHz @48 MHz
//	          phase_inc_testGen <= 64'h 102e85c0898b7; // 1 KHz @64.8
//		      phase_inc_carrGen <= 64'h 538ef34d6a161; // 5.1 KHz
//			  phase_inc_carrGen <= 64'h 624dd2f1a9fbe; // 6 KHz
  end


always @(posedge clk )
begin
		if (CIC_out_clkI) 
			begin
				StartSPI_I <= 1'b1;
          csr_sdr_rdata[31:0]   <= phase_inc_testGen[63:32];   //I_out[31:0];
          csr_sdr_rdata[32]  <= lsb_rx;
          csr_sdr_rdata[95:64]  <= MOSI_Val_I[31:0];
          csr_sdr_rdata[127:96] <= MOSI_Val_Q[31:0];
//TODO: cd_sdr_we seems not working, always low, keep disabled. we for lcd peripheral seems ok. 
 //          if (csr_sdr_we ==  1'b1) begin
              phase_inc_carrGen <= csr_sdr_wdata[63:0];
              lsb_rx <= csr_sdr_wdata[64];
              audio_vol <= csr_sdr_wdata[69:65];
              //reg1 <= csr_sdr_wdata[67:64];
              regtest <= csr_sdr_wdata[95:70];
              //reg3 <= csr_sdr_wdata[127:96];       
 //          end       
			end
			else
			begin
				StartSPI_I <= 1'b0;
			end

end
		

always @(posedge clk )
begin
		if (CIC_out_clkQ) 
			begin
				StartSPI_Q <= 1'b1;
			end
			else
			begin
				StartSPI_Q <= 1'b0;
			end
end

/*
SPI_Master SPI_Master_I (
.osc_clk (clk ),  
//.rst (rst),
//.data_in ({22'b0, LOSine[9:0]}),
//.data_in ({22'b0, RFIn[9:0]}),
//.data_in ({12'b0, MixerOutI[19:0]}),
.data_in (I_out),
//.data_in (32'b 10101010101010101010101010101011),
.data_out (data_out_I),
.StartSPI (StartSPI_I),
.SCK (SCK_I),
.MOSI (MOSI_I),
.MISO (MISO_I),
.SSEL (SSEL_I),
.Registers (Registers_I)
);

SPI_Master SPI_Master_Q (
.osc_clk (clk),  
//.rst (rst),
.data_in (Q_out), 
.data_out (data_out_Q),
.StartSPI (StartSPI_Q),
.SCK (SCK_Q),
.MOSI (MOSI_Q),
.MISO (MISO_Q),
.SSEL (SSEL_Q),
.Registers (Registers_Q)
);
*/

//音频DAC驱动
pt8211_drive u_pt8211_drive_0(
    .clk_1p536m(dac_clk),//bit clock, each sampling point occupies 32 clk_1p536m (16 for each left and right channel)
    .rst_n     (rst_n),//Active low asynchronous reset signal
    //用户数据接口
    .idata_right      ( audio_out[32:17]),// Tip // I Delay only
    .idata_left      ( audio_out[32:17]),// Ring // Q Hilbert
//  .idata_right      ( MixerOutI[19:4]),// Tip // I Delay only
//    .idata_left      ( MixerOutQ[19:4]),// Ring // Q Hilbert
//  .idata_right      ( I_out [31:16]),// Tip // I Delay only was  ( I_out [19:4])
//    .idata_left      ( (Q_out[31:16])),// Ring // Q Hilbert
//    .idata_right      ( MOSI_Val_I[31:16]),// Tip // I Delay only
//    .idata_left      ( MOSI_Val_Q[31:16]),// Ring // Q Hilbert  phase_inc_carrGen <= 64'h 624dd2f1a9fbe; // 6 KHz
    .req       (req_w),//Data request signal, can be connected to the read request of external FIFO (to avoid empty reading, try to AND it with !fifo_empty as fifo_rd)
    //pt8211接口
    .HP_BCK   (HP_BCK),//同clk_1p536m
    .HP_WS    (HP_WS),//Left and right channel switching signal, low level corresponds to the left channel
    .HP_DIN   (HP_DIN)//DAC serial data input signal
);

/*
PWM PWM1 (
.clk (osc_clk),
//.DataIn (IIR_out), //(CIC_out),
//.DataIn (DemodOut), //(IIR_out),
//.DataIn (MOSI_Val_I[31:20]),
.DataIn (audio_out[31:20]),
//.DataIn (LOSine_test_gen),
.PWMOut (PWMOut)
);
*/
endmodule
