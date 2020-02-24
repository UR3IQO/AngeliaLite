# Angelia.sdc
# PHY_RX_CLOCK delay set to 0xF0 in setup register.
# 6th Oct - major review
# 10th Oct - false paths to slow I/0. 1nS delay for generated clocks.
# 14th Oct - remove max/min where symetrical
# 26th Oct - added generated clocks to PLL outputs that drive FPGA output pins
#          - set false path to all generated clocks that drive FPGA output pins
#  1st Nov - added CLRCIN CLRCOUT clocks 

# 20th May 2017 - testing muticlock 



#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock (base clocks, external to the FPGA)
#**************************************************************

create_clock -period 77.76MHz	     [get_ports ADC1_CLK]					-name ADC1_CLK
create_clock -period 77.76MHz	     [get_ports ADC2_CLK]					-name ADC2_CLK
create_clock -period 155.52MHz 	  [get_ports M_CLK]					   -name M_CLK
create_clock -period 50.000MHz     [get_ports PHY_CLK50] 				-name PHY_CLK50
create_clock -period 10.000MHz     [get_ports REF_CLK] 				   -name REF_CLK

#virtual base clocks on required inputs
create_clock -name virt_PHY_CLK50  	-period 50MHz

##ADC1 & ADC2 virtual clock
create_clock -name virt_ADC1_CLK 		-period 77.76MHz
create_clock -name virt_ADC2_CLK 		-period 77.76MHz

#SN4AUP1G80
#Delays 1.2..4.1ns, 0ns, 3.3..4.3ns (DCO)
#Buffer delay is 0.5..1.2ns
#So, minimal delay is 1.2+3.3-1.2 = 3.3ns
#maximal delay is 4.1+4.3-0.5 = 7.9ns
#set_clock_latency -source -early 3.3 [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
#set_clock_latency -source -late 7.9  [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
#set_clock_latency -source -early 3.3 [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
#set_clock_latency -source -late 7.9  [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]

#SN74AUC1G80 (in the ADC clocking path)
#Delays 0.3..1.3ns, 0ns, 3.3..4.3ns (DCO)
#SN74AUC2GU04 (in the DAC / M_CLK clocking path)
#Delays 0.4..1.2ns
#So, minimal delay is 0.3+3.3-0.4 = 3.2ns
#maximal delay is 1.3+4.3+1.2 = 6.8ns
set_clock_latency -source -early 3.2 [ get_clocks { ADC1_CLK virt_ADC1_CLK } ]
set_clock_latency -source -late  6.8 [ get_clocks { ADC1_CLK virt_ADC1_CLK } ]
set_clock_latency -source -early 3.2 [ get_clocks { ADC2_CLK virt_ADC2_CLK } ]
set_clock_latency -source -late  6.8 [ get_clocks { ADC2_CLK virt_ADC2_CLK } ]


create_clock -name virt_DAC_CLK		-period 155.52MHz

#SN74AUC2GU04
#Delays 
# set_clock_latency -source -early 0.4 [ get_clocks { DAC_CLK virt_DAC_CLK } ]
# set_clock_latency -source -late  1.2 [ get_clocks { DAC_CLK virt_DAC_CLK } ]

#virtual base clocks on required inputs
# create_clock -name {virt_PHY_RX_CLOCK} -period 8.000 -waveform { 0.000 4.000 } 
# create_clock -name {virt_122MHz} -period 8.138 -waveform { 0.000 4.069 } 
# create_clock -name {virt_CBCLK} -period 325.520 -waveform { 0.000 162.760 } 


derive_pll_clocks

derive_clock_uncertainty

#assign more familiar names!
#set C77_76_clk  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]

set C155_52_clk     PLL_main|altpll_component|auto_generated|pll1|clk[0]
set C77_76_clk      PLL_main|altpll_component|auto_generated|pll1|clk[1]
#set SYNC          PLL_main|altpll_component|auto_generated|pll1|clk[2]
set DACD_clocl      PLL_main|altpll_component|auto_generated|pll1|clk[3]

## Assign readable names to CODEC clocks (12.288MHZ / 3.072MHZ / 0.048MHz)
set CMCLK  PLL_C_inst|altpll_component|auto_generated|pll1|clk[0]
set CBCLK  PLL_C_inst|altpll_component|auto_generated|pll1|clk[1]
set CLRCLK PLL_C_inst|altpll_component|auto_generated|pll1|clk[2]

