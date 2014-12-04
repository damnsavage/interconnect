// Verilog doesnt support 2D arrays as ports
// System verilog does.

///////  Verilog workaround if needed //////
// 
// `define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    \
//     genvar pk_idx; \
//     generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) \
//         assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; \
//     endgenerate
//
// `define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  
//     genvar unpk_idx; \
//     generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) \
//         assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; \
//     endgenerate
// 
// module example (                     
//     input  [63:0] pack_4_16_in,      
//     output [31:0] pack_16_2_out      
//     );                               
//                                     
// wire [3:0] in [0:15];                
// `UNPACK_ARRAY(4,16,in,pack_4_16_in)  
//                                     
// wire [15:0] out [0:1];               
// `PACK_ARRAY(16,2,in,pack_16_2_out)   
// 
///////////////////// 

module apb_interconnect(
    rstn, pclk, 
    sink_data, sink_valids, 
    source_data, source_valids, source_mapping
   );
   
   input  rstn;
   input  pclk;
   input  [`DATA_WIDTH-1:0]  sink_data  [`NSINKS-1:0];
   input  [`NSINKS-1:0]      sink_valids;
   input  [7:0]              source_mapping [`NSOURCES-1:0]; // from regbank 
   output [`DATA_WIDTH-1:0]  source_data;
   output [`NSOURCES-1:0]    source_valids;

   wire rstn, pclk;
   wire mst0_psel, mst0_penable;
   wire slv0_psel, slv0_penable;   
   wire pwrite, slv0_wr, slv0_rd;
   wire [`ADDR_WIDTH-1:0]  paddr;
   wire [`DATA_WIDTH-1:0]  pwdata, prdata;
   wire [`DATA_WIDTH-1:0]  mst0_din;
   reg  [`NSOURCES-1:0]    source_valids;

   reg  [`NSINKS-1:0]     valids_reg;
   reg  [`NSINKS-1:0]     valids_r, valids_active;
   reg  [`DATA_WIDTH-1:0] sink_dout;
   reg  [`ADDR_WIDTH-1:0] sink_addr;
   reg  [`ADDR_WIDTH-1:0] source_addr;
   
   reg  [$clog2(`NSINKS)-1:0] i, current_idx;
   reg  done, pclk_gated;
   
   //////////////////////////////////////////
   //
   // Instantiate Master / Slave modules
   //
   //////////////////////////////////////////
   apb_master master0 (
      .pclk ( pclk_gated ), .rstn( rstn ), .psel( mst0_psel ),
      .penable( mst0_penable ), .pwrite ( pwrite ), .paddr( paddr ),
      .pwdata( pwdata ), .prdata( prdata ),
      .done( done ), .ip_din( ), .sink_data( sink_dout ), .sink_addr( sink_addr )
      );

   apb_slave slave0 (
      .pclk ( pclk_gated ), .rstn( rstn ), .psel( slv0_psel ),
      .penable( slv0_penable ), .pwrite ( pwrite ), .paddr( paddr ),
      .pwdata( pwdata ), .prdata( prdata ),
      .wr( slv0_wr ), .rd( slv0_rd )
      );

   //////////////////////////////////////////
   //
   // MAIN
   //
   //////////////////////////////////////////
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
           always @(slv0_wr or rstn or paddr) // can't add source_mapping here for simulation?? I can add it in synthesis though!
               if (!rstn)
                   source_valids[j] <= 0;
               else if (slv0_wr == 1 && paddr == source_mapping[j])
                   source_valids[j] <= 1;
               else 
                   source_valids[j] <= 0;
       end
   endgenerate
      
// to fix... issue when finished transfer 1st data is resent

   // Following code is functional but maybe less optimal in synthesis
   // current_idx is registered this maybe an advantage to avoid glitches
