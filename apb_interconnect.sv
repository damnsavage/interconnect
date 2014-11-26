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

module apb_interconnect(reset, pclk, master_data, dest_addrs, master_valids, 
                        slave_data, slave_valids);
   input  reset;
   input  pclk;
   input  [`DATA_WIDTH-1:0]  master_data [`NUM_SINKS-1:0];
   input  [`ADDR_WIDTH-1:0]  dest_addrs  [`NUM_SINKS-1:0];
   input  [`NUM_SINKS-1:0]   master_valids;
   output [`DATA_WIDTH-1:0]  slave_data;
   output [`NUM_SOURCES-1:0] slave_valids;

   wire reset, pclk;
   wire mst0_psel, mst0_penable;
   wire slv0_psel, slv0_penable;   
   wire pwrite, slv0_wr, slv0_rd;
   wire [`ADDR_WIDTH-1:0] paddr;
   wire [`DATA_WIDTH-1:0] pwdata, prdata;
   wire [`DATA_WIDTH-1:0] mst0_din;
   reg [`NUM_SOURCES-1:0] slave_valids;

   reg  [`NUM_SINKS-1:0]  valids_reg;
   reg  [`NUM_SINKS-1:0]  valids_r;
   reg  [`DATA_WIDTH-1:0] mst_dout;
   reg  [`ADDR_WIDTH-1:0] dest_addr;
   reg  [`ADDR_WIDTH-1:0] source_addr;
   
   reg   [5:0] i, current_idx; // Log2(NUM_SINKS)
   
   //////////////////////////////////////////
   //
   // Instantiate Master / Slave modules
   //
   //////////////////////////////////////////
   apb_master master0 (
      .pclk ( pclk), .reset( reset ), .psel( mst0_psel ),
      .penable( mst0_penable ), .pwrite ( pwrite ), .paddr( paddr ),
      .pwdata( pwdata ), .prdata( prdata ),
      .valids( valids_r ), .ip_din( ), .ip_dout( mst_dout ), .ip_addr( dest_addr )
      );

   apb_slave slave0 (
      .pclk ( pclk), .reset( reset ), .psel( slv0_psel ),
      .penable( slv0_penable ), .pwrite ( pwrite ), .paddr( paddr ),
      .pwdata( pwdata ), .prdata( prdata ),
      .wr( slv0_wr ), .rd( slv0_rd )
      );

   //////////////////////////////////////////
   //
   // Assignments
   //
   //////////////////////////////////////////
   assign slv0_psel    = mst0_psel;
   assign slv0_penable = mst0_penable;
   
   assign mst_dout  = master_data[current_idx];
   assign dest_addr = dest_addrs[current_idx];

   // Slave writes
   assign slave_data = pwdata;  

   //////////////////////////////////////////
   //
   // MAIN
   //
   //////////////////////////////////////////
   // Assert valids_r on rising edge of valids
   always @(posedge pclk or negedge reset) 
       if (reset)
         valids_reg <= 0;
       else 
         valids_reg <= master_valids;
         
   genvar j;
   generate
       for (j=0; j < `NUM_SINKS; j = j + 1) begin
           always @(posedge pclk or negedge reset) 
               if (reset)
                   valids_r[j] <= 0;
               else if (master_valids[j] == 1 && valids_reg[j] == 0) 
               // rising edge
                   valids_r[j] <= 1;
       end
   endgenerate

   // Generate output valid for source X when writing to source X
   generate
       for (j=0; j < `NUM_SOURCES; j = j + 1) begin
           always @(slv0_wr or reset) 
               if (reset)
                   slave_valids[j] <= 0;
               else if (slv0_wr == 1 && paddr == j) 
                   slave_valids[j] <= 1;
               else 
                   slave_valids[j] <= 0;
       end
// to fix...
   endgenerate
   
   // Deassert valids_r when relevant data was transferred
   // i.e. after penable of the transfer
   always @(posedge pclk)       
      if (slv0_penable == 1) begin
          valids_r[current_idx]   = 0;
      end
      
   // LSB of master_valids are transfered first
//   generate
//       for (i=`NUM_SINKS-1; i >= 0 && i <= `NUM_SINKS-1; i = i - 1) begin
//           always @(valids_r or negedge reset) 
//               if (!reset)
//                 current_idx = 0;
//               else if (master_valids[i] == 1)
//                 current_idx = i;
//       end
//   endgenerate

   always @(valids_r or posedge reset)
   begin
      if (reset)
          current_idx = 0;
      if (valids_r != 0)
          for (i=`NUM_SINKS-1; i >= 0 && i <= `NUM_SINKS-1; i = i - 1)
              if (valids_r[i] == 1)
                  current_idx = i;      
