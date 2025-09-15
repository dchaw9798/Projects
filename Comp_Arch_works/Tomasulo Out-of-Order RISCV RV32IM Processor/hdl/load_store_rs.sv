module load_store_rs #(
    parameter RS_DEPTH = 4, 
    parameter ROB_DEPTH = 4
) (
    input   logic clk,
    input   logic rst,
    input   logic flush,
    //ufp side signal, connecting decoder
    input   logic [31:0]                  instr_in,
    input   logic                         valid_in, //indicates this rs array is activated (connects to comp_issue/pop from instruction queue)
    input   logic [$clog2(ROB_DEPTH)-1:0] tag_dest_in, //destination tag (ROB value)

    input   logic [$clog2(ROB_DEPTH)-1:0] tag_A_in, //ROB tag of source A (rs1_s rob tag)
    input   logic [31:0]                  data_A_in, //rs1_v read from regfile
    input   logic                         ready_A_in, //when data A is available

    input   logic [$clog2(ROB_DEPTH)-1:0] tag_B_in, //ROB tag of source B (rs2_s rob tag)
    input   logic [31:0]                  data_B_in, //imm_value read from instruction
    input   logic                         ready_B_in, //when data B is available

    input   logic [31:0]                  imm_in, //imm_value read from instruction

    output  logic                         rs_full, //tell instruction queue this rs is full
    
    //CDB side signal
    input   logic                         valid_CDB[4], //indicate this data on the CDB is valid
    input   logic [$clog2(ROB_DEPTH)-1:0] tag_CDB[4], //ROB tag on the CDB
    input   logic [31:0]                  data_CDB[4],

    //ROB to RS (when regfile's data and tag is overwritten by new instruction, forward tag and value from rob)
    input   logic                         rob_commit, 
    input   logic [31:0]                  rob_commit_rd_v,
    input   logic [$clog2(ROB_DEPTH)-1:0] rob_commit_tag,

    //addr_adder side signal
    input   logic                         resp, //resp from alu to ensure the operation has finished
    output  logic [31:0]                  data_A_out,
    output  logic [31:0]                  imm_out,
    output  logic                         comp_issue, //indicates this instruction is popped to ALU for operation

    //lsq side signal
    output  logic [31:0]                  lsq_store_data, //store data send into lsq
    output  logic [$clog2(ROB_DEPTH)-1:0] lsq_tag
);
    //assume there will be no instruction comp_issue from instruction queue (valid_in = 0) when RS if full

    logic [31:0]                  instr_arr       [RS_DEPTH]; //instruction array
    logic                         valid_arr       [RS_DEPTH]; //valid array indicate whether this array is used
    logic [$clog2(ROB_DEPTH)-1:0] tag_dest_arr    [RS_DEPTH]; //destination tag array
   
    logic [$clog2(ROB_DEPTH)-1:0] tag_A_arr       [RS_DEPTH]; //ROB for A data
    logic [31:0]                  data_A_arr      [RS_DEPTH]; //data for A data
    logic                         ready_A_arr     [RS_DEPTH]; //ready for A data

    logic [$clog2(ROB_DEPTH)-1:0] tag_B_arr       [RS_DEPTH]; //ROB for B data
    logic [31:0]                  data_B_arr      [RS_DEPTH]; //data for B data
    logic                         ready_B_arr     [RS_DEPTH]; //ready for B data

    logic [31:0]                  imm_arr         [RS_DEPTH]; //data for B data



    logic [$clog2(RS_DEPTH)-1:0]  rs_head;  //head pointer to indicate which array to pop to ALU
    logic [$clog2(RS_DEPTH)-1:0]  rs_tail;  //tail pointer to indicate which array to be pushed from instruction queue 
    logic [$clog2(RS_DEPTH)-1:0]  rs_counter; //used to search head and tail
    logic                         found_comp_issue; //indicator for comp_issue array position finding

    logic                         valid_CDB_arr[4]; //array to store 4 CDB valid
    logic [$clog2(ROB_DEPTH)-1:0] tag_CDB_arr[4]; //array to store 4 CDB tag
    logic [31:0]                  data_CDB_arr[4]; //array to store 4 CDB data



    always_ff @(posedge clk) begin
        if (rst | flush) begin
            for (int i = 0; i < RS_DEPTH; i++) begin
                instr_arr[i]    <= '0;
                valid_arr[i]    <= '0;
                tag_dest_arr[i] <= '0;
                tag_A_arr[i]    <= '0;
                data_A_arr[i]   <= '0;
                ready_A_arr[i]  <= '0;
                tag_B_arr[i]    <= '0;
                data_B_arr[i]   <= '0;
                ready_B_arr[i]  <= '0;
                imm_arr[i]      <= '0;
                end
            end
        else begin 
            for (int i = 0; i < RS_DEPTH; i++) begin
                if(rob_commit) begin
                    if (~ready_A_arr[i] && (valid_arr[i])) begin
                        if(rob_commit_tag == tag_A_arr[i]) begin
                            data_A_arr[i] <= rob_commit_rd_v;
                            tag_A_arr[i]    <= '0;
                            ready_A_arr[i]  <= 1'b1;                       
                        end
                    end
                    if (~ready_B_arr[i] && (valid_arr[i])) begin
                        if(rob_commit_tag == tag_B_arr[i]) begin
                            data_B_arr[i] <= rob_commit_rd_v;
                            tag_B_arr[i]    <= '0;
                            ready_B_arr[i]  <= 1'b1;           
                        end            
                    end
                end
                for (int j = 0; j < 4; j++) begin
                    if (valid_arr[i] && valid_CDB[j]) begin //when CDB broadcast data, compare tag. if tag match then ready pull high and data write
                        if (~ready_A_arr[i] && (tag_CDB[j] == tag_A_arr[i])) begin
                            tag_A_arr[i]    <= '0;
                            data_A_arr[i]   <= data_CDB[j];
                            ready_A_arr[i]  <= 1'b1;
                        end
                        if (~ready_B_arr[i] && (tag_CDB[j] == tag_B_arr[i])) begin
                            tag_B_arr[i]    <= '0;
                            data_B_arr[i]   <= data_CDB[j];
                            ready_B_arr[i]  <= 1'b1;
                        end 
                    end
                end
            end

            if (valid_in) begin //indicates this instruction is popped from instruction queue
                instr_arr[rs_tail]    <= instr_in;
                valid_arr[rs_tail]    <= valid_in;
                tag_dest_arr[rs_tail] <= tag_dest_in;
                tag_A_arr[rs_tail]    <= tag_A_in;
                data_A_arr[rs_tail]   <= data_A_in;
                ready_A_arr[rs_tail]  <= ready_A_in;
                tag_B_arr[rs_tail]    <= tag_B_in;
                data_B_arr[rs_tail]   <= data_B_in;
                ready_B_arr[rs_tail]  <= ready_B_in;
                imm_arr[rs_tail]      <= imm_in;

            end
           

            if (comp_issue) begin //indicates instruction currently comp_issued to ALU and the operation has finished by ALU
                if (resp) begin
                    instr_arr[rs_head]    <= '0;
                    valid_arr[rs_head]    <= '0;
                    tag_dest_arr[rs_head] <= '0;
                    tag_A_arr[rs_head]    <= '0;
                    data_A_arr[rs_head]   <= '0;
                    ready_A_arr[rs_head]  <= '0;
                    tag_B_arr[rs_head]    <= '0;
                    data_B_arr[rs_head]   <= '0;
                    ready_B_arr[rs_head]  <= '0;
                    imm_arr[rs_head]      <= '0;
                end
                else begin
                    instr_arr[rs_head]    <= instr_arr[rs_head];
                    valid_arr[rs_head]    <= valid_arr[rs_head];
                    tag_dest_arr[rs_head] <= tag_dest_arr[rs_head];
                    tag_A_arr[rs_head]    <= tag_A_arr[rs_head];
                    data_A_arr[rs_head]   <= data_A_arr[rs_head];
                    ready_A_arr[rs_head]  <= '0;
                    tag_B_arr[rs_head]    <= tag_B_arr[rs_head];
                    data_B_arr[rs_head]   <= data_B_arr[rs_head];
                    ready_B_arr[rs_head]  <= '0;
                    imm_arr[rs_head]      <= imm_arr[rs_head];
                end
            end
        end
    end
    
    //head_tail logic
    always_comb begin
        rs_tail    = '0;
        if (rst) begin
            rs_tail       = '0;
        end
        else begin
            if (rs_full) begin
                rs_tail       = '0;
            end
            else begin
                for (int unsigned i = 0; i < RS_DEPTH; i++) begin
                    if (!valid_arr[i]) begin
                        rs_tail       = ($clog2(RS_DEPTH))'(i);
                        break;
                    end
                end
            end
        end
    end
    
    
    always_ff @(posedge clk) begin
        rs_head  <= '0;
        if (rst | flush) begin
            rs_head <= '0;
        end
        else begin
            if (comp_issue & (!resp)) begin
                rs_head <= rs_head;
            end

            else begin
                for (int unsigned i = 0; i < RS_DEPTH; i++) begin
                    if (valid_arr[($clog2(RS_DEPTH))'(i+rs_counter)] && (ready_A_arr[($clog2(RS_DEPTH))'(i+rs_counter)] && ready_B_arr[($clog2(RS_DEPTH))'(i+rs_counter)])) begin
                        rs_head <= ($clog2(RS_DEPTH))'(i+rs_counter);
                        break;
                    end
                    else begin
                        rs_head <= rs_head;
                    end
                end  
            end
        end       
    end 

    always_ff @(posedge clk) begin
        if (rst | flush) begin
            rs_counter <= '0;
        end
        else if (comp_issue) begin
            rs_counter <= rs_head + 1'b1;
        end
    end


    //comp_issue logic
    always_ff @(posedge clk) begin
        if (rst | flush) begin
            found_comp_issue   <= 1'b0;
            comp_issue         <= 1'b0;
        end
        else begin
            if (comp_issue) begin
                if (resp) begin
                    found_comp_issue   <= 1'b0;
                    comp_issue         <= 1'b0;
                end
                else begin
                    found_comp_issue   <= 1'b0;
                    comp_issue         <= comp_issue;
                end
            end
            else begin
                found_comp_issue <= 1'b0;
                for (int i = 0; i < RS_DEPTH; i++) begin
                    if (!found_comp_issue && valid_arr[i] && (ready_A_arr[i] && ready_B_arr[i])) begin
                        found_comp_issue   <= 1'b1;
                        comp_issue         <= 1'b1;
                    end
                end  
            end
        end
    end

    always_comb begin
        if (comp_issue) begin
            lsq_tag           = tag_dest_arr[rs_head];
            data_A_out        = data_A_arr[rs_head];
            imm_out           = imm_arr[rs_head];
            lsq_store_data    = data_B_arr[rs_head];
        end

        else begin
            lsq_tag           = '0;
            data_A_out        = '0;
            imm_out           = '0;
            lsq_store_data    = '0;
        end
    end

    //rs_full = 1 when valid_arr all equals to 1
    always_comb begin
        rs_full    = 1'b1;
        for (int i = 0; i < RS_DEPTH; i++) begin
            rs_full &= valid_arr[i];
        end 
    end

endmodule
