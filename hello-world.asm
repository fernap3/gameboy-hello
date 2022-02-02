INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

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
CopyTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTiles

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
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11_10_01_00
	; xor a, $ff
	ld [rBGP], a

	
	ld b, 0
	ld hl, rSCX

Done:
	ld a, [rLY]
	cp 144
	jp c, Done

	dec b
	ld [hl], b

	ld a, 255
	ld d, 10
Wait:
	dec a
	jp nz, Wait
	dec d
	jp nz, Wait

	ld a, 255
	jp Done

	SECTION "Tile data", ROM0

	Tiles:
	db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$07, $07,$08, $0f,$17
	db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$80, $80,$60, $e0,$10
	db $00,$3f, $70,$7f, $0f,$32, $0a,$17, $0a,$17, $1f,$21, $1f,$3f, $20,$3f
	db $70,$c8, $38,$f4, $c8,$7c, $e0,$3e, $e6,$3f, $c6,$ff, $6e,$ff, $38,$fe
	db $01,$3f, $0f,$1f, $00,$1f, $0b,$77, $57,$ef, $47,$ff, $4b,$f7, $0c,$73
	db $e0,$f8, $80,$f8, $18,$e4, $bc,$c2, $dc,$e2, $dc,$e2, $bc,$ce, $78,$fc
	db $20,$3f, $10,$1f, $14,$1f, $0a,$0f, $08,$0f, $0e,$13, $1d,$2e, $00,$3f
	db $04,$fc, $04,$fc, $08,$fc, $08,$f8, $00,$f8, $f8,$3c, $f8,$fc, $00,$fc
	TilesEnd:
	SECTION "Tilemap", ROM0
	
	Tilemap:
	db $00, $01
	db $02, $03
	db $04, $05
	db $06, $07
	TilemapEnd:
	
	
	

	
	
	
	
	
