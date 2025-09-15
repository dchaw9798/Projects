import "DPI-C" function string getenv(input string env_name);
module top_tb_test;
import rv32im_types::*;

    // timeunit 1ps;
    // timeprecision 1ps;

    // int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

    // bit clk;
    // always #(clock_half_period_ps) clk = ~clk;

    // bit rst;

    //int timeout = 100; // in cycles, change according to your needs

    // mem_itf_banked bmem_itf(.*);
    // banked_memory banked_memory(.itf(bmem_itf));

    // mon_itf #(.CHANNELS(8)) mon_itf(.*);
    // monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    // cpu dut(
    //     .clk            (clk),
    //     .rst            (rst),

    //     .bmem_addr  (bmem_itf.addr  ),
    //     .bmem_read  (bmem_itf.read  ),
    //     .bmem_write (bmem_itf.write ),
    //     .bmem_wdata (bmem_itf.wdata ),
    //     .bmem_ready (bmem_itf.ready ),
    //     .bmem_raddr (bmem_itf.raddr ),
    //     .bmem_rdata (bmem_itf.rdata ),
    //     .bmem_rvalid(bmem_itf.rvalid)
    // );

    //`include "rvfi_reference.svh"

    mem_itf_banked mem_itf(.*);
    //banked_memory banked_memory(.itf(mem_itf)); // For directed testing with PROG

    // Pick one of the two options (only one of these should be uncommented at a time):
    //n_port_pipeline_memory_32_w_mask #(.CHANNELS(2), .MAGIC(0)) mem(.itf(mem_itf)); // For directed testing with PROG
    //random_tb #(.CHANNELS(2)) random_tb(.itf(mem_itf)); // For randomized testing
    //random_reservation_station_tb #(.RS_DEPTH(4), .ROB_DEPTH(32)) random_reservation_station_tb(.*); // For randomized testing

    // mon_itf #(.CHANNELS(8)) mon_itf(.*);
    // monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

    //cacheline_adapter_tb cacheline_adapter_tb(.itf(mem_itf));

    // always @(posedge clk) begin
    //     for (int unsigned i=0; i < 8; ++i) begin
    //         if (mon_itf.halt[i]) begin
    //             $finish;
    //         end
    //     end
    //     if (timeout == 0) begin
    //         $error("TB Error: Timed out");
    //         $finish;
    //     end
    //     if (mon_itf.error != 0) begin
    //         repeat (5) @(posedge clk);
    //         $finish;
    //     end
    //     if (bmem_itf.error != 0) begin
    //         repeat (5) @(posedge clk);
    //         $finish;
    //     end
    //     timeout <= timeout - 1;
    // end

    int timeout = 10000000;  
    //---------------------------------------------------------------------------------
    //CACHELINE ADAPTER I/O signal
    // parameter ADDR_WIDTH = 32;
    // parameter DATA_WIDTH = 256;
    // parameter CACHE_LINES = 16;



    // // Cacheline_adapter inputs
    // logic [ADDR_WIDTH-1:0] ufp_addr;
    // logic                  ufp_read;
    // logic                  ufp_write;
    // logic [DATA_WIDTH-1:0] ufp_wdata;

    // // Cacheline_adapter outputs
    // logic [DATA_WIDTH-1:0] ufp_rdata;
    // logic [ADDR_WIDTH-1:0] ufp_raddr;
    // logic                  ufp_resp;
    // logic                  ufp_ready;
    //---------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------
    //instruction_queue I/O signal
    // logic [31:0] read_data;
    // logic instr_pop;
    // logic instr_push;
    // logic [31:0] issue_out;
    // logic [31:0] instr_in;
    // logic is_empty;
    // logic is_full;
    //---------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------
