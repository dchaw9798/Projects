//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_dram_w_burst_cp2_tb
//import rv32im_types::*;
(
    mem_itf_banked.mem itf
);

    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();

    logic [31:0] addr;
    logic [63:0] instr;
    logic [31:0] rd;
    int a, b;
    // Do a bunch of LUIs to get useful register state.
    task init_register_state();
        assign itf.ready = 1'b1;
        itf.rvalid <= 1'b0;
        for (int i = 0; i < 4; ++i) begin
            @(posedge itf.clk iff itf.read);
            addr <= itf.addr;
            for (int j = 0 ; j < 4; ++j) begin
                @(posedge itf.clk);
                
                for (int k = 0; k < 2; ++k) begin
                    rd = (k+2*j+8*i);
                    gen.randomize() with {
                        instr.j_type.opcode == op_b_lui;
                        instr.j_type.rd == rd[4:0];
                    };
                    instr[(k*32) +: 32] = gen.instr.word;
                end
                itf.rdata <= instr;
                itf.rvalid <= 1'b1;
                itf.raddr <= addr;
                if (j == 3) begin
                    @(posedge itf.clk);
                    itf.rdata <= 'x;
                    itf.rvalid <= '0;
                    itf.raddr <= 'x;
                end
            end
        end
    endtask : init_register_state

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();
        assign itf.ready = 1'b1;
        itf.rvalid = 1'b0;
        repeat (5000) begin
            @(posedge itf.clk iff (|itf.read || |itf.write));
            itf.rvalid <= 1'b0;
            addr <= itf.addr;
            // Always read out a valid instruction.
            if (|itf.read) begin
                for (int j = 0 ; j < 4; ++j) begin
                    @(posedge itf.clk);
                    //addr <= itf.addr;
                    for (int k = 0; k < 2; ++k) begin
                        gen.randomize();
                        // a = k*32+31;
                        // b = k*32;
                        instr[(k*32) +: 32] = gen.instr.word;
                    end
                    itf.rdata <= instr;
                    itf.rvalid <= 1'b1;
                    itf.raddr <= addr;
                    if (j == 3) begin
                        @(posedge itf.clk);
                        itf.rdata <= 'x;
                        itf.rvalid <= '0;
                        itf.raddr <= 'x;
                    end
                end
            end

            // If it's a write, do nothing and just respond.
            itf.rvalid <= 1'b0;
        end
    endtask : run_random_instrs

    always @(posedge itf.clk iff !itf.rst) begin
        // if ($isunknown(itf.rmask) || $isunknown(itf.wmask)) begin
        //     $error("Memory Error: mask containes 1'bx");
        //     itf.error <= 1'b1;
        // end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            if (itf.addr[0] != 1'b0) begin
                $error("Memory Error: Address is not 16-bit aligned");
                itf.error <= 1'b1;
            end
        end
    end
    
    int covered;
    int total;

    // A single initial block ensures random stability.
    initial begin
        itf.ready = 1'b1;
        itf.rvalid = 1'b0;
        // Wait for reset.
        @(posedge itf.clk iff itf.rst == 1'b0);

        // Get some useful state into the processor by loading in a bunch of state.
        init_register_state();

        // Run!
        run_random_instrs();

        repeat(500) begin
            gen.randomize();
        end

        gen.instr_cg.all_opcodes.get_coverage(covered, total);
        $display("all_opcodes: %0d/%0d", covered, total);

        gen.instr_cg.all_funct7.get_coverage(covered, total);
        $display("all_funct7: %0d/%0d", covered, total);

        gen.instr_cg.all_funct3.get_coverage(covered, total);
        $display("all_funct3: %0d/%0d", covered, total);

        gen.instr_cg.all_regs_rs1.get_coverage(covered, total);
        $display("all_regs_rs1: %0d/%0d", covered, total);

        gen.instr_cg.all_regs_rs2.get_coverage(covered, total);
        $display("all_regs_rs2: %0d/%0d", covered, total);

        gen.instr_cg.funct3_cross.get_coverage(covered, total);
        $display("funct3_cross: %0d/%0d", covered, total);

        gen.instr_cg.funct7_cross.get_coverage(covered, total);
        $display("funct7_cross: %0d/%0d", covered, total);

        // Finish up
        $display("Random testbench finished!");
        $finish;
    end

endmodule : random_dram_w_burst_cp2_tb
