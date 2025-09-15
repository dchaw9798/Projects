module mult_div 
#(
    parameter ROB_DEPTH = 4,
    parameter MUL_CYCLE = 8,
    parameter DIV_CYCLE = 16
)
(
    input logic clk,
    input logic rst,
    input logic [31:0] mult_div_instr_in,
    input logic [31:0] rs1_v,
    input logic [31:0] rs2_v,
    input logic [$clog2(ROB_DEPTH)-1:0] rob_tag,
    input logic mult_div_en,
    input logic flush,
    
    output logic mult_div_resp,
    output logic [31:0] mult_div_result,
    output logic [$clog2(ROB_DEPTH)-1:0] cdb_rob,
    output logic valid
);

logic [32:0] rs2_v_ext;
assign rs2_v_ext = {1'b0, rs2_v};

logic sumult_start,sumult_done;
logic [64:0] sumult_product;
logic umult_start,umult_done;
logic [63:0] umult_product;
logic smult_start,smult_done;
logic [63:0] smult_product; 
logic udiv_start,udiv_done;
logic [31:0] udiv_q,udiv_r;
logic sdiv_start,sdiv_done;
logic [31:0] sdiv_q,sdiv_r;
logic [2:0] funct3;
logic sdiv_0,udiv_0;
//logic valid;

    typedef enum logic [3:0] {
        IDLE  = 4'b0000,
        EX_UMULT  = 4'b0010,
        EX_SMULT  = 4'b0011,
        EX_SUMULT = 4'b0100,
        EX_UDIV = 4'b0101,
        EX_SDIV = 4'b0110,
        UMULT_DONE = 4'b1100,
        SMULT_DONE = 4'b1101,
        SUMULT_DONE = 4'b1110,
        SDIV_DONE = 4'b1111,
        UDIV_DONE = 4'b1011
    } fsm_state_t;

    // Declare the state variables
    fsm_state_t state;
//logic [1:0] state;  //000:IDLE, 001:EX_SMULT,010:EX_UMULT,011:EX_SMULT,100:, 10:DONE


assign funct3 = mult_div_instr_in[14:12];

always_ff @(posedge clk) begin
    if(rst | flush) begin
        state <= IDLE;
    end
    else begin
        if(state == IDLE) begin
            if(umult_start) begin
                state <= EX_UMULT;
            end
            else if (smult_start) begin
                state <= EX_SMULT;
            end
            else if (sumult_start) begin
                state <= EX_SUMULT;
            end
            else if (sdiv_start) begin
                state <= EX_SDIV;
            end
            else if (udiv_start) begin
                state <= EX_UDIV;
            end
            else begin 
                state <= IDLE;
            end
        end
        if(state == EX_UMULT) begin
            if(umult_done) begin
                state <= UMULT_DONE;
            end
            else begin
                state <= EX_UMULT;
            end
        end
        if(state == EX_SMULT) begin
            if(smult_done) begin
                state <= SMULT_DONE;
            end
            else begin
                state <= EX_SMULT;
            end
        end
        if(state == EX_SUMULT) begin
            if(sumult_done) begin
                state <= SUMULT_DONE;
            end
            else begin
                state <= EX_SUMULT;
            end
        end
        if(state == EX_SDIV) begin
            if(sdiv_done) begin
                state <= SDIV_DONE;
            end
            else begin
                state <= EX_SDIV;
            end
        end
        if(state == EX_UDIV) begin
            if(udiv_done) begin
                state <= UDIV_DONE;
            end
            else begin
                state <= EX_UDIV;
            end
        end
        if((state == UDIV_DONE) | (state == SDIV_DONE) | (state == SMULT_DONE) | (state == UMULT_DONE) | (state == SUMULT_DONE)) begin
            state <= IDLE;
        end
    end
end

always_comb begin
    mult_div_resp = '0;
    mult_div_result = '0;
    umult_start = '0;
    smult_start = '0;
    sumult_start = '0;
    udiv_start = '0;
    sdiv_start = '0;
    valid = '0;
    cdb_rob = '0;
    if(mult_div_en) begin
        if(state == IDLE) begin
        case (funct3)
            3'b000: smult_start = '1;
            3'b001: smult_start = '1;
            3'b010: sumult_start = '1;
            3'b011: umult_start = '1;
            3'b100: sdiv_start = '1;
            3'b101: udiv_start = '1;
            3'b110: sdiv_start = '1;
            3'b111: udiv_start = '1;
        endcase
        end
        if (umult_done & (state == UMULT_DONE)) begin
            mult_div_result = umult_product[63:32];
            mult_div_resp = 1'b1;
            cdb_rob = rob_tag;
            valid = 1'b1;
        end
        else if (smult_done& (state == SMULT_DONE)) begin
            if(funct3 == 3'b000) begin
                mult_div_result = smult_product[31:0];
                mult_div_resp = 1'b1; 
                cdb_rob = rob_tag;
                valid = 1'b1; 
            end
            else begin
                mult_div_result = smult_product[63:32];
                mult_div_resp = 1'b1; 
                cdb_rob = rob_tag;
                valid = 1'b1; 
            end
        end
        else if (sumult_done& (state == SUMULT_DONE)) begin
            mult_div_result = sumult_product[63:32];
            mult_div_resp = 1'b1; 
            cdb_rob = rob_tag;
            valid = 1'b1; 
        end        
        else if (sdiv_done& (state == SDIV_DONE)) begin
            if(sdiv_0 != 1'b1) begin
                if(funct3 == 3'b100) begin
                    mult_div_result = sdiv_q;
                    mult_div_resp = 1'b1; 
                    cdb_rob = rob_tag;
                    valid = 1'b1;           
                end
                else if(funct3 == 3'b110) begin
                    mult_div_result = sdiv_r;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;
                end
            end
            else begin
                if(funct3 == 3'b100) begin
                    mult_div_result = 32'hFFFFFFFF;
                    mult_div_resp = 1'b1; 
                    cdb_rob = rob_tag;
                    valid = 1'b1;           
                end
                else if(funct3 == 3'b110) begin
                    mult_div_result = rs1_v;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;
                end                
            end
        end
        else if (udiv_done& (state == UDIV_DONE)) begin
            if(udiv_0 != 1'b1) begin
                if(funct3 == 3'b101) begin
                    mult_div_result = udiv_q;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;          
                end
                else if(funct3 == 3'b111) begin
                    mult_div_result = udiv_r;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;
                end
            end
            else begin
                if(funct3 == 3'b101) begin
                    mult_div_result = udiv_q;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;          
                end
                else if(funct3 == 3'b111) begin
                    mult_div_result = rs1_v;
                    mult_div_resp = 1'b1;  
                    cdb_rob = rob_tag;
                    valid = 1'b1;
                end                
            end
        end
    end

end

// logic flush_reg;
// always_ff @(posedge clk) begin
//     if (rst) begin
//         flush_reg <= 1'b0;
//     end
//     else begin
//         if(mult_div_en) begin
//             if (flush) begin
//                 flush_reg <= flush;
//             end
//             else if (flush_reg) begin
//                 if (mult_div_resp) begin
//                     flush_reg <= 1'b0;
//                 end
//             end
//         end
//     end
// end

// assign valid_cdb = valid & ~flush_reg;
DW_mult_seq #(32, 33, 1, MUL_CYCLE, 0, 1, 1, 0) 
    sumult (
    .clk(clk),
    .rst_n(~rst),
    .hold('0),
    .start(sumult_start),
    .a(rs1_v),
    .b(rs2_v_ext),
    .complete(sumult_done),
    .product(sumult_product)
);

DW_mult_seq #(32, 32, 0, MUL_CYCLE, 0, 1, 1, 0) 
    umult (
    .clk(clk),
    .rst_n(~rst),
    .hold('0),
    .start(umult_start),
    .a(rs1_v),
    .b(rs2_v),
    .complete(umult_done),
    .product(umult_product)
);

DW_mult_seq #(32, 32, 1, MUL_CYCLE, 0, 1, 1, 0) 
    smult (
    .clk(clk),
    .rst_n(~rst),
    .hold('0),
    .start(smult_start),
    .a(rs1_v),
    .b(rs2_v),
    .complete(smult_done),
    .product(smult_product)
);

DW_div_seq #(32, 32, 0, DIV_CYCLE, 0, 1, 1, 0) 
    udiv (
    .clk(clk),
    .rst_n(~rst),
    .hold('0),
    .start(udiv_start),
    .a(rs1_v),
    .b(rs2_v),
    .complete(udiv_done),
    .divide_by_0(udiv_0),
    .quotient(udiv_q),
    .remainder(udiv_r)
);

DW_div_seq #(32, 32, 1, DIV_CYCLE, 0, 1, 1, 0) 
    sdiv (
    .clk(clk),
    .rst_n(~rst),
    .hold('0),
    .start(sdiv_start),
    .a(rs1_v),
    .b(rs2_v),
    .complete(sdiv_done),
    .divide_by_0(sdiv_0),
    .quotient(sdiv_q),
    .remainder(sdiv_r)
);
endmodule
