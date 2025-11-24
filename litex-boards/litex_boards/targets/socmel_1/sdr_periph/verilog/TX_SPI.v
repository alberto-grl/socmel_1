
//Seems to work OK at 4 MHz, maybe 8. fails at 16 with slow slewrate. with fast slewrate works at 16, fails at 32


module SPI_Master (
	input              osc_clk  ,
	//input rst,
	input      [ 31:0] data_in  ,
	output reg [ 31:0] data_out ,
	input              MISO     , 
	input              StartSPI ,
	output reg         SCK      ,
	output             MOSI     ,
	output reg         SSEL     ,
	output reg [127:0] Registers  //will store 8 registers 16 bit wide. 16 * 8 = 128
);

	parameter BAUD_DIVISOR = 7; //desired value -1, insert 3 for dividing clock by 4

	reg  [15:0] SIO_count        ;
	reg  [31:0] MOSIdata         ; //we are master so this will be sent out on MOSI pin
	reg  [31:0] MISOdata         ; //we are master so this will store bits received on MISO pin
	reg  [31:0] data_in_1        ;
	reg         StartSPI_synced  ;
	reg         clk_scaled_enable;
	reg  [ 7:0] clk_counter      ;
	reg  [ 2:0] SCKr             ;
	reg  [ 2:0] SSELr            ;
	wire        SCK_risingedge  ;
	wire        SSEL_fallingedge ;

//generate clk_scaled_enable, used for lowering baud rate while always using always @ posedge osc_clk for sensitivity list.
//this eases timing constraint requirements
	always @(posedge osc_clk)
		begin
			if (clk_counter == BAUD_DIVISOR)
				begin
					clk_counter       <= 8'b0;
					clk_scaled_enable <= 1;
				end
			else
				begin
					clk_counter       <= clk_counter + 8'b1;
					clk_scaled_enable <= 0;
				end
		end


/*
	*    SPI Master  CPOL = 0, CPHA =0 (Motorola)
*/
	always @(posedge osc_clk )
		begin
			if (StartSPI) 
				begin //start SPI
	
					SSEL            <= 1'b0;
					SIO_count       <= 16'h 40 * 8 + 6;
					SCK             <= 1'b0;
					MOSIdata <= data_in;
				end
			else 
				begin
						if (SIO_count == 16'h0)  // h10: TX is over after 16 clocks for 8 bit TX, 64 for 32 bit
							begin //end SPI
								SSEL     <= 1'b1;
								SCK      <= 1'b0;
								data_out <= MISOdata;
							end
						else
							begin //send data and clock
								SIO_count <= SIO_count -16'b1;
								if (SIO_count[2:0] == 3'b 111)
									begin
										SCK <= ~SCK;
									end
								if (SIO_count[3:0] == 4'b 0111)
									begin
									//	MOSIdata[7:0] <= {MOSIdata[6:0], 1'b0};  //8 bit TX
										MOSIdata[31:0] <= {MOSIdata[30:0], 1'b0};
									end
							end
				end
	end

always @(posedge osc_clk )
		begin
//				if (clk_scaled_enable)
				begin		
					SSELr <= {SSELr[1:0], SSEL};
					SCKr <= {SCKr[1:0], SCK};
				end
		end	

assign SCK_risingedge = (SCKr[1:0]==2'b01);
assign SSEL_fallingedge = (SSELr[1:0]==2'b10);




/*

	always @(posedge osc_clk )
		begin
			data_in_1 <= data_in;
			if (StartSPI && !StartSPI_synced)
				begin
					StartSPI_synced <= 1'b1;
				end
			if (StartSPI_synced && clk_scaled_enable) //TODO check
				begin //start SPI
					StartSPI_synced <= 1'b0;
					SSEL            <= 1'b0;
					SIO_count       <= 16'h0;
					SCK             <= 1'b0;
				end
			else
				if (clk_scaled_enable)
					begin
						if (SIO_count == 16'h40)  // h10: TX is over after 16 clocks for 8 bit TX, 64 for 32 bit
							begin //end SPI
								SSEL     <= 1'b1;
								SCK      <= 1'b0;
								data_out <= MISOdata;
							end
						else
							begin //send data and clock
								SIO_count <= SIO_count +16'b1;
								SCK       <= ~SCK;
							end
					end
		end

always @(posedge osc_clk )
		begin
//				if (clk_scaled_enable)
				begin		
					SSELr <= {SSELr[1:0], SSEL};
					SCKr <= {SCKr[1:0], SCK};
				end
		end	

assign SCK_risingedge = (SCKr[1:0]==2'b01);
assign SSEL_fallingedge = (SSELr[1:0]==2'b10);


always @(posedge osc_clk )
		begin

			if (SCK_risingedge)
						begin
							//	MOSIdata[7:0] <= {MOSIdata[6:0], 1'b0};  //8 bit TX
							MOSIdata[31:0] <= {MOSIdata[30:0], 1'b0};
						end
			if (StartSPI )
						begin
							MOSIdata <= data_in;
						end
		end


*/


//assign MOSI = MOSIdata[7]; //8 bit
	assign MOSI = MOSIdata[31];  //32 bit

	always @(posedge osc_clk)
		begin
			if (SCK_risingedge)
				begin
					//	MISOdata[7:0] <= {MISOdata[7:1], MISO};  //8 bit TX
					MISOdata[31:0] <= {MISOdata[30:0], MISO}; //32 bit TX
				end
		end


	always @(posedge SSEL)
		begin
			Registers[data_out[19:16]*16+:16] <= data_out[15:0];
		end

endmodule