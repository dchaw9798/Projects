module cdb #(
    parameter CDB_SIZE  = 4, //0.load/store // 1.alu // 2.mult/div // 3.branch
    parameter ROB_DEPTH = 8
)
(
    input   logic [$clog2(ROB_DEPTH) - 1:0] exe_tag[CDB_SIZE],
    input   logic [31:0]                    data_in[CDB_SIZE],
    input   logic                           exe_done [CDB_SIZE],

    output  logic                           valid_CDB[CDB_SIZE],
    output  logic [$clog2(ROB_DEPTH) - 1:0] tag_CDB[CDB_SIZE],
    output  logic [31:0]                    data_CDB[CDB_SIZE]
);
  
    always_comb begin
        for (int i = 0; i < CDB_SIZE; i++) begin
            valid_CDB[i] = exe_done[i];
            data_CDB[i]  = data_in[i];
            tag_CDB[i]   = exe_tag[i];
        end
    end

endmodule

