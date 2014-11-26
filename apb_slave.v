module apb_slave (pclk, reset, psel, penable, pwrite, paddr, pwdata, prdata,
                  wr, rd);
    input                    pclk;
    input                    reset;
    input                    psel;
    input                    penable;
    input                    pwrite;
    input  [`ADDR_WIDTH-1:0] paddr;
    input  [`DATA_WIDTH-1:0] pwdata;
    output [`DATA_WIDTH-1:0] prdata;
    output                   wr, rd;

`ifdef APB3
    output pslverr;
    output pready; 
`endif

    wire                     wr, rd;
    reg  [`DATA_WIDTH-1:0]   din_r;
    reg  [`DATA_WIDTH-1:0]   ip_dout;
   
    assign wr     = psel & penable & pwrite;
    assign rd     = psel & (~penable) & (~pwrite);
    assign prdata = (penable && psel) ? ip_dout : {`DATA_WIDTH{1'bx}};

endmodule
