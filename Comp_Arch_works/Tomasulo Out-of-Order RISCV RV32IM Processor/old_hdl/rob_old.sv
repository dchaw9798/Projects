module rob_old# (
    parameter ROB_DEPTH = 8,
    parameter CDB_SIZE = 4
) (
    // order + 1 when commit
    input   logic                           clk,
    input   logic                           rst,
    input   logic                           flush,

    input   logic cdb_valid [CDB_SIZE],
    input   logic [$clog2(ROB_DEPTH) - 1:0] rob_tag [CDB_SIZE],
    input   logic [31:0]                    data_out [CDB_SIZE],
    output  logic                           rob_pop,

    input   logic                           rob_push, //from control to determine when to push
    input   logic [4:0]                     issue_rd_s,

    //input valid = pop
    input   logic [63:0]                    rvfi_order,
    input   logic [31:0]                    rvfi_inst,
    input   logic [4:0]                     rvfi_rs1_s,
    input   logic [4:0]                     rvfi_rs2_s,
    input   logic [4:0]                     rvfi_rd_s,
    input   logic [31:0]                    rvfi_pc,
    input   logic [31:0]                    rvfi_pc_next,

    output  logic                           rob_full,
    output  logic [$clog2(ROB_DEPTH) - 1:0] issue_rob,
    output  logic [4:0]                     issue_rs1_ready,
    output  logic [4:0]                     issue_rs2_ready,
    output  logic [31:0]                    issue_rs1_v,
    output  logic [31:0]                    issue_rs2_v,

    input   logic [$clog2(ROB_DEPTH) - 1:0] issue_rs1_rob,
    input   logic [$clog2(ROB_DEPTH) - 1:0] issue_rs2_rob
     
);
//rvfi signls 
localparam NUM_ELEMS = 2 ** $clog2(ROB_DEPTH) - 1'b1;
logic [63:0] rvfi_order_arr[NUM_ELEMS];
logic [31:0] rvfi_inst_arr[NUM_ELEMS];
logic [4:0] rvfi_rs1_s_arr[NUM_ELEMS];
logic [4:0] rvfi_rs2_s_arr[NUM_ELEMS];
logic [4:0] rvfi_rd_s_arr[NUM_ELEMS];
logic [31:0] rvfi_pc_arr[NUM_ELEMS];
logic [31:0] rvfi_pc_next_arr[NUM_ELEMS];
// logic [31:0] rvfi_mem_addr_arr[NUM_ELEMS];
// logic [3:0] rvfi_mem_rmask_arr[NUM_ELEMS];
// logic [3:0] rvfi_mem_wmask_arr[NUM_ELEMS];
// logic [31:0] rvfi_mem_rdata_arr[NUM_ELEMS];
// logic [31:0] rvfi_mem_wdata_arr[NUM_ELEMS];

logic [63:0] rvfi_order_head;
logic [31:0] rvfi_inst_head;
logic [4:0] rvfi_rs1_s_head;
logic [4:0] rvfi_rs2_s_head;
logic [4:0] rvfi_rd_s_head;
logic [31:0] rvfi_rd_v_head;
logic [31:0] rvfi_pc_head;
logic [31:0] rvfi_pc_next_head;
// logic [31:0] rvfi_mem_addr_head;
// logic [3:0] rvfi_mem_rmask_head;
// logic [3:0] rvfi_mem_wmask_head;
// logic [31:0] rvfi_mem_rdata_head;
// logic [31:0] rvfi_mem_wdata_head;

logic [31:0] number_element;
logic [$clog2(ROB_DEPTH) - 1:0] head, tail;
logic [4:0] issue_rd_s_array [NUM_ELEMS];

//ROB to Regfile signals
logic [4:0] rd_s_arr[NUM_ELEMS];
logic [31:0] rd_v_arr[NUM_ELEMS];

logic ready_arr [NUM_ELEMS];
logic valid_arr [NUM_ELEMS];

assign issue_rob = tail;

always_comb begin
    rob_full = '0;
    if(number_element == NUM_ELEMS) begin
        rob_full = 1'b1;
    end
end

