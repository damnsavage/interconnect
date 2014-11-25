`timescale 1ns/1ps

module tb();
   reg pclk, reset;

   reg  [`NUM_SINKS-1:0]  sink_valids;
   reg  [`DATA_WIDTH-1:0] sink_data   [`NUM_SINKS-1:0];
   reg  [`ADDR_WIDTH-1:0] dest_addrs  [`NUM_SINKS-1:0];
   reg  [`DATA_WIDTH-1:0] source_data [`NUM_SOURCES-1:0];
   
   logic [7:0] i;     // max of Log2(NUM_VALIDS)
   logic [5:0] delay;
   logic rnd_address;

   //////////////////////////////////////////
   //
   // Instantiate the interconnect
   //
   //////////////////////////////////////////
   apb_interconnect apb_matrix (
      .reset( reset ), .pclk( pclk ), 
      .master_data( sink_data ), .dest_addrs( dest_addrs ), .valids( sink_valids ),
      .slave_data( source_data )
      );


   //////////////////////////////////////////
   //
   // MAIN
   //
   //////////////////////////////////////////
   initial begin
      pclk        = 0;
      reset       = 1;
      sink_valids = 0;
      // intialise some random data and addrs
      for (i = 0; i < `NUM_SINKS; i = i + 1) begin
          sink_data[i] = $random;
          rnd_address = $random;
          while(rnd_address > `NUM_SOURCES-1)
              rnd_address = $random;
          dest_addrs[i] = rnd_address; // Should be < `NUM_SOURCES-1
      end
      $display("init done!!!");
      #5000
      reset = 0;
      #5000
      sink_valids = $random;
   end

   always begin
      pclk <= ~pclk;
      #500; // 1 MHz
   end
   
   // Generate valids
   always @(posedge pclk)
   begin
      delay = $random;
      #(5000*delay)
      sink_valids = $random;
   end
   

endmodule
