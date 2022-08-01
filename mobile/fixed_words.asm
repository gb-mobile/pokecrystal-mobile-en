; These functions seem to be related to the selection of preset phrases
; for use in mobile communications.  Annoyingly, they separate the
; Battle Tower function above from the data it references.
Function11c05d:
	ld a, e
	or d
	jr z, .error
	ld a, e
	and d
	cp $ff
	jr z, .error
	push hl
	call CopyMobileEZChatToC608
	pop hl
	call PlaceString
	and a
	ret

.error
	ld c, l
	ld b, h
	scf
	ret

Function11c075:
	push de
	ld a, c
	call Function11c254
	pop de
	ld bc, wcd36
	call Function11c08f
	ret

Unreferenced_Function11c082:
	push de
	ld a, c
	call Function11c254
	pop de
	ld bc, wcd36
	call PrintEZChatBattleMessage
	ret

Function11c08f:
	ld l, e
	ld h, d
	push hl
	ld a, 3
.loop
	push af
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld d, a
	inc bc
	push bc
	call Function11c05d
	jr c, .okay
	inc bc

.okay
	ld l, c
	ld h, b
	pop bc
	pop af
	dec a
	jr nz, .loop
	pop hl
	ld de, 2 * SCREEN_WIDTH
	add hl, de
	ld a, $3
.loop2
	push af
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld d, a
	inc bc
	push bc
	call Function11c05d
	jr c, .okay2
	inc bc

.okay2
	ld l, c
	ld h, b
	pop bc
	pop af
	dec a
	jr nz, .loop2
	ret

PrintEZChatBattleMessage:
; Use up to 6 words from bc to print text starting at de.
	; Preserve $cf63, $cf64
	ld a, [wJumptableIndex]
	ld l, a
	ld a, [wcf64]
	ld h, a
	push hl
	; reset value at c618 (not preserved)
	ld hl, $c618
	ld a, $0
	ld [hli], a
	; preserve de
	push de
	; $cf63 keeps track of which line we're on (0, 1, or 2)
	; $cf64 keeps track of how much room we have left in the current line
	xor a
	ld [wJumptableIndex], a
	ld a, 18
	ld [wcf64], a
	ld a, $6 ; up to 6 times
.loop
	push af
	; load the 2-byte word data pointed to by bc
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld d, a
	inc bc
	; if $0000, we're done
	or e
	jr z, .done
	; preserving hl and bc, get the length of the word
	push hl
	push bc
	call CopyMobileEZChatToC608
	call GetLengthOfWordAtC608
	ld e, c
	pop bc
	pop hl
	; if the functions return 0, we're done
	ld a, e
	or a
	jr z, .done
.loop2
	; e contains the length of the word
	; add 1 for the space, unless we're at the start of the line
	ld a, [wcf64]
	cp 18
	jr z, .skip_inc
	inc e

.skip_inc
	; if the word fits, put it on the same line
	cp e
	jr nc, .same_line
	; otherwise, go to the next line
	ld a, [wJumptableIndex]
	inc a
	ld [wJumptableIndex], a
	; if we're on line 2, insert "<NEXT>"
	ld [hl], "<NEXT>"
	rra
	jr c, .got_line_terminator
	; else, insert "<CONT>"
	ld [hl], "<CONT>"

.got_line_terminator
	inc hl
	; init the next line, holding on to the same word
	ld a, 18
	ld [wcf64], a
	dec e
	jr .loop2

.same_line
	; add the space, unless we're at the start of the line
	cp 18
	jr z, .skip_space
	ld [hl], " "
	inc hl

.skip_space
	; deduct the length of the word
	sub e
	ld [wcf64], a
	ld de, $c608
.place_string_loop
	; load the string from de to hl
	ld a, [de]
	cp "@"
	jr z, .done
	inc de
	ld [hli], a
	jr .place_string_loop

.done
	; next word?
	pop af
	dec a
	jr nz, .loop
	; we're finished, place "<DONE>"
	ld [hl], "<DONE>"
	; now, let's place the string from c618 to bc
	pop bc
	ld hl, $c618
	call PlaceHLTextAtBC
	; restore the original values of $cf63 and $cf64
	pop hl
	ld a, l
	ld [wJumptableIndex], a
	ld a, h
	ld [wcf64], a
	ret

GetLengthOfWordAtC608:
	ld c, $0
	ld hl, $c608
.loop
	ld a, [hli]
	cp "@"
	ret z
	inc c
	jr .loop

CopyMobileEZChatToC608:
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld a, "@"
	ld hl, $c608
	ld bc, NAME_LENGTH
	call ByteFill
	ld a, d
	and a
	jr z, .get_name
	ld hl, MobileEZChatCategoryPointers
	dec d
	sla d
	ld c, d
	ld b, $0
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	push bc
	pop hl
	ld c, e
	ld b, $0
	sla c
	rl b
	sla c
	rl b
	sla c
	rl b
	add hl, bc
	ld bc, NAME_LENGTH_JAPANESE - 1
.copy_string
	ld de, $c608
	call CopyBytes
	ld de, $c608
	pop af
	ldh [rSVBK], a
	ret

.get_name
	ld a, e
	ld [wNamedObjectIndexBuffer], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld bc, MON_NAME_LENGTH - 1
	jr .copy_string

Function11c1ab:
	ldh a, [hInMenu]
	push af
	ld a, $1
	ldh [hInMenu], a
	call Function11c1b9
	pop af
	ldh [hInMenu], a
	ret

Function11c1b9:
	call .InitKanaMode
	ldh a, [rSVBK]
	push af
	ld a, $5
	ldh [rSVBK], a
	call EZChat_MasterLoop
	pop af
	ldh [rSVBK], a
	ret

.InitKanaMode:
	xor a
	ld [wJumptableIndex], a
	ld [wcf64], a
	ld [wcf65], a
	ld [wcf66], a
	ld [wcd23], a
	ld [wcd20], a
	ld [wcd21], a
	ld [wcd22], a
	ld [wcd35], a
	ld [wcd2b], a
	ld a, $ff
	ld [wcd24], a
	ld a, [wMenuCursorY]
	dec a
	call Function11c254
	call ClearBGPalettes
	call ClearSprites
	call ClearScreen
	call Function11d323
	call SetPalettes
	call DisableLCD
	ld hl, GFX_11d67e
	ld de, vTiles2
	ld bc, $60
	call CopyBytes
	ld hl, LZ_11d6de
	ld de, vTiles0
	call Decompress
	call EnableLCD
	farcall ReloadMapPart
	farcall ClearSpriteAnims
	farcall LoadPokemonData
	farcall Pokedex_ABCMode
	ldh a, [rSVBK]
	push af
	ld a, $5
	ldh [rSVBK], a
	ld hl, $c6d0
	ld de, wLYOverrides
	ld bc, $100
	call CopyBytes
	pop af
	ldh [rSVBK], a
	call EZChat_GetCategoryWordsByKana
	call EZChat_GetSeenPokemonByKana
	ret

Function11c254:
	push af
	ld a, BANK(s4_a007)
	call GetSRAMBank
	ld hl, s4_a007
	pop af
	sla a
	sla a
	ld c, a
	sla a
	add c
	ld c, a
	ld b, $0
	add hl, bc
	ld de, wcd36
	ld bc, 12
	call CopyBytes
	call CloseSRAM
	ret

EZChat_ClearBottom12Rows:
	ld a, "　"
	hlcoord 0, 6
	ld bc, (SCREEN_HEIGHT - 6) * SCREEN_WIDTH
	call ByteFill
	ret

EZChat_MasterLoop:
.loop
	call JoyTextDelay
	ldh a, [hJoyPressed]
	ldh [hJoypadPressed], a
	ld a, [wJumptableIndex]
	bit 7, a
	jr nz, .exit
	call .DoJumptableFunction
	farcall PlaySpriteAnimations
	farcall ReloadMapPart
	jr .loop

.exit
	farcall ClearSpriteAnims
	call ClearSprites
	ret

.DoJumptableFunction:
	jumptable .Jumptable, wJumptableIndex

.Jumptable:
	dw .SpawnObjects ; 00
	dw .InitRAM ; 01
	dw Function11c35f ; 02
	dw Function11c373 ; 03
	dw Function11c3c2 ; 04
	dw Function11c3ed ; 05
	dw Function11c52c ; 06
	dw Function11c53d ; 07
	dw Function11c658 ; 08
	dw Function11c675 ; 09
	dw Function11c9bd ; 0a
	dw Function11c9c3 ; 0b
	dw Function11caad ; 0c
	dw Function11cab3 ; 0d
	dw Function11cb52 ; 0e
	dw Function11cb66 ; 0f
	dw Function11cbf5 ; 10
	dw Function11ccef ; 11
	dw Function11cd04 ; 12
	dw Function11cd20 ; 13
	dw Function11cd54 ; 14
	dw Function11ce0b ; 15
	dw Function11ce2b ; 16

.SpawnObjects:
	depixel 3, 1, 2, 5
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	depixel 8, 1, 2, 5

	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $1
	ld [hl], a

	depixel 9, 2, 2, 0
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $3
	ld [hl], a

	depixel 10, 16
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $4
	ld [hl], a

	depixel 10, 4
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $5
	ld [hl], a

	depixel 10, 2
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $2
	ld [hl], a

	ld hl, wcd23
	set 1, [hl]
	set 2, [hl]
	jp Function11cfb5

.InitRAM:
	ld a, $9
	ld [wcd2d], a
	ld a, $2
	ld [wcd2e], a
	ld [wcd2f], a
	ld [wcd30], a
	ld de, wcd2d
	call Function11cfce
	jp Function11cfb5

Function11c35f:
	ld hl, wcd2f
	inc [hl]
	inc [hl]
	dec hl
	dec hl
	dec [hl]
	push af
	ld de, wcd2d
	call Function11cfce
	pop af
	ret nz
	jp Function11cfb5

Function11c373:
	ld hl, wcd30
	inc [hl]
	inc [hl]
	dec hl
	dec hl
	dec [hl]
	push af
	ld de, wcd2d
	call Function11cfce
	pop af
	ret nz
	call Function11c38a
	jp Function11cfb5

Function11c38a:
	ld hl, Unknown_11c986
	ld bc, wcd36
	ld a, $6
.asm_11c392
	push af
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	push de
	pop hl
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	inc bc
	ld d, a
	push bc
	or e
	jr z, .asm_11c3af
	ld a, e
	and d
	cp $ff
	jr z, .asm_11c3af
	call Function11c05d
	jr .asm_11c3b5
.asm_11c3af
	ld de, String_11c3bc
	call PlaceString
.asm_11c3b5
	pop bc
	pop hl
	pop af
	dec a
	jr nz, .asm_11c392
	ret

String_11c3bc:
	db "ーーーーー@"

Function11c3c2:
	call EZChat_ClearBottom12Rows
	ld de, Unknown_11cfbe
	call Function11d035
	hlcoord 1, 7
	ld de, String_11c4db
	call PlaceString
	hlcoord 1, 16
	ld de, String_11c51b
	call PlaceString
	call Function11c4be
	ld hl, wcd23
	set 0, [hl]
	ld hl, wcd24
	res 0, [hl]
	call Function11cfb5

Function11c3ed:
	ld hl, wcd20 ; wcd20
	ld de, hJoypadPressed
	ld a, [de]
	and $8
	jr nz, .asm_11c426
	ld a, [de]
	and $2
	jr nz, .asm_11c41a
	ld a, [de]
	and $1
	jr nz, .asm_11c42c
	ld de, hJoyLast
	ld a, [de]
	and $40
	jr nz, .asm_11c47c
	ld a, [de]
	and $80
	jr nz, .asm_11c484
	ld a, [de]
	and $20
	jr nz, .asm_11c48c
	ld a, [de]
	and $10
	jr nz, .asm_11c498
	ret

.asm_11c41a
	call PlayClickSFX
.asm_11c41d
	ld hl, wcd24
	set 0, [hl]
	ld a, $c
	jr .asm_11c475
.asm_11c426
	ld a, $8
	ld [wcd20], a ; wcd20
	ret

.asm_11c42c
	ld a, [wcd20] ; wcd20
	cp $6
	jr c, .asm_11c472
	sub $6
	jr z, .asm_11c469
	dec a
	jr z, .asm_11c41d
	ld hl, wcd36
	ld c, $c
	xor a
.asm_11c440
	or [hl]
	inc hl
	dec c
	jr nz, .asm_11c440
	and a
	jr z, .asm_11c460
	ld de, Unknown_11cfba
	call Function11cfce
	decoord 1, 2
	ld bc, wcd36
	call Function11c08f
	ld hl, wcd24
	set 0, [hl]
	ld a, $e
	jr .asm_11c475
.asm_11c460
	ld hl, wcd24
	set 0, [hl]
	ld a, $11
	jr .asm_11c475
.asm_11c469
	ld hl, wcd24
	set 0, [hl]
	ld a, $a
	jr .asm_11c475
.asm_11c472
	call Function11c4a5
.asm_11c475
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.asm_11c47c
	ld a, [hl]
	cp $3
	ret c
	sub $3
	jr .asm_11c4a3
.asm_11c484
	ld a, [hl]
	cp $6
	ret nc
	add $3
	jr .asm_11c4a3
.asm_11c48c
	ld a, [hl]
	and a
	ret z
	cp $3
	ret z
	cp $6
	ret z
	dec a
	jr .asm_11c4a3
.asm_11c498
	ld a, [hl]
	cp $2
	ret z
	cp $5
	ret z
	cp $8
	ret z
	inc a
.asm_11c4a3
	ld [hl], a
	ret

Function11c4a5:
	ld hl, wcd23
	res 0, [hl]
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c4b7
	xor a
	ld [wcd21], a
	ld a, $6
	ret

.asm_11c4b7
	xor a
	ld [wcd22], a
	ld a, $15
	ret

Function11c4be:
	ld a, $1
	hlcoord 0, 6, wAttrMap
	ld bc, $a0
	call ByteFill
	ld a, $7
	hlcoord 0, 14, wAttrMap
	ld bc, $28
	call ByteFill
	farcall ReloadMapPart
	ret

String_11c4db:
	db   "Combine 6 words.";"６つのことば¯くみあわせます"
	next "Select the space";"かえたいところ¯えらぶと　でてくる"
	next "to change and";"ことばのグループから　いれかえたい"
	next "choose a new word.";"たんご¯えらんでください"
	db   "@"

String_11c51b:
	db "RESET　QUIT　　OK@";"ぜんぶけす　やめる　　　けってい@"

Function11c52c:
	call EZChat_ClearBottom12Rows
	call EZChat_PlaceCategoryNames
	call Function11c618
	ld hl, wcd24
	res 1, [hl]
	call Function11cfb5

Function11c53d:
	ld hl, wcd21
	ld de, hJoypadPressed

	ld a, [de]
	and START
	jr nz, .start

	ld a, [de]
	and SELECT
	jr nz, .select

	ld a, [de]
	and B_BUTTON
	jr nz, .b

	ld a, [de]
	and A_BUTTON
	jr nz, .a

	ld de, hJoyLast

	ld a, [de]
	and D_UP
	jr nz, .up

	ld a, [de]
	and D_DOWN
	jr nz, .down

	ld a, [de]
	and D_LEFT
	jr nz, .left

	ld a, [de]
	and D_RIGHT
	jr nz, .right

	ret

.a
	ld a, [wcd21]
	cp 15
	jr c, .got_category
	sub $f
	jr z, .done
	dec a
	jr z, .mode
	jr .b

