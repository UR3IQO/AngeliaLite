
/***********************************************************
*
*	Angelia
*
************************************************************/


//
//  HPSDR - High Performance Software Defined Radio
//
//  Angelia code. 
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

// (C) Phil Harman VK6APH/VK6PH, Kirk Weedman KD7IRS  2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015


/*
	2013 Dec 24 - Start coding 
					- remove log 
	2015 Jun 20 - First release with 4 receivers.  Number of receivers can be set using NR

	2015 Jun 21 - Changed to 7 receivers.
					- Changed version number to v9.2
				24 - replaced cdc_sync_strobe  with cdc_mcp.  2 Rx and Sync OK.
					- saved as today's date.
				27 - Sync not OK - force same phase word for both Rx. Add clock frequency and NR to Discovery reply
				   - Set NR = 2, Sync OK,  saved as today's date. 
					- Mod so that only Rx0 and Rx1 can be synced.  Independent phase words for both receivers.
					- All OK, saved as today's dat2 _2.
					- try 7 Rx - fails after a few seconds.
				   - replace Rx frequency with phase word from PC, 2 receivers.
				   - OK but Sync some times not work.
				   - save as today's data _phase_word.
				   - remove unnessary frequency to phase code
				   - enable Sync selection.
				   - All OK, save as today's date _phase_word_2	
					- try 4 receives, Sync not work, save as today's date _phase_word_3
					- try 7 receives,  Sync not work nor Rx3 ???
					- hold fifo clear until spd_rdy, 7 receivers OK but no Sync. Save as today's date _phase_word_4
					- unfold receivers. 7 receivers but Rx6 did fail and all will fail sometimes after deselecting Sync. 
				28 - Check Rx fifo is empty after Sync changes of status before continuing.
				   - NR = 2;
					- Connect fifo_clear to test LED to check that fifo is being reset.
					- works - saved as today's date.
					- replaced set_min_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK -4 with set_multicycle_path
					- works - saved as today's date _2 (and ping works!). 
				29 - Added items from Alex's network code to SDC file. Changed PHY delay to 1.2nS and updated sdc. 
				   - NR = 7, Receivers OK but not Sync.  Changed PHY delay back to 2nS. 
					- By forcing Rx1 phase word to Rx0 phase word then all receivers OK and Sync works. 
					- Try selecting Rx1 phase word dependent on Sync[0] setting. Runs but possible Sync problem.
		 Jul   2 - Revert to normal phase word selection. Receivers appear to work but not sure about Sync.
		         - Saved as today's date and sent to Warren etc for testing. 
				 3 - Warren reports that Rx1 and Rx5 seem to share the same frequency - confirmed - no idea why!  Unrolled Rx generation - no change.
				 4 - Unroll frequency selection in Hi Priority C&C, seems to have fixed the same frequency problem.
				   - Saved as today's date and sent to Kirk for assistance.
					- Code just stops running for some reason. 
				21 - Changed phy_cfg to turn off Tx delay and set Rx delay to F0 or C0 or 00 - all seem to work the same. 
				22 - Changed phy_cfg to use different Rx clock delays.
				   - Changed sdc to use different PHY data_in settings.  Checked 7 receivers appears OK, still not sure about Sync. 
					- Saved as today's date.
				23 - Changed KK so that each receiver can be set to different frequency. Works but some receivers fail when chip is cold.
					- Try unfolding Rx generation.  Appears to work OK, ping works for a few mins until FPGA warms up. 
					- Saved as today's date and sent to Warren for testing.
				25 - force same phase word to Rx0 and Rx1. Sync works but phase offset.  
				   - Force CORDIC reset when selecting Sync - no difference
					
					____________________________________________________________________________-
					
					- Two receiver version to speed up debug.
					- force Rx1 to use Rx0 phase word when in Sync mode - works OK.
					- force CIC reset when selecting sync - works OK.
					- force FIR reset when selecting sync - Rx hangs when Sync selected. 
					- independent phase words for Rx0 and Rx1 - not work
					- change High_Priority_CC so that Rx0 and Rx1 phase words are captured at the same time. Works until Rx1 is tuned.
					- when Sync active force Rx1 phase word to equal Rx0 phase word - wont run! see line 1038.
					- try setting Rx1 phase word  = Rx0 phase word  in High_Priority_CC when Sync active - no change
				26 - try reset CORDIC phase to zero when reset active. Works until you change frequency then need to set Sync again.
				   - remove reset code from High_Priority_CC  - same result.
					- remove reset from CIC filters - same result.
					- try just reseting CORDIC phase rather than other variables - same result.
					- use cdc_mcp to move receiver phase words to Rx clock domain - same result i.e. works until you change frequency.
					- use Sync to force Rx1 = Rx0 phase word - when you select Sync no Rx data sent?
					- force code to read phase at same time - using cdc_mcp - not work 
					- try using cdc_sync - works, can drag tune very slowly and phase preserved.
		         - set Rx1 = Rx0 phase word - code not run 
					- revert to separate Rx0 and Rx1 phase words. 
					- set Rx1 = Rx0 in High_Priority_CC - code runs but phase not work.
					- revert to separate Rx0 and Rx1 phase words.
				27 - Also reset CORDIC when new phase word arrives using Alex_data_ready - will not start.
					- Just use Alex_data_ready - Rx always at 0Hz, reasonable since as soon as new phase word is received it is set to zero. 
					- Move Alex_data_ready stobe to just before new Rx0 and Rx1 phase words.  Works most of the time but can tune such that phases are not correct.
					- Try Alex_data_ready directly after new Rx phases - works but blip in Rx audio as you tune not unexpectedly.
					- Try right at end - works OK. Sync does not hold after changing sampling rates.
				29 - Force Rx1 = Rx0 sample rate. Sync OK when changing sample rates.
				   - Force Rx1 = Rx0 sample rate from KK as well as Rx0 = Rx1 frequency.  Sync OK when changing sampling rate.
				   - Try setting Rx1 = Rx0 phase when Sync set again - remove reset of phase accumalator when frequency changes - WORKS!!!	
					- Saved as todays date. 
		  Aug  1 - Added Wideband_packets_per_frame.
				 2 - Sent to Warren for testing.
				 5 - Fixed bug in Wideband_packets_per_frame. Added Wideband_update_rate. Sync not work!  Was 70
				   - Try 60, 50 = OK, but not second time, 40.  Leave at 50. Try F0 = OK.
				 8 - modified ping check sum - not work and Rx0 not work. Ping error is due to incorrect data being received.
				 9 - modified ping code to use dual clock fifo and clock tx side on negedge. Ping works but not Sync.
				   - Try phy_config with E0. Sync works but not ping, last data element missing.
					- revert to F0 and posedge clock for Tx fifo. Review ping code later.
					- Use as basis of port to Hermes.
				29 - Saved as today's date.
				   - Imported changes from ANAN-10E code. Uses new Discovery protocol, namely:
							- Initial zero of unused C&C data
							- fix bug in C&C data relating to ADC overload
							- added openHPSDR Protocol version supported
							- modified CW so that MOX/PTT required if break-in not selected
							- changed Discovery reply to new protocol format
							- added hardware reset timer (but not enabled)	
							- added !run to sdr_send
					- Sync not work
					- Fixed DHCP bug reported by Hermes-Lite group.
					- Sync works but not after changing sampling rates. 
					- Remove for loop for Rx in sdr_send - no change
					- set Rx1 = Rx0 sampling rate when Sync selected. When in Sync mode can now change sampling rate.
				   - remove this set and still works
					- try resetting CORDIC when Sync changes state - no
					- try resetting CIC integrators - no
					- try increasing length of reset signal
					- try resetting CIC combs - no
					- try only rest when Sync goes 0 -> 1 - no
					- try more reset on CORDIC - no.
					- try using DEBUG_LED10 mono for long reset - no.
					- what works is to stop run, change speed on both receives, and run again. 
					- remove DEBUG_LED10. OK
					- remove CORDIC reset. OK
					- remove CIC int and combs. OK
					- remove try only rest when Sync goes 0 -> 1. OK
					- remove set Rx1 = Rx0 sampling rate when Sync selected. OK 
					- saved as today's date
				31	- Test 7 receivers
				   - Rx OK but not Sync. 
					- Unroll send_sdr. Rx 2 not work.					
		Sep    2 - High_Priority_CC mod to latch Rx frequency after it changes.
					- Rx2 not work.  Removed phase wire for Rx2.
				   - Works, saved as today's date. 
				 3 - High_Priority_CC output reg [31:0]Rx_frequency[0:NR-1] /* ramstyle = "logic" */  /* saved as today's date_1
				   - sdr_send.v input [7:0]Rx_data[0:NR-1] /* ramstyle = "logic" */  /* saved as today's date_2
					- Works. Sent as release to Doug, Warren and Joe. 
					- Saved as today's date.					
				 4 - Testing Alex data - set NR = 2.
				   - Change Alex data clock to CBCLK.
					- Modify Alex to update on change of data.
					- Works - saved as today's date.
				   - Set NR = 7.
				   - Redo timing - works.
				   - Save as today's date _2.	
		Oct    3 - Added new Erase code from Hermes.
               - Updated sdr_send.v to use latest erase and send_more replies.
					- not run with more than 4 receivers. Enabling 5th stops data being sent.
					- Saved as today's date. 
			    4 - Redo timing - works - saved as today's date.
			    5 - Fixed erase and program, change ASMI_interface back to use negedge.
			      - Redo timing - works - saved as today's date.
			   21 - Enabled deadman timer.
					- Saved as today's date.
					
					------------------------------------------------------------------
					
				31 - Test code for setting Rx levels.
					- NR = 2.
		Nov    2 - Increased gain of FIR by 12dB to match previous code.
					- Saved as today's date
					- NR = 7
					- Saved as today's date_2
				 4 - Test sending 16 bits to Rx1 as DAC feedback rather than 14. 
				   - removed 12dB gain in FIR
				 6 - Truncated Tx CIC output. 
				 7 - Added 12dB Rx gain in FIR.
				   - Set DAC feedback to 16 bits. CORDIC was set to 16 bits but only 15 used - fixed. Signals jump - try NR = 2.
					- NR = 2;
				 8 - Redo timing to give clean 16 bit feedback. 
				   - 16 bit feedback shows lots of low level spurs on Rx1 feedback.
					- Built both 14 and 16 bit versions and sent to Warren.
					- This is 14 bit version
					- saved as today's date
				14 - Testing 16 bit feedback
				   - 17 bit Tx chain, 14 bits to DAC, 16 bits to DAC feeback Rx.
					- Using top 14 bits of Tx data for DAC. Can now get full power out. 
				16 - Added 15 phase shift to DAC clock as per current Angelia code.
			      - Added phase shifted clock to sdc file and redo timing.	
				19 - If send 16bits of DAC data then when FPGA warms up noise floor gets high.
				   - Just sending 14 DAC bits.
					- Sent to Warren for testing.
					- Saved as today's date.
				22 - NR = 7 not run, need to turn hardware reset off. 
				   - OK now. 
					- Saved as today's date, sent to Warren for testing.
				27 - Added hardware resets to C&C code.
				   - Corrected reset from Tx_specific_CC.
					- Hardware timer still not correct.
					- Saved as today's date.
				28 - Try different hardware timer.
					- works using slow reset signals.
				   - Modify Tx_specific_data ready code.
					- redo timing.
					- OK now.
					- Prevent Discovery reply if already running - in sdr_send.v
					- Breaks DAC feedback signal - try redo timing.
					- OK now - sent to John and Warren for testing.
					- Moved open collectors to match V2.2.
					- not compliled - saved as today's date.
		  Dec  4 - Fixed bug that caused Mic PTT to latch .PTT in data to CC_Encoder
					- redo timing.
					- OK - saved as today's date and sent to John and Warren for testing.
				 5 - Test code for Discovery bug - NR = 2
				   - Set Discovery reply to 60 bytes - sdr_send.v modified
					- Set Protcol version to v2.2
					- No bug found, PC should not try and connect if Discovery reply indicates busy.
					- Changed code so that Discovery can be sent to either broadcast or hardware's IP address. 
					- NR = 7.
					- OK - saved as today's date and sent for testing.
				 6 - NR = 2.
				   - Testing hardware reset code.
				   - Increase timer to 2 seconds and use data_ready* to reset.
					- Remove broadcast test 255.255.255.255 in ip_recv.v from line 17.
					- Unreliable - use HW_reset* instead.
					- redo timing
					- NR = 7.
				 7	- OK - saved as today's date and sent for testing.
				 9 - The following changes prevent the HW restarting after a time out by issuing a Discovery command.
					  Requires a run command to restart. 
							Prevent HW timer reseting if not General_CC data, line 109. 
							Add HW_timeout to High_Priority_CC so that run is cleared on HW timeout, line 127
							Modify HW timer to give HW_timeout, lines 460-467.
							Replace run_set with run.
				10 - OK - saved as today's date and sent to John for testing.
				   - Only send Exciter, FWD & REV power when PTT active
				19 - Set protocol to V2.3
				   - Tidy Tx code comments relating to use of 22 bits from CORDIC now.
					- Match Tune and CW power out levels since change to 22 bits. 
					- NR = 2
					- new profile.mif table and added 'raised cosine profile.xls' to files
					- attenuate sidetone level, see line 1090
				   - NR = 7.	
					- OK - saved as today's date and released.
				20 - Corrected Mic and wideband data - swapped bytes
					- Saved as today's date and released.
	2016 Jan 17 - Added Tx_IQ_fifo almost_full, almost_empty.
					- Clear TR relay and Open Collectors if run not active.
					- Saved as today's date and released.
				18 - Added AIN4 user analog input.
				   - Added IO4 user digital input.
				20 - Redo timing. No output or sequence errors.
				22 - Remove set max and min delays from Angelia.sdc - runs OK  
				   - Saved as today's date. Release for testing.
				23 - modified Tx DACD clock to use 30 deg phase shift instead of 15 degrees 
					- modified deadman timer code to cure occasional-halt behavior
					- modified .sdc timing constraint file to achieve timing closure
					- Saved as today's date.  Released for testing.  					
				30 - removed references to Mercury in Angelia.qsf
					- added TX INHIBIT using IO4
					- added IO5 external CW keying feature for ext amp autotune support in iambic CW mode, using debounced IO5, 
						changes in Angelia.v and iambic.v
					- set all dual purpose pins to "use as regular IO" in Assignments > Device... > Device and Pin Options
					- changed blocking assignments ( = ) to unblocking assignments ( <= ) in all always and generate 
						blocks unless used in "assign" statements
					- changed x++ occurances to x <= x + 1 in always and generate blocks because ++ is a blocking operation
					- set deadman timer to 2 seconds interval
					- fixed sequence number output bugs for CC_seqnumber and spec_seq_number to send upper 8 bits of seq numbers
						correctly in sdr_send.v
			   31 - removed C122_PLL output c1 for phase shifted TX DAC data clock, created timing for TX DAC data and TX DAC
						as a set_output_delay constraint instead in Angelia.sdc
					- added max and min delays into Angelia.sdc to achieve timing closure
					- changed protocol_version number to v2.6
					- saved as today's date, changed version number to 10.2					

			
					**** IMPORTANT: Prevent Quartus merging PLLs! *****

	3 FEB 2016 - TRIAL TIMING APPROACH: SIMPLIFIED PHY IO CONSTRAINTS
				  - modified Angelia.sdc PHY-related "set_input_delay" and "set_output_delay" constraints,
					 including changing to a single constraint for PHY_RX with setup/hold delays of zero (i.e., identical 
					 setup and hold delay of zero but it nevertheless works!).  Set DACD[*] setup/hold delays to 0.2 nSec and 
					 PHY_TX setup/hold delays to 0.2 nSec, removed all existing "set_max_delay" and "set_min_delay" contstraints, 
					 compiled, then re-timed failing paths using only set_max_delay and set_min_delay constraints.
					 
		 Feb  6 - Added revised polyphase FIR, uses less RAM and ROM. 
			     - Fixed a number of compiler warnings. 
				  - Redo timing - all appears OK, released for testing.
		     18 - Modified timer hardware reset signals so that a reset signal can't stay high if Network lost
			     - Timing not closed.  Released as todays date for testing. 
				  
				  - re-instated input and output delays of 19Dec version for PHY timing on leading and trailing edges of clock,
					 set TX DAC data output delay to 0.8 nSec
				  - closed timing
			  19 - saved as today's date and released for testing
			  20 - Added hardware timer enable
					 Saved as today's date and released for testing. 
			  24 - Testing different sdc file. 
			  25 - Closed timing - works OK. Saved as today's date. 
		Mar   4 - New sdc file. 
			     - Saved as today's date - DAC feedback fails when hot
				7 - Try Tx PLL using source sync compensation for C0 output. 
			     - Try _122_90 to clock DAC data into Rx.
				  - Seems OK - saved as today's date and released for testing.
		Apr  24 - Testing Altera suggestions i.e. PHY_TX[*] instead of PHY_TX*
				  - Saved as today's date and released for testing.
	   Aug  29 - Change Mic data to have 64 samples (128 bytes) and Rx audio to have 64 samples (256 bytes)
					 Mic data - see Angelia.v line 886 and sdr_send line 397
				    Rx audio - see byte_to_32bits line 106.
					 Sent to Warren for testing.
		Sep   3 - Corrected Rx audio to be 64 samples
		          Sent to Warren for testing.
			  19 - Moved Wideband data to after DDC data so have lower priority.	
					 Sent to Warren for testing.
			  21 - Now send WB data after all DDC data has been sent. 
					 Sent to Warren for testing.
		Oct   7 - Change NR = 4
		Oct  17 - Modified Mux_clear to fix PureSignal switching issues.
		        - Moved phy_ready to C122 clock domain		
				  - Sent to Warren for testing.
				  - Basically OK but high noise floor on DAC feedback Rx on Warren's board.
			  19 - redo timing closure. 
			     - Sent to Warren for testing. Even high DAC noise floor.
				  - Saved as today's date.
			  21 - Fed Rx1 DAC data without 90 phase shift (used DAC)
			       Still high DAC noise floor when FPGA cold. 
				  - try latch DAC data when RF data available - NBG
				  - don't wait for DAC DDC to be ready - OK when hot, check when cold.
				  - when cold high DAC DDC noise floor.
			  22 - redo timing closure.
			     - check that Rx0 fifo is empty when PureSignal starts 
				  - works OK cold and hot starts
				  - sent to Warren for testing, works OK for him also.
				  - saved as today's date.
			  30 - fixed sequence number error in mic data - see sdr_send.v line 412.
			     - released for testing
				  - saved as today's date.
		Dec  12 - Modified FIR to use 4 ROMs for testing.
		     15 - Incorporate Hermes-Lite mods for DHCP and ICMP files change are network.v, dhcp.v, ip_recv.v, icmp.v & icmp_fifo.v.
					 Saved as today's date. 
					 
2017 	Jan 13 	- moved to Quartus Prime Lite v16.0 
					- regenerated anew all megafunctions in the Angelia design, using v16.0 megafunctions 
					- removed max/min delay constraints in the Angelia.sdc for a fresh timing procedure
					- moved tx_pll/.c4 to tx_pll/.c3 in rgmii_send_inst.v
					- changed version number to 10.3
					- compiled
					- constrained all unconstrained paths										
					- closded timing
					- moved from 80KHz XOR operation to 10MHz operations
					- removed C10_PLL megafunction from the project
					- changed C122_PLL/.c0 to 10MHz
					- removed C122_PLL/.c1
					- added PLL_IF/.c3 (_122_90)
					- changed phase shift for PLL_IF/.c1 to 90 degrees to cure an Rx audio problem
					- changed phase shift for PLL_IF/.c3 to 90 degrees
		  Jan 17 - hard coded inputs for the receiver modules as follows, except DDC1 input is switched between TxDAC
						(temp_DACD) on tx and temp_ADC[1] on rx:
							temp_ADC[0] -> DDC0 
							temp_DACD (tx) or temp_ADC[1] (rx)	-> DDC1
							temp_ADC[0] -> DDC2
							temp_ADC[1] -> DDC3
					- removed code referencing input switching options for the receiver modules
					- changed phase shift for PLL_IF/.c3 to 180 degrees
				   - changed version number to v10.4
					- closed timing
		Jan 26	- changed temp_DACD code to mimic Angelia_v5.5 temp_DACD code
					- changed PLL_IF/.c3 constraint in Angelia.sdc to reflect actual clock for DACD[*]
					- set PLL_IF/.c3 to 18 degrees phase shift					
					- changed version number to 10.5
		Feb  3   - Added DHCP Renewal code changes
					- Redo timing
					- changed version number to 10.6
			  4   - Saved as today's date
			      - Added Hermes-Lite fix to ping (icmp.v line 206)
					- Redo timing
					- Saved as Angelia_NP_v10.6.qar
					- Released for testing.
			  6	- removed debounce_PTT as input from FPGA_PTT assignment		
			  8 	- changed name of _122_90 clock to DACD_clock
					- moved temp_DACD assignment out of the C122_clk always block
					- changed to use DACD_clock for temp_DACD assignment
					- changed the ref clock for DACD[*] output_delay constraint in Angelia.sdc to _77_76MHz
					- changed version number to v10.7
					- changed PLL_IF/.c3 (DACD_clock) 122.88 MHz phase shift to 11.25 degrees
					- removed all max/min delay constraints in Angelia.sdc, compiled
					- closed timing, compiled
					- fixed frequency assignments for DDC0 and DDC1 (were temporarily assigned to Tx freq for testing)
					- changed version number to v10.8
					- changed the ref clock for DACD[*] output_delay constraint in Angelia.sdc to DACD_clock
					- removed all max/min delay constraints in Angelia.sdc, compiled
					- retimed, compiled
			  10  - re-instated software-slectable ADC/DDC assignments
					- set PLL_IF/.c3 phase shift to 15 degrees
					- changed the version number to v10.9
					- removed all max/min delay constraint in Angelia.sdc, compiled
					- re-timed, compiled iteratively until timing met
			  13  - added an additional bit to the Rx_fifo meagfunction by checking box for 
							"Add an extra MSB to usedw port(s)" option, i.e., use 12-bit variables: 
							wire [11:0] Rx_used[0:NR-1] vs previous 11-bit variables, to prevent halt 
							of Rx IQ data that occurred in previous versions when the Rx fifo became full
					- changed version number to v11.0
					- changed protocol version number to v3.3
					- removed all max/min delay constraints in Angelia.sdc file, compiled
					- retimed/recompiled iteratively until timing closed
				15 - modified the following additional FIFO megafunctions by selecting the 
						"Add an extra MSB to usedw port(s)" option:
							EPCS_fifo (increased used word sizes to [10:0]EPCS_Rx_used, [10:0]EPCS_wrused)
							Mic_fifo (already using it)
							Rx_fifo (increased used word sizes to [11:0] Rx_used[0:NR-1])
							Rx_Audio_fifo (already using it)
							SP_fifo (already using it)
							Tx1_IQ_fifo (increased used word size to [12:0]write_used)
							icmp_fifo (usedw output not used)
					- removed PLL_IF/.c3 output
					- changed DACD ref clock to negedge _77_76MHz
					- changed temp_DACD ref clock to C122_clk
					- changed version number to v11.1
					- removed all max/min delay constraints in Angelis.sdc file, compiled
					- retimed/recompiled iteratively until timing was closed
					
		Mar 7		- changed almost_full and almost_empty code for Tx1_IQ_fifo to fix sporadic Tx halts
					- added PLL_IF/.c3, 122.88 MHz with 11.25 degree phase shift
					- changed ref clock for temp_DACD and DACD to PLL_IF/.c3 (DACD_clock)
					- changed version number to v11.3 (skipped v11.2 which was done in Quartus Prime Lite v16.1)
					- changed Angelia.sdc to specify DACD_clock for DACD[*] path constraints
					- removed all max/min delay constraints in Angelia.sdc
					- retimed/recompiled iteratively until timing closed
	   Mar 17   - added a one-spi-clock delay to SPI.v code when the Alex_SPI_Tx data word changes
						to allow the data word to become stable before sending it to the bus
					- changed PLL_IF/.c3 phase shift to 15.0 degrees
					- changed FW version to v11.4
					- removed all max/min delay constraints from Orion.sdc
					- retimed/compiled iteratively until timing closed
					
					- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		Mar 18	- ported design to Quartus Prime Lite v16.1
					- updated all megafunctions to v16.1 megafunctions
					- removed one-spi-clock delay code in SPI.v
					- modified SPI.v to send the Alex data word twice each time the data word changes
					- changed FW version to 11.5
					- removed all max/min delay constraints from Orion.sdc
					- retimed/compiled iteratively until timing closed
					
		Apr 23	- implemented peak detection for AIN1 and AIN2:
								-created userADC_clk, 30.72MHz clock for Angelia_ADC.v which provides a 7.68MHz clock to 
									the ADC78H90 chip, increasing its previous sampling rate x10
								-replaced Angelia_ADC.v with version from Orion_MkII_v1.6 firmware
								-replaced CC_encoder.v with version from Orion_MkII_NP_v1.2 firmware
								- replaced Ethernet/sdr_send.v with version from Orion_MkII_NP_v1.2
								-added pk_detect_reset and pk_detect_ack to Angelia.v
								-added user_analog1 and user_analog2 (deleted user_analog) to Orion.v
					- added debounce_PTT to FPGA_PTT to fix bug with external PTT IN via pin13 on ANAN-100D accessory jack
					- added userADC_clk as a 30.72MHz generated clock to Angelia.sdc
					- changed PHY Rx clock skew settings values[6] = 16'h70FF (from 16'hF0FF)
					- changed FW version number to v11.6
					- removed all max/min delay constraints from Orion.sdc
					- retimed/compiled iteratively until timing closed
					
		 May 20  - recompiled using Quartus V17.0. Auto update of all Megafunctions.
					- replaced max clock delays for RX_clock with mulitpath
			  21  - used icmp.v and icmp_fifo.v from Hermes-Lite project. Ping sometimes works, when fails payload is wrong. 
			      - updated dhcp.v from Hermes-Lite project. Works OK. 
2018	Feb  10  - Merged files from Hermes-Lite project and those provided by Rick, N1GP.
				   - Fixed bug that caused non response to Discovery request.
				   - retimed	
					- set version to 11.7
					- Archived project as Angelia_Protocol_2_v11.7-Quartus-17
					- removed almost_full and almost_empty flags since no longer required by Simon, G4ELI, SDR-Radio software
					- corrected text explaining external 10MHz reference operation
					- released as 11.7 and archived as before. 
		Mar    3 - set Rx1 input = DAC data for Thetis debug testing
		         - // Remove ability for other than Rx1 to receive DAC data since not supported by other HW at the moment.
					- Modified sdr_send so that phy_ready requires no pending data from Rx0 fifo.
				   - Rx1 now has input data selectable again.
				   - Added Samplerate input to mux_clear to reset code if sample rate changes 
					- modified mux_clear such that either Mux or SampleRate changing state runs code. 
					- Remove ability for other than Rx1 to receive DAC data since not supported by other HW at the moment.
				 4 - Remove fifo_empty from mux_clear since can hang in that state otherwise. 
				   - Added mux_clear fifo_clear output to reset DDC0 and DDC1 - no improvement.
				 7 - Testing Diverstity - set DEBUG_LED10 = C122_SyncRx[0][1] to confirm signal from Thetis - looks OK. 
				10 - Force DDC0 and DDC1 to have same sampling rate when Mux active
			      - set DEBUG_LED10 to indicate amplitude difference between DDC0 and DDC1 when in Mux mode.	

2018 April  - changed to use in AngeliaLite by Oleg Skydan UR3IQO
				 
*/

