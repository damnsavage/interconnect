`timescale 1ns/1ps

program get_mapping(output logic [7:0] source_mapping [`NSOURCES-1:0]);
   class mapping;
       randc bit [7:0] mapping [`NSOURCES-1:0];       
   endclass
   
   task gen();
   endtask

endprogram


module tb();
   reg pclk, rstn;

   reg  [`NSINKS-1:0]     sink_valids;
   reg  [`DATA_WIDTH-1:0] sink_data [`NSINKS-1:0];
   reg  [`DATA_WIDTH-1:0] source_data;
   reg  [`NSOURCES-1:0]   source_valids;
   reg  [7:0]             source_mapping [`NSOURCES-1:0]; // mapping from regbank 

   
   logic [$clog2(`NSINKS)-1:0] i;
   logic [5:0] delay;
   logic [5:0] rnd_address;

   //////////////////////////////////////////
   //
   // Instantiate the interconnect
   //
   //////////////////////////////////////////
   apb_interconnect apb_bus (
      .rstn( rstn ), .pclk( pclk ), 
      .sink_data( sink_data ), .sink_valids( sink_valids ),
      .source_data( source_data ), .source_valids( source_valids ), .source_mapping( source_mapping )
      );
    
    // Instantiate your driver
    driver sink_driver()

   //////////////////////////////////////////
   //
   // MAIN
   //
   //////////////////////////////////////////
   initial begin
      pclk        = 0;
      rstn        = 0;
      sink_valids = 0;
      source_mapping = ;
      #5000
      rstn = 1;
      for (i = 0; i < `NSOURCES; i = i + 1) begin
          source_mapping[i] = $random;
      end
   end

   always begin
      pclk <= ~pclk;
      #500; // 1 MHz
   end
   
   // Generate Address, data and valids
   always @(posedge pclk)
   begin
      #(5000*24)
      
      for (i = 0; i < `NSINKS; i = i + 1) begin
          sink_data[i]  = $random;
          sink_addrs[i] = i;
      end
      #1;
      
      // Assign random values 32bits at a time
      for (i = 0; i < `NSINKS / 32; i = i + 1) begin
          sink_valids[i*32 +: 32] = $random;
      end
      // assign remaining bits
      for (i = 0; i < `NSINKS % 32; i = i + 1) begin
          sink_valids[(`NSINKS / 32)*32 + i +: 1] = $random;
      end
      
      // de-assert valids after 1 clock cycle
      #1001;
      sink_valids = 0;
      
   end
   
endmodule
