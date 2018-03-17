;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawSpriteHFlipM0
;;
;;    Draws a Mode 0 sprite from an array to video memory or Hardware Back Buffer 
;; flipping it Horizontally (right to left)
;;
;; C Definition:
;;    void <cpct_drawSpriteHFlipM0> (const void* *sprite*, void* *memory*, <u8> *width*, <u8> *height*) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;  (2B DE) sprite - Source Sprite Pointer
;;  (2B HL) memory - Destination video memory pointer
;;  (1B C ) width  - Sprite Width in *bytes* (Beware, *not* in pixels!)
;;  (1B B ) height - Sprite Height in bytes 
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawSpriteHFlipM0_asm
;;
;; Parameter Restrictions:
;;  * *sprite* must be a pointer to the sprite array containing Mode 0 pixel data 
;; to be drawn. Sprite must be rectangular and all bytes in the array must be 
;; consecutive pixels, starting from top-left corner and going left-to-right, 
;; top-to-bottom down to the bottom-right corner. Total amount of bytes in pixel 
;; array should be *width* x *height*.
;;  * *memory* must be a pointer to the place where the sprite is to be drawn. 
;; It could be any place in memory, inside or outside current video memory. 
;; It will be equally treated as video memory (taking into account CPC's video 
;; memory disposition). This lets you copy sprites to software or hardware 
;; backbuffers, and not only video memory.
;;  * *width* (1-256) must be the width of the sprite *in bytes*. Always remember 
;; that the width must be expressed in bytes and *not* in pixels. 
;;  * *height* (1-256) must be the height of the sprite in bytes. Height of a sprite in
;; bytes and pixels is the same value.
;;
;; Known limitations:
;;    * *width*s or *height*s of 0 will be considered as 256, and could 
;; potentially make your code behave erratically or crash.
;;    * This function does not do any kind of boundary check or clipping. If you 
;; try to draw sprites on the frontier of your video memory or screen buffer 
;; if might potentially overwrite memory locations beyond boundaries. This 
;; could cause your program to behave erratically, hang or crash. Always 
;; take the necessary steps to guarantee that you are drawing inside screen
;; or buffer boundaries.
;;    * As this function receives a byte-pointer to memory, it can only 
;; draw byte-sized and byte-aligned sprites. 
;;    * This function *will not work from ROM*, as it uses self-modifying code.
;;    * Although this function can be used under hardware-scrolling conditions,
;; it does not take into account video memory wrap-around (0x?7FF or 0x?FFF 
;; addresses, the end of character pixel lines).It  will produce a "step" 
;; in the middle of sprites when drawing near wrap-around.
;;
;; Details:


;;;;;;;;;;;;; TODO: Rewrite Details and Example