/*
    //RS I/O signal
    logic [31:0] instr_in;
    logic        valid_in; //indicates this rs array is activated (connects to issue/pop from instruction queue)
    logic [4:0]  tag_dest_in; //destination tag (ROB value)
    logic [5:0]  alu_ctrl_in; //not yet determined how to encode

    logic [4:0]  tag_A_in; //ROB tag of source A
    logic [31:0] data_A_in;
    logic        ready_A_in; //when data A is available

    logic [4:0]  tag_B_in; //ROB tag of source B
    logic [31:0] data_B_in;
    logic        ready_B_in; //when data A is available

    logic        rs_full; //tell instruction queue this rs is full
    
    //CDB side signal
    logic        valid_CDB; //indicate this data on the CDB is valid
    logic [4:0]  tag_CDB; //ROB tag on the CDB
    logic [31:0] data_CDB;
    

    //dfp side signal, connecting CDB/ALUe
    logic        resp; //resp from alu to ensure the operation has finished
    logic [31:0] instr_out;
    logic [4:0]  tag_dest_out;
    logic [5:0]  alu_ctrl_out; //not yet determined how to encode
    logic [31:0] data_A_out;
    logic [31:0] data_B_out;
    logic        comp_issue; //indicates this instruction is popped to ALU for operation
*/

    //---------------------------------------------------------------------------------
    // TODO: Generate a clock:
    //---------------------------------------------------------------------------------
    bit clk;
    bit rst;

    // Clock generation
    always #1ns clk = ~clk;

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
    //---------------------------------------------------------------------------------



    // Instantiate the cache module
 
    // cacheline_adapter dut (
    //     .clk(clk),
    //     .rst(rst),
    // // memory side signals, ufp -> upward facing port
    
    //     .ufp_addr(ufp_addr),
    //     .ufp_read(ufp_read),
    //     .ufp_write(ufp_write),
    //     .ufp_wdata(ufp_wdata),
    //     .ufp_rdata(ufp_rdata),
    //     .ufp_raddr(ufp_raddr),
    //     .ufp_resp(ufp_resp),
    //     .ufp_ready(ufp_ready),

    // // memory side signals, dfp -> downward facing port
    //     .dfp_addr(mem_itf.addr),
    //     .dfp_read(mem_itf.read),
    //     .dfp_write(mem_itf.write),
    //     .dfp_wdata(mem_itf.wdata),
    //     .dfp_ready(mem_itf.ready),
    //     .dfp_raddr(mem_itf.raddr),
    //     .dfp_rdata(mem_itf.rdata),
    //     .dfp_rvalid(mem_itf.rvalid)
    // );

    //instantiate FIFO queue
    // instruction_queue dut (
    //     .clk(clk),
    //     .rst(rst),
    //     .instr_push(instr_push),
    //     .instr_pop(instr_pop),
    //     .instr_in(instr_in),
    //     .issue_out(issue_out),
    //     .is_empty(is_empty),
    //     .is_full(is_full)
    // );

/*
    //instantiate RS
    reservation_station #(
        .RS_DEPTH(4),
        .ROB_DEPTH(32)
    ) dut  (
    .clk(clk),
    .rst(rst),
    //ufp side signal, connecting decode/ROB/Regfile
    .instr_in(instr_in),
    .valid_in(valid_in), //indicates this rs array is activated (connects to issue/pop from instruction queue)
    .tag_dest_in(tag_dest_in), //destination tag (ROB value)
    .alu_ctrl_in(alu_ctrl_in), //not yet determined how to encode

    .tag_A_in(tag_A_in), //ROB tag of source A
    .data_A_in(data_A_in),
    .ready_A_in(ready_A_in), //when data A is available

    .tag_B_in(tag_B_in), //ROB tag of source B
    .data_B_in(data_B_in),
    .ready_B_in(ready_B_in), //when data A is available

    .rs_full(rs_full), //tell instruction queue this rs is full
    
    //CDB side signal
    .valid_CDB(valid_CDB), //indicate this data on the CDB is valid
    .tag_CDB(tag_CDB), //ROB tag on the CDB
    .data_CDB(data_CDB),
    

    //dfp side signal, connecting CDB/ALU
    .resp(resp), //resp from alu to ensure the operation has finished
    .instr_out(instr_out),
    .tag_dest_out(tag_dest_out),
    .alu_ctrl_out(alu_ctrl_out), //not yet determined how to encode
    .data_A_out(data_A_out),
    .data_B_out(data_B_out),
    .comp_issue(comp_issue) //indicates this instruction is popped to ALU for operation

    );
*/

