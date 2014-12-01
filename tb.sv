`timescale 1ns/1ps

module tb();
   reg pclk, rstn;

   reg  [`NUM_SINKS-1:0]   sink_valids;
   reg  [`DATA_WIDTH-1:0]  sink_data   [`NUM_SINKS-1:0];
   reg  [`ADDR_WIDTH-1:0]  dest_addrs  [`NUM_SINKS-1:0];
   reg  [`DATA_WIDTH-1:0]  source_data;
   reg  [`NUM_SOURCES-1:0] source_valids;
   
   logic [`LOG2_NUM_SINKS-1:0] i;
   logic [5:0] delay;
   logic [5:0] rnd_address;
   logic [`NUM_SOURCES-1:0] src_brdcst_subscription;

   //////////////////////////////////////////
   //
   // Instantiate the interconnect
   //
   //////////////////////////////////////////
   apb_interconnect apb_bus (
      .rstn( rstn ), .pclk( pclk ), 
      .master_data( sink_data ), .dest_addrs( dest_addrs ), .master_valids( sink_valids ),
      .slave_data( source_data ), .slave_valids( source_valids ), .src_brdcst_subscription( src_brdcst_subscription )
      );


   //////////////////////////////////////////
   //
   // MAIN
   //
   //////////////////////////////////////////
   initial begin
      pclk        = 0;
      rstn        = 0;
      sink_valids = 0;
      src_brdcst_subscription = 0;
      #5000
      rstn = 1;
   end

   always begin
      pclk <= ~pclk;
      #500; // 1 MHz
   end
   
   // Generate Address, data and valids
   always @(posedge pclk)
   begin
      #(5000*24)
      
      for (i = 0; i < `NUM_SINKS; i = i + 1) begin
          sink_data[i] = $random;
          rnd_address = $random;
          while(rnd_address > `NUM_SOURCES-1 + 1)
              rnd_address = $random;
          dest_addrs[i] = rnd_address; // Should be < `NUM_SOURCES-1 + number of broadcast channels
      end
      #1;
      
      // Assign random values 32bits at a time
      for (i = 0; i < `NUM_SINKS / 32; i = i + 1) begin
          sink_valids[i*32 +: 32] = $random;
      end
      for (i = 0; i < `NUM_SOURCES / 32; i = i + 1) begin
          src_brdcst_subscription[i*32 +: 32] = $random;
      end
      // assign remaining bits
      for (i = 0; i < `NUM_SINKS % 32; i = i + 1) begin
          sink_valids[(`NUM_SINKS / 32)*32 + i +: 1] = $random;
      end
      for (i = 0; i < `NUM_SOURCES % 32; i = i + 1) begin
          src_brdcst_subscription[(`NUM_SOURCES / 32)*32 + i +: 1] = $random;
      end
      
      // de-assert valids after 1 clock cycle
      #1001;
      sink_valids = 0;
      
   end
   

endmodule
