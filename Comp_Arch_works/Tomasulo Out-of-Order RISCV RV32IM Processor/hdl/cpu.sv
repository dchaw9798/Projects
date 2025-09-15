module cpu
import rv32im_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid

);

localparam int ROB_DEPTH = 8;
localparam int RS_DEPTH = 4;
localparam int IQ_DEPTH = 16;
localparam int LSQ_DEPTH = 8;
localparam int MUL_CYCLE = 16;
localparam int DIV_CYCLE = 16;

logic [31:0]                  instr_fetch;
logic                         iq_full;
logic [31:0]                  pc_out,pc_next_out;
logic                         enqueue;
//logic instr_pop;
logic [31:0]                  iq_pc_out, iq_pc_next_out;
logic [31:0]                  iq_instr_out;
logic                         iq_valid_out;
logic                         iq_empty;
logic                         iq_issue;

//decode -> rob
logic                         rob_valid;
logic [31:0]                  rob_instr;
logic [4:0]                   rob_rs1_s;
logic [4:0]                   rob_rs2_s;
logic [4:0]                   rob_rd_s;
logic                         rob_regf_we;
logic [31:0]                  rob_pc;
logic [31:0]                  rob_pc_next;
logic                         rob_pc_next_valid;

//rob -> decode
logic                         rob_full;

//regfile
logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rs1;
logic [31:0]                  regf_data_rs1;
logic                         regf_ready_rs1;
logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rs2;
logic [31:0]                  regf_data_rs2;
logic                         regf_ready_rs2;
logic [$clog2(ROB_DEPTH)-1:0] regf_tag_rd;

logic [4:0]                   regf_rs1_s;
logic [4:0]                   regf_rs2_s;

//RS side signal
logic                         rs_alu_valid;
logic                         rs_mult_div_valid;
logic                         rs_load_store_valid;
logic                         rs_branch_valid;

logic                         rs_alu_full; //tell instruction queue this rs is full
logic                         rs_mul_div_full;
logic                         rs_load_store_full;
logic                         rs_branch_full;

logic [31:0]                  rs_instr;
logic [$clog2(ROB_DEPTH)-1:0] rs_tag_dest; //destination tag (ROB value)
//output  logic [5:0]                   rs_alu_ctrl, //not yet determined how to encode

logic [$clog2(ROB_DEPTH)-1:0] rs_tag_A; //ROB tag of source A
logic [31:0]                  rs_data_A;
logic                         rs_ready_A; //when data A is available

logic [$clog2(ROB_DEPTH)-1:0] rs_tag_B; //ROB tag of source B
logic [31:0]                  rs_data_B;
logic                         rs_ready_B; //when data B is available

logic [$clog2(ROB_DEPTH)-1:0] rs_tag_C; //ROB tag of source C
logic [31:0]                  rs_data_C;
logic                         rs_ready_C; //when data C is available


//rob -> reg
logic                         regf_commit_regf_we;
logic [4:0]                   regf_commit_rd_s;
logic [31:0]                  regf_commit_rd_v;
logic [$clog2(ROB_DEPTH)-1:0] regf_commit_tag;
logic [4:0]                   regf_issue_rd_s;
logic [$clog2(ROB_DEPTH)-1:0] regf_issue_tag;

//rs -> alu
logic [31:0]                  alu_instr_in;
logic [31:0]                  alu_data_A_out;
logic [31:0]                  alu_data_B_out;
logic                         alu_comp_issue;
logic [$clog2(ROB_DEPTH)-1:0] alu_tag_dest_out;

//alu -> rs
logic                         alu_resp;

//alu -> cdb   
logic [31:0]                  alu_result;
logic [$clog2(ROB_DEPTH)-1:0] alu_cdb_tag;
logic                         alu_valid;

//rs -> mult_div
logic [31:0]                  mult_div_instr_in;
logic [31:0]                  mult_div_data_A_out;
logic [31:0]                  mult_div_data_B_out;
logic                         mult_div_comp_issue;
logic [$clog2(ROB_DEPTH)-1:0] mult_div_tag_dest_out;

//mult_div -> rs
logic                         mult_div_resp;

//mult_div -> cdb   
logic [31:0]                  mult_div_result;
logic [$clog2(ROB_DEPTH)-1:0] mult_div_cdb_tag;
logic                         mult_div_valid;

