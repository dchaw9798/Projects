module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = 1000;
    longint timeout;// = 64'd1000000;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
        $value$plusargs("TIMEOUT_ECE411=%d", timeout);
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    mem_itf_banked mem_itf(.*);

    // Pick one of the two options (only one of these should be uncommented at a time):
    dram_w_burst_frfcfs_controller mem(.itf(mem_itf)); // Use this for compiling test program into the memory
    //random_dram_w_burst_cp2_tb random_dram_w_burst_cp2_tb(.itf(mem_itf)); // Use this for generating randomized memory data

    //rvfi monitor (comment these two lines to test individual module)
    // --------------------------------------------------------
    mon_itf #(.CHANNELS(8)) mon_itf(.*);
    monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));
    // --------------------------------------------------------


    // To test individual module: create seperate tb for each module and instantiate here
    //--------------------------------------------------------
    //cacheline_adapter_tb cacheline_adapter_tb(.itf(mem_itf)); // For testing cacheline_adapter
    //pipelined_cache_tb pipelined_cache_tb(.itf(mem_itf));
    //--------------------------------------------------------
   

    
    //comment out the following cpu instatiation cpu code for individual module test
    //uncomment if you want to test cpu
    //------------------------------------------------
    cpu dut(
        .clk            (clk),
        .rst            (rst),

        .bmem_addr  (mem_itf.addr  ),
        .bmem_read  (mem_itf.read  ),
        .bmem_write (mem_itf.write ),
        .bmem_wdata (mem_itf.wdata ),
        .bmem_ready (mem_itf.ready ),
        .bmem_raddr (mem_itf.raddr ),
        .bmem_rdata (mem_itf.rdata ),
        .bmem_rvalid(mem_itf.rvalid)
    );
    //------------------------------------------------


    //use following instatiate cpu code for individual module test
    //------------------------------------------------
    // logic local_read;
    // logic local_write;
    // logic [31:0] local_addr;
    // logic [63:0] local_wdata;

    // cpu dut(
    //     .clk            (clk),
    //     .rst            (rst),

    //     .bmem_addr  (local_addr ),
    //     .bmem_read  (local_read  ),
    //     .bmem_write (local_write ),
    //     .bmem_wdata (local_wdata ),
    //     .bmem_ready (mem_itf.ready ),
    //     .bmem_raddr (mem_itf.raddr ),
    //     .bmem_rdata (mem_itf.rdata ),
    //     .bmem_rvalid(mem_itf.rvalid)
    // );
    //------------------------------------------------

    //comment out `include "rvfi_reference.svh" for individual module test
    `include "rvfi_reference.svh"
    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();
    int covered;
    int total;

    initial begin
        $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;

        
        // uncomment code below for individual module test
        // comment out if you want to test cpu and use rvfi monitor
        // ------------------------------------------------------
        //  #200000;
        //  $finish;

    end

    // comment out code below for individual module test
    // uncomment if you want to test cpu and use rvfi monitor
    //------------------------------------------------  
    always @(posedge clk) begin
        for (int unsigned i = 0; i < 8; ++i) begin
            if (mon_itf.halt[i]) begin
                $finish;
            end
        end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $fatal;
        end
        if (mon_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $fatal;
        end
        if (mem_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $fatal;
        end
        timeout <= timeout - 1;
    end
    //------------------------------------------------  

endmodule

