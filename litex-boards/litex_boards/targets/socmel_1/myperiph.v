/*
module myperiph (
    input  wire        clk,
    input  wire [4:0]  btn_n,
    output wire [5:0]  leds,

    input  wire        csr_we,
    input  wire [127:0] csr_wdata, // 4 registers x 32 bits
    output reg  [127:0] csr_rdata, // 4 registers x 32 bits
    input  wire [3:0]  csr_addr    // optional
);

    reg [31:0] reg0, reg1, reg2, reg3;

    always @(posedge clk) begin
        if (csr_we) begin
            case (csr_addr)
                4'd0: reg0 <= csr_wdata[31:0];
                4'd1: reg1 <= csr_wdata[63:32];
                4'd2: reg2 <= csr_wdata[95:64];
                4'd3: reg3 <= csr_wdata[127:96];
            endcase
        end

        csr_rdata[31:0]   <= btn_n;
        csr_rdata[63:32]  <= reg1;
        csr_rdata[95:64]  <= reg2;
        csr_rdata[127:96] <= reg3;
    end

    assign leds = reg0[3:0];

endmodule
*/

/*
 135*240 ST7789
https://it.aliexpress.com/item/1005006982497657.html?spm=a2g0o.productlist.main.22.129dXydRXydRE6&algo_pvid=1ea05d0e-607c-4a4f-82b1-2f8e8adc714b&algo_exp_id=1ea05d0e-607c-4a4f-82b1-2f8e8adc714b-21&pdp_ext_f=%7B%22order%22%3A%2260%22%2C%22eval%22%3A%221%22%7D&pdp_npi=4%40dis%21EUR%213.12%213.12%21%21%2125.55%2125.55%21%40211b876e17511487535847411e132d%2112000038935573662%21sea%21IT%21171955453%21X&curPageLogUid=iC2aaq77cCaZ&utparam-url=scene%3Asearch%7Cquery_from%3A
https://www.buydisplay.com/download/ic/ST7789.pdf?srsltid=AfmBOooS_XLm28dQVeqIw6UatzsCkWblh2SwJsV513ScmFPQkIHphwBJ
https://github.com/lupyuen/lupyuen.github.io/blob/master/src/display.md

Configured as 4-line serial interface 1

*/

// `define LED_CONTROL_LCD_PERIPH

module myperiph (
    input clk, // 48M
    input  wire rst,
    input  wire [4:0]  btn_n,
    
    `ifdef LED_CONTROL_LCD_PERIPH
    output wire [5:0]  leds,
    `endif

    input  wire          csr_we,
    input  wire [127:0] csr_wdata, // 4 registers x 32 bits
    output reg  [127:0] csr_rdata, // 4 registers x 32 bits
    input  wire [3:0]  csr_addr,    // optional
    
    output lcd_resetn,
    output lcd_bl,
    output lcd_clk,
    output lcd_cs,
    output lcd_rs,  //register select (same as WRX, DCX, Data is regarded as a command when WRX is low
                    //Data is regarded as a parameter or data when WRX is high 
                    output lcd_data
                    );

`define MODELTECH


reg [31:0] reg0, reg1, reg2, reg3;
reg [1:0] clk_divider;
reg test_reg;

always @(posedge clk) begin
    clk_divider <= clk_divider + 1;
  /*  if (csr_we) begin
        case (csr_addr)
            4'd0: transfer_data <= csr_wdata[8:0]; //bit 8 is 0 for command, 1 for parameter
                                                // for pixel write send  0x1nn 0x1ll (16 bit transfer as two 8 bit)
                                                4'd1: reg1 <= csr_wdata[63:32];
                                                4'd2: reg2 <= csr_wdata[95:64];
                                                4'd3: reg3 <= csr_wdata[127:96];
        endcase
    end
*/
    if (csr_we ==  1'b1) begin
            transfer_data <= csr_wdata[8:0]; //bit 8 is 0 for command, 1 for parameter
                                                // for pixel write send  0x1nn 0x1ll (16 bit transfer as two 8 bit)
             reg1 <= csr_wdata[63:32];
             reg2 <= csr_wdata[95:64];
             reg3 <= csr_wdata[127:96];
    end
   

                                        csr_rdata[31:0]   <= btn_n;
                                        csr_rdata[63:32]  <= reg1;
                                        csr_rdata[95:64]  <= reg2;
                                        csr_rdata[127:96] <= reg3;
                                    end
`ifdef LED_CONTROL_LCD_PERIPH
                                    assign leds[0] = test_reg;
                                    assign leds[3:1] = reg2[2:0];