//rs -> mult_div
logic [31:0]                  branch_instr_in;
logic [31:0]                  branch_rs1_v;
logic [31:0]                  branch_rs2_v;
logic                         branch_comp_issue;
logic [$clog2(ROB_DEPTH)-1:0] branch_tag;

//mult_div -> rs
logic                         branch_resp;

//mult_div -> cdb   
logic [31:0]                  branch_result;
logic [$clog2(ROB_DEPTH)-1:0] branch_cdb_tag;
logic                         branch_valid;

//load_store_rs -> adder
logic [31:0]                  load_store_instr_in;
logic [31:0]                  load_store_rs1_v;
logic [31:0]                  load_store_rs2_v;
logic [31:0]                  load_store_imm;
logic                         load_store_comp_issue;
logic [$clog2(ROB_DEPTH)-1:0] load_store_tag;

//load_store -> rs
logic                         load_store_resp;

//mult_div -> cdb   
logic [31:0]                  load_store_result;
logic [$clog2(ROB_DEPTH)-1:0] load_store_cdb_tag;
logic                         load_store_valid;
//computation -> cdb
logic                         exe_done[4];
logic [31:0]                  data_in[4];
logic [$clog2(ROB_DEPTH)-1:0] exe_tag[4];

//cdb -> rob
logic                         valid_CDB[4];
logic [31:0]                  data_CDB[4];
logic [$clog2(ROB_DEPTH)-1:0] tag_CDB[4];


logic                         rob_commit;
logic                         flush;

logic [31:0]                  rs_pc;
logic [31:0]                  rs_imm;
logic [31:0]                  branch_pc;
logic [31:0]                  branch_imm;
logic [31:0]                  branch_pc_next;
logic [31:0]                  fetch_pc_next;

//arbiter side signal
logic [31:0]                  i_dram_addr;
logic                         i_dram_read;
logic                         i_dram_write;
logic [63:0]                  i_dram_wdata;

logic                         i_dram_ready;
logic [31:0]                  i_dram_raddr;
logic [63:0]                  i_dram_rdata;
logic                         i_dram_rvalid;

logic [31:0]                  d_dram_addr;
logic                         d_dram_read;
logic                         d_dram_write;
logic [63:0]                  d_dram_wdata;

logic                         d_dram_ready;
logic [31:0]                  d_dram_raddr;
logic [63:0]                  d_dram_rdata;
logic                         d_dram_rvalid;

logic                         lsq_full;

logic [31:0]                  rob_dmem_addr; //for rvfi
logic [3:0]                   rob_dmem_rmask; //for rvfi
logic [3:0]                   rob_dmem_wmask; //for rvfi
logic [31:0]                  rob_dmem_rdata; //for rvfi
logic [31:0]                  rob_dmem_wdata; //for rvfi

logic [31:0]                  load_store_cdb_data;

logic [31:0]                  lsq_addr;
logic                         lsq_addr_valid;
logic [$clog2(ROB_DEPTH)-1:0] lsq_commit_tag;
logic                         load_rs_full;

logic                         br_take;
logic [31:0]                  commit_pc;
logic [31:0]                  commit_pc_next;
logic [6:0]                   commit_opcode;
logic                         commit_br_take;

logic [6:0]                   branch_pc_opcode;
logic [31:0]                  pc_compare;

logic                         mispredict;



always_comb begin
    exe_done[0] = alu_valid;
    exe_done[1] = mult_div_valid;
    exe_done[2] = load_store_valid;
    exe_done[3] = branch_valid;
    data_in[0] = alu_result;
    data_in[1] = mult_div_result;
    data_in[2] = load_store_cdb_data;
    data_in[3] = branch_result;
    exe_tag[0]   = alu_cdb_tag;
    exe_tag[1]   = mult_div_cdb_tag;
    exe_tag[2]   = load_store_cdb_tag;
    exe_tag[3]   = branch_cdb_tag;
end


//rs -> rob assign rs values and tag
logic [31:0]                  data_A_out[4];
logic [31:0]                  data_B_out[4];
logic [$clog2(ROB_DEPTH)-1:0] tag_dest_out[4];
logic                         comp_issue[4];

