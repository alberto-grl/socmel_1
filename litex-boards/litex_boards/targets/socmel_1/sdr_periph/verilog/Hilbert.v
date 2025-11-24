// 55-tap Hilbert Transform Filter with Windowing
// Single MAC (Multiply-Accumulate) architecture
// Input: 32-bit signed I and Q channels
// Q_out: Hilbert transformed Q signal (90° phase shift)
// I_out: I signal delayed by group delay (27 samples for 55-tap filter)

module Hilbert (
    input wire clk,
    input wire rst_n,
    input wire signed [31:0] I_in,
    input wire signed [31:0] Q_in,
    input wire data_valid,
    output reg signed [31:0] I_out,
    output reg signed [31:0] Q_out,
    output reg data_out_valid
);

    // Filter parameters
    parameter NUM_TAPS = 55;
    parameter COEFF_WIDTH = 20;
    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 52;  // Wide enough to prevent overflow (32 + 20)
    parameter GROUP_DELAY = 27 + 1; // (NUM_TAPS - 1) / 2 //TODO was 27 Why?
    
    // State machine states
    localparam IDLE = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam DONE = 2'd2;
    
    reg [1:0] state;
    reg [5:0] tap_count;  // 0 to 54
    
    // Delay line (shift register) for Q input samples
    reg signed [DATA_WIDTH-1:0] Q_delay_line [0:NUM_TAPS-1];
    
    // Delay line for I input to match group delay
    reg signed [DATA_WIDTH-1:0] I_delay_line [0:GROUP_DELAY-1];
    
    // Accumulator for MAC operation
    reg signed [ACC_WIDTH-1:0] accumulator;
    
    // Windowed Hilbert filter coefficients (20-bit)
    // Coefficients provided by user, already scaled
    reg signed [COEFF_WIDTH-1:0] coefficients [0:NUM_TAPS-1];

    reg signed [ACC_WIDTH-1:0] mac_product;  //TODO use exact size
    reg mac_cycle;
    
    // Initialize coefficients
    // User-provided coefficients with exact tap indices
    // 55-tap filter: M = 27 (center tap at index 27)
    initial begin
        coefficients[0]  = 20'sd989;     // k[0]
        coefficients[1]  = 20'sd0;
        coefficients[2]  = 20'sd1234;     // k[2]
        coefficients[3]  = 20'sd0;
        coefficients[4]  = 20'sd1871;     // k[4]
        coefficients[5]  = 20'sd0;
        coefficients[6]  = 20'sd2982;
        coefficients[7]  = 20'sd0;
        coefficients[8]  = 20'sd4661;     // k[8]
        coefficients[9]  = 20'sd0;
        coefficients[10] = 20'sd7025;     // k[10]
        coefficients[11] = 20'sd0;
        coefficients[12] = 20'sd10238;    // k[12]
        coefficients[13] = 20'sd0;
        coefficients[14] = 20'sd14551;    // k[14]
        coefficients[15] = 20'sd0;
        coefficients[16] = 20'sd20388;    // k[16]
        coefficients[17] = 20'sd0;
        coefficients[18] = 20'sd28556;    // k[18]
        coefficients[19] = 20'sd0;
        coefficients[20] = 20'sd40800;    // k[20]
        coefficients[21] = 20'sd0;
        coefficients[22] = 20'sd61703;    // k[22]
        coefficients[23] = 20'sd0;
        coefficients[24] = 20'sd108171;   // k[24]
        coefficients[25] = 20'sd0;
        coefficients[26] = 20'sd332734;   // k[26]
        coefficients[27] = 20'sd0;        // Center tap (always 0)
        coefficients[28] = -20'sd332734;  // k[28] - negative side
        coefficients[29] = 20'sd0;
        coefficients[30] = -20'sd108171;  // k[30] = -k[26]
        coefficients[31] = 20'sd0;
        coefficients[32] = -20'sd61703;  // k[32] = -k[24]
        coefficients[33] = 20'sd0;
        coefficients[34] = -20'sd40800;   // k[34] = -k[22]
        coefficients[35] = 20'sd0;
        coefficients[36] = -20'sd28556;   // k[36] = -k[20]
        coefficients[37] = 20'sd0;
        coefficients[38] = -20'sd20388;   // k[38] = -k[18]
        coefficients[39] = 20'sd0;
        coefficients[40] = -20'sd14551;   // k[40] = -k[16]
        coefficients[41] = 20'sd0;
        coefficients[42] = -20'sd10238;   // k[42] = -k[14]
        coefficients[43] = 20'sd0;
        coefficients[44] = -20'sd7025;   // k[44] = -k[12]
        coefficients[45] = 20'sd0;
        coefficients[46] = -20'sd4661;    // k[46] = -k[10]
        coefficients[47] = 20'sd0;
        coefficients[48] = -20'sd2982;    // k[48] = -k[8]
        coefficients[49] = 20'sd0;
        coefficients[50] = -20'sd1871;
        coefficients[51] = 20'sd0;
        coefficients[52] = -20'sd1234;    // k[52] = -k[4]
        coefficients[53] = 20'sd0;
        coefficients[54] = -20'sd989;    // k[54] = -k[2]
    end
    
    // Q channel delay line shift register
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_TAPS; i = i + 1) begin
                Q_delay_line[i] <= 32'sd0;
            end
        end else if (data_valid && state == IDLE) begin
            // Shift new sample into delay line
            Q_delay_line[0] <= Q_in;
            for (i = 1; i < NUM_TAPS; i = i + 1) begin
                Q_delay_line[i] <= Q_delay_line[i-1];
            end
        end
    end
    
    // I channel delay line (matches group delay of filter)
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < GROUP_DELAY; j = j + 1) begin
                I_delay_line[j] <= 32'sd0;
            end
        end else if (data_valid && state == IDLE) begin
            // Shift I input through delay line
            I_delay_line[0] <= I_in;
            for (j = 1; j < GROUP_DELAY; j = j + 1) begin
                I_delay_line[j] <= I_delay_line[j-1];
            end
        end
    end
    
    // MAC operation and state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tap_count <= 6'd0;
            accumulator <= 52'sd0;
            I_out <= 32'sd0;
            Q_out <= 32'sd0;
            data_out_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    data_out_valid <= 1'b0;
                    if (data_valid) begin
                        // Start MAC operation
                        state <= COMPUTE;
                        tap_count <= 6'd0;
                        accumulator <= 52'sd0;
                        mac_cycle <= 1'd0;
                    end
                end
                
                COMPUTE: begin
                    // Perform one MAC operation per clock cycle
                    // accumulator += Q_delay_line[tap_count] * coefficients[tap_count]
                    
                    if (~mac_cycle)
                        mac_product <= (Q_delay_line[tap_count] * coefficients[tap_count]);
                    else           
                        accumulator <= accumulator + mac_product;
                    if ((tap_count == NUM_TAPS - 1) && mac_cycle) begin
                        state <= DONE;
                    end else begin
                        mac_cycle <= ~mac_cycle;
                        if (mac_cycle)
                            tap_count <= tap_count + 6'd1;
                    end
                end
                
                DONE: begin
                    // Scale down Q result (divide by 2^18 for Q1.18 format)
                    // Take bits [49:18] to handle sign extension properly
                    Q_out <=  accumulator[49:18];  
                    
                    // Output delayed I channel
                    I_out <= 2 * I_delay_line[GROUP_DELAY-1 ]; //TODO had to shorten delay by 1. Why? //TODO added factor 2. Why is it needed?
                    
                    data_out_valid <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule



