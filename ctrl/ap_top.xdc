################################################################
# Project: DIDE Audio Processing Reference Design
# Entity : ap_ref_design_top.vhd
# Author : Waj
################################################################

################################################################
# Physical Constraints
################################################################

# Clock & Reset
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports clk_pi]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports rst_pi]

# Inputs
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {sw_pi[0]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {sw_pi[1]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {sw_pi[2]}];
# set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {sw_pi[3]}]; # SW_3

# Outputs
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led4_po[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led4_po[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led4_po[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led4_po[3]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led8_po[0]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {led8_po[1]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led8_po[2]}]
#set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {led8_po[3]}]
#set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {led8_po[4]}]
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led8_po[5]}]
#set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {led8_po[6]}]
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led8_po[7]}]

# Audio Codec I2S
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports ac_bclk_po]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_mclk_po]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports ac_mute_n_po]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports ac_pbdat_po]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ac_pblrc_po]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports ac_recdat_pi]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports ac_reclrc_po]

# Audio Codec I2C
set_property PACKAGE_PIN N18 [get_ports ac_scl_pio]
set_property IOSTANDARD LVCMOS33 [get_ports ac_scl_pio]
set_property PULLUP true [get_ports ac_scl_pio]
set_property PACKAGE_PIN N17 [get_ports ac_sda_pio]
set_property IOSTANDARD LVCMOS33 [get_ports ac_sda_pio]
set_property PULLUP true [get_ports ac_sda_pio]


################################################################
# Timing Constraints
################################################################

##############
# Primary input clocks
##############
# Define external 125 MHz clock source (input to MMCM1)
create_clock -period 8.000 -name clk_pi_125 -waveform {0.000 4.000} -add [get_ports clk_pi]

#############
# CDC constraints for asynchronous clocks SYS_CLK and BCLK (C0...C2)
#############
### Constrain max path delays between asynchronous CLK_SYS and BCLK domains
# Note: Setting both clock domains as asynchrouns with the command below does not
#       work, because this would overrule the subsequent set_max_delay command
#       which is necessary to constrain the delay to the first SYS_CLK synchr. FF
#       for signal smpl_enb_reg.
#       set_clock_groups -asynchronous -group mmcm1_clkout0 -group mmcm2_clkout0
# set max. delay from source FF (bclk) to the first sync FF (clk_sys) <= 1 clk_sys cc (C0).
set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/smpl_enb_regb_r*] -to [get_cells {u_ap_codec_if/u_ac_i2s_if/sync_regs_reg[0]}] 10.000

# declare all synchronization FFs as asynchronous to force min. delay between them (C0)
set_property ASYNC_REG true [get_cells u_ap_codec_if/u_ac_i2s_if/sync_regs_reg*]

# set max. delay of DAC sample rebister pathes (CLK_SYS -> BCLK) to <= 2 clk_sys cc (C1).
set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/dac*regs_reg*] -to [get_cells u_ap_codec_if/u_ac_i2s_if/dac*regb_reg*] 20.000

# set max. delay of ADC sample register pathes (BCLK -> CLK_SYS) to <= 2 clk_sys cc (C2).
set_max_delay -datapath_only -from [get_cells u_ap_codec_if/u_ac_i2s_if/adc*regb_reg*] -to [get_cells u_ap_codec_if/u_ac_i2s_if/adc*regs_reg*] 20.000

##############
# External input/output delays 
##############
### external I2S/SSM2603 interface signals
# Note: For both inputs and outputs, the clock (BCLK) is generated within the FPGA.
#       For outputs from the FPGA to the AC, this corresponds to classical source-
#       synchronous clocking (clock transmitted together with data). The max. allowed
#       signal skew is set to 1/8 BCLK period before or after the generating (falling) 
#       edge. This will provide sufficient safety margin for secure sampling with the
#       rising edge within the AC.
#       For inputs from the AC to the FPGA, a source-synchronous clocking is assumed for
#       contraining, 
#       ..........  
# generate clock at BLCK output pin corresponding to BCLK source pin
create_generated_clock -name bclk_out -multiply_by 1 -source [get_pins u_clk_rst/u_clk_gen/u_mmcm2/CLKOUT0] [get_ports ac_bclk_po]
# define relevant delay values
set bclk_period 	81.4;	        # BCLK_period = 1/12.288 MHz
set skew     	     8.1;			# leave max. 1/10 of BCLK period for internal FPGA delay  
set in_skew  	    6.0;			# max. 1/4 BCLK period after/before falling (generating) edge  

# output_delay for signals to audio codec (C3)
set out_ports {ac_pbdat_po ac_pblrc_po ac_reclrc_po}
set_output_delay -clock bclk_out -max [expr $bclk_period - $skew] [get_ports $out_ports] -clock_fall;
set_output_delay -clock bclk_out -min $skew                       [get_ports $out_ports] -clock_fall;

# input_delay for signals from audio codec (C4)
set in_ports {ac_recdat_pi}
set_input_delay -clock bclk_out -max [expr $bclk_period - $skew] [get_ports $in_ports] 
set_input_delay -clock bclk_out -min $skew                       [get_ports $in_ports] 

##############
# Timing relaxation in CLK_SYS domain
##############
### set multi_cycle constraints w.r.t. adc/dac sample rate. 
### Note: The max. supported sample rate is 96 kHz. With 100 kHz, there are 
#         100 MHz/100 kHz = 1000 CLK_SYS cycles between two successive ADC/DAC sample
#         enable signals.
#         For each multi-cycle constraints two commands are needed (2nd to bring hold 
#         requirement back to current clock edge).
# set sample enable rate in CLK_SYS domain
set SMPL_ENB_RATE 1000
# get all FFs with CE connected to the FF output in I2S-Interface that generate the ADC/DAC enable signal
set SmplCEcells [get_cells -of [filter [all_fanout -flat -endpoints [get_pins u_ap_codec_if/u_ac_i2s_if/data_enb_regs*/Q]] IS_ENABLE]]
# set multi-cycle constraint between all FFs with CE connected to the sample enable signal
set_multicycle_path -from $SmplCEcells -to $SmplCEcells -setup $SMPL_ENB_RATE
set_multicycle_path -from $SmplCEcells -to $SmplCEcells -hold [expr $SMPL_ENB_RATE-1]


