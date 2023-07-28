HackDetection::
	farcall LoadOverworldFont
	call HackDetectionInitScreen
	call EnableLCD
	call HackDetectionWramCheck
	call HackDetectionRomCheck
	call DisableLCD
	ret

HackDetectionInitScreen:
	call HackDetectionSetPals
	ld de, .string_Wait
	ld hl, vBGMap0 + $106
	ld c, 7
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop
	ret

.string_Wait
	db "Wait..."

HackDetectionWramCheck:
	ld hl, WRAM0_Begin
	ld bc, WRAM1_End - WRAM0_Begin
:	ld [hl], $69
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, :-

	ld hl, WRAM0_Begin
	ld bc, WRAM1_End - WRAM0_Begin
.loop
	ld a, [hli]
	cp $69
	jr z, .ok
	call HackDetectionTrigger

.ok
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

HackDetectionRomCheck:
	ld de, RamCodeStart
	ld hl, WRAM1_Begin
	ld c, HackDetectionRomCheckFromRam.end - HackDetectionRomCheckFromRam
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop
	jp WRAM1_Begin

RamCodeStart:
	LOAD "RAM code", WRAMX
HackDetectionRomCheckFromRam:
	ld l, 0
	ld h, l
	ld de, VBlank
	ld bc, $4000 - VBlank
.rom0Loop
	push bc
	ld a, [de]
	inc de
	ld c, a
	ld b, 0
	add hl, bc
	pop bc
	dec bc
	ld a, b
	or c
	jr nz, .rom0Loop
	xor a
.romLoop
	ld [WRAM0_Begin], a
	rst Bankswitch
	ld de, $4000
	ld bc, $4000
.romXLoop
	push bc
	ld a, [de]
	inc de
	ld c, a
	ld b, 0
	add hl, bc
	pop bc
	dec bc
	ld a, b
	or c
	jr nz, .romXLoop
	ld a, [WRAM0_Begin]
	inc a
	cp BANK(HackDetectionRomCheck)
	jr nz, .romLoop
	ld a, $28
	cp l
	jr nz, .hackDetected
	ld a, $8f
	cp h
	jr nz, .hackDetected
	ld a, BANK(HackDetectionRomCheck)
	rst Bankswitch
	ret

.hackDetected
	farcall HackDetectionTrigger
.end
	ENDL

HackDetectionTrigger:
	call DisableLCD
	call HackDetectionSetMaps
	call HackDetectionSetPals
	call EnableLCD
.trap
	jp .trap

HackDetectionSetMaps:
	ld de, HackDetectionTilemap
	call .copyTilesToVram
	
	ld a, 1
	ldh [rVBK], a
	ld de, HackDetectionAttrmap
	call .copyTilesToVram
	ld a, 0
	ldh [rVBK], a
	ret

.copyTilesToVram
	ld hl, vBGMap0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	inc b
	inc c
	jr .handleLoop
.copyByte
	ld a, [de]
	ld [hli], a
	inc de
.handleLoop
	dec c
	jr nz, .checkSkip
	dec b
	jr nz, .checkSkip
	ret

.checkSkip
	ld a, l
	and SCREEN_WIDTH
	cp SCREEN_WIDTH
	jr c, .copyByte
;.skip
	push de
	ld de, BG_MAP_WIDTH - SCREEN_WIDTH
	add hl, de
	pop de
	jr .copyByte

HackDetectionSetPals:
	ld hl, HackDetectionPalettes
	ld a, 1 << rBGPI_AUTO_INCREMENT
	ldh [rBGPI], a
	ld c, LOW(rBGPD)
	ld b, 4 / 2
.bgp
rept (1 palettes) * 2
	ld a, [hli]
	ldh [c], a
endr

	dec b
	jr nz, .bgp
	ret

HackDetectionPalettes:
INCLUDE "gfx/intro/hack_detection.pal"

HackDetectionTilemap:
INCBIN "gfx/intro/hack_detection.tilemap"

HackDetectionAttrmap:
INCBIN "gfx/intro/hack_detection.attrmap"