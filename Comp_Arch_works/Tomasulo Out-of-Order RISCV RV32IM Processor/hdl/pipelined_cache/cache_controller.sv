module cache_controller 
import rv32im_types::*;
(
    input                   clk,
    input                   rst,
    input   logic           tag_match,        // Tag match (1: match, 0: no match)
    input   logic           dirty_bit,        // Dirty bit (1: modified, 0: not modified)
    input   logic           ufp_read_1,
    input   logic           ufp_write_1,
    input   logic           valid_1[4],
    input   logic   [1:0]   way_replace,
    input   logic           dfp_resp,
    input   logic   [1:0]   cache_state,
    //input   logic   [3:0]   write_hit_counter,
    //input   logic           ufp_rw_1,
    //input   logic           stall_state,
    //output  logic           stall,
    output  logic           hit,             // Output: 1 if cache hit
    output  logic           clean_miss_1,      // Output: 1 if clean miss
    output  logic           dirty_miss_1,       // Output: 1 if dirty miss
    output  logic           ufp_resp,
    output  logic   [1:0]   cache_write,
    output  logic   [1:0]   data_state
);

    logic ufp_rw_1;
    assign ufp_rw_1 = ufp_read_1 | ufp_write_1;

    enum logic [1:0] {
        data_exist,
        wait_data,
        data_arrived,
        data_finished
    } state, state_next;
    assign data_state = state;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= data_exist;
        end 
        else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = data_exist;
        if (ufp_rw_1) begin
            case(state)
                data_exist: begin
                    if (hit) begin
                        state_next = data_exist;
                    end
                    else begin
                        state_next = wait_data;
                    end
                end
                wait_data: begin
                    if (dfp_resp) begin
                        state_next = data_arrived;
                    end
                    else begin
                        state_next = wait_data;
                    end
                end
                data_arrived: begin
                    state_next = data_finished;
                end
                data_finished: begin
                    state_next = data_exist;
                end
                default:
                    state_next = data_exist;
            endcase
        end
        else begin
            state_next = data_exist;
        end
    end

    always_comb begin
        cache_write   = no_write;
        if (cache_state == 2'b00) begin
            cache_write = no_write;
        end
        // else if (dirty_miss_1) begin
        //     cache_write = no_write;
        // end
        else begin
            case(state)
                data_exist: begin
                    if (hit) begin
                        if (ufp_read_1) begin
                            cache_write = no_write;
                        end
                        if (ufp_write_1) begin
                            cache_write = write_cpu;
                        end
                    end
                    else begin
                        cache_write = write_mem;
                    end
                end
                wait_data: begin
                    cache_write = write_mem;
                end
                data_arrived: begin
                    if (ufp_read_1) begin
                        cache_write = no_write;
                    end
                    if (ufp_write_1) begin
                        cache_write = write_cpu;
                    end
                end
                data_finished: begin
                    if (hit) begin
                        cache_write = no_write;
                    end
                    else begin
                        cache_write = write_mem;
                    end
                end
                
                default: begin
                    cache_write = no_write;
                end
            endcase
        end
    end


    // Internal logic
    always_comb begin
        // Default outputs
        hit           = 1'b0;
        clean_miss_1  = 1'b0;
        dirty_miss_1  = 1'b0;
        ufp_resp      = 1'b0;
        //cache_write   = 2'b00;
        
       
        if (ufp_rw_1) begin
            if (tag_match) begin
                // If valid bit is 1 and tag matches, it's a hit
                hit         = 1'b1;
                // if (write_hit_counter == 4'b0001 && ufp_write_1) begin
                //     ufp_resp = 1'b0;
                // end
                //else begin
                    ufp_resp    = 1'b1;
                //end


                //ufp_resp    = 1'b1;
                //cache_write = no_write;
                // if (ufp_read_1) begin
                //     cache_write = no_write;
                // end
                // if (ufp_write_1) begin
                //     cache_write = write_cpu;
                // end
            end 
            
            else begin
                if (~valid_1[way_replace]) begin
                    clean_miss_1  = 1'b1;
                    
                    ufp_resp      = 1'b0;
                    // if (ufp_read_1) begin
                    //     cache_write = write_mem;
                    // end
                    // if (ufp_write_1) begin
                    //     cache_write = write_mem;
                    // end
                end
                else begin
                    // If valid bit is 1 but tag doesn't match
                    if (dirty_bit) begin
                        // If dirty bit is 1, it's a dirty miss
                        dirty_miss_1  = 1'b1;
                        
                        ufp_resp      = 1'b0;
                        // if (ufp_read_1) begin
                        //     cache_write = write_mem;
                        // end
                        // if (ufp_write_1) begin
                        //     cache_write = write_mem;
                        // end
                    end else begin
                        // If dirty bit is 0, it's a clean miss
                        clean_miss_1  = 1'b1;
                        
                        ufp_resp      = 1'b0;
                        // if (ufp_read_1) begin
                        //     cache_write = write_mem;
                        // end
                        // if (ufp_write_1) begin
                        //     cache_write = write_mem;
                        // end
                    end
                end
            end
        end
      
    end

    

endmodule : cache_controller
