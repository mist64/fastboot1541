
.segment "LOADADDR"
.addr *

.segment "VECTOR"

.byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
.byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

.segment "START"

start:
	nop
	nop
	nop
	lda #$00
	sta $d020

	lda #$0f
	sta $b9
	sta $b8
	ldx #<memory_execute
	ldy #>memory_execute
	lda #memory_execute_end - memory_execute
	jsr $fdf9       ;filnam
	jsr $f34a       ;open

	lda #%00111100
	sta $DD02 ; DDR port A
	
	lda #DATA_OUT | VIC_OUT ; CLK=0 DATA=1
	sta $DD00

wait_fast:
	bit $DD00
	bvs wait_fast
; the fast code is running now!

	jmp get_rest
	
.if 0
inf:
	lda $DD00
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	tax
	inc $0400,x
	jmp inf
.endif
	
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

.segment "MAIN"
; declare VIC bank select pins (#0 & #1)  as input so we don't
; switch VIC banks all the time when we write to the IEC bus
load:

;----------------------------------------
; fast in byte
;----------------------------------------
DATA_OUT := $20 ; bit 5
CLK_OUT  := $10 ; bit 4
VIC_OUT  := $03 ; bits need to be on to keep VIC happy

get_rest:
	ldx #0
get_rest_loop:
	bit $DD00
	bvc get_rest_loop ; wait for CLK=1
	
; wait for raster
wait_raster:
	lda $D012
	cmp #50
	bcc wait_raster_end
; XXX this doesn't work right yet :( - restrict to border
;	and #$07
;	cmp #$02
;	beq wait_raster
	jmp wait_raster
wait_raster_end:
	
	lda #VIC_OUT ; CLK=0 DATA=0
	sta $DD00
	pha ; 3 cycles
	pla ; 4 cycles
	bit $EA ; 3 cycles
	lda $DD00 ; get 2 bits into bits 6&7
	lsr a
	lsr a ; move down by 2 (bits 4&5)
	eor $DD00 ; get 2 more bits
	lsr a
	lsr a ; move everything down (bits 2-5)
	eor $DD00; get 2 more bits
	lsr a
	lsr a ; move everything down (bits 0-5)
	eor $DD00 ; get last 2 bits, now 0-7 are populated
	pha
	lda #DATA_OUT | VIC_OUT ; CLK=0 DATA=1
	sta $DD00
	pla
	eor #$03

	sta $0400,x
	inx
	bne get_rest_loop

	jmp *

; C64 -> Floppy: direct
; Floppy -> C64: inverted
