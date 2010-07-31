
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

	ldx #4
	ldy #0
get_rest_loop:
	stx save_x1+1
get_rest_loop2:
	bit $DD00
	bvc get_rest_loop2 ; wait for CLK=1
	
; wait for raster
wait_raster:
	lda $D012
	cmp #50
	bcc wait_raster_end
	and #$07
	cmp #$02
	beq wait_raster
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

	ldx #VIC_OUT | DATA_OUT ; CLK=0 DATA=1
	stx $DD00 ; not ready any more, don't start sending

selfmod1:
	sta $0400,y
	iny
	bne get_rest_loop2

	inc selfmod1+2
save_x1:
	ldx #0
	dex
	bne get_rest_loop

inf:
	inc $d800
	jmp inf
;	jmp get_rest_loop
	
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
	 .word $04A0 + 2
memory_execute_end:

;----------------------------------------------------------------------
;----------------------------------------------------------------------
; C64 -> Floppy: direct
; Floppy -> C64: inverted

.segment "FCODE"

LE9AE := $E9AE

F_DATA_OUT := $02
F_CLK_OUT  := $08

start1541:
	sei
	lda #F_CLK_OUT
	sta $1800 ; fast code is running!

	ldx #0
send_loop:
selfmod2:
	lda $0300,x
	stx save_x2+1
	jsr send_byte
save_x2:
	ldx #0
	inx
	bne send_loop

	inc selfmod2+2
;	jmp *
	jmp send_loop
	
send_byte:
; first encode
	eor #3 ; fix up for receiver side XXX this might be the VIC bank?
	pha ; save original
	lsr
	lsr
	lsr
	lsr ; get high nybble
	tax ; to X
	ldy bus_encode_table,x ; super-encoded high nybble in Y
	ldx #0
	stx $1800 ; DATA=0, CLK=0 -> we're ready to send!
	pla
	and #$0F ; lower nybble
	tax
	lda bus_encode_table,x ; super-encoded low nybble in A
; then wait for C64 to be ready
L0359:
	ldx $1800
	bne L0359; needs all 0

; then send
	sta $1800
	asl
	and #$0F
	sta $1800
	tya
	nop
	sta $1800
	asl
	and #$0F
	sta $1800

	jmp LE9AE ; CLK=1 10 cycles later
	
bus_encode_table:
	.byte %1111, %0111, %1101, %0101, %1011, %0011, %1001, %0001
	.byte %1110, %0110, %1100, %0100, %1010, %0010, %1000, %0000