## Assign readable names to Network stuff clocks
set clock_12_5MHz network_inst|eth_pll_inst|altpll_component|auto_generated|pll1|clk[0]
set clock_2_5MHz  network_inst|eth_pll_inst|altpll_component|auto_generated|pll1|clk[1]
set clock_25MHz   network_inst|eth_pll_inst|altpll_component|auto_generated|pll1|clk[2]


#**************************************************************
# Create Generated Clock (internal to the FPGA)
#**************************************************************
# NOTE: Whilst derive_pll_clocks constrains PLL clocks if these are connected to an FPGA output pin then a generated
# clock needs to be attached to the pin and a false path set to it

# PLL generated clocks feeding output pins 
# create_generated_clock -name CBCLK   -source $CBCLK  [get_ports CBCLK]
# create_generated_clock -name CMCLK   -source $CMCLK  [get_ports CMCLK]
# create_generated_clock -name CLRCIN  -source $CLRCLK [get_ports CLRCIN]
# create_generated_clock -name CLRCOUT -source $CLRCLK [get_ports CLRCOUT]

#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous \
               -group { PHY_CLK50 \
                        network_inst|eth_pll_inst|altpll_component|auto_generated|pll1|clk[0] \
                        network_inst|eth_pll_inst|altpll_component|auto_generated|pll1|clk[1] } \
					-group { ADC1_CLK ADC2_CLK virt_ADC1_CLK virt_ADC2_CLK M_CLK virt_DAC_CLK \
                        PLL_main|altpll_component|auto_generated|pll1|clk[1] \
                        PLL_main|altpll_component|auto_generated|pll1|clk[3] \
                        PLL_main|altpll_component|auto_generated|pll1|clk[0] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[0] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[1] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[2] } \
               -group { REF_CLK }

#************************************************************** 
# Set Input Delay
#**************************************************************

#ADC data output delay relative to DCO (ADC2_CLK/ADC2_CLK)
set_input_delay -clock virt_ADC1_CLK -min -0.9 [get_ports { ADC1[*] ADC1_OVF }]
set_input_delay -clock virt_ADC1_CLK -max -0.3 [get_ports { ADC1[*] ADC1_OVF }]
set_input_delay -clock virt_ADC2_CLK -min -0.9 [get_ports { ADC2[*] ADC2_OVF }]
set_input_delay -clock virt_ADC2_CLK -max -0.3 [get_ports { ADC2[*] ADC2_OVF }]

# data from PHY
set_input_delay  -max 5.0  -clock virt_PHY_CLK50 -add_delay [get_ports {PHY_RX[*] PHY_CRS}] 
set_input_delay  -min -1.4 -clock virt_PHY_CLK50 -add_delay [get_ports {PHY_RX[*] PHY_CRS}] 				

#**************************************************************
# Set Output Delay
#**************************************************************

# # If setup and hold delays are equal then only need to specify once without max or min 

##DAC setup and hold times

#DAC setup time (2ns)
#6.43 - 2.0
set_output_delay -clock virt_DAC_CLK -max -4.43 [get_ports {DAC[*]}] 

#DAC hold time (1.5ns)  subtract one clock cycle cause PLL clock has negative 400ps shift
#set_output_delay -clock virt_DAC_CLK -min -7.93 [get_ports { DAC[*] }]
#6.43 + 1.5
set_output_delay -clock virt_DAC_CLK -min -7.93 [get_ports {DAC[*]}]

# data to PHY
set_output_delay  -max 4.0  -clock virt_PHY_CLK50 [get_ports {PHY_TX[*] PHY_TX_EN}] 
set_output_delay  -min -1.5 -clock virt_PHY_CLK50 [get_ports {PHY_TX[*] PHY_TX_EN}] 

# #PHY (2.5MHz)
# set_output_delay  10 -clock $clock_2_5MHz {PHY_MDIO} -add_delay


#**************************************************************
# Set Maximum Delay
#************************************************************** 

# set_max_delay -from _122MHz -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] 10
# set_max_delay -from _122MHz -to _122MHz 11

# set_max_delay -from LTC2208_122MHz -to LTC2208_122MHz 18

# set_max_delay -from PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0] -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] 3
# set_max_delay -from PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] 11

# set_max_delay -from network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] -to tx_clock 21
# set_max_delay -from network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] -to network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] 21

