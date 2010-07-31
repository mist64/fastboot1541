
TARGET := $0400
TRACK := 18

DATA_OUT := $20 ; bit 5
CLK_OUT  := $10 ; bit 4
VIC_OUT  := $03 ; bits need to be on to keep VIC happy

seccnt = 2

;----------------------------------------------------------------------
; Hack to generate .PRG file with load address as first word
;----------------------------------------------------------------------
.segment "LOADADDR"
.addr *

;----------------------------------------------------------------------
; Send an "M-E" to the 1541 that jumps to floppy code.
; Then receive one block and run it.
; This code lives around $0190.
;----------------------------------------------------------------------
.segment "PART2"
main:
	lda #$0f
	sta $b9
	sta $b8
	ldx #<memory_execute
	ldy #>memory_execute
	lda #memory_execute_end - memory_execute
	jsr $fdf9 ; filnam
	jsr $f34a ; open

	sei
	lda #VIC_OUT | DATA_OUT ; CLK=0 DATA=1
	sta $DD00 ; we're not ready to receive

; wait until floppy code is active
wait_fast:
	bit $DD00
	bvs wait_fast

	lda #sector_table_end - sector_table ; number of sectors
	sta seccnt
	ldy #0
get_rest_loop:
	bit $DD00
	bvc get_rest_loop ; wait for CLK=1
	
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
	sta TARGET,y
	iny
	bne get_rest_loop

	inc selfmod1+2
	dec seccnt
	bne get_rest_loop

inf:
	jmp inf

.segment "VECTOR"
; these bytes will be overwritten by the KERNAL stack while loading
; let's set them all to "2" so we have a chance that this will work
; on a modified KERNAL
	.byte 2,2,2,2,2,2,2,2,2,2,2
; This is the vector to the start of the code; RTS will jump to $0203
	.byte 2,2
; These bytes are on top of the return value on the stack. We could use
; them for data; or, fill them with "2" so different versions of KERNAL
; might work
	.byte 2,2,2,2

.segment "CMD"
memory_execute:
	 .byte "M-E"
	 .word $0480 + 2
memory_execute_end:

;----------------------------------------------------------------------
; Jump to code that receives data.
;----------------------------------------------------------------------
.segment "START"
	jmp main

;----------------------------------------------------------------------
;----------------------------------------------------------------------
; C64 -> Floppy: direct
; Floppy -> C64: inverted
;----------------------------------------------------------------------
;----------------------------------------------------------------------

.segment "FCODE"

F_DATA_OUT := $02
F_CLK_OUT  := $08

sec_index := $05
ftemp := $1D

start1541:
	lda #F_CLK_OUT
	sta $1800 ; fast code is running!

	lda #0 ; sector
	sta sec_index
	sta $f9 ; buffer $0300 for the read
	lda #TRACK ; track
	sta $06
read_loop:
	ldx sec_index
	lda sector_table,x
	inc sec_index
	bmi end
	sta $07
	cli
	jsr $d586       ; read sector
	sei

send_loop:
; we can use $f9 as the byte counter, since we'll return it to 0
; so it holds the correct buffer number "0" when we read the next sector
	ldx $f9
	lda $0300,x

; first encode
	eor #3 ; fix up for receiver side (VIC bank!)
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

	jsr $E9AE ; CLK=1 10 cycles later

	inc $f9
	bne send_loop
	beq read_loop

end:
	jmp *

bus_encode_table:
	.byte %1111, %0111, %1101, %0101, %1011, %0011, %1001, %0001
	.byte %1110, %0110, %1100, %0100, %1010, %0010, %1000, %0000

sector_table:
	.byte 0,1,2,3,$FF
sector_table_end: