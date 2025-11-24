        
        module myperiph2 (
            input  wire        clk,
        //    input  wire [4:0]  btn_n,
           
            input  wire        csr2_we,
            input  wire [127:0] csr2_wdata, // 4 registers x 32 bits
            output reg  [127:0] csr2_rdata, // 4 registers x 32 bits
            input  wire [3:0]  csr2_addr    // optional
        );

            reg [31:0] reg0, reg1, reg2, reg3;

            always @(posedge clk) begin
                if (csr2_we) begin
   /*                 case (csr2_addr)
                        4'd0: reg0 <= csr2_wdata[31:0];
                        4'd1: reg1 <= csr2_wdata[63:32];
                        4'd2: reg2 <= csr2_wdata[95:64];
                        4'd3: reg3 <= csr2_wdata[127:96];
                    endcase*/
                        reg0 <= csr2_wdata[31:0];
                        reg1 <= csr2_wdata[63:32];
                        reg2 <= csr2_wdata[95:64];
                        reg3 <= csr2_wdata[127:96];
                end

                csr2_rdata[31:0]   <= reg1 + 256;
                csr2_rdata[63:32]  <= reg0;
                csr2_rdata[95:64]  <= reg2;
                csr2_rdata[127:96] <= reg3;
            end


        endmodule
        
