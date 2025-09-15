module iq_control (
    input logic branch_rs_full,
    input logic load_store_rs_full,
    input logic alu_rs_full,
    input logic mult_div_rs_full,
    input logic rob_full,
    input logic instr_valid,
    output logic instr_pop
);


always_comb begin
    instr_pop = '0;
    if(!branch_rs_full & !load_store_rs_full & !alu_rs_full & !mult_div_rs_full & !rob_full & instr_valid) begin
        instr_pop = 1'b1;
    end
end
endmodule