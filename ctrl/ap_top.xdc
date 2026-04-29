################################################################################
# Project       : DIDE Audio Processing Reference Design
# Entity        : ap_ref_design_top.vhd
# Description   : Physical and Timing Constraints for Zybo Z7
################################################################################

################################################################################
# Physical Constraints
################################################################################

# Primary Clock & Reset
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports clk_pi]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports rst_pi]

# User Switches (SW0..SW3)
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {sw_pi[0]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {sw_pi[1]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {sw_pi[2]}]
#set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {sw_pi[3]}]

# User Buttons (BTN1, BTN2)
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {btn_pi[1]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {btn_pi[2]}]

# Rotary Encoder
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports rot_a_pi]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports rot_b_pi]

# LED Bar Graph (8-bit)
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led8_po[0]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {led8_po[1]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led8_po[2]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {led8_po[3]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {led8_po[4]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led8_po[5]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {led8_po[6]}]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led8_po[7]}]

# Status LEDs (4-bit, onboard LD0..LD3)
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led4_po[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led4_po[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led4_po[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led4_po[3]}]

# ==============================================================================
# 7-Segment Anzeige (Exakt aus Übung 9)
# ==============================================================================
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { seg_po[0] }] ;# Segment A
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { seg_po[1] }] ;# Segment B
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { seg_po[2] }] ;# Segment C
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { seg_po[3] }] ;# Segment D
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { seg_po[4] }] ;# Segment E
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { seg_po[5] }] ;# Segment F
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { seg_po[6] }] ;# Segment G

# ==============================================================================
# 7-Segment Anoden (Digit Select)
# W14 ist der 8. Pin des Ports und steuert den Wechsel der Ziffern!
# V12 ist ein Dummy-Pin für an_po[1], damit Vivado nicht abstürzt.
# ==============================================================================
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { an_po[0] }]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { an_po[1] }]

# Audio Codec I2S Interface
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports ac_bclk_po]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_mclk_po]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports ac_mute_n_po]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports ac_pbdat_po]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ac_pblrc_po]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports ac_recdat_pi]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports ac_reclrc_po]

# Audio Codec I2C Configuration Interface
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ac_scl_pio]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ac_sda_pio]


################################################################################
# Timing Constraints
################################################################################

# Base Clock Definition
create_clock -period 8.000 -name clk_pi_125 -waveform {0.000 4.000} -add [get_ports clk_pi]

# Clock Domain Crossing (CDC) Constraints
set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/smpl_enb_regb_r*] -to [get_cells {u_ap_codec_if/u_ac_i2s_if/sync_regs_reg[0]}] 10.000
set_property ASYNC_REG true [get_cells u_ap_codec_if/u_ac_i2s_if/sync_regs_reg*]

set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/dac*regs_reg*] -to [get_cells u_ap_codec_if/u_ac_i2s_if/dac*regb_reg*] 20.000
set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/adc*regb_reg*] -to [get_cells u_ap_codec_if/u_ac_i2s_if/adc*regs_reg*] 20.000

# Generated Clocks
create_generated_clock -name bclk_out -multiply_by 1 -source [get_pins u_clk_rst/u_clk_gen/u_mmcm2/CLKOUT0] [get_ports ac_bclk_po]

# External Input/Output Delay Parameters
set bclk_period 81.4
set skew 8.1
set in_skew 6.0

# Output Delays
set out_ports {ac_pbdat_po ac_pblrc_po ac_reclrc_po}
set_output_delay -clock bclk_out -max [expr $bclk_period - $skew] [get_ports $out_ports] -clock_fall
set_output_delay -clock bclk_out -min $skew [get_ports $out_ports] -clock_fall

# Input Delays
set in_ports {ac_recdat_pi}
set_input_delay -clock bclk_out -max [expr $bclk_period - $skew] [get_ports $in_ports]
set_input_delay -clock bclk_out -min $skew [get_ports $in_ports]

# Multicycle Path Constraints for ADC/DAC Sample Rate
set SMPL_ENB_RATE 1000
set SmplCEcells [get_cells -of [filter [all_fanout -flat -endpoints [get_pins u_ap_codec_if/u_ac_i2s_if/data_enb_regs*/Q]] IS_ENABLE]]

set_multicycle_path -from $SmplCEcells -to $SmplCEcells -setup $SMPL_ENB_RATE
set_multicycle_path -from $SmplCEcells -to $SmplCEcells -hold [expr $SMPL_ENB_RATE - 1]