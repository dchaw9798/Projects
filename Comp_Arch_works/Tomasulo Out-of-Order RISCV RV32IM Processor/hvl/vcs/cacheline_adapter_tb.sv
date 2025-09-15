module cacheline_adapter_tb
(
  mem_itf_banked.mem itf
);

    //---------------------------------------------------------------------------------
    // Waveform generation.
    //---------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------
    // TODO: Declare cache port signals:
    //---------------------------------------------------------------------------------

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 256;
    parameter CACHE_LINES = 16;

    // int timeout = 10000000;

     // Cacheline_adapter inputs
    logic [ADDR_WIDTH-1:0] ufp_addr;
    logic                  ufp_read;
    logic                  ufp_write;
    logic [DATA_WIDTH-1:0] ufp_wdata;

    // Cacheline_adapter outputs
    logic [DATA_WIDTH-1:0] ufp_rdata;
    logic                  ufp_resp;


    //logic [31:0] read_data;


    
    //---------------------------------------------------------------------------------
    // TODO: Generate a clock:
    //---------------------------------------------------------------------------------
 
    int clock_half_period_ps = 1000;
    longint timeout = 64'd1000000;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
        $value$plusargs("TIMEOUT_ECE411=%d", timeout);
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;
    //---------------------------------------------------------------------------------
    // TODO: Write a task to generate rst:
    //---------------------------------------------------------------------------------
    // initial begin
    //     rst = 1'b1;
    //     repeat (2) @(posedge clk);
    //     rst <= 1'b0;
    // end

    //---------------------------------------------------------------------------------
    // TODO: Instantiate the DUT and physical memory:
    //---------------------------------------------ufp_resp------------------------------------

    // mem_itf_banked mem_itf(.*);
    // banked_memory banked_memory(.itf(mem_itf)); // For directed testing with PROG

    // Instantiate the cache module
 
    cacheline_adapter dut (
        .clk(itf.clk),
        .rst(itf.rst),
    // memory side signals, ufp -> upward facing port
    
        .ufp_addr(ufp_addr),
        .ufp_read(ufp_read),
        .ufp_write(ufp_write),
        .ufp_wdata(ufp_wdata),
        .ufp_rdata(ufp_rdata),
        .ufp_resp(ufp_resp),

    // memory side signals, dfp -> downward facing port
        .dfp_addr(mem_itf.addr),
        .dfp_read(mem_itf.read),
        .dfp_write(mem_itf.write),
        .dfp_wdata(mem_itf.wdata),
        .dfp_ready(mem_itf.ready),
        .dfp_raddr(mem_itf.raddr),
        .dfp_rdata(mem_itf.rdata),
        .dfp_rvalid(mem_itf.rvalid)
    );

    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------
    task single_read(logic [31:0] addr);
        @(posedge clk);
        ufp_addr <= addr;
        ufp_read <= 1'b1;
        ufp_write <= 1'b0;
        ufp_wdata <= 'x;
        @(posedge itf.clk iff ufp_resp);
        ufp_addr <= 'x;
        ufp_read <= 1'b0;
        ufp_write <= 1'b0;
        ufp_wdata <= 'x;

    endtask

    task single_write(logic [31:0] addr, logic [255:0] wdata);
        @(posedge clk);
        ufp_addr <= addr;
        ufp_read <= 1'b0;
        ufp_write <= 1'b1;
        ufp_wdata <= wdata;
        @(posedge clk iff ufp_resp);
        ufp_addr <= 'x;
        ufp_read <= 1'b0;
        ufp_write <= 1'b0;
        ufp_wdata <= 'x;

    endtask
    


   
    //---------------------------------------------------------------------------------
    // TODO: Main initial block that calls your tasks, then calls $finish
    //---------------------------------------------------------------------------------
    

    // Test procedure
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;

        
        ufp_addr = 'x;
        ufp_read = 1'b0;
        ufp_write = 1'b0;
        ufp_wdata = 'x;
        

        #40000;

        single_read(32'h1eceb000);
        single_write(32'h1eceb000, 256'h1eceb0001eceb0011eceb0021eceb0031eceb0041eceb0051eceb0061eceb007);

        $display("cacheline_adapter testbench finished!");
    end


endmodule : cacheline_adapter_tb