.start
	ld hl, wcd24
	set 0, [hl]
	ld a, $8
	ld [wcd20], a ; wcd20

.b
	ld a, $4
	jr .go_to_function

.select
	ld a, [wcd2b]
	xor $1
	ld [wcd2b], a
	ld a, $15
	jr .go_to_function

.mode
	ld a, $13
	jr .go_to_function

.got_category
	ld a, $8

.go_to_function
	ld hl, wcd24
	set 1, [hl]
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.done
	ld a, [wcd20] ; wcd20
	call Function11ca6a
	call PlayClickSFX
	ret

.up
	ld a, [hl]
	cp $3
	ret c
	sub $3
	jr .finish_dpad

.down
	ld a, [hl]
	cp $f
	ret nc
	add $3
	jr .finish_dpad

.left
	ld a, [hl]
	and a
	ret z
	cp $3
	ret z
	cp $6
	ret z
	cp $9
	ret z
	cp $c
	ret z
	cp $f
	ret z
	dec a
	jr .finish_dpad

.right
	ld a, [hl]
	cp $2
	ret z
	cp $5
	ret z
	cp $8
	ret z
	cp $b
	ret z
	cp $e
	ret z
	cp $11
	ret z
	inc a

.finish_dpad
	ld [hl], a
	ret

EZChat_PlaceCategoryNames:
	ld de, MobileEZChatCategoryNames
	ld bc, Coords_11c63a
	ld a, 15
.loop
	push af
	ld a, [bc]
	inc bc
	ld l, a
	ld a, [bc]
	inc bc
	ld h, a
	push bc
	call PlaceString
	; The category names are padded with "@".
	; To find the next category, the system must
	; find the first character at de that is not "@".
.find_next_string_loop
	inc de
	ld a, [de]
	cp "@"
	jr z, .find_next_string_loop
	pop bc
	pop af
	dec a
	jr nz, .loop
	hlcoord 1, 17
	ld de, EZChatString_Stop_Mode_Cancel
	call PlaceString
	ret

Function11c618:
	ld a, $2
	hlcoord 0, 6, wAttrMap
	ld bc, $c8
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatString_Stop_Mode_Cancel:
	db "ERASE　MODE　　CANCEL@";"けす　　　　モード　　　やめる@"

Coords_11c63a:
	dwcoord  1,  7
	dwcoord  7,  7
	dwcoord 13,  7
	dwcoord  1,  9
	dwcoord  7,  9
	dwcoord 13,  9
	dwcoord  1, 11
	dwcoord  7, 11
	dwcoord 13, 11
	dwcoord  1, 13
	dwcoord  7, 13
	dwcoord 13, 13
	dwcoord  1, 15
	dwcoord  7, 15
	dwcoord 13, 15

Function11c658:
	call EZChat_ClearBottom12Rows
	call Function11c770
	ld de, Unknown_11cfc2
	call Function11d035
	call Function11c9ab
	call Function11c7bc
	call Function11c86e
	ld hl, wcd24
	res 3, [hl]
	call Function11cfb5

Function11c675:
	ld hl, wMobileCommsJumptableIndex
	ld de, hJoypadPressed
	ld a, [de]
	and A_BUTTON
	jr nz, .a
	ld a, [de]
	and B_BUTTON
	jr nz, .b
	ld a, [de]
	and START
	jr nz, .start
	ld a, [de]
	and SELECT
	jr z, .select

	ld a, [wcd26]
	and a
	ret z
	sub $c
	jr nc, .asm_11c699
	xor a
.asm_11c699
	ld [wcd26], a
	jr .asm_11c6c4

.start
	ld hl, wcd28
	ld a, [wcd26]
	add $c
	cp [hl]
	ret nc
	ld [wcd26], a
	ld a, [hl]
	ld b, a
	ld hl, wMobileCommsJumptableIndex
	ld a, [wcd26]
	add [hl]
	jr c, .asm_11c6b9
	cp b
	jr c, .asm_11c6c4
.asm_11c6b9
	ld a, [wcd28]
	ld hl, wcd26
	sub [hl]
	dec a
	ld [wMobileCommsJumptableIndex], a
.asm_11c6c4
	call Function11c992
	call Function11c7bc
	call Function11c86e
	ret

.select
	ld de, hJoyLast
	ld a, [de]
	and D_UP
	jr nz, .asm_11c708
	ld a, [de]
	and D_DOWN
	jr nz, .asm_11c731
	ld a, [de]
	and D_LEFT
	jr nz, .asm_11c746
	ld a, [de]
	and D_RIGHT
	jr nz, .asm_11c755
	ret

.a
	call Function11c8f6
	ld a, $4
	ld [wcd35], a
	jr .asm_11c6fc
.b
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c6fa
	ld a, $6
	jr .asm_11c6fc
.asm_11c6fa
	ld a, $15
.asm_11c6fc
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 3, [hl]
	call PlayClickSFX
	ret

.asm_11c708
	ld a, [hl]
	cp $3
	jr c, .asm_11c711
	sub $3
	jr .asm_11c76e
.asm_11c711
	ld a, [wcd26]
	sub $3
	ret c
	ld [wcd26], a
	jr .asm_11c6c4
.asm_11c71c
	ld hl, wcd28
	ld a, [wcd26]
	add $c
	ret c
	cp [hl]
	ret nc
	ld a, [wcd26]
	add $3
	ld [wcd26], a
	jr .asm_11c6c4
.asm_11c731
	ld a, [wcd28]
	ld b, a
	ld a, [wcd26]
	add [hl]
	add $3
	cp b
	ret nc
	ld a, [hl]
	cp $9
	jr nc, .asm_11c71c
	add $3
	jr .asm_11c76e
.asm_11c746
	ld a, [hl]
	and a
	ret z
	cp $3
	ret z
	cp $6
	ret z
	cp $9
	ret z
	dec a
	jr .asm_11c76e
.asm_11c755
	ld a, [wcd28]
	ld b, a
	ld a, [wcd26]
	add [hl]
	inc a
	cp b
	ret nc
	ld a, [hl]
	cp $2
	ret z
	cp $5
	ret z
	cp $8
	ret z
	cp $b
	ret z
	inc a
.asm_11c76e
	ld [hl], a
	ret

Function11c770:
	xor a
	ld [wMobileCommsJumptableIndex], a
	ld [wcd26], a
	ld [wcd27], a
	ld a, [wcd2b]
	and a
	jr nz, .cd2b_is_nonzero
	ld a, [wcd21]
	and a
	jr z, .cd21_is_zero
	; load from data array
	dec a
	sla a
	ld hl, MobileEZChatData_WordAndPageCounts
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld [wcd28], a
	ld a, [hl]
.load
	ld [wcd29], a
	ret

.cd21_is_zero
	; compute from [wc7d2]
	ld a, [wc7d2]
	ld [wcd28], a
.div_12
	ld c, 12
	call SimpleDivide
	and a
	jr nz, .no_need_to_floor
	dec b
.no_need_to_floor
	ld a, b
	jr .load

.cd2b_is_nonzero
	; compute from [c6a8 + 2 * [cd22]]
	ld hl, $c6a8 ; $c68a + 30
	ld a, [wcd22]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hl]
	ld [wcd28], a
	jr .div_12

Function11c7bc:
	ld bc, Unknown_11c854
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c814
	ld a, [wcd21]
	ld d, a
	and a
	jr z, .asm_11c7e9
	ld a, [wcd26]
	ld e, a
.asm_11c7d0
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	and l
	cp $ff
	ret z
	push bc
	push de
	call Function11c05d
	pop de
	pop bc
	inc e
	ld a, [wcd28]
	cp e
	jr nz, .asm_11c7d0
	ret

.asm_11c7e9
	ld hl, wListPointer
	ld a, [wcd26]
	ld e, a
	add hl, de
.asm_11c7f1
	push de
	ld a, [hli]
	ld e, a
	ld d, $0
	push hl
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	and l
	cp $ff
	jr z, .asm_11c811
	push bc
	call Function11c05d
	pop bc
	pop hl
	pop de
	inc e
	ld a, [wcd28]
	cp e
	jr nz, .asm_11c7f1
	ret

.asm_11c811
	pop hl
	pop de
	ret

.asm_11c814
	ld hl, $c648
	ld a, [wcd22]
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	pop hl
	ld a, [wcd26]
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	ld a, [wcd26]
	ld e, a
.asm_11c831
	push de
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	and l
	cp $ff
	jr z, .asm_11c851
	push bc
	call Function11c05d
	pop bc
	pop hl
	pop de
	inc e
	ld a, [wcd28]
	cp e
	jr nz, .asm_11c831
	ret

.asm_11c851
	pop hl
	pop de
	ret

Unknown_11c854:
	dwcoord  2,  8
	dwcoord  8,  8
	dwcoord 14,  8
	dwcoord  2, 10
	dwcoord  8, 10
	dwcoord 14, 10
	dwcoord  2, 12
	dwcoord  8, 12
	dwcoord 14, 12
	dwcoord  2, 14
	dwcoord  8, 14
	dwcoord 14, 14
	dw -1

Function11c86e:
	ld a, [wcd26]
	and a
	jr z, .asm_11c88a
	hlcoord 2, 17
	ld de, MobileString_Prev
	call PlaceString
	hlcoord 6, 17
	ld c, $3
	xor a
.asm_11c883
	ld [hli], a
	inc a
	dec c
	jr nz, .asm_11c883
	jr .asm_11c895
.asm_11c88a
	hlcoord 2, 17
	ld c, $7
	ld a, $7f
.asm_11c891
	ld [hli], a
	dec c
	jr nz, .asm_11c891
.asm_11c895
	ld hl, wcd28
	ld a, [wcd26]
	add $c
	jr c, .asm_11c8b7
	cp [hl]
	jr nc, .asm_11c8b7
	hlcoord 16, 17
	ld de, MobileString_Next
	call PlaceString
	hlcoord 11, 17
	ld a, $3
	ld c, a
.asm_11c8b1
	ld [hli], a
	inc a
	dec c
	jr nz, .asm_11c8b1
	ret

.asm_11c8b7
	hlcoord 17, 16
	ld a, $7f
	ld [hl], a
	hlcoord 11, 17
	ld c, $7
.asm_11c8c2
	ld [hli], a
	dec c
	jr nz, .asm_11c8c2
	ret

BCD2String:
	inc a
	push af
	and $f
	ldh [hDividend], a
	pop af
	and $f0
	swap a
	ldh [hDividend + 1], a
	xor a
	ldh [hDividend + 2], a
	push hl
	farcall Function11a80c
	pop hl
	ld a, [wcd63]
	add "０"
	ld [hli], a
	ld a, [wcd62]
	add "０"
	ld [hli], a
	ret

MobileString_Page:
	db "PAGE@";"ぺージ@"

MobileString_Prev:
	db "PREV@";"まえ@"

MobileString_Next:
	db "NEXT@";"つぎ@"

Function11c8f6:
	ld a, [wcd20] ; wcd20
	call Function11c95d
	push hl
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c938
	ld a, [wcd21]
	ld d, a
	and a
	jr z, .asm_11c927
	ld hl, wcd26
	ld a, [wMobileCommsJumptableIndex]
	add [hl]
.asm_11c911
	ld e, a
.asm_11c912
	pop hl
	push de
	call Function11c05d
	pop de
	ld a, [wcd20] ; wcd20
	ld c, a
	ld b, $0
	ld hl, wcd36
	add hl, bc
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
	ret

.asm_11c927
	ld hl, wcd26
	ld a, [wMobileCommsJumptableIndex]
	add [hl]
	ld c, a
	ld b, $0
	ld hl, wListPointer
	add hl, bc
	ld a, [hl]
	jr .asm_11c911
.asm_11c938
	ld hl, $c648
	ld a, [wcd22]
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	pop hl
	ld a, [wcd26]
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	ld a, [wMobileCommsJumptableIndex]
	ld e, a
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	jr .asm_11c912

Function11c95d:
	sla a
	ld c, a
	ld b, 0
	ld hl, Unknown_11c986
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	push bc
	push bc
	pop hl
	ld a, $5
	ld c, a
	ld a, $7f
.asm_11c972
	ld [hli], a
	dec c
	jr nz, .asm_11c972
	dec hl
	ld bc, -20
	add hl, bc
	ld a, $5
	ld c, a
	ld a, $7f
.asm_11c980
	ld [hld], a
	dec c
	jr nz, .asm_11c980
	pop hl
	ret

Unknown_11c986:
	dwcoord  1,  2
	dwcoord  7,  2
	dwcoord 13,  2
	dwcoord  1,  4
	dwcoord  7,  4
	dwcoord 13,  4

Function11c992:
	ld a, $8
	hlcoord 2, 7
.asm_11c997
	push af
	ld a, $7f
	push hl
	ld bc, $11
	call ByteFill
	pop hl
	ld bc, $14
	add hl, bc
	pop af
	dec a
	jr nz, .asm_11c997
	ret

Function11c9ab:
	ld a, $7
	hlcoord 0, 6, wAttrMap
	ld bc, $c8
	call ByteFill
	farcall ReloadMapPart
	ret

Function11c9bd:
	ld de, String_11ca38
	call Function11ca7f

Function11c9c3:
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1
	jr nz, .asm_11c9de
	ld a, [de]
	and $2
	jr nz, .asm_11c9e9
	ld a, [de]
	and $40
	jr nz, .asm_11c9f7
	ld a, [de]
	and $80
	jr nz, .asm_11c9fc
	ret

.asm_11c9de
	ld a, [hl]
	and a
	jr nz, .asm_11c9e9
	call Function11ca5e
	xor a
	ld [wcd20], a ; wcd20
.asm_11c9e9
	ld hl, wcd24
	set 4, [hl]
	ld a, $4
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.asm_11c9f7
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.asm_11c9fc
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ret

Function11ca01:
	hlcoord 14, 7, wAttrMap
	ld de, $14
	ld a, $5
	ld c, a
.asm_11ca0a
	push hl
	ld a, $6
	ld b, a
	ld a, $7
.asm_11ca10
	ld [hli], a
	dec b
	jr nz, .asm_11ca10
	pop hl
	add hl, de
	dec c
	jr nz, .asm_11ca0a

Function11ca19:
	hlcoord 0, 12, wAttrMap
	ld de, $14
	ld a, $6
	ld c, a
.asm_11ca22
	push hl
	ld a, $14
	ld b, a
	ld a, $7
.asm_11ca28
	ld [hli], a
	dec b
	jr nz, .asm_11ca28
	pop hl
	add hl, de
	dec c
	jr nz, .asm_11ca22
	farcall ReloadMapPart
	ret

String_11ca38:
	db   "Want to erase";"とうろくちゅう<NO>あいさつ¯ぜんぶ"
	next "all words?@";"けしても　よろしいですか？@"

String_11ca57:
	db   "YES";"はい"
	next "NO@";"いいえ@"

Function11ca5e:
	xor a
.loop
	push af
	call Function11ca6a
	pop af
	inc a
	cp $6
	jr nz, .loop
	ret

Function11ca6a:
	ld hl, wcd36
	ld c, a
	ld b, $0
	add hl, bc
	add hl, bc
	ld [hl], b
	inc hl
	ld [hl], b
	call Function11c95d
	ld de, String_11c3bc
	call PlaceString
	ret

