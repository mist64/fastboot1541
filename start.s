
DATA_OUT := $20 ; bit 5
CLK_OUT  := $10 ; bit 4
VIC_OUT  := $03 ; bits need to be on to keep VIC happy

;----------------------------------------------------------------------
; Hack to generate .PRG file with load address as first word
;----------------------------------------------------------------------
.segment "LOADADDR"
.addr *

;----------------------------------------------------------------------
; Receive one block and run it.
; This code lives around $0190.
;----------------------------------------------------------------------
.segment "PART2"
main:
	sei
	lda #VIC_OUT | DATA_OUT ; CLK=0 DATA=1
	sta $DD00 ; we're not ready to receive

; wait until fast loader got loaded from 18/18 and is active
wait_fast:
	bit $DD00
	bvs wait_fast

	ldx #0
get_rest_loop:
	bit $DD00
	bvc get_rest_loop ; wait for CLK=1
	
; wait for raster
wait_raster:
		lda     $D012
        cmp     #50
        bcc     wait_raster_end
        and     #$07
        cmp     #$02
        beq     wait_raster
wait_raster_end:
	
	lda #VIC_OUT ; CLK=0 DATA=0
	sta $DD00 ; we're ready, start sending!
	pha ; 3 cycles
	pla ; 4 cycles
	bit $00 ; 3 cycles
	lda $DD00 ; get 2 bits into bits 6&7
	lsr
	lsr ; move down by 2 (bits 4&5)
	eor $DD00 ; get 2 more bits
	lsr
	lsr ; move everything down (bits 2-5)
	eor $DD00; get 2 more bits
	lsr
	lsr ; move everything down (bits 0-5)
	eor $DD00 ; get last 2 bits, now 0-7 are populated
	ldy #VIC_OUT | DATA_OUT ; CLK=0 DATA=1
	sty $DD00 ; not ready any more, don't start sending

	sta $0400,x
	inx
	bne get_rest_loop

	jmp *
	
;----------------------------------------------------------------------
; Send an "M-E" to the 1541 that loads track 18, sector 18 into a
; buffer and executes it.
; Then jump to code that receives data.
;----------------------------------------------------------------------
.segment "START"
	lda #$0f
	sta $b9
	sta $b8
	ldx #<memory_execute
	ldy #>memory_execute
	lda #memory_execute_end - memory_execute
	jsr $fdf9 ; filnam
	jsr $f34a ; open
	jmp main

memory_execute:
	 .byte "M-E"
	 .word $0200 + memory_execute_code - memory_execute
	.byte 18 ; track
memory_execute_code:
	lda #18 ; track 18, sector 18
	sta $0e
	sta $0f
	lda #4 ; buffer number
	sta $f9
	jsr $d586       ; read sector
	jmp $0700
memory_execute_end:

;----------------------------------------------------------------------
;----------------------------------------------------------------------
; C64 -> Floppy: direct
; Floppy -> C64: inverted
