module decoder
import rv32im_types::*;
#(
    parameter ROB_DEPTH = 8
)
(   
    //IQ side signal
    input   logic [31:0]                  iq_instr,
    input   logic [31:0]                  iq_pc,
    input   logic [31:0]                  iq_pc_next,
    input   logic                         iq_valid,
    input   logic                         iq_empty,


    
    output  logic                         iq_issue,


    //ROB side signal

    output  logic                         rob_valid,
    output  logic [31:0]                  rob_instr,
    output  logic [4:0]                   rob_rs1_s,
    output  logic [4:0]                   rob_rs2_s,
    output  logic [4:0]                   rob_rd_s,
    output  logic                         rob_regf_we,
    output  logic [31:0]                  rob_pc,
    output  logic [31:0]                  rob_pc_next,
    output  logic                         rob_pc_next_valid, //indicate whether this pc_next is valid. for branch or jump, pc_next_valid should be 0. 
    
    
    input   logic                         rob_full,
    input   logic                         rob_commit,
    input   logic [31:0]                  rob_commit_rd_v,
    input   logic [$clog2(ROB_DEPTH)-1:0] rob_commit_tag,

    //RegFile side signal
    input   logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rs1,
    input   logic [31:0]                  regf_data_rs1,
    input   logic                         regf_ready_rs1,
    input   logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rs2,
    input   logic [31:0]                  regf_data_rs2,
    input   logic                         regf_ready_rs2,
    input   logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rd,

    output  logic [4:0]                   regf_rs1_s,
    output  logic [4:0]                   regf_rs2_s,
    
    //RS side signal
    output  logic                         rs_alu_valid,
    output  logic                         rs_mul_div_valid,
    output  logic                         rs_load_store_valid,
    output  logic                         rs_branch_valid,

    input   logic                         rs_alu_full, //tell instruction queue this rs is full
    input   logic                         rs_mul_div_full,
    input   logic                         rs_load_store_full,
    input   logic                         rs_branch_full,


    output  logic [31:0]                  rs_instr,
    output  logic [$clog2(ROB_DEPTH)-1:0] rs_tag_dest, //destination tag (ROB value)
    //output  logic [5:0]                   rs_alu_ctrl, //not yet determined how to encode

    output  logic [$clog2(ROB_DEPTH)-1:0] rs_tag_A, //ROB tag of source A
    output  logic [31:0]                  rs_data_A,
    output  logic                         rs_ready_A, //when data A is available

    output  logic [$clog2(ROB_DEPTH)-1:0] rs_tag_B, //ROB tag of source B
    output  logic [31:0]                  rs_data_B,
    output  logic                         rs_ready_B, //when data B is available

    output  logic [31:0]                  rs_imm,
    output  logic [31:0]                  rs_pc,

    //LSQ side signal
    input   logic                         lsq_full,
    input   logic                         lsq_load_rs_full
);

    //instruction assign
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [6:0]  opcode;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [31:0] shamt;
 
    assign funct3 = iq_instr[14:12];
    assign funct7 = iq_instr[31:25];
    assign opcode = iq_instr[6:0];
    assign i_imm  = {{21{iq_instr[31]}}, iq_instr[30:20]};
    assign s_imm  = {{21{iq_instr[31]}}, iq_instr[30:25], iq_instr[11:7]};
    assign b_imm  = {{20{iq_instr[31]}}, iq_instr[7], iq_instr[30:25], iq_instr[11:8], 1'b0};
    assign u_imm  = {iq_instr[31:12], 12'h000};
    assign j_imm  = {{12{iq_instr[31]}}, iq_instr[19:12], iq_instr[20], iq_instr[30:21], 1'b0};
    assign shamt  = {27'b0, iq_instr[24:20]};
    

    //decode instruction
    always_comb begin
        iq_issue            = 1'b0;
        
        rs_alu_valid        = '0;
        rs_mul_div_valid    = '0;
        rs_load_store_valid = '0;
        rs_branch_valid     = '0;
        rs_instr            = '0;
        rs_tag_dest         = '0;
        rs_tag_A            = '0;
        rs_data_A           = '0;
        rs_ready_A          = 1'b0;
        rs_tag_B            = '0;
        rs_data_B           = '0;
        rs_ready_B          = 1'b0;
        rs_imm              = '0;
        rs_pc               = '0;

        regf_rs1_s          = iq_instr[19:15];
        regf_rs2_s          = iq_instr[24:20];
        
        rob_valid           = 1'b0;
        rob_instr           = '0;
        rob_rs1_s           = iq_instr[19:15];
        rob_rs2_s           = iq_instr[24:20];
        rob_rd_s            = iq_instr[11:7];
        rob_regf_we         = 1'b0;
        rob_pc              = iq_pc;
        rob_pc_next         = iq_pc_next;
        rob_pc_next_valid   = 1'b1;


        unique case (opcode)
            op_b_lui  : begin
                if (iq_valid && !rs_alu_full && !iq_empty && !rob_full) begin
                    iq_issue        = 1'b1;
                    
                    rs_alu_valid    = 1'b1;
                    rs_instr        = iq_instr;
                    rs_tag_dest     = regf_tag_rd;
                    rs_tag_A        = '0;
                    rs_data_A       = '0;
                    rs_ready_A      = 1'b1;
                    rs_tag_B        = '0;
                    rs_data_B       = u_imm;
                    rs_ready_B      = 1'b1;


                    regf_rs1_s      = '0;
                    regf_rs2_s      = '0;
                    
                    rob_valid       = 1'b1;
                    rob_instr       = iq_instr;
                    rob_rs1_s       = '0;
                    rob_rs2_s       = '0;
                    rob_rd_s        = iq_instr[11:7];
                    rob_regf_we     = 1'b1;
                    rob_pc          = iq_pc;
                    rob_pc_next     = iq_pc_next;

                end

                
            end
            op_b_auipc: begin //signed imm + pc
                if (iq_valid && !rs_alu_full && !iq_empty && !rob_full) begin
                    iq_issue        = 1'b1;

                    rs_alu_valid    = 1'b1;
                    rs_instr        = iq_instr;
                    rs_tag_dest     = regf_tag_rd;
                    rs_tag_A        = '0;
                    rs_data_A       = iq_pc;
                    rs_ready_A      = 1'b1;
                    rs_tag_B        = '0;
                    rs_data_B       = u_imm;
                    rs_ready_B      = 1'b1;

                    regf_rs1_s      = '0;
                    regf_rs2_s      = '0;

                    rob_valid       = 1'b1;
                    rob_instr       = iq_instr;
                    rob_rs1_s       = '0;
                    rob_rs2_s       = '0;
                    rob_rd_s        = iq_instr[11:7];
                    rob_regf_we     = 1'b1;
                    rob_pc          = iq_pc;
                    rob_pc_next     = iq_pc_next;

                end
               
            end
            op_b_jal  : begin //signed imm<<1 + pc //still need to store pc+4 to rd_v of regf, no datapath yet
                if (iq_valid && !rs_branch_full && !iq_empty && !rob_full) begin
                    iq_issue          = 1'b1;

                    rs_branch_valid   = 1'b1;
                    rs_instr          = iq_instr;
                    rs_tag_dest       = regf_tag_rd;
                    rs_tag_A          = '0;
                    rs_data_A         = '0;
                    rs_ready_A        = 1'b1;
                    rs_tag_B          = '0;
                    rs_data_B         = '0;
                    rs_ready_B        = 1'b1;
                    rs_pc             = iq_pc;
                    rs_imm            = j_imm;

                    regf_rs1_s        = '0;
                    regf_rs2_s        = '0;

                    rob_valid         = 1'b1;
                    rob_instr         = iq_instr;
                    rob_rs1_s         = '0;
                    rob_rs2_s         = '0;
                    rob_rd_s          = iq_instr[11:7];
                    rob_regf_we       = 1'b1;
                    rob_pc            = iq_pc;
                    rob_pc_next       = iq_pc_next;
                    rob_pc_next_valid = 1'b0;
                end
                
            end
            op_b_jalr : begin //signed imm + rs1 and set result LSB =0, no data path to store pc_4 to rd_v of regf yet
                if (iq_valid && !rs_branch_full && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;                                     
                    end
                    else begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                    end

                    iq_issue              = 1'b1;

                    rs_branch_valid       = 1'b1;
                    rs_instr              = iq_instr;
                    rs_tag_dest           = regf_tag_rd;

                    rs_tag_B              = '0;
                    rs_data_B             = '0;
                    rs_ready_B            = 1'b1;

                    rs_pc                 = iq_pc;
                    rs_imm                = i_imm;

                    regf_rs1_s            = iq_instr[19:15];
                    regf_rs2_s            = '0;

                    rob_valid             = 1'b1;
                    rob_instr             = iq_instr;
                    rob_rs1_s             = iq_instr[19:15];
                    rob_rs2_s             = '0;
                    rob_rd_s              = iq_instr[11:7];
                    rob_regf_we           = 1'b1;
                    rob_pc                = iq_pc;
                    rob_pc_next           = iq_pc_next;
                    rob_pc_next_valid     = 1'b0;

                end
                
            end
            
            
            op_b_br   : begin
                if (iq_valid && !rs_branch_full && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1; 
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                    
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs2) && (rob_commit_tag != regf_tag_rs1) && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag != regf_tag_rs2) && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;     
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;
                                                       
                    end
                    else begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                 
                    end   

                    iq_issue              = 1'b1;

                    rs_branch_valid       = 1'b1;
                    rs_instr              = iq_instr;
                    rs_tag_dest           = regf_tag_rd;

                    rs_imm                = b_imm;
                    rs_pc                 = iq_pc;

                    regf_rs1_s            = iq_instr[19:15];
                    regf_rs2_s            = iq_instr[24:20];

                    rob_valid             = 1'b1;
                    rob_instr             = iq_instr;
                    rob_rs1_s             = iq_instr[19:15];
                    rob_rs2_s             = iq_instr[24:20];
                    rob_rd_s              = '0;
                    rob_regf_we           = 1'b0;
                    rob_pc                = iq_pc;
                    rob_pc_next           = iq_pc_next;
                    rob_pc_next_valid     = 1'b0;
                end
                
            end
            
            op_b_load : begin
                if (!lsq_full && !lsq_load_rs_full && iq_valid && !rs_load_store_full && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;                                     
                    end
                    else begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                    end

                    iq_issue              = 1'b1;

                    rs_load_store_valid   = 1'b1;
                    rs_instr              = iq_instr;
                    rs_tag_dest           = regf_tag_rd;

                    rs_tag_B              = '0;
                    rs_data_B             = '0;
                    rs_ready_B            = 1'b1;

                    rs_imm                = i_imm;

                    regf_rs1_s            = iq_instr[19:15];
                    regf_rs2_s            = '0;

                    rob_valid             = 1'b1;
                    rob_instr             = iq_instr;
                    rob_rs1_s             = iq_instr[19:15];
                    rob_rs2_s             = '0;
                    rob_rd_s              = iq_instr[11:7];
                    rob_regf_we           = 1'b1;
                    rob_pc                = iq_pc;
                    rob_pc_next           = iq_pc_next;

                end
                   
                        
            end
            
            op_b_store: begin
                if (!lsq_full && iq_valid && !rs_load_store_full && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1; 
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                    
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs2) && (rob_commit_tag != regf_tag_rs1) && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag != regf_tag_rs2) && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;     
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;
                                                       
                    end
                    else begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                 
                    end   

                    iq_issue              = 1'b1;

                    rs_load_store_valid   = 1'b1;
                    rs_instr              = iq_instr;
                    rs_tag_dest           = regf_tag_rd;

                    rs_imm                = s_imm;

                    regf_rs1_s            = iq_instr[19:15];
                    regf_rs2_s            = iq_instr[24:20];

                    rob_valid             = 1'b1;
                    rob_instr             = iq_instr;
                    rob_rs1_s             = iq_instr[19:15];
                    rob_rs2_s             = iq_instr[24:20];
                    rob_rd_s              = '0;
                    rob_regf_we           = 1'b0;
                    rob_pc                = iq_pc;
                    rob_pc_next           = iq_pc_next;
                end
                
                
            end


            op_b_imm  : begin
                if (iq_valid && !rs_alu_full && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;                                     
                    end
                    else begin
                        rs_tag_A        = regf_tag_rs1;
                        rs_data_A       = regf_data_rs1;
                        rs_ready_A      = regf_ready_rs1;
                    end
                    
                    iq_issue        = 1'b1;

                    rs_alu_valid    = 1'b1;
                    rs_instr        = iq_instr;
                    rs_tag_dest     = regf_tag_rd;

                    
                    regf_rs1_s      = iq_instr[19:15];
                    regf_rs2_s      = '0;

                    rob_valid       = 1'b1;
                    rob_instr       = iq_instr;
                    rob_rs1_s       = iq_instr[19:15];
                    rob_rs2_s       = '0;
                    rob_rd_s        = iq_instr[11:7];
                    rob_regf_we     = 1'b1;
                    rob_pc          = iq_pc;
                    rob_pc_next     = iq_pc_next;
                    
                    unique case(funct3)
                        arith_f3_sll: begin
                            rs_tag_B    = '0;
                            rs_data_B   = shamt;
                            rs_ready_B  = 1'b1;
                        
                        end
                        arith_f3_sr: begin
                            rs_tag_B    = '0;
                            rs_data_B   = shamt;
                            rs_ready_B  = 1'b1;
                                
                        end
                        default: begin
                            rs_tag_B    = '0;
                            rs_data_B   = i_imm;
                            rs_ready_B  = 1'b1;
                        end
                    endcase
                end
                
                
            end
            op_b_reg  : begin
                if (iq_valid && !iq_empty && !rob_full) begin
                    if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && regf_ready_rs1 && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1; 
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs1) && (rob_commit_tag == regf_tag_rs2) && !regf_ready_rs1 && regf_ready_rs2) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;   
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                    
                    end
                    else if(rob_commit && (rob_commit_tag == regf_tag_rs2) && (rob_commit_tag != regf_tag_rs1) && !regf_ready_rs2) begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_data_B   = rob_commit_rd_v;
                        rs_tag_B    = '0;
                        rs_ready_B  = 1'b1;                                     
                    end
                    else if(rob_commit && (rob_commit_tag != regf_tag_rs2) && (rob_commit_tag == regf_tag_rs1) && !regf_ready_rs1) begin
                        rs_data_A   = rob_commit_rd_v;
                        rs_tag_A    = '0;
                        rs_ready_A  = 1'b1;     
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                              
                    end
                    else begin
                        rs_tag_A    = regf_tag_rs1;
                        rs_data_A   = regf_data_rs1;
                        rs_ready_A  = regf_ready_rs1;
                        rs_tag_B    = regf_tag_rs2;
                        rs_data_B   = regf_data_rs2;
                        rs_ready_B  = regf_ready_rs2;                                 
                    end                    
                
                    rs_instr    = iq_instr;
                    rs_tag_dest = regf_tag_rd;


                    regf_rs1_s  = iq_instr[19:15];
                    regf_rs2_s  = iq_instr[24:20];

                    rob_valid   = 1'b1;
                    rob_instr   = iq_instr;
                    rob_rs1_s   = iq_instr[19:15];
                    rob_rs2_s   = iq_instr[24:20];
                    rob_rd_s    = iq_instr[11:7];
                    rob_regf_we = 1'b1;
                    rob_pc      = iq_pc;
                    rob_pc_next = iq_pc_next;


                    if (funct7 == extension) begin
                        if (!rs_mul_div_full) begin
                            iq_issue            = 1'b1;
                            rs_mul_div_valid    = 1'b1;
                        end
                    end
                    else begin
                        if (!rs_alu_full) begin
                            iq_issue        = 1'b1;
                            rs_alu_valid    = 1'b1; 
                        end 
                    end
                end                
            end
            
            
            default: begin
                iq_issue            = 1'b0;
        
                rs_alu_valid        = '0;
                rs_mul_div_valid    = '0;
                rs_load_store_valid = '0;
                rs_branch_valid     = '0;
                rs_instr            = '0;
                rs_tag_dest         = '0;
                rs_tag_A            = '0;
                rs_data_A           = '0;
                rs_ready_A          = 1'b0;
                rs_tag_B            = '0;
                rs_data_B           = '0;
                rs_ready_B          = 1'b0;

                regf_rs1_s          = iq_instr[19:15];
                regf_rs2_s          = iq_instr[24:20];
                
                rob_valid           = 1'b0;
                rob_instr           = '0;
                rob_rs1_s           = iq_instr[19:15];
                rob_rs2_s           = iq_instr[24:20];
                rob_rd_s            = iq_instr[11:7];
                rob_regf_we         = 1'b0;
                rob_pc              = iq_pc;
                rob_pc_next         = iq_pc_next;
            end
        endcase
    end

    

    // //decode instruction
    // always_comb begin
    //     regf_we_id    = 1'b0;
    //     imm_id        = '0;
    //     MemtoReg_id   = 1'b0;
    //     branch_id     = 1'b0;
    //     alusrc_id     = '0;
    //     rs1_s         = iq_instr[19:15];
    //     rs2_s         = iq_instr[24:20];


    //     rs_alu_valid = '0;
    //     rs_mul_div_valid = '0;
    //     rs_load_store_valid = '0;        
    //     rs_branch_valid = '0;

        
        

    //     unique case (opcode)
    //         op_b_lui  : begin
    //             regf_we_id = 1'b1;
    //             alusrc_id = 1'b1;
    //             imm_id = u_imm;
    //             rs1_s  = '0;
    //             rs2_s  = '0;
    //             rs_alu_valid = instr_issue;
    //         end
    //         op_b_auipc: begin
    //             regf_we_id = 1'b1;
    //             alusrc_id = 1'b1;
    //             imm_id = u_imm;
    //             rs1_s  = '0;
    //             rs2_s  = '0;
    //             rs_alu_valid = instr_issue;
    //         end
    //         op_b_jal  : begin
    //             regf_we_id = 1'b1;
    //             imm_id = j_imm;
    //             branch_id = 1'b1;
    //             rs_alu_valid = instr_issue;
    //         end
    //         op_b_jalr : begin
    //             regf_we_id = 1'b1;
    //             imm_id = i_imm;
    //             branch_id = 1'b1;
    //             rs_alu_valid = instr_issue;
    //         end
            
            
    //         op_b_br   : begin
    //             regf_we_id = 1'b0;
    //             imm_id     = b_imm;
    //             branch_id = 1'b1;
    //             alusrc_id = 1'b0;
    //             rs_branch_valid = instr_issue;
    //         end
            
    //         op_b_load : begin
    //             regf_we_id = 1'b1;
    //             alusrc_id = 1'b1;
    //             imm_id = i_imm;
    //             MemtoReg_id = 1'b1;               
    //             rs2_s  = '0; 
    //             rs_load_store_valid = instr_issue;   
                        
    //         end
            
    //         op_b_store: begin
    //             alusrc_id = 1'b1;
    //             imm_id = s_imm;
    //             rs_load_store_valid = instr_issue;
                
    //         end


    //         op_b_imm  : begin
    //             rs_alu_valid = instr_issue;
    //             unique case(funct3)
    //                 arith_f3_sll: begin
    //                     regf_we_id = 1'b1;
    //                     alusrc_id = 1'b1;
    //                     imm_id = shamt;
                        
    //                 end
    //                 arith_f3_sr: begin
    //                     regf_we_id = 1'b1;
    //                     alusrc_id = 1'b1;
    //                     imm_id = shamt;   
                                
    //                 end
    //                 default: begin
    //                     regf_we_id = 1'b1;
    //                     alusrc_id = 1'b1;
    //                     imm_id = i_imm;
                        
    //                 end
    //             endcase
    //         end
    //         op_b_reg  : begin
    //             regf_we_id = 1'b1;
    //             alusrc_id = 1'b0;
    //             imm_id = 32'b0; 
    //             if (funct7 == extension) begin
    //                 rs_mul_div_valid = instr_issue;
    //             end
    //             else begin
    //                 rs_alu_valid = instr_issue;
    //             end
    //         end
            
            
    //         default: begin
    //             regf_we_id    = 1'b0;
    //             imm_id     = '0;
    //             regf_we_id = 1'b0;
    //             MemtoReg_id = 1'b0;
    //             branch_id = 1'b0;
    //             alusrc_id = 'x;
            
            
    //         end
    //     endcase
    // end
endmodule
