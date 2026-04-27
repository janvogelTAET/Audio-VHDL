#==================================================================
# Vivado Project Generation
#===================================================================

#------------------- Project specific definitions ------------------

#### project name
set prj_name zybo_ps1

#### VHDL source files
set vhdl_src_files {}
lappend vhdl_src_files zybo_ps1_top.vhd
lappend vhdl_src_files ap_user/ap_user_top.vhd
lappend vhdl_src_files ap_user/fir/fir_par.vhd
lappend vhdl_src_files ap_user/dds/dds.vhd
lappend vhdl_src_files ap_clk_rst/clk_rst_gen.vhd
lappend vhdl_src_files ap_clk_rst/clk_gen.vhd
lappend vhdl_src_files ap_clk_rst/rst_gen.vhd
lappend vhdl_src_files ap_codec/ap_codec_if.vhd
lappend vhdl_src_files ap_codec/ac_i2c_if.vhd
lappend vhdl_src_files ap_codec/ac_i2c_wrapper.vhd
lappend vhdl_src_files ap_codec/ac_i2c_master.vhd
lappend vhdl_src_files ap_codec/ac_i2s_if.vhd
lappend vhdl_src_files pkg/ac_ssm2603_pkg.vhd
lappend vhdl_src_files pkg/ap_design_pkg.vhd
lappend vhdl_src_files pkg/ap_fir_pkg.vhd
lappend vhdl_src_files pkg/ap_dds_pkg.vhd

#### VHDL tstbench files
set vhdl_tb_files {}
lappend vhdl_tb_files tb/tb_zybo_ps1_top.vhd

#### Constraints files
set const_files {}
lappend const_files ap_top.xdc

#### Waveform files
set wave_files {}
lappend wave_files tb_ap_top.wcfg

#------------------- Default definitions and actions --------------

#### define environment ####################
# project directory
set prj_dir ./vivado
# source directory
set vhdl_dir ./vhdl
# control directory
set ctr_dir ./ctrl
# Zynq device
set zynq_dev xc7z010clg400-1

#### build the project #####################
# move to script directory
set script_dir [file dirname [file normalize [info script]]]
cd $script_dir
# create project
create_project $prj_name $prj_dir -part $zynq_dev
# project settings
#set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]
set_property default_lib work [current_project]

#### add VHDL source files ################
if {[llength $vhdl_src_files] > 0} {
  set l_vhdl_src_files ""
  foreach file $vhdl_src_files {
    set l_vhdl_src_files [concat $l_vhdl_src_files $vhdl_dir/$file]
  }
  add_files -norecurse $l_vhdl_src_files
  set_property library work [get_files $l_vhdl_src_files]
  set_property FILE_TYPE {VHDL 2008} [get_files $l_vhdl_src_files]
  update_compile_order
}

#### add VHDL testbench files #############
if {[llength $vhdl_tb_files] > 0} {
  set_property SOURCE_SET sources_1 [get_filesets sim_1]
  set l_vhdl_tb_files ""
  foreach file $vhdl_tb_files {
    set l_vhdl_tb_files [concat $l_vhdl_tb_files $vhdl_dir/$file]
  }
  add_files -fileset sim_1 -norecurse $l_vhdl_tb_files
  set_property library work [get_files $l_vhdl_tb_files]
  set_property FILE_TYPE {VHDL 2008} [get_files $l_vhdl_tb_files]
  update_compile_order -fileset sim_1
}

#### add constraints files #################
if {[llength $const_files] > 0} {
  set l_const_files ""
  foreach file $const_files {
    set l_const_files [concat $l_const_files $ctr_dir/$file]
  }
    add_files -fileset constrs_1 -norecurse $l_const_files
    set_property used_in_synthesis false [get_files $l_const_files]
}

#### add waveform files ####################
if {[llength $wave_files] > 0} {
  set_property SOURCE_SET sources_1 [get_filesets sim_1]
  set l_wave_files ""
  foreach file $wave_files {
    set l_wave_files [concat $l_wave_files $ctr_dir/$file]
  }
  add_files -fileset sim_1 -norecurse $l_wave_files
}

