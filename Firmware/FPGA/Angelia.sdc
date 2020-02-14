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
set_clock_latency -source -early 3.3 [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
set_clock_latency -source -late 7.9  [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
set_clock_latency -source -early 3.3 [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]
set_clock_latency -source -late 7.9  [ get_clocks { virt_ADC1_CLK  virt_ADC2_CLK} ]


create_clock -name virt_DAC_CLK		-period 155.52MHz

#virtual base clocks on required inputs
# create_clock -name {virt_PHY_RX_CLOCK} -period 8.000 -waveform { 0.000 4.000 } 
# create_clock -name {virt_122MHz} -period 8.138 -waveform { 0.000 4.069 } 
# create_clock -name {virt_CBCLK} -period 325.520 -waveform { 0.000 162.760 } 


derive_pll_clocks

derive_clock_uncertainty

#assign more familiar names!
set _77_76MHz  PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]

set M_CLK_PLL     PLL_main|altpll_component|auto_generated|pll1|clk[0]
set M_SPI_EN      PLL_main|altpll_component|auto_generated|pll1|clk[1]
set SYNC          PLL_main|altpll_component|auto_generated|pll1|clk[2]
set DACD_clocl    PLL_main|altpll_component|auto_generated|pll1|clk[3]

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
					-group { ADC1_CLK ADC2_CLK M_CLK \
                        PLL_IF_inst|altpll_component|auto_generated|pll1|clk[3] \
                        PLL_main|altpll_component|auto_generated|pll1|clk[3] \
                        PLL_main|altpll_component|auto_generated|pll1|clk[0] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[0] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[1] \
                        PLL_C_inst|altpll_component|auto_generated|pll1|clk[2] } \
               -group { REF_CLK }

#************************************************************** 
# Set Input Delay
#**************************************************************

#ADC setup and hold times
# set_multicycle_path 3 -to [get_registers {ADC*}] -end -setup
# set_multicycle_path 2 -to [get_registers {ADC*}] -end -hold

# set_multicycle_path 3 -from [get_clocks {ADC*_CLK}] -end -setup
# set_multicycle_path 2 -from [get_clocks {ADC*_CLK}] -end -hold

set_input_delay -clock virt_ADC1_CLK -min -0.3 [get_ports { ADC1[*] ADC1_OVF }]
set_input_delay -clock virt_ADC1_CLK -max  1.2 [get_ports { ADC1[*] ADC1_OVF }]
set_input_delay -clock virt_ADC2_CLK -min -0.3 [get_ports { ADC2[*] ADC2_OVF }]
set_input_delay -clock virt_ADC2_CLK -max  1.2 [get_ports { ADC2[*] ADC2_OVF }]

# # If setup and hold delays are equal then only need to specify once without max or min 

# #12.5MHz clock for Config EEPROM  +/- 10nS setup and hold
# set_input_delay 10  -clock  $clock_12_5MHz { ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_cv82:ASMI_altasmi_parallel_cv82_component|sd2~ALTERA_DATA0 }

# # data from LTC2208 +/- 2nS setup and hold 
# set_input_delay 2.000 -clock virt_122MHz  { INA*}

# data from PHY
set_input_delay  -max 5.0  -clock virt_PHY_CLK50 -add_delay [get_ports {PHY_RX[*] PHY_CRS}] 
set_input_delay  -min -1.4 -clock virt_PHY_CLK50 -add_delay [get_ports {PHY_RX[*] PHY_CRS}] 				

# #TLV320 Data in +/- 20nS setup and hold
# set_input_delay  20  -clock virt_CBCLK  {CDOUT} -add_delay

# #EEPROM Data in +/- 40nS setup and hold
# set_input_delay  40  -clock $clock_2_5MHz {SO} -add_delay 

# #PHY PHY_MDIO Data in +/- 10nS setup and hold
# set_input_delay  10  -clock $clock_2_5MHz {PHY_MDIO PHY_INT_N} -add_delay

# #ADC78H90 Data in +/- 10nS setup and hold
# set_input_delay  10  -clock data_clk2 {ADCMISO} -add_delay


#**************************************************************
# Set Output Delay
#**************************************************************

# # If setup and hold delays are equal then only need to specify once without max or min 

##DAC setup and hold times

#DAC setup time (2ns) subtract one clock cycle cause PLL clock has negative 400ps shift
#Relax requirements by 300ps
set_output_delay -clock virt_DAC_CLK -max -4.73 [get_ports { DAC[*] }] 
#set_output_delay -clock virt_DAC_CLK -max 2.0 [get_ports {DAC[*]}] 

#DAC hold time (1.5ns)  subtract one clock cycle cause PLL clock has negative 400ps shift
set_output_delay -clock virt_DAC_CLK -min -7.93 [get_ports { DAC[*] }]
#set_output_delay -clock virt_DAC_CLK -min -1.5 [get_ports {DAC[*]}]

set_output_delay  -max 4.0  -clock virt_PHY_CLK50 [get_ports {PHY_TX[*] PHY_TX_EN}] 
set_output_delay  -min -1.5 -clock virt_PHY_CLK50 [get_ports {PHY_TX[*] PHY_TX_EN}] 

# #12.5MHz clock for Config EEPROM  +/- 10nS
# set_output_delay  10 -clock $clock_12_5MHz {ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_cv82:ASMI_altasmi_parallel_cv82_component|sd2~ALTERA_DCLK ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_cv82:ASMI_altasmi_parallel_cv82_component|sd2~ALTERA_SCE ASMI_interface:ASMI_int_inst|ASMI:ASMI_inst|ASMI_altasmi_parallel_cv82:ASMI_altasmi_parallel_cv82_component|sd2~ALTERA_SDO }

# #122.88MHz clock for Tx DAC 
# #set_output_delay 0.8 -clock _122MHz {DACD[*]}
# set_output_delay 1.0 -clock $DACD_clock {DACD[*]} -add_delay

# # Attenuators - min is referenced to falling edge of clock 
# set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* } -add_delay
# set_output_delay  10  -clock data_clk { ATTN_DATA* ATTN_LE* } -clock_fall -add_delay

# #TLV320 SPI  
# set_output_delay  20 -clock data_clk { MOSI nCS} -add_delay

# #TLV320 Data out 
# set_output_delay  10 -clock $CBCLK {CDIN CMODE} -add_delay

# #Alex  uses CBCLK/4
# set_output_delay  10 -clock data_clk2 { SPI_SDO J15_5 J15_6} -add_delay

# #EEPROM (2.5MHz)
# set_output_delay  40 -clock $clock_2_5MHz {SCK SI CS} -add_delay

# #ADC78H90 
# set_output_delay  10 -clock data_clk2 {ADCMOSI nADCCS} -add_delay

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

#set_multicycle_path -from [get_keepers { temp1_DACD }] -to [get_keepers { DACD } ] -setup -start 3
#set_multicycle_path -from [get_keepers { temp1_DACD }] -to [get_keepers { DACD } ] -hold -start 3


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

# don't need fast paths to the LEDs and adhoc outputs so set false paths so Timing will be ignored
#set_false_path -to [get_keepers { Status_LED DEBUG_LED* DITH* FPGA_PTT  NCONFIG  RAND*  USEROUT* FPGA_PLL DAC_ALC}]
# set_false_path -to [get_keepers { Status_LED }]
set_false_path -to [get_registers { Led_flash:Flash_LED*|LED }]

# #don't need fast paths from the following inputs
#set_false_path -from [get_keepers  {ANT_TUNE IO4 IO5 IO6 IO8 KEY_DASH KEY_DOT OVERFLOW* PTT MODE2}]
#set_false_path -from [get_keepers  {IO4 IO5 IO6 IO8 KEY_DASH KEY_DOT OVERFLOW* PTT FPGA_PTT}]
set_false_path -from [get_ports  { ADC1_OVF ADC2_OVF PTT }]
set_false_path -to [get_keepers  { FPGA_PTT }]
set_false_path -from [get_cells  { debounce:*|clean_pb }]
set_false_path -from [get_keepers { profile:*|*_PTT }]

#these registers are set long before they are used
#set_false_path -from [get_registers {network:network_inst|local_mac[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|local_ip[*]}] -to [all_registers]
set_false_path -from [get_registers {network:network_inst|arp:arp_inst|destination_mac[*]}] -to [all_registers]

############################################# LNA/ADC Control SPI ###############################################
#LNA/ADC SPI output pins
set_false_path -to [get_ports LNA_*]

################################################ Misc ########################################################
#1.2V regulator syncronization
set_false_path -to [get_ports SYNC]

#Phase detector output
set_false_path -to [get_ports PD_*]

#Internal reference enable
set_false_path -to [get_ports REF_EN]

#PHY MDC
set_false_path -to [get_ports {PHY_MDC PHY_MDIO}]
set_false_path -from [get_ports {PHY_MDIO}]
