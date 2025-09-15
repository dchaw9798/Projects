module random_reservation_station_tb
//import rv32im_types::*;
#(
    parameter RS_DEPTH = 4, 
    parameter ROB_DEPTH = 4
) (
    input logic clk,
    input logic rst,
    //ufp side signal, connecting decode/ROB/Regfile
    output logic [31:0]                  instr_in,
    output logic                         valid_in, //indicates this rs array is activated (connects to issue/pop from instruction queue)
    output logic [$clog2(ROB_DEPTH)-1:0] tag_dest_in, //destination tag (ROB value)
    output logic [5:0]                   alu_ctrl_in, //not yet determined how to encode

    output logic [$clog2(ROB_DEPTH)-1:0] tag_A_in, //ROB tag of source A
    output logic [31:0]                  data_A_in,
    output logic                         ready_A_in, //when data A is available

    output logic [$clog2(ROB_DEPTH)-1:0] tag_B_in, //ROB tag of source B
    output logic [31:0]                  data_B_in,
    output logic                         ready_B_in, //when data A is available

    input logic                         rs_full, //tell instruction queue this rs is full
    
    //CDB side signal
    output logic                         valid_CDB, //indicate this data on the CDB is valid
    output logic [$clog2(ROB_DEPTH)-1:0] tag_CDB, //ROB tag on the CDB
    output logic [31:0]                  data_CDB,
    

    //dfp side signal, connecting CDB/ALU
    output  logic                         resp, //resp from alu to ensure the operation has finished
    input logic [31:0]                  instr_out,
    input logic [$clog2(ROB_DEPTH)-1:0] tag_dest_out,
    input logic [5:0]                   alu_ctrl_out, //not yet determined how to encode
    input logic [31:0]                  data_A_out,
    input logic [31:0]                  data_B_out,
    input logic                         comp_issue //indicates this instruction is popped to ALU for operation

);

    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();
    logic [31:0]                 data;
    logic                        valid_CDB_rand;
    logic [$clog2(ROB_DEPTH)-1:0] tag_CDB_rand;
    logic [31:0]                 data_CDB_rand;
    logic                        resp_rand;

    
    task signal_assign(int i);
        @(posedge clk);
        if (i%4 == 1) begin
            gen.randomize();
            instr_in    <= gen.instr.word;
            tag_dest_in <= ($clog2(ROB_DEPTH))'(i);
            alu_ctrl_in <= 6'b000000;
            tag_A_in    <= ($clog2(ROB_DEPTH))'(i+1);
            data_A_in   <= 'x;
            ready_A_in  <= 1'b0;
            tag_B_in    <= ($clog2(ROB_DEPTH))'(i+2);
            data_B_in   <= 'x;
            ready_B_in  <= 1'b0;
        end
        else if (i%4 == 2) begin
            gen.randomize();
            instr_in    <= gen.instr.word;
            tag_dest_in <= ($clog2(ROB_DEPTH))'(i);
            alu_ctrl_in <= 6'b000000;
            tag_A_in    <= 'x;
            std::randomize(data);
            data_A_in   <= data;
            ready_A_in  <= 1'b1;
            tag_B_in    <= ($clog2(ROB_DEPTH))'(i+2);
            data_B_in   <= 'x;
            ready_B_in  <= 1'b0;
            
        end

        else if (i%4 == 3) begin
            gen.randomize();
            instr_in    <= gen.instr.word;
            tag_dest_in <= ($clog2(ROB_DEPTH))'(i);
            alu_ctrl_in <= 6'b000000;
            tag_A_in    <= ($clog2(ROB_DEPTH))'(i+1);
            data_A_in   <= 'x;
            ready_A_in  <= 1'b0;
            tag_B_in    <= 'x;
            std::randomize(data);
            data_B_in   <= data;
            ready_B_in  <= 1'b1;
            
        end
        else begin
            gen.randomize();
            instr_in    <= gen.instr.word;
            tag_dest_in <= ($clog2(ROB_DEPTH))'(i);
            alu_ctrl_in <= 6'b000000;
            tag_A_in    <= 'x;
            std::randomize(data);
            data_A_in   <= data;
            ready_A_in  <= 1'b1;
            tag_B_in    <= 'x;
            std::randomize(data);
            data_B_in   <= data;
            ready_B_in  <= 1'b1;
        end
    endtask


    task RS_test();
        
        for (int i = 0; i < 32; ++i) begin
            @(posedge clk);
            assign valid_in = ~rs_full;
            
            std::randomize(resp_rand);
            
            assign resp = comp_issue & resp_rand;
            
            signal_assign(i);
            $display("i = %d",i);
            
        end
        
    endtask : RS_test

   

    always @(posedge clk iff !rst) begin
        if (comp_issue) begin
            if ($isunknown(instr_out)) begin
                $error("instr_out contains x");
            end
            if ($isunknown(tag_dest_out)) begin
                $error("tag_dest_out contains x");
            end
            if ($isunknown(alu_ctrl_out)) begin
                $error("aluctrl_out contains x");
            end
            if ($isunknown(data_A_out)) begin
                $error("data_A_out contains x");
            end
            if ($isunknown(data_B_out)) begin
                $error("data_B_out contains x");
            end
        end
    end
    always @(posedge clk) begin
        
        std::randomize(valid_CDB_rand);
        std::randomize(tag_CDB_rand);
        std::randomize(data_CDB_rand);
        

        valid_CDB   <= valid_CDB_rand;
        tag_CDB     <= tag_CDB_rand;
        data_CDB    <= data_CDB_rand;
    end
    
    // A single initial block ensures random stability.
    initial begin
        valid_in = 1'b0;
        // Wait for reset.
        @(posedge clk iff rst == 1'b0);
        repeat(1000) RS_test();
        
        // Finish up
        $display("Random testbench finished!");
        $finish;
    end

endmodule : random_reservation_station_tb