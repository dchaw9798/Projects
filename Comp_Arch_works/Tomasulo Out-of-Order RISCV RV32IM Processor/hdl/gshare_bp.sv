module gshare_bp 
import rv32im_types::*;
#(
    parameter GHR_LENGTH = 30,
    parameter PHT_DEPTH = 6
)(
    input logic         clk,
    input logic         rst,
    input logic         flush,
    input logic         br_take,
    input logic         rob_commit,
    input logic [31:0]  commit_pc,
    input logic [6:0]   commit_opcode,
    input logic [31:0]  pc,

    output logic        predict_take

);

localparam PHT_NUM_ELEMENT = 2 ** PHT_DEPTH;

logic [GHR_LENGTH-1:0] GHR;
logic [1:0] PHT [PHT_NUM_ELEMENT];

always_ff @(posedge clk) begin
    if (rst) begin
        GHR <= '0;
        for (int i = 0; i < PHT_NUM_ELEMENT; i++) begin
            PHT[i] <= 2'b01;
        end
    end 
    else begin
        if (rob_commit) begin
            if (commit_opcode == op_b_br) begin
                GHR <= {GHR[GHR_LENGTH-2:0], br_take};
                if (flush) begin
                    if (PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]][1]) begin
                        PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] <= PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] - 2'b01;
                    end 
                    else begin
                        PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] <= PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] + 2'b01;
                    end
                end 
                else begin
                    if (PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] == 2'b10) begin
                        PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] <= 2'b11;
                    end 
                    else if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] == 2'b01) begin
                        PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] <= 2'b00;
                    end
                    else if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] == 2'b00) begin
                        PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] <= 2'b00;
                    end
                    else if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] == 2'b11) begin
                        PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] <= 2'b11;
                    end
                end
            end
        end
    end
end

always_comb begin
    predict_take = '0;
    if (PHT[GHR[PHT_DEPTH-1:0] ^ pc[PHT_DEPTH+1:2]][1]) begin
        predict_take = '1;
    end
end

endmodule
