package rv32im_types;
/////////////////////////////////////////////////////////////
// Maybe merge what is in mp_verif/pkg/types.sv over here? //
/////////////////////////////////////////////////////////////


    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [3:0] {
        alu_r_add     = 4'b0000,
        alu_r_sub     = 4'b1000,
        alu_r_sll     = 4'b0001,
        alu_r_slt     = 4'b0010,
        alu_r_sltu    = 4'b0011,
        alu_r_xor     = 4'b0100,
        alu_r_srl     = 4'b0101,
        alu_r_sra     = 4'b1101,
        alu_r_or      = 4'b0110,
        alu_r_and     = 4'b0111
    } alu_ctrl_rtype;

    typedef enum logic [3:0] {
        alu_i_add     = 4'b0000,
        alu_i_slt     = 4'b0010,
        alu_i_sltu    = 4'b0011,
        alu_i_xor     = 4'b0100,
        alu_i_or      = 4'b0110,
        alu_i_and     = 4'b0111,
        alu_i_sll     = 4'b0001,
        alu_i_srl     = 4'b0101,
        alu_i_sra     = 4'b1101
    } alu_ctrl_itype;

    typedef enum logic [1:0] {
        alu_op_lui    = 2'b00,
        alu_op_auipc  = 2'b01,
        alu_op_itype  = 2'b10,
        alu_op_rtype  = 2'b11
    } alu_ctrl_optype;

    // typedef enum logic [3:0] {
    //     mul_div_mul   = 
    // } mul_div_ctrl;



     typedef enum logic [3:0] {
        alu_op_add     = 4'b0000,
        alu_op_sub     = 4'b1000,
        alu_op_sll     = 4'b0001,
        alu_op_slt     = 4'b0010,
        alu_op_sltu    = 4'b0011,
        alu_op_xor     = 4'b0100,
        alu_op_srl     = 4'b0101,
        alu_op_sra     = 4'b1101,
        alu_op_or      = 4'b0110,
        alu_op_and     = 4'b0111
    } alu_rtype_ctrl;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000,
        extension      = 7'b0000001
    } funct7_t;
    
    typedef enum logic [1:0] {
        from_ex        = 2'b00,
        from_m         = 2'b01,
        from_wb        = 2'b10,
        from_hold      = 2'b11
    } forward_t;

    typedef enum logic [6:0] {
        op_cp2_lui       = 7'b0110111, // load upper immediate (U type)
        op_cp2_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_cp2_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_cp2_reg       = 7'b0110011  // arith ops with register operands (R type)
    } cp2_opcode;

    typedef enum logic [1:0]{
        way_A = 2'b00,
        way_B = 2'b01,
        way_C = 2'b10,
        way_D = 2'b11
    } way_t;

    // typedef enum logic [1:0]{
    //     hit        = 2'b00;
    //     clean_miss = 2'b01;
    //     dirty_miss = 2'b10;
    // }

    typedef enum logic [1:0] {
        no_write  = 2'b00,
        write_cpu = 2'b01,
        write_mem = 2'b10
    } write_t;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        struct packed {
            logic imm_12;        // 1 bit (imm[12])
            logic [10:5] imm_10_5; // 6 bits (imm[10:5])
            logic [4:0]  rs2;    // 5 bits
            logic [4:0]  rs1;    // 5 bits
            logic [2:0]  funct3; // 3 bits
            logic [4:1]  imm_4_1;  // 4 bits (imm[4:1])
            logic imm_11;        // 1 bit (imm[11])
            rv32i_opcode opcode; // 7 bits
        } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;
        
        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } u_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            cp2_opcode  opcode;
        } cp2_type;

    } instr_t;

    typedef struct packed {
        logic           valid;
        logic   [63:0]  order;
        logic   [31:0]  inst;
        logic   [4:0]   rs1_addr;
        logic   [4:0]   rs2_addr;
        logic   [31:0]  rs1_rdata;
        logic   [31:0]  rs2_rdata;
        logic   [4:0]   rd_addr;
        logic   [31:0]  rd_wdata;
        logic   [31:0]  pc_rdata;
        logic   [31:0]  pc_wdata;
        logic   [31:0]  dmem_addr;
        logic   [3:0]   dmem_rmask;
        logic   [3:0]   dmem_wmask;
        logic   [31:0]  dmem_rdata;
        logic   [31:0]  dmem_wdata;  
    } rvfi_t;

endpackage