//for mult_div test
logic [31:0]mult_div_instr_in;
    logic [31:0]rs1_v;
    logic [31:0]rs2_v;
    logic [2:0]rob_tag;
    logic mult_div_en;
    logic mult_div_resp;
    logic [31:0]mult_div_result;
    logic [2:0]cdb_rob;
    logic valid;

    mult_div dut (
        .clk(clk),
        .rst(rst),
        .mult_div_instr_in(mult_div_instr_in),
        .rs1_v(rs1_v),
        .rs2_v(rs2_v),
        .rob_tag(rob_tag),
        .mult_div_en(mult_div_en),
        .mult_div_resp(mult_div_resp),
        .mult_div_result(mult_div_result),
        .cdb_rob(cdb_rob),
        .valid (valid)   
    );

    task sign_mult();
        @(posedge clk);
        mult_div_instr_in <= 32'h0220e1b3;
        rs1_v <= 32'h00000004;
        rs2_v <= 32'hFFFFFFFd;
        rob_tag <= 3'b001;
        mult_div_en <= 1'b1;    
	@(posedge clk iff mult_div_resp)
        mult_div_instr_in <= 32'h022081b3;
        rs1_v <= 32'h00000005;
        rs2_v <= 32'h00000002;
        rob_tag <= 3'b011;
        mult_div_en <= 1'b1;  	   
    endtask
    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------
    
    // task single_read(logic [31:0] addr);
        
    //     ufp_addr <= addr;
    //     ufp_read <= 1'b1;
    //     ufp_write <= 1'b0;
    //     ufp_wdata <= 'x;
    //     @(posedge clk iff ufp_resp);
    //     ufp_addr <= 'x;
    //     ufp_read <= 1'b0;
    //     ufp_write <= 1'b0;
    //     ufp_wdata <= 'x;

    // endtask
    
    // task instruction_queue_test();
    //     instr_push = '0;
    //     instr_pop = '0;
    //     instr_in = '0;
    //     #10000

        
    //     @(posedge clk);
    //     instr_push <= 1'b1;
    //     instr_pop <= 1'b0;
    //     instr_in <= 32'h1eceb000;
    //     @(posedge clk);
    //     instr_push <= 1'b1;
    //     instr_pop <= 1'b0;
    //     instr_in <= 32'h1eceb001;
    //     @(posedge clk);
    //     instr_push <= 1'b1;
    //     instr_pop <= 1'b0;
    //     instr_in <= 32'h1eceb010;
    //     @(posedge clk);
    //     instr_push <= 1'b0;
    //     instr_pop <= 1'b1;
    //     instr_in <= 32'h1eceb011;
    //     @(posedge clk);
    //     instr_push <= 1'b1;
    //     instr_pop <= 1'b1;
    //     instr_in <= 32'h1eceb100;
    //     @(posedge clk);
    //     instr_push <= 1'b1;
    //     instr_pop <= 1'b1;
    //     instr_in <= 32'h1eceb101;
    //     @(posedge clk);
    //     instr_push <= 1'b0;
    //     instr_pop <= 1'b1;
    //     instr_in <= 32'h1eceb011;
    //     @(posedge clk);
    //     instr_push <= 1'b0;
    //     instr_pop <= 1'b1;
    //     instr_in <= 32'h1eceb011;
    // endtask
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
 
        
        // ufp_addr = 'x;
        // ufp_read = 1'b0;
        // ufp_write = 1'b0;
        // ufp_wdata = 'x;
        mult_div_instr_in = '0;
        rs1_v = '0;
        rs2_v = '0;
        rob_tag = '0;
        mult_div_en = '0;
	#10000;
	sign_mult();


        #30000;

        //single_read(32'h1eceb000);

        $display("testbench finished!");
        $finish;
    end
    always @(posedge clk) begin
        // for (int unsigned i=0; i < 8; ++i) begin
        //     if (mon_itf.halt[i]) begin
        //         $finish;
        //     end
        // end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        // if (mon_itf.error != 0) begin
        //     repeat (5) @(posedge clk);
        //     $finish;
        // end
        // if (mem_itf.error != 0) begin
        //     repeat (5) @(posedge clk);
        //     $finish;
        // end
        timeout <= timeout - 1;
    end
endmodule
