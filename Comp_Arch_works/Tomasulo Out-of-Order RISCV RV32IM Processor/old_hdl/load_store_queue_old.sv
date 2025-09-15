// module load_store_queue_old
// import rv32im_types::*;
// #(
//     parameter QUEUE_DEPTH = 8
// ) (
//     input   logic                           clk,
//     input   logic                           rst,
//     input   logic                           flush,

//     //decoder side signal
//     input   logic                           iq_issue,
//     input   logic [31:0]                    decoder_instr,
//     input   logic [2:0]                     decoder_tag,

//     // load_store_adder side signal
//     input   logic [31:0]                    load_store_addr,
//     input   logic                           valid_addr,
//     input   logic                           adder_resp,

//     // RS side signal
//     input   logic [31:0]                    store_data, 
//     input   logic [2:0]                     rs_tag,


//     // decoder side signal
//     output  logic                           lsq_full,
    
//     // dcache side signal
//     output  logic [31:0]                    dmem_wdata,
//     output  logic [3:0]                     dmem_rmask,
//     output  logic [3:0]                     dmem_wmask,
//     input   logic                           dmem_resp,
//     input   logic [31:0]                    dmem_rdata,

//     // CDB side signal
//     output  logic                           cdb_valid,
//     output  logic [31:0]                    cdb_data,
//     output  logic [2:0]                     cdb_tag

// );
//     logic [31:0]                    decoder_instr_arr[QUEUE_DEPTH];
//     logic                           valid_addr_arr[QUEUE_DEPTH];
//     logic [31:0]                    load_store_addr_arr[QUEUE_DEPTH];
//     logic [31:0]                    store_data_arr[QUEUE_DEPTH];
//     logic [31:0]                    dmem_rdata_arr[QUEUE_DEPTH];
//     logic [2:0]                     decoder_tag_arr[QUEUE_DEPTH];
//     logic [3:0]                     rmask_arr[QUEUE_DEPTH];
//     logic [3:0]                     wmask_arr[QUEUE_DEPTH];
//     logic                           commit_ready_arr[QUEUE_DEPTH];

//     logic [$clog2(QUEUE_DEPTH) - 1:0] lsq_head, lsq_tail;
//     logic                           lsq_commit;

//     //lsq_full logic
//     always_comb begin
//         lsq_full  = 1'b1;  
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             lsq_full  &= valid_addr_arr[i];
//         end 
//     end
    
//     //commit logic
//     always_comb begin
//         lsq_commit = 1'b0;
//         if (valid_addr_arr[lsq_head] & dmem_resp) begin
//             lsq_commit = 1'b1;
//         end
//     end
//     //head tail logic
//     always_ff @(posedge clk) begin
//         if (rst || flush) begin
//             lsq_head <= '0;
//             lsq_tail <= '0;
//         end
//         else begin
//             if (iq_issue) begin
//                 lsq_tail <= lsq_tail + ($clog2(QUEUE_DEPTH))'(1);
//             end
//             if (lsq_commit) begin
//                 lsq_head <= lsq_head + ($clog2(QUEUE_DEPTH))'(1);
//             end
//         end
//     end

//     //mask logic
//     always_comb begin
//         for (int unsigned i = 0; i < QUEUE_DEPTH; i++) begin
//             rmask_arr[i] = '0;
//             wmask_arr[i] = '0;
//             dmem_wdata = '0;
//             if(valid_addr[lsq_head]) begin
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     rmask_arr[lsq_head] = 4'b0001 << load_store_addr_arr[lsq_head][1:0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lbu)) begin
//                     rmask_arr[lsq_head] = 4'b0001 << load_store_addr_arr[lsq_head][1:0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lh)) begin
//                     rmask_arr[lsq_head] = 4'b0011 << load_store_addr_arr[lsq_head][1:0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lhu)) begin
//                     rmask_arr[lsq_head] = 4'b0011 << load_store_addr_arr[lsq_head][1:0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lw)) begin
//                     rmask_arr[lsq_head] = 4'b1111;
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_store) && (decoder_instr_arr[lsq_head][14:12] == store_f3_sb)) begin
//                     wmask_arr[lsq_head] = 4'b0001 << load_store_addr_arr[lsq_head][1:0];
//                     dmem_wdata[8 *load_store_addr_arr[lsq_head][1:0] +: 8 ] = store_data[7 :0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_store) && (decoder_instr_arr[lsq_head][14:12] == store_f3_sh)) begin
//                     wmask_arr[lsq_head] = 4'b0011 << load_store_addr_arr[lsq_head][1:0];
//                     dmem_wdata[16 *load_store_addr_arr[lsq_head][1] +: 16 ] = store_data[15 :0];
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_store) && (decoder_instr_arr[lsq_head][14:12] == store_f3_sw)) begin
//                     wmask_arr[lsq_head] = 4'b1111;
//                     dmem_wdata = store_data;
//                 end
//             end
//         end
//     end