always_comb begin
    data_A_out[0] = alu_data_A_out;
    data_A_out[1] = mult_div_data_A_out;
    data_A_out[2] = load_store_rs1_v;
    data_A_out[3] = branch_rs1_v;
    data_B_out[0] = alu_data_B_out;
    data_B_out[1] = mult_div_data_B_out;
    data_B_out[2] = load_store_rs2_v;
    data_B_out[3] = branch_rs2_v;
    tag_dest_out[0]   = alu_tag_dest_out;
    tag_dest_out[1]   = mult_div_tag_dest_out;
    tag_dest_out[2]   = load_store_tag;
    tag_dest_out[3]   = branch_tag;
    comp_issue[0]   = alu_comp_issue;
    comp_issue[1]   = mult_div_comp_issue;
    comp_issue[2]   = load_store_comp_issue;
    comp_issue[3]   = branch_comp_issue;
end



fetch fetch_unit (
    .clk(clk),
    .rst(rst),
    .branch(flush),
    .pc_branch(fetch_pc_next),
    .iq_full(iq_full), //instruction queue full signal
    .pc_out(pc_out),
    .pc_next_out(pc_next_out),
    .instr(instr_fetch),
    .enqueue(enqueue), //pop instr and pc into instruction queue

// dram port
    .i_dram_addr(i_dram_addr),
    .i_dram_read(i_dram_read),
    .i_dram_write(i_dram_write),
    .i_dram_wdata(i_dram_wdata),

    .i_dram_ready(i_dram_ready),
    .i_dram_raddr(i_dram_raddr),
    .i_dram_rdata(i_dram_rdata),
    .i_dram_rvalid(i_dram_rvalid),

// from rob
    .commit_pc(commit_pc),
    .commit_pc_next(fetch_pc_next),
    .commit_opcode(commit_opcode),
    .commit_br_take(commit_br_take),
    .rob_commit(rob_commit)
    //.mispredict(mispredict)
);

bmem_arbitor bmem_arbitor(
    .clk(clk),
    .rst(rst),

    // icache side
    .i_dram_addr(i_dram_addr),
    .i_dram_read(i_dram_read),
    .i_dram_write(i_dram_write),
    .i_dram_wdata(i_dram_wdata),

    .i_dram_ready(i_dram_ready),
    .i_dram_raddr(i_dram_raddr),
    .i_dram_rdata(i_dram_rdata),
    .i_dram_rvalid(i_dram_rvalid),

    // dcache side
    .d_dram_addr(d_dram_addr),
    .d_dram_read(d_dram_read),
    .d_dram_write(d_dram_write),
    .d_dram_wdata(d_dram_wdata),   

    .d_dram_ready(d_dram_ready),
    .d_dram_raddr(d_dram_raddr),
    .d_dram_rdata(d_dram_rdata),
    .d_dram_rvalid(d_dram_rvalid), 

    // mem side
    .bmem_addr(bmem_addr),
    .bmem_read(bmem_read),
    .bmem_write(bmem_write),
    .bmem_wdata(bmem_wdata),

    .bmem_ready(bmem_ready),
    .bmem_raddr(bmem_raddr),
    .bmem_rdata(bmem_rdata),
    .bmem_rvalid(bmem_rvalid)
);

instruction_queue #(
    .IQ_DEPTH(IQ_DEPTH),
    .IQ_WIDTH(32)
) instruction_queue (
    // for improvement, do simultaneously push and pop if full.
    .clk(clk),
    .rst(rst),
    .flush(flush),
    // fetch side signal
    .instr_push(enqueue),
    .pc_in(pc_out),
    .pc_next_in(pc_next_out),
    .instr_in(instr_fetch),
    .iq_full(iq_full),
        
    // decode side signal
    .instr_pop(iq_issue),
    .pc_out(iq_pc_out),
    .pc_next_out(iq_pc_next_out),
    .instr_out(iq_instr_out),
    .iq_empty(iq_empty),
    .valid_out(iq_valid_out)
);

