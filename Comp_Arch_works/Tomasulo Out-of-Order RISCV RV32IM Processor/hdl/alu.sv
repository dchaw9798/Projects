module alu
  import rv32im_types::*;
#(
    parameter ROB_DEPTH = 4
)
 (
    input logic [31:0] alu_instr_in,
    input logic [31:0] rs1_v,
    input logic [31:0] rs2_v,
    input logic alu_en,
    input logic [$clog2(ROB_DEPTH)-1:0] rob_tag,
    
    output logic alu_resp,
    output logic [31:0] alu_result,
    output logic cdb_valid,
    output logic [$clog2(ROB_DEPTH)-1:0] cdb_tag
);

    logic [2:0] funct3;
    assign funct3 = alu_instr_in[14:12];
    logic [6:0] opcode;
    assign opcode = alu_instr_in[6:0];

    logic signed   [31:0] rs1_sv;
    logic signed   [31:0] rs2_sv;
    logic unsigned [31:0] rs1_uv;
    logic unsigned [31:0] rs2_uv;

    assign rs1_sv = signed'(rs1_v);
    assign rs2_sv = signed'(rs2_v);
    assign rs1_uv = unsigned'(rs1_v);
    assign rs2_uv = unsigned'(rs2_v);

    always_comb begin
        alu_result = '0;
        alu_resp = '0;
        cdb_valid = '0;
        cdb_tag = '0;

        if(alu_en) begin
            unique case (opcode)
                op_b_lui: begin
                    alu_result = rs2_v;
                    alu_resp = 1'b1;
                    cdb_valid = 1'b1;
                    cdb_tag = rob_tag;
                end
                op_b_auipc: begin
                    alu_result = rs2_v + rs1_v;
                    alu_resp = 1'b1;
                    cdb_valid = 1'b1;
                    cdb_tag = rob_tag;
                end      
                op_b_imm: begin
                    alu_resp = 1'b1;
                    cdb_valid = 1'b1;
                    cdb_tag = rob_tag;
                    unique case (funct3)
                        arith_f3_add: alu_result = rs1_uv + rs2_uv;
                        arith_f3_sll: alu_result = rs1_uv << rs2_uv[4:0];
                        arith_f3_slt: alu_result = {31'b0, (rs1_sv < rs2_sv)};
                        arith_f3_sltu: alu_result = {31'b0, (rs1_uv < rs2_uv)};
                        arith_f3_xor: alu_result = rs1_uv ^ rs2_uv;
                        arith_f3_sr: begin
                            if(~alu_instr_in[30]) begin
                                alu_result = rs1_uv >> rs2_uv[4:0];
                            end
                            else begin
                                alu_result = unsigned'(rs1_sv >>> rs2_uv[4:0]);
                            end
                        end
                        arith_f3_or: alu_result = rs1_uv | rs2_uv;
                        arith_f3_and: alu_result = rs1_uv & rs2_uv;
                        default: alu_result = 'x;
                    endcase
                end
                op_b_reg: begin
                    alu_resp = 1'b1;
                    cdb_valid = 1'b1;
                    cdb_tag = rob_tag;
                    unique case (funct3)
                        arith_f3_add: begin
                            if(~alu_instr_in[30]) begin
                                alu_result = rs1_uv + rs2_uv;
                            end
                            else begin
                                alu_result = rs1_uv - rs2_uv;
                            end
                        end                                
                        arith_f3_sll: alu_result = rs1_uv << rs2_uv[4:0];
                        arith_f3_slt: alu_result = {31'b0, (rs1_sv < rs2_sv)};
                        arith_f3_sltu: alu_result = {31'b0, (rs1_uv < rs2_uv)};
                        arith_f3_xor: alu_result = rs1_uv ^ rs2_uv;
                        arith_f3_sr: begin
                            if(~alu_instr_in[30]) begin
                                alu_result = rs1_uv >> rs2_uv[4:0];
                            end
                            else begin
                                alu_result = unsigned'(rs1_sv >>> rs2_uv[4:0]);
                            end
                        end
                        arith_f3_or: alu_result = rs1_uv | rs2_uv;
                        arith_f3_and: alu_result = rs1_uv & rs2_uv;
                        default: alu_result = 'x;
                    endcase
                end
                default: begin
                    alu_result = '0;
                    alu_resp = '0;
                    cdb_valid = '0;
                    cdb_tag = '0;
                end
            endcase
        end
    end

endmodule
