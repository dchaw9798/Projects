module fetch_old (
    input logic clk,
    input logic rst,
    input logic do_fetch, //tell if we should fetch
    input logic flush, //tell if flush happened in the instruction

    input logic [31:0] pc_branch_target, //branch prediction result
    input logic [63:0] order_branch_target, //keep the order of targets

    output logic [31:0] imem_addr,
    output logic [3:0] imem_rmask,
    output logic imem_rqst,

    output logic [31:0] pc,
    output logic [63:0] order,
    input logic [31:0] pc_next
);
  // registers
  logic [31:0] pc_curr;
  logic [63:0] order_curr;
  logic [63:0] order_next;

  // initialize all the values
  always_comb begin
    pc = pc_curr;
    order = order_curr;
    order_next = order + 64'b1;
    imem_addr = pc;
  end
  

  //when fetch, set mask and request
  //when not, set them 0
  always_comb begin
    if (do_fetch) begin
      imem_rmask = 4'b1111;
      imem_rqst  = 1'b1;
    end else begin
      imem_rmask = '0;
      imem_rqst  = '0;
    end
  end

  //rst: pc = 1ECEB000
  //fetch: pc <- pc_next
  //flush: pc <- pc_target
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_curr <= 32'h1ECEB000;
      order_curr <= '0;
    end else begin
      if (flush) begin
        pc_curr <= pc_branch_target;
        order_curr <= order_branch_target;
      end else if (do_fetch) begin
        pc_curr <= pc_next;
        order_curr <= order_next;
      end
    end
  end

endmodule