decoder #(
    .ROB_DEPTH(ROB_DEPTH)
) decoder (   
    //IQ side signal
    .iq_instr(iq_instr_out),
    .iq_pc(iq_pc_out),
    .iq_pc_next(iq_pc_next_out),
    .iq_valid(iq_valid_out),
    .iq_empty(iq_empty),
    
    .iq_issue(iq_issue),
    .lsq_full(lsq_full),
    .lsq_load_rs_full(load_rs_full),

    //ROB side signal
    .rob_valid(rob_valid),
    .rob_instr(rob_instr),
    .rob_rs1_s(rob_rs1_s),
    .rob_rs2_s(rob_rs2_s),
    .rob_rd_s(rob_rd_s),
    .rob_regf_we(rob_regf_we),
    .rob_pc(rob_pc),
    .rob_pc_next(rob_pc_next),
    .rob_pc_next_valid(rob_pc_next_valid),
    
    
    .rob_full(rob_full),
    .rob_commit(rob_commit),
    //.rob_commit_rd_s(regf_commit_rd_s),
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),

    //RegFile side signal
    .regf_tag_rs1(regf_tag_rs1),
    .regf_data_rs1(regf_data_rs1),
    .regf_ready_rs1(regf_ready_rs1),
    .regf_tag_rs2(regf_tag_rs2),
    .regf_data_rs2(regf_data_rs2),
    .regf_ready_rs2(regf_ready_rs2),
    .regf_tag_rd(regf_tag_rd),

    .regf_rs1_s(regf_rs1_s),
    .regf_rs2_s(regf_rs2_s),
    
    //RS side signal
    .rs_alu_valid(rs_alu_valid),
    .rs_mul_div_valid(rs_mult_div_valid),
    .rs_load_store_valid(rs_load_store_valid),
    .rs_branch_valid(rs_branch_valid),

    .rs_alu_full(rs_alu_full), //tell instruction queue this rs is full
    .rs_mul_div_full(rs_mul_div_full),
    .rs_load_store_full(rs_load_store_full),
    .rs_branch_full(rs_branch_full),

    .rs_instr(rs_instr),
    .rs_tag_dest(rs_tag_dest), //destination tag (ROB value)
    //output  logic [5:0]                   rs_alu_ctrl, //not yet determined how to encode

    .rs_tag_A(rs_tag_A), //ROB tag of source A
    .rs_data_A(rs_data_A),
    .rs_ready_A(rs_ready_A), //when data A is available

    .rs_tag_B(rs_tag_B), //ROB tag of source B
    .rs_data_B(rs_data_B),
    .rs_ready_B(rs_ready_B), //when data B is available

    .rs_pc(rs_pc),
    .rs_imm(rs_imm)

);

reservation_station #(
    .RS_DEPTH(RS_DEPTH),
    .ROB_DEPTH(ROB_DEPTH)
) alu_rs (
    .clk(clk),
    .rst(rst),
    .flush(flush),
    //ufp side signal, connecting decoder
    .instr_in(rs_instr),
    .valid_in(rs_alu_valid), //indicates this rs array is activated (connects to comp_issue/pop from instruction queue)
    .tag_dest_in(rs_tag_dest), //destination tag (ROB value)
    //[5:0]                   alu_ctrl_in, //not yet determined how to encode

    .tag_A_in(rs_tag_A), //ROB tag of source A
    .data_A_in(rs_data_A),
    .ready_A_in(rs_ready_A), //when data A is available

    .tag_B_in(rs_tag_B), //ROB tag of source B
    .data_B_in(rs_data_B),
    .ready_B_in(rs_ready_B), //when data A is available

    .rs_full(rs_alu_full), //tell instruction queue this rs is full
    
    //CDB side signal
    .valid_CDB(valid_CDB), //indicate this data on the CDB is valid
    .tag_CDB(tag_CDB), //ROB tag on the CDB
    .data_CDB(data_CDB),

    .rob_commit(rob_commit),
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),

    //dfp side signal, connecting ALU
    .resp(alu_resp), //resp from alu to ensure the operation has finished
    .instr_out(alu_instr_in),
    
    .tag_dest_out(alu_tag_dest_out),
    //.alu_ctrl_out, //not yet determined how to encode
    .data_A_out(alu_data_A_out),
    .data_B_out(alu_data_B_out),
    .comp_issue(alu_comp_issue) //indicates this instruction is popped to ALU for operation

);