module Angelia(
  //clock PLL
  input M_CLK,              //155.52MHz from VCXO
  input  REF_CLK,             //10MHz reference in 
  output REF_EN,
  
  //VCXO contol voltage
  output PD_POL, //Polarity
  output PD_EN,  //Enable

  //DGA/ADC SPI control
  output LNA_DATA,
  output LNA_CLK,
  output LNA_LOAD,

  //rx adc (AD9255)
  input  [13:0]ADC1,              //samples from AD9255
  input  [13:0]ADC2,            //samples from AD9255 #2
  input  ADC1_CLK,         //77.76MHz from ADC1_CLK pin 
  input  ADC2_CLK,       //77.76MHz from #2 ADC1_CLK pin 
  input  ADC1_OVF,               //high indicates AD9255 have overflow
  input  ADC2_OVF,             //high indicates AD9255 have overflow

  //tx adc (AD9744)
  //output reg  DAC_ALC,          //sets Tx DAC output level
  output reg signed [13:0] DAC,  //Tx DAC data bus
    
  //phy rmii (LAN8720A)
  input PHY_CLK50,              //PHY 50MHz clock
  output [1:0] PHY_TX,
  output PHY_TX_EN,              //PHY Tx enable
  input  [1:0] PHY_RX,     
  input  PHY_CRS,                 //PHY has data flag
  
	//phy mdio (LAN8720)
	inout  PHY_MDIO,               //data line to PHY MDIO
	output PHY_MDC,                //2.5MHz clock to PHY MDIO

   //MB MCU SPI interface
   input MCU_CLK,                  
   input MCU_MOSI,                   
   output MCU_MISO,                   
   input MCU_MAC_LOAD,
   input MCU_LOAD,


	//eeprom (25AA02E48T-I/OT)
	// output 	SCK, 							// clock on MAC EEPROM
	// output 	SI,							// serial in on MAC EEPROM
	// input   	SO, 							// SO on MAC EEPROM
	// output  	CS,							// CS on MAC EEPROM
	
  //eeprom (M25P16VMW6G)  
//  output NCONFIG,                //when high causes FPGA to reload from eeprom EPCS16	
  
//   //12 bit adc's (ADC78H90CIMT)
//   output ADCMOSI,                
//   output ADCCLK,
//   input  ADCMISO,
//   output nADCCS, 
 
  //alex/apollo spi
//   output SPI_SDO,                //SPI data to Alex or Apollo 
// //  input  SPI_SDI,                //SPI data from Apollo 
//   output SPI_SCK,                //SPI clock to Alex or Apollo 
//   output J15_5,                  //SPI Rx data load strobe to Alex / Apollo enable
//   output J15_6,                  //SPI Tx data load strobe to Alex / Apollo ~reset 
  
  //misc. i/o
  input  PTT,                    //PTT active low
  input  KEY_DOT,                //dot input from J11
  input  KEY_DASH,               //dash input from J11
  output FPGA_PTT,               //high turns Q4 on for PTTOUT
  
  //DC-DC synchronization
  output SYNC

  //audio codec (TLV320AIC23B)
  //output CBCLK,               
  //output CLRCLK, 
  //output CDIN,                   //Speaker/phones data to TLV320
  //output CMCLK,                  //Master Clock to TLV320 
  //output CMODE,                  //sets TLV320 mode - I2C or SPI
  //output nCS,                    //chip select on TLV320
  //output MOSI,                   //SPI data for TLV320
  //output SSCK,                   //SPI clock for TLV320
  //input  CDOUT                  //Mic data from TLV320  


//   //user digital inputs
//   input  IO4,                    
//   input  IO5,
//   input  IO6,
//   input  IO8,
  
//   //user outputs
//   output USEROUT0,               
//   output USEROUT1,
//   output USEROUT2,
//   output USEROUT3,
//   output USEROUT4,
//   output USEROUT5,
//   output USEROUT6,
  
//     //debug led's
//   output Status_LED,      
//   output DEBUG_LED1,             
//   output DEBUG_LED2,
//   output DEBUG_LED3,
//   output DEBUG_LED4,
//   output DEBUG_LED5,
//   output DEBUG_LED6,
//   output DEBUG_LED7,
//   output DEBUG_LED8,
//   output DEBUG_LED9,
//   output DEBUG_LED10,

      // output S144,
      // output S143,
      // output S142,
      // output S141
      // output S133,
      // output S132,
      // output S125
  
);