Function11ca7f:
	push de
	ld de, Unknown_11cfc6
	call Function11cfce
	ld de, Unknown_11cfca
	call Function11cfce
	hlcoord 1, 14
	pop de
	call PlaceString
	hlcoord 16, 8
	ld de, String_11ca57
	call PlaceString
	call Function11ca01
	ld a, $1
	ld [wcd2a], a
	ld hl, wcd24
	res 4, [hl]
	call Function11cfb5
	ret

Function11caad:
	ld de, String_11cb1c
	call Function11ca7f

Function11cab3:
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1
	jr nz, .asm_11cace
	ld a, [de]
	and $2
	jr nz, .asm_11caf9
	ld a, [de]
	and $40
	jr nz, .asm_11cb12
	ld a, [de]
	and $80
	jr nz, .asm_11cb17
	ret

.asm_11cace
	call PlayClickSFX
	ld a, [hl]
	and a
	jr nz, .asm_11cafc
	ld a, [wcd35]
	and a
	jr z, .asm_11caf3
	cp $ff
	jr z, .asm_11caf3
	ld a, $ff
	ld [wcd35], a
	hlcoord 1, 14
	ld de, String_11cb31
	call PlaceString
	ld a, $1
	ld [wcd2a], a
	ret

.asm_11caf3
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

.asm_11caf9
	call PlayClickSFX
.asm_11cafc
	ld hl, wcd24
	set 4, [hl]
	ld a, $4
	ld [wJumptableIndex], a
	ld a, [wcd35]
	cp $ff
	ret nz
	ld a, $1
	ld [wcd35], a
	ret

.asm_11cb12
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.asm_11cb17
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ret

String_11cb1c:
	db   "Want to stop";"あいさつ<NO>とうろく¯ちゅうし"
	next "setting a MESSAGE?@";"しますか？@"

String_11cb31:
	db   "Quit without sav-";"とうろくちゅう<NO>あいさつ<WA>ほぞん"
	next "ing the MESSAGE?  @";"されません<GA>よろしい　ですか？@"

Function11cb52:
	ld hl, Unknown_11cc01
	ld a, [wMenuCursorY]
.asm_11cb58
	dec a
	jr z, .asm_11cb5f
	inc hl
	inc hl
	jr .asm_11cb58
.asm_11cb5f
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	call Function11ca7f

Function11cb66:
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1
	jr nz, .asm_11cb81
	ld a, [de]
	and $2
	jr nz, .asm_11cbd7
	ld a, [de]
	and $40
	jr nz, .asm_11cbeb
	ld a, [de]
	and $80
	jr nz, .asm_11cbf0
	ret

.asm_11cb81
	ld a, [hl]
	and a
	jr nz, .asm_11cbd4
	ld a, BANK(s4_a007)
	call GetSRAMBank
	ld hl, s4_a007
	ld a, [wMenuCursorY]
	dec a
	sla a
	sla a
	ld c, a
	sla a
	add c
	ld c, a
	ld b, $0
	add hl, bc
	ld de, wcd36
	ld c, $c
.asm_11cba2
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .asm_11cba2
	call CloseSRAM
	call PlayClickSFX
	ld de, Unknown_11cfc6
	call Function11cfce
	ld hl, Unknown_11cc7e
	ld a, [wMenuCursorY]
.asm_11cbba
	dec a
	jr z, .asm_11cbc1
	inc hl
	inc hl
	jr .asm_11cbba
.asm_11cbc1
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	hlcoord 1, 14
	call PlaceString
	ld hl, wJumptableIndex
	inc [hl]
	inc hl
	ld a, $10
	ld [hl], a
	ret

.asm_11cbd4
	call PlayClickSFX
.asm_11cbd7
	ld de, Unknown_11cfba
	call Function11cfce
	call Function11c38a
	ld hl, wcd24
	set 4, [hl]
	ld a, $4
	ld [wJumptableIndex], a
	ret

.asm_11cbeb
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.asm_11cbf0
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ret

Function11cbf5:
	call WaitSFX
	ld hl, wcf64
	dec [hl]
	ret nz
	dec hl
	set 7, [hl]
	ret

Unknown_11cc01:
	dw String_11cc09
	dw String_11cc23
	dw String_11cc42
	dw String_11cc60

String_11cc09:
	db   "Shown to introduce";"じこしょうかい　は"
	next "yourself. OK?@";"この　あいさつで　いいですか？@"

String_11cc23:
	db   "Shown when begin-";"たいせん　<GA>はじまるとき　は"
	next "ning a battle. OK?@";"この　あいさつで　いいですか？@"

String_11cc42:
	db   "Shown when win-";"たいせん　<NI>かったとき　は"
	next "ning a battle. OK?@";"この　あいさつで　いいですか？@"

String_11cc60:
	db   "Shown when los-";"たいせん　<NI>まけたとき　は"
	next "ing a battle. OK?@";"この　あいさつで　いいですか？@"

Unknown_11cc7e:
	dw String_11cc86
	dw String_11cc9d
	dw String_11ccb9
	dw String_11ccd4

String_11cc86:
	db   "MESSAGE set!@";"じこしょうかい　の"
	;next "あいさつ¯とうろくした！@"

String_11cc9d:
	db   "MESSAGE set!@";"たいせん　<GA>はじまるとき　の"
	;next "あいさつ¯とうろくした！@"

String_11ccb9:
	db   "MESSAGE set!@";"たいせん　<NI>かったとき　の"
	;next "あいさつ¯とうろくした！@"

String_11ccd4:
	db   "MESSAGE set!@";"たいせん　<NI>まけたとき　の"
	;next "あいさつ¯とうろくした！@"

Function11ccef:
	ld de, Unknown_11cfc6
	call Function11cfce
	hlcoord 1, 14
	ld de, String_11cd10
	call PlaceString
	call Function11ca19
	call Function11cfb5

Function11cd04:
	ld de, hJoypadPressed
	ld a, [de]
	and a
	ret z
	ld a, $4
	ld [wJumptableIndex], a
	ret

String_11cd10:
	db "Please enter some";"なにか　ことば¯いれてください@"
	next "words.@"

Function11cd20:
	call EZChat_ClearBottom12Rows
	ld de, Unknown_11cfc6
	call Function11cfce
	hlcoord 1, 14
	ld a, [wcd2b]
	ld [wcd2c], a
	and a
	jr nz, .asm_11cd3a
	ld de, String_11cdc7
	jr .asm_11cd3d
.asm_11cd3a
	ld de, String_11cdd9
.asm_11cd3d
	call PlaceString
	hlcoord 4, 8
	ld de, String_11cdf5
	call PlaceString
	call Function11cdaa
	ld hl, wcd24
	res 5, [hl]
	call Function11cfb5

Function11cd54:
	ld hl, wcd2c
	ld de, hJoypadPressed
	ld a, [de]
	and A_BUTTON
	jr nz, .asm_11cd6f
	ld a, [de]
	and B_BUTTON
	jr nz, .asm_11cd73
	ld a, [de]
	and D_UP
	jr nz, .asm_11cd8b
	ld a, [de]
	and D_DOWN
	jr nz, .asm_11cd94
	ret

.asm_11cd6f
	ld a, [hl]
	ld [wcd2b], a
.asm_11cd73
	ld a, [wcd2b]
	and a
	jr nz, .asm_11cd7d
	ld a, $6
	jr .asm_11cd7f

.asm_11cd7d
	ld a, $15
.asm_11cd7f
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 5, [hl]
	call PlayClickSFX
	ret

.asm_11cd8b
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ld de, String_11cdc7
	jr .asm_11cd9b

.asm_11cd94
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ld de, String_11cdd9
.asm_11cd9b
	push de
	ld de, Unknown_11cfc6
	call Function11cfce
	pop de
	hlcoord 1, 14
	call PlaceString
	ret

Function11cdaa:
	ld a, $2
	hlcoord 0, 6, wAttrMap
	ld bc, 6 * SCREEN_WIDTH
	call ByteFill
	ld a, $7
	hlcoord 0, 12, wAttrMap
	ld bc, 4 * SCREEN_WIDTH
	call ByteFill
	farcall ReloadMapPart
	ret

String_11cdc7:
; Words will be displayed by category
	db   "Display words";"ことば¯しゅるいべつに"
	next "by category@";"えらべます@"

String_11cdd9:
; Words will be displayed in alphabetical order
	db   "Display words in";"ことば¯アイウエオ　の"
	next "alphabetical order@";"じゅんばんで　ひょうじ　します@"

String_11cdf5:
	db   "GROUP MODE";"しゅるいべつ　モード"  ; Category mode
	next "ABC MODE@";"アイウエオ　　モード@" ; ABC mode

Function11ce0b:
	call EZChat_ClearBottom12Rows
	hlcoord 1, 7
	ld de, String_11cf79
	call PlaceString
	hlcoord 1, 17
	ld de, EZChatString_Stop_Mode_Cancel
	call PlaceString
	call Function11c618
	ld hl, wcd24
	res 2, [hl]
	call Function11cfb5

Function11ce2b:
	ld a, [wcd22]
	sla a
	sla a
	ld c, a
	ld b, 0
	ld hl, Unknown_11ceb9
	add hl, bc

	ld de, hJoypadPressed
	ld a, [de]
	and START
	jr nz, .start
	ld a, [de]
	and SELECT
	jr nz, .select
	ld a, [de]
	and A_BUTTON
	jr nz, .a
	ld a, [de]
	and B_BUTTON
	jr nz, .b

	ld de, hJoyLast
	ld a, [de]
	and D_UP
	jr nz, .up
	ld a, [de]
	and D_DOWN
	jr nz, .down
	ld a, [de]
	and D_LEFT
	jr nz, .left
	ld a, [de]
	and D_RIGHT
	jr nz, .right

	ret

.a
	ld a, [wcd22]
	cp NUM_KANA
	jr c, .place
	sub NUM_KANA
	jr z, .done
	dec a
	jr z, .mode
	jr .b

.start
	ld hl, wcd24
	set 0, [hl]
	ld a, $8
	ld [wcd20], a ; wcd20
.b
	ld a, $4
	jr .load

.select
	ld a, [wcd2b]
	xor $1
	ld [wcd2b], a
	ld a, $6
	jr .load

.place
	ld a, $8
	jr .load

.mode
	ld a, $13
.load
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 2, [hl]
	call PlayClickSFX
	ret

.done
	ld a, [wcd20] ; wcd20
	call Function11ca6a
	call PlayClickSFX
	ret

.left
	inc hl
.down
	inc hl
.right
	inc hl
.up
	ld a, [hl]
	cp $ff
	ret z
	ld [wcd22], a
	ret

Unknown_11ceb9:
	; up left down right
	db $ff, $01
	db $05, $ff
	db $ff, $02
	db $06, $00
	db $ff, $03
	db $07, $01
	db $ff, $04
	db $08, $02
	db $ff, $14
	db $09, $03
	db $00, $06
	db $0a, $ff
	db $01, $07
	db $0b, $05
	db $02, $08
	db $0c, $06
	db $03, $09
	db $0d, $07
	db $04, $19
	db $0e, $08
	db $05, $0b
	db $0f, $ff
	db $06, $0c
	db $10, $0a
	db $07, $0d
	db $11, $0b
	db $08, $0e
	db $12, $0c
	db $09, $1e
	db $13, $0d
	db $0a, $10
	db $2d, $ff
	db $0b, $11
	db $2d, $0f
	db $0c, $12
	db $2d, $10
	db $0d, $13
	db $2d, $11
	db $0e, $26
	db $2d, $12
	db $ff, $15
	db $19, $04
	db $ff, $16
	db $1a, $14
	db $ff, $17
	db $1b, $15
	db $ff, $18
	db $1c, $16
	db $ff, $23
	db $1d, $17
	db $14, $1a
	db $1e, $09
	db $15, $1b
	db $1f, $19
	db $16, $1c
	db $20, $1a
	db $17, $1d
	db $21, $1b
	db $18, $2b
	db $22, $1c
	db $19, $1f
	db $26, $0e
	db $1a, $20
	db $27, $1e
	db $1b, $21
	db $28, $1f
	db $1c, $22
	db $29, $20
	db $1d, $2c
	db $2a, $21
	db $ff, $24
	db $2b, $18
	db $ff, $25
	db $2b, $23
	db $ff, $ff
	db $2b, $24
	db $1e, $27
	db $2e, $13
	db $1f, $28
	db $2e, $26
	db $20, $29
	db $2e, $27
	db $21, $2a
	db $2e, $28
	db $22, $ff
	db $2e, $29
	db $23, $ff
	db $2c, $1d
	db $2b, $ff
	db $2f, $22
	db $0f, $2e
	db $ff, $ff
	db $26, $2f
	db $ff, $2d
	db $2c, $ff
	db $ff, $2e

String_11cf79:
; Hiragana table
	db   "あいうえお　なにぬねの　や　ゆ　よ"
	next "かきくけこ　はひふへほ　わ"
	next "さしすせそ　まみむめも　そのた"
	next "たちつてと　らりるれろ"
	db   "@"

Function11cfb5:
	ld hl, wJumptableIndex
	inc [hl]
	ret

Unknown_11cfba:
	db  0,  0 ; start coords
	db 20,  6 ; end coords

Unknown_11cfbe:
	db  0, 14 ; start coords
	db 20,  4 ; end coords

Unknown_11cfc2:
	db  0,  6 ; start coords
	db 20, 10 ; end coords

Unknown_11cfc6:
	db  0, 12 ; start coords
	db 20,  6 ; end coords

Unknown_11cfca:
	db 14,  7 ; start coords
	db  6,  5 ; end coords

Function11cfce:
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
	ld a, [de]
	inc de
	push af
	ld a, [de]
	inc de
	and a
.add_n_times
	jr z, .done_add_n_times
	add hl, bc
	dec a
	jr .add_n_times
.done_add_n_times
	pop af
	ld c, a
	ld b, 0
	add hl, bc
	push hl
	ld a, $79
	ld [hli], a
	ld a, [de]
	inc de
	dec a
	dec a
	jr z, .skip_fill
	ld c, a
	ld a, $7a
.fill_loop
	ld [hli], a
	dec c
	jr nz, .fill_loop
.skip_fill
	ld a, $7b
	ld [hl], a
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	ld a, [de]
	dec de
	dec a
	dec a
	jr z, .skip_section
	ld b, a
.loop
	push hl
	ld a, $7c
	ld [hli], a
	ld a, [de]
	dec a
	dec a
	jr z, .skip_row
	ld c, a
	ld a, $7f
.row_loop
	ld [hli], a
	dec c
	jr nz, .row_loop
.skip_row
	ld a, $7c
	ld [hl], a
	pop hl
	push bc
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
	dec b
	jr nz, .loop
.skip_section
	ld a, $7d
	ld [hli], a
	ld a, [de]
	dec a
	dec a
	jr z, .skip_remainder
	ld c, a
	ld a, $7a
.final_loop
	ld [hli], a
	dec c
	jr nz, .final_loop
.skip_remainder
	ld a, $7e
	ld [hl], a
	ret

Function11d035:
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
	ld a, [de]
	inc de
	push af
	ld a, [de]
	inc de
	and a
.add_n_times
	jr z, .done_add_n_times
	add hl, bc
	dec a
	jr .add_n_times
