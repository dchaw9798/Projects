// module arbitor #(
//     parameter ROB_DEPTH = 8
// ) (
//     input logic clk,
//     input logic rst,

//     // in_resp should be continully high before out_resp send a high signal back to RS to clear the issue feed into the computation unit
//     input logic        in_resp0, // signal from computation unit to indicate the computation has finished by the computation unit
//     input logic        in_resp1, // signal from computation unit to indicate the computation has finished by the computation unit
//     input logic        in_resp2, // signal from computation unit to indicate the computation has finished by the computation unit
//     input logic        in_resp3, // signal from computation unit to indicate the computation has finished by the computation unit

//     input logic [31:0] in_instr0,
//     input logic [31:0] in_instr1,
//     input logic [31:0] in_instr2,
//     input logic [31:0] in_instr3,

//     input logic [31:0] din0,
//     input logic [31:0] din1,
//     input logic [31:0] din2,
//     input logic [31:0] din3,

//     input logic [$clog2(ROB_DEPTH)-1:0] in_rob_tag0,
//     input logic [$clog2(ROB_DEPTH)-1:0] in_rob_tag1,
//     input logic [$clog2(ROB_DEPTH)-1:0] in_rob_tag2,
//     input logic [$clog2(ROB_DEPTH)-1:0] in_rob_tag3,

//     output logic        out_resp0, // signal goes back to RS to indicate the computation has finished, and the RS can be marked clean
//     output logic        out_resp1, // signal goes back to RS to indicate the computation has finished, and the RS can be marked clean
//     output logic        out_resp2, // signal goes back to RS to indicate the computation has finished, and the RS can be marked clean
//     output logic        out_resp3, // signal goes back to RS to indicate the computation has finished, and the RS can be marked clean

//     output logic [31:0] out_instr,
//     output logic [31:0] dout,
//     output logic [$clog2(ROB_DEPTH)-1:0] out_rob_tag
// );


// logic [1:0] gate; // control which input channel can be sent to output

// // gate number circulates from 00 to 11 for each clock cycle
// always_ff @(posedge clk) begin
//     if (rst) begin
//         gate <= 2'b00;
//     end
//     else begin
//         if (gate == 2'b11) begin
//             gate <= 2'b00;
//         end
//         else begin
//             gate <= gate + 2'b01;
//         end
//     end
// end

// // output assign
// // gate number has highest priority for output selection.
// always_comb begin
//     case (gate)
//     2'b00: begin
//         if (in_resp0) begin
//             out_resp0   = in_resp0;
//             out_instr   = in_instr0;
//             dout        = din0;
//             out_rob_tag = in_rob_tag0;
//         end
//         else begin
//             out_resp0   = 1'b0;
//             out_instr   = in_instr0;
//             dout        = din0;
//             out_rob_tag = {$clog2(ROB_DEPTH){1'b1}};
//         end
//     end
//     2'b01: begin
//         if (in_resp1) begin
//             out_resp1   = in_resp1;
//             out_instr   = in_instr1;
//             dout        = din1;
//             out_rob_tag = in_rob_tag1;
//         end
//         else begin
//             out_resp1   = 1'b0;
//             out_instr   = in_instr1;
//             dout        = din1;
//             out_rob_tag = {$clog2(ROB_DEPTH){1'b1}};
//         end
//     end
//     2'b10: begin
//         if (in_resp2) begin
//             out_resp2   = in_resp2;
//             out_instr   = in_instr2;
//             dout        = din2;
//             out_rob_tag = in_rob_tag2;
//         end
//         else begin
//             out_resp2   = 1'b0;
//             out_instr   = in_instr2;
//             dout        = din2;
//             out_rob_tag = {$clog2(ROB_DEPTH){1'b1}};
//         end
//     end
//     2'b11: begin
//         if (in_resp3) begin
//             out_resp3   = in_resp3;
//             out_instr   = in_instr3;
//             dout        = din3;
//             out_rob_tag = in_rob_tag3;
//         end
//         else begin
//             out_resp3   = 1'b0;
//             out_instr   = in_instr3;
//             dout        = din3;
//             out_rob_tag = {$clog2(ROB_DEPTH){1'b1}};
//         end
//     end
//     default: begin
//         out_resp0 = 1'b0;
//         out_resp1 = 1'b0;
//         out_resp2 = 1'b0;
//         out_resp3 = 1'b0;
//         out_instr = '0;
//         dout      = '0;
//         out_rob_tag = {$clog2(ROB_DEPTH){1'b1}};
//     end
//     endcase
// end
// endmodule