/*
module Hilbert (
 input  clk  ,
 input wire rst_n,
 input  data_valid  ,
 input  [31:0] Q_in,
 input  [31:0] I_in,
 output reg signed [31:0] Q_out,
 output reg signed [31:0] I_out,
 output reg data_out_valid
 );

integer TAPS;

integer TAPS_D;

parameter COEFF_WIDTH = 13;

parameter DATA_WIDTH = 32;

parameter N = 55;    // Number of filter taps, SHOULD BE ODD

parameter DELAY_TAPS = 28;
reg signed [COEFF_WIDTH-1:0] k[0:N/2-1];
reg signed [DATA_WIDTH-1:0] v_Q[0:N-1];
reg signed [DATA_WIDTH-1:0] v_I[0:DELAY_TAPS ];
reg signed [DATA_WIDTH + COEFF_WIDTH + 2:0] sum[0:N/2-1];
reg signed [DATA_WIDTH+5+COEFF_WIDTH:0] mac_result;
reg [7:0] tap_counter;


initial begin
   k[0] = 8 ;
   k[1] = 10 ;
   k[2] = 15 ;
   k[3] = 23 ;
   k[4] = 36 ;
   k[5] = 55 ;
   k[6] = 80 ;
   k[7] = 114 ;
   k[8] = 159 ;
   k[9] = 223 ;
   k[10] = 319 ;
   k[11] = 482 ;
   k[12] = 845 ;
   k[13] = 2599 ;
end


always @(posedge clk)
 begin
              if (tap_counter < N/4+1) begin
                 mac_result <= mac_result + (sum[tap_counter]);
                 tap_counter <= tap_counter + 1;
             end

   if ((data_valid) && (tap_counter >= N/4+1))
       begin
         // Output the result and reset MAC for the next sample
                 Q_out <= mac_result[DATA_WIDTH + COEFF_WIDTH-2:COEFF_WIDTH-1]; // Truncate to output width
                 I_out <= v_I[0];
                 mac_result <= 0;
                 tap_counter <= 0;

        sum[0] <= (v_Q[0] - v_Q[54]) * k[0] ;
        sum[1] <= (v_Q[2] - v_Q[52]) * k[1] ;
        sum[2] <= (v_Q[4] - v_Q[50]) * k[2] ;
        sum[3] <= (v_Q[6] - v_Q[48]) * k[3] ;
        sum[4] <= (v_Q[8] - v_Q[46]) * k[4] ;
        sum[5] <= (v_Q[10] - v_Q[44]) * k[5] ;
        sum[6] <= (v_Q[12] - v_Q[42]) * k[6] ;
        sum[7] <= (v_Q[14] - v_Q[40]) * k[7] ;
        sum[8] <= (v_Q[16] - v_Q[38]) * k[8] ;
        sum[9] <= (v_Q[18] - v_Q[36]) * k[9] ;
        sum[10] <= (v_Q[20] - v_Q[34]) * k[10] ;
        sum[11] <= (v_Q[22] - v_Q[32]) * k[11] ;
        sum[12] <= (v_Q[24] - v_Q[30]) * k[12] ;
        sum[13] <= (v_Q[26] - v_Q[28]) * k[13] ;

 for (TAPS = 0 ; TAPS < N-1; TAPS = TAPS + 1) begin
                    v_Q[TAPS] <= v_Q[TAPS+1];
                 end
                 v_Q[N-1] <= Q_in;

 for (TAPS_D = 0 ; TAPS_D < DELAY_TAPS; TAPS_D = TAPS_D + 1) begin
                    v_I[TAPS_D] <= v_I[TAPS_D+1];
                 end
                 v_I[DELAY_TAPS] <= I_in;

      end
   end
endmodule
*/


