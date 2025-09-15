module rob
import rv32im_types::*;
#(
    parameter ROB_DEPTH = 8,
    parameter CDB_SIZE = 4 //alu: 0, mul_div: 1, load_store: 2, branch: 3
) (
    // order + 1 when commit
    input   logic                           clk,
    input   logic                           rst,
    output   logic                          flush,

    // CDB side signal
    input   logic                           valid_CDB[CDB_SIZE],
    input   logic [$clog2(ROB_DEPTH) - 1:0] tag_CDB[CDB_SIZE],
    input   logic [31:0]                    data_CDB[CDB_SIZE],

    output  logic                           rob_commit,

    // decoder side signal
    input   logic                           iq_issue, 
    input   logic                           decoder_valid,
    input   logic [31:0]                    decoder_instr,
    input   logic [4:0]                     decoder_rs1_s,
    input   logic [4:0]                     decoder_rs2_s,
    input   logic [4:0]                     decoder_rd_s,
    input   logic                           decoder_regf_we,
    input   logic [31:0]                    decoder_pc,
    input   logic [31:0]                    decoder_pc_next,
    input   logic                           decoder_pc_next_valid,
    output  logic                           rob_full,
    
    // regfile side signal
    output  logic                           regf_commit_regf_we,
    output  logic [4:0]                     regf_commit_rd_s,
    output  logic [31:0]                    regf_commit_rd_v,
    output  logic [$clog2(ROB_DEPTH)-1:0]   regf_commit_tag,

    output  logic [4:0]                     regf_issue_rd_s,
    output  logic [$clog2(ROB_DEPTH)-1:0]   regf_issue_tag,

    // rs side signal
    input   logic [$clog2(ROB_DEPTH)-1:0]   rs_tag[CDB_SIZE], // connect to RS tag_dest_out output
    input   logic [31:0]                    rs_rs1_v[CDB_SIZE], // connect to RS data_A_out output
    input   logic [31:0]                    rs_rs2_v[CDB_SIZE], // connect to RS data_B_out output
    input   logic                           rs_ready[CDB_SIZE], // connect to RS comp_issue output


    // branch side signal
    input   logic [31:0]                    branch_pc_next,
    input   logic                           br_take,

    // fetch side signal
    output  logic [31:0]                    fetch_pc_next, //take this when flush happen, otherwise use pc_next from btb
    output  logic [31:0]                    commit_pc,
    output  logic [6:0]                     commit_opcode,
    output  logic                           commit_br_take,
    output  logic [31:0]                    commit_pc_next,

    // lsq side signal
    input   logic [31:0]                    lsq_dmem_addr, //for rvfi
    input   logic [3:0]                     lsq_dmem_rmask, //for rvfi
    input   logic [3:0]                     lsq_dmem_wmask, //for rvfi
    input   logic [31:0]                    lsq_dmem_rdata, //for rvfi
    input   logic [31:0]                    lsq_dmem_wdata, //for rvfi
    output  logic [$clog2(ROB_DEPTH)-1:0]   lsq_commit_tag

    //btb side siganl
    //input logic                             mispredict
    // rvfi connection signal
    //output  rvfi_t                          rvfi
);
    rvfi_t                          rvfi;

    logic                           valid_arr[ROB_DEPTH];
    logic [31:0]                    instr_arr[ROB_DEPTH];
    logic [4:0]                     rs1_s_arr[ROB_DEPTH];
    logic [4:0]                     rs2_s_arr[ROB_DEPTH];
    logic [31:0]                    rs1_v_arr[ROB_DEPTH];
    logic [31:0]                    rs2_v_arr[ROB_DEPTH];
    logic [4:0]                     rd_s_arr[ROB_DEPTH];
    logic [31:0]                    rd_v_arr[ROB_DEPTH];
    logic [31:0]                    pc_arr[ROB_DEPTH];
    logic [31:0]                    pc_next_arr[ROB_DEPTH];
    logic                           pc_next_valid_arr[ROB_DEPTH];
    logic [31:0]                    dmem_addr[ROB_DEPTH];
    logic [3:0]                     dmem_rmask[ROB_DEPTH];
    logic [3:0]                     dmem_wmask[ROB_DEPTH];
    logic [31:0]                    dmem_rdata[ROB_DEPTH];
    logic [31:0]                    dmem_wdata[ROB_DEPTH];

   
    logic                           regf_we_arr[ROB_DEPTH];
    logic                           commit_ready_arr [ROB_DEPTH]; // verify rd_data is ready
    logic [63:0]                    order, order_next; //counter for commited instruction
    logic [$clog2(ROB_DEPTH) - 1:0] rob_head, rob_tail; // head pointing to commit row, tail pointing to issue row

    logic                           br_take_arr[ROB_DEPTH];
    // logic [31:0]                    branch_target_pc_arr[ROB_DEPTH];
    logic                           br_flush_arr[ROB_DEPTH];

    //performance counter
    logic [63:0]                    flush_count;
    logic [63:0]                    br_count;
   
    assign regf_commit_regf_we    = regf_we_arr[rob_head];
    assign regf_commit_rd_s       = rd_s_arr[rob_head];
    assign regf_commit_rd_v       = rd_v_arr[rob_head];
    assign regf_commit_tag        = rob_head;
    assign regf_issue_rd_s        = decoder_rd_s;
    assign regf_issue_tag         = rob_tail;
    assign lsq_commit_tag         = rob_head;

    always_ff @(posedge clk) begin
        if(rst) begin
            flush_count <= '0;
            br_count <= '0;
        end
        else begin
            if(commit_br_take) begin
                br_count <= br_count + 'd1;
            end
            if(flush) begin
                flush_count <= flush_count + 'd1;
            end
        end
    end

    //rob_full logic
    always_comb begin
        rob_full  = 1'b1;  
        for (int i = 0; i < ROB_DEPTH; i++) begin
            rob_full  &= valid_arr[i];
        end 
    end
    
    //commit logic
    always_comb begin
        rob_commit = 1'b0;
        if (valid_arr[rob_head] & commit_ready_arr[rob_head]) begin
            rob_commit = 1'b1;
        end
    end

    //flush logic
    // always_comb begin
    //     flush = '0;
    //     fetch_pc_next = 'x;
    //     if(rob_commit) begin
    //         if(pc_next_arr[rob_head] == pc_arr[rob_head] +'d4 ) begin
    //             flush = '0;
    //         end
    //         else begin
    //             flush = 1'b1;
    //             fetch_pc_next = pc_next_arr[rob_head];
    //         end
    //     end
    // end

    always_comb begin
        flush = '0;
        commit_br_take = '0;
        if (commit_opcode == op_b_br || commit_opcode == op_b_jal || commit_opcode == op_b_jalr) begin
            if (br_flush_arr[rob_head]) begin
                flush = '1;
            end
            if (br_take_arr[rob_head]) begin
                commit_br_take = '1;
            end
        end
    end

    assign fetch_pc_next = pc_next_arr[rob_head];


    //head tail logic
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            rob_head <= '0;
            rob_tail <= '0;
        end
        else begin
            if (iq_issue) begin
                rob_tail <= rob_tail + ($clog2(ROB_DEPTH))'(1);
            end
            if (rob_commit) begin
                rob_head <= rob_head + ($clog2(ROB_DEPTH))'(1);
            end
        end
    end

    //rob data logic
    always_ff @(posedge clk) begin
        if (rst) begin
            order       <= '0;
        end
        if (rst | flush) begin
            if (rob_commit) begin
                order <= order + 'd1;
            end
            for (int i = 0; i < ROB_DEPTH; i++) begin
                valid_arr[i]            <= '0;
                instr_arr[i]            <= '0;
                rs1_s_arr[i]            <= '0;
                rs2_s_arr[i]            <= '0;
                rs1_v_arr[i]            <= '0;
                rs2_v_arr[i]            <= '0;
                rd_s_arr[i]             <= '0;
                rd_v_arr[i]             <= '0;
                pc_arr[i]               <= '0;
                pc_next_arr[i]          <= '0;
                pc_next_valid_arr[i]    <= '0;
                regf_we_arr[i]          <= '0;
                commit_ready_arr [i]    <= '0;
                br_take_arr[i]          <= '0;
                // branch_target_pc_arr[i]     <= '0;
                br_flush_arr[i]         <= '0;
                dmem_addr[i]   <= '0;
                dmem_rmask[i]  <= '0;
                dmem_wmask[i]  <= '0;
                dmem_rdata[i]  <= '0;
                dmem_wdata[i]  <= '0;
            end

        end
        else begin
            for (int unsigned i = 0; i < ROB_DEPTH; i++) begin
                for (int j = 0; j < CDB_SIZE; j++) begin
                    if (!commit_ready_arr[i] && valid_arr[i] && valid_CDB[j]) begin 
                        if (tag_CDB[j] == ($clog2(ROB_DEPTH))'(i)) begin

                            if (j == 32'(2)) begin
                                dmem_addr[i]             <= lsq_dmem_addr;
                                dmem_rmask[i]            <= lsq_dmem_rmask;
                                dmem_wmask[i]            <= lsq_dmem_wmask;
                                dmem_rdata[i]            <= lsq_dmem_rdata;
                                dmem_wdata[i]            <= lsq_dmem_wdata;
                                if (regf_we_arr[i]) begin
                                    rd_v_arr[i]           <= data_CDB[j];
                                    commit_ready_arr[i]   <= 1'b1;
                                    // if (pc_next_valid_arr[i] == 1'b0) begin
                                    //     pc_next_arr[i]        <= branch_pc_next;
                                    // end
                                end
                            end
                            if(valid_CDB[3]) begin
                                commit_ready_arr[i]   <= 1'b1;
                                if ((pc_next_arr[tag_CDB[3]] != branch_pc_next)) begin
                                    br_flush_arr[tag_CDB[3]] <= '1;
                                    pc_next_arr[tag_CDB[3]] <= branch_pc_next;
                                end
                                if (br_take) begin
                                    br_take_arr[tag_CDB[3]] <= '1;
                                end
                            end
                            if (regf_we_arr[i]) begin
                                rd_v_arr[i]           <= data_CDB[j];
                                commit_ready_arr[i]   <= 1'b1;
                                // if (pc_next_valid_arr[i] == 1'b0) begin
                                //     pc_next_arr[i]        <= branch_pc_next;
                                // end
                            end

                            // if (!pc_next_valid_arr[i]) begin
                            //     pc_next_arr[i]        <= branch_pc_next;
                            //     commit_ready_arr[i]   <= 1'b1;
                            // end
                            else begin // for store instruction
                                commit_ready_arr[i]   <= 1'b1;
                            end

                        end
                    end
                end
                for (int j = 0; j < CDB_SIZE; j++) begin
                    if (rs_ready[j] && valid_arr[i] && (rs_tag[j] == $clog2(ROB_DEPTH)'(i))) begin
                        rs1_v_arr[i] <= rs_rs1_v[j];
                        rs2_v_arr[i] <= rs_rs2_v[j];
                    end
                end
            end
            if (rob_commit) begin
                order                         <= order + 'd1;
                valid_arr[rob_head]           <= '0;
                instr_arr[rob_head]           <= '0;
                rs1_s_arr[rob_head]           <= '0;
                rs2_s_arr[rob_head]           <= '0;
                rs1_v_arr[rob_head]           <= '0;
                rs2_v_arr[rob_head]           <= '0;
                rd_s_arr[rob_head]            <= '0;
                rd_v_arr[rob_head]            <= '0;
                pc_arr[rob_head]              <= '0;
                pc_next_arr[rob_head]         <= '0;
                pc_next_valid_arr[rob_head]   <= '0;
                commit_ready_arr [rob_head]   <= '0;
                dmem_addr[rob_head]                     <= '0;
                dmem_rmask[rob_head]                    <= '0;
                dmem_wmask[rob_head]                    <= '0;
                dmem_rdata[rob_head]                    <= '0;
                dmem_wdata[rob_head]                    <= '0;
                br_take_arr[rob_head]         <= '0;
                // branch_target_pc_arr[rob_head]<= '0;
                br_flush_arr[rob_head]        <= '0;
            end
            if (iq_issue) begin
                valid_arr[rob_tail]           <= decoder_valid;
                instr_arr[rob_tail]           <= decoder_instr;
                rs1_s_arr[rob_tail]           <= decoder_rs1_s;
                rs2_s_arr[rob_tail]           <= decoder_rs2_s;
                rd_s_arr[rob_tail]            <= decoder_rd_s;
                pc_arr[rob_tail]              <= decoder_pc;
                pc_next_arr[rob_tail]         <= decoder_pc_next;
                pc_next_valid_arr[rob_tail]   <= decoder_pc_next_valid;
                regf_we_arr[rob_tail]         <= decoder_regf_we;

            end
        end
    end

    
    //assign rvfi signal
    always_comb begin
        rvfi.valid      = rob_commit;
        rvfi.order      = order;
        rvfi.inst       = instr_arr[rob_head];
        rvfi.rs1_addr   = rs1_s_arr[rob_head];
        rvfi.rs2_addr   = rs2_s_arr[rob_head];
        rvfi.rs1_rdata  = rs1_v_arr[rob_head];
        rvfi.rs2_rdata  = rs2_v_arr[rob_head];
        rvfi.rd_addr    = rd_s_arr[rob_head];
        rvfi.rd_wdata   = rd_v_arr[rob_head];
        rvfi.pc_rdata   = pc_arr[rob_head];
        rvfi.pc_wdata   = pc_next_arr[rob_head];
        rvfi.dmem_addr  = dmem_addr[rob_head];
        rvfi.dmem_rmask = dmem_rmask[rob_head];
        rvfi.dmem_wmask = dmem_wmask[rob_head];
        rvfi.dmem_rdata = dmem_rdata[rob_head];
        rvfi.dmem_wdata = dmem_wdata[rob_head];
    end

assign commit_pc = pc_arr[rob_head];
assign commit_pc_next = pc_next_arr[rob_head];
assign commit_opcode = instr_arr[rob_head][6:0];

endmodule
