module valids (rstn, pclk, paddr, master_valids, slave_valids, 
    src_brdcst_subscription, slv0_wr, slv0_penable, valids_active, current_idx);
    
   input  rstn, pclk, slv0_wr, slv0_penable;
   input  [`NSINKS-1:0]   master_valids;
   output [`NSOURCES-1:0] slave_valids;
   input  [`NSOURCES-1:0] src_brdcst_subscription;
   input  [`ADDR_WIDTH-1:0]  paddr;
   input  [$clog2(`NSINKS)-1:0] current_idx;
   output [`NSINKS-1:0]   valids_active;

   reg  [`NSOURCES-1:0] slave_valids;
   reg  [`NSINKS-1:0]   valids_reg;
   reg  [`NSINKS-1:0]   valids_r;
   reg  [`NSINKS-1:0]   valids_active;

   // Assert valids_r on rising edge of valids
   always @(posedge pclk or negedge rstn) 
       if (!rstn)
         valids_reg <= 0;
       else 
         valids_reg <= master_valids;
         
   genvar j;
   generate
       for (j=0; j < `NSINKS; j = j + 1) begin
           // rising edge detect combinational logic per sink
           always @(master_valids or valids_reg)
               if (master_valids[j] == 1 && valids_reg[j] == 0)
                   valids_r[j] = 1;
               else 
                   valids_r[j] = 0;

           // Valid is active after rising edge and 
           // Deasserted when relevant data was transferred
           // i.e. after penable of the transfer
           // Requires additional register per sink
           always @(posedge pclk)       
              if (valids_r[j] == 1)
                  valids_active[j] = 1;
              else if (slv0_penable == 1 && j == current_idx) 
                  valids_active[j] = 0;
       end       
   endgenerate
   

   // Generate output valid for source X when writing to source X
   generate
       for (j=0; j < `NSOURCES; j = j + 1) begin
           always @(slv0_wr or rstn or paddr or src_brdcst_subscription) 
               if (!rstn)
                   slave_valids[j] <= 0;
               else if ( slv0_wr == 1 && (paddr == j || 
                         (paddr == `NSOURCES && src_brdcst_subscription[j] == 1) ) // broadcast 
                        )
                   slave_valids[j] <= 1;
               else 
                   slave_valids[j] <= 0;
       end
   endgenerate


endmodule