/*
module Hilbert (
 input  clk  ,
 input wire rst_n,
 input  data_valid  ,
 input  [31:0] Q_in,
 input  [31:0] I_in,
 output reg signed [31:0] Q_out,
 output reg signed [31:0] I_out,
 output reg data_out_valid
 );

integer TAPS;

integer TAPS_D;

parameter COEFF_WIDTH = 13;

parameter DATA_WIDTH = 32;

parameter N = 55;    // Number of filter taps, SHOULD BE ODD

parameter DELAY_TAPS = 28;
reg signed [COEFF_WIDTH-1:0] k[0:N/2-1];
reg signed [DATA_WIDTH-1:0] v_Q[0:N-1];
reg signed [DATA_WIDTH-1:0] v_I[0:DELAY_TAPS ];
reg signed [DATA_WIDTH + COEFF_WIDTH + 2:0] sum[0:N/2-1];
reg signed [DATA_WIDTH+5+COEFF_WIDTH:0] mac_result;
reg [7:0] tap_counter;


initial begin
   k[0] = 8 ;
   k[1] = 10 ;
   k[2] = 15 ;
   k[3] = 23 ;
   k[4] = 36 ;
   k[5] = 55 ;
   k[6] = 80 ;
   k[7] = 114 ;
   k[8] = 159 ;
   k[9] = 223 ;
   k[10] = 319 ;
   k[11] = 482 ;
   k[12] = 845 ;
   k[13] = 2599 ;
end


always @(posedge clk)
 begin
              if (tap_counter < N/4+1) begin
                 mac_result <= mac_result + (sum[tap_counter]);
                 tap_counter <= tap_counter + 1;
             end

   if ((data_valid) && (tap_counter >= N/4+1))
       begin
         // Output the result and reset MAC for the next sample
                 Q_out <= mac_result[DATA_WIDTH + COEFF_WIDTH-2:COEFF_WIDTH-1]; // Truncate to output width
                 I_out <= v_I[0];
                 mac_result <= 0;
                 tap_counter <= 0;

        sum[0] <= (v_Q[0] - v_Q[54]) * k[0] ;
        sum[1] <= (v_Q[2] - v_Q[52]) * k[1] ;
        sum[2] <= (v_Q[4] - v_Q[50]) * k[2] ;
        sum[3] <= (v_Q[6] - v_Q[48]) * k[3] ;
        sum[4] <= (v_Q[8] - v_Q[46]) * k[4] ;
        sum[5] <= (v_Q[10] - v_Q[44]) * k[5] ;
        sum[6] <= (v_Q[12] - v_Q[42]) * k[6] ;
        sum[7] <= (v_Q[14] - v_Q[40]) * k[7] ;
        sum[8] <= (v_Q[16] - v_Q[38]) * k[8] ;
        sum[9] <= (v_Q[18] - v_Q[36]) * k[9] ;
        sum[10] <= (v_Q[20] - v_Q[34]) * k[10] ;
        sum[11] <= (v_Q[22] - v_Q[32]) * k[11] ;
        sum[12] <= (v_Q[24] - v_Q[30]) * k[12] ;
        sum[13] <= (v_Q[26] - v_Q[28]) * k[13] ;

 for (TAPS = 0 ; TAPS < N-1; TAPS = TAPS + 1) begin
                    v_Q[TAPS] <= v_Q[TAPS+1];
                 end
                 v_Q[N-1] <= Q_in;

 for (TAPS_D = 0 ; TAPS_D < DELAY_TAPS; TAPS_D = TAPS_D + 1) begin
                    v_I[TAPS_D] <= v_I[TAPS_D+1];
                 end
                 v_I[DELAY_TAPS] <= I_in;

      end
   end
endmodule
*/

