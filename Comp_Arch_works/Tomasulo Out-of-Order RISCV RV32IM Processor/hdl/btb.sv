module btb
import rv32im_types::*;
#(
    parameter BTB_DEPTH = 2
) (
    input logic         clk,
    input logic         rst,
    input logic         br_take,
    input logic [31:0]  pc,
    input logic         rob_commit,
    input logic [31:0]  commit_pc,
    input logic [31:0]  commit_pc_next,
    input logic [6:0]   commit_opcode,
    input logic         predict_take,
    output logic [31:0] btb_pc_next
    //output logic        mispredict
);

localparam NUM_ELEMENT = 2 ** BTB_DEPTH;

//br prediction arr
logic                   br_valid_arr[NUM_ELEMENT];
logic [31:0]            br_pc_arr[NUM_ELEMENT];
logic [31:0]            br_pc_target_arr[NUM_ELEMENT];

//jump prediction arr
logic                   jr_valid_arr[NUM_ELEMENT];
logic [31:0]            jr_pc_arr[NUM_ELEMENT];
logic [31:0]            jr_pc_target_arr[NUM_ELEMENT];

//br logic 
logic                   br_update;
logic                   br_validate;
logic [BTB_DEPTH - 1:0] br_update_index;
logic [BTB_DEPTH - 1:0] br_validate_index;
logic [BTB_DEPTH - 1:0] br_else;

//jump logic 
logic                   jr_update;
logic                   jr_validate;
logic [BTB_DEPTH - 1:0] jr_update_index;
logic [BTB_DEPTH - 1:0] jr_validate_index;
logic [BTB_DEPTH - 1:0] jr_else;

always_ff @(posedge clk) begin
    if(rst) begin
        for(int i = 0; i < NUM_ELEMENT; i ++) begin
            br_valid_arr[i] <= '0;
            jr_valid_arr[i] <= '0;
            br_pc_arr[i] <= '0;
            br_pc_target_arr[i] <= '0;
            br_else <= '0;
            jr_pc_arr[i] <= '0;
            jr_pc_target_arr[i] <= '0;  
            jr_else <= '0;  
        end   
    end
    else begin
        if(rob_commit && br_take) begin
            if(commit_opcode == op_b_br) begin
                if(br_update) begin
                    br_pc_arr[br_update_index] <= commit_pc;
                    br_pc_target_arr[br_update_index] <= commit_pc_next;                  
                end
                else if(br_validate) begin
                    br_valid_arr[br_validate_index] <= '1;
                    br_pc_arr[br_validate_index] <= commit_pc;
                    br_pc_target_arr[br_validate_index] <= commit_pc_next;
                end
                else begin
                    br_pc_arr[br_else] <= commit_pc;
                    br_pc_target_arr[br_else] <= commit_pc_next;
                    br_else             <= br_else + 1'b1;                     
                end
            end
            else if ((commit_opcode == op_b_jal) || (commit_opcode == op_b_jalr)) begin
                if (jr_update) begin
                    jr_pc_arr[jr_update_index] <= commit_pc;
                    jr_pc_target_arr[jr_update_index] <= commit_pc_next;                           
                end
                else if(jr_validate) begin
                    jr_valid_arr[jr_validate_index] <= '1;
                    jr_pc_arr[jr_validate_index] <= commit_pc;
                    jr_pc_target_arr[jr_validate_index] <= commit_pc_next;                   
                end
                else begin
                    jr_pc_arr[jr_else] <= commit_pc;
                    jr_pc_target_arr[jr_else] <= commit_pc_next;
                    jr_else             <= jr_else + 1'b1;                     
                end
            end
        end

    end
end

// always_comb begin
//     mispredict = '0;
//     if((commit_opcode == op_b_br) || (commit_opcode == op_b_jal) || (commit_opcode == op_b_jalr)) begin
//         mispredict = 1'b1;
//         for (int i = 0; i < NUM_ELEMENT; i++) begin
//             if(commit_pc == br_pc_arr[i] && br_valid_arr[i]) begin
//                 if(commit_pc_next != br_pc_target_arr[i]) begin
//                     mispredict = 1'b1;
//                 end
//                 else if(commit_pc_next == br_pc_target_arr[i] && !predict_take)begin
//                     mispredict = 1'b1;
//                 end
//                 else begin
//                     mispredict = '0;
//                 end
//             end
//             else if (commit_pc == jr_pc_arr[i] && jr_valid_arr[i]) begin
//                 if(commit_pc_next != jr_pc_target_arr[i]) begin
//                     mispredict = 1'b1;
//                 end
//                 else if(commit_pc_next == jr_pc_target_arr[i] && !predict_take)begin
//                     mispredict = 1'b1;
//                 end
//                 else begin
//                     mispredict = '0;
//                 end
//             end
//         end
//     end
// end

always_comb begin
    br_update = '0;
    br_validate = '0;
    br_update_index = '0;
    br_validate_index = '0;
    jr_update = '0;
    jr_validate = '0;
    jr_update_index = '0;
    jr_validate_index = '0;
    if ((commit_opcode == op_b_br) || (commit_opcode == op_b_jal) || (commit_opcode == op_b_jalr)) begin
        for (int unsigned i = 0; i < NUM_ELEMENT; i++) begin
            if (commit_opcode == op_b_br) begin
                if (br_valid_arr[i] && (br_pc_arr[i] == commit_pc)) begin
                    br_update = 1'b1;
                    br_update_index = (BTB_DEPTH)'(i);
                end
                if (!br_valid_arr[i]) begin
                    br_validate = 1'b1;
                    br_validate_index = (BTB_DEPTH)'(i);
                end
            end 
            else begin
                if (jr_valid_arr[i] && (jr_pc_arr[i] == commit_pc)) begin
                    jr_update = 1'b1;
                    jr_update_index = (BTB_DEPTH)'(i);
                end
                if (!jr_valid_arr[i]) begin
                    jr_validate = 1'b1;
                    jr_validate_index = (BTB_DEPTH)'(i);
                end
            end
        end
    end
end

always_comb begin
    if(rst) begin
        btb_pc_next = 32'h1eceb000;
    end
    else begin
        btb_pc_next = pc + 'd4;
        for(int i = 0; i < NUM_ELEMENT; i++) begin
            if(predict_take && br_valid_arr[i] && (pc == br_pc_arr[i])) begin
                btb_pc_next = br_pc_target_arr[i];
                break;
            end
            else if (jr_valid_arr[i] && (pc == jr_pc_arr[i])) begin
                btb_pc_next = jr_pc_target_arr[i];
                break;
            end
        end
    end
end

endmodule