//     assign dmem_rmask = rmask_arr[lsq_head];
//     assign dmem_wmask = wmask_arr[lsq_head];

//     //CDB data
//     always_ff begin
//         if(rst|flush) begin
//             cdb_data <= '0;
//             cdb_tag <= '0;
//             cdb_valid <= '0;
//         end
//         if(dmem_resp) begin
//             cdb_data <= dmem_rdata_arr[lsq_head];
//             cdb_tag <= decoder_tag_arr[lsq_head];
//             cdb_valid <= 1'b1;
//         end
//     end

//     //lsq data logic
//     always_ff @(posedge clk) begin
//         if (rst | flush) begin
//             for (int i = 0; i < QUEUE_DEPTH; i++) begin
//                 valid_addr_arr[i]    <= '0;
//                 decoder_instr_arr[i]    <= '0;
//                 load_store_addr_arr[i]    <= '0;
//                 store_data_arr[i]    <= '0;
//                 dmem_rdata_arr[i]    <= '0;
//                 decoder_tag_arr[i]    <= '0;
//                 rmask_arr[i]     <= '0;
//                 wmask_arr[i]     <= '0;
//                 commit_ready_arr [i] <= '0;
//             end
//         end
//         else begin
//             if (lsq_commit) begin
//                 decoder_tag[lsq_head]    <= '0;
//                 decoder_instr_arr[lsq_head]    <= '0;
//                 valid_addr[lsq_head]    <= '0;
//                 load_store_addr_arr[lsq_head]    <= '0;
//                 commit_ready_arr[lsq_head]    <= '0;
//             end
//             if (iq_issue) begin
//                 decoder_instr_arr[lsq_tail]   <= decoder_instr;
//                 decoder_tag[lsq_tail]   <= decoder_tag;
//             end
//             if (adder_resp) begin
//                 for (int unsigned i = 0; i < QUEUE_DEPTH; i++) begin
//                     if(decoder_tag_arr[i] == rs_tag) begin
//                         valid_addr[i]    <= valid_addr;
//                         load_store_addr_arr[i]   <= load_store_addr;
//                     end
//                 end
//             end
//             if (dmem_resp) begin
//                 cdb_valid <= 1'b1;
//                 cdb_tag <= decoder_tag_arr[lsq_head];
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     cdb_data <= {{24{dmem_rdata[7 +8 *load_store_addr_arr[lsq_head][1:0]]}}, dmem_rdata[8 *load_store_addr_arr[lsq_head][1:0] +: 8 ]};
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     cdb_data <= {{24{1'b0}}                                      , dmem_rdata[8 *load_store_addr_arr[lsq_head][1:0] +: 8 ]};
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     cdb_data <= {{16{dmem_rdata[15 +16 *load_store_addr_arr[lsq_head][1]]}}, dmem_rdata[16 *load_store_addr_arr[lsq_head][1] +: 16 ]};
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     cdb_data <= {{16{1'b0}}                                      , dmem_rdata[16 *load_store_addr_arr[lsq_head][1] +: 16 ]};
//                 end
//                 if((decoder_instr_arr[lsq_head][6:0] == op_b_load) && (decoder_instr_arr[lsq_head][14:12] == load_f3_lb)) begin
//                     cdb_data <= dmem_rdata;
//                 end
//             end

//         end
//     end


// endmodule