.done_add_n_times
	pop af
	ld c, a
	ld b, $0
	add hl, bc
	push hl
	ld a, $79
	ld [hl], a
	pop hl
	push hl
	ld a, [de]
	dec a
	inc de
	ld c, a
	add hl, bc
	ld a, $7b
	ld [hl], a
	call .AddNMinusOneTimes
	ld a, $7e
	ld [hl], a
	pop hl
	push hl
	call .AddNMinusOneTimes
	ld a, $7d
	ld [hl], a
	pop hl
	push hl
	inc hl
	push hl
	call .AddNMinusOneTimes
	pop bc
	dec de
	ld a, [de]
	cp $2
	jr z, .skip
	dec a
	dec a
.loop
	push af
	ld a, $7a
	ld [hli], a
	ld [bc], a
	inc bc
	pop af
	dec a
	jr nz, .loop
.skip
	pop hl
	ld bc, $14
	add hl, bc
	push hl
	ld a, [de]
	dec a
	ld c, a
	ld b, $0
	add hl, bc
	pop bc
	inc de
	ld a, [de]
	cp $2
	ret z
	push bc
	dec a
	dec a
	ld c, a
	ld b, a
	ld de, $14
.loop2
	ld a, $7c
	ld [hl], a
	add hl, de
	dec c
	jr nz, .loop2
	pop hl
.loop3
	ld a, $7c
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop3
	ret

.AddNMinusOneTimes:
	ld a, [de]
	dec a
	ld bc, SCREEN_WIDTH
.add_n_minus_one_times
	add hl, bc
	dec a
	jr nz, .add_n_minus_one_times
	ret

AnimateEZChatCursor:
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, [hl]
	ld e, a
	ld d, 0
	ld hl, .Jumptable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.Jumptable:
	dw .zero
	dw .one
	dw .two
	dw .three
	dw .four
	dw .five
	dw .six
	dw .seven
	dw .eight
	dw .nine
	dw .ten

.zero
	ld a, [wcd20] ; wcd20
	sla a
	ld hl, .Coords_Zero
	ld e, $1
	jr .load

.one
	ld a, [wcd21]
	sla a
	ld hl, .Coords_One
	ld e, $2
	jr .load

.two
	ld hl, .FramesetsIDs_Two
	ld a, [wcd22]
	ld e, a
	ld d, $0
	add hl, de
	ld a, [hl]
	call ReinitSpriteAnimFrame

	ld a, [wcd22]
	sla a
	ld hl, .Coords_Two
	ld e, $4
	jr .load

.three
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
	call ReinitSpriteAnimFrame
	ld a, [wMobileCommsJumptableIndex]
	sla a
	ld hl, .Coords_Three
	ld e, $8
.load
	push de
	ld e, a
	ld d, $0
	add hl, de
	push hl
	pop de
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hl], a
	pop de
	ld a, e
	call .UpdateObjectFlags
	ret

.four
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
	call ReinitSpriteAnimFrame
	ld a, [wcd2a]
	sla a
	ld hl, .Coords_Four
	ld e, $10
	jr .load

.five
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
	call ReinitSpriteAnimFrame
	ld a, [wcd2c]
	sla a
	ld hl, .Coords_Five
	ld e, $20
	jr .load

.six
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_5
	call ReinitSpriteAnimFrame
	; X = [wcd4a] * 8 + 24
	ld a, [wcd4a]
	sla a
	sla a
	sla a
	add $18
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hli], a
	; Y = 48
	ld a, $30
	ld [hl], a

	ld a, $1
	ld e, a
	call .UpdateObjectFlags
	ret

.seven
	ld a, [wEZChatCursorYCoord]
	cp $4
	jr z, .cursor0
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3
	jr .got_frameset

.cursor0
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1
.got_frameset
	call ReinitSpriteAnimFrame
	ld a, [wEZChatCursorYCoord]
	cp $4
	jr z, .asm_11d1b1
	; X = [wEZChatCursorXCoord] * 8 + 32
	ld a, [wEZChatCursorXCoord]
	sla a
	sla a
	sla a
	add $20
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hli], a
	; Y = [wEZChatCursorYCoord] * 16 + 72
	ld a, [wEZChatCursorYCoord]
	sla a
	sla a
	sla a
	sla a
	add $48
	ld [hl], a
	ld a, $2
	ld e, a
	call .UpdateObjectFlags
	ret

.asm_11d1b1
	; X = [wEZChatCursorXCoord] * 40 + 24
	ld a, [wEZChatCursorXCoord]
	sla a
	sla a
	sla a
	ld e, a
	sla a
	sla a
	add e
	add $18
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hli], a
	; Y = 138
	ld a, $8a
	ld [hl], a
	ld a, $2
	ld e, a
	call .UpdateObjectFlags
	ret

.nine
	ld d, -13 * 8
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_7
	jr .eight_nine_load

.eight
	ld d, 2 * 8
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_6
.eight_nine_load
	push de
	call ReinitSpriteAnimFrame
	ld a, [wcd4a]
	sla a
	sla a
	sla a
	ld e, a
	sla a
	add e
	add 8 * 8
	ld hl, SPRITEANIMSTRUCT_YCOORD
	add hl, bc
	ld [hld], a
	pop af
	ld [hl], a
	ld a, $4
	ld e, a
	call .UpdateObjectFlags
	ret

.ten
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1
	call ReinitSpriteAnimFrame
	ld a, $8
	ld e, a
	call .UpdateObjectFlags
	ret

.Coords_Zero:
	dbpixel  1,  3, 5, 2
	dbpixel  7,  3, 5, 2
	dbpixel 13,  3, 5, 2
	dbpixel  1,  5, 5, 2
	dbpixel  7,  5, 5, 2
	dbpixel 13,  5, 5, 2
	dbpixel  1, 17, 5, 2
	dbpixel  7, 17, 5, 2
	dbpixel 13, 17, 5, 2

.Coords_One:
	dbpixel  1,  8, 5, 2
	dbpixel  7,  8, 5, 2
	dbpixel 13,  8, 5, 2
	dbpixel  1, 10, 5, 2
	dbpixel  7, 10, 5, 2
	dbpixel 13, 10, 5, 2
	dbpixel  1, 12, 5, 2
	dbpixel  7, 12, 5, 2
	dbpixel 13, 12, 5, 2
	dbpixel  1, 14, 5, 2
	dbpixel  7, 14, 5, 2
	dbpixel 13, 14, 5, 2
	dbpixel  1, 16, 5, 2
	dbpixel  7, 16, 5, 2
	dbpixel 13, 16, 5, 2
	dbpixel  1, 18, 5, 2
	dbpixel  7, 18, 5, 2
	dbpixel 13, 18, 5, 2

.Coords_Two:
	dbpixel  2,  9       ; 00
	dbpixel  3,  9       ; 01
	dbpixel  4,  9       ; 02
	dbpixel  5,  9       ; 03
	dbpixel  6,  9       ; 04
	dbpixel  2, 11       ; 05
	dbpixel  3, 11       ; 06
	dbpixel  4, 11       ; 07
	dbpixel  5, 11       ; 08
	dbpixel  6, 11       ; 09
	dbpixel  2, 13       ; 0a
	dbpixel  3, 13       ; 0b
	dbpixel  4, 13       ; 0c
	dbpixel  5, 13       ; 0d
	dbpixel  6, 13       ; 0e
	dbpixel  2, 15       ; 0f
	dbpixel  3, 15       ; 10
	dbpixel  4, 15       ; 11
	dbpixel  5, 15       ; 12
	dbpixel  6, 15       ; 13
	dbpixel  8,  9       ; 14
	dbpixel  9,  9       ; 15
	dbpixel 10,  9       ; 16
	dbpixel 11,  9       ; 17
	dbpixel 12,  9       ; 18
	dbpixel  8, 11       ; 19
	dbpixel  9, 11       ; 1a
	dbpixel 10, 11       ; 1b
	dbpixel 11, 11       ; 1c
	dbpixel 12, 11       ; 1d
	dbpixel  8, 13       ; 1e
	dbpixel  9, 13       ; 1f
	dbpixel 10, 13       ; 20
	dbpixel 11, 13       ; 21
	dbpixel 12, 13       ; 22
	dbpixel 14,  9       ; 23
	dbpixel 16,  9       ; 24
	dbpixel 18,  9       ; 25
	dbpixel  8, 15       ; 26
	dbpixel  9, 15       ; 27
	dbpixel 10, 15       ; 28
	dbpixel 11, 15       ; 29
	dbpixel 12, 15       ; 2a
	dbpixel 14, 11       ; 2b
	dbpixel 14, 13       ; 2c
	dbpixel  1, 18, 5, 2 ; 2d
	dbpixel  7, 18, 5, 2 ; 2e
	dbpixel 13, 18, 5, 2 ; 2f

.Coords_Three:
	dbpixel  2, 10
	dbpixel  8, 10
	dbpixel 14, 10
	dbpixel  2, 12
	dbpixel  8, 12
	dbpixel 14, 12
	dbpixel  2, 14
	dbpixel  8, 14
	dbpixel 14, 14
	dbpixel  2, 16
	dbpixel  8, 16
	dbpixel 14, 16

.Coords_Four:
	dbpixel 16, 10
	dbpixel 16, 12

.Coords_Five:
	dbpixel  4, 10
	dbpixel  4, 12

.FramesetsIDs_Two:
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 00
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 01
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 02
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 03
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 04
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 05
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 06
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 07
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 08
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 09
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0a
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0b
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0c
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0d
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0e
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0f
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 10
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 11
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 12
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 13
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 14
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 15
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 16
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 17
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 18
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 19
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1a
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1b
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1c
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1d
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1e
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1f
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 20
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 21
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 22
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 23
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 24
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 25
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 26
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 27
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 28
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 29
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 2a
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 2b
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_4 ; 2c
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 2d
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 2e
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 2f

.UpdateObjectFlags:
	ld hl, wcd24
	and [hl]
	jr nz, .update_y_offset
	ld a, e
	ld hl, wcd23
	and [hl]
	jr z, .reset_y_offset
	ld hl, SPRITEANIMSTRUCT_0E
	add hl, bc
	ld a, [hl]
	and a
	jr z, .flip_bit_0
	dec [hl]
	ret

.flip_bit_0
	ld a, $0
	ld [hld], a
	ld a, $1
	xor [hl]
	ld [hl], a
	and a
	jr nz, .update_y_offset
.reset_y_offset
	ld hl, SPRITEANIMSTRUCT_YOFFSET
	add hl, bc
	xor a
	ld [hl], a
	ret

.update_y_offset
	ld hl, SPRITEANIMSTRUCT_YCOORD
	add hl, bc
	ld a, $b0
	sub [hl]
	ld hl, SPRITEANIMSTRUCT_YOFFSET
	add hl, bc
	ld [hl], a
	ret

Function11d323:
	ldh a, [rSVBK]
	push af
	ld a, $5
	ldh [rSVBK], a
	ld hl, Palette_11d33a
	ld de, wBGPals1
	ld bc, 16 palettes
	call CopyBytes
	pop af
	ldh [rSVBK], a
	ret

Palette_11d33a:
	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 16, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 23, 17, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 31, 31, 31
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00
	RGB 00, 00, 00

EZChat_GetSeenPokemonByKana:
	ldh a, [rSVBK]
	push af
	ld hl, $c648
	ld a, LOW(w5_d800)
	ld [wcd2d], a
	ld [hli], a
	ld a, HIGH(w5_d800)
	ld [wcd2e], a
	ld [hl], a

	ld a, LOW(EZChat_SortedPokemon)
	ld [wcd2f], a
	ld a, HIGH(EZChat_SortedPokemon)
	ld [wcd30], a

	ld a, LOW($c6a8)
	ld [wcd31], a
	ld a, HIGH($c6a8)
	ld [wcd32], a

	ld a, LOW($c64a)
	ld [wcd33], a
	ld a, HIGH($c64a)
	ld [wcd34], a

	ld hl, EZChat_SortedWords
	ld a, (EZChat_SortedWords.End - EZChat_SortedWords) / 4

.MasterLoop:
	push af
; read row
; offset
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
; size
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
; save the pointer to the next row
	push hl
; add de to w3_d000
	ld hl, w3_d000
	add hl, de
; recover de from wcd2d (default: w5_d800)
	ld a, [wcd2d]
	ld e, a
	ld a, [wcd2e]
	ld d, a
; save bc for later
	push bc

.loop1
; copy 2*bc bytes from 3:hl to 5:de
	ld a, $3
	ldh [rSVBK], a
	ld a, [hli]
	push af
	ld a, $5
	ldh [rSVBK], a
	pop af
	ld [de], a
	inc de

	ld a, $3
	ldh [rSVBK], a
	ld a, [hli]
	push af
	ld a, $5
	ldh [rSVBK], a
	pop af
	ld [de], a
	inc de

	dec bc
	ld a, c
	or b
	jr nz, .loop1

; recover the pointer from wcd2f (default: EZChat_SortedPokemon)
	ld a, [wcd2f]
	ld l, a
	ld a, [wcd30]
	ld h, a
; copy the pointer from [hl] to bc
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
; store the pointer to the next pointer back in wcd2f
	ld a, l
	ld [wcd2f], a
	ld a, h
	ld [wcd30], a
; push pop that pointer to hl
	push bc
	pop hl
	ld c, $0
.loop2
; Have you seen this Pokemon?
	ld a, [hl]
	cp $ff
	jr z, .done
	call .CheckSeenMon
	jr nz, .next
; If not, skip it.
	inc hl
	jr .loop2

.next
; If so, append it to the list at 5:de, and increase the count.
	ld a, [hli]
	ld [de], a
	inc de
	xor a
	ld [de], a
	inc de
	inc c
	jr .loop2

.done
; Remember the original value of bc from the table?
; Well, the stack remembers it, and it's popping it to hl.
	pop hl
; Add the number of seen Pokemon from the list.
	ld b, $0
	add hl, bc
; Push pop to bc.
	push hl
	pop bc
; Load the pointer from [wcd31] (default: $c6a8)
	ld a, [wcd31]
	ld l, a
	ld a, [wcd32]
	ld h, a
; Save the quantity from bc to [hl]
	ld a, c
	ld [hli], a
	ld a, b
	ld [hli], a
; Save the new value of hl to [wcd31]
	ld a, l
	ld [wcd31], a
	ld a, h
	ld [wcd32], a
; Recover the pointer from [wcd33] (default: $c64a)
	ld a, [wcd33]
	ld l, a
	ld a, [wcd34]
	ld h, a
; Save the current value of de there
	ld a, e
	ld [wcd2d], a
	ld [hli], a
	ld a, d
	ld [wcd2e], a
; Save the new value of hl back to [wcd33]
	ld [hli], a
	ld a, l
	ld [wcd33], a
	ld a, h
	ld [wcd34], a
; Next row
	pop hl
	pop af
	dec a
	jr z, .ExitMasterLoop
	jp .MasterLoop

.ExitMasterLoop:
	pop af
	ldh [rSVBK], a
	ret

.CheckSeenMon:
	push hl
	push bc
	push de
	dec a
	ld hl, rSVBK
	ld e, $1
	ld [hl], e
	call CheckSeenMon
	ld hl, rSVBK
	ld e, $5
	ld [hl], e
	pop de
	pop bc
	pop hl
	ret

EZChat_GetCategoryWordsByKana:
	ldh a, [rSVBK]
	push af
	ld a, $3
	ldh [rSVBK], a

	; load pointers
	ld hl, MobileEZChatCategoryPointers
	ld bc, MobileEZChatData_WordAndPageCounts

	; init WRAM registers
	xor a
	ld [wcd2d], a
	inc a
	ld [wcd2e], a

	; enter the first loop
	ld a, 14
