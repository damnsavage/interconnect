# *********************************************************
# *
# * A very simple script that shows the basic RTL Compiler flow 
# *
# *********************************************************
set_attr lib_search_path { /home/uda9801_workareas/nxp66404/mx3/data/dsb_mx3_ic_lib/dsb_mx3_ic/encounter/lib/13_25/ }

#set_attribute hdl_search_path <full_path_of_hdl_files_directory>

set_attribute library {corelib_p_PttV1800T025.ldb}
#set_attribute library {c35_CORELIB_TYP.lib c35_IOLIB_TYP.lib}

# Grouping and ungrouping are helpful when you need to change your design hierarchy as
# part of your synthesis strategy. Grouping builds a level of hierarchy around a set of instances.
# ungrouping flattens a level of hierarchy. The following ungrouping command makes the rtl compiler
# optimize for timing, area or both during ungrouping...
# set_attribute auto_ungroup {none | timing | area | both} 

# read_hdl <hdl_file_names>
# when you issue the read_hdl command, RTL compiler reads the files and performs syntax checks
# -v1995 (default): IEEE Std 1364-1995 compliance
# -v2001 : IEEE Std 1364-2001 compliance
# type in the verilog files of your design after the read_hdl statement:
set_attr hdl_search_path { /home/nxp66404/work/git/interconnect }
read_hdl defines.v apb_slave.v apb_master.v -sv apb_interconnect.sv

#elaborate <top_level_design_name>
# the elaborate command builds the design (creats a design object). During elaboration RTL compiler
# performs the following tasks:
# 1. builds data structures
# 2. infers registers in the design
# 3. perfroms higher-level HDL optimization, such as dead code removal
# 4. check semantics
# after elaboration, RTL compiler has an internally created data structure for the whole design
# so you can apply constraints and perform other operations 
elaborate

# here with you can control the amount of information RTL Compiler writes out
# in the output logfiles.  set_attribute information_level 0(min) .. 9(max).
set_attribute information_level 9

# DEFINE_Clock Section
# the clock name must match to the name of the clock signal into your verilog file.
# please fill in the correct name of your clock signal and the maximum period time of your module (pico seconds).
#define_clock -name clk1 -period 50000 [find / -port ports_in/clk]
define_clock -name pclk -period 100000 [list "pclk"]
external_delay -clock pclk -input 0  /designs/*/ports_in/*
external_delay -clock pclk -output 2 /designs/*/ports_out/*
#create_clock -name "pclk" -add -period 1000.0 -waveform {0.0 500.0} [get_pins apb_interconnect/pclk]

#set_attribute information_level 4
#set clock [define_clock -period <periodicity> -name <clock_name> [clock_ports]]
#external_delay -input <specify_input_external_delay_on_clock>
#external_delay -output <specify_output_external_delay_on_clock>

# Net Load/Input
# Modify the names of your input signals and set them to be ideal! 
dc::set_load 0.2 [all_outputs]
dc::set_ideal_net pclk
#dc::set_ideal_net clrb

#ungroup -all -flatten

# the synthesizing includes following steps:
# 1. sythesizing the design to generic logic (RTL optimizations are performed in this step)
# 2. mapping to the technology library and performing incremental optimization
# there are two options for performing the synthetize command:
# 1. synthesize -to_generic: performs RTL optimization on your design. NOTE: when synthesize command
# is issued on an RTL design without any arguments, the -to_generic option is implied.
# 2. synthesize -to_mapped: it maps the specified design to the cells described in the supplied
# technology library and performs logic optimization(technology-independent boolean optimization,
# technology mapping nad technology-dependent gate optimization).
# setting the -effort to be high: the RTL compiler does the timing-driven structuring on larger sections
# of logic and spends more time and makes more attempts on inremental clean up. this effort level 
# involves very aggressive redundancy identification and removal. 
synthesize -effort low -to_mapped

report timing > reports/timing.rpt
report design > reports/design.rpt
report area >  reports/area.rpt
report summary > reports/summary.rpt
report gates > reports/gates.rpt
report clocks > reports/clock.rpt
report clocks -ideal > reports/clockideal.rpt
report clocks -generated > reports/clockgen.rpt
report nets > reports/nets.rpt
report power > reports/power.rpt

# the final part of the RTL compiler flow involves writing out the netlists and constraints.
# to write the gate-level netlist, use the write cmd. 
# The -mapped option of the write command writes a gate-level netlist,
# in this case to the file design.v
# write_hdl > design.v      # this writes the gate-level netlist to a file calles design.v
# Modify the name of the netlist file if necessary.
write -mapped > hardreg_net.v

# This command writes out the constraints to the file constraints.tcl
write_script > constraints.tcl

# This command writes out the constraints in SDC (standard design compiler) format.
# modify the name of your sdc file if necessary.
write_sdc > hardreg_sdc.sdc

# standard delay format (SDF) file that analysis and verification tools or timing
# simulation tools can use for delay annotation. 
# The  SDF  file  specifies  the  delay of all the cells and
# interconnects in the design in the Standard Delay Format. Specifically,
# it includes the delay values for all the timing arcs of a given cell in
# the design.
# Modify the name of the sdf file if necessary.
#write_sdf -no_escape -nonegchecks > hardreg_net.sdf
write_sdf -nonegchecks -no_escape -edges check_edge > hardreg_net.sdf
#exit