# set_max_delay -from tx_clock -to network_inst|rgmii_send_inst|tx_pll_inst|altpll_component|auto_generated|pll1|clk[0] 21
# set_max_delay -from tx_clock -to tx_clock 21

# set_max_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK 10

#**************************************************************
# Set Multicycle Path
#************************************************************** 

#Set multicycle path for the data form Tx1_DAC_data to DACD
#set_multicycle_path -from { PLL_main|altpll_component|auto_generated|pll1|clk[0] } -to { PLL_main|altpll_component|auto_generated|pll1|clk[3] } -setup 2
#set_multicycle_path -from { mix_tx:mix_tx_inst|dac* } -to { DACD* } -setup 2
#set_multicycle_path -from { mix_tx:mix_tx_inst|dac* } -to { DACD* } -hold  -end 1

##CIC RX Decimation, stage 1

set_multicycle_path 9 -to [get_fanouts [get_registers {receiver:receiver_inst*|cic:cic_inst_I1|out_strobe}] -through [get_pins -hierarchical *|*ena*]] -end -setup
set_multicycle_path 8 -to [get_fanouts [get_registers {receiver:receiver_inst*|cic:cic_inst_I1|out_strobe}] -through [get_pins -hierarchical *|*ena*]] -end -hold

##CIC RX Decimation, stage 2

set_multicycle_path 45 -to [get_fanouts [get_registers {receiver:receiver_inst*|varcic:varcic_inst_I1|out_strobe}] -through [get_pins -hierarchical *|*ena*]] -end -setup
set_multicycle_path 44 -to [get_fanouts [get_registers {receiver:receiver_inst*|varcic:varcic_inst_I1|out_strobe}] -through [get_pins -hierarchical *|*ena*]] -end -hold

##FIR RX Decimation, stage 3

set_multicycle_path 405 -to [get_fanouts [get_registers {receiver:receiver_inst*|FIRDecim:firdecim_inst|strobe_out}] -through [get_pins -hierarchical *|*ena*]] -end -setup
set_multicycle_path 404 -to [get_fanouts [get_registers {receiver:receiver_inst*|FIRDecim:firdecim_inst|strobe_out}] -through [get_pins -hierarchical *|*ena*]] -end -hold


#**************************************************************
# Set Minimum Delay
#**************************************************************

# set_min_delay -from virt_PHY_RX_CLOCK -to PHY_RX_CLOCK -3
# set_min_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK -1
# set_min_delay -from PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2] -to PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1] -1


#**************************************************************
# Set False Paths
#**************************************************************
 
#set_false_path -from [get_clocks {ADC1_CLK}] -to [get_clocks {ADC2_CLK}]

# # Set false path to generated clocks that feed output pins
# set_false_path -to [get_ports {CMCLK CBCLK CLRCLK PHY_MDC PHY_TX_CLOCK}]

# don't need fast paths to the fallowing outputs
set_false_path -to [get_registers { Led_flash:Flash_LED*|LED }]
set_false_path -to [get_keepers  { FPGA_PTT }]

# #don't need fast paths from the following inputs
set_false_path -from [get_ports  { ADC1_OVF ADC2_OVF PTT }]
set_false_path -from [get_cells  { debounce:*|clean_pb }]
set_false_path -from [get_keepers { profile:*|*_PTT }]


#these registers are set long before they are used
#set_false_path -from [get_registers {network:network_inst|local_mac[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|local_ip[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|arp:arp_inst|destination_mac[*]}] -to [all_registers]

############################################# LNA/ADC Control SPI ###############################################
#LNA/ADC SPI output pins
set_false_path -to [get_ports LNA_*]

############################################# MB MCU SPI ###############################################
#LNA/ADC SPI output pins
set_false_path -to [get_ports { MCU_MISO }]
set_false_path -from [get_ports { MCU_MOSI MCU_CLK MCU_LOAD MCU_MAC_LOAD }]

################################################ Misc ########################################################
#1.2V regulator syncronization
set_false_path -to [get_ports SYNC]

#Phase detector output
set_false_path -to [get_ports PD_*]

#Internal reference enable
set_false_path -to [get_ports REF_EN]

#Keyer inputs
set_false_path -from [get_ports { KEY_DOT KEY_DASH }]

#PHY MDC
set_false_path -to [get_ports {PHY_MDC PHY_MDIO}]
set_false_path -from [get_ports {PHY_MDIO}]