.loop1
	push af

	; load the pointer to the category
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl

	; skip to the attributes
	ld hl, NAME_LENGTH_JAPANESE - 1
	add hl, de

	; get the number of words in the category
	ld a, [bc] ; number of entries to copy
	inc bc
	inc bc
	push bc

.loop2
	push af
	push hl

	; load offset at [hl]
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a

	; add to w3_d000
	ld hl, w3_d000
	add hl, de

	; copy from wcd2d and increment [wcd2d] in place
	ld a, [wcd2d]
	ld [hli], a
	inc a
	ld [wcd2d], a

	; copy from wcd2e
	ld a, [wcd2e]
	ld [hl], a

	; next entry
	pop hl
	ld de, 8
	add hl, de
	pop af
	dec a
	jr nz, .loop2

	; reset and go to next category
	ld hl, wcd2d
	xor a
	ld [hli], a
	inc [hl]
	pop bc
	pop hl
	pop af
	dec a
	jr nz, .loop1
	pop af
	ldh [rSVBK], a
	ret

INCLUDE "data/pokemon/ezchat_order.asm"

GFX_11d67e:
INCBIN "gfx/pokedex/select_start.2bpp"

LZ_11d6de:
INCBIN "gfx/pokedex/slowpoke_mobile.2bpp.lz"

MobileEZChatCategoryNames:
; Fixed message categories
	db "PKMN@@" 	; 00 ; Pokemon 		; "ポケモン@@"
	db "TYPES@" 	; 01 ; Types		; "タイプ@@@"
	db "GREET@" 	; 02 ; Greetings	; "あいさつ@@"
	db "HUMAN@" 	; 03 ; People		; "ひと@@@@"
	db "FIGHT@" 	; 04 ; Battle		; "バトル@@@"
	db "VOICE@" 	; 05 ; Voices		; "こえ@@@@"
	db "TALK@@" 	; 06 ; Speech		; "かいわ@@@"
	db "EMOTE@" 	; 07 ; Feelings		; "きもち@@@"
	db "DESC@@" 	; 08 ; Conditions	; "じょうたい@"
	db "LIFE@@" 	; 09 ; Lifestyle	; "せいかつ@@"
	db "HOBBY@" 	; 0a ; Hobbies		; "しゅみ@@@" 
	db "ACT@@@" 	; 0b ; Actions		; "こうどう@@"
	db "ITEM@@" 	; 0c ; Time			; "じかん@@@"
	db "END@@@" 	; 0d ; Endings		; "むすび@@@"
	db "MISC@@" 	; 0e ; Misc			; "あれこれ@@"

MobileEZChatCategoryPointers:
; entries correspond to EZCHAT_* constants
	dw .Types          ; 01
	dw .Greetings      ; 02
	dw .People         ; 03
	dw .Battle         ; 04
	dw .Exclamations   ; 05
	dw .Conversation   ; 06
	dw .Feelings       ; 07
	dw .Conditions     ; 08
	dw .Life           ; 09
	dw .Hobbies        ; 0a
	dw .Actions        ; 0b
	dw .Time           ; 0c
	dw .Farewells      ; 0d
	dw .ThisAndThat    ; 0e

.Types:
	db	"DARK@",	$26,	$0,	$0		; あく@@@,
	db	"ROCK@",	$aa,	$0,	$0		; いわ@@@,
	db	"PSYCH",	$da,	$0,	$0		; エスパー@,
	db	"FIGHT",	$4e,	$1,	$0		; かくとう@,
	db	"GRASS",	$ba,	$1,	$0		; くさ@@@,
	db	"GHOST",	$e4,	$1,	$0		; ゴースト@,
	db	"ICE@@",	$e6,	$1,	$0		; こおり@@,
	db	"GROUN",	$68,	$2,	$0		; じめん@@,
	db	"TYPE@",	$e8,	$2,	$0		; タイプ@@,
	db	"ELECT",	$8e,	$3,	$0		; でんき@@,
	db	"POISO",	$ae,	$3,	$0		; どく@@@,
	db	"DRAGO",	$bc,	$3,	$0		; ドラゴン@,
	db	"NORMA",	$22,	$4,	$0		; ノーマル@,
	db	"STEEL",	$36,	$4,	$0		; はがね@@,
	db	"FLYIN",	$5e,	$4,	$0		; ひこう@@,
	db	"FIRE@",	$b2,	$4,	$0		; ほのお@@,
	db	"WATER",	$f4,	$4,	$0		; みず@@@,
	db	"BUG@@",	$12,	$5,	$0		; むし@@@,
						
.Greetings:						
	db	"THANK",	$58,	$0,	$0		; ありがと@,
	db	"THANK",	$5a,	$0,	$0		; ありがとう,
	db	"LETS ",	$80,	$0,	$0		; いくぜ！@,
	db	"GO ON",	$82,	$0,	$0		; いくよ！@,
	db	"DO IT",	$84,	$0,	$0		; いくわよ！,
	db	"YEAH@",	$a6,	$0,	$0		; いやー@@,
	db	"HOW D",	$a,		$1,	$0		; おっす@@,
	db	"HOWDY",	$22,	$1,	$0		; おはつです,
	db	"CONGR",	$2a,	$1,	$0		; おめでとう,
	db	"SORRY",	$f8,	$1,	$0		; ごめん@@,
	db	"SORRY",	$fa,	$1,	$0		; ごめんよ@,
	db	"HI TH",	$fc,	$1,	$0		; こらっ@@,
	db	"HI!@@",	$a,		$2,	$0		; こんちは！,
	db	"HELLO",	$10,	$2,	$0		; こんにちは,
	db	"GOOD-",	$28,	$2,	$0		; さようなら,
	db	"CHEER",	$2e,	$2,	$0		; サンキュー,
	db	"I'M H",	$30,	$2,	$0		; さんじょう,
	db	"PARDO",	$48,	$2,	$0		; しっけい@,
	db	"EXCUS",	$4c,	$2,	$0		; しつれい@,
	db	"SEE Y",	$6c,	$2,	$0		; じゃーね@,
	db	"YO!@@",	$8c,	$2,	$0		; すいません,
	db	"WELL.",	$ca,	$2,	$0		; それじゃ@,
	db	"GRATE",	$a6,	$3,	$0		; どうも@@,
	db	"WASSU",	$ee,	$3,	$0		; なんじゃ@,
	db	"HI@@@",	$2c,	$4,	$0		; ハーイ@@,
	db	"YEA, ",	$32,	$4,	$0		; はいはい@,
	db	"BYE-B",	$34,	$4,	$0		; バイバイ@,
	db	"HEY@@",	$8a,	$4,	$0		; へイ@@@,
	db	"SMELL",	$de,	$4,	$0		; またね@@,
	db	"TUNED",	$32,	$5,	$0		; もしもし@,
	db	"HOO-H",	$3e,	$5,	$0		; やあ@@@,
	db	"YAHOO",	$4e,	$5,	$0		; やっほー@,
	db	"YO@@@",	$62,	$5,	$0		; よう@@@,
	db	"GO OV",	$64,	$5,	$0		; ようこそ@,
	db	"COUNT",	$80,	$5,	$0		; よろしく@,
	db	"WELCO",	$94,	$5,	$0		; らっしゃい,

.People:
	db	"OPPON",	$1c,	$0,	$0		; あいて@@,
	db	"I@@@@",	$36,	$0,	$0		; あたし@@,
	db	"YOU@@",	$40,	$0,	$0		; あなた@@,
	db	"YOURS",	$42,	$0,	$0		; あなたが@,
	db	"SON@@",	$44,	$0,	$0		; あなたに@,
	db	"YOUR@",	$46,	$0,	$0		; あなたの@,
	db	"YOU'R",	$48,	$0,	$0		; あなたは@,
	db	"YOU'V",	$4a,	$0,	$0		; あなたを@,
	db	"MOM@@",	$e8,	$0,	$0		; おかあさん,
	db	"GRAND",	$fc,	$0,	$0		; おじいさん,
	db	"UNCLE",	$2,		$1,	$0		; おじさん@,
	db	"DAD@@",	$e,		$1,	$0		; おとうさん,
	db	"BOY@@",	$10,	$1,	$0		; おとこのこ,
	db	"ADULT",	$14,	$1,	$0		; おとな@@,
	db	"BROTH",	$16,	$1,	$0		; おにいさん,
	db	"SISTE",	$18,	$1,	$0		; おねえさん,
	db	"GRAND",	$1c,	$1,	$0		; おばあさん,
	db	"AUNT@",	$20,	$1,	$0		; おばさん@,
	db	"ME@@@",	$34,	$1,	$0		; おれさま@,
	db	"GIRL@",	$3a,	$1,	$0		; おんなのこ,
	db	"BABE@",	$40,	$1,	$0		; ガール@@,
	db	"FAMIL",	$52,	$1,	$0		; かぞく@@,
	db	"HER@@",	$72,	$1,	$0		; かのじょ@,
	db	"HIM@@",	$7c,	$1,	$0		; かれ@@@,
	db	"HE@@@",	$9a,	$1,	$0		; きみ@@@,
	db	"PLACE",	$9c,	$1,	$0		; きみが@@,
	db	"DAUGH",	$9e,	$1,	$0		; きみに@@,
	db	"HIS@@",	$a0,	$1,	$0		; きみの@@,
	db	"HE'S@",	$a2,	$1,	$0		; きみは@@,
	db	"AREN'",	$a4,	$1,	$0		; きみを@@,
	db	"GAL@@",	$ae,	$1,	$0		; ギャル@@,
	db	"SIBLI",	$b2,	$1,	$0		; きょうだい,
	db	"CHILD",	$f0,	$1,	$0		; こども@@,
	db	"MYSEL",	$54,	$2,	$0		; じぶん@@,
	db	"I WAS",	$56,	$2,	$0		; じぶんが@,
	db	"TO ME",	$58,	$2,	$0		; じぶんに@,
	db	"MY@@@",	$5a,	$2,	$0		; じぶんの@,
	db	"I AM@",	$5c,	$2,	$0		; じぶんは@,
	db	"I'VE@",	$5e,	$2,	$0		; じぶんを@,
	db	"WHO@@",	$18,	$3,	$0		; だれ@@@,
	db	"SOMEO",	$1a,	$3,	$0		; だれか@@,
	db	"WHO W",	$1c,	$3,	$0		; だれが@@,
	db	"TO WH",	$1e,	$3,	$0		; だれに@@,
	db	"WHOSE",	$20,	$3,	$0		; だれの@@,
	db	"WHO I",	$22,	$3,	$0		; だれも@@,
	db	"IT'S@",	$24,	$3,	$0		; だれを@@,
	db	"LADY@",	$38,	$3,	$0		; ちゃん@@,
	db	"FRIEN",	$b8,	$3,	$0		; ともだち@,
	db	"ALLY@",	$d4,	$3,	$0		; なかま@@,
	db	"PEOPL",	$62,	$4,	$0		; ひと@@@,
	db	"DUDE@",	$98,	$4,	$0		; ボーイ@@,
	db	"THEY@",	$a0,	$4,	$0		; ボク@@@,
	db	"THEY ",	$a2,	$4,	$0		; ボクが@@,
	db	"TO TH",	$a4,	$4,	$0		; ボクに@@,
	db	"THEIR",	$a6,	$4,	$0		; ボクの@@,
	db	"THEY'",	$a8,	$4,	$0		; ボクは@@,
	db	"THEY'",	$aa,	$4,	$0		; ボクを@@,
	db	"WE@@@",	$4,		$5,	$0		; みんな@@,
	db	"BEEN@",	$6,		$5,	$0		; みんなが@,
	db	"TO US",	$8,		$5,	$0		; みんなに@,
	db	"OUR@@",	$a,		$5,	$0		; みんなの@,
	db	"WE'RE",	$c,		$5,	$0		; みんなは@,
	db	"RIVAL",	$8a,	$5,	$0		; ライバル@,
	db	"SHE@@",	$c2,	$5,	$0		; わたし@@,
	db	"SHE W",	$c4,	$5,	$0		; わたしが@,
	db	"TO HE",	$c6,	$5,	$0		; わたしに@,
	db	"HERS@",	$c8,	$5,	$0		; わたしの@,
	db	"SHE I",	$ca,	$5,	$0		; わたしは@,
	db	"SOME@",	$cc,	$5,	$0		; わたしを@,

.Battle:
	db	"MATCH",	$18,	$0,	$0		; あいしょう,
	db	"GO!@@",	$88,	$0,	$0		; いけ！@@,
	db	"NO. 1",	$96,	$0,	$0		; いちばん@,
	db	"DECID",	$4c,	$1,	$0		; かくご@@,
	db	"I WIN",	$54,	$1,	$0		; かたせて@,
	db	"WINS@",	$56,	$1,	$0		; かち@@@,
	db	"WIN@@",	$58,	$1,	$0		; かつ@@@,
	db	"WON@@",	$60,	$1,	$0		; かった@@,
	db	"IF I ",	$62,	$1,	$0		; かったら@,
	db	"I'LL ",	$64,	$1,	$0		; かって@@,
	db	"CANT ",	$66,	$1,	$0		; かてない@,
	db	"CAN W",	$68,	$1,	$0		; かてる@@,
	db	"NO MA",	$70,	$1,	$0		; かなわない,
	db	"SPIRI",	$84,	$1,	$0		; きあい@@,
	db	"DECID",	$a8,	$1,	$0		; きめた@@,
	db	"ACE C",	$b6,	$1,	$0		; きりふだ@,
	db	"HI-YA",	$c2,	$1,	$0		; くらえ@@,
	db	"COME ",	$da,	$1,	$0		; こい！@@,
	db	"ATTAC",	$e0,	$1,	$0		; こうげき@,
	db	"GIVE ",	$e2,	$1,	$0		; こうさん@,
	db	"GUTS@",	$8,		$2,	$0		; こんじょう,
	db	"TALEN",	$16,	$2,	$0		; さいのう@,
	db	"STRAT",	$1a,	$2,	$0		; さくせん@,
	db	"SMITE",	$22,	$2,	$0		; さばき@@,
	db	"MATCH",	$7e,	$2,	$0		; しょうぶ@,
	db	"VICTO",	$80,	$2,	$0		; しょうり@,
	db	"OFFEN",	$b4,	$2,	$0		; せめ@@@,
	db	"SENSE",	$b6,	$2,	$0		; センス@@,
	db	"VERSU",	$e6,	$2,	$0		; たいせん@,
	db	"FIGHT",	$f6,	$2,	$0		; たたかい@,
	db	"POWER",	$32,	$3,	$0		; ちから@@,
	db	"TASK@",	$36,	$3,	$0		; チャレンジ,
	db	"STRON",	$58,	$3,	$0		; つよい@@,
	db	"TOO M",	$5a,	$3,	$0		; つよすぎ@,
	db	"HARD@",	$5c,	$3,	$0		; つらい@@,
	db	"TERRI",	$5e,	$3,	$0		; つらかった,
	db	"GO EA",	$6c,	$3,	$0		; てかげん@,
	db	"FOE@@",	$6e,	$3,	$0		; てき@@@,
	db	"GENIU",	$90,	$3,	$0		; てんさい@,
	db	"LEGEN",	$94,	$3,	$0		; でんせつ@,
	db	"TRAIN",	$c6,	$3,	$0		; トレーナー,
	db	"ESCAP",	$4,		$4,	$0		; にげ@@@,
	db	"LUKEW",	$10,	$4,	$0		; ぬるい@@,
	db	"AIM@@",	$16,	$4,	$0		; ねらう@@,
	db	"BATTL",	$4a,	$4,	$0		; バトル@@,
	db	"FIGHT",	$72,	$4,	$0		; ファイト@,
	db	"REVIV",	$78,	$4,	$0		; ふっかつ@,
	db	"POINT",	$94,	$4,	$0		; ポイント@,
	db	"POKÉM",	$ac,	$4,	$0		; ポケモン@,
	db	"SERIO",	$bc,	$4,	$0		; ほんき@@,
	db	"OH NO",	$c4,	$4,	$0		; まいった！,
	db	"LOSS@",	$c8,	$4,	$0		; まけ@@@,
	db	"YOU L",	$ca,	$4,	$0		; まけたら@,
	db	"LOST@",	$cc,	$4,	$0		; まけて@@,
	db	"LOSE@",	$ce,	$4,	$0		; まける@@,
	db	"GUARD",	$ea,	$4,	$0		; まもり@@,
	db	"PARTN",	$f2,	$4,	$0		; みかた@@,
	db	"REJEC",	$fe,	$4,	$0		; みとめない,
	db	"ACCEP",	$0,		$5,	$0		; みとめる@,
	db	"UNBEA",	$16,	$5,	$0		; むてき@@,
	db	"GOT I",	$3c,	$5,	$0		; もらった！,
	db	"EASY@",	$7a,	$5,	$0		; よゆう@@,
	db	"WEAK@",	$82,	$5,	$0		; よわい@@,
	db	"TOO W",	$84,	$5,	$0		; よわすぎ@,
	db	"PUSHO",	$8e,	$5,	$0		; らくしょう,
	db	"CHIEF",	$9e,	$5,	$0		; りーダー@,
	db	"RULE@",	$a0,	$5,	$0		; ルール@@,
	db	"LEVEL",	$a6,	$5,	$0		; レべル@@,
	db	"MOVE@",	$be,	$5,	$0		; わざ@@@,