reg [13:0] DACD;
assign DAC = DACD;

wire IO5;

assign IO5 = 1'b1;


assign SHDN = 1'b0;				   		// normal LTC2208 operation
assign SHDN_2 = 1'b0;

//debug led's
wire Status_LED;      
wire DEBUG_LED1;             
wire DEBUG_LED2;
wire DEBUG_LED3;
wire DEBUG_LED4;
wire DEBUG_LED5;
wire DEBUG_LED6;
wire DEBUG_LED7;
wire DEBUG_LED8;
wire DEBUG_LED9;
wire DEBUG_LED10;


assign NCONFIG = IP_write_done || reset_FPGA;

wire speed = 1'b0; // high for 1000T
// enable AF Amp
assign  IO1 = 1'b0;  						// low to enable, high to mute

localparam NR = 4; 							// number of receivers to implement
localparam master_clock = 77760000; 	// DSP  master clock in Hz.

parameter M_TPD   = 4;
parameter IF_TPD  = 2;

localparam board_type = 8'h04;		  	// 0x00 = Metis, 0x01 = Hermes, 0x02 = Griffin, 0x04 = Angelia, 0x05 = Orion
parameter  Angelia_version = 8'd117;	// FPGA code version
parameter  protocol_version = 8'd37;	// openHPSDR protocol version implemented

wire _77_76MHz;

//--------------------------------------------------------------
// Reset Lines - C122_rst, IF_rst, SPI_Alex_reset
//--------------------------------------------------------------

wire  IF_rst;
wire SPI_Alex_rst;
wire C122_rst;
wire C155_rst;
wire SPI_clk;
	
assign IF_rst = network_state;  // hold code in reset until Ethernet code is running.


// transfer IF_rst to 122.88MHz clock domain to generate C122_rst
cdc_sync #(1)
	reset_C122 (.siga(IF_rst), .rstb(0), .clkb(_77_76MHz), .sigb(C122_rst)); // 122.88MHz clock domain reset

cdc_sync #(1)
	reset_C155 (.siga(IF_rst), .rstb(0), .clkb(_155_52MHz), .sigb(C155_rst)); // 122.88MHz clock domain reset

cdc_sync #(1)
	reset_Alex (.siga(IF_rst), .rstb(0), .clkb(SPI_clk), .sigb(SPI_Alex_rst));  // SPI_clk domain reset
	
// Deadman timer - clears run if HW_timer_enable and no C&C commands received for ~2 seconds.

wire timer_reset = (HW_reset1 | HW_reset2 | HW_reset3 | HW_reset4);

