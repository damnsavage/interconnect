module bin_mux_forloop(valids_r, current_idx);
   input  [`NUM_SINKS-1:0] valids_r; 

   output [`LOG2_NUM_SINKS-1:0] current_idx;
   reg    [`LOG2_NUM_SINKS-1:0] i, current_idx;

   // Following code is functional but does not synthesize well
   always @(valids_r)
   begin
      if (valids_r != 0)
          for (i=`NUM_SINKS-1; i >= 0 && i <= `NUM_SINKS-1; i = i - 1)
              if (valids_r[i] == 1)
                  current_idx = i;      
   end

endmodule



// Synthesis results
// synthesize -effort low -to_mapped
//
// Incremental optimization status
// ===============================
//                                     Worst - - DRC Totals - -
//                            Total  Weighted    Max       Max
// Operation                   Area  Neg Slk    Trans      Cap
// -------------------------------------------------------------------------------
//  init_delay                 2724        0         0        0
//
// delay 162 ps
//
//
//    Instance     Cells  Cell Area  Net Area  Total Area  Wireload
// ----------------------------------------------------------------------
// bin_mux_forloop    225       2724         0        2724    <none> (D)
// 
// 
//    Type    Instances   Area   Area %
// -------------------------------------
// sequential         6  110.101    4.0
// inverter          25  131.072    4.8
// logic            194 2482.504   91.1
// -------------------------------------
// total            225 2723.676  100.0
//

// using  -effort high -to_mapped
//
//    Type    Instances   Area   Area %
// -------------------------------------
// sequential         6  110.101    7.0
// inverter           8   41.943    2.7
// logic            114 1415.577   90.3
// -------------------------------------
// total            128 1567.621  100.0

