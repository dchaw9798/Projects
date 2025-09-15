module instruction_queue_old #(
    parameter INSTR_DEPTH = 4, 
    parameter INSTR_WIDTH = 32
) (
    input logic clk,
    input logic rst,

    // outputing whether the instruction queue is full and the valid/opcode information
    // we assume the instr_push and instr_pop are always correct
    //output logic instr_full,
    //output logic instr_valid,
    //output logic instr_ready,

    input logic instr_push,
    input logic instr_pop,

    input logic [31:0] instr_in,
    output logic is_empty,
    output logic is_full,
    output logic [31:0] instr_out,
    output logic instr_issue
);

  logic [INSTR_WIDTH - 1:0] instr_arr[INSTR_DEPTH]; // total 4 blocks queue

    //check how many elements in the queue
  logic [2:0] number_element;
  logic empty;
  logic full;

  //head for pop position, tail for 
  logic [1:0] head, tail;

//full: 16 elements;
//empty: 0 elements;
always_comb begin
    empty = 1'b0;
    full = 1'b0;
    if(number_element == '0) begin
        empty = 1'b1;
    end
    if(number_element == INSTR_DEPTH) begin
        full = 1'b1;
    end
end

assign is_empty = empty;
assign is_full = full;

always_ff @(posedge clk) begin
    //if reset or flush, set all values 0
    if (rst) begin
      head <= '0;
      tail <= '0;
      number_element <= '0;
      instr_issue <= '0;
    end 

    else begin
        if (instr_push & !full) begin
            if(!instr_pop) begin
                if(tail != (INSTR_DEPTH-1)) begin
                    instr_arr[tail] <= instr_in;
                    tail <= tail + 1'b1;
                    number_element <= number_element + 1'b1;
                end
                else begin
                    instr_arr[tail] <= instr_in;
                    tail <= '0;
                    number_element <= number_element + 1'b1;                
                end
            end
            else begin
                if(tail != (INSTR_DEPTH-1)) begin
                    instr_arr[tail] <= instr_in;
                    tail <= tail + 1'b1;
                end
                else begin
                    instr_arr[tail] <= instr_in;
                    tail <= '0;              
                end     
            end           
	    end
        // pop instruction if it's valid
        if (instr_pop & !empty) begin
            instr_issue <= 1'b1;
            if(!instr_push) begin
                if(head != (INSTR_DEPTH-1)) begin
                    //instr_out <= instr_arr[head];
                    instr_arr[head] <= '0;
                    head <= head + 1'b1;
                    number_element <= number_element - 1'b1;
                end
                else begin
                    //instr_out <= instr_arr[head];
                    instr_arr[head] <= '0;
                    head <= '0;
                    number_element <= number_element - 1'b1;
                end 
            end  
            else begin
                if(head != (INSTR_DEPTH-1)) begin
                    //instr_out <= instr_arr[head];
                    instr_arr[head] <= '0;
                    head <= head + 1'b1;
                end
                else begin
                    //instr_out <= instr_arr[head];
                    instr_arr[head] <= '0;
                    head <= '0;
                end 
            end                           
        end

    end
end

always_comb begin
	instr_out = '0;
	if(instr_pop) begin
		instr_out = instr_arr[head];
	end
end


endmodule
