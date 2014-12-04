module valids (rstn, pclk, paddr, sink_valids, source_valids, source_mapping,
    slv0_wr, slv0_penable, valids_active, current_idx);
    
   input  rstn, pclk, slv0_wr, slv0_penable;
   input  [`NSINKS-1:0]   sink_valids;
   output [`NSOURCES-1:0] source_valids;
   input  [7:0]              source_mapping [`NSOURCES-1:0]; // from regbank 
   input  [`ADDR_WIDTH-1:0]  paddr;
   input  [$clog2(`NSINKS)-1:0] current_idx;
   output [`NSINKS-1:0]   valids_active;

   reg  [`NSOURCES-1:0] source_valids;
   reg  [`NSINKS-1:0]   valids_reg;
   reg  [`NSINKS-1:0]   valids_r;
   reg  [`NSINKS-1:0]   valids_active;

   // Assert valids_r on rising edge of valids
   always @(posedge pclk or negedge rstn) 
       if (!rstn)
         valids_reg <= 0;
       else 
         valids_reg <= sink_valids;
         
   genvar j;
   generate
       for (j=0; j < `NSINKS; j = j + 1) begin
           // rising edge detect combinational logic per sink
           always @(sink_valids or valids_reg)
               if (sink_valids[j] == 1 && valids_reg[j] == 0)
                   valids_r[j] = 1;
               else 
                   valids_r[j] = 0;

           // Valid is active after rising edge and 
           // Deasserted when relevant data was transferred
           // i.e. after penable of the transfer
           // Requires additional register per sink
           always @(posedge pclk or negedge rstn)       
              if (!rstn)
                  valids_active[j] = 0;
              else if (valids_r[j] == 1)
                  valids_active[j] = 1;
              else if (slv0_penable == 1 && j == current_idx) 
                  valids_active[j] = 0;
       end       
   endgenerate
   

   // Generate output valid for source X when paddr = source_mapping[x]
   generate
       for (j=0; j < `NSOURCES; j = j + 1) begin
           always @(slv0_wr or rstn or paddr) // can't add source_mapping here??
               if (!rstn)
                   source_valids[j] <= 0;
               else if (slv0_wr == 1 && paddr == source_mapping[j])
                   source_valids[j] <= 1;
               else 
                   source_valids[j] <= 0;
       end
   endgenerate


endmodule