.Exclamations:
	db	"!@@@@",	$0,		$0,	$0		; ！@@@@,
	db	"!!@@@",	$2,		$0,	$0		; ！！@@@,
	db	"!?@@@",	$4,		$0,	$0		; ！？@@@,
	db	"?@@@@",	$6,		$0,	$0		; ？@@@@,
	db	"…@@@@",	$8,		$0,	$0		; ⋯@@@@,
	db	"…!@@@",	$a,		$0,	$0		; ⋯！@@@,
	db	"………@@",	$c,		$0,	$0		; ⋯⋯⋯@@,
	db	"-@@@@",	$e,		$0,	$0		; ー@@@@,
	db	"- - -",	$10,	$0,	$0		; ーーー@@,
	db	"UH-OH",	$14,	$0,	$0		; あーあ@@,
	db	"WAAAH",	$16,	$0,	$0		; あーん@@,
	db	"AHAHA",	$52,	$0,	$0		; あははー@,
	db	"OH?@@",	$54,	$0,	$0		; あら@@@,
	db	"NOPE@",	$72,	$0,	$0		; いえ@@@,
	db	"YES@@",	$74,	$0,	$0		; イエス@@,
	db	"URGH@",	$ac,	$0,	$0		; うう@@@,
	db	"HMM@@",	$ae,	$0,	$0		; うーん@@,
	db	"WHOAH",	$b0,	$0,	$0		; うおー！@,
	db	"WROOA",	$b2,	$0,	$0		; うおりゃー,
	db	"WOW@@",	$bc,	$0,	$0		; うひょー@,
	db	"GIGGL",	$be,	$0,	$0		; うふふ@@,
	db	"SHOCK",	$ca,	$0,	$0		; うわー@@,
	db	"CRIES",	$cc,	$0,	$0		; うわーん@,
	db	"AGREE",	$d2,	$0,	$0		; ええ@@@,
	db	"EH?@@",	$d4,	$0,	$0		; えー@@@,
	db	"CRY@@",	$d6,	$0,	$0		; えーん@@,
	db	"EHEHE",	$dc,	$0,	$0		; えへへ@@,
	db	"HOLD ",	$e0,	$0,	$0		; おいおい@,
	db	"OH, Y",	$e2,	$0,	$0		; おお@@@,
	db	"OOPS@",	$c,		$1,	$0		; おっと@@,
	db	"SHOCK",	$42,	$1,	$0		; がーん@@,
	db	"EEK@@",	$aa,	$1,	$0		; キャー@@,
	db	"GRAAA",	$ac,	$1,	$0		; ギャー@@,
	db	"HE-HE",	$bc,	$1,	$0		; ぐふふふふ,
	db	"ICK!@",	$ce,	$1,	$0		; げっ@@@,
	db	"WEEP@",	$3e,	$2,	$0		; しくしく@,
	db	"HMPH@",	$2e,	$3,	$0		; ちえっ@@,
	db	"BLUSH",	$86,	$3,	$0		; てへ@@@,
	db	"NO@@@",	$20,	$4,	$0		; ノー@@@,
	db	"HUH?@",	$2a,	$4,	$0		; はあー@@,
	db	"YUP@@",	$30,	$4,	$0		; はい@@@,
	db	"HAHAH",	$48,	$4,	$0		; はっはっは,
	db	"AIYEE",	$56,	$4,	$0		; ひいー@@,
	db	"HIYAH",	$6a,	$4,	$0		; ひゃあ@@,
	db	"FUFU@",	$7c,	$4,	$0		; ふっふっふ,
	db	"MUTTE",	$7e,	$4,	$0		; ふにゃ@@,
	db	"LOL@@",	$80,	$4,	$0		; ププ@@@,
	db	"SNORT",	$82,	$4,	$0		; ふふん@@,
	db	"HUMPH",	$88,	$4,	$0		; ふん@@@,
	db	"HEHEH",	$8e,	$4,	$0		; へっへっへ,
	db	"HEHE@",	$90,	$4,	$0		; へへー@@,
	db	"HOHOH",	$9c,	$4,	$0		; ほーほほほ,
	db	"UH-HU",	$b6,	$4,	$0		; ほら@@@,
	db	"OH, D",	$c0,	$4,	$0		; まあ@@@,
	db	"ARRGH",	$10,	$5,	$0		; むきー！！,
	db	"MUFU@",	$18,	$5,	$0		; むふー@@,
	db	"MUFUF",	$1a,	$5,	$0		; むふふ@@,
	db	"MMM@@",	$1c,	$5,	$0		; むむ@@@,
	db	"OH-KA",	$6a,	$5,	$0		; よーし@@,
	db	"OKAY!",	$72,	$5,	$0		; よし！@@,
	db	"LALAL",	$98,	$5,	$0		; ラララ@@,
	db	"YAY@@",	$ac,	$5,	$0		; わーい@@,
	db	"AWW!@",	$b0,	$5,	$0		; わーん！！,
	db	"WOWEE",	$b2,	$5,	$0		; ワオ@@@,
	db	"GWAH!",	$ce,	$5,	$0		; わっ！！@,
	db	"WAHAH",	$d0,	$5,	$0		; わははは！,

.Conversation:
	db	"LISTE",	$50,	$0,	$0		; あのね@@,
	db	"NOT V",	$6e,	$0,	$0		; あんまり@,
	db	"MEAN@",	$8e,	$0,	$0		; いじわる@,
	db	"LIE@@",	$b6,	$0,	$0		; うそ@@@,
	db	"LAY@@",	$c4,	$0,	$0		; うむ@@@,
	db	"OI@@@",	$e4,	$0,	$0		; おーい@@,
	db	"SUGGE",	$6,		$1,	$0		; おすすめ@,
	db	"NITWI",	$1e,	$1,	$0		; おばかさん,
	db	"QUITE",	$6e,	$1,	$0		; かなり@@,
	db	"FROM@",	$7a,	$1,	$0		; から@@@,
	db	"FEELI",	$98,	$1,	$0		; きぶん@@,
	db	"BUT@@",	$d6,	$1,	$0		; けど@@@,
	db	"HOWEV",	$ea,	$1,	$0		; こそ@@@,
	db	"CASE@",	$ee,	$1,	$0		; こと@@@,
	db	"MISS@",	$12,	$2,	$0		; さあ@@@,
	db	"HOW@@",	$1e,	$2,	$0		; さっぱり@,
	db	"HIT@@",	$20,	$2,	$0		; さて@@@,
	db	"ENOUG",	$72,	$2,	$0		; じゅうぶん,
	db	"SOON@",	$94,	$2,	$0		; すぐ@@@,
	db	"A LOT",	$98,	$2,	$0		; すごく@@,
	db	"A LIT",	$9a,	$2,	$0		; すこしは@,
	db	"AMAZI",	$a0,	$2,	$0		; すっっごい,
	db	"ENTIR",	$b0,	$2,	$0		; ぜーんぜん,
	db	"FULLY",	$b2,	$2,	$0		; ぜったい@,
	db	"AND S",	$ce,	$2,	$0		; それで@@,
	db	"ONLY@",	$f2,	$2,	$0		; だけ@@@,
	db	"AROUN",	$fc,	$2,	$0		; だって@@,
	db	"PROBA",	$6,		$3,	$0		; たぶん@@,
	db	"IF@@@",	$14,	$3,	$0		; たら@@@,
	db	"VERY@",	$3a,	$3,	$0		; ちょー@@,
	db	"A BIT",	$3c,	$3,	$0		; ちょっと@,
	db	"WILD@",	$4e,	$3,	$0		; ったら@@,
	db	"THAT'",	$50,	$3,	$0		; って@@@,
	db	"I MEA",	$62,	$3,	$0		; ていうか@,
	db	"EVEN ",	$88,	$3,	$0		; でも@@@,
	db	"MUST ",	$9c,	$3,	$0		; どうしても,
	db	"NATUR",	$a0,	$3,	$0		; とうぜん@,
	db	"GO AH",	$a2,	$3,	$0		; どうぞ@@,
	db	"FOR N",	$be,	$3,	$0		; とりあえず,
	db	"HEY?@",	$cc,	$3,	$0		; なあ@@@,
	db	"JOKIN",	$f4,	$3,	$0		; なんて@@,
	db	"READY",	$fc,	$3,	$0		; なんでも@,
	db	"SOMEH",	$fe,	$3,	$0		; なんとか@,
	db	"ALTHO",	$8,		$4,	$0		; には@@@,
	db	"PERFE",	$46,	$4,	$0		; バッチり@,
	db	"FIRML",	$52,	$4,	$0		; ばりばり@,
	db	"EQUAL",	$b0,	$4,	$0		; ほど@@@,
	db	"REALL",	$be,	$4,	$0		; ほんと@@,
	db	"TRULY",	$d0,	$4,	$0		; まさに@@,
	db	"SUREL",	$d2,	$4,	$0		; マジ@@@,
	db	"FOR S",	$d4,	$4,	$0		; マジで@@,
	db	"TOTAL",	$e4,	$4,	$0		; まったく@,
	db	"UNTIL",	$e6,	$4,	$0		; まで@@@,
	db	"AS IF",	$ec,	$4,	$0		; まるで@@,
	db	"MOOD@",	$e,		$5,	$0		; ムード@@,
	db	"RATHE",	$14,	$5,	$0		; むしろ@@,
	db	"NO WA",	$24,	$5,	$0		; めちゃ@@,
	db	"AWFUL",	$28,	$5,	$0		; めっぽう@,
	db	"ALMOS",	$2c,	$5,	$0		; もう@@@,
	db	"MODE@",	$2e,	$5,	$0		; モード@@,
	db	"MORE@",	$36,	$5,	$0		; もっと@@,
	db	"TOO L",	$38,	$5,	$0		; もはや@@,
	db	"FINAL",	$4a,	$5,	$0		; やっと@@,
	db	"ANY@@",	$4c,	$5,	$0		; やっぱり@,
	db	"INSTE",	$7c,	$5,	$0		; より@@@,
	db	"TERRI",	$a4,	$5,	$0		; れば@@@,

.Feelings:
	db	"MEET@",	$1a,	$0,	$0		; あいたい@,
	db	"PLAY@",	$32,	$0,	$0		; あそびたい,
	db	"GOES@",	$7c,	$0,	$0		; いきたい@,
	db	"GIDDY",	$b4,	$0,	$0		; うかれて@,
	db	"HAPPY",	$c6,	$0,	$0		; うれしい@,
	db	"GLEE@",	$c8,	$0,	$0		; うれしさ@,
	db	"EXCIT",	$d8,	$0,	$0		; エキサイト,
	db	"CRUCI",	$de,	$0,	$0		; えらい@@,
	db	"FUNNY",	$ec,	$0,	$0		; おかしい@,
	db	"GOT@@",	$8,		$1,	$0		; オッケー@,
	db	"GO HO",	$48,	$1,	$0		; かえりたい,
	db	"FAILS",	$5a,	$1,	$0		; がっくし@,
	db	"SAD@@",	$6c,	$1,	$0		; かなしい@,
	db	"TRY@@",	$80,	$1,	$0		; がんばって,
	db	"HEARS",	$86,	$1,	$0		; きがしない,
	db	"THINK",	$88,	$1,	$0		; きがする@,
	db	"HEAR@",	$8a,	$1,	$0		; ききたい@,
	db	"WANTS",	$90,	$1,	$0		; きになる@,
	db	"MISHE",	$96,	$1,	$0		; きのせい@,
	db	"DISLI",	$b4,	$1,	$0		; きらい@@,
	db	"ANGRY",	$be,	$1,	$0		; くやしい@,
	db	"ANGER",	$c0,	$1,	$0		; くやしさ@,
	db	"LONES",	$24,	$2,	$0		; さみしい@,
	db	"FAIL@",	$32,	$2,	$0		; ざんねん@,
	db	"JOY@@",	$36,	$2,	$0		; しあわせ@,
	db	"GETS@",	$44,	$2,	$0		; したい@@,
	db	"NEVER",	$46,	$2,	$0		; したくない,
	db	"DARN@",	$64,	$2,	$0		; しまった@,
	db	"DOWNC",	$82,	$2,	$0		; しょんぼり,
	db	"LIKES",	$92,	$2,	$0		; すき@@@,
	db	"DISLI",	$da,	$2,	$0		; だいきらい,
	db	"BORIN",	$dc,	$2,	$0		; たいくつ@,
	db	"CARE@",	$de,	$2,	$0		; だいじ@@,
	db	"ADORE",	$e4,	$2,	$0		; だいすき@,
	db	"DISAS",	$ea,	$2,	$0		; たいへん@,
	db	"ENJOY",	$0,		$3,	$0		; たのしい@,
	db	"ENJOY",	$2,		$3,	$0		; たのしすぎ,
	db	"EAT@@",	$8,		$3,	$0		; たべたい@,
	db	"USELE",	$e,		$3,	$0		; ダメダメ@,
	db	"LACKI",	$16,	$3,	$0		; たりない@,
	db	"BAD@@",	$34,	$3,	$0		; ちくしょー,
	db	"SHOUL",	$9e,	$3,	$0		; どうしよう,
	db	"EXCIT",	$ac,	$3,	$0		; ドキドキ@,
	db	"NICE@",	$d0,	$3,	$0		; ナイス@@,
	db	"DRINK",	$26,	$4,	$0		; のみたい@,
	db	"SURPR",	$60,	$4,	$0		; びっくり@,
	db	"FEAR@",	$74,	$4,	$0		; ふあん@@,
	db	"WOBBL",	$86,	$4,	$0		; ふらふら@,
	db	"WANT@",	$ae,	$4,	$0		; ほしい@@,
	db	"SHRED",	$b8,	$4,	$0		; ボロボロ@,
	db	"YET@@",	$e0,	$4,	$0		; まだまだ@,
	db	"WAIT@",	$e8,	$4,	$0		; まてない@,
	db	"CONTE",	$f0,	$4,	$0		; まんぞく@,
	db	"SEE@@",	$f8,	$4,	$0		; みたい@@,
	db	"RARE@",	$22,	$5,	$0		; めずらしい,
	db	"FIERY",	$2a,	$5,	$0		; メラメラ@,
	db	"NEGAT",	$46,	$5,	$0		; やだ@@@,
	db	"DONE@",	$48,	$5,	$0		; やったー@,
	db	"DANGE",	$50,	$5,	$0		; やばい@@,
	db	"DONE ",	$52,	$5,	$0		; やばすぎる,
	db	"DEFEA",	$54,	$5,	$0		; やられた@,
	db	"BEAT@",	$56,	$5,	$0		; やられて@,
	db	"GREAT",	$6e,	$5,	$0		; よかった@,
	db	"DOTIN",	$96,	$5,	$0		; ラブラブ@,
	db	"ROMAN",	$a8,	$5,	$0		; ロマン@@,
	db	"QUEST",	$aa,	$5,	$0		; ろんがい@,
	db	"REALI",	$b4,	$5,	$0		; わから@@,
	db	"REALI",	$b6,	$5,	$0		; わかり@@,
	db	"SUSPE",	$ba,	$5,	$0		; わくわく@,

