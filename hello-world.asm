INCLUDE "hardware.inc"

SpriteBuffer equ $D000
VBlankInterruptHandler equ $FF80

; copy BC bytes from HL to DE (macro for the Z80 ldir instruction)
macro LDIR
push af
LdirLoop:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, LdirLoop
pop af
endm

SECTION "VBlankinterrupt", ROM0[$0040]
	jp VBlankInterruptHandler

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Copy our DMACopy code to [VBlankInterruptHandler] since only $FF80-FFFE is accessible during DMA
	ld bc, DMACopyEnd - DMACopy
	ld hl, DMACopy
	ld de, VBlankInterruptHandler
	LDIR

	; Do not turn the LCD off outside of VBlank
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
CopyTilesToVRAM:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTilesToVRAM

ld de, Sprites
ld hl, _VRAM
ld bc, SpritesEnd - Sprites

CopySpritesToVRAM:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopySpritesToVRAM


ld de, SpriteBuffer
ld bc, 40 ; 40 tiles in our buffer get copied to OAM RAM

ZeroAllSprites:
	ld a, 0
	ld [de], a
	inc de
	ld [de], a
	inc de
	inc de
	inc de
	dec bc

	ld a, b
	or a, c
	jp nz, ZeroAllSprites

PositionSprites:
	ld b, 50 ; x
	ld c, 25 ; y
	ld a, 0 ; source sprite number
	ld e, 0 ; destination sprite number
	ld h, 0 ; attributes
	call SetSprite
	
	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap

CopyTilemap:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTilemap

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11_01_10_00

	ld [rBGP], a
	ld a, %11_01_10_00
	ld [rOBP0], a

	ld a, %0000_0001 ; turn on vblank interrupt
	ld [$FFFF], a
	ei

	
	; ld b, 0
	; ld hl, rSCX

ld b, 50

Done:
; 	ld a, [rLY]
; 	cp 144
; 	jp c, Done

; 	dec b
; 	ld [hl], b

	inc b ; x
	ld c, 25 ; y
	ld a, 0 ; source sprite number
	ld e, 0 ; destination sprite number
	ld h, 0 ; attributes
	call SetSprite

	ld a, 255
	ld d, 20
Wait:
	dec a
	jp nz, Wait
	dec d
	jp nz, Wait

	ld a, 255
	jp Done

; A=source sprite number
; B=X, C=Y
; E=dest sprite number
; H=attributes
SetSprite:
	ld d, h
	push af
		rlca ; multiply the sprite number by 4 to get the byte offset into SpriteBuffer
		rlca
		push hl
		push de
			push hl
				ld hl, SpriteBuffer ; The address of our virtual sprite buffer which we will DMA to video memory during vblank
				ld l, a ; a is the byte offset from SpriteBuffer of the sprite data to copy
				ld a, c ; write the y-coord
				ld [hli], a
				ld a, b ; write the x-coord
				ld [hli], a
				ld a, e ; write the sprite number
				ld [hli], a
			pop de
			ld a, d ; write the sprite attributes
			ld [hli], a
		pop de
		pop hl
	pop af
	ret

DMACopy:
	ld a, SpriteBuffer/256 ; top byte of source address
	ld [rDMA], a ; start the DMA
	ld a, $28 ; amount to wait
DMACopyWait:
	dec a
	jr nz, DMACopyWait
	reti
DMACopyEnd:

SECTION "Sprite data", ROM0

Sprites:
		db $3f,$3f, $7f,$0f, $32,$3d, $17,$1d, $17,$1d, $21,$3e, $3f,$20, $3f,$1f
SpritesEnd:

SECTION "Tile data", ROM0

Tiles:
		db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00
		db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $07,$07, $08,$0f, $17,$18
		db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $80,$80, $60,$e0, $10,$f0
		db $3f,$3f, $7f,$0f, $32,$3d, $17,$1d, $17,$1d, $21,$3e, $3f,$20, $3f,$1f
		db $c8,$b8, $f4,$cc, $7c,$b4, $3e,$de, $3f,$d9, $ff,$39, $ff,$91, $fe,$c6
		db $3f,$3e, $1f,$10, $1f,$1f, $77,$7c, $ef,$b8, $ff,$b8, $f7,$bc, $73,$7f
		db $f8,$18, $f8,$78, $e4,$fc, $c2,$7e, $e2,$3e, $e2,$3e, $ce,$72, $fc,$84
		db $3f,$1f, $1f,$0f, $1f,$0b, $0f,$05, $0f,$07, $13,$1d, $2e,$33, $3f,$3f
		db $fc,$f8, $fc,$f8, $fc,$f4, $f8,$f0, $f8,$f8, $3c,$c4, $fc,$04, $fc,$fc
TilesEnd:

SECTION "Tilemap", ROM0
	
Tilemap:
		db $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $03, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $05, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $07, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
TilemapEnd:

	
	
	

	
	
	
	
	