// to fix...
// changes too late so send 1st data twice...
   end

   /////////////////////////////   
   // APB decoder
   /////////////////////////////   

   
   /////////////////////////////
   // APB Address map
   /////////////////////////////
   // Slave addresses:
   // ----------------
   // 0 - tdm1 source 0
   // 0 - tdm1 source 1
   // 0 - tdm1 source 2
   // 0 - tdm1 source 3
   // 0 - tdm1 source 4
   // 0 - tdm1 source 5
   // 0 - tdm1 source 6
   // 0 - tdm1 source 7
   // 0 - tdm2 source 0
   // 0 - tdm2 source 1
   // 0 - tdm2 source 2
   // 0 - tdm2 source 3
   // 0 - tdm2 source 4
   // 0 - tdm2 source 5
   // 0 - tdm2 source 6
   // 0 - tdm2 source 7
   // 0 - tdm3 source 0
   // 0 - tdm3 source 1
   // 0 - tdm3 source 2
   // 0 - tdm3 source 3
   // 0 - tdm3 source 4
   // 0 - tdm3 source 5
   // 0 - tdm3 source 6
   // 0 - tdm3 source 7
   // 0 - slimbus
   // x - asrc_in
   // x - asrc_out
   // x - vad
   // x - analog 0
   // x - analog 1 
   // x - analog 2
   // x - analog 3
   // x - analog 4
   // x - analog 5
   // x - analog 6
   // x - analog 7
   // x - decimator 0
   // x - decimator 1 
   // x - decimator 2
   // x - decimator 3
   // x - decimator 4
   // x - decimator 5
   // 0   cf - tdm_channel_1_left      
   // 1   cf - tdm_channel_1_right     
   // 2   cf - tdm_channel_2           
   // 3   cf - tdm_channel_3           
   // 4   cf - gain_second_device_in   
   // 5   cf - voltage_sensing_left    
   // 6   cf - current_sensing_left    
   // 7   cf - voltage_sensing_right   
   // 8   cf - current_sensing_right   
   // 9   cf - pdm_channel_1           
   // 10  cf - pdm_channel_2           
   // 11  cf - pdm_channel_3           
   // 12  cf - pdm_channel_4           
   // 13  cf - pdm_channel_5           
   // 14  cf - pdm_channel_6           
   // 15  cf - low_latency_in_1 (I sense left HS)
   // 16  cf - low_latency_in_2 (I sense right HS)
   //
   // Broadcast addresses:
   // --------------------
   // give some slaves several addresses
   // If we want to allow one to many connections
   
   // Master addresses:
   // ----------------
   // 0 - tdm1 sink 0
   // 0 - tdm1 sink 1
   // 0 - tdm1 sink 2
   // 0 - tdm1 sink 3
   // 0 - tdm1 sink 4
   // 0 - tdm1 sink 5
   // 0 - tdm1 sink 6
   // 0 - tdm1 sink 7
   // 0 - tdm2 sink 0
   // 0 - tdm2 sink 1
   // 0 - tdm2 sink 2
   // 0 - tdm2 sink 3
   // 0 - tdm2 sink 4
   // 0 - tdm2 sink 5
   // 0 - tdm2 sink 6
   // 0 - tdm2 sink 7
   // 0 - tdm3 sink 0
   // 0 - tdm3 sink 1
   // 0 - tdm3 sink 2
   // 0 - tdm3 sink 3
   // 0 - tdm3 sink 4
   // 0 - tdm3 sink 5
   // 0 - tdm3 sink 6
   // 0 - tdm3 sink 7
   // 0 - slimbus
   // x - asrc_in
   // x - asrc_out
   // x - spkr current sensing left
   // x - spkr current sensing right
   // x - spkr voltage sensing left
   // x - spkr voltage sensing right
   // x - hdset current sensing left
   // x - hdset current sensing right
   // x - Microphone (decimator output) 
   // 17 cf - cf_audio_data_1_left             
   // 18 cf - cf_audio_data_1_right    
   // 19 cf - cf_audio_data_2_left          
   // 20 cf - cf_audio_data_2_right         
   // 21 cf - tdm_out_channel_1_left        
   // 22 cf - tdm_out_channel_1_right       
   // 23 cf - tdm_out_channel_2_left        
   // 24 cf - tdm_out_channel_2_right       
   // 25 cf - tdm_out_channel_3_left        
   // 26 cf - tdm_out_channel_3_right       
   // 27 cf - gain_out_second_device        
   // 28 cf - haptic_driver_control
   // 29 cf - gain_control_side_tone_mixing
   // 30 cf - low_latency_out_left
   // 31 cf - low_latency_out_right



   // Add gray encode / decode to data to reduce signal transitions??
   
endmodule
