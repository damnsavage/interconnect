#!/bin/bash

irun -gui -access +rwc -timescale 1ns/1ps -linedebug \
    apb_slave.v apb_master.v apb_interconnect.sv tb.sv 
