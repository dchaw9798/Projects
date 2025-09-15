module data_instr_arb_old (
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
    logic [31:0]          i_dram_addr_buf;
    logic                 i_dram_read_buf;
    logic                 i_dram_write_buf;
    logic [63:0]          i_dram_wdata_buf;
    logic [31:0]          d_dram_addr_buf;
    logic                 d_dram_read_buf;
    logic                 d_dram_write_buf;
    logic [63:0]          d_dram_wdata_buf;
    logic                 bmem_ready_buf;
    logic [31:0]          bmem_raddr_buf;
    logic [63:0]          bmem_rdata_buf;
    logic                 bmem_rvalid_buf;
    typedef enum logic [2:0] {
        INSTR_STAGE  = 3'b000,
        DREAD_STAGE  = 3'b001,
        DWRITE_STAGE0 = 3'b010,
        DWRITE_STAGE1 = 3'b011,
        DWRITE_STAGE2 = 3'b100,
        DWRITE_STAGE3 = 3'b101
    } fsm_state_t;
    fsm_state_t state;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= INSTR_STAGE;
            i_dram_addr_buf <= '0;
            i_dram_read_buf <= '0;
            i_dram_write_buf <= '0;
            i_dram_wdata_buf <= '0;
            d_dram_addr_buf <= '0;
            d_dram_read_buf <= '0;
            d_dram_write_buf <= '0;
            d_dram_wdata_buf <= '0;
            bmem_ready_buf <= '0;
            bmem_raddr_buf <= '0;
            bmem_rdata_buf <= '0;
            bmem_rvalid_buf <= '0;
        end
        else begin
            if(state == INSTR_STAGE) begin
                state <= INSTR_STAGE;
                i_dram_addr_buf <= i_dram_addr;
                i_dram_read_buf <= i_dram_read;
                i_dram_write_buf <= i_dram_write;
                i_dram_wdata_buf <= i_dram_wdata;
                d_dram_addr_buf <= '0;
                d_dram_read_buf <= '0;
                d_dram_write_buf <= '0;
                d_dram_wdata_buf <= '0;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
                if(d_dram_read) begin
                    state <= DREAD_STAGE;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
                else if (d_dram_write) begin
                    state <= DWRITE_STAGE0;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
            end
            if (state == DREAD_STAGE) begin
                state <= INSTR_STAGE;
                i_dram_addr_buf <= i_dram_addr;
                i_dram_read_buf <= i_dram_read;
                i_dram_write_buf <= i_dram_write;
                i_dram_wdata_buf <= i_dram_wdata;
                d_dram_addr_buf <= '0;
                d_dram_read_buf <= '0;
                d_dram_write_buf <= '0;
                d_dram_wdata_buf <= '0;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
                if(d_dram_read) begin
                    state <= DREAD_STAGE;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
                else if (d_dram_write) begin
                    state <= DWRITE_STAGE0;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
            end                
            if (state == DWRITE_STAGE0) begin
                state <= DWRITE_STAGE1;
                i_dram_addr_buf <= '0;
                i_dram_read_buf <= '0;
                i_dram_write_buf <= '0;
                i_dram_wdata_buf <= '0;
                d_dram_addr_buf <= d_dram_addr;
                d_dram_read_buf <= d_dram_read;
                d_dram_write_buf <= d_dram_write;
                d_dram_wdata_buf <= d_dram_wdata;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
            end
            if (state == DWRITE_STAGE1) begin
                state <= DWRITE_STAGE2;
                i_dram_addr_buf <= '0;
                i_dram_read_buf <= '0;
                i_dram_write_buf <= '0;
                i_dram_wdata_buf <= '0;
                d_dram_addr_buf <= d_dram_addr;
                d_dram_read_buf <= d_dram_read;
                d_dram_write_buf <= d_dram_write;
                d_dram_wdata_buf <= d_dram_wdata;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
            end
            if (state == DWRITE_STAGE2) begin
                state <= DWRITE_STAGE3;
                i_dram_addr_buf <= '0;
                i_dram_read_buf <= '0;
                i_dram_write_buf <= '0;
                i_dram_wdata_buf <= '0;
                d_dram_addr_buf <= d_dram_addr;
                d_dram_read_buf <= d_dram_read;
                d_dram_write_buf <= d_dram_write;
                d_dram_wdata_buf <= d_dram_wdata;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
            end
            if (state == DWRITE_STAGE3) begin
                state <= INSTR_STAGE;
                i_dram_addr_buf <= i_dram_addr;
                i_dram_read_buf <= i_dram_read;
                i_dram_write_buf <= i_dram_write;
                i_dram_wdata_buf <= i_dram_wdata;
                d_dram_addr_buf <= '0;
                d_dram_read_buf <= '0;
                d_dram_write_buf <= '0;
                d_dram_wdata_buf <= '0;
                bmem_ready_buf <= bmem_ready;
                bmem_raddr_buf <= bmem_raddr;
                bmem_rdata_buf <= bmem_rdata;
                bmem_rvalid_buf <= bmem_rvalid;
                if(d_dram_read) begin
                    state <= DREAD_STAGE;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
                else if (d_dram_write) begin
                    state <= DWRITE_STAGE0;
                    i_dram_addr_buf <= '0;
                    i_dram_read_buf <= '0;
                    i_dram_write_buf <= '0;
                    i_dram_wdata_buf <= '0;
                    d_dram_addr_buf <= d_dram_addr;
                    d_dram_read_buf <= d_dram_read;
                    d_dram_write_buf <= d_dram_write;
                    d_dram_wdata_buf <= d_dram_wdata;
                    bmem_ready_buf <= bmem_ready;
                    bmem_raddr_buf <= bmem_raddr;
                    bmem_rdata_buf <= bmem_rdata;
                    bmem_rvalid_buf <= bmem_rvalid;
                end
            end
        end
    end

    always_comb begin
        bmem_addr = '0;
        bmem_read = '0;
        bmem_write = '0;
        bmem_wdata = '0;
        i_dram_ready = '0;
        i_dram_raddr = '0;
        i_dram_rdata = '0;
        i_dram_rvalid = '0;
        d_dram_ready = '0;
        d_dram_raddr = '0;
        d_dram_rdata = '0;
        d_dram_rvalid = '0;
        if(state == INSTR_STAGE) begin
            bmem_addr = i_dram_addr_buf;
            bmem_read = i_dram_read_buf;
            bmem_write = i_dram_write_buf;
            bmem_wdata = i_dram_wdata_buf;
            i_dram_ready = bmem_ready_buf;
            i_dram_raddr = bmem_raddr_buf;
            i_dram_rdata = bmem_rdata_buf;
            i_dram_rvalid = bmem_rvalid_buf;
            d_dram_ready = '0;
            d_dram_raddr = '0;
            d_dram_rdata = '0;
            d_dram_rvalid = '0;
        end
        else begin
            bmem_addr = d_dram_addr_buf;
            bmem_read = d_dram_read_buf;
            bmem_write = d_dram_write_buf;
            bmem_wdata = d_dram_wdata_buf;
            d_dram_ready = bmem_ready_buf;
            d_dram_raddr = bmem_raddr_buf;
            d_dram_rdata = bmem_rdata_buf;
            d_dram_rvalid = bmem_rvalid_buf;
            i_dram_ready = '0;
            i_dram_raddr = '0;
            i_dram_rdata = '0;
            i_dram_rvalid = '0;
        end
    end

endmodule