//   always @(valids_r)
//   begin
//      if (valids_r != 0)
//          for (i=`NSINKS-1; i >= 0 && i <= `NSINKS-1; i = i - 1)
//              if (valids_r[i] == 1)
//                  current_idx = i;      
//   end

   always @(valids_active)
   begin
      // Needs to be manually updated when NSINKS changes!!!!    
      casez (valids_active)
          // Unfortunately '?' does not work in hex
          71'b??????????????????????????????????????????????????????????????????????1 : current_idx = 0;
          71'b?????????????????????????????????????????????????????????????????????10 : current_idx = 1;
          71'b????????????????????????????????????????????????????????????????????100 : current_idx = 2;
          71'b???????????????????????????????????????????????????????????????????1000 : current_idx = 3;
          71'b??????????????????????????????????????????????????????????????????10000 : current_idx = 4;
          71'b?????????????????????????????????????????????????????????????????100000 : current_idx = 5;
          71'b????????????????????????????????????????????????????????????????1000000 : current_idx = 6;
          71'b???????????????????????????????????????????????????????????????10000000 : current_idx = 7;
          71'b??????????????????????????????????????????????????????????????100000000 : current_idx = 8;
          71'b?????????????????????????????????????????????????????????????1000000000 : current_idx = 9;
          71'b????????????????????????????????????????????????????????????10000000000 : current_idx = 10;
          71'b???????????????????????????????????????????????????????????100000000000 : current_idx = 11;
          71'b??????????????????????????????????????????????????????????1000000000000 : current_idx = 12;
          71'b?????????????????????????????????????????????????????????10000000000000 : current_idx = 13;
          71'b????????????????????????????????????????????????????????100000000000000 : current_idx = 14;
          71'b???????????????????????????????????????????????????????1000000000000000 : current_idx = 15;
          71'b??????????????????????????????????????????????????????10000000000000000 : current_idx = 16;
          71'b?????????????????????????????????????????????????????100000000000000000 : current_idx = 17;
          71'b????????????????????????????????????????????????????1000000000000000000 : current_idx = 18;
          71'b???????????????????????????????????????????????????10000000000000000000 : current_idx = 19;
          71'b??????????????????????????????????????????????????100000000000000000000 : current_idx = 20;
          71'b?????????????????????????????????????????????????1000000000000000000000 : current_idx = 21;
          71'b????????????????????????????????????????????????10000000000000000000000 : current_idx = 22;
          71'b???????????????????????????????????????????????100000000000000000000000 : current_idx = 23;
          71'b??????????????????????????????????????????????1000000000000000000000000 : current_idx = 24;
          71'b?????????????????????????????????????????????10000000000000000000000000 : current_idx = 25;
          71'b????????????????????????????????????????????100000000000000000000000000 : current_idx = 26;
          71'b???????????????????????????????????????????1000000000000000000000000000 : current_idx = 27;
          71'b??????????????????????????????????????????10000000000000000000000000000 : current_idx = 28;
          71'b?????????????????????????????????????????100000000000000000000000000000 : current_idx = 29;
          71'b????????????????????????????????????????1000000000000000000000000000000 : current_idx = 30;
          71'b???????????????????????????????????????10000000000000000000000000000000 : current_idx = 31;
          71'b??????????????????????????????????????100000000000000000000000000000000 : current_idx = 32;
          71'b?????????????????????????????????????1000000000000000000000000000000000 : current_idx = 33;
          71'b????????????????????????????????????10000000000000000000000000000000000 : current_idx = 34;
          71'b???????????????????????????????????100000000000000000000000000000000000 : current_idx = 35;
          71'b??????????????????????????????????1000000000000000000000000000000000000 : current_idx = 36;
          71'b?????????????????????????????????10000000000000000000000000000000000000 : current_idx = 37;
          71'b????????????????????????????????100000000000000000000000000000000000000 : current_idx = 38;
          71'b???????????????????????????????1000000000000000000000000000000000000000 : current_idx = 39;
          71'b??????????????????????????????10000000000000000000000000000000000000000 : current_idx = 40;
          71'b?????????????????????????????100000000000000000000000000000000000000000 : current_idx = 41;
          71'b????????????????????????????1000000000000000000000000000000000000000000 : current_idx = 42;
          71'b???????????????????????????10000000000000000000000000000000000000000000 : current_idx = 43;
          71'b??????????????????????????100000000000000000000000000000000000000000000 : current_idx = 44;
          71'b?????????????????????????1000000000000000000000000000000000000000000000 : current_idx = 45;
          71'b????????????????????????10000000000000000000000000000000000000000000000 : current_idx = 46;
          71'b???????????????????????100000000000000000000000000000000000000000000000 : current_idx = 47;
          71'b??????????????????????1000000000000000000000000000000000000000000000000 : current_idx = 48;
          71'b?????????????????????10000000000000000000000000000000000000000000000000 : current_idx = 49;
          71'b????????????????????100000000000000000000000000000000000000000000000000 : current_idx = 50;
          71'b???????????????????1000000000000000000000000000000000000000000000000000 : current_idx = 51;
          71'b??????????????????10000000000000000000000000000000000000000000000000000 : current_idx = 52;
          71'b?????????????????100000000000000000000000000000000000000000000000000000 : current_idx = 53;
          71'b????????????????1000000000000000000000000000000000000000000000000000000 : current_idx = 54;
          71'b???????????????10000000000000000000000000000000000000000000000000000000 : current_idx = 55;
          71'b??????????????100000000000000000000000000000000000000000000000000000000 : current_idx = 56;
          71'b?????????????1000000000000000000000000000000000000000000000000000000000 : current_idx = 57;
          71'b????????????10000000000000000000000000000000000000000000000000000000000 : current_idx = 58;
          71'b???????????100000000000000000000000000000000000000000000000000000000000 : current_idx = 59;
          71'b??????????1000000000000000000000000000000000000000000000000000000000000 : current_idx = 60;
          71'b?????????10000000000000000000000000000000000000000000000000000000000000 : current_idx = 61;
          71'b????????100000000000000000000000000000000000000000000000000000000000000 : current_idx = 62;
          71'b???????1000000000000000000000000000000000000000000000000000000000000000 : current_idx = 63;
          71'b??????10000000000000000000000000000000000000000000000000000000000000000 : current_idx = 64;
          71'b?????100000000000000000000000000000000000000000000000000000000000000000 : current_idx = 65;
          71'b????1000000000000000000000000000000000000000000000000000000000000000000 : current_idx = 66;
          71'b???10000000000000000000000000000000000000000000000000000000000000000000 : current_idx = 67;
          71'b??100000000000000000000000000000000000000000000000000000000000000000000 : current_idx = 68;
          71'b?1000000000000000000000000000000000000000000000000000000000000000000000 : current_idx = 69;
          71'b10000000000000000000000000000000000000000000000000000000000000000000000 : current_idx = 70;
          default : current_idx = 0;
      endcase
   end

   //////////////////////////////////////////
   //
   // Assignments
   //
   //////////////////////////////////////////
   assign slv0_psel    = mst0_psel;
   assign slv0_penable = mst0_penable;
   
   assign sink_dout = sink_data[current_idx];
   assign sink_addr = current_idx;
   
   assign done = (valids_active == 0) ? 1 : 0;

   // Slave writes
   assign source_data = pwdata;  
   
   // not correct way to gate clock
   assign pclk_gated = (!done || slv0_psel) ? pclk : 1;
   
endmodule
