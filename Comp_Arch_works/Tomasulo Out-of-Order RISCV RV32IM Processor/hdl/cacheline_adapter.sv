module cacheline_adapter (
    input  logic          clk, 
    input  logic          rst, 

    // cache side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic           ufp_read,
    input   logic           ufp_write, //for data_cache
    input   logic   [255:0] ufp_wdata,
    output  logic   [255:0] ufp_rdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write, //for data_cache
    output  logic   [63:0]  dfp_wdata, //for data_cache
    input   logic           dfp_ready,
    input   logic   [31:0]  dfp_raddr,
    input   logic   [63:0]  dfp_rdata,
    input   logic           dfp_rvalid
);

    // State machine parameters
    enum logic [1:0] {
        IDLE,
        READ_BURST,
        WRITE_BURST,
        DONE
    } state, state_next;

    logic [1:0] count, count_next;  // counter for data receive cycles 

    // Registers to hold the 256-bit data
    logic [255:0] data_buffer;
    // Registers to hold 32 bit read address from dram
    logic [31:0] addr_buffer;

    always_ff @(posedge clk) begin
        state <= state_next;
        count <= count_next;
    end
    always_comb begin
        state_next = IDLE;
        count_next = 2'b00;
        if (rst) begin
            state_next = IDLE;
            count_next = 2'b00;
        end
        else begin
            case(state)
                IDLE: begin
                    count_next = 2'b00;
                    if (ufp_read) begin
                        state_next = READ_BURST;
                    end
                    else if (ufp_write) begin
                        state_next = WRITE_BURST;
                    end
                    else begin
                        state_next = IDLE;
                    end
                end
                READ_BURST: begin
                    count_next = count;
                    if (dfp_rvalid) begin
                        if (dfp_raddr == addr_buffer) begin
                            count_next = count + 1'b1;
                            if (count == 2'b11) begin
                                state_next = DONE;
                            end
                            else begin
                                state_next = READ_BURST;
                            end
                        end
                        else begin
                            state_next = READ_BURST;
                        end
                    end
                    else begin
                        state_next = READ_BURST;
                        count_next = count;
                    end

                end
                WRITE_BURST: begin
                    count_next = count + 1'b1;
                    if (count == 2'b11) begin
                        state_next = DONE;
                    end
                    else begin
                        state_next = WRITE_BURST;
                    end
                end
                DONE: begin
                    state_next = IDLE;
                    count_next = count;
                end
                
                default: begin
                    state_next = IDLE;
                    count_next = count;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        case(state)
            IDLE: begin
                data_buffer <= 'x;
                if (ufp_read) begin
                    addr_buffer <= ufp_addr;
                end
                if (ufp_write) begin
                    data_buffer <= ufp_wdata;
                    addr_buffer <= ufp_addr;
                end
            end

            READ_BURST: begin
                if (dfp_raddr == addr_buffer && dfp_rvalid && count == 2'b00) begin
                    data_buffer <= {192'b0, dfp_rdata};
                end
                if (dfp_raddr == addr_buffer && dfp_rvalid && count == 2'b01) begin
                    data_buffer <= {128'b0, dfp_rdata, data_buffer[63:0]};
                end
                if (dfp_raddr == addr_buffer && dfp_rvalid && count == 2'b10) begin
                    data_buffer <= {64'b0, dfp_rdata, data_buffer[127:0]};
                end
                if (dfp_raddr == addr_buffer && dfp_rvalid && count == 2'b11) begin
                    data_buffer <= {dfp_rdata, data_buffer[191:0]};
                end
            end

            WRITE_BURST: begin
                if (ufp_write && count == 2'b11) begin
                    data_buffer <= 'x;
                    addr_buffer <= 'x;
                end
                else begin
                    data_buffer <= data_buffer;
                    addr_buffer <= addr_buffer;
                end
            end

            DONE: begin
                    addr_buffer <= 'x;
                    data_buffer <= 'x;
            end
            default: begin
                data_buffer <= 'x;
                addr_buffer <= 'x;
            end
        endcase
    end

    always_comb begin
        ufp_rdata = 'x;
        ufp_resp  = 1'b0;
        
        dfp_read  = ufp_read;
        dfp_addr  = ufp_addr;

        dfp_write = ufp_write;
        dfp_wdata = 'x;

        case(state)
            IDLE: begin
                ufp_rdata = 'x;
                ufp_resp  = 1'b0;
                dfp_read  = ufp_read;
                dfp_write = 1'b0;
                dfp_addr  = ufp_addr;
                dfp_wdata = 'x;
            end
            READ_BURST: begin
                ufp_rdata = 'x;
                ufp_resp  = 1'b0;
                dfp_read  = 1'b0;
                dfp_write = 1'b0;
                dfp_addr  = 'x;
                dfp_wdata = 'x;
            end

            WRITE_BURST: begin
                ufp_rdata = 'x;
                ufp_resp  = 1'b0;
                dfp_read  = 1'b0;
                dfp_write = 1'b1;
                dfp_addr  = addr_buffer;
                if (count == 2'b00) begin
                    dfp_wdata = data_buffer[63:0];
                end
                else if (count == 2'b01) begin
                    dfp_wdata = data_buffer[127:64];
                end
                else if (count == 2'b10) begin
                    dfp_wdata = data_buffer[191:128];
                end
                else if (count == 2'b11) begin
                    dfp_wdata = data_buffer[255:192];
                end
                 
            end
            DONE: begin
                ufp_rdata = data_buffer;
                ufp_resp  = 1'b1;
                dfp_read  = 1'b0;
                dfp_write = 1'b0;
                dfp_addr  = 'x;
                dfp_wdata = 'x;
            end
            default: begin
                ufp_rdata = 'x;
                ufp_resp  = 1'b0;
                dfp_read  = ufp_read;
                dfp_write = 1'b0;
                dfp_addr  = ufp_addr;
                dfp_wdata = 'x;
            end
        endcase
    end

    always_comb begin
        if (dfp_ready) begin
        end
        else begin
        end
    end






//     // Assign data_out to data_buffer when transfer is complete
//     assign data_out = data_buffer;

//     // State machine for data accumulation
//     always_ff @(posedge clk) begin
//         if (rst) begin
//             state <= IDLE;
//             index <= 2'b00;
//             data_buffer <= 256'b0;
//             ready_out <= 1'b0;
//         end else begin
//             case (state)
//                 IDLE: begin
//                     ready_out <= 1'b0;
//                     if (enable) begin
//                         state <= ACCUMULATE;
//                         index <= 2'b00;
//                     end
//                 end
//                 ACCUMULATE: begin
//                     if (valid_in) begin
//                         case (index)
//                             2'b00: data_buffer[63:0]   <= data_in;
//                             2'b01: data_buffer[127:64]  <= data_in;
//                             2'b10: data_buffer[191:128] <= data_in;
//                             2'b11: data_buffer[255:192] <= data_in;
//                         endcase
//                         if (index == 2'b11) begin
//                             state <= DONE;
//                         end else begin
//                             index <= index + 1;
//                         end
//                     end
//                 end
//                 DONE: begin
//                     ready_out <= 1'b1;  // Indicate the 256-bit output is valid
//                     if (!enable) begin
//                         state <= IDLE;
//                     end
//                 end
//             endcase
//         end
//     end

endmodule