.Conditions:
	db	"HOT@@",	$38,	$0,	$0		; あつい@@,
	db	"EXIST",	$3a,	$0,	$0		; あった@@,
	db	"APPRO",	$56,	$0,	$0		; あり@@@,
	db	"HAS@@",	$5e,	$0,	$0		; ある@@@,
	db	"HURRI",	$6a,	$0,	$0		; あわてて@,
	db	"GOOD@",	$70,	$0,	$0		; いい@@@,
	db	"LESS@",	$76,	$0,	$0		; いか@@@,
	db	"MEGA@",	$78,	$0,	$0		; イカス@@,
	db	"MOMEN",	$7a,	$0,	$0		; いきおい@,
	db	"GOING",	$8a,	$0,	$0		; いける@@,
	db	"WEIRD",	$8c,	$0,	$0		; いじょう@,
	db	"BUSY@",	$90,	$0,	$0		; いそがしい,
	db	"TOGET",	$9a,	$0,	$0		; いっしょに,
	db	"FULL@",	$9c,	$0,	$0		; いっぱい@,
	db	"ABSEN",	$a0,	$0,	$0		; いない@@,
	db	"BEING",	$a4,	$0,	$0		; いや@@@,
	db	"NEED@",	$a8,	$0,	$0		; いる@@@,
	db	"TASTY",	$c0,	$0,	$0		; うまい@@,
	db	"SKILL",	$c2,	$0,	$0		; うまく@@,
	db	"BIG@@",	$e6,	$0,	$0		; おおきい@,
	db	"LATE@",	$f2,	$0,	$0		; おくれ@@,
	db	"CLOSE",	$fa,	$0,	$0		; おしい@@,
	db	"AMUSI",	$2c,	$1,	$0		; おもしろい,
	db	"ENGAG",	$2e,	$1,	$0		; おもしろく,
	db	"COOL@",	$5c,	$1,	$0		; かっこいい,
	db	"CUTE@",	$7e,	$1,	$0		; かわいい@,
	db	"FLAWL",	$82,	$1,	$0		; かんぺき@,
	db	"PRETT",	$d0,	$1,	$0		; けっこう@,
	db	"HEALT",	$d8,	$1,	$0		; げんき@@,
	db	"SCARY",	$6,		$2,	$0		; こわい@@,
	db	"SUPER",	$14,	$2,	$0		; さいこう@,
	db	"COLD@",	$26,	$2,	$0		; さむい@@,
	db	"LIVEL",	$2c,	$2,	$0		; さわやか@,
	db	"FATED",	$38,	$2,	$0		; しかたない,
	db	"MUCH@",	$96,	$2,	$0		; すごい@@,
	db	"IMMEN",	$9c,	$2,	$0		; すごすぎ@,
	db	"FABUL",	$a4,	$2,	$0		; すてき@@,
	db	"ELSE@",	$e0,	$2,	$0		; たいした@,
	db	"ALRIG",	$e2,	$2,	$0		; だいじょぶ,
	db	"COSTL",	$ec,	$2,	$0		; たかい@@,
	db	"CORRE",	$f8,	$2,	$0		; ただしい@,
	db	"UNLIK",	$c,		$3,	$0		; だめ@@@,
	db	"SMALL",	$2c,	$3,	$0		; ちいさい@,
	db	"VARIE",	$30,	$3,	$0		; ちがう@@,
	db	"TIRED",	$48,	$3,	$0		; つかれ@@,
	db	"SKILL",	$b0,	$3,	$0		; とくい@@,
	db	"NON-S",	$b6,	$3,	$0		; とまらない,
	db	"NONE@",	$ce,	$3,	$0		; ない@@@,
	db	"NOTHI",	$d2,	$3,	$0		; なかった@,
	db	"NATUR",	$d8,	$3,	$0		; なし@@@,
	db	"BECOM",	$dc,	$3,	$0		; なって@@,
	db	"FAST@",	$50,	$4,	$0		; はやい@@,
	db	"SHINE",	$5a,	$4,	$0		; ひかる@@,
	db	"LOW@@",	$5c,	$4,	$0		; ひくい@@,
	db	"AWFUL",	$64,	$4,	$0		; ひどい@@,
	db	"ALONE",	$66,	$4,	$0		; ひとりで@,
	db	"BORED",	$68,	$4,	$0		; ひま@@@,
	db	"LACKS",	$76,	$4,	$0		; ふそく@@,
	db	"LOUSY",	$8c,	$4,	$0		; へた@@@,
	db	"MISTA",	$e2,	$4,	$0		; まちがって,
	db	"KIND@",	$42,	$5,	$0		; やさしい@,
	db	"WELL@",	$70,	$5,	$0		; よく@@@,
	db	"WEAKE",	$86,	$5,	$0		; よわって@,
	db	"SIMPL",	$8c,	$5,	$0		; らく@@@,
	db	"SEEMS",	$90,	$5,	$0		; らしい@@,
	db	"BADLY",	$d4,	$5,	$0		; わるい@@,

.Life:	
	db	"CHORE",	$64,	$0,	$0		; アルバイト,
	db	"HOME@",	$ba,	$0,	$0		; うち@@@,
	db	"MONEY",	$ee,	$0,	$0		; おかね@@,
	db	"SAVIN",	$f4,	$0,	$0		; おこづかい,
	db	"BATH@",	$24,	$1,	$0		; おふろ@@,
	db	"SCHOO",	$5e,	$1,	$0		; がっこう@,
	db	"REMEM",	$92,	$1,	$0		; きねん@@,
	db	"GROUP",	$c6,	$1,	$0		; グループ@,
	db	"GOTCH",	$d2,	$1,	$0		; ゲット@@,
	db	"EXCHA",	$de,	$1,	$0		; こうかん@,
	db	"WORK@",	$40,	$2,	$0		; しごと@@,
	db	"TRAIN",	$74,	$2,	$0		; しゅぎょう,
	db	"CLASS",	$76,	$2,	$0		; じゅぎょう,
	db	"LESSO",	$78,	$2,	$0		; じゅく@@,
	db	"EVOLV",	$88,	$2,	$0		; しんか@@,
	db	"HANDB",	$90,	$2,	$0		; ずかん@@,
	db	"LIVIN",	$ae,	$2,	$0		; せいかつ@,
	db	"TEACH",	$b8,	$2,	$0		; せんせい@,
	db	"CENTE",	$ba,	$2,	$0		; センター@,
	db	"TOWER",	$28,	$3,	$0		; タワー@@,
	db	"LINK@",	$40,	$3,	$0		; つうしん@,
	db	"TEST@",	$7e,	$3,	$0		; テスト@@,
	db	"TV@@@",	$8c,	$3,	$0		; テレビ@@,
	db	"PHONE",	$96,	$3,	$0		; でんわ@@,
	db	"ITEM@",	$9a,	$3,	$0		; どうぐ@@,
	db	"TRADE",	$c4,	$3,	$0		; トレード@,
	db	"NAME@",	$e8,	$3,	$0		; なまえ@@,
	db	"NEWS@",	$a,		$4,	$0		; ニュース@,
	db	"POPUL",	$c,		$4,	$0		; にんき@@,
	db	"PARTY",	$2e,	$4,	$0		; パーティー,
	db	"STUDY",	$92,	$4,	$0		; べんきょう,
	db	"MACHI",	$d6,	$4,	$0		; マシン@@,
	db	"CARD@",	$1e,	$5,	$0		; めいし@@,
	db	"MESSA",	$26,	$5,	$0		; メッセージ,
	db	"MAKEO",	$3a,	$5,	$0		; もようがえ,
	db	"DREAM",	$5a,	$5,	$0		; ゆめ@@@,
	db	"DAY C",	$66,	$5,	$0		; ようちえん,
	db	"RADIO",	$92,	$5,	$0		; ラジオ@@,
	db	"WORLD",	$ae,	$5,	$0		; ワールド@,

.Hobbies:
	db	"IDOL@",	$1e,	$0,	$0		; アイドル@,
	db	"ANIME",	$4c,	$0,	$0		; アニメ@@,
	db	"SONG@",	$b8,	$0,	$0		; うた@@@,
	db	"MOVIE",	$d0,	$0,	$0		; えいが@@,
	db	"CANDY",	$ea,	$0,	$0		; おかし@@,
	db	"CHAT@",	$4,		$1,	$0		; おしゃべり,
	db	"TOYHO",	$28,	$1,	$0		; おままごと,
	db	"TOYS@",	$30,	$1,	$0		; おもちゃ@,
	db	"MUSIC",	$38,	$1,	$0		; おんがく@,
	db	"CARDS",	$3e,	$1,	$0		; カード@@,
	db	"SHOPP",	$46,	$1,	$0		; かいもの@,
	db	"GOURM",	$c8,	$1,	$0		; グルメ@@,
	db	"GAME@",	$cc,	$1,	$0		; ゲーム@@,
	db	"MAGAZ",	$1c,	$2,	$0		; ざっし@@,
	db	"WALK@",	$34,	$2,	$0		; さんぽ@@,
	db	"BIKE@",	$50,	$2,	$0		; じてんしゃ,
	db	"HOBBI",	$7a,	$2,	$0		; しゅみ@@,
	db	"SPORT",	$a8,	$2,	$0		; スポーツ@,
	db	"DIET@",	$d8,	$2,	$0		; ダイエット,
	db	"TREAS",	$f0,	$2,	$0		; たからもの,
	db	"TRAVE",	$4,		$3,	$0		; たび@@@,
	db	"DANCE",	$2a,	$3,	$0		; ダンス@@,
	db	"FISHI",	$60,	$3,	$0		; つり@@@,
	db	"DATE@",	$6a,	$3,	$0		; デート@@,
	db	"TRAIN",	$92,	$3,	$0		; でんしゃ@,
	db	"PLUSH",	$e,		$4,	$0		; ぬいぐるみ,
	db	"PC@@@",	$3e,	$4,	$0		; パソコン@,
	db	"FLOWE",	$4c,	$4,	$0		; はな@@@,
	db	"HERO@",	$58,	$4,	$0		; ヒーロー@,
	db	"NAP@@",	$6e,	$4,	$0		; ひるね@@,
	db	"HEROI",	$70,	$4,	$0		; ヒロイン@,
	db	"JOURN",	$96,	$4,	$0		; ぼうけん@,
	db	"BOARD",	$9a,	$4,	$0		; ボード@@,
	db	"BALL@",	$9e,	$4,	$0		; ボール@@,
	db	"BOOK@",	$ba,	$4,	$0		; ほん@@@,
	db	"MANGA",	$ee,	$4,	$0		; マンガ@@,
	db	"PROMI",	$40,	$5,	$0		; やくそく@,
	db	"HOLID",	$44,	$5,	$0		; やすみ@@,
	db	"PLANS",	$74,	$5,	$0		; よてい@@,

.Actions:	
	db	"MEETS",	$20,	$0,	$0		; あう@@@,
	db	"CONCE",	$24,	$0,	$0		; あきらめ@,
	db	"GIVE@",	$28,	$0,	$0		; あげる@@,
	db	"GIVES",	$2e,	$0,	$0		; あせる@@,
	db	"PLAYE",	$30,	$0,	$0		; あそび@@,
	db	"PLAYS",	$34,	$0,	$0		; あそぶ@@,
	db	"COLLE",	$3e,	$0,	$0		; あつめ@@,
	db	"WALKI",	$60,	$0,	$0		; あるき@@,
	db	"WALKS",	$62,	$0,	$0		; あるく@@,
	db	"WENT@",	$7e,	$0,	$0		; いく@@@,
	db	"GO@@@",	$86,	$0,	$0		; いけ@@@,
	db	"WAKE ",	$f0,	$0,	$0		; おき@@@,
	db	"WAKES",	$f6,	$0,	$0		; おこり@@,
	db	"ANGER",	$f8,	$0,	$0		; おこる@@,
	db	"TEACH",	$fe,	$0,	$0		; おしえ@@,
	db	"TEACH",	$0,		$1,	$0		; おしえて@,
	db	"PLEAS",	$1a,	$1,	$0		; おねがい@,
	db	"LEARN",	$26,	$1,	$0		; おぼえ@@,
	db	"CHANG",	$4a,	$1,	$0		; かえる@@,
	db	"TRUST",	$74,	$1,	$0		; がまん@@,
	db	"HEARI",	$8c,	$1,	$0		; きく@@@,
	db	"TRAIN",	$8e,	$1,	$0		; きたえ@@,
	db	"CHOOS",	$a6,	$1,	$0		; きめ@@@,
	db	"COME@",	$c4,	$1,	$0		; くる@@@,
	db	"SEARC",	$18,	$2,	$0		; さがし@@,
	db	"CAUSE",	$2a,	$2,	$0		; さわぎ@@,
	db	"THESE",	$42,	$2,	$0		; した@@@,
	db	"KNOW@",	$4a,	$2,	$0		; しって@@,
	db	"KNOWS",	$4e,	$2,	$0		; して@@@,
	db	"REFUS",	$52,	$2,	$0		; しない@@,
	db	"STORE",	$60,	$2,	$0		; しまう@@,
	db	"BRAG@",	$66,	$2,	$0		; じまん@@,
	db	"IGNOR",	$84,	$2,	$0		; しらない@,
	db	"THINK",	$86,	$2,	$0		; しる@@@,
	db	"BELIE",	$8a,	$2,	$0		; しんじて@,
	db	"SLIDE",	$aa,	$2,	$0		; する@@@,
	db	"EATS@",	$a,		$3,	$0		; たべる@@,
	db	"USE@@",	$42,	$3,	$0		; つかう@@,
	db	"USES@",	$44,	$3,	$0		; つかえ@@,
	db	"USING",	$46,	$3,	$0		; つかって@,
	db	"COULD",	$70,	$3,	$0		; できない@,
	db	"CAPAB",	$72,	$3,	$0		; できる@@,
	db	"VANIS",	$84,	$3,	$0		; でない@@,
	db	"APPEA",	$8a,	$3,	$0		; でる@@@,
	db	"THROW",	$d6,	$3,	$0		; なげる@@,
	db	"WORRY",	$ea,	$3,	$0		; なやみ@@,
	db	"SLEPT",	$18,	$4,	$0		; ねられ@@,
	db	"SLEEP",	$1a,	$4,	$0		; ねる@@@,
	db	"RELEA",	$24,	$4,	$0		; のがし@@,
	db	"DRINK",	$28,	$4,	$0		; のむ@@@,
	db	"RUNS@",	$3a,	$4,	$0		; はしり@@,
	db	"RUN@@",	$3c,	$4,	$0		; はしる@@,
	db	"WORKS",	$40,	$4,	$0		; はたらき@,
	db	"WORKI",	$42,	$4,	$0		; はたらく@,
	db	"SINK@",	$4e,	$4,	$0		; はまって@,
	db	"SMACK",	$7a,	$4,	$0		; ぶつけ@@,
	db	"PRAIS",	$b4,	$4,	$0		; ほめ@@@,
	db	"SHOW@",	$f6,	$4,	$0		; みせて@@,
	db	"LOOKS",	$fc,	$4,	$0		; みて@@@,
	db	"SEES@",	$2,		$5,	$0		; みる@@@,
	db	"SEEK@",	$20,	$5,	$0		; めざす@@,
	db	"OWN@@",	$34,	$5,	$0		; もって@@,
	db	"TAKE@",	$58,	$5,	$0		; ゆずる@@,
	db	"ALLOW",	$5c,	$5,	$0		; ゆるす@@,
	db	"FORGE",	$5e,	$5,	$0		; ゆるせ@@,
	db	"FORGE",	$9a,	$5,	$0		; られない@,
	db	"APPEA",	$9c,	$5,	$0		; られる@@,
	db	"FAINT",	$b8,	$5,	$0		; わかる@@,
	db	"FAINT",	$c0,	$5,	$0		; わすれ@@,