;;    Draws given *sprite* to *memory* taking into account CPC's standard video
;; memory disposition. Therefore, *memory* can be pointing to actual video memory
;; or to a hardware backbuffer. 
;;
;;    The drawing happens bottom-to-top. *memory* will be considered to be pointing
;; to the bottom-left byte of the sprite in video memory. This is the way in which
;; the sprite will be drawn in reverse,
;;
;; (start code)
;; ||-----------------------||----------------------||
;; ||   MEMORY              ||  VIDEO MEMORY        ||
;; ||-----------------------||----------------------|| 
;; ||           width       ||          width       ||
;; ||         (------)      ||        (------)      ||
;; ||                       ||                      ||
;; ||      /->###  ###  ^   ||        # #  # #  ^   || ^
;; || sprite  ##    ##  | h ||        ##    ##  | h || |
;; ||         #      #  | e ||        ###  ###  | e || | Sprite is 
;; ||         ###  ###  | i ||        ##   ###  | i || | drawn in 
;; ||         ##   ###  | g ||        ###  ###  | g || | this order
;; ||         ###  ###  | h ||        #      #  | h || | (bottom to
;; ||         ##    ##  | t || memory ##    ##  | t || |  top)
;; ||         # #  # #  v   ||     \->###  ###  v   || -  
;; ||-----------------------||----------------------||
;; (end code)
;;
;;    In order to get a pointer to the bottom-left of the memory location where you
;; want to draw your sprite, you may use <cpct_getBottomLeftPtr>.
;;
;;    Use example,
;; (start code)
;;    ///////////////////////////////////////////////////////////////////
;;    // DRAW OBJECT IN FRONT OF INVERTING MIRROR
;;    //    Draws an object in its coordinates and a vertically inverted
;;    // version of the same object right next to the original one.
;;    //
;;    void drawObjectInFrontOfMirror(Object* o) {
;;       u8* pvmem;  // Pointer to video memory
;;    
;;       //-----Draw original object
;;       //
;;       // Get a pointer to video memory byte for object location
;;       pvmem = cpct_getScreenPtr(CPCT_VMEM_START, o->x, o->y);
;;       // Draw the object
;;       cpct_drawSprite(o->sprite, pvmem, o->width, o->height);
;;    
;;       //-----Draw Inverted object right next to original one
;;       //
;;       // Assuming pvmem points to upper-left byte of the original sprite in
;;       // video memory, calculate a pointer to the bottom-left byte (in video memory).
;;       // Equivalent to: cpct_getScreenPtr(CPCT_VMEM_START, o->x, (o->y + o->height - 1) )
;;       pvmem = cpct_getBottomLeftPtr(pvmem, o->height);
;;       // As we don't want to overwrite the original object, this inverted version will
;;       // be drawn 1 byte to its right (in front of the original). That means moving to 
;;       // the right (adding) a number of bytes equal to the width of the object + 1. 
;;       pvmem += o->width + 1;
;;       // Finally, draw the vertically flipped object. This draw function
;;       // does the drawing bottom-to-top in the video memory. That's the reason
;;       // to have a pointer to the bottom-left.
;;       cpct_drawSpriteHFlipM0(o->sprite, pvmem, o->width, o->height);
;;    }
;; (end code)
;;
;; Destroyed Register values: 
;;     C-bindings - AF, BC, DE, HL
;;   ASM-bindings - AF, BC, DE, HL, IXL
;;
;; Required memory:
;;     C-bindings - 63 bytes
;;   ASM-bindings - 54 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |   microSecs (us)        |        CPU Cycles
;; -----------------------------------------------------------------
;;  Best      | 33 + (15 + 20W)H + 10HH | 132 + (60 + 80W)H + 40HH
;;  Worst     |       Best + 10         |      Best + 40
;; -----------------------------------------------------------------
;;  W=2,H=16  |        923 /  933       |   3692 /  3732
;;  W=4,H=32  |       3103 / 3113       |  12412 / 12452
;; -----------------------------------------------------------------
;; Asm saving |         -25             |        -100
;; -----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes, HH = int((H-1)/8)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Use IXL as counter for sprite rows (B will be used for other operations)
   ld__ixl_b            ;; [2] IXL = Height

   ;; Set Up placeholders to restore sprite width for each new row
   ld     a, c          ;; [1] A = Width
   ld (widthRestore), a ;; [4] Set up Width restoration value in C register for each new sprite row
   ld (addWidth), a     ;; [4] Set up Width to be added to HL for next video memory row to be filled up

   ;; Make HL point to the right-most byte of the first row of the screen to be drawn
   dec    a             ;; [1] A = width - 1
   add_hl_a             ;; [5] HL += width - 1 (Point to last byte at the screen)

   jr  firstbyte        ;; [3] First byte does not require C to be restored nor DE/HL to be changed

nextbyte:
   inc   de             ;; [2] DE++ (Next sprite byte)
   dec   hl             ;; [2] HL-- (Previous byte in video memory. We draw right-to-left)
firstbyte:
   ld     a, (de)                      ;; [2] A = Next sprite byte
   ld     b, a                         ;; [1] B = A (For temporary calculations)
   cpctm_reverse_mode_0_pixels_of_A b  ;; [7] Reverses both pixels of sprite byte in A
   ld  (hl), a                         ;; [2] Save Sprite byte with both pixels reversed

   dec    c             ;; [1]   C-- (One less byte in this row to go)
   jr    nz, nextbyte   ;; [2/3] If C!=0, there are more bytes, so continue with nextbyte

   ;; Finished drawing present sprite row to screen. Count 1 less row
   dec__ixl             ;; [2]   IXL-- (One less sprite row to go)
   jr     z, return     ;; [2/3] if IXL==0, all rows are finished, then return

   ;; Set Up everything for Next Sprite Row

   ;; Make HL Point to the right-most byte of next screen row to be drawn
addWidth = .+1
   ld    bc, #0x0800    ;; [3] BC = 0x800 + width  (Offset from now to right-most byte of next row)
   add   hl, bc         ;; [3] HL += 0x800 + width (HL points to right-most byte of next row)
 
   ;; Check if HL has moved outside of video memory boundaries
   ld     a, h          ;; [1]   Bits 13,12,11 of H become 0 at the same time when moving outside video memory boundaries
   and   #0x38          ;; [2]   Isolate bits 13,12,11 
   jr    nz, nextbyte   ;; [2/3] If A!=0, someone of the 3 bits is not 0, so boundaries have not been crossed

   ;; HL points outside video memory area (last +0x800 crossed boundaries)   
   ;; To wrap up to the start of video memory again, add up +0xC050
   ;; (0xC000 = 48K which means jumping 3 memory banks forward, returning to original memory bank
   ;;  and 0x50 is offset for the start of next pixel line inside next character line)
   ld    bc, #0xC050    ;; [3] BC = 0xC000 + 0x50
   add   hl, bc         ;; [3] HL += 0xC050 (Wrap up HL to make it point again to previous memory bank +0x50)
widthRestore = .+1
   ld     c, #00        ;; [2] Restore Width into C before looping over next row bytes one by one
   jr    nextbyte       ;; [3] Continue with next sprite row
return:
   ;; Ret instruction provided by C/ASM bindings