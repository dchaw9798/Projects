module load_store_addr_adder
import rv32im_types::*;
 (
    //LS_RS side signal
    input   logic [31:0] rs_ls_rs1_data,
    input   logic [31:0] rs_ls_imm_data,
    input   logic        rs_ls_addr_adder_en,
    output  logic        rs_ls_addr_adder_resp,
    //LS_queue side signal
    output  logic        lsq_addr_valid,
    output  logic [31:0] lsq_addr //to LSQ
);

    //ls_adder_resp, lsq_valid logic
    always_comb begin
        rs_ls_addr_adder_resp   = rs_ls_addr_adder_en;
        lsq_addr_valid          = rs_ls_addr_adder_en;
    end    
 
    //load_store_addr logic
    always_comb begin
        lsq_addr = '0;
        if (rs_ls_addr_adder_en) begin
            lsq_addr = rs_ls_rs1_data + rs_ls_imm_data;
        end
    end


endmodule