.Time:	
	db	"FALL@",	$22,	$0,	$0		; あき@@@,
	db	"MORNI",	$2a,	$0,	$0		; あさ@@@,
	db	"TOMOR",	$2c,	$0,	$0		; あした@@,
	db	"DAY@@",	$94,	$0,	$0		; いちにち@,
	db	"SOMET",	$98,	$0,	$0		; いつか@@,
	db	"ALWAY",	$9e,	$0,	$0		; いつも@@,
	db	"CURRE",	$a2,	$0,	$0		; いま@@@,
	db	"FOREV",	$ce,	$0,	$0		; えいえん@,
	db	"DAYS@",	$12,	$1,	$0		; おととい@,
	db	"END@@",	$36,	$1,	$0		; おわり@@,
	db	"TUESD",	$78,	$1,	$0		; かようび@,
	db	"Y'DAY",	$94,	$1,	$0		; きのう@@,
	db	"TODAY",	$b0,	$1,	$0		; きょう@@,
	db	"FRIDA",	$b8,	$1,	$0		; きんようび,
	db	"MONDA",	$d4,	$1,	$0		; げつようび,
	db	"LATER",	$f4,	$1,	$0		; このあと@,
	db	"EARLI",	$f6,	$1,	$0		; このまえ@,
	db	"ANOTH",	$c,		$2,	$0		; こんど@@,
	db	"TIME@",	$3c,	$2,	$0		; じかん@@,
	db	"DECAD",	$70,	$2,	$0		; じゅうねん,
	db	"WEDNS",	$8e,	$2,	$0		; すいようび,
	db	"START",	$9e,	$2,	$0		; スタート@,
	db	"MONTH",	$a2,	$2,	$0		; ずっと@@,
	db	"STOP@",	$a6,	$2,	$0		; ストップ@,
	db	"NOW@@",	$c4,	$2,	$0		; そのうち@,
	db	"FINAL",	$3e,	$3,	$0		; ついに@@,
	db	"NEXT@",	$4a,	$3,	$0		; つぎ@@@,
	db	"SATUR",	$ba,	$3,	$0		; どようび@,
	db	"SUMME",	$da,	$3,	$0		; なつ@@@,
	db	"SUNDA",	$6,		$4,	$0		; にちようび,
	db	"OUTSE",	$38,	$4,	$0		; はじめ@@,
	db	"SPRIN",	$54,	$4,	$0		; はる@@@,
	db	"DAYTI",	$6c,	$4,	$0		; ひる@@@,
	db	"WINTE",	$84,	$4,	$0		; ふゆ@@@,
	db	"DAILY",	$c6,	$4,	$0		; まいにち@,
	db	"THURS",	$30,	$5,	$0		; もくようび,
	db	"NITET",	$76,	$5,	$0		; よなか@@,
	db	"NIGHT",	$7e,	$5,	$0		; よる@@@,
	db	"WEEK@",	$88,	$5,	$0		; らいしゅう,

.Farewells:	
	db	"WILL@",	$92,	$0,	$0		; いたします,
	db	"AYE@@",	$32,	$1,	$0		; おります@,
	db	"?!@@@",	$3c,	$1,	$0		; か！？@@,
	db	"HM?@@",	$44,	$1,	$0		; かい？@@,
	db	"Y'THI",	$50,	$1,	$0		; かしら？@,
	db	"IS IT",	$6a,	$1,	$0		; かな？@@,
	db	"BE@@@",	$76,	$1,	$0		; かも@@@,
	db	"GIMME",	$ca,	$1,	$0		; くれ@@@,
	db	"COULD",	$e8,	$1,	$0		; ございます,
	db	"TEND ",	$3a,	$2,	$0		; しがち@@,
	db	"WOULD",	$62,	$2,	$0		; します@@,
	db	"IS@@@",	$6a,	$2,	$0		; じゃ@@@,
	db	"ISNT ",	$6e,	$2,	$0		; じゃん@@,
	db	"LET'S",	$7c,	$2,	$0		; しよう@@,
	db	"OTHER",	$ac,	$2,	$0		; ぜ！@@@,
	db	"ARE@@",	$bc,	$2,	$0		; ぞ！@@@,
	db	"WAS@@",	$d4,	$2,	$0		; た@@@@,
	db	"WERE@",	$d6,	$2,	$0		; だ@@@@,
	db	"THOSE",	$ee,	$2,	$0		; だからね@,
	db	"ISN'T",	$f4,	$2,	$0		; だぜ@@@,
	db	"WON'T",	$fa,	$2,	$0		; だった@@,
	db	"CAN'T",	$fe,	$2,	$0		; だね@@@,
	db	"CAN@@",	$10,	$3,	$0		; だよ@@@,
	db	"DON'T",	$12,	$3,	$0		; だよねー！,
	db	"DO@@@",	$26,	$3,	$0		; だわ@@@,
	db	"DOES@",	$4c,	$3,	$0		; ッス@@@,
	db	"WHOM@",	$52,	$3,	$0		; ってかんじ,
	db	"WHICH",	$54,	$3,	$0		; っぱなし@,
	db	"WASN'",	$56,	$3,	$0		; つもり@@,
	db	"WEREN",	$64,	$3,	$0		; ていない@,
	db	"HAVE@",	$66,	$3,	$0		; ている@@,
	db	"HAVEN",	$68,	$3,	$0		; でーす！@,
	db	"A@@@@",	$74,	$3,	$0		; でした@@,
	db	"AN@@@",	$76,	$3,	$0		; でしょ？@,
	db	"NOT@@",	$78,	$3,	$0		; でしょー！,
	db	"THERE",	$7a,	$3,	$0		; です@@@,
	db	"OK?@@",	$7c,	$3,	$0		; ですか？@,
	db	"SO@@@",	$80,	$3,	$0		; ですよ@@,
	db	"MAYBE",	$82,	$3,	$0		; ですわ@@,
	db	"ABOUT",	$a4,	$3,	$0		; どうなの？,
	db	"OVER@",	$a8,	$3,	$0		; どうよ？@,
	db	"IT@@@",	$aa,	$3,	$0		; とかいって,
	db	"FOR@@",	$e0,	$3,	$0		; なの@@@,
	db	"ON@@@",	$e2,	$3,	$0		; なのか@@,
	db	"OFF@@",	$e4,	$3,	$0		; なのだ@@,
	db	"AS@@@",	$e6,	$3,	$0		; なのよ@@,
	db	"TO@@@",	$f2,	$3,	$0		; なんだね@,
	db	"WITH@",	$f8,	$3,	$0		; なんです@,
	db	"BETTE",	$fa,	$3,	$0		; なんてね@,
	db	"EVER@",	$12,	$4,	$0		; ね@@@@,
	db	"SINCE",	$14,	$4,	$0		; ねー@@@,
	db	"OF@@@",	$1c,	$4,	$0		; の@@@@,
	db	"BELON",	$1e,	$4,	$0		; の？@@@,
	db	"AT@@@",	$44,	$4,	$0		; ばっかり@,
	db	"IN@@@",	$c2,	$4,	$0		; まーす！@,
	db	"OUT@@",	$d8,	$4,	$0		; ます@@@,
	db	"TOO@@",	$da,	$4,	$0		; ますわ@@,
	db	"LIKE@",	$dc,	$4,	$0		; ません@@,
	db	"DID@@",	$fa,	$4,	$0		; みたいな@,
	db	"WITHO",	$60,	$5,	$0		; よ！@@@,
	db	"AFTER",	$68,	$5,	$0		; よー@@@,
	db	"BEFOR",	$6c,	$5,	$0		; よーん@@,
	db	"WHILE",	$78,	$5,	$0		; よね@@@,
	db	"THAN@",	$a2,	$5,	$0		; るよ@@@,
	db	"ONCE@",	$bc,	$5,	$0		; わけ@@@,
	db	"ANYWH",	$d2,	$5,	$0		; わよ！@@,

.ThisAndThat:
	db	"HIGHS",	$12, $0, $0		; ああ@@@,
	db	"LOWS@",	$3c, $0, $0		; あっち@@,
	db	"UM@@@",	$4e, $0, $0		; あの@@@,
	db	"REAR@",	$5c, $0, $0		; ありゃ@@,
	db	"THING",	$66, $0, $0		; あれ@@@,
	db	"THING",	$68, $0, $0		; あれは@@,
	db	"BELOW",	$6c, $0, $0		; あんな@@,
	db	"HIGH@",	$dc, $1, $0		; こう@@@,
	db	"HERE@",	$ec, $1, $0		; こっち@@,
	db	"INSID",	$f2, $1, $0		; この@@@,
	db	"OUTSI",	$fe, $1, $0		; こりゃ@@,
	db	"BESID",	$0,	 $2, $0		; これ@@@,
	db	"THIS ",	$2,	 $2, $0		; これだ！@,
	db	"THIS@",	$4,	 $2, $0		; これは@@,
	db	"EVERY",	$e,	 $2, $0		; こんな@@,
	db	"SEEMS",	$be, $2, $0		; そう@@@,
	db	"DOWN@",	$c0, $2, $0		; そっち@@,
	db	"THAT@",	$c2, $2, $0		; その@@@,
	db	"THAT ",	$c6, $2, $0		; そりゃ@@,
	db	"THAT ",	$c8, $2, $0		; それ@@@,
	db	"THATS",	$cc, $2, $0		; それだ！@,
	db	"THAT'",	$d0, $2, $0		; それは@@,
	db	"THAT ",	$d2, $2, $0		; そんな@@,
	db	"UP@@@",	$98, $3, $0		; どう@@@,
	db	"CHOIC",	$b2, $3, $0		; どっち@@,
	db	"FAR@@",	$b4, $3, $0		; どの@@@,
	db	"AWAY@",	$c0, $3, $0		; どりゃ@@,
	db	"NEAR@",	$c2, $3, $0		; どれ@@@,
	db	"WHERE",	$c8, $3, $0		; どれを@@,
	db	"WHEN@",	$ca, $3, $0		; どんな@@,
	db	"WHAT@",	$de, $3, $0		; なに@@@,
	db	"DEEP@",	$ec, $3, $0		; なんか@@,
	db	"SHALL",	$f0, $3, $0		; なんだ@@,
	db	"WHY@@",	$f6, $3, $0		; なんで@@,
	db	"CONFU",	$0,  $4, $0		; なんなんだ,
	db	"OPPOS",	$2,	 $4, $0		; なんの@@,

MobileEZChatData_WordAndPageCounts:
macro_11f220: MACRO
; parameter: number of words
	db \1
; 12 words per page (0-based indexing)
x = \1 / 12
if \1 % 12 == 0
x = x + -1
endc
	db x
ENDM
	macro_11f220 18 ; 01: Types
	macro_11f220 36 ; 02: Greetings
	macro_11f220 69 ; 03: People
	macro_11f220 69 ; 04: Battle
	macro_11f220 66 ; 05: Exclamations
	macro_11f220 66 ; 06: Conversation
	macro_11f220 69 ; 07: Feelings
	macro_11f220 66 ; 08: Conditions
	macro_11f220 39 ; 09: Life
	macro_11f220 39 ; 0a: Hobbies
	macro_11f220 69 ; 0b: Actions
	macro_11f220 39 ; 0c: Time
	macro_11f220 66 ; 0d: Farewells
	macro_11f220 36 ; 0e: ThisAndThat

EZChat_SortedWords:
; Addresses in WRAM bank 3 where EZChat words beginning
; with the given kana are sorted in memory, and the pre-
; allocated size for each.
; These arrays are expanded dynamically to accomodate
; any Pokemon you've seen that starts with each kana.\
macro_11f23c: MACRO
	dw x - w3_d000, \1
x = x + 2 * \1
ENDM
x = $d012
	macro_11f23c $2f ; a
	macro_11f23c $1e ; i
	macro_11f23c $11 ; u
	macro_11f23c $09 ; e
	macro_11f23c $2e ; o
	macro_11f23c $24 ; ka_ga
	macro_11f23c $1b ; ki_gi
	macro_11f23c $09 ; ku_gu
	macro_11f23c $07 ; ke_ge
	macro_11f23c $1c ; ko_go
	macro_11f23c $12 ; sa_za
	macro_11f23c $2b ; shi_ji
	macro_11f23c $10 ; su_zu
	macro_11f23c $08 ; se_ze
	macro_11f23c $0c ; so_zo
	macro_11f23c $2c ; ta_da
	macro_11f23c $09 ; chi_dhi
	macro_11f23c $12 ; tsu_du
	macro_11f23c $1b ; te_de
	macro_11f23c $1a ; to_do
	macro_11f23c $1c ; na
	macro_11f23c $05 ; ni
	macro_11f23c $02 ; nu
	macro_11f23c $05 ; ne
	macro_11f23c $07 ; no
	macro_11f23c $16 ; ha_ba_pa
	macro_11f23c $0e ; hi_bi_pi
	macro_11f23c $0c ; fu_bu_pu
	macro_11f23c $05 ; he_be_pe
	macro_11f23c $16 ; ho_bo_po
	macro_11f23c $19 ; ma
	macro_11f23c $0e ; mi
	macro_11f23c $08 ; mu
	macro_11f23c $07 ; me
	macro_11f23c $09 ; mo
	macro_11f23c $0d ; ya
	macro_11f23c $04 ; yu
	macro_11f23c $14 ; yo
	macro_11f23c $0b ; ra
	macro_11f23c $01 ; ri
	macro_11f23c $02 ; ru
	macro_11f23c $02 ; re
	macro_11f23c $02 ; ro
	macro_11f23c $15 ; wa
x = $d000
	macro_11f23c $09 ; end
.End
