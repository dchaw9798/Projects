// module bmem_arbitor (
//     input logic bmem_ready,

//     //for icache response
//     input logic icache_read,
//     input logic [31:0]icache_bmem_addr,

//     //for dcache response
//     input logic dcache_read,
//     input logic dcache_write,
//     input logic [31:0]dcache_bmem_addr,
//     input lgoic [63:0]dcache_bmem_wdata,

//     //output to bmem
//     output logic [31:0]bmem_addr,
//     output logic [63:0]bmem_wdata,

//     //output to cache
//     output logic icache_ready,
//     output logic dcache_ready,
//     output logic bmem_read,bmem_write
// );


// always_comb begin
//     bmem_addr = '0;
//     bmem_wdata = '0;
//     icache_ready = '0;
//     dcache_ready = '0;
//     bmem_read = '0;
//     bmem_write = '0;
//     if(bmem_ready == 1'b1) begin
//         if(icache_read == 1'b1) begin
//             bmem_addr = icache_bmem_addr;
//             bmem_read = icache_read;
//             icache_ready = 1'b1;
//         end
//         if((dcache_read == 1'b1) | (dcache_write == 1'b1)) begin
//             bmem_addr = dcache_bmem_addr;
//             bmem_read = dcache_read;
//             bmem_write = dcache_write;
//             dcache_ready = 1'b1;
//             bmem_wdata = dcache_bmem_wdata;
//         end
//     end
// end
// endmodule