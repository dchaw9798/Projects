module branch_comp 
import rv32im_types::*;
#(
    parameter ROB_DEPTH = 4
)
(
    input   logic [31:0]                        rs1_v,
    input   logic [31:0]                        rs2_v,
    input   logic [31:0]                        pc,
    input   logic [31:0]                        imm,
    input   logic [31:0]                        instr,
    input   logic [$clog2(ROB_DEPTH)-1:0]       branch_tag,
    input   logic                               comp_issue,

    output  logic [31:0]                        cdb_data,
    output  logic                               cdb_valid,
    output  logic [$clog2(ROB_DEPTH)-1:0]       cdb_tag,
    output  logic [31:0]                        pc_next,
    output  logic                               branch_resp,

    output  logic                               br_take,
    output  logic [31:0]                        pc_compare,
    output  logic [6:0]                         branch_pc_opcode    
);

    logic [6:0]                                 decode;
    logic [2:0]                                 funct3;
    
    assign funct3 = instr[14:12];
    assign decode = instr[6:0];
    assign pc_compare = pc;
    assign branch_pc_opcode = decode;

    always_comb begin
        cdb_data = '0;
        cdb_valid = '0;
        cdb_tag = '0;
        pc_next = pc + 'd4;
        branch_resp = '0;
        br_take = '0;
        if(comp_issue) begin
            if(decode == op_b_jal) begin
                branch_resp = 1'b1;
                cdb_data = pc + 'd4;
                cdb_valid = 1'b1;
                cdb_tag = branch_tag;
                pc_next = (pc + imm);
                br_take = 1'b1;
            end
            else if (decode == op_b_jalr) begin
                branch_resp = 1'b1;
                cdb_data = pc + 'd4;
                cdb_valid = 1'b1;
                cdb_tag = branch_tag;
                pc_next = (rs1_v + imm)& 32'hfffffffe;
                br_take = 1'b1;
            end
            else if (decode == op_b_br) begin
                branch_resp = 1'b1;
                if(funct3 == branch_f3_beq) begin
                    if(signed'(rs1_v) == signed'(rs2_v)) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm; 
                        br_take = 1'b1;                   
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
                if(funct3 == branch_f3_bne) begin
                    if(signed'(rs1_v) != signed'(rs2_v)) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm;  
                        br_take = 1'b1;                  
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
                if(funct3 == branch_f3_blt) begin
                    if(signed'(rs1_v) < signed'(rs2_v)) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm;  
                        br_take = 1'b1;                  
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
                if(funct3 == branch_f3_bgeu) begin
                    if((unsigned'(rs1_v) > unsigned'(rs2_v)) || (unsigned'(rs1_v) == unsigned'(rs2_v))) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm;  
                        br_take = 1'b1;                  
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
                if(funct3 == branch_f3_bge) begin
                    if((signed'(rs1_v) > signed'(rs2_v) || (signed'(rs1_v) == signed'(rs2_v)))) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm;   
                        br_take = 1'b1;                 
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
                if(funct3 == branch_f3_bltu) begin
                    if((unsigned'(rs1_v) < unsigned'(rs2_v))) begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + imm;  
                        br_take = 1'b1;                  
                    end
                    else begin
                        cdb_data = pc + 'd4;
                        cdb_valid = 1'b1;
                        cdb_tag = branch_tag;
                        pc_next = pc + 'd4;
                        br_take = '0;
                    end
                end
            end
        end
    end

endmodule
