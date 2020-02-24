# **How to use microUSB port on the AngeliaLite Mainboard**

There is a microUSB connector on the AngeliaLite Mainboard. It is connected to the board MCU (STM32F072) and is used to:
- Firmware flashing to the MCU
- Checking MAC/IP addresses 
- Seting IP address (and also to select DHCP/static IP)

## **Firmware flashing**
You can flash the MCU firmware using the ST DFU utilities for the STM32. Connect AngeliaLite Mainboard to the PC computer (using microUSB-USB cable), turn it on holding BOOT button, release BOOT button. The MCU will enter bootloader mode and you will be able to flash it.

## **Setting IP address**
By default AngeliaLite uses DHCP to obtain valid IP address or rolls back to APIPA address if it can not get IP address. You can program static IP address useing microUSB port on the AngeliaLite Mainboard.

Connect AngeliaLite Mainboard to the PC computer (using microUSB-USB cable), turn it on. A new communication port should be found by your PC. Connect to those port using terminal software (for example Putty), use default parameters.

After connection the following commands will be available:
| Command | Description |
|-------|-------|
|**H;** | Brief help message|
|**I;**|show IP address|
|**I aaa.bbb.ccc.ddd;**|set static IP address *aaa.bbb.ccc.ddd*|
|**I DHCP;**|obtain IP address from DHCP server or use APIPA|adress if DHCP fails
|**M;**|show MAC address|
|**V;**|show firmware version and serial number|

The changes will be effective after the board restarts