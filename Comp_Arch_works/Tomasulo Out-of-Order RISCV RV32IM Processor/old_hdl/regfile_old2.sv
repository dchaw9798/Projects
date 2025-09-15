module regfile_old_infile #(
    ROB_DEPTH = 3
)(
    input logic clk,
    input logic rst,
    input logic flush,

    // from rob to reg_file
    input logic commit_reg_write,
    input logic [4:0] commit_rd_s,
    input logic [31:0] commit_rd_v,
    input logic [ROB_DEPTH - 1:0] commit_rob,

    // overwrite the scoreboard when instruction is issued
    input logic issue,
    input logic [6:0] issue_opcode,
    input logic [4:0] issue_rd_s,
    input logic [ROB_DEPTH - 1:0] issue_rob,

    // read from registerfile when instruction is issued
    input  logic [4:0] issue_rs1_s,
    input  logic [4:0] issue_rs2_s,
    output logic [31:0] issue_rs1_s_reg_v,
    output logic [31:0] issue_rs2_s_reg_v,
    output logic [ROB_DEPTH - 1:0] issue_rs1_reg_rob,
    output logic [ROB_DEPTH - 1:0] issue_rs2_reg_rob,
    output logic issue_rs1_reg_valid,
    output logic issue_rs2_reg_valid
);

  logic [31:0] register_file[32];
  logic [ROB_DEPTH - 1:0] rob_tag[32];
  logic rob_tag_valid[32];


  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 32; i++) begin
        register_file[i] <= '0;
        rob_tag[i] <= '0;
        rob_tag_valid[i] <= '0;
      end
    end 

    else begin 
        //if committed rob matches the one in regfile and it is valid, delete it 
        if (commit_reg_write && (commit_rd_s != 5'd0)) begin
            register_file[commit_rd_s] <= commit_rd_v;
            if((commit_rob == rob_tag[commit_rd_s]) & (rob_tag_valid[commit_rd_s] == 1'b1)) begin
                rob_tag[commit_rd_s] <= '0;
                rob_tag_valid[commit_rd_s] <= '0;
            end
        end

        //issue instruction -> ROB, ROB gives issue_rob address to our regfile
        if (issue && (issue_rd_s != 5'd0)) begin
            if (issue_opcode != 7'b1100011 && issue_opcode != 7'b0100011) begin
                rob_tag[issue_rd_s] <= issue_rob; //issue_rob = tail of our ROB
                rob_tag_valid[issue_rd_s] <= '1;
            end
        end

        //if flush, we flush every rob_tag and valid, keep regfile data
        if (flush) begin
            for (int i = 0; i < 32; i++) begin
                rob_tag[i] <= '0;
                rob_tag_valid[i] <= '0;
            end
        end
    end
  end
  always_comb begin
    issue_rs1_s_reg_v = '0;
    issue_rs2_s_reg_v = '0;
    issue_rs1_reg_rob = '0;
    issue_rs2_reg_rob = '0;
    issue_rs1_reg_valid = ~rob_tag_valid[issue_rs1_s];
    issue_rs1_reg_valid = ~rob_tag_valid[issue_rs2_s];
    if(rob_tag_valid[issue_rs1_s] != 1'b1) begin
        issue_rs1_s_reg_v = register_file[issue_rs1_s];
    end
    if(rob_tag_valid[issue_rs2_s] != 1'b1) begin
        issue_rs2_s_reg_v = register_file[issue_rs2_s];
    end
    if(rob_tag_valid[issue_rs1_s] == 1'b1) begin
        issue_rs1_reg_rob = rob_tag[issue_rs1_s];       
    end
    if(rob_tag_valid[issue_rs2_s] == 1'b1) begin
        issue_rs2_reg_rob = rob_tag[issue_rs2_s];
    end
  end

endmodule