always_comb begin
    rob_pop = 1'b0;
    //if head tag is ready and valid, pop
    if(valid_arr[head] & ready_arr[head]) begin
        rob_pop = 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (rst | flush) begin
        head <= '0;
        tail <= '0;
        number_element <= '0;
        for (int i = 0; i < NUM_ELEMS; i++) begin
            valid_arr[i] <= '0;
            ready_arr[i] <= '0;
            rd_s_arr[i] <= '0;
            rvfi_order_arr[i] <= '0;
            rvfi_inst_arr[i] <= '0;
            rvfi_rs1_s_arr[i] <= '0;
            rvfi_rs2_s_arr[i] <= '0;
            rvfi_rd_s_arr[i] <= '0;
            rvfi_pc_arr[i] <= '0;
            rvfi_pc_next_arr[i] <= '0;
            // rvfi_mem_addr_arr[i] <= '0;
            // rvfi_mem_rmask_arr[i] <= '0;
            // rvfi_mem_wmask_arr[i] <= '0;
            // rvfi_mem_rdata_arr[i] <= '0;
            // rvfi_mem_wdata_arr[i] <= '0;
        end
    end
    else begin
        //check if the data in CDB valid, if it is, match the tag and put data into that array
        for (int i = 0; i < CDB_SIZE; ++i) begin
            if (cdb_valid[i]) begin
                ready_arr[rob_tag[i]] <= '1;
                rd_v_arr[rob_tag[i]]  <= data_out[i];
            end
        end
        if(rob_pop) begin
            if(number_element == '0) begin
                head <= '0;
            end
            else begin
                head <= head + 1'b1;
                number_element <= number_element - 1'b1;
            end
            valid_arr[head] <= '0;
            ready_arr[head] <= '0;
            rd_s_arr[head] <= '0;
            rvfi_order_arr[head] <= '0;
            rvfi_inst_arr[head] <= '0;
            rvfi_rs1_s_arr[head] <= '0;
            rvfi_rs2_s_arr[head] <= '0;
            rvfi_rd_s_arr[head] <= '0;
            rvfi_pc_arr[head] <= '0;
            rvfi_pc_next_arr[head] <= '0;
            // rvfi_mem_addr_arr[head] <= '0;
            // rvfi_mem_rmask_arr[head] <= '0;
            // rvfi_mem_wmask_arr[head] <= '0;
            // rvfi_mem_rdata_arr[head] <= '0;
            // rvfi_mem_wdata_arr[head] <= '0;       
        end
        if(rob_push) begin
            if(number_element == NUM_ELEMS) begin
                tail <= '0;
            end
            else begin
                tail <= tail + 1'b1;
                number_element <= number_element + 1'b1;
            end
            valid_arr[tail] <= 1'b1;
            ready_arr[tail] <= 1'b0;
            rd_s_arr[tail] <= issue_rd_s;
            rvfi_order_arr[tail] <= rvfi_order;
            rvfi_rs1_s_arr[tail] <= rvfi_rs1_s;
            rvfi_rs2_s_arr[tail] <= rvfi_rs2_s;
            rvfi_rd_s_arr[tail] <= rvfi_rd_s;
            rvfi_pc_arr[tail] <= rvfi_pc;
            rvfi_pc_next_arr[tail] <= rvfi_pc_next;
            rvfi_inst_arr[tail] <= rvfi_inst;
            // rvfi_mem_addr_arr[tail] <= '0;
            // rvfi_mem_rmask_arr[tail] <= '0;
            // rvfi_mem_wmask_arr[tail] <= '0;
            // rvfi_mem_rdata_arr[tail] <= '0;
            // rvfi_mem_wdata_arr[tail] <= '0;   
        end
    end
end

always_comb begin
    issue_rs1_ready = '0;
    issue_rs1_v = '0;
    issue_rs2_ready = '0;
    issue_rs2_v = '0;
    if (valid_arr[issue_rs1_rob] == 1'b1) begin

        for (int i = 0; i < CDB_SIZE; i++) begin
            if ((cdb_valid[i] == 1'b1) & (rob_tag[i] == issue_rs1_rob)) begin
                issue_rs1_ready = '1;
                issue_rs1_v = data_out[i];
            end
        end

        if (ready_arr[issue_rs1_rob] == 1'b1) begin
            issue_rs1_ready = '1;
            issue_rs1_v = rd_v_arr[issue_rs1_rob];
        end
    end

    if (valid_arr[issue_rs2_rob] == 1'b1) begin

        for (int i = 0; i < CDB_SIZE; i++) begin
            if (cdb_valid[i] && (rob_tag[i] == issue_rs2_rob)) begin
                issue_rs2_ready = '1;
                issue_rs2_v = data_out[i];
            end
        end     

        if (ready_arr[issue_rs2_rob] == 1'b1) begin
            issue_rs2_ready = '1;
            issue_rs2_v = rd_v_arr[issue_rs2_rob];
        end
    end
end


//assign rvfi signal to head of rob
  always_comb begin
    rvfi_order_head = rvfi_order_arr[head];
    rvfi_inst_head = rvfi_inst_arr[head];
    rvfi_rs1_s_head = rvfi_rs1_s_arr[head];
    rvfi_rs2_s_head = rvfi_rs2_s_arr[head];
    rvfi_rd_s_head = rvfi_rd_s_arr[head];
    rvfi_rd_v_head = rd_v_arr[head];
    rvfi_pc_head = rvfi_pc_arr[head];
    rvfi_pc_next_head = rvfi_pc_next_arr[head];
    // rvfi_mem_addr_head = rvfi_mem_addr_arr[head];
    // rvfi_mem_rmask_head = rvfi_mem_rmask_arr[head];
    // rvfi_mem_wmask_head = rvfi_mem_wmask_arr[head];
    // rvfi_mem_rdata_head = rvfi_mem_rdata_arr[head];
    // rvfi_mem_wdata_head = rvfi_mem_wdata_arr[head];
  end

endmodule
