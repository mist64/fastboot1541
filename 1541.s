.segment "CODE"

table1 := $0400
table2 := $0500

LE9AE := $E9AE

DATA_OUT := $02
CLK_OUT  := $08

start1541:
	sei
	lda #CLK_OUT
	sta $1800 ; fast code is running!

; make tables
	ldy #0
table_loop:
	tya
	lsr
	lsr
	lsr
	lsr ; get high nybble
	tax ; to X
	lda bus_encode_table,x ; super-encoded high nybble in Y
	sta table1,y
	tya
	and #$0F ; lower nybble
	eor #3 ; fix up for receiver side XXX this might be the VIC bank?
	tax
	lda bus_encode_table,x ; super-encoded low nybble in A
	sta table2,y
	iny
	bne table_loop

read_loop:
	lda #18 ; track 18, sector 18
	sta $06
	lda #0
	sta $07
	lda #0 ; buffer number
	sta $f9
;	jsr $d586       ; read sector

	ldx #0
send_loop:
selfmod:
	lda $0300,x
	stx save_x+1
	jsr send_byte
save_x:
	ldx #0
	inx
	bne send_loop

	inc selfmod+2

;	jmp *
	inc $07
	jmp read_loop
	
send_byte:
; first encode
	ldx #0
	stx $1800 ; DATA=0, CLK=0 -> we're ready to send!
	tax
	lda table2,x
; then wait for C64 to be ready
L0359:
	ldy $1800
	bne L0359; needs all 0

; then send
	sta $1800
	asl
	and #$0F
	sta $1800
	lda table1,x
	sta $1800
	asl
	and #$0F
	sta $1800

	jmp LE9AE ; CLK=1 10 cycles later
	
bus_encode_table:
; b0 = !b3
; b1 = !b1
; b2 = !b2
; b3 = !b0
	.byte %1111, %0111, %1101, %0101, %1011, %0011, %1001, %0001
	.byte %1110, %0110, %1100, %0100, %1010, %0010, %1000, %0000






