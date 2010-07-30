.segment "CODE"

LE9AE := $E9AE

DATA_OUT := $02
CLK_OUT  := $08

start1541:
	lda #CLK_OUT
	sta $1800 ; fast code is running!

	lda #'M'
	jsr send_byte
	lda #'I'
	jsr send_byte
	lda #'S'
	jsr send_byte
	lda #'T'
	jsr send_byte

	jmp *

send_byte:
; first encode
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