mult_div_rs #(
    .RS_DEPTH(RS_DEPTH),
    .ROB_DEPTH(ROB_DEPTH)
) mult_div_rs (
    .clk(clk),
    .rst(rst),
    .flush(flush),
    //ufp side signal, connecting decoder
    .instr_in(rs_instr),
    .valid_in(rs_mult_div_valid), //indicates this rs array is activated (connects to comp_issue/pop from instruction queue)
    .tag_dest_in(rs_tag_dest), //destination tag (ROB value)
    //[5:0]                   alu_ctrl_in, //not yet determined how to encode

    .tag_A_in(rs_tag_A), //ROB tag of source A
    .data_A_in(rs_data_A),
    .ready_A_in(rs_ready_A), //when data A is available

    .tag_B_in(rs_tag_B), //ROB tag of source B
    .data_B_in(rs_data_B),
    .ready_B_in(rs_ready_B), //when data A is available

    .rs_full(rs_mul_div_full), //tell instruction queue this rs is full
    
    //CDB side signal
    .valid_CDB(valid_CDB), //indicate this data on the CDB is valid
    .tag_CDB(tag_CDB), //ROB tag on the CDB
    .data_CDB(data_CDB),

    .rob_commit(rob_commit),
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),

    //dfp side signal, connecting ALU
    .resp(mult_div_resp), //resp from alu to ensure the operation has finished
    .instr_out(mult_div_instr_in),
    .tag_dest_out(mult_div_tag_dest_out),
    //.alu_ctrl_out, //not yet determined how to encode
    .data_A_out(mult_div_data_A_out),
    .data_B_out(mult_div_data_B_out),
    .comp_issue(mult_div_comp_issue) //indicates this instruction is popped to ALU for operation

);

branch_rs #(
    .RS_DEPTH(RS_DEPTH), 
    .ROB_DEPTH(ROB_DEPTH)
) branch_rs (
    .clk(clk),
    .rst(rst),
    .flush(flush),
    //ufp side signal, connecting decoder
    .instr_in(rs_instr),
    .valid_in(rs_branch_valid), //indicates this rs array is activated (connects to comp_issue/pop from instruction queue)
    .tag_dest_in(rs_tag_dest), //destination tag (ROB value)

    .tag_A_in(rs_tag_A), //ROB tag of source A (rs1_s rob tag)
    .data_A_in(rs_data_A), //rs1_v read from regfile
    .ready_A_in(rs_ready_A), //when data A is available

    .tag_B_in(rs_tag_B), //ROB tag of source B (rs2_s rob tag)
    .data_B_in(rs_data_B), //rs2_v read from regfile
    .ready_B_in(rs_ready_B), //when data B is available

    .pc_in(rs_pc),  // pc value read from decoder
    .imm_in(rs_imm), // imm value read from decoder

    .rs_full(rs_branch_full), //tell instruction queue this rs is full
    
    //CDB side signal
    .valid_CDB(valid_CDB), //indicate this data on the CDB is valid
    .tag_CDB(tag_CDB), //ROB tag on the CDB
    .data_CDB(data_CDB),

    //ROB to RS (when regfile's data and tag is overwritten by new instruction, forward tag and value from rob)
    .rob_commit(rob_commit), 
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),

    //addr_adder side signal
    .resp(branch_resp), //resp from alu to ensure the operation has finished
    .tag_dest_out(branch_tag),
    .instr_out(branch_instr_in),
    .data_A_out(branch_rs1_v),
    .data_B_out(branch_rs2_v),
    .pc_out(branch_pc),
    .imm_out(branch_imm),
    .comp_issue(branch_comp_issue) //indicates this instruction is popped to ALU for operation
);


load_store_rs #(
    .RS_DEPTH (RS_DEPTH), 
    .ROB_DEPTH(ROB_DEPTH)
) load_store_rs (
    .clk(clk),
    .rst(rst),
    .flush(flush),
    //ufp side signal, connecting decoder
    .instr_in(rs_instr),
    .valid_in(rs_load_store_valid), //indicates this rs array is activated (connects to comp_issue/pop from instruction queue)
    .tag_dest_in(rs_tag_dest), //destination tag (ROB value)
    //[5:0]                   alu_ctrl_in, //not yet determined how to encode

    .tag_A_in(rs_tag_A), //ROB tag of source A
    .data_A_in(rs_data_A),
    .ready_A_in(rs_ready_A), //when data A is available

    .tag_B_in(rs_tag_B), //ROB tag of source B
    .data_B_in(rs_data_B),
    .ready_B_in(rs_ready_B), //when data B is available

    .imm_in(rs_imm),

    .rs_full(rs_load_store_full), //tell instruction queue this rs is full
    
    //CDB side signal
    .valid_CDB(valid_CDB), //indicate this data on the CDB is valid
    .tag_CDB(tag_CDB), //ROB tag on the CDB
    .data_CDB(data_CDB),

    .rob_commit(rob_commit),
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),

    //dfp side signal, connecting ALU
    .resp(load_store_resp), //resp from alu to ensure the operation has finished

    //.alu_ctrl_out, //not yet determined how to encode
    .data_A_out(load_store_rs1_v),
    .imm_out(load_store_imm),
    .comp_issue(load_store_comp_issue), //indicates this instruction is popped to ALU for operation
    .lsq_store_data(load_store_rs2_v),
    .lsq_tag(load_store_tag)
);

