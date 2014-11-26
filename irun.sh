#!/bin/bash

irun -gui -access +rwc -timescale 1ns/1ps -linedebug \
    defines.v apb_slave.v apb_master.v apb_interconnect.sv tb.sv 
