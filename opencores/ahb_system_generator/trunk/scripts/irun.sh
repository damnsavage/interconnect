#!/bin/bash

# to use the existing script 'ahb_simulate.do' you need these variables
export DSN=/home/nxp66404/work/git/ahb_interconnect/opencores/ahb_system_generator/trunk
export SIMULATOR=ncvhdl

#AHB_Generate.pl 
# script to generate AHB interconnct system opens tcl/tk gui
# you can load some demo configs from ../conf or create your own
# script doesnt take any arguments. Output files are:
#  ahb_generate.conf
#  ahb_configure.vhd
#  ahb_matrix.vhd
#  ahb_system.vhd
#  ahb_tb.vhd
# I cant get the tk gui to read a conf file.
# however this seems to work
#perl AHB_Generate.pl -nogui ../conf/ahb_6mst_1slv.conf

# Using irun
irun -gui -access +rwc -timescale 1ns/1ns -f $DSN/scripts/files.f -top ahb_tb

# vhdl creates a log file for each master and slave

# the wrap files contain the file logging and

# slave wrap: has file logging and memory or register bank
