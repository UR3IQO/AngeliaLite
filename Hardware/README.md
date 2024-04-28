# SDRModule and AngeliaLite Mainboard
In this folder you can find SDR module and AngeliaLite Mainboard schematics.

# Assembly instructions
## AngeliaLite Mainboard v1.1
***Important!***

Do ***not install*** the following components:
- U10 (74LVC1G04)
- U13 (25AA02E48T)
- C37
- C43
- R13
- R15
- R18
- R50
- R59
- R32
- R35

***Install*** the following components: 
- R17 10 kOhm
- R33 0 Ohm
- R34 0 Ohm

## SDRModule v2.B
Do ***not install*** the following components:
- R35
- R72
- R75
- L23

Assemble the power supply circuits firstly and do a brief check. Proceed with the other components when you see the correct voltages supplyed by the regulators. This may save you some money and time ;)

# Troubleshooting

## Diagnostic LEDs on the Motherboard 
- **LED1** flash for ~0.2 second whenever the PHY receives (rgmii_rx_activ)
- **LED2** flash for ~0.2 second whenever the PHY transmits (rgmii_tx_active)
- **LED3** is not used
- **LED4** flash for ~0.2 seconds whenever traffic to the boards MAC address is received 
- **LED5** displays state of Ethernet PHY negotiations:
   - fast flash if no Ethernet connection
   - slow flash if 100T
   - swaps between fast and slow flash if not full duplex
- **LED6** displays state of DHCP negotiations:
   - on if success
   - slow flash if fail
   - fast flash if time out 
   - swap between fast and slow if using a static IP address
- **LED7** flash for ~0.2 seconds whenever udp_rx_active
- **LED8** (**STATUS**) flash if FPGA and MCU firmware are running and FPGA<->MCU SPI bus operates properly
