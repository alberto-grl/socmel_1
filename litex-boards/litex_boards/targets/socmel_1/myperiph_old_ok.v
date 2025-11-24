module myperiph (
    input  wire        clk,
    input  wire [3:0]  csr_addr,
    input  wire [31:0] csr_wdata,
    input  wire        csr_we,
    output reg  [31:0] csr_rdata,

    input  wire [3:0]  buttons,
    output reg  [3:0]  leds
);

    reg [3:0] led_reg;

    always @(posedge clk) begin
        if (csr_we)
            led_reg <= csr_wdata[3:0];
        else
            led_reg <= buttons;  // buttons override when CSR is not writing

        leds <= led_reg;
        csr_rdata <= {28'd0, led_reg};
    end

endmodule
