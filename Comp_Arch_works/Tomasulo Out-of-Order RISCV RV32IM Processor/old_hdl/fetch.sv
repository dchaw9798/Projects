module fetch (
    // cpu port
    input  logic        clk,
    input  logic        rst,
    input  logic        branch,
    input  logic [31:0] pc_branch,
    input  logic        iq_full, //instruction queue full signal
    output logic [31:0] pc_out,
    output logic [31:0] pc_next_out,
    output logic [31:0] instr,
    output logic        enqueue, //pop instr and pc into instruction queue
    
    // dram port
    output logic [31:0] i_dram_addr,
    output logic        i_dram_read,
    output logic        i_dram_write,
    output logic [63:0] i_dram_wdata,

    input  logic        i_dram_ready,
    input  logic [31:0] i_dram_raddr,
    input  logic [63:0] i_dram_rdata,
    input  logic        i_dram_rvalid

);
    logic [31:0]  pc;
    logic [31:0]  pc_next;
    logic         i_cache_resp;
    logic [31:0]  i_adapter_addr;
    logic         i_adapter_read;
    logic         i_adapter_write;
    logic [255:0] i_adapter_rdata;
    logic [255:0] i_adapter_wdata;
    logic         i_adapter_resp;
    logic [31:0]  pc_fetch; //pc send into icache
    logic         fetch;
    logic         branch_buffer;
    logic [31:0]  branch_addr_buffer;


    always_comb begin
        if (iq_full) begin
            enqueue = 1'b0;
        end
        else begin
            if (!branch_buffer) begin
                if (i_cache_resp) begin
                    enqueue = 1'b1;
                end
                else begin
                    enqueue = 1'b0;
                end
            end
            else begin
                enqueue = 1'b0;
            end
        end
    end

     // fetch FSM
    enum logic [1:0] {
        START,
        OPERATE,
        IDLE
    } fetch_state, fetch_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            fetch_state <= START;
        end
        else begin
            fetch_state <= fetch_state_next;
        end
    end

    always_comb begin
        fetch_state_next = IDLE;
        case(fetch_state)
            START: begin
                fetch_state_next = OPERATE;
            end
            OPERATE: begin
                if (i_cache_resp) begin
                    fetch_state_next = IDLE;
                end
                else begin
                    fetch_state_next = OPERATE;
                end
            end
            IDLE: begin
                fetch_state_next = OPERATE;
            end
            default: begin
                fetch_state_next = IDLE;
            end
        endcase    
    end

    always_comb begin
        if (rst) begin
            pc_next = 32'h1eceb000;
        end
        else begin
            case (fetch_state)
                IDLE: begin
                    if (branch) begin
                        pc_next = pc_branch;
                    end
                    else begin
                        pc_next = pc + 'd4;
                    end
                end
                OPERATE: begin
                    if (!branch_buffer && i_cache_resp) begin
                        if (branch) begin
                            pc_next = pc_branch;
                        end
                        else begin
                            pc_next = pc + 'd4;
                        end
                    end
                    else begin
                        if (branch_buffer) begin
                            pc_next = branch_addr_buffer;
                        end
                        else begin
                            pc_next = pc + 'd4;
                        end
                    end
                end
                default: begin
                    pc_next = pc + 'd4;
                end

            endcase
            // if (branch) begin
            //     pc_next = pc_branch;
            // end
            // else begin
            //     pc_next = pc + 'd4;
            // end
        end
    end

    assign fetch = ~iq_full;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h1eceb000;
        end
        else begin
            case (fetch_state) 
                IDLE: begin
                    if (branch) begin
                        pc <= pc_next;
                    end
                    else begin
                        if(i_cache_resp && fetch) begin
                            pc <= pc_next;
                        end
                        else begin
                            pc <= pc;
                        end
                    end
                end 
                OPERATE: begin
                    
                    if(i_cache_resp) begin
                        if (branch) begin
                            pc <= pc_next;
                        end
                        else begin
                            if (fetch) begin
                                pc <= pc_next;
                            end
                            else begin
                                pc <= pc;
                            end
                        end
                        
                    end
                    else begin
                        pc <= pc;
                    end
                end
                default: begin
                    if(i_cache_resp && fetch) begin
                        pc <= pc_next;
                    end
                    else begin
                        pc <= pc;
                    end
                end
            endcase
            
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            branch_buffer <= '0;
            branch_addr_buffer <= '0;
        end
        else begin
            case (fetch_state)
                IDLE: begin
                    branch_buffer <= '0;
                    branch_addr_buffer <= '0;
                end
                OPERATE: begin
                    if (!i_cache_resp) begin
                        if (branch) begin
                            branch_buffer <= branch;
                            branch_addr_buffer <= pc_branch;
                        end
                    end
                    else begin
                        branch_buffer <= '0;
                        branch_addr_buffer <= '0;
                    end
                end
                default: begin
                    branch_buffer <= '0;
                    branch_addr_buffer <= '0;
                end

            endcase
            
        end
    end

   

    //assign fetch_state_next = OPERATE;

    always_comb begin
        case (fetch_state) 
            START: begin
                pc_fetch = pc;
            end
            IDLE: begin
                // if (!i_cache_resp) begin
                //     pc_fetch = pc;
                // end
                // else begin
                //     if (branch_buffer) begin
                //         pc_fetch = branch_addr_buffer;
                //     end
                //     else begin
                //         //pc_fetch = pc_next;
                //         pc_fetch = pc;
                //     end
                // end
                if (branch) begin
                    pc_fetch = pc_branch;
                end
                else begin
                    pc_fetch = pc;
                end
            end
            OPERATE: begin
                pc_fetch = pc;
            end
            default: begin
                pc_fetch = pc_next;
            end
        endcase
    end

    assign pc_out         = pc;
    assign pc_next_out    = pc_next;

    
    // pipelined_cache icache (
    //     .clk        (clk),
    //     .rst        (rst),
    //     .ufp_addr   (pc_fetch),
    //     .ufp_rmask  (4'b1111),
    //     .ufp_wmask  ('0),
    //     .ufp_rdata  (instr),
    //     .ufp_wdata  ('0),
    //     .ufp_resp   (i_cache_resp),
    //     .dfp_addr   (i_adapter_addr),
    //     .dfp_read   (i_adapter_read),
    //     .dfp_write  (i_adapter_write),
    //     .dfp_rdata  (i_adapter_rdata),
    //     .dfp_wdata  (i_adapter_wdata),
    //     .dfp_resp   (i_adapter_resp)
    // );
    
    provided_cache icache (
        .clk        (clk),
        .rst        (rst),
        .ufp_addr   (pc_fetch),
        .ufp_rmask  (4'b1111),
        .ufp_wmask  ('0),
        .ufp_rdata  (instr),
        .ufp_wdata  ('0),
        .ufp_resp   (i_cache_resp),
        .dfp_addr   (i_adapter_addr),
        .dfp_read   (i_adapter_read),
        .dfp_write  (i_adapter_write),
        .dfp_rdata  (i_adapter_rdata),
        .dfp_wdata  (i_adapter_wdata),
        .dfp_resp   (i_adapter_resp)
    );

    cacheline_adapter icache_adapter (
        .clk        (clk),
        .rst        (rst),
        .ufp_addr   (i_adapter_addr),
        .ufp_read   (i_adapter_read),
        .ufp_write  ('0),
        .ufp_wdata  ('0),
        .ufp_rdata  (i_adapter_rdata),
        .ufp_resp   (i_adapter_resp),
        .dfp_addr   (i_dram_addr),
        .dfp_read   (i_dram_read),
        .dfp_write  (i_dram_write),
        .dfp_wdata  (i_dram_wdata),
        .dfp_ready  (i_dram_ready),
        .dfp_raddr  (i_dram_raddr),
        .dfp_rdata  (i_dram_rdata),
        .dfp_rvalid (i_dram_rvalid) 
    );
   
    


endmodule
