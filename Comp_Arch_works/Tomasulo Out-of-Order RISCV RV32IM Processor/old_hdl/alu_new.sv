module alu_new
import rv32im_types::*;
#(
    parameter ROB_DEPTH = 8
)
(
    input   logic [31:0]                  rs_instr,
    input   logic [31:0]                  rs_data_A,
    input   logic [31:0]                  rs_data_B,
    input   logic                         rs_alu_en, //enable this computation unit
    input   logic [$clog2(ROB_DEPTH)-1:0] rs_dest_tag,
    
    output  logic                         alu_resp,
    output  logic [31:0]                  alu_result, //connect to data_CDB
    output  logic                         alu_valid_CDB,
    output  logic [$clog2(ROB_DEPTH)-1:0] alu_tag_CDB
);
    logic [6:0] opcode;
    logic [2:0] funct3;

    logic signed   [31:0] signed_A;
    logic signed   [31:0] signed_B;
    logic unsigned [31:0] unsigned_A;
    logic unsigned [31:0] unsigned_B;

    assign opcode       = rs_instr[6:0];
    assign funct3       = rs_instr[14:12];
    assign signed_A     = signed'(rs_data_A);
    assign signed_B     = signed'(rs_data_B);
    assign unsigned_A   = unsigned'(rs_data_A);
    assign unsigned_B   = unsigned'(rs_data_B);

    always_comb begin
        alu_result    = '0;
        alu_resp      = '0;
        alu_valid_CDB = '0;
        alu_tag_CDB   = '0;

        if(rs_alu_en) begin
            unique case (opcode)
                op_b_lui: begin
                    alu_result    = rs_data_B;
                    alu_resp      = 1'b1;
                    alu_valid_CDB = 1'b1;
                    alu_tag_CDB   = rs_dest_tag;
                end
                op_b_auipc: begin
                    alu_result    = rs_data_B + rs_data_A;
                    alu_resp      = 1'b1;
                    alu_valid_CDB = 1'b1;
                    alu_tag_CDB   = rs_dest_tag;
                end      
                op_b_imm: begin
                    alu_resp        = 1'b1;
                    alu_valid_CDB   = 1'b1;
                    alu_tag_CDB     = rs_dest_tag;
                    unique case (funct3)
                        arith_f3_add: alu_result = unsigned_A + unsigned_B;
                        arith_f3_sll: alu_result = unsigned_A << unsigned_B[4:0];
                        arith_f3_slt: alu_result = (signed_A < signed_B);
                        arith_f3_sltu: alu_result = (unsigned_A < unsigned_B);
                        arith_f3_xor: alu_result = unsigned_A ^ unsigned_B;
                        arith_f3_sr: begin
                            if(~rs_instr[30]) begin
                                alu_result = unsigned_A >> unsigned_B[4:0];
                            end
                            else begin
                                alu_result = unsigned'(signed_A >>> unsigned_B[4:0]);
                            end
                        end
                        arith_f3_or: alu_result = unsigned_A | unsigned_B;
                        arith_f3_and: alu_result = unsigned_A & unsigned_B;
                        default: alu_result = 'x;
                    endcase
                end
                op_b_reg: begin
                    alu_resp = 1'b1;
                    alu_valid_CDB = 1'b1;
                    alu_tag_CDB = rs_dest_tag;
                    unique case (funct3)
                        arith_f3_add: begin
                            if(~rs_instr[30]) begin
                                alu_result = unsigned_A + unsigned_B;
                            end
                            else begin
                                alu_result = unsigned_A - unsigned_B;
                            end
                        end                                
                        arith_f3_sll: alu_result = unsigned_A << unsigned_B[4:0];
                        arith_f3_slt: alu_result = (signed_A < signed_B);
                        arith_f3_sltu: alu_result = (unsigned_A < unsigned_B);
                        arith_f3_xor: alu_result = unsigned_A ^ unsigned_B;
                        arith_f3_sr: begin
                            if(~rs_instr[30]) begin
                                alu_result = unsigned_A >> unsigned_B[4:0];
                            end
                            else begin
                                alu_result = unsigned'(signed_A >>> unsigned_B[4:0]);
                            end
                        end
                        arith_f3_or: alu_result = unsigned_A | unsigned_B;
                        arith_f3_and: alu_result = unsigned_A & unsigned_B;
                        default: alu_result = 'x;
                    endcase
                end
                default: begin
                    alu_result = '0;
                    alu_resp = '0;
                    alu_valid_CDB = '0;
                    alu_tag_CDB = '0;
                end
            endcase
        end
    end

endmodule