load_store_addr_adder load_store_addr_adder
 (
    //LS_RS side signal
    .rs_ls_rs1_data(load_store_rs1_v),
    .rs_ls_imm_data(load_store_imm),
    .rs_ls_addr_adder_en(load_store_comp_issue),
    .rs_ls_addr_adder_resp(load_store_resp),
    //LS_queue side signal
    .lsq_addr_valid(lsq_addr_valid),
    .lsq_addr(lsq_addr) //to LSQ
);

load_store_queue
#(
    .LS_QUEUE_DEPTH(LSQ_DEPTH),
    .ROB_DEPTH(ROB_DEPTH)
) load_store_queue (
    .clk(clk),
    .rst(rst),
    .flush(flush),

    // decoder side signal
    .iq_issue(iq_issue),
    .decoder_instr(rs_instr),
    .decoder_tag(rs_tag_dest),
    .lsq_full(lsq_full),
    .load_rs_full(load_rs_full),
    .decoder_load_store_valid(rs_load_store_valid),

    // load_store_adder side signal
    .addr_valid(lsq_addr_valid), //connect to lsq_addr_valid
    .load_store_addr(lsq_addr), //connect to lsq_addr

    // RS side signal
    .ls_rs_store_data(load_store_rs2_v),  //connect to lsq_store_data
    .ls_rs_tag(load_store_tag), //connect to lsq_tag

    // dram port
    .d_dram_addr(d_dram_addr),
    .d_dram_read(d_dram_read),
    .d_dram_write(d_dram_write),
    .d_dram_wdata(d_dram_wdata),

    .d_dram_ready(d_dram_ready),
    .d_dram_raddr(d_dram_raddr),
    .d_dram_rdata(d_dram_rdata),
    .d_dram_rvalid(d_dram_rvalid),

    // CDB side signal
    .valid_CDB(load_store_valid),
    .data_CDB(load_store_cdb_data),
    .tag_CDB(load_store_cdb_tag),

    // ROB side signal
    .rob_commit_tag(lsq_commit_tag),

    .rob_dmem_addr(rob_dmem_addr), //for rvfi
    .rob_dmem_rmask(rob_dmem_rmask), //for rvfi
    .rob_dmem_wmask(rob_dmem_wmask), //for rvfi
    .rob_dmem_rdata(rob_dmem_rdata), //for rvfi
    .rob_dmem_wdata(rob_dmem_wdata) //for rvfi

);

rob #(
    .ROB_DEPTH(ROB_DEPTH),
    .CDB_SIZE(4) //alu: 0, mul_div: 1, load_store: 2, branch: 3
) rob (
    // order + 1 when commit
    .clk(clk),
    .rst(rst),
    .flush(flush),

    // CDB side signal
    .valid_CDB(valid_CDB),
    .tag_CDB(tag_CDB),
    .data_CDB(data_CDB),

    .rob_commit(rob_commit),

    // decoder side signal
    .iq_issue(iq_issue), 
    .decoder_valid(rob_valid),
    .decoder_instr(rob_instr),
    .decoder_rs1_s(rob_rs1_s),
    .decoder_rs2_s(rob_rs2_s),
    .decoder_rd_s(rob_rd_s),
    .decoder_regf_we(rob_regf_we),
    .decoder_pc(rob_pc),
    .decoder_pc_next(rob_pc_next),
    .decoder_pc_next_valid(rob_pc_next_valid),
    .rob_full(rob_full),
    
    // regfile side signal
    .regf_commit_regf_we(regf_commit_regf_we),
    .regf_commit_rd_s(regf_commit_rd_s),
    .regf_commit_rd_v(regf_commit_rd_v),
    .regf_commit_tag(regf_commit_tag),
    .regf_issue_rd_s(regf_issue_rd_s),
    .regf_issue_tag(regf_issue_tag),

    // rs side signal
    .rs_tag(tag_dest_out), // connect to RS tag_dest_out output
    .rs_rs1_v(data_A_out), // connect to RS data_A_out output
    .rs_rs2_v(data_B_out), // connect to RS data_B_out output
    .rs_ready(comp_issue), // connect to RS comp_issue output

    .branch_pc_next(branch_pc_next),
    .br_take(br_take),

    .fetch_pc_next(fetch_pc_next),
    .commit_pc(commit_pc),
    .commit_opcode(commit_opcode),
    .commit_pc_next(commit_pc_next),
    .commit_br_take(commit_br_take),

    .lsq_dmem_addr(rob_dmem_addr), //for rvfi
    .lsq_dmem_rmask(rob_dmem_rmask), //for rvfi
    .lsq_dmem_wmask(rob_dmem_wmask), //for rvfi
    .lsq_dmem_rdata(rob_dmem_rdata), //for rvfi
    .lsq_dmem_wdata(rob_dmem_wdata), //for rvfi
    .lsq_commit_tag(lsq_commit_tag)

    //.mispredict(mispredict)
    
    // rvfi connection signal
    //.rvfi
);

