#==================================================================
# Vivado Project Generation - ZYBO PS1
#===================================================================

#------------------- Project specific definitions ------------------

#### project name
set prj_name zybo_ps1

#### VHDL source files (in compilation order)
set vhdl_src_files {}
# Packages first
lappend vhdl_src_files pkg/ap_design_pkg.vhd
lappend vhdl_src_files pkg/ac_ssm2603_pkg.vhd
lappend vhdl_src_files pkg/ap_fir_pkg.vhd
lappend vhdl_src_files pkg/ap_dds_pkg.vhd
# Clock/Reset generation
lappend vhdl_src_files ap_clk_rst/clk_gen.vhd
lappend vhdl_src_files ap_clk_rst/rst_gen.vhd
lappend vhdl_src_files ap_clk_rst/clk_rst_gen.vhd
# Codec interface
lappend vhdl_src_files ap_codec/ac_i2c_master.vhd
lappend vhdl_src_files ap_codec/ac_i2c_wrapper.vhd
lappend vhdl_src_files ap_codec/ac_i2c_if.vhd
lappend vhdl_src_files ap_codec/ac_i2s_if.vhd
lappend vhdl_src_files ap_codec/ap_codec_if.vhd
# User components
lappend vhdl_src_files ap_user/fir/fir_trn.vhd
lappend vhdl_src_files ap_user/fir/fir_par.vhd
lappend vhdl_src_files ap_user/fir/fir_sel.vhd
lappend vhdl_src_files ap_user/dds/dds.vhd
lappend vhdl_src_files ap_user/audio/tone_gen.vhd
lappend vhdl_src_files ap_user/audio/audio_ram.vhd
lappend vhdl_src_files ap_user/seg/seg7_driver.vhd
lappend vhdl_src_files ap_user/seg/rotary_encoder_ctrl.vhd
lappend vhdl_src_files ap_user/ap_user_top.vhd
# Top level
lappend vhdl_src_files zybo_ps1_top.vhd

#### VHDL testbench files
set vhdl_tb_files {}
lappend vhdl_tb_files tb/tb_zybo_ps1_top.vhd

#### Constraints files
set const_files {}
lappend const_files ap_top.xdc

#### Waveform files
set wave_files {}
# lappend wave_files tb_ap_top.wcfg

#------------------- Default definitions and actions --------------

#### define environment
set prj_dir ./vivado
set vhdl_dir ./vhdl
set ctr_dir ./ctrl
set zynq_dev xc7z010clg400-1

#### build the project
set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

# Remove old project if exists
if {[file exists $prj_dir]} {
    puts "Removing old project directory..."
    file delete -force $prj_dir
}

# Create project
create_project $prj_name $prj_dir -part $zynq_dev -force

# Project settings
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]
set_property default_lib work [current_project]

#### add VHDL source files
if {[llength $vhdl_src_files] > 0} {
  set l_vhdl_src_files ""
  foreach file $vhdl_src_files {
    set full_path $vhdl_dir/$file
    if {[file exists $full_path]} {
      lappend l_vhdl_src_files $full_path
    } else {
      puts "WARNING: File not found: $full_path"
    }
  }
  if {[llength $l_vhdl_src_files] > 0} {
    add_files -norecurse $l_vhdl_src_files
    set_property library work [get_files $l_vhdl_src_files]
    set_property FILE_TYPE {VHDL 2008} [get_files $l_vhdl_src_files]
    update_compile_order -fileset sources_1
  }
}

#### add VHDL testbench files
if {[llength $vhdl_tb_files] > 0} {
  set_property SOURCE_SET sources_1 [get_filesets sim_1]
  set l_vhdl_tb_files ""
  foreach file $vhdl_tb_files {
    set full_path $vhdl_dir/$file
    if {[file exists $full_path]} {
      lappend l_vhdl_tb_files $full_path
    }
  }
  if {[llength $l_vhdl_tb_files] > 0} {
    add_files -fileset sim_1 -norecurse $l_vhdl_tb_files
    set_property library work [get_files $l_vhdl_tb_files]
    set_property FILE_TYPE {VHDL 2008} [get_files $l_vhdl_tb_files]
    update_compile_order -fileset sim_1
  }
}

#### add constraints files
if {[llength $const_files] > 0} {
  set l_const_files ""
  foreach file $const_files {
    set full_path $ctr_dir/$file
    if {[file exists $full_path]} {
      lappend l_const_files $full_path
    } else {
      puts "WARNING: Constraints file not found: $full_path"
    }
  }
  if {[llength $l_const_files] > 0} {
    add_files -fileset constrs_1 -norecurse $l_const_files
    set_property used_in_synthesis true [get_files $l_const_files]
  }
}

puts "Project created successfully!"
puts "Project location: [get_property DIRECTORY [current_project]]"