`endif



                                    assign lcd_bl = 'b0;

                                    localparam MAX_CMDS = 69;

                                    wire [8:0] init_cmd[MAX_CMDS:0];

assign init_cmd[ 0] = 9'h036; //MADCTL
assign init_cmd[ 1] = 9'h170;
assign init_cmd[ 2] = 9'h03A; //COLMOD
assign init_cmd[ 3] = 9'h105; // ‘101’ = 16bit/pixel (RGB-5-6-5)
assign init_cmd[ 4] = 9'h0B2; //PORCTRL
assign init_cmd[ 5] = 9'h10C;
assign init_cmd[ 6] = 9'h10C;
assign init_cmd[ 7] = 9'h100;
assign init_cmd[ 8] = 9'h133;
assign init_cmd[ 9] = 9'h133;
assign init_cmd[10] = 9'h0B7; //GCTRL
assign init_cmd[11] = 9'h135;
assign init_cmd[12] = 9'h0BB; //VCOMS
assign init_cmd[13] = 9'h119;
assign init_cmd[14] = 9'h0C0; //LCMCTRL
assign init_cmd[15] = 9'h12C;
assign init_cmd[16] = 9'h0C2; //VDVVRHEN
assign init_cmd[17] = 9'h101;
assign init_cmd[18] = 9'h0C3; //VRHS
assign init_cmd[19] = 9'h112;
assign init_cmd[20] = 9'h0C4; // VDVS
assign init_cmd[21] = 9'h120;
assign init_cmd[22] = 9'h0C6; //FRCTRL2 
assign init_cmd[23] = 9'h10F;
assign init_cmd[24] = 9'h0D0;
assign init_cmd[25] = 9'h1A4;
assign init_cmd[26] = 9'h1A1;
assign init_cmd[27] = 9'h0E0;
assign init_cmd[28] = 9'h1D0;
assign init_cmd[29] = 9'h104;
assign init_cmd[30] = 9'h10D;
assign init_cmd[31] = 9'h111;
assign init_cmd[32] = 9'h113;
assign init_cmd[33] = 9'h12B;
assign init_cmd[34] = 9'h13F;
assign init_cmd[35] = 9'h154;
assign init_cmd[36] = 9'h14C;
assign init_cmd[37] = 9'h118;
assign init_cmd[38] = 9'h10D;
assign init_cmd[39] = 9'h10B;
assign init_cmd[40] = 9'h11F;
assign init_cmd[41] = 9'h123;
assign init_cmd[42] = 9'h0E1;
assign init_cmd[43] = 9'h1D0;
assign init_cmd[44] = 9'h104;
assign init_cmd[45] = 9'h10C;
assign init_cmd[46] = 9'h111;
assign init_cmd[47] = 9'h113;
assign init_cmd[48] = 9'h12C;
assign init_cmd[49] = 9'h13F;
assign init_cmd[50] = 9'h144;
assign init_cmd[51] = 9'h151;
assign init_cmd[52] = 9'h12F;
assign init_cmd[53] = 9'h11F;
assign init_cmd[54] = 9'h11F;
assign init_cmd[55] = 9'h120;
assign init_cmd[56] = 9'h123;
assign init_cmd[57] = 9'h021;
assign init_cmd[58] = 9'h029;

assign init_cmd[59] = 9'h02A; // column
assign init_cmd[60] = 9'h100;
assign init_cmd[61] = 9'h128;
assign init_cmd[62] = 9'h101;
assign init_cmd[63] = 9'h117; //117
assign init_cmd[64] = 9'h02B; // row
assign init_cmd[65] = 9'h100;
assign init_cmd[66] = 9'h135;
assign init_cmd[67] = 9'h100;
assign init_cmd[68] = 9'h1BB; //1BB
assign init_cmd[69] = 9'h02C; // start

localparam INIT_RESET   = 4'b0000; // delay 100ms while reset
localparam INIT_PREPARE = 4'b0001; // delay 200ms after reset
localparam INIT_WAKEUP  = 4'b0010; // write cmd 0x11 MIPI_DCS_EXIT_SLEEP_MODE
localparam INIT_SNOOZE  = 4'b0011; // delay 120ms after wakeup
localparam INIT_WORKING = 4'b0100; // write command & data
localparam WAIT_FOR_DATA    = 4'b0101; // wait for a CSR update
localparam SEND_DATA    = 4'b0110; // send commands and parameters to LCD

`ifdef MODELTECH

