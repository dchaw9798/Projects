module bmem_arbitor (
    input logic                 clk,
    input logic                 rst,

    // icache side
    input logic [31:0]          i_dram_addr,
    input logic                 i_dram_read,
    input logic                 i_dram_write,
    input logic [63:0]          i_dram_wdata,

    output  logic               i_dram_ready,
    output  logic [31:0]        i_dram_raddr,
    output  logic [63:0]        i_dram_rdata,
    output  logic               i_dram_rvalid,

    // dcache side
    input logic [31:0]          d_dram_addr,
    input logic                 d_dram_read,
    input logic                 d_dram_write,
    input logic [63:0]          d_dram_wdata,   

    output  logic               d_dram_ready,
    output  logic [31:0]        d_dram_raddr,
    output  logic [63:0]        d_dram_rdata,
    output  logic               d_dram_rvalid, 

    // mem side
    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,

    input   logic               bmem_ready,
    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid


);
    logic [1:0]           write_counter;
    logic [31:0]          i_dram_addr_buffer;
    logic                 i_dram_read_buffer;
    logic                 i_dram_write_buffer;
    logic [63:0]          i_dram_wdata_buffer;
    
    logic [31:0]          d_dram_addr_buffer;
    logic                 d_dram_read_buffer;
    logic                 d_dram_write_buffer;
    logic [63:0]          d_dram_wdata_buffer;

    assign i_dram_write_buffer = i_dram_write;
    assign i_dram_wdata_buffer = i_dram_wdata;

    always_comb begin
        i_dram_ready    = bmem_ready;
        i_dram_raddr    = bmem_raddr;
        i_dram_rdata    = bmem_rdata;
        i_dram_rvalid   = bmem_rvalid;
        d_dram_ready    = bmem_ready;
        d_dram_raddr    = bmem_raddr;
        d_dram_rdata    = bmem_rdata;
        d_dram_rvalid   = bmem_rvalid;
    end
    
    enum logic [1:0] {
        INSTR_READ,
        DATA_READ,
        DATA_WRITE
    } state, state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= INSTR_READ;
        end
        else begin
            state <= state_next;
        end    
    end
    
    always_comb begin
        case (state)
            INSTR_READ: begin
                bmem_addr = i_dram_addr_buffer;
                bmem_read = i_dram_read_buffer;
                bmem_write = '0;
                bmem_wdata = 'x;
                state_next = INSTR_READ;
                if (d_dram_read) begin
                    state_next = DATA_READ;
                    
                end
                if (d_dram_write) begin
                    state_next = DATA_WRITE;
                    
                end
            end
            DATA_READ: begin
                state_next = INSTR_READ;
                bmem_addr = d_dram_addr_buffer;
                bmem_read = d_dram_read_buffer;
                bmem_write = d_dram_write_buffer;
                bmem_wdata = d_dram_wdata_buffer;
            end
            DATA_WRITE: begin
                bmem_addr = d_dram_addr_buffer;
                bmem_read = d_dram_read_buffer;
                bmem_write = d_dram_write_buffer;
                bmem_wdata = d_dram_wdata_buffer;
                if (write_counter == 2'b11) begin
                    state_next = INSTR_READ;
                end
                else begin
                    state_next = DATA_WRITE;
                end
            end
            default: begin
                state_next = INSTR_READ;
                bmem_addr = i_dram_addr_buffer;
                bmem_read = i_dram_read_buffer;
                bmem_write = '0;
                bmem_wdata = 'x;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            write_counter         <= '0;
            i_dram_addr_buffer    <= 'x;
            i_dram_read_buffer    <= '0;
    
            d_dram_addr_buffer    <= 'x;
            d_dram_read_buffer    <= '0;
            d_dram_write_buffer   <= '0;
            d_dram_wdata_buffer   <= 'x;
        end


        else begin
            case (state)
                INSTR_READ: begin
                    write_counter <= '0;
                    i_dram_addr_buffer <= 'x;
                    i_dram_read_buffer <= '0;

                    d_dram_addr_buffer <= '0;
                    d_dram_read_buffer <= '0;
                    d_dram_write_buffer <= '0;
                    d_dram_wdata_buffer <= '0;

                    if (d_dram_read || d_dram_write) begin
                        
                        d_dram_addr_buffer <= d_dram_addr;
                        d_dram_read_buffer <= d_dram_read;
                        d_dram_write_buffer <= d_dram_write;
                        d_dram_wdata_buffer <= d_dram_wdata;
                    end

                    if (i_dram_read) begin
                        i_dram_addr_buffer <= i_dram_addr;
                        i_dram_read_buffer <= i_dram_read;
                    end

                end
                DATA_READ: begin
                    write_counter <= '0;
                    d_dram_addr_buffer <= '0;
                    d_dram_read_buffer <= '0;
                    d_dram_write_buffer <= '0;
                    d_dram_wdata_buffer <= '0;
                    if (i_dram_read) begin
                        i_dram_addr_buffer <= i_dram_addr;
                        i_dram_read_buffer <= i_dram_read;
                    end
                end
                DATA_WRITE: begin
                    write_counter <= write_counter + 1'b1;
                    d_dram_addr_buffer <= d_dram_addr;
                    d_dram_read_buffer <= d_dram_read;
                    d_dram_write_buffer <= d_dram_write;
                    d_dram_wdata_buffer <= d_dram_wdata;
                    if (i_dram_read) begin
                        i_dram_addr_buffer <= i_dram_addr;
                        i_dram_read_buffer <= i_dram_read;
                    end
                end
                default: begin
                    write_counter         <= '0;
                    i_dram_addr_buffer    <= '0;
                    i_dram_read_buffer    <= '0;
            
                    d_dram_addr_buffer    <= '0;
                    d_dram_read_buffer    <= '0;
                    d_dram_write_buffer   <= '0;
                    d_dram_wdata_buffer   <= '0;
                end
            endcase
        end
    end
    

endmodule