regfile #(
    .ROB_DEPTH(ROB_DEPTH)
) regfile (
    .clk(clk),
    .rst(rst),
    .flush(flush), //flush the tag in regfile when branch

    // rob side signal when commit
    .rob_commit(rob_commit),
    .rob_commit_regf_we(regf_commit_regf_we),
    .rob_commit_rd_s(regf_commit_rd_s),
    .rob_commit_rd_v(regf_commit_rd_v),
    .rob_commit_tag(regf_commit_tag),
    // rob side signal when issue
    .rob_issue_rd_s(regf_issue_rd_s),
    .rob_issue_tag(regf_issue_tag),

    // iq side signal when issue
    .iq_issue(iq_issue),
   
    // decoder side signal
    .decoder_rs1_s(regf_rs1_s),
    .decoder_rs2_s(regf_rs2_s),
    .decoder_rs1_v(regf_data_rs1),
    .decoder_rs2_v(regf_data_rs2),
    .decoder_rs1_tag(regf_tag_rs1),
    .decoder_rs2_tag(regf_tag_rs2),
    .decoder_rs1_ready(regf_ready_rs1),
    .decoder_rs2_ready(regf_ready_rs2),
    .decoder_rd_tag(regf_tag_rd)
);


alu #(
    .ROB_DEPTH(ROB_DEPTH)
) alu (
    .alu_instr_in(alu_instr_in),
    .rs1_v(alu_data_A_out),
    .rs2_v(alu_data_B_out),
    .alu_en(alu_comp_issue),
    .rob_tag(alu_tag_dest_out),
    
    .alu_resp(alu_resp),
    .alu_result(alu_result),
    .cdb_valid(alu_valid),
    .cdb_tag(alu_cdb_tag)
);

mult_div #(
    .ROB_DEPTH(ROB_DEPTH),
    .MUL_CYCLE(MUL_CYCLE),
    .DIV_CYCLE(DIV_CYCLE)
) mult_div (
    .clk(clk),
    .rst(rst),
    .mult_div_instr_in(mult_div_instr_in),
    .rs1_v(mult_div_data_A_out),
    .rs2_v(mult_div_data_B_out),
    .rob_tag(mult_div_tag_dest_out),
    .mult_div_en(mult_div_comp_issue),
    .flush(flush),
    
    .mult_div_resp(mult_div_resp),
    .mult_div_result(mult_div_result),
    .cdb_rob(mult_div_cdb_tag),
    .valid(mult_div_valid)
);


branch_comp #(
    .ROB_DEPTH(ROB_DEPTH)
) branch_comp (
    .rs1_v(branch_rs1_v),
    .rs2_v(branch_rs2_v),
    .pc(branch_pc),
    .imm(branch_imm),
    .instr(branch_instr_in),
    .branch_tag(branch_tag),
    .comp_issue(branch_comp_issue),

    .cdb_data(branch_result),
    .cdb_valid(branch_valid),
    .cdb_tag(branch_cdb_tag),
    .pc_next(branch_pc_next),
    .branch_resp(branch_resp),
    .br_take(br_take),
    .pc_compare(pc_compare),
    .branch_pc_opcode(branch_pc_opcode)
);

cdb #(
    .CDB_SIZE(4),
    .ROB_DEPTH(ROB_DEPTH)
) cdb (
    .exe_tag(exe_tag),
    .data_in(data_in),
    .exe_done(exe_done),

    .valid_CDB(valid_CDB),
    .tag_CDB(tag_CDB),
    .data_CDB(data_CDB)
);


endmodule : cpu