localparam CNT_100MS = 32'd2700000;
localparam CNT_120MS = 32'd3240000;
localparam CNT_200MS = 32'd5400000;

`else

// speedup for simulation
localparam CNT_100MS = 32'd27;
localparam CNT_120MS = 32'd32;
localparam CNT_200MS = 32'd54;

`endif


reg [ 3:0] init_state;
reg [ 6:0] cmd_index;
reg [31:0] clk_cnt;
reg [ 4:0] bit_loop;

reg lcd_cs_r;
reg lcd_rs_r;
reg lcd_reset_r;

reg [7:0] spi_data;
reg [5:0] grey_val;
reg grey_inc;

assign lcd_resetn = lcd_reset_r;
assign lcd_clk    = ~clk; //clk_divider[1]; //~clk;
assign lcd_cs     = lcd_cs_r;
assign lcd_rs     = lcd_rs_r;
assign lcd_data   = spi_data[7]; // MSB


// Display is 135 x 240, pixel_cnt max is 32400
reg [8:0] transfer_data;

always@(posedge clk  or posedge rst) begin
    if (rst) begin
        clk_cnt <= 0;
        cmd_index <= 0;
        init_state <= INIT_RESET;

        lcd_cs_r <= 1;
        lcd_rs_r <= 1;
        lcd_reset_r <= 0;
        spi_data <= 8'hFF;
        bit_loop <= 0;

    end else begin
//    if (clk_divider == 3) begin
    case (init_state)

        INIT_RESET : begin
            if (clk_cnt == CNT_100MS) begin
                clk_cnt <= 0;
                init_state <= INIT_PREPARE;
                lcd_reset_r <= 1;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end

        INIT_PREPARE : begin
            if (clk_cnt == CNT_200MS) begin
                clk_cnt <= 0;
                init_state <= INIT_WAKEUP;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end

        INIT_WAKEUP : begin
            if (bit_loop == 0) begin
                    // start
                    lcd_cs_r <= 0;
                    lcd_rs_r <= 0;
                    spi_data <= 8'h11; // exit sleep
                    bit_loop <= bit_loop + 1;
                end else if (bit_loop == 8) begin
                    // end
                    lcd_cs_r <= 1;
                    lcd_rs_r <= 1;
                    bit_loop <= 0;
                    init_state <= INIT_SNOOZE;
                end else begin
                    // loop
                    spi_data <= { spi_data[6:0], 1'b1 };
                    bit_loop <= bit_loop + 1'd1;
                end
        end

        INIT_SNOOZE : begin
                if (clk_cnt == CNT_120MS) begin
                    clk_cnt <= 0;
                    init_state <= INIT_WORKING;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
        end

        INIT_WORKING : begin
                if (cmd_index == MAX_CMDS + 1) begin
                    init_state <= WAIT_FOR_DATA;
                end else begin
                    if (bit_loop == 0) begin
                        // start
                        lcd_cs_r <= 0;
                        lcd_rs_r <= init_cmd[cmd_index][8];
                        spi_data <= init_cmd[cmd_index][7:0];
                        bit_loop <= bit_loop + 1;
                    end else if (bit_loop == 8) begin
                        // end
                        lcd_cs_r <= 1;
                        lcd_rs_r <= 1;
                        bit_loop <= 0;
                        cmd_index <= cmd_index + 1'd1; // next command
                    end else begin
                        // loop
                        spi_data <= { spi_data[6:0], 1'b1 };
                        bit_loop <= bit_loop + 1'd1;
                    end
                end
            end

            WAIT_FOR_DATA : begin
                if (csr_we ==  1'b1) begin             
                    init_state <= SEND_DATA;
                end
            end 

            SEND_DATA : begin
                if (bit_loop == 0) begin
                            // start
                            lcd_cs_r <= 0;
                            lcd_rs_r <= transfer_data[8];
                            spi_data <= transfer_data[7:0];
                            bit_loop <= bit_loop + 1;
                            test_reg <= 1;
                end else begin
                            if (bit_loop == 8) begin
                                lcd_cs_r <= 1;
                                lcd_rs_r <= 1;
                                bit_loop <= 0;
                                init_state <= WAIT_FOR_DATA;
                                test_reg <= 0;

                            end else begin
                            // loop
                                spi_data <= { spi_data[6:0], 1'b1 };
                                bit_loop <= bit_loop + 1'd1;
                                end
                end
            end
    endcase

//    end
end
end
endmodule



