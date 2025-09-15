module Pipeline_Reg
import rv32im_types::*;
(
    input   logic           clk,
    input   logic           rst,

    //input   logic           stall,
    input   logic   [31:0]  ufp_addr_0,
    input   logic   [3:0]   ufp_rmask_0,
    input   logic   [3:0]   ufp_wmask_0,
    input   logic   [31:0]  ufp_wdata_0,
    input   logic   [1:0]   state,
    //input   logic           csb_0,
    //input   logic           ufp_rw_0,

    output  logic   [31:0]  ufp_addr_1,
    output  logic   [3:0]   ufp_rmask_1,
    output  logic   [3:0]   ufp_wmask_1,
    output  logic   [31:0]  ufp_wdata_1,
    output  logic           csb_1
    //output  logic           ufp_rw_1
);

    always_ff @(posedge clk) begin
        if (rst) begin
            ufp_addr_1    <= '0;
            ufp_rmask_1   <= '0;
            ufp_wmask_1   <= '0;
            ufp_wdata_1   <= '0;
            //csb_1         <= 1'b1;

        end


        else begin
            ufp_addr_1    <= ufp_addr_0;
            ufp_rmask_1   <= ufp_rmask_0;
            ufp_wmask_1   <= ufp_wmask_0;
            ufp_wdata_1   <= ufp_wdata_0; 
            //csb_1         <= csb_0;
        end
    end

    always_comb begin
        if (state != 2'b00) begin
            csb_1 = 1'b0;
        end
        else begin
            csb_1 = 1'b1;
        end
    end



endmodule : Pipeline_Reg
