#!/usr/bin/bash
nios=$ALTERAPATH/nios2eds/nios2_command_shell.sh

TOP_MODULE="iob_ila"

$nios quartus_sh -t ../ila.tcl "$1" "$2" "$3"
$nios quartus_map --read_settings_files=on --write_settings_files=off $TOP_MODULE -c $TOP_MODULE
$nios quartus_fit --read_settings_files=off --write_settings_files=off $TOP_MODULE -c $TOP_MODULE
$nios quartus_cdb --read_settings_files=off --write_settings_files=off $TOP_MODULE -c $TOP_MODULE --merge=on
$nios quartus_cdb iob_ila -c iob_ila --incremental_compilation_export=iob_ila_0.qxp --incremental_compilation_export_partition_name=Top --incremental_compilation_export_post_synth=on --incremental_compilation_export_post_fit=off --incremental_compilation_export_routing=on --incremental_compilation_export_flatten=on

