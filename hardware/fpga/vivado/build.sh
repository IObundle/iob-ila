#!/usr/bin/bash
TOP_MODULE="iob_ila"
source $XILINXPATH/Vivado/settings64.sh
vivado -nojournal -log vivado.log -mode batch -source ../iob_ila.tcl -tclargs "$TOP_MODULE" "$1" "$2" "$3" "$4"
