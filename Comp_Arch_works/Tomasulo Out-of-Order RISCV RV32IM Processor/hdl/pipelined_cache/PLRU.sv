module PLRU
import rv32im_types::*; 
(
    input   logic           hit,
    input   logic   [2:0]   PLRU_rdata,
    input   logic   [1:0]   way_hit, 
    output  logic   [2:0]   PLRU_update,
    output  logic   [1:0]   way_replace
);

    
    // if hit, then update
    always_comb begin 
        PLRU_update = PLRU_rdata;
        if (hit) begin
            case (way_hit)
                way_A: begin 
                    PLRU_update = {1'b0, 1'b0, PLRU_rdata[0]};
                end 
                way_B: begin 
                    PLRU_update = {1'b0, 1'b1, PLRU_rdata[0]};
                end
                way_C: begin
                    PLRU_update = {1'b1, PLRU_rdata[1], 1'b0};
                end 
                way_D: begin 
                    PLRU_update = {1'b1, PLRU_rdata[1], 1'b1};
                end 
            endcase
        end
        else begin
            PLRU_update = PLRU_rdata;
        end
    end 

    always_comb begin 
        if (~PLRU_rdata[2]) begin
            if (~PLRU_rdata[0]) begin
                way_replace = way_D;
            end
            else begin
                way_replace = way_C;
            end
        end
        else begin
            if (~PLRU_rdata[1]) begin
                way_replace = way_B;
            end
            else begin
                way_replace = way_A;
            end
        end
    
    end 

endmodule
