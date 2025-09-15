module instruction_queue #(
    parameter IQ_DEPTH = 4, 
    parameter IQ_WIDTH = 32
) (
    // for improvement, do simultaneously push and pop if full.
    input   logic        clk,
    input   logic        rst,
    input   logic        flush,
    // fetch side signal
    input   logic        instr_push,
    input   logic [31:0] pc_in,
    input   logic [31:0] pc_next_in,
    input   logic [31:0] instr_in,
    output  logic        iq_full,
        
    // decode side signal
    input   logic        instr_pop,
    output  logic [31:0] pc_out,
    output  logic [31:0] pc_next_out,
    output  logic [31:0] instr_out,
    output  logic        iq_empty,
    output  logic        valid_out
);

    logic [(IQ_WIDTH - 1):0] instr_arr[IQ_DEPTH];
    logic [(IQ_WIDTH - 1):0] pc_arr[IQ_DEPTH];
    logic [(IQ_WIDTH - 1):0] pc_next_arr[IQ_DEPTH];
    logic                    valid_arr[IQ_DEPTH]; 

    //check how many elements in the queue
    logic [$clog2(IQ_DEPTH):0] number_element;

    //head for pop position, tail for push position
    logic [$clog2(IQ_DEPTH) - 1:0] iq_head, iq_tail;

    //full empty logic
    always_comb begin
        iq_full  = 1'b1;
        iq_empty = 1'b1;
        number_element = '0;
        for (int i = 0; i < IQ_DEPTH; i++) begin
            iq_full  &= valid_arr[i];
            iq_empty &= !valid_arr[i];
            if (valid_arr[i]) begin
                number_element += ($clog2(IQ_DEPTH)+1)'(1);
            end
        end 
    end

    // head/tail/data logic
    always_ff @(posedge clk) begin
        //if reset or flush, set all values 0
        if (rst || flush) begin
            iq_head <= '0;
            iq_tail <= '0;
            for (int i = 0; i < IQ_DEPTH; i++) begin
                instr_arr[i]    <= '0;
                pc_arr[i]       <= '0;
                pc_next_arr[i]  <= '0;
                valid_arr[i]    <= '0;
            end
        end 

        else begin
            if (instr_push & !iq_full) begin
                instr_arr[iq_tail]    <= instr_in;
                pc_arr[iq_tail]       <= pc_in;
                pc_next_arr[iq_tail]  <= pc_next_in;
                valid_arr[iq_tail]    <= 1'b1;
                iq_tail               <= iq_tail + 1'b1;
            end
            // pop instruction if it's valid
            if (instr_pop & !iq_empty) begin
                instr_arr[iq_head]    <= '0;
                pc_arr[iq_head]       <= '0;
                pc_next_arr[iq_head]  <= '0;
                valid_arr[iq_head]    <= 1'b0;
                iq_head               <= iq_head + 1'b1;
                                
            end
        end
    end
   
    assign instr_out    = instr_arr[iq_head];
    assign pc_out       = pc_arr[iq_head];
    assign pc_next_out  = pc_next_arr[iq_head];
    assign valid_out    = valid_arr[iq_head];

endmodule
