;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2014 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_firmware

.include /firmware.s/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_disableFirmware
;;
;;    Disables Amstrad CPC firmware, preventing it from being executed at every
;; CPU interrupt.
;;
;; C Definition:
;;    u16 <cpct_disableFirmware> ()
;;
;; Assembly call:
;;    > call cpct_disableFirmware_asm
;;
;; Return value:
;;    <u16> - Present interrupt handler code (normally, pointer to firmware ROM code).
;; This value should be stored to restore it later, if required.
;;
;; Details:
;;    Disables the firmware modifying the interrupt vector at memory location 
;; 0x38. Normally, firmware routines are called and executed at every interrupt
;; and the ROM entry point is stored at 0x38 (a 16-bit address where the 
;; firmware code starts). This function substitutes the 2 bytes located at 
;; 0x38 by 0xC9FB, (0xFB = EI, 0xC9 = RET), which basically does nothing 
;; at each interruption (restores interrupts and returns).
;;
;;    Before inserting 0xC9FB at 0x38, the 2 bytes lying there are saved into DE.
;; These 2 bytes are returned to the caller, to let them be stored and restored 
;; later on, if normal firmware operation (or previous interrupt handler) is 
;; required. <cpct_reenableFirmware> may be used for this restoring operation.
;;
;;    Disabling the firmware is useful for several reasons:
;;    - Firmware code gets executed 6 times per frame (1 at each interrupt) when 
;; is active. If you turn it off, you win CPU clock cycles for your program, 
;; because firmware will not execute anymore.
;;    - Most of CPCtelera's functions talk directly to hardware, no to firmware.
;; They are faster, but they do not change firmware variables. As a result, 
;; firmware can revert changes made by CPCtelera's functions when active. For 
;; instance, if you change to video mode 0 using CPCtelera's functions, firmware
;; will see that the video mode is different from what it should be (attending 
;; to its own variables) and will change it again to 1. This happens with video
;; modes and palette values mainly.
;;    - Also, firmware uses part of the RAM to store its variables (from 
;; 0xA6FC to 0xBFFF). If you accidentaly overwrite anything there with firmware
;; being active, unpredictable things will happen, even hanging the computer.
;; Moreover, disabling firmware lets you use this part of the RAM for your 
;; own uses.
;;
;; Destroyed Register values: 
;;    HL
;;
;; Required memory:
;;    16 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs (us) | CPU Cycles
;; --------------------------------------
;; Any  |      22        |     88
;; --------------------------------------
;; (end code)
;;
;; Credits:                                                       
;;    This function was coded copying and modifying cpc_disableFirmware 
;; from CPCRSLib by Raul Simarro.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_disableFirmware::
cpct_disableFirmware_asm::        ;; Assembly entry point
   di                             ;; [1] Disable interrupts
   ld   hl, (firmware_RST_jp)     ;; [5] Obtain firmware ROM code pointer and store it for restoring it later
   ex   de, hl                    ;; [1] DE = HL (Save present firmware ROM code pointer)

   im    1                        ;; [2] Set Interrupt Mode 1 (CPU will jump to 0x38 when a interrupt occurs)
   ld   hl, #0xC9FB               ;; [3] FB C9 (take into account little endian) => EI : RET

   ld (firmware_RST_jp), hl       ;; [5] Setup new "interrupt handler" and enable interrupts again
   ei                             ;; [1]
   ex   de, hl                    ;; [1] HL = Present firmware ROM code pointer (return value)

   ret                            ;; [3] Return
