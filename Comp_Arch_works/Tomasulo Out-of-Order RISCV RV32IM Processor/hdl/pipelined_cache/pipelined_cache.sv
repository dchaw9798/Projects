module pipelined_cache 
import rv32im_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    logic             ufp_read;
    logic             ufp_write;
    logic             ufp_read_1;
    logic             ufp_write_1;
    logic             ufp_rw_0;
    logic             ufp_rw_1;
    
    logic             csb;
    logic             web[4];
    logic             web_valid[4];

    logic             stall;
    logic             tag_match;

    logic    [2:0]    lru_dout1;

    // cache input signal
    logic   [31:0]    ufp_addr_cache;
    logic   [3:0]     ufp_rmask_cache;
    logic   [31:0]    ufp_wmask_cache;
    logic   [255:0]   ufp_wdata_cache; 
    logic   [255:0]   dfp_rdata_cache;
    logic   [31:0]    cache_wmask;
    logic   [255:0]   cache_data_din;
    logic   [23:0]    cache_tag_din;
   

  

    // cache output signal
    logic   [255:0]  cache_data_1[4];
    logic   [23:0]   cache_tag_1[4]; 
    logic            dirty_bit;
    logic   [31:0]   ufp_rdata_local;

    // PLRU encode signal
    logic            hit_1;
    logic            clean_miss_1;
    logic            dirty_miss_1;
    logic   [2:0]    PLRU_rdata;
    logic   [1:0]    way_hit;
    logic   [1:0]    way_replace;
    logic   [2:0]    PLRU_update;




    // ufp value at stage 0
    logic   [31:0]    ufp_addr_0;
    logic   [3:0]     ufp_rmask_0;
    logic   [3:0]     ufp_wmask_0;
    logic   [31:0]    ufp_wdata_0;
    logic             csb_0;
    // tag/set/valid at stage 0
    logic   [22:0]    tag_0;
    logic   [3:0]     set_0;
    logic             valid_0[4];

    // shadow reg stored value at stage 1
    logic   [31:0]    ufp_addr_1;
    logic   [3:0]     ufp_rmask_1;
    logic   [3:0]     ufp_wmask_1;
    logic   [31:0]    ufp_wdata_1;
    logic             csb_1;

    // tag/set at stage 1
    logic   [22:0]    tag_1;
    logic   [3:0]     set_1;
    logic             valid_1[4];

    // tag/set/valid at cache input
    logic   [22:0]    tag_cache;
    logic   [3:0]     set_cache;
    logic             valid_cache;
    logic             csb_cache;

    // cache write control signal
    logic   [1:0]     cache_write;


    // data state
    logic   [1:0]     data_state;

    

    
    always_comb begin
        ufp_read_1 = 1'b0;
        ufp_write_1 = 1'b0;
        //ufp_rw_0 = 1'b0;
        // if (rst) begin
        //     ufp_rw_0 = 1'b0;
        // end
        //else begin
            if (ufp_rmask_1 != '0) begin 
                ufp_read_1 = 1'b1;
            end 
            if (ufp_wmask_1 != '0) begin
                ufp_write_1 = 1'b1;
            end  
            // if ((|ufp_rmask)|(|ufp_wmask)) begin
            //     ufp_rw_0 = 1'b1;
            // end      
        //end  
    end

    enum logic [1:0] {
        idle,
        //start,
        control,
        dfp_read_finish,
        dfp_write_finish
    } state, state_next;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= idle;
        end
        else begin
            state <= state_next;
        end
    end
    // always_comb begin
    //     state_replace = start;
        
    //     if (select) begin
    //         state = state_replace;
    //     end
    //     else begin
    //         state = state_int;
    //     end
    // end

    assign ufp_rw_0 =  ((|ufp_rmask)|(|ufp_wmask));
    // logic [3:0] write_hit_counter, write_hit_counter_initiallized;
    // always_ff @(posedge clk) begin
    //     if (tag_match && (|ufp_wmask_1)) begin
    //         write_hit_counter <= write_hit_counter + 1'b1;
    //     end
    //     else begin
    //         write_hit_counter <= write_hit_counter_initiallized;
    //     end
    // end


    //assign ufp_rw_0 = (ufp_rmask[0] | ufp_rmask[1] | ufp_rmask[2] | ufp_rmask[3] | ufp_wmask[0] | ufp_wmask[1] | ufp_wmask[2] | ufp_wmask[3]);   
    always_comb begin
        
        case (state)
            idle: begin
                if (ufp_rw_0) begin
                    state_next = control;
                    //write_hit_counter_initiallized = 4'b0;
                end
                else begin
                    state_next = idle;
                end
            end
            // start: begin
            //     state_next = control;
            // end
            control: begin
                if (ufp_resp) begin
                    if (ufp_rw_0) begin
                        state_next = control;
                        //write_hit_counter_initiallized = 4'b0;
                    end
                    else begin
                        state_next = idle;
                    end
                end
                else begin
                    if (dirty_miss_1) begin
                        if (dfp_resp) begin
                            state_next = dfp_write_finish;
                        end
                        else begin
                            state_next = control; 
                        end   
                    
                    end
                    else begin
                        if (dfp_resp) begin
                            state_next = dfp_read_finish;
                        end
                        else begin
                            state_next = control; 
                        end   
                    end
                end
            end
            dfp_read_finish:
                state_next = control;
            dfp_write_finish: 
                state_next = control;
            default:
                state_next = idle;
        endcase
    end



    always_comb begin
        stall       = 1'b0;
        dfp_read    = 1'b0;
        dfp_write   = 1'b0;
        csb         = 1'b1;
        case (state)
            // idle: begin
            //     stall       = 1'b0;
            //     dfp_read    = 1'b0;
            //     dfp_write   = 1'b0;
            //     csb         = 1'b1;
            // end
            idle: begin
                stall       = 1'b0;
                dfp_read    = 1'b0;
                dfp_write   = 1'b0;
                csb         = 1'b0;
                // if (ufp_rw_0) begin
                //     csb         = 1'b0;
                // end
                // else begin
                //     csb         = 1'b1;
                // end
                
            end
            control: begin
                // csb = 1'b0;
                // if (write_hit_counter == 4'b0001) begin
                //     stall       = 1'b1;
                //     dfp_read    = 1'b0;
                //     dfp_write   = 1'b0;
                //     csb         = 1'b0;
                // end
                if (ufp_resp) begin
                    stall       = 1'b0;
                    dfp_read    = 1'b0;
                    dfp_write   = 1'b0;
                    csb         = 1'b0;
                end
                else begin
                    stall   = 1'b1;
                    csb = 1'b0;
                    if (dirty_miss_1) begin
                        dfp_read  = 1'b0;
                        dfp_write = dirty_miss_1;
                    end
                    else begin
                        dfp_read  = clean_miss_1;
                        dfp_write = 1'b0;
                    end

                end
            end

            dfp_read_finish: begin
                stall       = 1'b1;
                dfp_read    = 1'b0;
                dfp_write   = 1'b0;
                csb         = 1'b0;
            end
            dfp_write_finish: begin
                stall      = 1'b1;
                dfp_read   = 1'b1;
                dfp_write  = 1'b0;
                csb        = 1'b0;
            end
            default: begin
                stall       = 1'b0;
                dfp_read    = 1'b0;
                dfp_write   = 1'b0;
                csb         = 1'b1;
            end
        endcase
    end

    Pipeline_Reg Pipeline_Reg (
        .clk            (clk),
        .rst            (rst),
        .ufp_addr_0     (ufp_addr_0),
        .ufp_rmask_0    (ufp_rmask_0),
        .ufp_wmask_0    (ufp_wmask_0),
        .ufp_wdata_0    (ufp_wdata_0),
        .state          (state),
        //.csb_0          (csb_0),
        .ufp_addr_1     (ufp_addr_1),
        .ufp_rmask_1    (ufp_rmask_1),
        .ufp_wmask_1    (ufp_wmask_1),
        .ufp_wdata_1    (ufp_wdata_1),
        .csb_1          (csb_1)
    );

    // ufp stage 0 signal mux
    always_comb begin

        ufp_addr_0    = ufp_addr;
        ufp_rmask_0   = ufp_rmask;
        ufp_wmask_0   = ufp_wmask;
        ufp_wdata_0   = ufp_wdata;
        csb_0         = csb;

        if (stall) begin
            ufp_addr_0    = ufp_addr_1;
            ufp_rmask_0   = ufp_rmask_1;
            ufp_wmask_0   = ufp_wmask_1;
            ufp_wdata_0   = ufp_wdata_1;
            csb_0         = csb_1;
        end

        else begin
            ufp_addr_0    = ufp_addr;
            ufp_rmask_0   = ufp_rmask;
            ufp_wmask_0   = ufp_wmask;
            ufp_wdata_0   = ufp_wdata;
            csb_0         = csb;
        end
    end

    
    // ufp cache input signal mux
    always_comb begin
        
        //ufp_addr_cache    = ufp_addr_0;
        ufp_addr_cache    = 'x;
        ufp_rmask_cache   = ufp_rmask_0;
        ufp_wmask_cache   = {28'b0,ufp_wmask_0};
        ufp_wdata_cache   = {224'b0,ufp_wdata_0};
        csb_cache         = '0;
        cache_wmask       = '0;
        cache_data_din    = '0;
        cache_tag_din     = '0;
        //valid_cache       = '0;
        web[0]            = 1'b1;
        web[1]            = 1'b1;
        web[2]            = 1'b1;
        web[3]            = 1'b1;

        if (rst) begin
            ufp_addr_cache    = '0;
            web[0] = 1'b1;
            web[1] = 1'b1;
            web[2] = 1'b1;
            web[3] = 1'b1;
        end
        else begin// if (stall_state == 1'b1) begin

            unique case(cache_write)
                no_write: begin
                    ufp_addr_cache    = ufp_addr_0;
                    ufp_rmask_cache   = ufp_rmask_0;
                    ufp_wmask_cache   = 'x;
                    ufp_wdata_cache   = '0;
                    csb_cache         = csb_0;
                    cache_wmask       = 'x;
                    cache_data_din    = 'x;
                    //cache_tag_din     = {1'b0, ufp_addr_cache[31:9]};
                    cache_tag_din     = 'x;
                    
                    web[0]            = 1'b1;
                    web[1]            = 1'b1;
                    web[2]            = 1'b1;
                    web[3]            = 1'b1;


                end
                write_cpu: begin
                    ufp_addr_cache    = ufp_addr_1;
                    ufp_rmask_cache   = ufp_rmask_1;
                    ufp_wmask_cache   = {28'b0,ufp_wmask_1};
                    ufp_wdata_cache   = {224'b0,ufp_wdata_1};
                    csb_cache         = csb_1;
                    cache_wmask       = ufp_wmask_cache << (ufp_addr_cache[4:2]*4);
                    cache_data_din    = ufp_wdata_cache << (ufp_addr_cache[4:2]*32);
                    cache_tag_din     = {1'b1, ufp_addr_cache[31:9]};
                    //valid_cache       = 1'b1;
                    if (data_state == 2'b10) begin
                        unique case(way_replace)
                            2'b00: web[0] = 1'b0; 
                            2'b01: web[1] = 1'b0; 
                            2'b10: web[2] = 1'b0; 
                            2'b11: web[3] = 1'b0; 
                            default: begin
                                web[0] = 1'b1;
                                web[1] = 1'b1;
                                web[2] = 1'b1;
                                web[3] = 1'b1; 
                            end
                        endcase
                    end
                    if (data_state == 2'b00) begin
                        unique case(way_hit)
                            2'b00: web[0] = 1'b0; 
                            2'b01: web[1] = 1'b0; 
                            2'b10: web[2] = 1'b0; 
                            2'b11: web[3] = 1'b0; 
                            default: begin
                                web[0] = 1'b1;
                                web[1] = 1'b1;
                                web[2] = 1'b1;
                                web[3] = 1'b1; 
                            end
                        endcase
                    end
                end
                write_mem: begin
                    ufp_addr_cache    = ufp_addr_1;
                    ufp_rmask_cache   = ufp_rmask_1;
                    ufp_wmask_cache   = {28'b0,ufp_wmask_1};
                    ufp_wdata_cache   = {224'b0,ufp_wdata_1};
                    csb_cache         = csb_0;
                    cache_wmask       = 32'hFFFFFFFF;
                    cache_data_din    = dfp_rdata_cache;
                    //valid_cache       = 1'b1;
                    if (dirty_miss_1) begin
                        if (dfp_write && dfp_resp) begin
                            cache_tag_din     = {1'b0, cache_tag_1[way_replace][22:0]};
                            unique case(way_replace)
                                2'b00: web[0] = 1'b0; 
                                2'b01: web[1] = 1'b0; 
                                2'b10: web[2] = 1'b0; 
                                2'b11: web[3] = 1'b0; 
                                default: begin
                                    web[0] = 1'b1;
                                    web[1] = 1'b1;
                                    web[2] = 1'b1;
                                    web[3] = 1'b1; 
                                end
                            endcase

                        end
                    end

                    else if (clean_miss_1) begin
                        cache_tag_din[23]     = 1'b0;
                        if (dfp_read && dfp_resp) begin
                            cache_tag_din     = {1'b0, dfp_addr[31:9]};
                            unique case(way_replace)
                                2'b00: web[0] = 1'b0; 
                                2'b01: web[1] = 1'b0; 
                                2'b10: web[2] = 1'b0; 
                                2'b11: web[3] = 1'b0; 
                                default: begin
                                    web[0] = 1'b1;
                                    web[1] = 1'b1;
                                    web[2] = 1'b1;
                                    web[3] = 1'b1; 
                                end
                            endcase
                        end

                    
                    end

                end 
                default: begin
                    ufp_addr_cache    = ufp_addr_1;
                    ufp_rmask_cache   = ufp_rmask_0;
                    ufp_wmask_cache   = {28'b0,ufp_wmask_0};
                    ufp_wdata_cache   = {224'b0,ufp_wdata_0};
                    csb_cache         = csb_0;
                    cache_wmask       = '0;
                    cache_data_din    = '0;
                    cache_tag_din     = {1'b0, ufp_addr_cache[31:9]};
                    web[0]            = 1'b1;
                    web[1]            = 1'b1;
                    web[2]            = 1'b1;
                    web[3]            = 1'b1;
                    //valid_cache       = '0;
                end
            endcase 
        end
 
    end


    // signal assign
    always_comb begin
        set_0 = ufp_addr_0[8:5];
        tag_0 = ufp_addr_0[31:9];
        set_1 = ufp_addr_1[8:5];
        tag_1 = ufp_addr_1[31:9];
        set_cache = ufp_addr_cache[8:5];
        tag_cache = ufp_addr_cache[31:9];
        dirty_bit = cache_tag_1[way_replace][23];
    end
    
    // way_hit logic
    always_comb begin 
        tag_match = '0;
        way_hit = 'x;

        // valid && equal
        if (cache_tag_1[0][22:0] == tag_1 && valid_1[0]) begin
            way_hit = way_A;
            tag_match = 1'b1;
        end
        else if (cache_tag_1[1][22:0] == tag_1 && valid_1[1]) begin
            way_hit = way_B;
            tag_match = 1'b1;
        end
        else if (cache_tag_1[2][22:0] == tag_1 && valid_1[2]) begin
            way_hit = way_C;
            tag_match = 1'b1;
        end
        else if (cache_tag_1[3][22:0] == tag_1 && valid_1[3]) begin
            way_hit = way_D;
            tag_match = 1'b1;
        end
        else begin
            tag_match = 1'b0;
            way_hit   = 'x;
        end
    end

    // hit/miss logic
    cache_controller cache_control (
        .clk            (clk),
        .rst            (rst),
        .tag_match      (tag_match),
        .dirty_bit      (dirty_bit),
        .ufp_read_1     (ufp_read_1),
        .ufp_write_1    (ufp_write_1),
        //.ufp_rw_1       (ufp_rw_1),
        //.stall_state    (stall_state),
        .valid_1        (valid_1),
        .way_replace    (way_replace),
        .dfp_resp       (dfp_resp),
        .cache_state    (state),
        //.write_hit_counter (write_hit_counter),
        //.stall          (stall),
        .hit            (hit_1),
        .clean_miss_1   (clean_miss_1),
        .dirty_miss_1   (dirty_miss_1),
        .ufp_resp       (ufp_resp),
        .cache_write    (cache_write),
        .data_state     (data_state)
    );
    
    
    // hit read
    always_comb begin
        ufp_rdata = 'x;
        ufp_rdata_local = '0;
        if (ufp_read_1) begin
            if (hit_1) begin
                ufp_rdata_local = cache_data_1[way_hit][32 * ufp_addr_1[4:2] +: 32];
                // ufp_rdata = {
                //     (ufp_rmask_1[3] ? ufp_rdata_local[31:24] : 8'b0),  // Byte 3: [31:24]
                //     (ufp_rmask_1[2] ? ufp_rdata_local[23:16] : 8'b0),  // Byte 2: [23:16]
                //     (ufp_rmask_1[1] ? ufp_rdata_local[15:8]  : 8'b0),  // Byte 1: [15:8] 
                //     (ufp_rmask_1[0] ? ufp_rdata_local[7:0]   : 8'b0)   // Byte 0: [7:0]          
                // };
                ufp_rdata = ufp_rdata_local;
            end 
        end
    end 


    // clean miss read/write
    always_comb begin
        dfp_rdata_cache = 'x;
        valid_0[0] = 1'b0;
        valid_0[1] = 1'b0;
        valid_0[2] = 1'b0;
        valid_0[3] = 1'b0;
        if ((dfp_read && dfp_resp) || (cache_write == write_cpu)) begin
            if (clean_miss_1) begin
                dfp_rdata_cache = dfp_rdata;
                case(way_replace)
                    2'b00: begin
                        valid_0[0] = 1'b1;
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end
                    
                    2'b01: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = 1'b1;
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end
                    2'b10: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = 1'b1;
                        valid_0[3] = valid_1[3];
                    end
                    2'b11: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = 1'b1;
                    end
                    default:begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end

                endcase
                
            end  
            if (hit_1) begin
                dfp_rdata_cache = dfp_rdata;
                case(way_hit)
                    2'b00: begin
                        valid_0[0] = 1'b1;
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end
                    
                    2'b01: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = 1'b1;
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end
                    2'b10: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = 1'b1;
                        valid_0[3] = valid_1[3];
                    end
                    2'b11: begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = 1'b1;
                    end
                    default:begin
                        valid_0[0] = valid_1[0];
                        valid_0[1] = valid_1[1];
                        valid_0[2] = valid_1[2];
                        valid_0[3] = valid_1[3];
                    end

                endcase
                
            end  

        end
        else begin
            valid_0[0] = 'x;
            valid_0[1] = 'x;
            valid_0[2] = 'x;
            valid_0[3] = 'x;
        end

    end



    always_comb begin
        dfp_addr  = '0;
        dfp_wdata = 'x;

         
        if (dfp_write) begin 
            dfp_addr = {cache_tag_1[way_replace][22:0] , set_1, 5'b0};
            dfp_wdata = cache_data_1[way_replace];
        end else if (dfp_read) begin
            dfp_addr = {tag_1, set_1, 5'b0};
            
        end 
   
    end

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_ooo_data_array data_array (
            .clk0       (clk),
            .csb0       (csb_cache),
            .web0       (web[i]),
            .wmask0     (cache_wmask),
            .addr0      (set_cache),
            .din0       (cache_data_din),
            .dout0      (cache_data_1[i])
        );
        mp_ooo_tag_array tag_array (
            .clk0       (clk),
            .csb0       (csb_cache),
            .web0       (web[i]),
            .addr0      (set_cache),
            .din0       (cache_tag_din),
            .dout0      (cache_tag_1[i])
        );
        valid_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (web[i]),
            .addr0      (set_cache),
            .din0       (valid_0[i]),
            .dout0      (valid_1[i])
        ); 


        // if dfp_resp then pull valid high
    end endgenerate

    lru_array lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (csb_0),
        .web0       (1'b1),
        .addr0      (set_0),
        .din0       ('0),
        .dout0      (PLRU_rdata),
        .csb1       (csb_1),
        .web1       (~hit_1),
        .addr1      (set_1),
        .din1       (PLRU_update),
        .dout1      (lru_dout1) //no dout for write only lru array
    );

    PLRU PLRU (
        .hit            (hit_1),
        .PLRU_rdata     (PLRU_rdata), 
        .way_hit        (way_hit),
        .PLRU_update    (PLRU_update),
        .way_replace    (way_replace)
    );

endmodule
