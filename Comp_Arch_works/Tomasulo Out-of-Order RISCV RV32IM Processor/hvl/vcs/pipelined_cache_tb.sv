module pipelined_cache_tb
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

    // cache inputs
    logic [ADDR_WIDTH-1:0] ufp_addr;
    logic [3:0]            ufp_rmask;
    logic [3:0]            ufp_wmask;
    logic [31:0]           ufp_wdata;

    // cache outouts
    logic [31:0]           ufp_rdata;
    logic                  ufp_resp;
    

     // Cacheline_adapter inputs
    logic [ADDR_WIDTH-1:0] adapter_addr;
    logic                  adapter_read;
    logic                  adapter_write;
    logic [DATA_WIDTH-1:0] adapter_wdata;

    // Cacheline_adapter outputs
    logic [DATA_WIDTH-1:0] adapter_rdata;
    logic                  adapter_resp;


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
    pipelined_cache dut0 (
        .clk(itf.clk),
        .rst(itf.rst),
        .ufp_addr(ufp_addr),
        .ufp_rmask(ufp_rmask),
        .ufp_wmask(ufp_wmask),
        .ufp_rdata(ufp_rdata),
        .ufp_wdata(ufp_wdata),
        .ufp_resp(ufp_resp),

        .dfp_addr(adapter_addr),
        .dfp_read(adapter_read),
        .dfp_write(adapter_write),
        .dfp_rdata(adapter_rdata),
        .dfp_wdata(adapter_wdata),
        .dfp_resp(adapter_resp)
    );
    
    cacheline_adapter dut1 (
        .clk(itf.clk),
        .rst(itf.rst),
    // memory side signals, ufp -> upward facing port
    
        .ufp_addr(adapter_addr),
        .ufp_read(adapter_read),
        .ufp_write(adapter_write),
        .ufp_wdata(adapter_wdata),
        .ufp_rdata(adapter_rdata),
        .ufp_resp(adapter_resp),

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
    // task single_read(logic [31:0] addr);
    //     @(posedge clk);
    //     ufp_addr <= addr;
    //     ufp_read <= 1'b1;
    //     ufp_write <= 1'b0;
    //     ufp_wdata <= 'x;
    //     @(posedge itf.clk iff ufp_resp);
    //     ufp_addr <= 'x;
    //     ufp_read <= 1'b0;
    //     ufp_write <= 1'b0;
    //     ufp_wdata <= 'x;

    // endtask

    // task single_write(logic [31:0] addr, logic [255:0] wdata);
    //     @(posedge clk);
    //     ufp_addr <= addr;
    //     ufp_read <= 1'b0;
    //     ufp_write <= 1'b1;
    //     ufp_wdata <= wdata;
    //     @(posedge clk iff ufp_resp);
    //     ufp_addr <= 'x;
    //     ufp_read <= 1'b0;
    //     ufp_write <= 1'b0;
    //     ufp_wdata <= 'x;

    // endtask
    logic [31:0] offset;
    task consecutive_read_hit(logic [31:0] addr);
        for (int i = 0; i <= 20; ++i) begin
            @(posedge clk);
            
                assign ufp_addr = 'x;  // Procedural assignment
                assign ufp_rmask = 'x;       // Procedural assignment
                assign ufp_wmask = 'x;            // Procedural assignment
                assign ufp_wdata = 'x;    
            if (i == '0) begin
                offset = i * 4; 
                $display("i = %d", i);
                @(posedge clk);
                assign ufp_addr = addr + offset;  // Procedural assignment
                assign ufp_rmask = 4'b1111;       // Procedural assignment
                assign ufp_wmask = '0;            // Procedural assignment
                assign ufp_wdata = '0;            // Procedural assignment
                @(posedge clk);
                assign ufp_addr = 'x;  // Procedural assignment
                assign ufp_rmask = 'x;       // Procedural assignment
                assign ufp_wmask = 'x;            // Procedural assignment
                assign ufp_wdata = 'x;            // Procedural assignment

                //wait (ufp_resp == 1'b1);   // Wait until ufp_resp is true
            end        
            else begin
                #10;
                //@(posedge clk);
                $display("Simulation time: %0t", $time);

                assign ufp_addr = 'x;  // Procedural assignment
                assign ufp_rmask = 'x;       // Procedural assignment
                assign ufp_wmask = 'x;            // Procedural assignment
                assign ufp_wdata = 'x;    
                $display("i = %d", i);
                $display("ufp_resp = %d", ufp_resp);
                $display("ufp_addr = x");
                
                
                wait (ufp_resp == 1'b1);

                offset = i * 4; 
                $display("i = %d", i);
                $display("ufp_resp = %d", ufp_resp);
                $display("Simulation time: %0t", $time);
                

                assign ufp_addr = addr + offset;  // Procedural assignment
                $display("ufp_addr = %h", ufp_addr);
                assign ufp_rmask = 4'b1111;       // Procedural assignment
                assign ufp_wmask = '0;            // Procedural assignment
                assign ufp_wdata = '0;            // Procedural assignment
             
            end
        end

        // for (int i = 0; i <= 4; ++i) begin
            
        //     if (i == 'd0) begin
        //         @(posedge clk);
        //         ufp_addr <= addr + i*4;
        //         ufp_rmask <= 4'b1111;
        //         ufp_wmask <= '0;
        //         ufp_wdata <= 'x;
                
        //         @(posedge clk);
        //         ufp_addr <= 'x;
        //         ufp_rmask <= 'x;
        //         ufp_wmask <= 'x;
        //         ufp_wdata <= 'x;
        //         addr_buffer <= addr + (i+1)*200;
        //     end
        //     else if (i == 'd1) begin
        //         @(posedge clk);
        //         @(ufp_resp);
        //         if (ufp_resp) begin
        //             assign ufp_addr = addr_buffer;
        //             assign ufp_rmask = 4'b1111;
        //             assign ufp_wmask = '0;
        //             assign ufp_wdata = 'x;
        //             @(posedge clk);
        //             addr_buffer <= addr + (i+1)*200;
        //         end
        //     end
        //     else if (i == 'd2) begin
        //         assign ufp_addr = 'x;
        //         assign ufp_rmask = 'x;
        //         assign ufp_wmask = 'x;
        //         assign ufp_wdata = 'x;
        //         @(posedge clk);
                
        //         @(ufp_resp);
        //         if (ufp_resp) begin
        //             assign ufp_addr = addr_buffer;
        //             assign ufp_rmask = 4'b1111;
        //             assign ufp_wmask = '0;
        //             assign ufp_wdata = 'x;
        //             addr_buffer <= addr + (i)*20+4;
        //         end
        //     end
        //     else begin
        //         @(posedge clk);
        //         if (ufp_resp) begin
        //             assign ufp_addr = addr_buffer;
        //             assign ufp_rmask = 4'b1111;
        //             assign ufp_wmask = '0;
        //             assign ufp_wdata = 'x;
        //             addr_buffer <= addr + (i+1)*20;
        //         end
        //     end
        // end

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
        ufp_rmask = '0;
        ufp_wmask = '0;
        ufp_wdata = 'x;
        

        #40000;

        consecutive_read_hit(32'h1eceb000);
        //single_write(32'h1eceb000, 256'h1eceb0001eceb0011eceb0021eceb0031eceb0041eceb0051eceb0061eceb007);

        $display("pipelined cache testbench finished!");
        $finish;
    end


endmodule : pipelined_cache_tb
