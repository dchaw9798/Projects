module regfile #(
    parameter ROB_DEPTH = 4
)(
    input   logic                           clk,
    input   logic                           rst,
    input   logic                           flush, //flush the tag in regfile when branch

    // rob side signal when commit
    input   logic                           rob_commit,
    input   logic                           rob_commit_regf_we,
    input   logic [4:0]                     rob_commit_rd_s,
    input   logic [31:0]                    rob_commit_rd_v,
    input   logic [$clog2(ROB_DEPTH) - 1:0] rob_commit_tag,
    // rob side signal when issue
    input   logic [4:0]                     rob_issue_rd_s,
    input   logic [$clog2(ROB_DEPTH) - 1:0] rob_issue_tag,

    // iq side signal when issue
    input   logic                           iq_issue,
   
    // decoder side signal
    input   logic [4:0]                     decoder_rs1_s,
    input   logic [4:0]                     decoder_rs2_s,
    output  logic [31:0]                    decoder_rs1_v,
    output  logic [31:0]                    decoder_rs2_v,
    output  logic [$clog2(ROB_DEPTH) - 1:0] decoder_rs1_tag,
    output  logic [$clog2(ROB_DEPTH) - 1:0] decoder_rs2_tag,
    output  logic                           decoder_rs1_ready,
    output  logic                           decoder_rs2_ready,
    output  logic [$clog2(ROB_DEPTH) - 1:0] decoder_rd_tag
);

    logic [31:0]                    reg_file[32];
    logic [$clog2(ROB_DEPTH) - 1:0] tag_arr[32];
    logic                           ready_arr[32];

    assign decoder_rd_tag = rob_issue_tag;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                reg_file[i]   <= '0;
                tag_arr[i]    <= '0;
                ready_arr[i]  <= 1'b1;
            end
        end 

        else begin 
            //if committed rob matches the one in regfile and it is valid, delete it 
            if (rob_commit & rob_commit_regf_we && (rob_commit_rd_s != 5'd0)) begin
                reg_file[rob_commit_rd_s] <= rob_commit_rd_v;
                if ((rob_commit_tag == tag_arr[rob_commit_rd_s]) && (ready_arr[rob_commit_rd_s] == 1'b0)) begin
                    tag_arr[rob_commit_rd_s]    <= '0;
                    ready_arr[rob_commit_rd_s]  <= 1'b1;
                end
                else begin
                    tag_arr[rob_commit_rd_s]    <= tag_arr[rob_commit_rd_s];
                    ready_arr[rob_commit_rd_s]  <= ready_arr[rob_commit_rd_s];
                end
            end


            //issue instruction -> ROB, ROB gives rob_issue_tag address to our regfile
            if (iq_issue && (rob_issue_rd_s != 5'd0)) begin
                //reg_file[rob_issue_rd_s]  <= reg_file[rob_issue_rd_s];
                tag_arr[rob_issue_rd_s]   <= rob_issue_tag; //rob_issue_tag = tail of our ROB
                ready_arr[rob_issue_rd_s] <= 1'b0;
            end

            
            //if flush, we flush every tag_arr and valid, keep regfile data
            if (flush) begin
                for (int i = 0; i < 32; i++) begin
                    tag_arr[i]    <= '0;
                    ready_arr[i]  <= 1'b1;
                end
            end
        end
    end

    // output signal assign, data forwarding from ROB considered
    always_comb begin
        decoder_rs1_v       = (decoder_rs1_s != 5'd0) ? reg_file[decoder_rs1_s] : '0;
        decoder_rs2_v       = (decoder_rs2_s != 5'd0) ? reg_file[decoder_rs2_s] : '0;
        decoder_rs1_tag     = (decoder_rs1_s != 5'd0) ? tag_arr[decoder_rs1_s] : '0;
        decoder_rs2_tag     = (decoder_rs2_s != 5'd0) ? tag_arr[decoder_rs2_s] : '0;
        decoder_rs1_ready   = (decoder_rs1_s != 5'd0) ? ready_arr[decoder_rs1_s] : 1'b1;
        decoder_rs2_ready   = (decoder_rs2_s != 5'd0) ? ready_arr[decoder_rs2_s] : 1'b1;
        // if (rob_commit_rd_s == decoder_rs1_s) begin
        //     decoder_rs1_v = rob_commit_rd_v;
        //     decoder_rs1_tag = '0;
        //     decoder_rs1_ready = 1'b1;
        // end
        // if (rob_commit_rd_s == decoder_rs2_s) begin
        //     decoder_rs2_v = rob_commit_rd_v;
        //     decoder_rs2_tag = '0;
        //     decoder_rs2_ready = 1'b1;
        // end
        // else begin
        //     decoder_rs1_v       = (decoder_rs1_s != 5'd0) ? reg_file[decoder_rs1_s] : '0;
        //     decoder_rs2_v       = (decoder_rs2_s != 5'd0) ? reg_file[decoder_rs2_s] : '0;
        //     decoder_rs1_tag     = (decoder_rs1_s != 5'd0) ? tag_arr[decoder_rs1_s] : '0;
        //     decoder_rs2_tag     = (decoder_rs2_s != 5'd0) ? tag_arr[decoder_rs2_s] : '0;
        //     decoder_rs1_ready   = (decoder_rs1_s != 5'd0) ? ready_arr[decoder_rs1_s] : 1'b1;
        //     decoder_rs2_ready   = (decoder_rs2_s != 5'd0) ? ready_arr[decoder_rs2_s] : 1'b1;
        // end
    end

endmodule