reg [27:0] sec_count;
wire HW_timeout;
always @ (posedge rx_clock)
begin
	if (HW_timer_enable) begin
		if (timer_reset) sec_count <= 28'b0;
		else if (sec_count < 28'd155_520_000) 	// approx 2 secs. 
			sec_count <= sec_count + 28'b1;
	end
	else sec_count <= 28'd0;
end

 assign HW_timeout = (sec_count >= 28'd155_520_000) ? 1'd1 : 1'd0;   



//---------------------------------------------------------
//		CLOCKS
//---------------------------------------------------------

wire C122_clk; 
wire C122_clk_2;
assign C122_clk = _77_76MHz;
assign C122_clk_2 = _77_76MHz;

//wire CLRCLK;
//assign CLRCIN  = CLRCLK;
//assign CLRCOUT = CLRCLK;


wire 	IF_locked;
wire C122_cbrise;
wire DACD_clock;
wire M_CLK_PLL;

// Generate CMCLK (12.288MHz), CBCLK(3.072MHz), CLRCLK (48kHz) for CODEC 
// NOTE: CBCLK is generated at 180 degress so that LRCLK occurs on negative edge of BCLK 
PLL_C PLL_C_inst (.inclk0(M_CLK), .c0(CMCLK), .c1(CBCLK), .c2(CLRCLK), .locked());

pulsegen pulse  (.sig(CBCLK), .rst(IF_rst), .clk(!CMCLK), .pulse(C122_cbrise));  // pulse on rising edge of BCLK for Rx/Tx frequency calculations


//Generate _77_76MHz clock from the ADC clock
PLL_IF PLL_IF_inst (.inclk0(ADC1_CLK), .c3(_77_76MHz), .locked(IF_locked));

// Generate 155.52MHz clock for transmitter (M_CLK_PLL), 1. for DC-DC syncronization (SYNC)
// and clock enable for SPI LNA/ADC control interface
wire M_SPI_EN;

PLL PLL_main (.inclk0(M_CLK),	.c0(M_CLK_PLL), /*.c1(M_SPI_EN), .c2(SYNC),*/ .c3(DACD_clock), .locked());

assign SYNC = 1'b0;
//-----------------------------------------------------------------------------
//                           network module
//-----------------------------------------------------------------------------


wire network_state;
wire speed_1Gbit;
wire clock_25MHz;
wire clock_12_5MHz;
wire clock_2_5MHz;
wire [7:0] network_status;
wire rx_clock;
wire tx_clock;
wire udp_rx_active;
wire [7:0] udp_rx_data;
wire udp_tx_active;
wire [47:0] local_mac;	
wire broadcast;
wire [15:0] udp_tx_length;
wire [7:0] udp_tx_data;
wire udp_tx_request;
wire udp_tx_enable;
wire set_ip;
wire IP_write_done;	
wire static_ip_assigned;
wire dhcp_timeout;
wire dhcp_success;
wire dhcp_failed;
wire icmp_rx_enable;
	


network network_inst (

	// inputs
  .speed(speed),	
  .udp_tx_request(udp_tx_request),
  .udp_tx_data(udp_tx_data),  
  .set_ip(set_ip),
  .assign_ip(assign_ip),
  .port_ID(port_ID), 
  

  // outputs
  .clock_25MHz(clock_25MHz),
  .clock_12_5MHz(clock_12_5MHz),
  .clock_2_5MHz(clock_2_5MHz),
  .rx_clock(rx_clock),
  .tx_clock(tx_clock),
  .broadcast(broadcast),
  .udp_rx_active(udp_rx_active),
  .udp_rx_data(udp_rx_data),
  .udp_tx_length(udp_tx_length),
  .udp_tx_active(udp_tx_active),
  .local_mac(local_mac),
  .udp_tx_enable(udp_tx_enable), 
  .IP_write_done(IP_write_done),
  .icmp_rx_enable(icmp_rx_enable),   // test for ping bug
  .to_port(to_port),   					// UDP port the PC is sending to

	// status outputs
  .speed_1Gbit(speed_1Gbit),	
  .network_state(network_state),	
  .network_status(network_status),
  .static_ip_assigned(static_ip_assigned),
  .dhcp_timeout(dhcp_timeout),
  .dhcp_success(dhcp_success),
  .dhcp_failed(dhcp_failed),  

  //make hardware pins available inside this module
  .MODE2(1'b1),
  .PHY_TX(PHY_TX),
  .PHY_TX_EN(PHY_TX_EN),            
  .PHY_RX(PHY_RX),     
  .PHY_CRS(PHY_CRS),    					// use PHY_CRS to be consistent with Metis            
  .PHY_CLK50(PHY_CLK50),           
  .PHY_MDIO(PHY_MDIO),             
  .PHY_MDC(PHY_MDC),

   .MCU_CLK(MCU_CLK),                  
   .MCU_MOSI(MCU_MOSI),                   
   .MCU_MAC_LOAD(MCU_MAC_LOAD)
  );


//-----------------------------------------------------------------------------
//                          sdr receive
//-----------------------------------------------------------------------------
wire sending_sync;
wire discovery_reply;
wire pc_send;
wire debug;
wire seq_error;
wire erase_ACK;
wire EPCS_FIFO_enable;
wire erase;	
wire send_more;
wire send_more_ACK;
wire set_up;
wire [31:0] assign_ip;
wire [15:0]to_port;
wire [31:0] PC_seq_number;				// sequence number sent by PC when programming
wire discovery_ACK;
wire discovery_ACK_sync;


sdr_receive sdr_receive_inst(
	//inputs 
	.rx_clock(rx_clock),
	.udp_rx_data(udp_rx_data),
	.udp_rx_active(udp_rx_active),
	.sending_sync(sending_sync),
	.broadcast(broadcast),
	.erase_ACK(busy),						// set when erase is in progress
	.EPCS_wrused(EPCS_wrused),
	.local_mac(local_mac),
	.to_port(to_port),
	.discovery_ACK(discovery_ACK_sync),	// set when discovery reply request received by sdr_send
	
	//outputs
	.discovery_reply(discovery_reply),
	.seq_error(seq_error),
	.erase(erase),
	.num_blocks(num_blocks),
	.EPCS_FIFO_enable(EPCS_FIFO_enable),
	.set_ip(set_ip),
	.assign_ip(assign_ip),
	.sequence_number(PC_seq_number)
	);
			        


//-----------------------------------------------------------------------------
//                               sdr rx, tx & IF clock domain transfers
//-----------------------------------------------------------------------------
wire run_sync;
wire wideband_sync;
wire discovery_reply_sync;

// transfer tx clock domain signals to rx clock domain
//sync sync_inst1(.clock(rx_clock), .sig_in(udp_tx_active), .sig_out(sending_sync));   
assign sending_sync = udp_tx_active;
//sync sync_inst2(.clock(rx_clock), .sig_in(discovery_ACK), .sig_out(discovery_ACK_sync));
assign discovery_ACK_sync = discovery_ACK;

// transfer rx clock domain signals to tx clock domain  
//sync sync_inst5(.clock(tx_clock), .sig_in(discovery_reply), .sig_out(discovery_reply_sync)); 
assign discovery_reply_sync = discovery_reply;
//sync sync_inst6(.clock(tx_clock), .sig_in(run), .sig_out(run_sync)); 
assign run_sync = run;
//sync sync_inst7(.clock(tx_clock), .sig_in(wideband), .sig_out(wideband_sync));
assign wideband_sync = wideband;

//-----------------------------------------------------------------------------
//                          sdr send
//-----------------------------------------------------------------------------

wire [7:0] port_ID;
wire [7:0]Mic_data;
wire mic_fifo_rdreq;
wire [7:0]Rx_data[0:NR-1];
wire fifo_ready[0:NR-1];
wire fifo_rdreq[0:NR-1];

sdr_send #(board_type, NR, master_clock, protocol_version) sdr_send_inst(
	//inputs
	.tx_clock(tx_clock),
	.udp_tx_active(udp_tx_active),
	.discovery(discovery_reply_sync),
	.run(run_sync),       
	.wideband(wideband_sync),
	.sp_data_ready(sp_data_ready),
	.sp_fifo_rddata(sp_fifo_rddata),		// **** why the odd name - use spectrum_data ?
	.local_mac(local_mac),
	.code_version(Angelia_version),
	.Rx_data(Rx_data),						// Rx I&Q data to send to PHY
	.udp_tx_enable(udp_tx_enable),
	.erase_done(erase_done | erase),    // send ACK when erase command received and when erase complete
	.send_more(send_more),
	.Mic_data(Mic_data),						// mic data to send to PHY
	.fifo_ready(fifo_ready),				// data available in Rx fifo
	.mic_fifo_ready(mic_fifo_ready),		// data avaiable in mic fifo
	.CC_data_ready(CC_data_ready),      // C&C data availble 
	.CC_data(CC_data),
	.sequence_number(PC_seq_number),		// sequence number to send when programming and requesting more data
	.samples_per_frame(samples_per_frame),
	.tx_length(tx_length),
	.Wideband_packets_per_frame(Wideband_packets_per_frame),  
	
	//outputs
	.udp_tx_data(udp_tx_data),
	.udp_tx_length(udp_tx_length),
	.udp_tx_request(udp_tx_request),
	.fifo_rdreq(fifo_rdreq),				// high to indicate read from Rx fifo required
	.sp_fifo_rdreq	(sp_fifo_rdreq	),		// high to indicate read from spectrum fifo required
	.erase_done_ACK(erase_done_ACK),		
   .send_more_ACK(send_more_ACK),
	.port_ID(port_ID),
	.mic_fifo_rdreq(mic_fifo_rdreq),		// high to indicate read from mic fifo required
	.CC_ack(CC_ack),							// ack to CC_encoder that send request received
	.WB_ack(WB_ack),							// ack to WB controller that send request received	
	.phy_ready(phy_ready),					// set when PHY is not sending DDC data
	.discovery_ACK(discovery_ACK) 		// set to acknowlege discovery reply received
	 ); 		

//---------------------------------------------------------
// 		Set up TLV320 using SPI 
//---------------------------------------------------------


//TLV320_SPI TLV (.clk(CMCLK), .CMODE(CMODE), .nCS(nCS), .MOSI(MOSI), .SSCK(SSCK), .boost(Mic_boost), .line(Line_In), .line_in_gain(Line_In_Gain));

//-------------------------------------------------------------------------
//			Determine number of I&Q samples per frame when in Sync or Mux mode
//-------------------------------------------------------------------------

reg [15:0] samples_per_frame[0:NR-1] ;
reg [15:0] tx_length[0:NR-1];				// calculate length of Tx packet here rather than do it at high speed in the Ethernet code. 

generate
genvar j;

for (j = 0 ; j < NR; j++)
	begin:q

		always @ (*)
		begin 
			samples_per_frame[j] <= 16'd238;
			tx_length[j] <= 16'd1444;
	   end 
	end

endgenerate


//------------------------------------------------------------------------
//   Rx(n)_fifo  (2k Bytes) Dual clock FIFO - Altera Megafunction (dcfifo)
//------------------------------------------------------------------------

/*
	  
						   +-------------------+
     Rx(n)_fifo_data	|data[7:0]		wrful| Rx(n)_fifo_full
						   |				        |
	  Rx(n)_fifo_wreq	|wreq		           | 
						   |					     |
		     C122_clk	|>wrclk	wrused[9:0]| 
						   +-------------------+
     fifo_rdreq[n]	|rdreq		  q[7:0]| Rx_data[n]
						   |					     |
	     tx_clock		|>rdclk		rdempty | Rx_fifo_empty[n]
		               |                   |
						   |		 rdusedw[10:0]| Rx(n)_used  (0 to 2047 bytes)
						   +-------------------+
						   |                   |
   Rx_fifo_clr[n] OR |aclr               |
	 IF_rst	OR !run	+-------------------+
	 OR fifo_clear
		
    

*/

wire 			Rx_fifo_wreq[0:NR-1];
wire  [7:0] Rx_fifo_data[0:NR-1];
wire        Rx_fifo_full[0:NR-1];
wire [11:0] Rx_used[0:NR-1];
wire        Rx_fifo_clr[0:NR-1];
wire 			Rx_fifo_empty;
wire 			fifo_clear;
wire 			fifo_clear1;
wire 			write_enable;
wire 			phy_ready;
wire 			convert_state;
wire 			C122_run;

// This is just for Rx0 since it can sync with Rx1.

		Rx_fifo Rx0_fifo_inst(.wrclk (C122_clk),.rdreq (fifo_rdreq[0]),.rdclk (tx_clock),.wrreq (Rx_fifo_wreq[0] && write_enable), 
							 .data (Rx_fifo_data[0]), .q (Rx_data[0]), .wrfull(Rx_fifo_full[0]), .rdempty(Rx_fifo_empty),
							 .rdusedw(Rx_used[0]), .aclr (IF_rst | Rx_fifo_clr[0] | !run | fifo_clear ));  											
							  
		Rx_fifo_ctrl0 #(NR) Rx0_fifo_ctrl_inst( .reset(!C122_run || !C122_EnableRx0_7[0] ), .clock(C122_clk), .data_in_I(rx_I[1]), .data_in_Q(rx_Q[1]), // was rx_Q[1]
													.spd_rdy(strobe[0]), .spd_rdy2(strobe[1]), .fifo_full(Rx_fifo_full[0]), .Rx_fifo_empty(C122_Rx_fifo_empty),  //.Rx_number(d),
													.wrenable(Rx_fifo_wreq[0]), .data_out(Rx_fifo_data[0]), .fifo_clear(Rx_fifo_clr[0]),
													.Sync_data_in_I(rx_I[0]), .Sync_data_in_Q(rx_Q[0]), .Sync(C122_SyncRx[0]), .convert_state(convert_state));	
													
		assign  fifo_ready[0] = (Rx_used[0] > 12'd1427) ? 1'b1 : 1'b0;  // used to signal that fifo has enough data to send to PC
		
// When Mux first set, inhibit fifo write then wait for PHY to be looking for more Rx0 data to ensure there is no data in transit.
// Then reset fifo then wait for 48 to 8 converter to be looking for Rx0 DDC data at first byte. Then enable write to fifo again.


// move flags into correct clock domains
wire C122_phy_ready;
wire C122_Rx_fifo_empty;
cdc_sync #(1) cdc_phyready  (.siga(phy_ready), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_phy_ready));
cdc_sync #(1) cdc_Rx_fifo_empty  (.siga(Rx_fifo_empty), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_Rx_fifo_empty));

cdc_sync #(1) C122_run_sync  (.siga(run), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_run));
cdc_sync #(16) C122_EnableRx0_7_sync  (.siga(EnableRx0_7), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_EnableRx0_7));

Mux_clear Mux_clear_inst( .clock(C122_clk), .Mux(C122_SyncRx[0][1]), .phy_ready(C122_phy_ready), .convert_state(convert_state), .SampleRate(C122_SampleRate[0]),
								  .fifo_clear(fifo_clear), .fifo_clear1(fifo_clear1), .fifo_write_enable(write_enable), .fifo_empty(C122_Rx_fifo_empty), .reset(!C122_run));	
								  
		Rx_fifo Rx1_fifo_inst(.wrclk (C122_clk),.rdreq (fifo_rdreq[1]),.rdclk (tx_clock),.wrreq (Rx_fifo_wreq[1]), 
							 .data (Rx_fifo_data[1]), .q (Rx_data[1]), .wrfull(Rx_fifo_full[1]),
							 .rdusedw(Rx_used[1]), .aclr (IF_rst | Rx_fifo_clr[1] | !C122_run | fifo_clear1));   // ***** added fifo_clear1

		Rx_fifo_ctrl #(NR) Rx1_fifo_ctrl_inst( .reset(!C122_run || !C122_EnableRx0_7[1]), .clock(C122_clk),   
							.spd_rdy(strobe[1]), .fifo_full(Rx_fifo_full[1]), //.Rx_number(d),
							.wrenable(Rx_fifo_wreq[1]), .data_out(Rx_fifo_data[1]), .fifo_clear(Rx_fifo_clr[1]),
							.Sync_data_in_I(rx_I[1]), .Sync_data_in_Q(rx_Q[1]), .Sync(0));
													
		assign  fifo_ready[1] = (Rx_used[1] > 12'd1427) ? 1'b1 : 1'b0;  // used to signal that fifo has enough data to send to PC

generate
genvar d;

for (d = 2 ; d < NR; d++)
	begin:p

		Rx_fifo Rx_fifo_inst(.wrclk (C122_clk),.rdreq (fifo_rdreq[d]),.rdclk (tx_clock),.wrreq (Rx_fifo_wreq[d]), 
							 .data (Rx_fifo_data[d]), .q (Rx_data[d]), .wrfull(Rx_fifo_full[d]),
							 .rdusedw(Rx_used[d]), .aclr (IF_rst | Rx_fifo_clr[d] | !C122_run));

		// Convert 48 bit Rx I&Q data (24bit I, 24 bit Q) into 8 bits to feed Tx FIFO. Only run if EnableRx0_7[x] is set.
		// If Sync[n] enabled then select the data from the receiver to be synchronised.
		// Do this by using C122_SyncRx(n) to select the required receiver I & Q data.

		Rx_fifo_ctrl #(NR) Rx0_fifo_ctrl_inst( .reset(!C122_run || !C122_EnableRx0_7[d]), .clock(C122_clk),   
							.spd_rdy(strobe[d]), .fifo_full(Rx_fifo_full[d]), //.Rx_number(d),
							.wrenable(Rx_fifo_wreq[d]), .data_out(Rx_fifo_data[d]), .fifo_clear(Rx_fifo_clr[d]),
							.Sync_data_in_I(rx_I[d]), .Sync_data_in_Q(rx_Q[d]), .Sync(0));
													
		assign  fifo_ready[d] = (Rx_used[d] > 12'd1427) ? 1'b1 : 1'b0;  // used to signal that fifo has enough data to send to PC

	end
endgenerate

											  
//------------------------------------------------------------------------
//   Mic_fifo  (1024 words) Dual clock FIFO - Altera Megafunction (dcfifo)
//------------------------------------------------------------------------

/*
						   +-------------------+
         mic_data 	|data[15:0]	  wrfull| 
						   |				        |
		mic_data_ready	|wrreq		        |
						   |					     |
				 CBCLK	|>wrclk	           | 
						   +-------------------+
   mic_fifo_rdreq		|rdreq		  q[7:0]| Mic_data
						   |					     |
	     tx_clock		|>rdclk		        | 
						   |		 rdusedw[11:0]| mic_rdused* (0 to 2047 bytes)
						   +-------------------+
			            |                   |
	         !run  	|aclr               |
				         +-------------------+
							
		* additional bit added so not zero when full.
		LSByte of input data is output first
	
*/

wire [11:0]	mic_rdused; 
							  
 Mic_fifo Mic_fifo_inst(.wrclk (CBCLK),.rdreq (mic_fifo_rdreq),.rdclk (tx_clock),.wrreq (mic_data_ready), 
 							  .data ({mic_data[7:0], mic_data[15:8]}), .q (Mic_data), .wrfull(),
                        .rdusedw(mic_rdused), .aclr(!run)); 

wire mic_fifo_ready = mic_rdused > 12'd131 ? 1'b1 : 1'b0;		// used to indicate that fifo has enough data to send to PC.					  
							  
//----------------------------------------------
//		Get mic data from  TLV320 in I2S format 
//---------------------------------------------- 

wire [15:0] mic_data;
reg mic_data_ready;
// reg CLRCLK1;

// always @(posedge CBCLK)
// begin
//    CLRCLK1 <= CLRCLK;
//    mic_data_ready <= (CLRCLK & ~CLRCLK1);
// end

 mic_I2S mic_I2S_inst (.clock(CBCLK), .CLRCLK(CLRCLK), .in(CDOUT), .mic_data(mic_data), .ready(mic_data_ready));

	 
//------------------------------------------------
//   SP_fifo  (16384 words) dual clock FIFO
//------------------------------------------------

/*
        The spectrum data FIFO is 16 by 16384 words long on the input.
        Output is in Bytes for easy interface to the PHY code
        NB: The output flags are only valid after a read/write clock has taken place

       
							   SP_fifo
						+--------------------+
  Wideband_source |data[15:0]	   wrfull| sp_fifo_wrfull
						|				         |
	sp_fifo_wrreq	|wrreq	     wrempty| sp_fifo_wrempty
						|				         |
			C122_clk	|>wrclk              | 
						+--------------------+
	sp_fifo_rdreq	|rdreq		   q[7:0]| sp_fifo_rddata
						|                    | 
						|				         |
		 tx_clock	|>rdclk		         | 
						|		               | 
						+--------------------+
						|                    |
	   !wideband   |aclr                |
		      	   |                    |
	    				+--------------------+
		
*/

wire  sp_fifo_rdreq;
wire [7:0]sp_fifo_rddata;
wire sp_fifo_wrempty;
wire sp_fifo_wrfull;
wire sp_fifo_wrreq;


//-----------------------------------------------------------------------------
//   Wideband Spectrum Data 
//-----------------------------------------------------------------------------

//	When sp_fifo_wrempty fill fifo with 'user selected' # words of consecutive ADC samples.
// Pass sp_data_ready to sdr_send to indicate that data is available.
// Reset fifo when !wideband so the data always starts at a known state.
// The time between fifo fills is set by the user (0-255mS). . The number of  samples sent per UDP frame is set by the user
// (default to 1024) as is the sample size (defaults to 16 bits).
// The number of frames sent, per fifo fill, is set by the user - currently set at 8 i.e. 4,096 samples. 


wire have_sp_data;

wire wideband = (Wideband_enable[0] | Wideband_enable[1]);  							// enable Wideband data if either selected
wire [15:0] Wideband_source = Wideband_enable[0] ? temp_ADC[0] : temp_ADC[1];	// select Wideband data source ADC0 or ADC1

// SP_fifo  SPF (.aclr(!wideband), .wrclk (C122_clk), .rdclk(tx_clock), 
//              .wrreq (sp_fifo_wrreq), .data ({Wideband_source[7:0], Wideband_source[15:8]}), .rdreq (sp_fifo_rdreq),
//              .q(sp_fifo_rddata), .wrfull(sp_fifo_wrfull), .wrempty(sp_fifo_wrempty)); 	
				 
// sp_rcv_ctrl SPC (.clk(C122_clk), .reset(0), .sp_fifo_wrempty(sp_fifo_wrempty),
//                  .sp_fifo_wrfull(sp_fifo_wrfull), .write(sp_fifo_wrreq), .have_sp_data(have_sp_data));	
				 
// **** TODO: change number of samples in FIFO (presently 16k) based on user selection **** 


// wire [:0] update_rate = 100T ?  12500 : 125000; // **** TODO: need to change counter target when run at 100T.
wire [17:0] update_rate = 12500;

reg  sp_data_ready;
reg [24:0]wb_counter;
wire WB_ack;

// always @ (posedge tx_clock)	
// begin
// 	if (wb_counter == (Wideband_update_rate * update_rate)) begin	  // max delay 255mS
// 		wb_counter <= 25'd0;
// 		if (have_sp_data & wideband) sp_data_ready <= 1'b1;	  
// 	end
// 	else begin 
// 			wb_counter <= wb_counter + 25'd1;
// 			if (WB_ack) sp_data_ready <= 0;  // wait for confirmation that request has been seen
// 	end
// end	


//----------------------------------------------------
//   					Rx_Audio_fifo
//----------------------------------------------------

/*
							  Rx_Audio_fifo (4k) 
							
								+--------------------+
				 audio_data |data[31:0]	  wrfull | Audio_full
								|				         |
	Rx_Audio_fifo_wrreq	|wrreq				   |
								|					      |									    
				 rx_clock	|>wrclk	 		      |
								+--------------------+								
	  get_audio_samples  |rdreq		  q[31:0]| LR_data 
								|					      |					  			
								|   		            | 
								|            rdempty | Audio_empty 							
				    CBCLK	|>rdclk              |    
								+--------------------+								
								|                    |
		  !run OR IF_rst  |aclr                |								
								+--------------------+	
								
	Only request audio samples if fifo not empty 						
*/

wire Rx_Audio_fifo_wrreq;
wire  [31:0] temp_LR_data;
wire  [31:0] LR_data;
wire get_audio_samples;  // request audio samples at 48ksps
wire Audio_full;
wire Audio_empty;
wire get_samples;
wire [31:0]audio_data;
wire Audio_seq_err;
reg [11:0]Rx_Audio_Used;

Rx_Audio_fifo Rx_Audio_fifo_inst(.wrclk (rx_clock),.rdreq (get_audio_samples),.rdclk (CBCLK),.wrreq(Rx_Audio_fifo_wrreq), 
			.rdusedw(Rx_Audio_Used), .data (audio_data),.q (LR_data),	.aclr(IF_rst | !run), .wrfull(Audio_full), .rdempty(Audio_empty));
					 
// Manage Rx Audio data to feed to Audio FIFO  - parameter is port #
byte_to_32bits #(1028) Audio_byte_to_32bits_inst
			(.clock(rx_clock), .run(run), .udp_rx_active(udp_rx_active), .udp_rx_data(udp_rx_data), .to_port(to_port),
			 .fifo_wrreq(Rx_Audio_fifo_wrreq), .data_out(audio_data), .sequence_error(Audio_seq_err), .full(Audio_full));
			
// select sidetone when CW key active and sidetone_level is not zero else Rx audio.
wire [31:0] Rx_audio;
assign Rx_audio = CW_PTT && (sidetone_level != 0) ? {prof_sidetone, prof_sidetone}  : LR_data;

// send receiver audio to TLV320 in I2S format
audio_I2S audio_I2S_inst (.run(run), .empty(Audio_empty), .BCLK(CBCLK), .rdusedw(Rx_Audio_Used), .LRCLK(CLRCLK), .data_in(Rx_audio), .data_out(CDIN), .get_data(get_audio_samples)); 


//----------------------------------------------------
//   					Tx1_IQ_fifo
//----------------------------------------------------

/*
							   Tx1_IQ_fifo (4k) 
							
								+--------------------+
			 Tx1_IQ_data   |data[47:0]	         | 
								|				         |
			Tx1_fifo_wrreq |wrreq  wrusedw[11:0]|	write_used[11:0]	
								|					      |									    
				 rx_clock	|>wrclk	 		      |
								+--------------------+								
	               req1  |rdreq		  q[47:0]| C122_IQ1_data
								|					      |					  			
								|   		            | 
								|                    | 							
				_155_52MHz	|>rdclk              | 	    
								+--------------------+								
								|                    |
		  !run | IF_rst   |aclr                |								
								+--------------------+	
								
*/

wire _155_52MHz;
assign _155_52MHz = M_CLK_PLL;

wire Tx1_fifo_wrreq;
wire [35:0]C155_IQ1_data;
wire [47:0]Tx1_IQ_data;
wire [12:0]write_used;

Tx1_IQ_fifo Tx1_IQ_fifo_inst(.wrclk (rx_clock),.rdreq (req1),.rdclk (_155_52MHz),.wrreq(Tx1_fifo_wrreq), 
 					 .data ({ Tx1_IQ_data[47:30], Tx1_IQ_data[23:6] }), .q(C155_IQ1_data), .aclr(!run | IF_rst), .wrusedw(write_used));
					 
// Manage Tx I&Q data to feed to Tx  - parameter is port #
byte_to_48bits #(1029) IQ_byte_to_48bits_inst
			(.clock(rx_clock), .run(run), .udp_rx_active(udp_rx_active), .udp_rx_data(udp_rx_data), .to_port(to_port),
			 .fifo_wrreq(Tx1_fifo_wrreq), .data_out(Tx1_IQ_data), .full(1'b0), .sequence_error());					 

// Ensure I&Q data is zero if not trasmitting
wire [47:0] IQ_Tx_data = FPGA_PTT ? C155_IQ1_data : 48'b0; 													

// indicate how full or empty the FIFO is - was required by Simon G4ELI code but no longer required. 
//wire almost_full 	= (write_used > 13'd3584) ? 1'b1 : 1'b0; //(write_used[11:8] == 4'b1111) ? 1'b1 : 1'b0;  // >= 3,840 samples
//wire almost_empty = (write_used < 13'd512)  ? 1'b1 : 1'b0; //(write_used[11:9] == 4'b0001) ? 1'b1 : 1'b0;  // <= 511 samples




													
//--------------------------------------------------------------------------
//			EPCS16 Erase and Program code 
//--------------------------------------------------------------------------

/*
					    EPCS_fifo (1k bytes) 
					
					    +-------------------+
	  udp_rx_data   |data[7:0]	         | 
					    |				         |
 EPCS_FIFO_enable  |wrreq		         | 
					    |					      |									    
	    rx_clock	 |>wrclk wrusedw[9:0]| EPCS_wrused
					    +-------------------+								
	   EPCS_rdreq   |rdreq		  q[7:0] | EPCS_data
					    |					      |					  			
			     	    |   		            |  
			          |                   | 							
     clock_12_5MHz |>rdclk rdusedw[9:0]| EPCS_Rx_used	    
					    +-------------------+								
					    |                   |
			  IF_rst  |aclr               |								
					    +-------------------+						
*/

wire [7:0]EPCS_data;
wire [10:0]EPCS_Rx_used;
wire  EPCS_rdreq;
wire [31:0] num_blocks;  
wire EPCS_full;
wire [10:0] EPCS_wrused;


// EPCS_fifo EPCS_fifo_inst(.wrclk (rx_clock),.rdreq (EPCS_rdreq),.rdclk (clock_12_5MHz),.wrreq(EPCS_FIFO_enable),  
//                 .data (udp_rx_data),.q (EPCS_data), .rdusedw(EPCS_Rx_used), .aclr(IF_rst), .wrusedw(EPCS_wrused));

//----------------------------
// 			ASMI Interface
//----------------------------
wire busy;				 // drives LED
wire erase_done;
wire erase_done_ACK;
wire reset_FPGA;

// ASMI_interface  ASMI_int_inst(.clock(clock_12_5MHz), .busy(busy), .erase(erase), .erase_ACK(erase_ACK), .IF_PHY_data(EPCS_data),
// 							 .IF_Rx_used(EPCS_Rx_used), .rdreq(EPCS_rdreq), .erase_done(erase_done), .num_blocks(num_blocks),
// 							 .send_more(send_more), .send_more_ACK(send_more_ACK), .erase_done_ACK(erase_done_ACK), .NCONFIG(reset_FPGA)); 
							 
//--------------------------------------------------------------------------------------------
//  	Iambic CW Keyer
//--------------------------------------------------------------------------------------------

wire keyout;

// parameter is clock speed in kHz.
iambic #(48) iambic_inst (.clock(CLRCLK), .cw_speed(keyer_speed),  .iambic(iambic), .keyer_mode(keyer_mode), .weight(keyer_weight), 
                          .letter_space(keyer_spacing), .dot_key(!KEY_DOT | Dot), .dash_key(!KEY_DASH | Dash),
								  .CWX(CWX), .paddle_swap(key_reverse), .keyer_out(keyout), .IO5(debounce_IO5));
						  
// //--------------------------------------------------------------------------------------------
// //  	Calculate  Raised Cosine profile for sidetone and CW envelope when internal CW selected 
// //--------------------------------------------------------------------------------------------

wire CW_char;
assign CW_char = (keyout & internal_CW & run);		// set if running, internal_CW is enabled and either CW key is active
wire [15:0] CW_RF;
wire [15:0] profile;
wire CW_PTT;

profile profile_sidetone (.clock(CLRCLK), .CW_char(CW_char), .profile(profile),  .delay(8'd0));
profile profile_CW       (.clock(CLRCLK), .CW_char(CW_char), .profile(CW_RF),    .delay(RF_delay), .hang(hang), .PTT(CW_PTT));

// //--------------------------------------------------------
// //			Generate CW sidetone with raised cosine profile
// //--------------------------------------------------------	
wire signed [15:0] prof_sidetone;
sidetone sidetone_inst( .clock(CLRCLK), .enable(sidetone), .tone_freq(tone_freq), .sidetone_level(sidetone_level), .CW_PTT(CW_PTT),
                        .prof_sidetone(prof_sidetone),  .profile(profile >>> 1));	// divide sidetone profile level by two since only 16 bits used
				
				
//-------------------------------------------------------
//		De-ramdomizer
//--------------------------------------------------------- 

/*

 A Digital Output Randomizer is fitted to the LTC2208. This complements bits 15 to 1 if 
 bit 0 is 1. This helps to reduce any pickup by the A/D input of the digital outputs. 
 We need to de-ramdomize the LTC2208 data if this is turned on. 
 
*/

reg [13:0] temp_ADC[0:1];
reg [13:0] temp_DACD;

always @ (posedge _155_52MHz)
   if(!_77_76MHz)temp_DACD <= Tx1_DAC_data;

always @ (posedge C122_clk) 
begin 

	 //{DAC,x} <= {x, Tx1_DAC_data[21:8], 2'b0}; // make DACD 16-bits, use high bits for DACD
	//temp_DACD <= {DACD, 2'b00};
	
   temp_ADC[0] <= ADC1;  // not set so just copy data	 	
	temp_ADC[1] <= ADC2;
	
end 



//------------------------------------------------------------------------------
//                 All DSP code is in the Receiver module
//------------------------------------------------------------------------------

wire       [31:0] C155_frequency_HZ [0:NR-1];   // frequency control bits for CORDIC
reg       [31:0] C122_frequency_HZ_Tx;
reg       [31:0] C122_last_freq [0:NR-1];
reg       [31:0] C122_last_freq_Tx;
reg       [31:0] C122_sync_phase_word [0:NR-1];
reg       [31:0] C122_sync_phase_word_Tx;
wire      [63:0] C122_ratio [0:NR-1];
wire      [63:0] C122_ratio_Tx;
wire      [23:0] rx_I [0:NR-1];
wire      [23:0] rx_Q [0:NR-1];
wire             strobe [0:NR-1];
wire      [15:0] C122_SampleRate[0:NR-1]; 
wire       [7:0] C122_RxADC[0:NR-1];
wire       [7:0] C122_SyncRx[0:NR-1];
wire      [31:0] C122_phase_word[0:NR-1]; 
wire [13:0] select_input_RX[0:NR-1];		// set receiver module input sources
//wire 		[15:0] select_input_RX1;		// set receiver module input source for RX1

reg 		 			frequency_change[0:NR-1];  // bit set when frequency of Rx[n] changes

generate
  genvar c;
  for (c = 0; c < NR; c++) 
   begin: MDC 
	
	// Move RxADC[n] to C122 clock domain
	cdc_mcp #(16) ADC_select
	(.a_rst(C122_rst), .a_clk(rx_clock), .a_data(RxADC[c]), .a_data_rdy(Rx_data_ready), .b_rst(C122_rst), .b_clk(C122_clk), .b_data(C122_RxADC[c]));


	// Move Rx[n] sample rate to C122 clock domain
	cdc_mcp #(16) S_rate
	(.a_rst(C122_rst), .a_clk(rx_clock), .a_data(RxSampleRate[c]), .a_data_rdy(Rx_data_ready), .b_rst(C122_rst), .b_clk(C122_clk), .b_data(C122_SampleRate[c]));
	
  end
endgenerate

always @ (posedge C122_clk) begin
    select_input_RX[0] <= C122_RxADC[0] == 8'd1 ? temp_ADC[1] : temp_ADC[0];
    select_input_RX[1] <= C122_RxADC[1] == 8'd2 ? temp_DACD : (C122_RxADC[1] == 8'd1 ? temp_ADC[1] : temp_ADC[0]); 
    select_input_RX[2] <= C122_RxADC[2] == 8'd1 ? temp_ADC[1] : temp_ADC[0]; 
    select_input_RX[3] <= C122_RxADC[3] == 8'd1 ? temp_ADC[1] : temp_ADC[0]; 
//    select_input_RX[4] <= C122_RxADC[4] == 8'd1 ? temp_ADC[1] : temp_ADC[0]; 
//    select_input_RX[5] <= C122_RxADC[5] == 8'd1 ? temp_ADC[1] : temp_ADC[0]; 
//    select_input_RX[6] <= C122_RxADC[6] == 8'd1 ? temp_ADC[1] : temp_ADC[0]; 
end

// move Rx phase words to C122 clock domain
cdc_sync #(32) Rx_freq0 
(.siga(Rx_frequency[0]), .rstb(C155_rst), .clkb(M_CLK_PLL), .sigb(C155_frequency_HZ[0]));

cdc_sync #(32) Rx_freq1 
(.siga(Rx_frequency[1]), .rstb(C155_rst), .clkb(M_CLK_PLL), .sigb(C155_frequency_HZ[1]));	

 cdc_sync #(32) Rx_freq2 
 (.siga(Rx_frequency[2]), .rstb(C155_rst), .clkb(M_CLK_PLL), .sigb(C155_frequency_HZ[2]));	

 cdc_sync #(32) Rx_freq3 
 (.siga(Rx_frequency[3]), .rstb(C155_rst), .clkb(M_CLK_PLL), .sigb(C155_frequency_HZ[3]));	

//cdc_sync #(32) Rx_freq4 
//(.siga(Rx_frequency[4]), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_frequency_HZ[4]));	

//cdc_sync #(32) Rx_freq5 
//(.siga(Rx_frequency[5]), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_frequency_HZ[5]));	

//cdc_sync #(32) Rx_freq6 
//(.siga(Rx_frequency[6]), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_frequency_HZ[6]));	

wire [17:0] mix_data_I[0:NR-1];
wire [17:0] mix_data_Q[0:NR-1];

    mix2 #(.CALCTYPE(4)) mix2_inst0 (
      .clk(C122_clk),
      .clk_2x(M_CLK_PLL),
      .rst(1'b0),
      .phi0(C155_frequency_HZ[0]),
      .phi1(C155_frequency_HZ[1]),
      .adc0(select_input_RX[0]),
      .adc1(select_input_RX[1]),
      .mixdata0_i(mix_data_I[0]),
      .mixdata0_q(mix_data_Q[0]),
      .mixdata1_i(mix_data_I[1]),
      .mixdata1_q(mix_data_Q[1])
   );


	receiver receiver_inst0(   
	//control
	.reset(fifo_clear || !C122_run || !C122_EnableRx0_7[0]),
	.clock(C122_clk),
	//input
	.sample_rate(C122_SampleRate[0]),
	.in_data_I(mix_data_I[0]),
   .in_data_Q(mix_data_Q[0]),
	//output
	.out_data_I(rx_I[0]),
	.out_data_Q(rx_Q[0]),
	.out_strobe(strobe[0])
	);


	receiver receiver_inst1(   
	//control
	.reset(fifo_clear || !C122_run || !C122_EnableRx0_7[0]),
	.clock(C122_clk),
	//input
	.sample_rate( C122_SampleRate[1]),
	.in_data_I(mix_data_I[1]),
   .in_data_Q(mix_data_Q[1]),
	//output
	.out_data_I(rx_I[1]),
	.out_data_Q(rx_Q[1]),
	.out_strobe(strobe[1])
	);


    mix2 #(.CALCTYPE(4)) mix2_inst1 (
      .clk(C122_clk),
      .clk_2x(M_CLK_PLL),
      .rst(1'b0),
      .phi0(C155_frequency_HZ[2]),
      .phi1(C155_frequency_HZ[3]),
      .adc0(select_input_RX[2]),
      .adc1(select_input_RX[3]),
      .mixdata0_i(mix_data_I[2]),
      .mixdata0_q(mix_data_Q[2]),
      .mixdata1_i(mix_data_I[3]),
      .mixdata1_q(mix_data_Q[3])
   );


	receiver receiver_inst2(   
	//control
	.reset(!C122_run),
	.clock(C122_clk),
	.sample_rate(C122_SampleRate[2]),
	.out_strobe(strobe[2]),
	//input
	.in_data_I(mix_data_I[2]),
   .in_data_Q(mix_data_Q[2]),
	//output
	.out_data_I(rx_I[2]),
	.out_data_Q(rx_Q[2])
	);


	receiver receiver_inst3(   
	//control
	.reset(!C122_run),  
	.clock(C122_clk),
	.sample_rate(C122_SampleRate[3]),
	.out_strobe(strobe[3]),
	//input
	.in_data_I(mix_data_I[3]),
   .in_data_Q(mix_data_Q[3]),
	//output
	.out_data_I(rx_I[3]),
	.out_data_Q(rx_Q[3])
	);



/*	
	receiver receiver_inst4(   
	//control
	.reset(!C122_run),
	.clock(C122_clk),
	.sample_rate(C122_SampleRate[4]),
	.frequency(C122_frequency_HZ[4]),     // PC send phase word now
	.out_strobe(strobe[4]),
	//input
	.in_data(select_input_RX[4]),
	//output
	.out_data_I(rx_I[4]),
	.out_data_Q(rx_Q[4])
	);	

	

	receiver receiver_inst5(   
	//control
	.reset(!C122_run),
	.clock(C122_clk),
	.sample_rate(C122_SampleRate[5]),
	.frequency(C122_frequency_HZ[5]),     // PC send phase word now
	.out_strobe(strobe[5]),
	//input
	.in_data(select_input_RX[5]),
	//output
	.out_data_I(rx_I[5]),
	.out_data_Q(rx_Q[5])
	);	
	
	

	receiver receiver_inst6(   
	//control
	.reset(!C122_run),
	.clock(C122_clk),
	.sample_rate(C122_SampleRate[6]),
	.frequency(C122_frequency_HZ[6]),     // PC send phase word now
	.out_strobe(strobe[6]),
	//input
	.in_data(select_input_RX[6]),
	//output
	.out_data_I(rx_I[6]),
	.out_data_Q(rx_Q[6])
	);	
*/

// only using Rx0 and Rx1 Sync for now so can use simpler code
	// Move SyncRx[n] into C122 clock domain
	cdc_mcp #(8) SyncRx_inst
	(.a_rst(C122_rst), .a_clk(rx_clock), .a_data(SyncRx[0]), .a_data_rdy(Rx_data_ready), .b_rst(C122_rst), .b_clk(C122_clk), .b_data(C122_SyncRx[0]));
		
				   
//---------------------------------------------------------
//                 Transmitter code 
//---------------------------------------------------------	

//---------------------------------------------------------
//  Interpolate by 640 CIC filter
//---------------------------------------------------------

//For interpolation, the growth in word size is  Celi(log2(R^(M-1))
//so for 5 stages and R = 640  = log2(640^4) = 37.28 so use 38

wire req1;
wire [18:0] y2_r, y2_i;
wire [18:0] y2_r1, y2_i1;

// CicInterpM5 #(.RRRR(810), .IBITS(24), .OBITS(18), .GBITS(39)) in2 (_155_52MHz, 1'd1, req1, IQ_Tx_data[47:24],
// 					IQ_Tx_data[23:0], y2_r, y2_i); 

// CicInterpMx #(.RATIO(810), .IBITS(24), .OBITS(18), .GBITS(39), .STAGES(5)) in2 (_155_52MHz, 1'd1, req1, IQ_Tx_data[47:24],
//  					IQ_Tx_data[23:0], y2_r, y2_i); 

//Upsample by 27
//Additional bits are log2(27^(5-1)) = 19.0196, use 20bits
wire req2;
//Divider div_Tx_27(_155_52MHz, 1'b1, strobe_Tx_27, 30);
CicInterpMx #(.RATIO(27), .IBITS(18), .OBITS(19), .GBITS(20), .STAGES(5)) in2_1 (_155_52MHz, req2, req1, IQ_Tx_data[35:18],
  					IQ_Tx_data[17:0], y2_r1, y2_i1); 

//Upsample by 30
CicInterpMx #(.RATIO(30), .IBITS(19), .OBITS(19), .GBITS(5), .STAGES(2)) in2_2 (_155_52MHz, 1'd1, req2, y2_i1,
  					y2_r1, y2_r, y2_i); 

reg signed [17:0] I;
reg signed [17:0] Q;

// if break_in is selected then CW_PTT can generate RF otherwise PC_PTT must be active.

reg [15:0] CW_RF1;

always @(posedge _155_52MHz)
begin 
   CW_RF1 <= CW_RF;
   I <= ((CW_PTT & break_in) ? { 1'b0, CW_RF1, 1'b0 }: ((CW_PTT & PC_PTT) ?  { 1'b0, CW_RF1, 1'b0 } : y2_i[17:0]));  // select VNA or CW mode if active. 
   // select VNA or CW mode if active else use CIC output 
   Q <= CW_PTT ? 18'd0 : y2_r[17:0]; 					
end

wire signed [13:0] Tx1_DAC_data;

mix_tx mix_tx_inst(.clk(_155_52MHz), .rst(1'b0), .phi(C122_frequency_HZ_Tx), .i_data(I), .q_data(Q), .dac(Tx1_DAC_data));

//assign DAC = Tx1_DAC_data;

//Generate debug signal - full scale DAC signal sinusoid at 9.72MHz
// reg [3:0] incnt;
// reg signed [13:0] test_DACD;
// always @ (posedge DACD_clock)
// begin
//    case (incnt)
//       4'h0 : test_DACD <= 14'd0;
//       4'h1 : test_DACD <= 14'd3135;
//       4'h2 : test_DACD <= 14'd5792;
//       4'h3 : test_DACD <= 14'd7567;
//       4'h4 : test_DACD <= 14'd8191;
//       4'h5 : test_DACD <= 14'd7567;
//       4'h6 : test_DACD <= 14'd5792;
//       4'h7 : test_DACD <= 14'd3135;
//       4'h8 : test_DACD <= 14'd0;
//       4'h9 : test_DACD <= -14'd3135;
//       4'ha : test_DACD <= -14'd5792;
//       4'hb : test_DACD <= -14'd7567;
//       4'hc : test_DACD <= -14'd8191;
//       4'hd : test_DACD <= -14'd7567;
//       4'he : test_DACD <= -14'd5792;
//       4'hf : test_DACD <= -14'd3135;
//    endcase
// 	incnt <= incnt + 4'd1; 
// end  

/*reg [13:0] temp1_DACD;

always @ (posedge _155_52MHz)
   temp1_DACD <= Tx1_DAC_data;
*/
always @ (posedge DACD_clock)
//	DACD <= IO4 ? Tx1_DAC_data[21:8] : 14'b0;   // select top 14 bits for DAC data // disable TX DAC if IO4 active
	DACD <= Tx1_DAC_data;   // Multiply output by 2, select top 14 bits for DAC data // disable TX DAC if IO4 active
//   DACD <= test_DACD;
 


//------------------------------------------------------------
//  Set Power Output 
//------------------------------------------------------------

// PWM DAC to set drive current to DAC. PWM_count increments 
// using rx_clock. If the count is less than the drive 
// level set by the PC then DAC_ALC will be high, otherwise low.  

// reg [7:0] PWM_count;
// always @ (posedge rx_clock)
// begin 
// 	PWM_count <= PWM_count + 1'b1;
// 	if (Drive_Level >= PWM_count)
// 		DAC_ALC <= 1'b1;
// 	else 
// 		DAC_ALC <= 1'b0;
// end 


//---------------------------------------------------------
//              Decode Command & Control data
//---------------------------------------------------------

wire         mode;     			// normal or Class E PA operation 
wire         Attenuator;		// selects input attenuator setting, 1 = 20dB, 0 = 0dB 
wire  [31:0] frequency[0:NR-1]; 	// Tx, Rx1, Rx2, Rx3, Rx4, Rx5, Rx6, Rx7
wire         IF_duplex;
wire   [7:0] Drive_Level; 		// Tx drive level
wire         Mic_boost;			// Mic boost 0 = 0dB, 1 = 20dB
wire         Line_In;				// Selects input, mic = 0, line = 1
wire			 common_Merc_freq;		// when set forces Rx2 freq to Rx1 freq
wire   [4:0] Line_In_Gain;		// Sets Line-In Gain value (00000=-32.4 dB to 11111=+12 dB in 1.5 dB steps)
wire         Apollo;				// Selects Alex (0) or Apollo (1)
wire   [4:0] Attenuator0;			// 0-31 dB Heremes attenuator value
wire			 TR_relay_disable;		// Alex T/R relay disable option
wire	 [4:0] Attenuator1;		// attenuation setting for input attenuator 2 (input atten for ADC2), 0-31 dB
wire         internal_CW;			// set when internal CW generation selected
wire   [7:0] sidetone_level;		// 0 - 100, sets internal sidetone level
wire 			 sidetone;				// Sidetone enable, 0 = off, 1 = on
wire   [7:0] RF_delay;				// 0 - 255, sets delay in mS from CW Key activation to RF out
wire   [9:0] hang;					// 0 - 1000, sets delay in mS from release of CW Key to dropping of PTT
wire  [11:0] tone_freq;				// 200 to 1000 Hz, sets sidetone frequency.
wire         key_reverse;		   // reverse CW keyes if set
wire   [5:0] keyer_speed; 			// CW keyer speed 0-60 WPM
wire         keyer_mode;			// 0 = Mode A, 1 = Mode B
wire 			 iambic;					// 0 = external/straight/bug  1 = iambic
wire   [7:0] keyer_weight;			// keyer weight 33-66
wire         keyer_spacing;		// 0 = off, 1 = on
wire 			 break_in;				// if set then use break in mode
wire   [4:0] atten0_on_Tx;			// ADC0 attenuation value to use when Tx is active
wire   [4:0] atten1_on_Tx;			// ADC1 attenuation value to use when Tx is active
wire  [31:0] Rx_frequency[0:NR-1];	// Rx(n) receive frequency
wire  [31:0] Tx0_frequency;		// Tx0 transmit frequency
wire  [31:0] Alex_data;				// control data to Alex board
wire         run;						// set when run active 
wire 		    PC_PTT;					// set when PTT from PC active
wire 	 [7:0] dither;					// Dither for ADC0[0], ADC1[1]...etc
wire   [7:0] random;					// Random for ADC0[0], ADC1[1]...etc
wire   [7:0] RxADC[0:NR-1];			// ADC or DAC that Rx(n) is connected to
wire 	[15:0] RxSampleRate[0:NR-1];	// Rxn Sample rate 48/96/192 etc
wire 			 Alex_data_ready;		// indicates Alex data available
wire         Rx_data_ready;		// indicates Rx_specific data available
wire 			 Tx_data_ready;		// indicated Tx_specific data available
wire   [7:0] Mux;						// Rx in mux mode when bit set, [0] = Rx0, [1] = Rx1 etc 
wire   [7:0] SyncRx[0:NR-1];			// bit set selects Rx to sync or mux with
wire 	 [7:0] EnableRx0_7;			// Rx enabled when bit set, [0] = Rx0, [1] = Rx1 etc
wire 	 [7:0] C122_EnableRx0_7;
wire  [15:0] Rx_Specific_port;	// 
wire  [15:0] Tx_Specific_port;
wire  [15:0] High_Prioirty_from_PC_port;
wire  [15:0] High_Prioirty_to_PC_port;			
wire  [15:0] Rx_Audio_port;
wire  [15:0] Tx_IQ_port;
wire  [15:0] Rx0_port;
wire  [15:0] Mic_port;
wire  [15:0] Wideband_ADC0_port;
wire   [7:0] Wideband_enable;					// [0] set enables ADC0, [1] set enables ADC1
wire  [15:0] Wideband_samples_per_packet;				
wire   [7:0] Wideband_sample_size;
wire   [7:0] Wideband_update_rate;
wire   [7:0] Wideband_packets_per_frame; 
wire  [15:0] Envelope_PWM_max;
wire  [15:0] Envelope_PWM_min;
wire   [7:0] Open_Collector;
wire   [7:0] User_Outputs;
wire   [7:0] Mercury_Attenuator;	
wire 			 CWX;						// CW keyboard from PC 
wire         Dot;						// CW dot key from PC
wire         Dash;					// CW dash key from PC]
wire freq_data_ready;


//wire         Time_stamp;
//wire         VITA_49;				
localparam         VNA = 0;									// Selects VNA mode when set. 
//wire   [7:0] Atlas_bus;
//wire     [7:0] _10MHz_reference,
wire         PA_enable;
//wire         Apollo_enable;	
wire   [7:0] Alex_enable;			
wire         data_ready;
wire 			 HW_reset1;
wire 			 HW_reset2;	
wire 			 HW_reset3;
wire 			 HW_reset4;
wire 			 HW_timer_enable;

General_CC #(1024) General_CC_inst // parameter is port number  ***** this data is in rx_clock domain *****
			(
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				// outputs
			   .Rx_Specific_port(Rx_Specific_port),
				.Tx_Specific_port(Tx_Specific_port),
				.High_Prioirty_from_PC_port(High_Prioirty_from_PC_port),
				.High_Prioirty_to_PC_port(High_Prioirty_to_PC_port),			
				.Rx_Audio_port(Rx_Audio_port),
				.Tx_IQ_port(Tx_IQ_port),
				.Rx0_port(Rx0_port),
				.Mic_port(Mic_port),
				.Wideband_ADC0_port(Wideband_ADC0_port),
				.Wideband_enable(Wideband_enable),
				.Wideband_samples_per_packet(Wideband_samples_per_packet),				
				.Wideband_sample_size(Wideband_sample_size),
				.Wideband_update_rate(Wideband_update_rate),
				.Wideband_packets_per_frame(Wideband_packets_per_frame),
			//	.Envelope_PWM_max(Envelope_PWM_max),
			//	.Envelope_PWM_min(Envelope_PWM_min),
			//	.Time_stamp(Time_stamp),
			//	.VITA_49(VITA_49),				
			//	.VNA(VNA),
				//.Atlas_bus(),
				//._10MHz_reference(),
				.PA_enable(PA_enable),
			//	.Apollo_enable(Apollo_enable),	
				.Alex_enable(Alex_enable),			
				.data_ready(data_ready),
				.HW_reset(HW_reset1),
				.HW_timer_enable(HW_timer_enable)
				);



High_Priority_CC #(1027, NR) High_Priority_CC_inst  // parameter is port number 1027  ***** this data is in rx_clock domain *****
			(
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				.HW_timeout(HW_timeout),					// used to clear run if HW timeout.
				// outputs
			   .run(run),
				.PC_PTT(PC_PTT),
				.CWX(CWX),
				.Dot(Dot),
				.Dash(Dash),
				.Rx_frequency(Rx_frequency),
				.Tx0_frequency(Tx0_frequency),
				.Alex_data(Alex_data),
				.drive_level(Drive_Level),
				.Attenuator0(Attenuator0),
				.Attenuator1(Attenuator1),
				.Open_Collector(Open_Collector),			// open collector outputs on Angelia
			//	.User_Outputs(),
			//	.Mercury_Attenuator(),	
				.Alex_data_ready(Alex_data_ready),
				.HW_reset(HW_reset2)
			);

// if break_in is selected then CW_PTT can activate the FPGA_PTT. 
// if break_in is slected then CW_PTT can generate RF otherwise PC_PTT must be active.	
// inhibit T/R switching if IO4 TX INHIBIT is active (low)		
assign FPGA_PTT = /*IO4 &&*/ ((break_in && CW_PTT) || PC_PTT || debounce_PTT); // CW_PTT is used when internal CW is selected

// clear TR relay and Open Collectors if run not set 
wire [31:0]runsafe_Alex_data 		  = run ? Alex_data : {Alex_data[31:26], 1'b0, Alex_data[24:0]};

Tx_specific_CC #(1026)Tx_specific_CC_inst //   // parameter is port number  ***** this data is in rx_clock domain *****
			( 	
				// inputs
				.clock (rx_clock),
				.to_port (to_port),
				.udp_rx_active (udp_rx_active),
				.udp_rx_data (udp_rx_data),
				// outputs
				.EER() ,
				.internal_CW (internal_CW),
				.key_reverse (key_reverse), 
				.iambic (iambic),					
				.sidetone (sidetone), 			
				.keyer_mode (keyer_mode), 		
				.keyer_spacing(keyer_spacing),
				.break_in(break_in), 						
				.sidetone_level(sidetone_level), 
				.tone_freq(tone_freq), 
				.keyer_speed(keyer_speed),	
				.keyer_weight(keyer_weight),
				.hang(hang), 
				.RF_delay(RF_delay),
				.Line_In(Line_In),
				.Line_In_Gain(Line_In_Gain),
				.Mic_boost(Mic_boost),
				.Angelia_atten_Tx1(atten1_on_Tx),
				.Angelia_atten_Tx0(atten0_on_Tx),	
				.data_ready(Tx_data_ready),
				.HW_reset(HW_reset3)

			);

			
Rx_specific_CC #(1025, NR) Rx_specific_CC_inst // parameter is port number 
			( 	
				// inputs
				.clock(rx_clock),
				.to_port(to_port),
				.udp_rx_active(udp_rx_active),
				.udp_rx_data(udp_rx_data),
				// outputs
				.dither(dither),
				.random(random),
				.RxSampleRate(RxSampleRate),
				.RxADC(RxADC),	
				.SyncRx(SyncRx),
				.EnableRx0_7(EnableRx0_7),
				.Rx_data_ready(Rx_data_ready),
				.Mux(Mux),
				.HW_reset(HW_reset4)
			);			
//assign EnableRx0_7 = 8'b00000011;

assign  DITH   = dither[0];      		//high turns LTC2208 dither on 
assign  DITH_2 = dither[1]; 		

// transfer C&C data in rx_clock domain, on strobe, into relevant clock domains
cdc_mcp #(32) Tx1_freq 
 (.a_rst(C122_rst), .a_clk(rx_clock), .a_data(Tx0_frequency), .a_data_rdy(Alex_data_ready), .b_rst(C155_rst), .b_clk(_155_52MHz), .b_data(C122_frequency_HZ_Tx));
 
// move Mux data into C122_clk domain
wire [7:0]C122_Mux;
cdc_mcp #(8) Mux_inst 
	(.a_rst(C122_rst), .a_clk(rx_clock), .a_data(Mux), .a_data_rdy(Rx_data_ready), .b_rst(C122_rst), .b_clk(C122_clk), .b_data(C122_Mux)); 

// move Alex data into CBCLK domain
wire  [31:0] SPI_Alex_data;
cdc_sync #(32) SPI_Alex (.siga(runsafe_Alex_data), .rstb(IF_rst), .clkb(CBCLK), .sigb(SPI_Alex_data));
 

 

//------------------------------------------------------------
//  			High Priority to PC C&C Encoder 
//------------------------------------------------------------

// All input data is transfered to tx_clock domain in the encoder

wire CC_ack;
wire CC_data_ready;
wire [7:0] CC_data[0:55];
wire [15:0] Exciter_power = FPGA_PTT ? {4'b0,AIN5} : 16'b0; 
wire [15:0] FWD_power     = FPGA_PTT ? {4'b0,AIN1} : 16'b0;
wire [15:0] REV_power     = FPGA_PTT ? {4'b0,AIN2} : 16'b0;
wire [15:0] user_analog1  = {4'b0, AIN3}; 
wire [15:0] user_analog2  = {4'b0, AIN4}; 
wire locked_10MHz;
 
CC_encoder #(50, NR) CC_encoder_inst (				// 50mS update rate
					//	inputs
					.clock(tx_clock),					// tx_clock  125MHz
					.ACK (CC_ack),
					.PTT ((break_in & CW_PTT) | debounce_PTT),
					.Dot (debounce_DOT),
					.Dash(debounce_DASH),
					.frequency_change(frequency_change),
					.locked_10MHz(locked_10MHz),		// set if the 10MHz divider PLL is locked.
					.ADC0_overload (ADC1_OVF),
					.ADC1_overload (ADC2_OVF),
					.Exciter_power (Exciter_power),			
					.FWD_power (FWD_power),
					.REV_power (REV_power),
					.Supply_volts ({4'b0,AIN6}),  
					.User_ADC1 (user_analog1),
					.User_ADC2 (user_analog2),
					.User_IO ({3'b0, IO4}),
					.Debug_data({6'b000000,~DEBUG_LED10,~DEBUG_LED9,~DEBUG_LED8,~DEBUG_LED7,~DEBUG_LED6,~DEBUG_LED5,~DEBUG_LED4,~DEBUG_LED3,~DEBUG_LED2,~DEBUG_LED1}),
					.pk_detect_ack,			// from Angelia_ADC
					.FPGA_PTT(FPGA_PTT),						// when set change update rate to 1mS
							
					//	outputs
					.CC_data (CC_data),
					.ready (CC_data_ready),
					.pk_detect_reset 			// to Angelia_ADC
				);
							
 
 
 
 
//------------------------------------------------------------
//  Angelia on-board attenuators 
//------------------------------------------------------------

// set the two input attenuators
wire [4:0] atten0;
wire [4:0] atten1;

assign atten0 = FPGA_PTT ? atten0_on_Tx : Attenuator0;
assign atten1 = FPGA_PTT ? atten1_on_Tx : Attenuator1; 

// Attenuator Attenuator_ADC0 (.clk(CMCLK), .data(atten0), .ATTN_CLK(ATTN_CLK),   .ATTN_DATA(ATTN_DATA),   .ATTN_LE(ATTN_LE));
// Attenuator Attenuator_ADC1 (.clk(CMCLK), .data(atten1), .ATTN_CLK(ATTN_CLK_2), .ATTN_DATA(ATTN_DATA_2), .ATTN_LE(ATTN_LE_2));

reg DITH;
reg DITH_2;
reg SHDN;
reg SHDN_2;

wire [7:0] LNA_CODE = { atten0 + 6'd4, /*SHDN*/ 1'b1, /*DITH*/ 1'b1 };
wire [7:0] LNA_CODE2 = { atten1 + 6'd4, /*SHDN_2*/ 1'b1, /*DITH_2*/ 1'b1 };

SPI_DVGA SPI_DGA_ADC(/*M_CLK_PLL*/CBCLK, /*M_SPI_EN*/ 1'b1, { LNA_CODE, LNA_CODE2 } , LNA_CLK, LNA_DATA, LNA_LOAD);



//---------------------------------------------------------
//  Debounce inputs - active low
//---------------------------------------------------------

wire debounce_PTT;    // debounced button
wire debounce_DOT;
wire debounce_DASH;
wire debounce_IO5;

debounce de_PTT	(.clean_pb(debounce_PTT),  .pb(!PTT), .clk(CMCLK));
debounce de_DOT	(.clean_pb(debounce_DOT),  .pb(!KEY_DOT), .clk(CMCLK));
debounce de_DASH	(.clean_pb(debounce_DASH), .pb(!KEY_DASH), .clk(CMCLK));
debounce de_IO5	(.clean_pb(debounce_IO5),	.pb(!IO5), 		 .clk(CMCLK));

//-------------------------------------------------------
//    PLLs 
//---------------------------------------------------------


/* 
	Divide the 122.88MHz clock to give a 10MHz signal.
	Apply this with the 10MHz TCXO to an EXOR phase detector. If the 10MHz reference is not
	present the EXOR output will be a 10MHz square wave. When passed through 
	the loop filter this will provide a dc level of (3.3/2)v which will
	set the 122.88MHz VCXO to its nominal frequency.
	The selection of the internal or external 10MHz reference for the PLL
	is made using a PCB jumper; some boards select this automatically when the external reference is applied. 

*/


//155.52MHz PLL
assign REF_EN = 1'b1;
MPLL PLL155_52M(M_CLK /*VCXO*/, REF_CLK /*reference*/, PD_POL /*PFD output polarity*/, PD_EN /*PFD output enable*/);


//-----------------------------------------------------------
//  LED Control  
//-----------------------------------------------------------

/*
	LEDs:  
	
	DEBUG_LED1  	- Lights when an Ethernet broadcast is detected
	DEBUG_LED2  	- Lights when traffic to the boards MAC address is detected
	DEBUG_LED3  	- Lights when detect a received sequence error or ASMI is busy
	DEBUG_LED4 		- Displays state of PHY negotiations - fast flash if no Ethernet connection, slow flash if 100T and on if 1000T
	DEBUG_LED5		- Lights when the PHY receives Ethernet traffic
	DEBUG_LED6  	- Lights when the PHY transmits Ethernet traffic
	DEBUG_LED7  	- Displays state of DHCP negotiations or static IP - on if ACK, slow flash if NAK, fast flash if time out 
					     and long then short flash if static IP
	DEBUG_LED8  	- Lights when sync (0x7F7F7F) received from PC
	DEBUG_LED9  	- Lights when a Metis discovery packet is received
	DEBUG_LED10 	- Lights when a Metis discovery packet reply is sent	
	
	Status_LED	    - Flashes once per second
	
	A LED is flashed for the selected period on the positive edge of the signal
	If the signal period is greater than the LED period the LED will remain on.


*/

parameter half_second = 2_500_000; // 0.2sec at 12.288MHz clock rate
parameter fast_clock_half_second = 2_500_000; // at PHY rate (12.5MHz)

`define LEDS 1

`ifdef LEDS

// flash LED1 for ~ 0.2 second whenever the PHY receives (rgmii_rx_activ)
Led_flash Flash_LED1(.clock(rx_clock), .signal(network_status[2]), .LED(DEBUG_LED1), .period(half_second)); 	
//Led_flash Flash_LED1(.clock(C122_clk), .signal(C122_EnableRx0_7[1]), .LED(DEBUG_LED1), .period(fast_clock_half_second)); 	

// flash LED2 for ~ 0.2 second whenever the PHY transmits (rgmii_tx_active)
Led_flash Flash_LED2(.clock(rx_clock), .signal(network_status[1]), .LED(DEBUG_LED2), .period(half_second)); 

// flash LED3 for ~0.2 seconds whenever ip_rx_enable ????
Led_flash Flash_LED3(.clock(rx_clock), .signal(0), .LED(DEBUG_LED3), .period(half_second));

// flash LED4 for ~0.2 seconds whenever traffic to the boards MAC address is received 
Led_flash Flash_LED4(.clock(rx_clock), .signal(network_status[0]), .LED(DEBUG_LED4), .period(half_second));

// flash LED7 for ~0.2 seconds whenever udp_rx_active
Led_flash Flash_LED7(.clock(rx_clock), .signal(network_status[4]), .LED(DEBUG_LED7), .period(half_second));		// udp_rx_active

// flash LED8 for ~0.2 seconds when
Led_flash Flash_LED8(.clock(rx_clock), .signal(0), .LED(DEBUG_LED8), .period(fast_clock_half_second));

// flash LED9 for ~0.2 seconds when
Led_flash Flash_LED9(.clock(rx_clock), .signal(C122_SyncRx[0][1]), .LED(DEBUG_LED9), .period(fast_clock_half_second)); // note fast clock now - DAC data

// flash LED10 for ~0.2 seconds when 
//Led_flash Flash_LED10(.clock(rx_clock), .signal(fifo_clear), .LED(DEBUG_LED10), .period(fast_clock_half_second));  // note fast clock now - mux
Led_flash Flash_LED10(.clock(tx_clock), .signal(port_ID[7:0] == 8'd8), .LED(DEBUG_LED10), .period(fast_clock_half_second));  // note fast clock now - mux


//------------------------------------------------------------
//   Multi-state LED Control   - code in Led_control is for active LOW LEDs
//------------------------------------------------------------

parameter clock_speed = 12_500_000; // 12.288MHz clock 

// display state of PHY negotiations  - fast flash if no Ethernet connection, slow flash if 100T, on if 1000T
// and swap between fast and slow flash if not full duplex
Led_control #(clock_speed) Control_LED0(.clock(rx_clock), .on(0), .fast_flash(~network_status[7]),
										.slow_flash(network_status[5]), .vary(~network_status[6]), .LED(DEBUG_LED5));  
										
// display state of DHCP negotiations - on if success, slow flash if fail, fast flash if time out and swap between fast and slow 
// if using a static IP address
Led_control # (clock_speed) Control_LED1(.clock(rx_clock), .on(dhcp_success), .slow_flash(dhcp_failed & !dhcp_timeout),
										.fast_flash(dhcp_timeout), .vary(static_ip_assigned), .LED(DEBUG_LED6));	
`else
 
assign DEBUG_LED1 = 1'b1;
assign DEBUG_LED2 = 1'b1;
assign DEBUG_LED3 = 1'b1;
assign DEBUG_LED4 = 1'b1;
assign DEBUG_LED5 = 1'b1;
assign DEBUG_LED6 = 1'b1;
assign DEBUG_LED7 = 1'b1;
assign DEBUG_LED8 = 1'b1;
assign DEBUG_LED9 = 1'b1;
assign DEBUG_LED10 = 1'b1;

`endif


//Flash Heart beat LED
reg [25:0]HB_counter;
always @(posedge PHY_CLK50) HB_counter <= HB_counter + 1'b1;
assign Status_LED = HB_counter[25];  // Blink



//----------------------------------------------
//		MB SPI interface
//----------------------------------------------

wire [11:0] AIN1;  // FWD_power
wire [11:0] AIN2;  // REV_power
wire [11:0] AIN3;  // User 1
wire [11:0] AIN4;  // User 2
wire [11:0] AIN5;  // holds 12 bit ADC value of Forward Voltage detector.
wire [11:0] AIN6;  // holds 12 bit ADC of 13.8v measurement 
wire pk_detect_reset;
wire pk_detect_ack;


// Angelia_ADC ADC_SPI(.clock(userADC_clk/*CBCLK*/), .SCLK(ADCCLK), .nCS(nADCCS), .MISO(ADCMISO), .MOSI(ADCMOSI),
// 				   .AIN1(AIN1), .AIN2(AIN2), .AIN3(AIN3), .AIN4(AIN4), .AIN5(AIN5), .AIN6(AIN6), .pk_detect_reset(pk_detect_reset), .pk_detect_ack(pk_detect_ack));	
				   
// SPI Alex_SPI_Tx (.reset (IF_rst), .enable(Alex_enable[0]), .Alex_data(SPI_Alex_data), .SPI_data(Alex_SPI_SDO),
//                  .SPI_clock(Alex_SPI_SCK), .Tx_load_strobe(SPI_TX_LOAD),
//                  .Rx_load_strobe(SPI_RX_LOAD), .spi_clock(CBCLK));	


// force open collector drives to off state when code not running.
wire [6:0] USEROUT;
assign USEROUT = run ? Open_Collector[7:1] : 7'b0;					

MB_SPI_IO MB_SPI_IO_inst(.clock(CMCLK), 
                         .AIN1(AIN1), .AIN2(AIN2), .AIN3(AIN3), .AIN4(AIN4), .AIN5(AIN5), .AIN6(AIN6), 
                         .pk_detect_reset(pk_detect_reset), .pk_detect_ack(pk_detect_ack),
                         .enable(Alex_enable[0]), .Alex_data(SPI_Alex_data),
                         .leds( {Status_LED, DEBUG_LED7, DEBUG_LED6, DEBUG_LED5, DEBUG_LED4, DEBUG_LED3, DEBUG_LED2, DEBUG_LED1} ),
                         .OC(USEROUT), .DAC(Drive_Level),
                         .CLK(MCU_CLK), .MISO(MCU_MISO), .MOSI(MCU_MOSI), .LOAD(MCU_LOAD)
                         );

endmodule 



