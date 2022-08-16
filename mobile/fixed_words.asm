EZCHAT_WORD_COUNT equ 4
EZCHAT_WORD_LENGTH equ 8

; These functions seem to be related to the selection of preset phrases
; for use in mobile communications.  Annoyingly, they separate the
; Battle Tower function above from the data it references.

EZChat_RenderOneWord:
; hl = where to place it to
; d,e = params?
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
	ld bc, wEZChatWords ; (?)
	call EZChat_RenderWords
	ret

Function11c082: ; unreferenced
	push de
	ld a, c
	call Function11c254
	pop de
	ld bc, wEZChatWords
	call PrintEZChatBattleMessage
	ret

Function11c08f:
EZChat_RenderWords:
	ld l, e
	ld h, d
	push hl
if 1
	ld a, 2 ; Determines the number of easy chat words displayed before going onto the next line
else
	ld a, 3
endc
.loop
	push af
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld d, a
	inc bc
	push bc
	call EZChat_RenderOneWord
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
	call EZChat_RenderOneWord
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
	; Preserve [wJumptableIndex], $cf64
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
	; [wJumptableIndex] keeps track of which line we're on (0, 1, or 2)
	; $cf64 keeps track of how much room we have left in the current line
	xor a
	ld [wJumptableIndex], a
	ld a, 18
	ld [wcf64], a
	ld a, EZCHAT_WORD_COUNT
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
	ld de, wEZChatWordBuffer
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

GetLengthOfWordAtC608: ; Finds the length of the word being stored for EZChat?
	ld c, $0
	ld hl, wEZChatWordBuffer
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
	ld hl, wEZChatWordBuffer
	ld bc, EZCHAT_WORD_LENGTH + 1
	call ByteFill
	ld a, d
	and a
	jr z, .get_name
; load in name
	ld hl, MobileEZChatCategoryPointers
	dec d
	sla d
	ld c, d
	ld b, $0
	add hl, bc
; got category pointer
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
; bc -> hl
	push bc
	pop hl
	ld c, e
	ld b, $0
; got which word
; bc * (5 + 1 + 1 + 1) = bc * 8
;	sla c
;	rl b
;	sla c
;	rl b
;	sla c
;	rl b
;	add hl, bc
rept EZCHAT_WORD_LENGTH + 3 ; fuck it, do (bc * 11) this way
	add hl, bc
endr
; got word address
	ld bc, EZCHAT_WORD_LENGTH
.copy_string
	ld de, wEZChatWordBuffer
	call CopyBytes
	ld de, wEZChatWordBuffer
	pop af
	ldh [rSVBK], a
	ret

.get_name
	ld a, e
	ld [wNamedObjectIndexBuffer], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld bc, EZCHAT_WORD_LENGTH
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

.InitKanaMode: ; Possibly opens the appropriate sorted list of words when sorting by letter?
	xor a
	ld [wJumptableIndex], a
	ld [wcf64], a
	ld [wcf65], a
	ld [wcf66], a
	ld [wcd23], a
	ld [wEZChatSelection], a
	ld [wEZChatCategorySelection], a
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
	ld hl, SelectStartGFX ; GFX_11d67e
	ld de, vTiles2
	ld bc, $60
	call CopyBytes
	ld hl, EZChatSlowpokeLZ ; LZ_11d6de
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
	ld de, wEZChatWords
	ld bc, EZCHAT_WORD_COUNT * 2
	call CopyBytes
	call CloseSRAM
	ret

EZChat_ClearBottom12Rows: ; Clears area below selected messages.
	ld a, "　"
	hlcoord 0, 6 ; Start of the area to clear
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

.Jumptable: ; and jumptable constants
	const_def
	
	const EZCHAT_SPAWN_OBJECTS
	dw .SpawnObjects ; 00
	
	const EZCHAT_INIT_RAM
	dw .InitRAM ; 01
	
	const EZCHAT_02
	dw Function11c35f ; 02
	
	const EZCHAT_03
	dw Function11c373 ; 03
	
	const EZCHAT_DRAW_CHAT_WORDS
	dw EZChatDraw_ChatWords ; 04
	
	const EZCHAT_MENU_CHAT_WORDS
	dw EZChatMenu_ChatWords ; 05
	
	const EZCHAT_DRAW_CATEGORY_MENU
	dw EZChatDraw_CategoryMenu ; 06
	
	const EZCHAT_MENU_CATEOGRY_MENU
	dw EZChatMenu_CategoryMenu ; 07
	
	const EZCHAT_DRAW_WORD_SUBMENU
	dw EZChatDraw_WordSubmenu ; 08
	
	const EZCHAT_MENU_WORD_SUBMENU
	dw EZChatMenu_WordSubmenu ; 09
	
	const EZCHAT_DRAW_ERASE_SUBMENU
	dw EZChatDraw_EraseSubmenu ; 0a
	
	const EZCHAT_MENU_ERASE_SUBMENU
	dw EZChatMenu_EraseSubmenu ; 0b
	
	const EZCHAT_DRAW_EXIT_SUBMENU
	dw EZChatDraw_ExitSubmenu ; 0c
	
	const EZCHAT_MENU_EXIT_SUBMENU
	dw EZChatMenu_ExitSubmenu ; 0d
	
	const EZCHAT_DRAW_MESSAGE_TYPE_MENU
	dw EZChatDraw_MessageTypeMenu ; 0e
	
	const EZCHAT_MENU_MESSAGE_TYPE_MENU
	dw EZChatMenu_MessageTypeMenu ; 0f
	
	const EZCHAT_10
	dw Function11cbf5 ; 10 (Something related to sound)
	
	const EZCHAT_MENU_WARN_EMPTY_MESSAGE
	dw EZChatMenu_WarnEmptyMessage ; 11 (Something related to SortBy menus)
	
	const EZCHAT_12
	dw Function11cd04 ; 12 (Something related to input)
	
	const EZCHAT_DRAW_SORT_BY_MENU
	dw EZChatDraw_SortByMenu ; 13
	
	const EZCHAT_MENU_SORT_BY_MENU
	dw EZChatMenu_SortByMenu ; 14
	
	const EZCHAT_DRAW_SORT_BY_CHARACTER
	dw EZChatDraw_SortByCharacter ; 15
	
	const EZCHAT_MENU_SORT_BY_CHARACTER
	dw EZChatMenu_SortByCharacter ; 16
	
.SpawnObjects:
	depixel 3, 1, 2, 5
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	depixel 8, 1, 2, 5

	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C
	add hl, bc
	ld a, $1 ; Message Menu Index (?)
	ld [hl], a

	depixel 9, 2, 2, 0
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C ; VAR1
	add hl, bc
	ld a, $3 ; Word Menu Index (?)
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
	ld hl, SPRITEANIMSTRUCT_0C ; VAR1
	add hl, bc
	ld a, $5 ; Sort By Menu Index (?)
	ld [hl], a

	depixel 10, 2
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call _InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_0C ; VAR1
	add hl, bc
	ld a, $2 ; Sort By Letter Menu Index (?)
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
	call EZChat_Textbox
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
	call EZChat_Textbox
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
	call EZChat_Textbox
	pop af
	ret nz
	call EZChatMenu_MessageSetup
	jp Function11cfb5

EZChatMenu_MessageSetup:
	ld hl, EZChatCoord_ChatWords
	ld bc, wEZChatWords
	ld a, EZCHAT_WORD_COUNT
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
	jr z, .emptystring
	ld a, e
	and d
	cp $ff
	jr z, .emptystring
	call EZChat_RenderOneWord
	jr .asm_11c3b5
.emptystring
	ld de, EZChatString_EmptyWord
	call PlaceString
.asm_11c3b5
	pop bc
	pop hl
	pop af
	dec a
	jr nz, .asm_11c392
	ret

EZChatString_EmptyWord: ; EZChat Unassigned Words
	db "--------@"

EZChatDraw_ChatWords: ; Switches between menus?, not sure which.
	call EZChat_ClearBottom12Rows
	ld de, EZChatBKG_ChatExplanation
	call EZChat_Textbox2
	hlcoord 1, 7 ; Location of EZChatString_ChatExplanation
	ld de, EZChatString_ChatExplanation
	call PlaceString
	hlcoord 1, 16 ; Location of EZChatString_ChatExplanationBottom
	ld de, EZChatString_ChatExplanationBottom
	call PlaceString
	call EZChatDrawBKG_ChatWords
	ld hl, wcd23
	set 0, [hl]
	ld hl, wcd24
	res 0, [hl]
	call Function11cfb5

; ezchat main options
	const_def
	const EZCHAT_MAIN_WORD1
	const EZCHAT_MAIN_WORD2
	const EZCHAT_MAIN_WORD3
	const EZCHAT_MAIN_WORD4
	;const EZCHAT_MAIN_WORD5
	;const EZCHAT_MAIN_WORD6
	
	const EZCHAT_MAIN_RESET
	const EZCHAT_MAIN_QUIT
	const EZCHAT_MAIN_OK

EZChatMenu_ChatWords: ; EZChat Word Menu

; ----- (00) ----- (01) ----- (02)
; ----- (03) ----- (04) ----- (05)
; RESET (06)  QUIT (07)   OK  (08)

; to

; -------- (00) -------- (01)
; -------- (02) -------- (03)
; RESET (04)  QUIT (05)   OK  (06)

	ld hl, wEZChatSelection
	ld de, hJoypadPressed
	ld a, [de]
	and START
	jr nz, .select_ok
	ld a, [de]
	and B_BUTTON
	jr nz, .click_sound_and_quit
	ld a, [de]
	and A_BUTTON
	jr nz, .select_option
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

.click_sound_and_quit
	call PlayClickSFX
.to_quit_prompt
	ld hl, wcd24
	set 0, [hl]
	ld a, EZCHAT_DRAW_EXIT_SUBMENU
	jr .move_jumptable_index

.select_ok
	ld a, EZCHAT_MAIN_OK
	ld [wEZChatSelection], a
	ret

.select_option
	ld a, [wEZChatSelection]
	cp EZCHAT_MAIN_RESET
	jr c, .to_word_select
	sub EZCHAT_MAIN_RESET
	jr z, .to_reset_prompt
	dec a
	jr z, .to_quit_prompt
; ok prompt
	ld hl, wEZChatWords
	ld c, EZCHAT_WORD_COUNT * 2
	xor a
.go_through_all_words
	or [hl]
	inc hl
	dec c
	jr nz, .go_through_all_words
	and a
	jr z, .if_all_empty

; filled out
	ld de, EZChatBKG_ChatWords
	call EZChat_Textbox
	decoord 1, 2
	ld bc, wEZChatWords
	call EZChat_RenderWords
	ld hl, wcd24
	set 0, [hl]
	ld a, EZCHAT_DRAW_MESSAGE_TYPE_MENU
	jr .move_jumptable_index

.if_all_empty
	ld hl, wcd24
	set 0, [hl]
	ld a, EZCHAT_MENU_WARN_EMPTY_MESSAGE
	jr .move_jumptable_index

.to_reset_prompt
	ld hl, wcd24
	set 0, [hl]
	ld a, EZCHAT_DRAW_ERASE_SUBMENU
	jr .move_jumptable_index

.to_word_select
	call EZChat_MoveToCategoryOrSortMenu
.move_jumptable_index
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.up
	ld a, [hl]
if 1
	cp 2
	ret c
	sub 2
else
	cp 3
	ret c
	sub 3
endc
	jr .finish_dpad
.down
	ld a, [hl]
if 1
	cp 4
	ret nc
	add 2
else
	cp 6
	ret nc
	add 3
endc
	jr .finish_dpad
.left
	ld a, [hl]
if 1
	and a ; cp a, 0
	ret z
	cp 2
	ret z
	cp 4
	ret z
else
	and a
	ret z
	cp $3
	ret z
	cp $6
	ret z
endc
	dec a
	jr .finish_dpad
.right
	ld a, [hl]
if 1
; rightmost side of everything
	cp 1
	ret z
	cp 3
	ret z
	cp 6
	ret z
else
	cp 2
	ret z
	cp 5
	ret z
	cp 8
	ret z
endc
	inc a
.finish_dpad
	ld [hl], a
	ret

EZChat_MoveToCategoryOrSortMenu:
	ld hl, wcd23
	res 0, [hl]
	ld a, [wcd2b]
	and a
	jr nz, .to_sort_menu
	xor a
	ld [wEZChatCategorySelection], a
	ld a, EZCHAT_DRAW_CATEGORY_MENU ; from where this is called, it sets jumptable stuff
	ret

.to_sort_menu
	xor a
	ld [wcd22], a
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
	ret

EZChatDrawBKG_ChatWords:
	ld a, $1
	hlcoord 0, 6, wAttrMap 	; Draws the pink background for 'Combine words'
	ld bc, $a0 				; Area to fill
	call ByteFill
	ld a, $7
	hlcoord 0, 14, wAttrMap ; Clears white area at bottom of menu
	ld bc, $28 				; Area to clear
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatString_ChatExplanation: ; Explanation string 
	db   "Combine 4 words.";"６つのことば¯くみあわせます"
	next "Select the space";"かえたいところ¯えらぶと　でてくる"
	next "to change and";"ことばのグループから　いれかえたい"
	next "choose a new word.";"たんご¯えらんでください"
	db   "@"

EZChatString_ChatExplanationBottom: ; Explanation commands string
	db "RESET　QUIT  　OK@";"ぜんぶけす　やめる　　　けってい@"

EZChatDraw_CategoryMenu: ; Open category menu
; might need no change here
	call EZChat_ClearBottom12Rows
	call EZChat_PlaceCategoryNames
	call Function11c618
	ld hl, wcd24
	res 1, [hl]
	call Function11cfb5

EZChatMenu_CategoryMenu: ; Category Menu Controls
	ld hl, wEZChatCategorySelection
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
	ld a, [wEZChatCategorySelection]
	cp 15
	jr c, .got_category
	sub 15
	jr z, .done
	dec a
	jr z, .mode
	jr .b

.start
	ld hl, wcd24
	set 0, [hl]
	ld a, $8
	ld [wEZChatSelection], a

.b
	ld a, EZCHAT_DRAW_CHAT_WORDS
	jr .go_to_function

.select
	ld a, [wcd2b]
	xor 1
	ld [wcd2b], a
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
	jr .go_to_function

.mode
	ld a, EZCHAT_DRAW_SORT_BY_MENU
	jr .go_to_function

.got_category
	ld a, EZCHAT_DRAW_WORD_SUBMENU

.go_to_function
	ld hl, wcd24
	set 1, [hl]
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.done
	ld a, [wEZChatSelection]
	call EZChatDraw_EraseWordsLoop
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
	ld bc, EZChatCoord_Categories
	ld a, 15 ; Number of EZ Chat categories displayed
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

EZChatCoord_Categories: ; Category Coordinates
	dwcoord  1,  7 ; PKMN
	dwcoord  7,  7 ; TYPES
	dwcoord 13,  7 ; GREET
	dwcoord  1,  9 ; HUMAN
	dwcoord  7,  9 ; FIGHT
	dwcoord 13,  9 ; VOICE
	dwcoord  1, 11 ; TALK
	dwcoord  7, 11 ; EMOTE
	dwcoord 13, 11 ; DESC
	dwcoord  1, 13 ; LIFE
	dwcoord  7, 13 ; HOBBY
	dwcoord 13, 13 ; ACT
	dwcoord  1, 15 ; ITEM
	dwcoord  7, 15 ; END
	dwcoord 13, 15 ; MISC

EZChatDraw_WordSubmenu: ; Opens/Draws Word Submenu
	call EZChat_ClearBottom12Rows
	call Function11c770
	ld de, EZChatBKG_WordSubmenu
	call EZChat_Textbox2
	call EZChat_WhiteOutLowerMenu
	call Function11c7bc
	call EZChatMenu_WordSubmenuBottom
	ld hl, wcd24
	res 3, [hl]
	call Function11cfb5

EZChatMenu_WordSubmenu: ; Word Submenu Controls
	ld hl, wEZChatWordSelection
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
	sub $c ; EZCHAT_WORD_COUNT * 2 ?
	jr nc, .asm_11c699
	xor a
.asm_11c699
	ld [wcd26], a
	jr .asm_11c6c4

.start
	ld hl, wcd28
	ld a, [wcd26]
if 1
	add $8 ; $c Skips down in the menu? MENU_WIDTH
else
	add 12 ; EZCHAT_WORD_COUNT * 2
endc
	cp [hl]
	ret nc
	ld [wcd26], a
	ld a, [hl]
	ld b, a
	ld hl, wEZChatWordSelection
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
	ld [wEZChatWordSelection], a
.asm_11c6c4
	call Function11c992
	call Function11c7bc
	call EZChatMenu_WordSubmenuBottom
	ret

.select
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
	call Function11c8f6
	ld a, $4
	ld [wcd35], a
	jr .jump_to_index
.b
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c6fa
	ld a, $6
	jr .jump_to_index
.asm_11c6fa
	ld a, $15
.jump_to_index
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 3, [hl]
	call PlayClickSFX
	ret

.up
	ld a, [hl]
if 1
	cp $2 ; MENU_WIDTH
	jr c, .asm_11c711
	sub $2 ; 3 MENU_WIDTH
else
	cp 3
	jr c, .asm_11c711
	sub 3
endc
	jr .finish_dpad

.asm_11c711
	ld a, [wcd26]
if 1
	sub $2 ; 3 MENU_WIDTH
else
	sub 3
endc
	ret c
	ld [wcd26], a
	jr .asm_11c6c4

.asm_11c71c
	ld hl, wcd28
	ld a, [wcd26]
if 1
	add $8 ; $c Skips down in the menu on SELECT? 
else
	add 12 ; EZCHAT_WORD_COUNT * 2
endc
	ret c
	cp [hl]
	ret nc
	ld a, [wcd26]
if 1
	add $2 ; 3 MENU_WIDTH
else
	add 3
endc
	ld [wcd26], a
	jr .asm_11c6c4

.down
	ld a, [wcd28]
	ld b, a
	ld a, [wcd26]
	add [hl]
if 1
	add $2 ; 3 MENU_WIDTH
	cp b
	ret nc
	ld a, [hl]
	cp $8 ; 9 MENU_WIDTH
	jr nc, .asm_11c71c
	add $2 ; 3 MENU_WIDTH
else
	add 3
	cp b
	ret nc
	ld a, [hl]
	cp 9
	jr nc, .asm_11c71c
	add 3
endc
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
	dec a
	jr .finish_dpad

.right
	ld a, [wcd28]
	ld b, a
	ld a, [wcd26]
	add [hl]
	inc a
	cp b
	ret nc
	ld a, [hl]
if 1
	cp $1 ; 2 MENU_WIDTH
	ret z
	cp $4 ; 5 MENU_WIDTH
	ret z
	cp $7 ; 8 MENU_WIDTH
	ret z
	cp $a ; b MENU_WIDTH
else
	cp 2
	ret z
	cp 5
	ret z
	cp 8
	ret z
	cp 11
endc
	ret z
	inc a

.finish_dpad
	ld [hl], a
	ret

Function11c770:
	xor a
	ld [wEZChatWordSelection], a
	ld [wcd26], a
	ld [wcd27], a
	ld a, [wcd2b]
	and a
	jr nz, .cd2b_is_nonzero
	ld a, [wEZChatCategorySelection]
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
if 1
	ld c, 8 ; 12 Number of words to draw in word submenu? MENU_WIDTH
else
	ld c, 12 ; EZCHAT_WORD_COUNT * 2
endc
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

Function11c7bc: ; Related to drawing words in the lower menu after picking a category
	ld bc, EZChatCoord_WordSubmenu
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c814
	ld a, [wEZChatCategorySelection]
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
	call EZChat_RenderOneWord
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
	call EZChat_RenderOneWord
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
	call EZChat_RenderOneWord
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

EZChatCoord_WordSubmenu: ; Word coordinates (within category submenu)
if 1
	dwcoord  2,  8
	dwcoord  11,  8 ; 8, 8 MENU_WIDTH
	dwcoord  2, 10
	dwcoord  11, 10 ; 8, 10 MENU_WIDTH
	dwcoord  2, 12
	dwcoord  11, 12 ; 8, 12 MENU_WIDTH
	dwcoord  2, 14
	dwcoord  11, 14 ; 8, 14 MENU_WIDTH
else
	dwcoord  2,  8
	dwcoord  8,  8 ; MENU_WIDTH
	dwcoord 14,  8 ; MENU_WIDTH
	dwcoord  2, 10
	dwcoord  8, 10 ; MENU_WIDTH
	dwcoord 14, 10 ; MENU_WIDTH
	dwcoord  2, 12
	dwcoord  8, 12 ; MENU_WIDTH
	dwcoord 14, 12 ; MENU_WIDTH
	dwcoord  2, 14
	dwcoord  8, 14 ; MENU_WIDTH
	dwcoord 14, 14 ; MENU_WIDTH
endc
	dw -1

EZChatMenu_WordSubmenuBottom: ; Seems to handle the bottom of the word menu.
	ld a, [wcd26]
	and a
	jr z, .asm_11c88a
	hlcoord 1, 17 	; Draw PREV string (2, 17)
	ld de, MobileString_Prev
	call PlaceString
	hlcoord 6, 17 	; Draw SELECT tiles
	ld c, $3 		; SELECT tile length
	xor a
.asm_11c883
	ld [hli], a
	inc a
	dec c
	jr nz, .asm_11c883
	jr .asm_11c895
.asm_11c88a
	hlcoord 1, 17 	; Clear PREV/SELECT (2, 17)
	ld c, $8 		; Clear PREV/SELECT length
	ld a, $7f
.asm_11c891
	ld [hli], a
	dec c
	jr nz, .asm_11c891
.asm_11c895
	ld hl, wcd28
	ld a, [wcd26]
	add $c ; EZCHAT_WORD_COUNT * 2 ?
	jr c, .asm_11c8b7
	cp [hl]
	jr nc, .asm_11c8b7
	hlcoord 15, 17 	; NEXT string (16, 17)
	ld de, MobileString_Next
	call PlaceString
	hlcoord 11, 17 	; START tiles
	ld a, $3 		; START tile length
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
	hlcoord 11, 17 	; Clear START/NEXT
	ld c, $9 		; Clear START/NEXT length
.asm_11c8c2
	ld [hli], a
	dec c
	jr nz, .asm_11c8c2
	ret

BCD2String: ; unreferenced
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

MobileString_Page: ; unreferenced
	db "PAGE@";"ぺージ@"

MobileString_Prev:
	db "PREV@";"まえ@"

MobileString_Next:
	db "NEXT@";"つぎ@"

Function11c8f6:
	ld a, [wEZChatSelection]
	call Function11c95d
	push hl
	ld a, [wcd2b]
	and a
	jr nz, .asm_11c938
	ld a, [wEZChatCategorySelection]
	ld d, a
	and a
	jr z, .asm_11c927
	ld hl, wcd26
	ld a, [wEZChatWordSelection]
	add [hl]
.asm_11c911
	ld e, a
.asm_11c912
	pop hl
	push de
	call EZChat_RenderOneWord
	pop de
	ld a, [wEZChatSelection]
	ld c, a
	ld b, $0
	ld hl, wEZChatWords
	add hl, bc
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
	ret

.asm_11c927
	ld hl, wcd26
	ld a, [wEZChatWordSelection]
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
	ld a, [wEZChatWordSelection]
	ld e, a
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	jr .asm_11c912

Function11c95d: ; Possibly draws words at the top for EZ chat
	sla a
	ld c, a
	ld b, 0
	ld hl, EZChatCoord_ChatWords
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	push bc
	push bc
	pop hl
	ld a, $5 ; Was changed to $7?
	ld c, a
	ld a, $7f
.asm_11c972
	ld [hli], a
	dec c
	jr nz, .asm_11c972
	dec hl
	ld bc, -20
	add hl, bc
	ld a, $5 ; Was changed to $7?
	ld c, a
	ld a, $7f
.asm_11c980
	ld [hld], a
	dec c
	jr nz, .asm_11c980
	pop hl
	ret

EZChatCoord_ChatWords: ; EZChat Message Coordinates
if 1
	dwcoord  1,  2
	dwcoord 10,  2 ;  7, 2
	;dwcoord  7,  7 ; 13, 2 (Pushed under 'Combine 4 words' menu) WORD_COUNT
	dwcoord  1,  4
	dwcoord 10,  4 ;  7, 4
	;dwcoord 12, 12 ; 13, 4 (Pushed under 'Combine 4 words' menu) WORD_COUNT
else
	dwcoord  1,  2
	dwcoord  7,  2
	dwcoord 13,  2
	dwcoord  1,  4
	dwcoord  7,  4
	dwcoord 13,  4
endc

Function11c992: ; Likely related to the word submenu, references the first word position
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

EZChat_WhiteOutLowerMenu:
	ld a, $7
	hlcoord 0, 6, wAttrMap
	ld bc, $c8
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatDraw_EraseSubmenu:
	ld de, EZChatString_EraseMenu
	call EZChatDraw_ConfirmationSubmenu

EZChatMenu_EraseSubmenu: ; Erase submenu controls
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1 ; A
	jr nz, .a
	ld a, [de]
	and $2 ; B
	jr nz, .b
	ld a, [de]
	and $40 ; UP
	jr nz, .up
	ld a, [de]
	and $80 ; DOWN
	jr nz, .down
	ret

.a
	ld a, [hl]
	and a
	jr nz, .b
	call EZChatMenu_EraseWordsAccept
	xor a
	ld [wEZChatSelection], a
.b
	ld hl, wcd24
	set 4, [hl]
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.up
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.down
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ret

Function11ca01: ; Erase Yes/No Menu (?)
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

EZChatString_EraseMenu: ; Erase words string, accessed from erase command on entry menu for EZ chat
	db   "Want to erase";"とうろくちゅう<NO>あいさつ¯ぜんぶ"
	next "all words?@";"けしても　よろしいですか？@"

EZChatString_EraseConfirmation: ; Erase words confirmation string
	db   "YES";"はい"
	next "NO@";"いいえ@"

EZChatMenu_EraseWordsAccept:
	xor a
.loop
	push af
	call EZChatDraw_EraseWordsLoop
	pop af
	inc a
if 1
	cp $4 ; 6 WORD_COUNT
else
	cp 6
endc
	jr nz, .loop
	ret

EZChatDraw_EraseWordsLoop:
	ld hl, wEZChatWords
	ld c, a
	ld b, $0
	add hl, bc
	add hl, bc
	ld [hl], b
	inc hl
	ld [hl], b
	call Function11c95d
	ld de, EZChatString_EmptyWord
	call PlaceString
	ret

EZChatDraw_ConfirmationSubmenu:
	push de
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	ld de, EZChatBKG_SortByConfirmation
	call EZChat_Textbox
	hlcoord 1, 14
	pop de
	call PlaceString
	hlcoord 16, 8
	ld de, EZChatString_EraseConfirmation
	call PlaceString
	call Function11ca01
	ld a, $1
	ld [wcd2a], a
	ld hl, wcd24
	res 4, [hl]
	call Function11cfb5
	ret

EZChatDraw_ExitSubmenu:
	ld de, EZChatString_ExitPrompt
	call EZChatDraw_ConfirmationSubmenu

EZChatMenu_ExitSubmenu: ; Exit Message menu
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1 ; A
	jr nz, .a
	ld a, [de]
	and $2 ; B
	jr nz, .b
	ld a, [de]
	and $40 ; UP
	jr nz, .up
	ld a, [de]
	and $80 ; DOWN
	jr nz, .down
	ret

.a
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
	ld de, EZChatString_ExitConfirmation
	call PlaceString
	ld a, $1
	ld [wcd2a], a
	ret

.asm_11caf3
	ld hl, wJumptableIndex
	set 7, [hl] ; exit
	ret

.b
	call PlayClickSFX
.asm_11cafc
	ld hl, wcd24
	set 4, [hl]
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wJumptableIndex], a
	ld a, [wcd35]
	cp $ff
	ret nz
	ld a, $1
	ld [wcd35], a
	ret

.up
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.down
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ret

EZChatString_ExitPrompt: ; Exit menu string 
	db   "Want to stop";"あいさつ<NO>とうろく¯ちゅうし"
	next "setting a MESSAGE?@";"しますか？@"

EZChatString_ExitConfirmation: ; Exit menu confirmation string
	db   "Quit without sav-";"とうろくちゅう<NO>あいさつ<WA>ほぞん"
	next "ing the MESSAGE?  @";"されません<GA>よろしい　ですか？@"

EZChatDraw_MessageTypeMenu: ; Message Type Menu Drawing (Intro/Battle Start/Win/Lose menu)
	ld hl, EZChatString_MessageDescription
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
	call EZChatDraw_ConfirmationSubmenu

EZChatMenu_MessageTypeMenu: ; Message Type Menu Controls (Intro/Battle Start/Win/Lose menu)
	ld hl, wcd2a
	ld de, hJoypadPressed
	ld a, [de]
	and $1 ; A
	jr nz, .a
	ld a, [de]
	and $2 ; B
	jr nz, .b
	ld a, [de]
	and $40 ; UP
	jr nz, .up
	ld a, [de]
	and $80 ; DOWN
	jr nz, .down
	ret

.a
	ld a, [hl]
	and a
	jr nz, .clicksound
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
	ld de, wEZChatWords
	ld c, EZCHAT_WORD_COUNT * 2
.asm_11cba2
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .asm_11cba2
	call CloseSRAM
	call PlayClickSFX
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	ld hl, EZChatString_MessageSet
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

.clicksound
	call PlayClickSFX
.b
	ld de, EZChatBKG_ChatWords
	call EZChat_Textbox
	call EZChatMenu_MessageSetup
	ld hl, wcd24
	set 4, [hl]
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wJumptableIndex], a
	ret

.up
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

.down
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

EZChatString_MessageDescription: ; Message usage strings
	dw EZChatString_MessageIntroDescription
	dw EZChatString_MessageBattleStartDescription
	dw EZChatString_MessageBattleWinDescription
	dw EZChatString_MessageBattleLoseDescription

EZChatString_MessageIntroDescription:
	db   "Shown to introduce";"じこしょうかい　は"
	next "yourself. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleStartDescription:
	db   "Shown when begin-";"たいせん　<GA>はじまるとき　は"
	next "ning a battle. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleWinDescription:
	db   "Shown when win-";"たいせん　<NI>かったとき　は"
	next "ning a battle. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleLoseDescription:
	db   "Shown when los-";"たいせん　<NI>まけたとき　は"
	next "ing a battle. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageSet: ; message accept strings, one for each type of message.
	dw EZChatString_MessageIntroSet
	dw EZChatString_MessageBattleStartSet
	dw EZChatString_MessageBattleWinSet
	dw EZChatString_MessageBattleLoseSet

EZChatString_MessageIntroSet:
	db   "MESSAGE set!@";"じこしょうかい　の"
	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleStartSet:
	db   "MESSAGE set!@";"たいせん　<GA>はじまるとき　の"
	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleWinSet:
	db   "MESSAGE set!@";"たいせん　<NI>かったとき　の"
	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleLoseSet:
	db   "MESSAGE set!@";"たいせん　<NI>まけたとき　の"
	;next "あいさつ¯とうろくした！@"

EZChatMenu_WarnEmptyMessage:
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	hlcoord 1, 14
	ld de, EZChatString_EnterSomeWords
	call PlaceString
	call Function11ca19
	call Function11cfb5

Function11cd04:
	ld de, hJoypadPressed
	ld a, [de]
	and a
	ret z
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wJumptableIndex], a
	ret

EZChatString_EnterSomeWords:
	db "Please enter some";"なにか　ことば¯いれてください@"
	next "words.@"

EZChatDraw_SortByMenu: ; Draws/Opens Sort By Menu
	call EZChat_ClearBottom12Rows
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	hlcoord 1, 14
	ld a, [wcd2b]
	ld [wcd2c], a
	and a
	jr nz, .asm_11cd3a
	ld de, EZChatString_SortByCategory
	jr .asm_11cd3d
.asm_11cd3a
	ld de, EZChatString_SortByAlphabetical
.asm_11cd3d
	call PlaceString
	hlcoord 4, 8
	ld de, EZChatString_SortByMenu
	call PlaceString
	call Function11cdaa
	ld hl, wcd24
	res 5, [hl]
	call Function11cfb5

EZChatMenu_SortByMenu: ; Sort Menu Controls
	ld hl, wcd2c
	ld de, hJoypadPressed
	ld a, [de]
	and A_BUTTON
	jr nz, .a
	ld a, [de]
	and B_BUTTON
	jr nz, .b
	ld a, [de]
	and D_UP
	jr nz, .up
	ld a, [de]
	and D_DOWN
	jr nz, .down
	ret

.a
	ld a, [hl]
	ld [wcd2b], a
.b
	ld a, [wcd2b]
	and a
	jr nz, .asm_11cd7d
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .jump_to_index

.asm_11cd7d
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
.jump_to_index
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 5, [hl]
	call PlayClickSFX
	ret

.up
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ld de, EZChatString_SortByCategory
	jr .asm_11cd9b

.down
	ld a, [hl]
	and a
	ret nz
	inc [hl]
	ld de, EZChatString_SortByAlphabetical
.asm_11cd9b
	push de
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
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

EZChatString_SortByCategory:
; Words will be displayed by category
	db   "Display words";"ことば¯しゅるいべつに"
	next "by category@";"えらべます@"

EZChatString_SortByAlphabetical:
; Words will be displayed in alphabetical order
	db   "Display words in";"ことば¯アイウエオ　の"
	next "alphabetical order@";"じゅんばんで　ひょうじ　します@"

EZChatString_SortByMenu:
	db   "GROUP MODE";"しゅるいべつ　モード"  ; Category mode
	next "ABC MODE@";"アイウエオ　　モード@" ; ABC mode

EZChatDraw_SortByCharacter: ; Sort by Character Menu
	call EZChat_ClearBottom12Rows
	hlcoord 1, 7
	ld de, EZChatScript_SortByCharacterTable
	call PlaceString
	hlcoord 1, 17
	ld de, EZChatString_Stop_Mode_Cancel
	call PlaceString
	call Function11c618
	ld hl, wcd24
	res 2, [hl]
	call Function11cfb5

EZChatMenu_SortByCharacter: ; Sort By Character Menu Controls
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
	ld [wEZChatSelection], a
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
	ld a, EZCHAT_DRAW_SORT_BY_MENU
.load
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 2, [hl]
	call PlayClickSFX
	ret

.done
	ld a, [wEZChatSelection]
	call EZChatDraw_EraseWordsLoop
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

Unknown_11ceb9: ; Sort Menu Letter tile values or coordinates?
	; up left down right
	db $ff, $01 ; 255, 1
	db $05, $ff ;  5, 255
	db $ff, $02 ; 255, 2
	db $06, $00 ;  6, 0
	db $ff, $03 ; 255, 3
	db $07, $01 ;  7, 1
	db $ff, $04 ; 255, 4
	db $08, $02 ;  8, 2
	db $ff, $14 ; 255, 20
	db $09, $03 ;  9, 3
	db $00, $06 ;  0, 6
	db $0a, $ff ; 10, 255
	db $01, $07 ;  1, 7
	db $0b, $05 ; 11, 5
	db $02, $08 ;  2, 8
	db $0c, $06 ; 12, 6
	db $03, $09 ;  3, 9
	db $0d, $07 ; 13, 7
	db $04, $19 ;  4, 25
	db $0e, $08 ; 14, 8
	db $05, $0b ;  5, 11
	db $0f, $ff ; 15, 255
	db $06, $0c ;  6, 12
	db $10, $0a ; 16, 10
	db $07, $0d ;  7, 13
	db $11, $0b ; 17, 11
	db $08, $0e ;  8, 14
	db $12, $0c ; 18, 12
	db $09, $1e ;  9, 15
	db $13, $0d ; 19, 13
	db $0a, $10 ; 10, 16
	db $2d, $ff ; 45, 255
	db $0b, $11 ; 11, 17
	db $2d, $0f ; 45, 15
	db $0c, $12 ; 12, 18
	db $2d, $10 ; 45, 16
	db $0d, $13 ; 13, 19
	db $2d, $11 ; 45, 17
	db $0e, $26 ; 14, 38
	db $2d, $12 ; 45, 18
	db $ff, $15 ; 255, 21
	db $19, $04 ; 25, 4
	db $ff, $16 ; 255, 22
	db $1a, $14 ; 26, 20
	db $ff, $17 ; 255, 23
	db $1b, $15 ; 27, 21
	db $ff, $18 ; 255, 24
	db $1c, $16 ; 28, 22
	db $ff, $23 ; 255, 35
	db $1d, $17 ; 29, 23
	db $14, $1a ; 20, 26
	db $1e, $09 ; 30, 9
	db $15, $1b ; 21, 27
	db $1f, $19 ; 31, 25
	db $16, $1c ; 22, 28
	db $20, $1a ; 32, 26
	db $17, $1d ; 23, 29
	db $21, $1b ; 33, 27
	db $18, $2b ; 24, 43
	db $22, $1c ; 34, 28
	db $19, $1f ; 25, 31
	db $26, $0e ; 38, 14
	db $1a, $20 ; 26, 32
	db $27, $1e ; 39, 30
	db $1b, $21 ; 27, 33
	db $28, $1f ; 40, 31
	db $1c, $22 ; 28, 34
	db $29, $20 ; 41, 32
	db $1d, $2c ; 29, 44
	db $2a, $21 ; 42, 33
	db $ff, $24 ; 255, 36
	db $2b, $18 ; 43, 24
	db $ff, $25 ; 255, 37
	db $2b, $23 ; 43, 35
	db $ff, $ff ; 255, 255
	db $2b, $24 ; 43, 36
	db $1e, $27 ; 30, 39
	db $2e, $13 ; 46, 19
	db $1f, $28 ; 31, 40
	db $2e, $26 ; 46, 38
	db $20, $29 ; 32, 41
	db $2e, $27 ; 46, 39
	db $21, $2a ; 33, 42
	db $2e, $28 ; 46, 40
	db $22, $ff ; 34, 255
	db $2e, $29 ; 46, 41
	db $23, $ff ; 35, 255
	db $2c, $1d ; 44, 29
	db $2b, $ff ; 43, 255
	db $2f, $22 ; 47, 34
	db $0f, $2e ; 15, 46
	db $ff, $ff ; 255, 255
	db $26, $2f ; 38, 47
	db $ff, $2d ; 255, 45
	db $2c, $ff ; 44, 255
	db $ff, $2e ; 255, 46

EZChatScript_SortByCharacterTable: ; Hiragana table, used when sorting alphabetically
; Hiragana table
	db   "ABCDE　FGHIJ　-　-　-" ;"あいうえお　なにぬねの　や　ゆ　よ"
	next "KLMNO　PQRST　-" ; "かきくけこ　はひふへほ　わ"
	next "UVWXY　Z----　ETC" ; "さしすせそ　まみむめも　そのた"
	next "-----　-----" ;"たちつてと　らりるれろ"
	db   "@"

Function11cfb5:
	ld hl, wJumptableIndex
	inc [hl]
	ret

EZChatBKG_ChatWords: ; EZChat Word Background
	db  0,  0 ; start coords
	db 20,  6 ; end coords

EZChatBKG_ChatExplanation: ; EZChat Explanation Background
	db  0, 14 ; start coords
	db 20,  4 ; end coords

EZChatBKG_WordSubmenu:
	db  0,  6 ; start coords
	db 20, 10 ; end coords

EZChatBKG_SortBy: ; Sort Menu
	db  0, 12 ; start coords
	db 20,  6 ; end coords

EZChatBKG_SortByConfirmation:
	db 14,  7 ; start coords
	db  6,  5 ; end coords

EZChat_Textbox:
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

EZChat_Textbox2:
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

AnimateEZChatCursor: ; EZChat cursor drawing code, extends all the way down to roughly line 2958
	ld hl, SPRITEANIMSTRUCT_0C ; VAR1
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
	dw .zero   ; EZChat Message Menu
	dw .one    ; Category Menu
	dw .two    ; Sort By Letter Menu
	dw .three  ; Words Submenu
	dw .four   ; Yes/No Menu
	dw .five   ; Sort By Menu
	dw .six
	dw .seven
	dw .eight
	dw .nine
	dw .ten

.zero ; EZChat Message Menu
; reinit sprite
	ld a, [wEZChatSelection]
	cp EZCHAT_MAIN_RESET
	jr nc, .shorter_cursor
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_8
	call ReinitSpriteAnimFrame
	jr .cont0
.shorter_cursor
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1
	call ReinitSpriteAnimFrame
.cont0
	ld a, [wEZChatSelection]
	sla a
	ld hl, .Coords_Zero
	ld e, $1 ; Category Menu Index (?) (May be the priority of which the selection boxes appear (0 is highest))
	jr .load

.one ; Category Menu
	ld a, [wEZChatCategorySelection]
	sla a
	ld hl, .Coords_One
	ld e, $2 ; Sort by Letter Menu Index (?)
	jr .load

.two ; Sort By Letter Menu
	ld hl, .FramesetsIDs_Two
	ld a, [wcd22]
	ld e, a
	ld d, $0 ; Message Menu Index (?)
	add hl, de
	ld a, [hl]
	call ReinitSpriteAnimFrame

	ld a, [wcd22]
	sla a
	ld hl, .Coords_Two
	ld e, $4 ; Yes/No Menu Index (?)
	jr .load

.three ; Words Submenu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2 ; $27
	call ReinitSpriteAnimFrame
	ld a, [wEZChatWordSelection]
	sla a
	ld hl, .Coords_Three
	ld e, $8
.load
	push de
	ld e, a
	ld d, $0 ; Message Menu Index (?)
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

.four ; Yes/No Menu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2 ; $27
	call ReinitSpriteAnimFrame
	ld a, [wcd2a]
	sla a
	ld hl, .Coords_Four
	ld e, $10
	jr .load

.five ; Sort By Menu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2 ; $27
	call ReinitSpriteAnimFrame
	ld a, [wcd2c]
	sla a
	ld hl, .Coords_Five
	ld e, $20
	jr .load

.six
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_5 ; $2a
	call ReinitSpriteAnimFrame
	ld a, [wcd4a] ; X = [wcd4a] * 8 + 24
	sla a
	sla a
	sla a
	add $18
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hli], a
	ld a, $30 ; Y = 48
	ld [hl], a

	ld a, $1
	ld e, a
	call .UpdateObjectFlags
	ret

.seven
	ld a, [wEZChatCursorYCoord]
	cp $4 ; Yes/No Menu Index (?)
	jr z, .cursor0
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; $28
	jr .got_frameset
;test
.cursor0
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; $26
.got_frameset
	call ReinitSpriteAnimFrame
	ld a, [wEZChatCursorYCoord]
	cp $4 ; Yes/No Menu Index (?)
	jr z, .asm_11d1b1
	ld a, [wEZChatCursorXCoord]	; X = [wEZChatCursorXCoord] * 8 + 32
	sla a
	sla a
	sla a
	add $20
	ld hl, SPRITEANIMSTRUCT_XCOORD
	add hl, bc
	ld [hli], a
	ld a, [wEZChatCursorYCoord]	; Y = [wEZChatCursorYCoord] * 16 + 72
	sla a
	sla a
	sla a
	sla a
	add $48
	ld [hl], a
	ld a, $2 ; Sort by Letter Menu Index (?)
	ld e, a
	call .UpdateObjectFlags
	ret

.asm_11d1b1
	ld a, [wEZChatCursorXCoord] ; X = [wEZChatCursorXCoord] * 40 + 24
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
	ld a, $8a ; Y = 138
	ld [hl], a
	ld a, $2 ; Sort By Letter Menu Index (?)
	ld e, a
	call .UpdateObjectFlags
	ret

.nine
	ld d, -13 * 8
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_7 ; $2c
	jr .eight_nine_load

.eight
	ld d, 2 * 8
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_6 ; $2b
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
	ld a, $4 ; Yes/No Menu Index (?)
	ld e, a
	call .UpdateObjectFlags
	ret

.ten
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; $26
	call ReinitSpriteAnimFrame
	ld a, $8
	ld e, a
	call .UpdateObjectFlags
	ret

.Coords_Zero: ; EZChat Message Menu
if 1
	dbpixel  1,  3, 5, 2 ; Message 1 - 00
	dbpixel 10,  3, 5, 2 ; Message 2 - 01
	dbpixel  1,  5, 5, 2 ; Message 3 - 02
	dbpixel 10,  5, 5, 2 ; Message 4 - 03
	dbpixel  1, 17, 5, 2 ; RESET     - 04
	dbpixel  7, 17, 5, 2 ; QUIT      - 05
	dbpixel 13, 17, 5, 2 ; OK        - 06
else
	dbpixel  1,  3, 5, 2 ; Message 1
	dbpixel  7,  3, 5, 2 ; Message 2
	dbpixel 13,  3, 5, 2 ; Message 3
	dbpixel  1,  5, 5, 2 ; Message 4
	dbpixel  7,  5, 5, 2 ; Message 5
	dbpixel 13,  5, 5, 2 ; Message 6
	dbpixel  1, 17, 5, 2 ; RESET
	dbpixel  7, 17, 5, 2 ; QUIT
	dbpixel 13, 17, 5, 2 ; OK
endc

.Coords_One: ; Category Menu
	dbpixel  1,  8, 5, 2 ; PKMN
	dbpixel  7,  8, 5, 2 ; TYPES
	dbpixel 13,  8, 5, 2 ; GREET
	dbpixel  1, 10, 5, 2 ; HUMAN
	dbpixel  7, 10, 5, 2 ; FIGHT
	dbpixel 13, 10, 5, 2 ; VOICE
	dbpixel  1, 12, 5, 2 ; TALK
	dbpixel  7, 12, 5, 2 ; EMOTE
	dbpixel 13, 12, 5, 2 ; DESC
	dbpixel  1, 14, 5, 2 ; LIFE
	dbpixel  7, 14, 5, 2 ; HOBBY
	dbpixel 13, 14, 5, 2 ; ACT
	dbpixel  1, 16, 5, 2 ; ITEM
	dbpixel  7, 16, 5, 2 ; END
	dbpixel 13, 16, 5, 2 ; MISC
	dbpixel  1, 18, 5, 2 ; ERASE
	dbpixel  7, 18, 5, 2 ; MODE
	dbpixel 13, 18, 5, 2 ; CANCEL

.Coords_Two: ; Sort By Letter Menu
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

.Coords_Three: ; Words Submenu Arrow Positions
if 1
	dbpixel  2, 10 
	dbpixel  11, 10 ; 8, 10 MENU_WIDTH
	;dbpixel 14, 10
	dbpixel  2, 12
	dbpixel  11, 12 ; 8, 12 MENU_WIDTH
	;dbpixel 14, 12
	dbpixel  2, 14
	dbpixel  11, 14 ; 8, 14 MENU_WIDTH
	;dbpixel 14, 14
	dbpixel  2, 16
	dbpixel  11, 16 ; 8, 16 MENU_WIDTH
	;dbpixel 14, 16
else
	dbpixel  2, 10 
	dbpixel  8, 10 ; MENU_WIDTH
	dbpixel 14, 10
	dbpixel  2, 12
	dbpixel  8, 12 ; MENU_WIDTH
	dbpixel 14, 12
	dbpixel  2, 14
	dbpixel  8, 14 ; MENU_WIDTH
	dbpixel 14, 14
	dbpixel  2, 16
	dbpixel  8, 16 ; MENU_WIDTH
	dbpixel 14, 16
endc

.Coords_Four: ; Yes/No Box
	dbpixel 16, 10 ; YES
	dbpixel 16, 12 ; NO

.Coords_Five: ; Sort By Menu
	dbpixel  4, 10 ; Group Mode
	dbpixel  4, 12 ; ABC Mode

.FramesetsIDs_Two:
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 00 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 01 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 02 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 03 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 04 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 05 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 06 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 07 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 08 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 09 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0a (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0b (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0c (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0d (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0e (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 0f (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 10 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 11 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 12 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 13 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 14 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 15 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 16 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 17 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 18 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 19 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1a (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1b (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1c (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1d (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1e (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 1f (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 20 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 21 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 22 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 23 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 24 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 25 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 26 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 27 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 28 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 29 (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 2a (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_3 ; 2b (Letter selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_4 ; 2c (Misc selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_9 ; 2d (Bottom Menu Selection box?)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_9 ; 2e (Bottom Menu Selection box?)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_9 ; 2f (Bottom Menu Selection box?)

.UpdateObjectFlags:
	ld hl, wcd24
	and [hl]
	jr nz, .update_y_offset
	ld a, e
	ld hl, wcd23
	and [hl]
	jr z, .reset_y_offset
	ld hl, SPRITEANIMSTRUCT_0E ; VAR3
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

EZChat_GetSeenPokemonByKana: ; From here all the way down to roughly 3236 is the code for sorting seen Pokemon to form the Pokemon name category
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
	ld hl, EZCHAT_WORD_LENGTH
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
	ld de, EZCHAT_WORD_LENGTH + 3
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

SelectStartGFX:
INCBIN "gfx/pokedex/select_start.2bpp"

EZChatSlowpokeLZ:
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

if 0
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
else
.Types:
	db	"DARK@@@@",	$26,	$0,	$0		; あく@@@,
	db	"ROCK@@@@",	$aa,	$0,	$0		; いわ@@@,
	db	"PSYCHIC@",	$da,	$0,	$0		; エスパー@,
	db	"FIGHTING",	$4e,	$1,	$0		; かくとう@,
	db	"GRASS@@@",	$ba,	$1,	$0		; くさ@@@,
	db	"GHOST@@@",	$e4,	$1,	$0		; ゴースト@,
	db	"ICE@@@@@",	$e6,	$1,	$0		; こおり@@,
	db	"GROUND@@",	$68,	$2,	$0		; じめん@@,
	db	"TYPE@@@@",	$e8,	$2,	$0		; タイプ@@,
	db	"ELECTRIC",	$8e,	$3,	$0		; でんき@@,
	db	"POISON@@",	$ae,	$3,	$0		; どく@@@,
	db	"DRAGON@@",	$bc,	$3,	$0		; ドラゴン@,
	db	"NORMAL@@",	$22,	$4,	$0		; ノーマル@,
	db	"STEEL@@@",	$36,	$4,	$0		; はがね@@,
	db	"FLYING@@",	$5e,	$4,	$0		; ひこう@@,
	db	"FIRE@@@@",	$b2,	$4,	$0		; ほのお@@,
	db	"WATER@@@",	$f4,	$4,	$0		; みず@@@,
	db	"BUG@@@@@",	$12,	$5,	$0		; むし@@@,

.Greetings:
	db	"THANKS@@",	$58,	$0,	$0		; ありがと@,
	db	"THANK U@",	$5a,	$0,	$0		; ありがとう,
	db	"LETS GO!",	$80,	$0,	$0		; いくぜ！@,
	db	"GO ON!@@",	$82,	$0,	$0		; いくよ！@,
	db	"DO IT!@@",	$84,	$0,	$0		; いくわよ！,
	db	"YEAH@@@@",	$a6,	$0,	$0		; いやー@@,
	db	"HOW DO@@",	$a,	    $1,	$0		; おっす@@,
	db	"HOWDY!@@",	$22,	$1,	$0		; おはつです,
	db	"CONGRATS",	$2a,	$1,	$0		; おめでとう,
	db	"SORRY@@@",	$f8,	$1,	$0		; ごめん@@,
	db	"SORRY!@@",	$fa,	$1,	$0		; ごめんよ@,
	db	"HI THERE",	$fc,	$1,	$0		; こらっ@@,
	db	"HI!@@@@@",	$a,	    $2,	$0		; こんちは！,
	db	"HELLO@@@",	$10,	$2,	$0		; こんにちは,
	db	"GOOD-BYE",	$28,	$2,	$0		; さようなら,
	db	"CHEERS@@",	$2e,	$2,	$0		; サンキュー,
	db	"I'M HERE",	$30,	$2,	$0		; さんじょう,
	db	"PARDON@@",	$48,	$2,	$0		; しっけい@,
	db	"EXCUSE@@",	$4c,	$2,	$0		; しつれい@,
	db	"SEE YA@@",	$6c,	$2,	$0		; じゃーね@,
	db	"YO!@@@@@",	$8c,	$2,	$0		; すいません,
	db	"WELL...@",	$ca,	$2,	$0		; それじゃ@,
	db	"GRATEFUL",	$a6,	$3,	$0		; どうも@@,
	db	"WASSUP?@",	$ee,	$3,	$0		; なんじゃ@,
	db	"HI@@@@@@",	$2c,	$4,	$0		; ハーイ@@,
	db	"YEA, YEA",	$32,	$4,	$0		; はいはい@,
	db	"BYE-BYE@",	$34,	$4,	$0		; バイバイ@,
	db	"HEY@@@@@",	$8a,	$4,	$0		; へイ@@@,
	db	"SMELL@@@",	$de,	$4,	$0		; またね@@,
	db	"TUNED IN",	$32,	$5,	$0		; もしもし@,
	db	"HOO-HAH@",	$3e,	$5,	$0		; やあ@@@,
	db	"YAHOO@@@",	$4e,	$5,	$0		; やっほー@,
	db	"YO@@@@@@",	$62,	$5,	$0		; よう@@@,
	db	"GO OVER@",	$64,	$5,	$0		; ようこそ@,
	db	"COUNT ON",	$80,	$5,	$0		; よろしく@,
	db	"WELCOME@",	$94,	$5,	$0		; らっしゃい,

.People:
	db	"OPPONENT",	$1c,	$0,	$0		; あいて@@,
	db	"I@@@@@@@",	$36,	$0,	$0		; あたし@@,
	db	"YOU@@@@@",	$40,	$0,	$0		; あなた@@,
	db	"YOURS@@@",	$42,	$0,	$0		; あなたが@,
	db	"SON@@@@@",	$44,	$0,	$0		; あなたに@,
	db	"YOUR@@@@",	$46,	$0,	$0		; あなたの@,
	db	"YOU'RE@@",	$48,	$0,	$0		; あなたは@,
	db	"YOU'VE@@",	$4a,	$0,	$0		; あなたを@,
	db	"MOM@@@@@",	$e8,	$0,	$0		; おかあさん,
	db	"GRANDPA@",	$fc,	$0,	$0		; おじいさん,
	db	"UNCLE@@@",	$2,	    $1,	$0		; おじさん@,
	db	"DAD@@@@@",	$e,	    $1,	$0		; おとうさん,
	db	"BOY@@@@@",	$10,	$1,	$0		; おとこのこ,
	db	"ADULT@@@",	$14,	$1,	$0		; おとな@@,
	db	"BROTHER@",	$16,	$1,	$0		; おにいさん,
	db	"SISTER@@",	$18,	$1,	$0		; おねえさん,
	db	"GRANDMA@",	$1c,	$1,	$0		; おばあさん,
	db	"AUNT@@@@",	$20,	$1,	$0		; おばさん@,
	db	"ME@@@@@@",	$34,	$1,	$0		; おれさま@,
	db	"GIRL@@@@",	$3a,	$1,	$0		; おんなのこ,
	db	"BABE@@@@",	$40,	$1,	$0		; ガール@@,
	db	"FAMILY@@",	$52,	$1,	$0		; かぞく@@,
	db	"HER@@@@@",	$72,	$1,	$0		; かのじょ@,
	db	"HIM@@@@@",	$7c,	$1,	$0		; かれ@@@,
	db	"HE@@@@@@",	$9a,	$1,	$0		; きみ@@@,
	db	"PLACE@@@",	$9c,	$1,	$0		; きみが@@,
	db	"DAUGHTER",	$9e,	$1,	$0		; きみに@@,
	db	"HIS@@@@@",	$a0,	$1,	$0		; きみの@@,
	db	"HE'S@@@@",	$a2,	$1,	$0		; きみは@@,
	db	"AREN'T@@",	$a4,	$1,	$0		; きみを@@,
	db	"GAL@@@@@",	$ae,	$1,	$0		; ギャル@@,
	db	"SIBLINGS",	$b2,	$1,	$0		; きょうだい,
	db	"CHILDREN",	$f0,	$1,	$0		; こども@@,
	db	"MYSELF@@",	$54,	$2,	$0		; じぶん@@,
	db	"I WAS@@@",	$56,	$2,	$0		; じぶんが@,
	db	"TO ME@@@",	$58,	$2,	$0		; じぶんに@,
	db	"MY@@@@@@",	$5a,	$2,	$0		; じぶんの@,
	db	"I AM@@@@",	$5c,	$2,	$0		; じぶんは@,
	db	"I'VE@@@@",	$5e,	$2,	$0		; じぶんを@,
	db	"WHO@@@@@",	$18,	$3,	$0		; だれ@@@,
	db	"SOMEONE@",	$1a,	$3,	$0		; だれか@@,
	db	"WHO WAS@",	$1c,	$3,	$0		; だれが@@,
	db	"TO WHOM@",	$1e,	$3,	$0		; だれに@@,
	db	"WHOSE@@@",	$20,	$3,	$0		; だれの@@,
	db	"WHO IS@@",	$22,	$3,	$0		; だれも@@,
	db	"IT'S@@@@",	$24,	$3,	$0		; だれを@@,
	db	"LADY@@@@",	$38,	$3,	$0		; ちゃん@@,
	db	"FRIEND@@",	$b8,	$3,	$0		; ともだち@,
	db	"ALLY@@@@",	$d4,	$3,	$0		; なかま@@,
	db	"PEOPLE@@",	$62,	$4,	$0		; ひと@@@,
	db	"DUDE@@@@",	$98,	$4,	$0		; ボーイ@@,
	db	"THEY@@@@",	$a0,	$4,	$0		; ボク@@@,
	db	"THEY ARE",	$a2,	$4,	$0		; ボクが@@,
	db	"TO THEM@",	$a4,	$4,	$0		; ボクに@@,
	db	"THEIR@@@",	$a6,	$4,	$0		; ボクの@@,
	db	"THEY'RE@",	$a8,	$4,	$0		; ボクは@@,
	db	"THEY'VE@",	$aa,	$4,	$0		; ボクを@@,
	db	"WE@@@@@@",	$4,	    $5,	$0		; みんな@@,
	db	"BEEN@@@@",	$6,	    $5,	$0		; みんなが@,
	db	"TO US@@@",	$8,	    $5,	$0		; みんなに@,
	db	"OUR@@@@@",	$a,	    $5,	$0		; みんなの@,
	db	"WE'RE@@@",	$c,	    $5,	$0		; みんなは@,
	db	"RIVAL@@@",	$8a,	$5,	$0		; ライバル@,
	db	"SHE@@@@@",	$c2,	$5,	$0		; わたし@@,
	db	"SHE WAS@",	$c4,	$5,	$0		; わたしが@,
	db	"TO HER@@",	$c6,	$5,	$0		; わたしに@,
	db	"HERS@@@@",	$c8,	$5,	$0		; わたしの@,
	db	"SHE IS@@",	$ca,	$5,	$0		; わたしは@,
	db	"SOME@@@@",	$cc,	$5,	$0		; わたしを@,

.Battle:
	db	"MATCH UP",	$18,	$0,	$0		; あいしょう,
	db	"GO!@@@@@",	$88,	$0,	$0		; いけ！@@,
	db	"NO. 1@@@",	$96,	$0,	$0		; いちばん@,
	db	"DECIDE@@",	$4c,	$1,	$0		; かくご@@,
	db	"I WIN@@@",	$54,	$1,	$0		; かたせて@,
	db	"WINS@@@@",	$56,	$1,	$0		; かち@@@,
	db	"WIN@@@@@",	$58,	$1,	$0		; かつ@@@,
	db	"WON@@@@@",	$60,	$1,	$0		; かった@@,
	db	"IF I WIN",	$62,	$1,	$0		; かったら@,
	db	"I'LL WIN",	$64,	$1,	$0		; かって@@,
	db	"CANT WIN",	$66,	$1,	$0		; かてない@,
	db	"CAN WIN@",	$68,	$1,	$0		; かてる@@,
	db	"NO MATCH",	$70,	$1,	$0		; かなわない,
	db	"SPIRIT@@",	$84,	$1,	$0		; きあい@@,
	db	"DECIDED@",	$a8,	$1,	$0		; きめた@@,
	db	"ACE CARD",	$b6,	$1,	$0		; きりふだ@,
	db	"HI-YA!@@",	$c2,	$1,	$0		; くらえ@@,
	db	"COME ON@",	$da,	$1,	$0		; こい！@@,
	db	"ATTACK@@",	$e0,	$1,	$0		; こうげき@,
	db	"GIVE UP@",	$e2,	$1,	$0		; こうさん@,
	db	"GUTS@@@@",	$8,	    $2,	$0		; こんじょう,
	db	"TALENT@@",	$16,	$2,	$0		; さいのう@,
	db	"STRATEGY",	$1a,	$2,	$0		; さくせん@,
	db	"SMITE@@@",	$22,	$2,	$0		; さばき@@,
	db	"MATCH@@@",	$7e,	$2,	$0		; しょうぶ@,
	db	"VICTORY@",	$80,	$2,	$0		; しょうり@,
	db	"OFFENSE@",	$b4,	$2,	$0		; せめ@@@,
	db	"SENSE@@@",	$b6,	$2,	$0		; センス@@,
	db	"VERSUS@@",	$e6,	$2,	$0		; たいせん@,
	db	"FIGHTS@@",	$f6,	$2,	$0		; たたかい@,
	db	"POWER@@@",	$32,	$3,	$0		; ちから@@,
	db	"TASK@@@@",	$36,	$3,	$0		; チャレンジ,
	db	"STRONG@@",	$58,	$3,	$0		; つよい@@,
	db	"TOO MUCH",	$5a,	$3,	$0		; つよすぎ@,
	db	"HARD@@@@",	$5c,	$3,	$0		; つらい@@,
	db	"TERRIBLE",	$5e,	$3,	$0		; つらかった,
	db	"GO EASY@",	$6c,	$3,	$0		; てかげん@,
	db	"FOE@@@@@",	$6e,	$3,	$0		; てき@@@,
	db	"GENIUS@@",	$90,	$3,	$0		; てんさい@,
	db	"LEGEND@@",	$94,	$3,	$0		; でんせつ@,
	db	"TRAINER@",	$c6,	$3,	$0		; トレーナー,
	db	"ESCAPE@@",	$4,	    $4,	$0		; にげ@@@,
	db	"LUKEWARM",	$10,	$4,	$0		; ぬるい@@,
	db	"AIM@@@@@",	$16,	$4,	$0		; ねらう@@,
	db	"BATTLE@@",	$4a,	$4,	$0		; バトル@@,
	db	"FIGHT@@@",	$72,	$4,	$0		; ファイト@,
	db	"REVIVE@@",	$78,	$4,	$0		; ふっかつ@,
	db	"POINTS@@",	$94,	$4,	$0		; ポイント@,
	db	"POKÉMON@",	$ac,	$4,	$0		; ポケモン@,
	db	"SERIOUS@",	$bc,	$4,	$0		; ほんき@@,
	db	"OH NO!@@",	$c4,	$4,	$0		; まいった！,
	db	"LOSS@@@@",	$c8,	$4,	$0		; まけ@@@,
	db	"YOU LOSE",	$ca,	$4,	$0		; まけたら@,
	db	"LOST@@@@",	$cc,	$4,	$0		; まけて@@,
	db	"LOSE@@@@",	$ce,	$4,	$0		; まける@@,
	db	"GUARD@@@",	$ea,	$4,	$0		; まもり@@,
	db	"PARTNER@",	$f2,	$4,	$0		; みかた@@,
	db	"REJECT@@",	$fe,	$4,	$0		; みとめない,
	db	"ACCEPT@@",	$0,	    $5,	$0		; みとめる@,
	db	"UNBEATEN",	$16,	$5,	$0		; むてき@@,
	db	"GOT IT!@",	$3c,	$5,	$0		; もらった！,
	db	"EASY@@@@",	$7a,	$5,	$0		; よゆう@@,
	db	"WEAK@@@@",	$82,	$5,	$0		; よわい@@,
	db	"TOO WEAK",	$84,	$5,	$0		; よわすぎ@,
	db	"PUSHOVER",	$8e,	$5,	$0		; らくしょう,
	db	"CHIEF@@@",	$9e,	$5,	$0		; りーダー@,
	db	"RULE@@@@",	$a0,	$5,	$0		; ルール@@,
	db	"LEVEL@@@",	$a6,	$5,	$0		; レべル@@,
	db	"MOVE@@@@",	$be,	$5,	$0		; わざ@@@,

.Exclamations:
	db	"!@@@@@@@",	$0,	    $0,	$0		; ！@@@@,
	db	"!!@@@@@@",	$2,	    $0,	$0		; ！！@@@,
	db	"!?@@@@@@",	$4,	    $0,	$0		; ！？@@@,
	db	"?@@@@@@@",	$6,	    $0,	$0		; ？@@@@,
	db	"…@@@@@@@",	$8,	    $0,	$0		; ⋯@@@@,
	db	"…!@@@@@@",	$a,	    $0,	$0		; ⋯！@@@,
	db	"………@@@@@",	$c,	    $0,	$0		; ⋯⋯⋯@@,
	db	"-@@@@@@@",	$e,	    $0,	$0		; ー@@@@,
	db	"- - -@@@",	$10,	$0,	$0		; ーーー@@,
	db	"UH-OH@@@",	$14,	$0,	$0		; あーあ@@,
	db	"WAAAH@@@",	$16,	$0,	$0		; あーん@@,
	db	"AHAHA@@@",	$52,	$0,	$0		; あははー@,
	db	"OH?@@@@@",	$54,	$0,	$0		; あら@@@,
	db	"NOPE@@@@",	$72,	$0,	$0		; いえ@@@,
	db	"YES@@@@@",	$74,	$0,	$0		; イエス@@,
	db	"URGH@@@@",	$ac,	$0,	$0		; うう@@@,
	db	"HMM@@@@@",	$ae,	$0,	$0		; うーん@@,
	db	"WHOAH@@@",	$b0,	$0,	$0		; うおー！@,
	db	"WROOAAR!",	$b2,	$0,	$0		; うおりゃー,
	db	"WOW@@@@@",	$bc,	$0,	$0		; うひょー@,
	db	"GIGGLES@",	$be,	$0,	$0		; うふふ@@,
	db	"SHOCKING",	$ca,	$0,	$0		; うわー@@,
	db	"CRIES@@@",	$cc,	$0,	$0		; うわーん@,
	db	"AGREE@@@",	$d2,	$0,	$0		; ええ@@@,
	db	"EH?@@@@@",	$d4,	$0,	$0		; えー@@@,
	db	"CRY@@@@@",	$d6,	$0,	$0		; えーん@@,
	db	"EHEHE@@@",	$dc,	$0,	$0		; えへへ@@,
	db	"HOLD ON!",	$e0,	$0,	$0		; おいおい@,
	db	"OH, YEAH",	$e2,	$0,	$0		; おお@@@,
	db	"OOPS@@@@",	$c,	    $1,	$0		; おっと@@,
	db	"SHOCKED@",	$42,	$1,	$0		; がーん@@,
	db	"EEK@@@@@",	$aa,	$1,	$0		; キャー@@,
	db	"GRAAAH@@",	$ac,	$1,	$0		; ギャー@@,
	db	"HE-HE-HE",	$bc,	$1,	$0		; ぐふふふふ,
	db	"ICK!@@@@",	$ce,	$1,	$0		; げっ@@@,
	db	"WEEP@@@@",	$3e,	$2,	$0		; しくしく@,
	db	"HMPH@@@@",	$2e,	$3,	$0		; ちえっ@@,
	db	"BLUSH@@@",	$86,	$3,	$0		; てへ@@@,
	db	"NO@@@@@@",	$20,	$4,	$0		; ノー@@@,
	db	"HUH?@@@@",	$2a,	$4,	$0		; はあー@@,
	db	"YUP@@@@@",	$30,	$4,	$0		; はい@@@,
	db	"HAHAHA@@",	$48,	$4,	$0		; はっはっは,
	db	"AIYEEH@@",	$56,	$4,	$0		; ひいー@@,
	db	"HIYAH@@@",	$6a,	$4,	$0		; ひゃあ@@,
	db	"FUFU@@@@",	$7c,	$4,	$0		; ふっふっふ,
	db	"MUTTER@@",	$7e,	$4,	$0		; ふにゃ@@,
	db	"LOL@@@@@",	$80,	$4,	$0		; ププ@@@,
	db	"SNORT@@@",	$82,	$4,	$0		; ふふん@@,
	db	"HUMPH@@@",	$88,	$4,	$0		; ふん@@@,
	db	"HEHEHE@@",	$8e,	$4,	$0		; へっへっへ,
	db	"HEHE@@@@",	$90,	$4,	$0		; へへー@@,
	db	"HOHOHO@@",	$9c,	$4,	$0		; ほーほほほ,
	db	"UH-HUH@@",	$b6,	$4,	$0		; ほら@@@,
	db	"OH, DEAR",	$c0,	$4,	$0		; まあ@@@,
	db	"ARRGH!@@",	$10,	$5,	$0		; むきー！！,
	db	"MUFU@@@@",	$18,	$5,	$0		; むふー@@,
	db	"MUFUFU@@",	$1a,	$5,	$0		; むふふ@@,
	db	"MMM@@@@@",	$1c,	$5,	$0		; むむ@@@,
	db	"OH-KAY@@",	$6a,	$5,	$0		; よーし@@,
	db	"OKAY!@@@",	$72,	$5,	$0		; よし！@@,
	db	"LALALA@@",	$98,	$5,	$0		; ラララ@@,
	db	"YAY@@@@@",	$ac,	$5,	$0		; わーい@@,
	db	"AWW!@@@@",	$b0,	$5,	$0		; わーん！！,
	db	"WOWEE@@@",	$b2,	$5,	$0		; ワオ@@@,
	db	"GWAH!@@@",	$ce,	$5,	$0		; わっ！！@,
	db	"WAHAHA!@",	$d0,	$5,	$0		; わははは！,

.Conversation:
	db	"LISTEN@@",	$50,	$0,	$0		; あのね@@,
	db	"NOT VERY",	$6e,	$0,	$0		; あんまり@,
	db	"MEAN@@@@",	$8e,	$0,	$0		; いじわる@,
	db	"LIE@@@@@",	$b6,	$0,	$0		; うそ@@@,
	db	"LAY@@@@@",	$c4,	$0,	$0		; うむ@@@,
	db	"OI@@@@@@",	$e4,	$0,	$0		; おーい@@,
	db	"SUGGEST@",	$6,	    $1,	$0		; おすすめ@,
	db	"NITWIT@@",	$1e,	$1,	$0		; おばかさん,
	db	"QUITE@@@",	$6e,	$1,	$0		; かなり@@,
	db	"FROM@@@@",	$7a,	$1,	$0		; から@@@,
	db	"FEELING@",	$98,	$1,	$0		; きぶん@@,
	db	"BUT@@@@@",	$d6,	$1,	$0		; けど@@@,
	db	"HOWEVER@",	$ea,	$1,	$0		; こそ@@@,
	db	"CASE@@@@",	$ee,	$1,	$0		; こと@@@,
	db	"MISS@@@@",	$12,	$2,	$0		; さあ@@@,
	db	"HOW@@@@@",	$1e,	$2,	$0		; さっぱり@,
	db	"HIT@@@@@",	$20,	$2,	$0		; さて@@@,
	db	"ENOUGH@@",	$72,	$2,	$0		; じゅうぶん,
	db	"SOON@@@@",	$94,	$2,	$0		; すぐ@@@,
	db	"A LOT@@@",	$98,	$2,	$0		; すごく@@,
	db	"A LITTLE",	$9a,	$2,	$0		; すこしは@,
	db	"AMAZING@",	$a0,	$2,	$0		; すっっごい,
	db	"ENTIRELY",	$b0,	$2,	$0		; ぜーんぜん,
	db	"FULLY@@@",	$b2,	$2,	$0		; ぜったい@,
	db	"AND SO@@",	$ce,	$2,	$0		; それで@@,
	db	"ONLY@@@@",	$f2,	$2,	$0		; だけ@@@,
	db	"AROUND@@",	$fc,	$2,	$0		; だって@@,
	db	"PROBABLY",	$6,	    $3,	$0		; たぶん@@,
	db	"IF@@@@@@",	$14,	$3,	$0		; たら@@@,
	db	"VERY@@@@",	$3a,	$3,	$0		; ちょー@@,
	db	"A BIT@@@",	$3c,	$3,	$0		; ちょっと@,
	db	"WILD@@@@",	$4e,	$3,	$0		; ったら@@,
	db	"THAT'S@@",	$50,	$3,	$0		; って@@@,
	db	"I MEAN@@",	$62,	$3,	$0		; ていうか@,
	db	"EVEN SO,",	$88,	$3,	$0		; でも@@@,
	db	"MUST BE@",	$9c,	$3,	$0		; どうしても,
	db	"NATURALY",	$a0,	$3,	$0		; とうぜん@,
	db	"GO AHEAD",	$a2,	$3,	$0		; どうぞ@@,
	db	"FOR NOW,",	$be,	$3,	$0		; とりあえず,
	db	"HEY?@@@@",	$cc,	$3,	$0		; なあ@@@,
	db	"JOKING@@",	$f4,	$3,	$0		; なんて@@,
	db	"READY@@@",	$fc,	$3,	$0		; なんでも@,
	db	"SOMEHOW@",	$fe,	$3,	$0		; なんとか@,
	db	"ALTHOUGH",	$8,	    $4,	$0		; には@@@,
	db	"PERFECT@",	$46,	$4,	$0		; バッチり@,
	db	"FIRMLY@@",	$52,	$4,	$0		; ばりばり@,
	db	"EQUAL TO",	$b0,	$4,	$0		; ほど@@@,
	db	"REALLY@@",	$be,	$4,	$0		; ほんと@@,
	db	"TRULY@@@",	$d0,	$4,	$0		; まさに@@,
	db	"SURELY@@",	$d2,	$4,	$0		; マジ@@@,
	db	"FOR SURE",	$d4,	$4,	$0		; マジで@@,
	db	"TOTALLY@",	$e4,	$4,	$0		; まったく@,
	db	"UNTIL@@@",	$e6,	$4,	$0		; まで@@@,
	db	"AS IF@@@",	$ec,	$4,	$0		; まるで@@,
	db	"MOOD@@@@",	$e,	    $5,	$0		; ムード@@,
	db	"RATHER@@",	$14,	$5,	$0		; むしろ@@,
	db	"NO WAY@@",	$24,	$5,	$0		; めちゃ@@,
	db	"AWFULLY@",	$28,	$5,	$0		; めっぽう@,
	db	"ALMOST@@",	$2c,	$5,	$0		; もう@@@,
	db	"MODE@@@@",	$2e,	$5,	$0		; モード@@,
	db	"MORE@@@@",	$36,	$5,	$0		; もっと@@,
	db	"TOO LATE",	$38,	$5,	$0		; もはや@@,
	db	"FINALLY@",	$4a,	$5,	$0		; やっと@@,
	db	"ANY@@@@@",	$4c,	$5,	$0		; やっぱり@,
	db	"INSTEAD@",	$7c,	$5,	$0		; より@@@,
	db	"TERRIFIC",	$a4,	$5,	$0		; れば@@@,

.Feelings:
	db	"MEET@@@@",	$1a,	$0,	$0		; あいたい@,
	db	"PLAY@@@@",	$32,	$0,	$0		; あそびたい,
	db	"GOES@@@@",	$7c,	$0,	$0		; いきたい@,
	db	"GIDDY@@@",	$b4,	$0,	$0		; うかれて@,
	db	"HAPPY@@@",	$c6,	$0,	$0		; うれしい@,
	db	"GLEE@@@@",	$c8,	$0,	$0		; うれしさ@,
	db	"EXCITE@@",	$d8,	$0,	$0		; エキサイト,
	db	"CRUCIAL@",	$de,	$0,	$0		; えらい@@,
	db	"FUNNY@@@",	$ec,	$0,	$0		; おかしい@,
	db	"GOT@@@@@",	$8,	    $1,	$0		; オッケー@,
	db	"GO HOME@",	$48,	$1,	$0		; かえりたい,
	db	"FAILS@@@",	$5a,	$1,	$0		; がっくし@,
	db	"SAD@@@@@",	$6c,	$1,	$0		; かなしい@,
	db	"TRY@@@@@",	$80,	$1,	$0		; がんばって,
	db	"HEARS@@@",	$86,	$1,	$0		; きがしない,
	db	"THINK@@@",	$88,	$1,	$0		; きがする@,
	db	"HEAR@@@@",	$8a,	$1,	$0		; ききたい@,
	db	"WANTS@@@",	$90,	$1,	$0		; きになる@,
	db	"MISHEARD",	$96,	$1,	$0		; きのせい@,
	db	"DISLIKE@",	$b4,	$1,	$0		; きらい@@,
	db	"ANGRY@@@",	$be,	$1,	$0		; くやしい@,
	db	"ANGER@@@",	$c0,	$1,	$0		; くやしさ@,
	db	"LONESOME",	$24,	$2,	$0		; さみしい@,
	db	"FAIL@@@@",	$32,	$2,	$0		; ざんねん@,
	db	"JOY@@@@@",	$36,	$2,	$0		; しあわせ@,
	db	"GETS@@@@",	$44,	$2,	$0		; したい@@,
	db	"NEVER@@@",	$46,	$2,	$0		; したくない,
	db	"DARN@@@@",	$64,	$2,	$0		; しまった@,
	db	"DOWNCAST",	$82,	$2,	$0		; しょんぼり,
	db	"LIKES@@@",	$92,	$2,	$0		; すき@@@,
	db	"DISLIKES",	$da,	$2,	$0		; だいきらい,
	db	"BORING@@",	$dc,	$2,	$0		; たいくつ@,
	db	"CARE@@@@",	$de,	$2,	$0		; だいじ@@,
	db	"ADORE@@@",	$e4,	$2,	$0		; だいすき@,
	db	"DISASTER",	$ea,	$2,	$0		; たいへん@,
	db	"ENJOY@@@",	$0,	    $3,	$0		; たのしい@,
	db	"ENJOYS@@",	$2,	    $3,	$0		; たのしすぎ,
	db	"EAT@@@@@",	$8,	    $3,	$0		; たべたい@,
	db	"USELESS@",	$e,	    $3,	$0		; ダメダメ@,
	db	"LACKING@",	$16,	$3,	$0		; たりない@,
	db	"BAD@@@@@",	$34,	$3,	$0		; ちくしょー,
	db	"SHOULD@@",	$9e,	$3,	$0		; どうしよう,
	db	"EXCITING",	$ac,	$3,	$0		; ドキドキ@,
	db	"NICE@@@@",	$d0,	$3,	$0		; ナイス@@,
	db	"DRINK@@@",	$26,	$4,	$0		; のみたい@,
	db	"SURPRISE",	$60,	$4,	$0		; びっくり@,
	db	"FEAR@@@@",	$74,	$4,	$0		; ふあん@@,
	db	"WOBBLY@@",	$86,	$4,	$0		; ふらふら@,
	db	"WANT@@@@",	$ae,	$4,	$0		; ほしい@@,
	db	"SHREDDED",	$b8,	$4,	$0		; ボロボロ@,
	db	"YET@@@@@",	$e0,	$4,	$0		; まだまだ@,
	db	"WAIT@@@@",	$e8,	$4,	$0		; まてない@,
	db	"CONTENT@",	$f0,	$4,	$0		; まんぞく@,
	db	"SEE@@@@@",	$f8,	$4,	$0		; みたい@@,
	db	"RARE@@@@",	$22,	$5,	$0		; めずらしい,
	db	"FIERY@@@",	$2a,	$5,	$0		; メラメラ@,
	db	"NEGATIVE",	$46,	$5,	$0		; やだ@@@,
	db	"DONE@@@@",	$48,	$5,	$0		; やったー@,
	db	"DANGER@@",	$50,	$5,	$0		; やばい@@,
	db	"DONE FOR",	$52,	$5,	$0		; やばすぎる,
	db	"DEFEATED",	$54,	$5,	$0		; やられた@,
	db	"BEAT@@@@",	$56,	$5,	$0		; やられて@,
	db	"GREAT@@@",	$6e,	$5,	$0		; よかった@,
	db	"DOTING@@",	$96,	$5,	$0		; ラブラブ@,
	db	"ROMANTIC",	$a8,	$5,	$0		; ロマン@@,
	db	"QUESTION",	$aa,	$5,	$0		; ろんがい@,
	db	"REALIZE@",	$b4,	$5,	$0		; わから@@,
	db	"REALIZES",	$b6,	$5,	$0		; わかり@@,
	db	"SUSPENSE",	$ba,	$5,	$0		; わくわく@,

.Conditions:
	db	"HOT@@@@@",	$38,	$0,	$0		; あつい@@,
	db	"EXISTS@@",	$3a,	$0,	$0		; あった@@,
	db	"APPROVED",	$56,	$0,	$0		; あり@@@,
	db	"HAS@@@@@",	$5e,	$0,	$0		; ある@@@,
	db	"HURRIED@",	$6a,	$0,	$0		; あわてて@,
	db	"GOOD@@@@",	$70,	$0,	$0		; いい@@@,
	db	"LESS@@@@",	$76,	$0,	$0		; いか@@@,
	db	"MEGA@@@@",	$78,	$0,	$0		; イカス@@,
	db	"MOMENTUM",	$7a,	$0,	$0		; いきおい@,
	db	"GOING@@@",	$8a,	$0,	$0		; いける@@,
	db	"WEIRD@@@",	$8c,	$0,	$0		; いじょう@,
	db	"BUSY@@@@",	$90,	$0,	$0		; いそがしい,
	db	"TOGETHER",	$9a,	$0,	$0		; いっしょに,
	db	"FULL@@@@",	$9c,	$0,	$0		; いっぱい@,
	db	"ABSENT@@",	$a0,	$0,	$0		; いない@@,
	db	"BEING@@@",	$a4,	$0,	$0		; いや@@@,
	db	"NEED@@@@",	$a8,	$0,	$0		; いる@@@,
	db	"TASTY@@@",	$c0,	$0,	$0		; うまい@@,
	db	"SKILLED@",	$c2,	$0,	$0		; うまく@@,
	db	"BIG@@@@@",	$e6,	$0,	$0		; おおきい@,
	db	"LATE@@@@",	$f2,	$0,	$0		; おくれ@@,
	db	"CLOSE@@@",	$fa,	$0,	$0		; おしい@@,
	db	"AMUSING@",	$2c,	$1,	$0		; おもしろい,
	db	"ENGAGING",	$2e,	$1,	$0		; おもしろく,
	db	"COOL@@@@",	$5c,	$1,	$0		; かっこいい,
	db	"CUTE@@@@",	$7e,	$1,	$0		; かわいい@,
	db	"FLAWLESS",	$82,	$1,	$0		; かんぺき@,
	db	"PRETTY@@",	$d0,	$1,	$0		; けっこう@,
	db	"HEALTHY@",	$d8,	$1,	$0		; げんき@@,
	db	"SCARY@@@",	$6,	    $2,	$0		; こわい@@,
	db	"SUPERB@@",	$14,	$2,	$0		; さいこう@,
	db	"COLD@@@@",	$26,	$2,	$0		; さむい@@,
	db	"LIVELY@@",	$2c,	$2,	$0		; さわやか@,
	db	"FATED@@@",	$38,	$2,	$0		; しかたない,
	db	"MUCH@@@@",	$96,	$2,	$0		; すごい@@,
	db	"IMMENSE@",	$9c,	$2,	$0		; すごすぎ@,
	db	"FABULOUS",	$a4,	$2,	$0		; すてき@@,
	db	"ELSE@@@@",	$e0,	$2,	$0		; たいした@,
	db	"ALRIGHT@",	$e2,	$2,	$0		; だいじょぶ,
	db	"COSTLY@@",	$ec,	$2,	$0		; たかい@@,
	db	"CORRECT@",	$f8,	$2,	$0		; ただしい@,
	db	"UNLIKELY",	$c,	    $3,	$0		; だめ@@@,
	db	"SMALL@@@",	$2c,	$3,	$0		; ちいさい@,
	db	"VARIED@@",	$30,	$3,	$0		; ちがう@@,
	db	"TIRED@@@",	$48,	$3,	$0		; つかれ@@,
	db	"SKILL@@@",	$b0,	$3,	$0		; とくい@@,
	db	"NON-STOP",	$b6,	$3,	$0		; とまらない,
	db	"NONE@@@@",	$ce,	$3,	$0		; ない@@@,
	db	"NOTHING@",	$d2,	$3,	$0		; なかった@,
	db	"NATURAL@",	$d8,	$3,	$0		; なし@@@,
	db	"BECOMES@",	$dc,	$3,	$0		; なって@@,
	db	"FAST@@@@",	$50,	$4,	$0		; はやい@@,
	db	"SHINE@@@",	$5a,	$4,	$0		; ひかる@@,
	db	"LOW@@@@@",	$5c,	$4,	$0		; ひくい@@,
	db	"AWFUL@@@",	$64,	$4,	$0		; ひどい@@,
	db	"ALONE@@@",	$66,	$4,	$0		; ひとりで@,
	db	"BORED@@@",	$68,	$4,	$0		; ひま@@@,
	db	"LACKS@@@",	$76,	$4,	$0		; ふそく@@,
	db	"LOUSY@@@",	$8c,	$4,	$0		; へた@@@,
	db	"MISTAKE@",	$e2,	$4,	$0		; まちがって,
	db	"KIND@@@@",	$42,	$5,	$0		; やさしい@,
	db	"WELL@@@@",	$70,	$5,	$0		; よく@@@,
	db	"WEAKENED",	$86,	$5,	$0		; よわって@,
	db	"SIMPLE@@",	$8c,	$5,	$0		; らく@@@,
	db	"SEEMS@@@",	$90,	$5,	$0		; らしい@@,
	db	"BADLY@@@",	$d4,	$5,	$0		; わるい@@,

.Life:
	db	"CHORES@@",	$64,	$0,	$0		; アルバイト,
	db	"HOME@@@@",	$ba,	$0,	$0		; うち@@@,
	db	"MONEY@@@",	$ee,	$0,	$0		; おかね@@,
	db	"SAVINGS@",	$f4,	$0,	$0		; おこづかい,
	db	"BATH@@@@",	$24,	$1,	$0		; おふろ@@,
	db	"SCHOOL@@",	$5e,	$1,	$0		; がっこう@,
	db	"REMEMBER",	$92,	$1,	$0		; きねん@@,
	db	"GROUP@@@",	$c6,	$1,	$0		; グループ@,
	db	"GOTCHA@@",	$d2,	$1,	$0		; ゲット@@,
	db	"EXCHANGE",	$de,	$1,	$0		; こうかん@,
	db	"WORK@@@@",	$40,	$2,	$0		; しごと@@,
	db	"TRAINING",	$74,	$2,	$0		; しゅぎょう,
	db	"CLASS@@@",	$76,	$2,	$0		; じゅぎょう,
	db	"LESSONS@",	$78,	$2,	$0		; じゅく@@,
	db	"EVOLVE@@",	$88,	$2,	$0		; しんか@@,
	db	"HANDBOOK",	$90,	$2,	$0		; ずかん@@,
	db	"LIVING@@",	$ae,	$2,	$0		; せいかつ@,
	db	"TEACHER@",	$b8,	$2,	$0		; せんせい@,
	db	"CENTER@@",	$ba,	$2,	$0		; センター@,
	db	"TOWER@@@",	$28,	$3,	$0		; タワー@@,
	db	"LINK@@@@",	$40,	$3,	$0		; つうしん@,
	db	"TEST@@@@",	$7e,	$3,	$0		; テスト@@,
	db	"TV@@@@@@",	$8c,	$3,	$0		; テレビ@@,
	db	"PHONE@@@",	$96,	$3,	$0		; でんわ@@,
	db	"ITEM@@@@",	$9a,	$3,	$0		; どうぐ@@,
	db	"TRADE@@@",	$c4,	$3,	$0		; トレード@,
	db	"NAME@@@@",	$e8,	$3,	$0		; なまえ@@,
	db	"NEWS@@@@",	$a,	    $4,	$0		; ニュース@,
	db	"POPULAR@",	$c,	    $4,	$0		; にんき@@,
	db	"PARTY@@@",	$2e,	$4,	$0		; パーティー,
	db	"STUDY@@@",	$92,	$4,	$0		; べんきょう,
	db	"MACHINE@",	$d6,	$4,	$0		; マシン@@,
	db	"CARD@@@@",	$1e,	$5,	$0		; めいし@@,
	db	"MESSAGE@",	$26,	$5,	$0		; メッセージ,
	db	"MAKEOVER",	$3a,	$5,	$0		; もようがえ,
	db	"DREAM@@@",	$5a,	$5,	$0		; ゆめ@@@,
	db	"DAY CARE",	$66,	$5,	$0		; ようちえん,
	db	"RADIO@@@",	$92,	$5,	$0		; ラジオ@@,
	db	"WORLD@@@",	$ae,	$5,	$0		; ワールド@,

.Hobbies:
	db	"IDOL@@@@",	$1e,	$0,	$0		; アイドル@,
	db	"ANIME@@@",	$4c,	$0,	$0		; アニメ@@,
	db	"SONG@@@@",	$b8,	$0,	$0		; うた@@@,
	db	"MOVIE@@@",	$d0,	$0,	$0		; えいが@@,
	db	"CANDY@@@",	$ea,	$0,	$0		; おかし@@,
	db	"CHAT@@@@",	$4,	    $1,	$0		; おしゃべり,
	db	"TOYHOUSE",	$28,	$1,	$0		; おままごと,
	db	"TOYS@@@@",	$30,	$1,	$0		; おもちゃ@,
	db	"MUSIC@@@",	$38,	$1,	$0		; おんがく@,
	db	"CARDS@@@",	$3e,	$1,	$0		; カード@@,
	db	"SHOPPING",	$46,	$1,	$0		; かいもの@,
	db	"GOURMET@",	$c8,	$1,	$0		; グルメ@@,
	db	"GAME@@@@",	$cc,	$1,	$0		; ゲーム@@,
	db	"MAGAZINE",	$1c,	$2,	$0		; ざっし@@,
	db	"WALK@@@@",	$34,	$2,	$0		; さんぽ@@,
	db	"BIKE@@@@",	$50,	$2,	$0		; じてんしゃ,
	db	"HOBBIES@",	$7a,	$2,	$0		; しゅみ@@,
	db	"SPORTS@@",	$a8,	$2,	$0		; スポーツ@,
	db	"DIET@@@@",	$d8,	$2,	$0		; ダイエット,
	db	"TREASURE",	$f0,	$2,	$0		; たからもの,
	db	"TRAVEL@@",	$4,	    $3,	$0		; たび@@@,
	db	"DANCE@@@",	$2a,	$3,	$0		; ダンス@@,
	db	"FISHING@",	$60,	$3,	$0		; つり@@@,
	db	"DATE@@@@",	$6a,	$3,	$0		; デート@@,
	db	"TRAIN@@@",	$92,	$3,	$0		; でんしゃ@,
	db	"PLUSHIE@",	$e,	    $4,	$0		; ぬいぐるみ,
	db	"PC@@@@@@",	$3e,	$4,	$0		; パソコン@,
	db	"FLOWERS@",	$4c,	$4,	$0		; はな@@@,
	db	"HERO@@@@",	$58,	$4,	$0		; ヒーロー@,
	db	"NAP@@@@@",	$6e,	$4,	$0		; ひるね@@,
	db	"HEROINE@",	$70,	$4,	$0		; ヒロイン@,
	db	"JOURNEY@",	$96,	$4,	$0		; ぼうけん@,
	db	"BOARD@@@",	$9a,	$4,	$0		; ボード@@,
	db	"BALL@@@@",	$9e,	$4,	$0		; ボール@@,
	db	"BOOK@@@@",	$ba,	$4,	$0		; ほん@@@,
	db	"MANGA@@@",	$ee,	$4,	$0		; マンガ@@,
	db	"PROMISE@",	$40,	$5,	$0		; やくそく@,
	db	"HOLIDAY@",	$44,	$5,	$0		; やすみ@@,
	db	"PLANS@@@",	$74,	$5,	$0		; よてい@@,

.Actions:
	db	"MEETS@@@",	$20,	$0,	$0		; あう@@@,
	db	"CONCEDE@",	$24,	$0,	$0		; あきらめ@,
	db	"GIVE@@@@",	$28,	$0,	$0		; あげる@@,
	db	"GIVES@@@",	$2e,	$0,	$0		; あせる@@,
	db	"PLAYED@@",	$30,	$0,	$0		; あそび@@,
	db	"PLAYS@@@",	$34,	$0,	$0		; あそぶ@@,
	db	"COLLECT@",	$3e,	$0,	$0		; あつめ@@,
	db	"WALKING@",	$60,	$0,	$0		; あるき@@,
	db	"WALKS@@@",	$62,	$0,	$0		; あるく@@,
	db	"WENT@@@@",	$7e,	$0,	$0		; いく@@@,
	db	"GO@@@@@@",	$86,	$0,	$0		; いけ@@@,
	db	"WAKE UP@",	$f0,	$0,	$0		; おき@@@,
	db	"WAKES UP",	$f6,	$0,	$0		; おこり@@,
	db	"ANGERS@@",	$f8,	$0,	$0		; おこる@@,
	db	"TEACH@@@",	$fe,	$0,	$0		; おしえ@@,
	db	"TEACHES@",	$0,	    $1,	$0		; おしえて@,
	db	"PLEASE@@",	$1a,	$1,	$0		; おねがい@,
	db	"LEARN@@@",	$26,	$1,	$0		; おぼえ@@,
	db	"CHANGE@@",	$4a,	$1,	$0		; かえる@@,
	db	"TRUST@@@",	$74,	$1,	$0		; がまん@@,
	db	"HEARING@",	$8c,	$1,	$0		; きく@@@,
	db	"TRAINS@@",	$8e,	$1,	$0		; きたえ@@,
	db	"CHOOSE@@",	$a6,	$1,	$0		; きめ@@@,
	db	"COME@@@@",	$c4,	$1,	$0		; くる@@@,
	db	"SEARCH@@",	$18,	$2,	$0		; さがし@@,
	db	"CAUSE@@@",	$2a,	$2,	$0		; さわぎ@@,
	db	"THESE@@@",	$42,	$2,	$0		; した@@@,
	db	"KNOW@@@@",	$4a,	$2,	$0		; しって@@,
	db	"KNOWS@@@",	$4e,	$2,	$0		; して@@@,
	db	"REFUSE@@",	$52,	$2,	$0		; しない@@,
	db	"STORES@@",	$60,	$2,	$0		; しまう@@,
	db	"BRAG@@@@",	$66,	$2,	$0		; じまん@@,
	db	"IGNORANT",	$84,	$2,	$0		; しらない@,
	db	"THINKS@@",	$86,	$2,	$0		; しる@@@,
	db	"BELIEVE@",	$8a,	$2,	$0		; しんじて@,
	db	"SLIDE@@@",	$aa,	$2,	$0		; する@@@,
	db	"EATS@@@@",	$a,	    $3,	$0		; たべる@@,
	db	"USE@@@@@",	$42,	$3,	$0		; つかう@@,
	db	"USES@@@@",	$44,	$3,	$0		; つかえ@@,
	db	"USING@@@",	$46,	$3,	$0		; つかって@,
	db	"COULDN'T",	$70,	$3,	$0		; できない@,
	db	"CAPABLE@",	$72,	$3,	$0		; できる@@,
	db	"VANISH@@",	$84,	$3,	$0		; でない@@,
	db	"APPEAR@@",	$8a,	$3,	$0		; でる@@@,
	db	"THROW@@@",	$d6,	$3,	$0		; なげる@@,
	db	"WORRY@@@",	$ea,	$3,	$0		; なやみ@@,
	db	"SLEPT@@@",	$18,	$4,	$0		; ねられ@@,
	db	"SLEEP@@@",	$1a,	$4,	$0		; ねる@@@,
	db	"RELEASE@",	$24,	$4,	$0		; のがし@@,
	db	"DRINKS@@",	$28,	$4,	$0		; のむ@@@,
	db	"RUNS@@@@",	$3a,	$4,	$0		; はしり@@,
	db	"RUN@@@@@",	$3c,	$4,	$0		; はしる@@,
	db	"WORKS@@@",	$40,	$4,	$0		; はたらき@,
	db	"WORKING@",	$42,	$4,	$0		; はたらく@,
	db	"SINK@@@@",	$4e,	$4,	$0		; はまって@,
	db	"SMACK@@@",	$7a,	$4,	$0		; ぶつけ@@,
	db	"PRAISE@@",	$b4,	$4,	$0		; ほめ@@@,
	db	"SHOW@@@@",	$f6,	$4,	$0		; みせて@@,
	db	"LOOKS@@@",	$fc,	$4,	$0		; みて@@@,
	db	"SEES@@@@",	$2,	    $5,	$0		; みる@@@,
	db	"SEEK@@@@",	$20,	$5,	$0		; めざす@@,
	db	"OWN@@@@@",	$34,	$5,	$0		; もって@@,
	db	"TAKE@@@@",	$58,	$5,	$0		; ゆずる@@,
	db	"ALLOW@@@",	$5c,	$5,	$0		; ゆるす@@,
	db	"FORGET@@",	$5e,	$5,	$0		; ゆるせ@@,
	db	"FORGETS@",	$9a,	$5,	$0		; られない@,
	db	"APPEARS@",	$9c,	$5,	$0		; られる@@,
	db	"FAINT@@@",	$b8,	$5,	$0		; わかる@@,
	db	"FAINTED@",	$c0,	$5,	$0		; わすれ@@,

.Time:
	db	"FALL@@@@",	$22,	$0,	$0		; あき@@@,
	db	"MORNING@",	$2a,	$0,	$0		; あさ@@@,
	db	"TOMORROW",	$2c,	$0,	$0		; あした@@,
	db	"DAY@@@@@",	$94,	$0,	$0		; いちにち@,
	db	"SOMETIME",	$98,	$0,	$0		; いつか@@,
	db	"ALWAYS@@",	$9e,	$0,	$0		; いつも@@,
	db	"CURRENT@",	$a2,	$0,	$0		; いま@@@,
	db	"FOREVER@",	$ce,	$0,	$0		; えいえん@,
	db	"DAYS@@@@",	$12,	$1,	$0		; おととい@,
	db	"END@@@@@",	$36,	$1,	$0		; おわり@@,
	db	"TUESDAY@",	$78,	$1,	$0		; かようび@,
	db	"Y'DAY@@@",	$94,	$1,	$0		; きのう@@,
	db	"TODAY@@@",	$b0,	$1,	$0		; きょう@@,
	db	"FRIDAY@@",	$b8,	$1,	$0		; きんようび,
	db	"MONDAY@@",	$d4,	$1,	$0		; げつようび,
	db	"LATER@@@",	$f4,	$1,	$0		; このあと@,
	db	"EARLIER@",	$f6,	$1,	$0		; このまえ@,
	db	"ANOTHER@",	$c,	    $2,	$0		; こんど@@,
	db	"TIME@@@@",	$3c,	$2,	$0		; じかん@@,
	db	"DECADE@@",	$70,	$2,	$0		; じゅうねん,
	db	"WEDNSDAY",	$8e,	$2,	$0		; すいようび,
	db	"START@@@",	$9e,	$2,	$0		; スタート@,
	db	"MONTH@@@",	$a2,	$2,	$0		; ずっと@@,
	db	"STOP@@@@",	$a6,	$2,	$0		; ストップ@,
	db	"NOW@@@@@",	$c4,	$2,	$0		; そのうち@,
	db	"FINAL@@@",	$3e,	$3,	$0		; ついに@@,
	db	"NEXT@@@@",	$4a,	$3,	$0		; つぎ@@@,
	db	"SATURDAY",	$ba,	$3,	$0		; どようび@,
	db	"SUMMER@@",	$da,	$3,	$0		; なつ@@@,
	db	"SUNDAY@@",	$6,	    $4,	$0		; にちようび,
	db	"OUTSET@@",	$38,	$4,	$0		; はじめ@@,
	db	"SPRING@@",	$54,	$4,	$0		; はる@@@,
	db	"DAYTIME@",	$6c,	$4,	$0		; ひる@@@,
	db	"WINTER@@",	$84,	$4,	$0		; ふゆ@@@,
	db	"DAILY@@@",	$c6,	$4,	$0		; まいにち@,
	db	"THURSDAY",	$30,	$5,	$0		; もくようび,
	db	"NITETIME",	$76,	$5,	$0		; よなか@@,
	db	"NIGHT@@@",	$7e,	$5,	$0		; よる@@@,
	db	"WEEK@@@@",	$88,	$5,	$0		; らいしゅう,

.Farewells:
	db	"WILL@@@@",	$92,	$0,	$0		; いたします,
	db	"AYE@@@@@",	$32,	$1,	$0		; おります@,
	db	"?!@@@@@@",	$3c,	$1,	$0		; か！？@@,
	db	"HM?@@@@@",	$44,	$1,	$0		; かい？@@,
	db	"Y'THINK?",	$50,	$1,	$0		; かしら？@,
	db	"IS IT?@@",	$6a,	$1,	$0		; かな？@@,
	db	"BE@@@@@@",	$76,	$1,	$0		; かも@@@,
	db	"GIMME@@@",	$ca,	$1,	$0		; くれ@@@,
	db	"COULD@@@",	$e8,	$1,	$0		; ございます,
	db	"TEND TO@",	$3a,	$2,	$0		; しがち@@,
	db	"WOULD@@@",	$62,	$2,	$0		; します@@,
	db	"IS@@@@@@",	$6a,	$2,	$0		; じゃ@@@,
	db	"ISNT IT?",	$6e,	$2,	$0		; じゃん@@,
	db	"LET'S@@@",	$7c,	$2,	$0		; しよう@@,
	db	"OTHER@@@",	$ac,	$2,	$0		; ぜ！@@@,
	db	"ARE@@@@@",	$bc,	$2,	$0		; ぞ！@@@,
	db	"WAS@@@@@",	$d4,	$2,	$0		; た@@@@,
	db	"WERE@@@@",	$d6,	$2,	$0		; だ@@@@,
	db	"THOSE@@@",	$ee,	$2,	$0		; だからね@,
	db	"ISN'T@@@",	$f4,	$2,	$0		; だぜ@@@,
	db	"WON'T@@@",	$fa,	$2,	$0		; だった@@,
	db	"CAN'T@@@",	$fe,	$2,	$0		; だね@@@,
	db	"CAN@@@@@",	$10,	$3,	$0		; だよ@@@,
	db	"DON'T@@@",	$12,	$3,	$0		; だよねー！,
	db	"DO@@@@@@",	$26,	$3,	$0		; だわ@@@,
	db	"DOES@@@@",	$4c,	$3,	$0		; ッス@@@,
	db	"WHOM@@@@",	$52,	$3,	$0		; ってかんじ,
	db	"WHICH@@@",	$54,	$3,	$0		; っぱなし@,
	db	"WASN'T@@",	$56,	$3,	$0		; つもり@@,
	db	"WEREN'T@",	$64,	$3,	$0		; ていない@,
	db	"HAVE@@@@",	$66,	$3,	$0		; ている@@,
	db	"HAVEN'T@",	$68,	$3,	$0		; でーす！@,
	db	"A@@@@@@@",	$74,	$3,	$0		; でした@@,
	db	"AN@@@@@@",	$76,	$3,	$0		; でしょ？@,
	db	"NOT@@@@@",	$78,	$3,	$0		; でしょー！,
	db	"THERE@@@",	$7a,	$3,	$0		; です@@@,
	db	"OK?@@@@@",	$7c,	$3,	$0		; ですか？@,
	db	"SO@@@@@@",	$80,	$3,	$0		; ですよ@@,
	db	"MAYBE@@@",	$82,	$3,	$0		; ですわ@@,
	db	"ABOUT@@@",	$a4,	$3,	$0		; どうなの？,
	db	"OVER@@@@",	$a8,	$3,	$0		; どうよ？@,
	db	"IT@@@@@@",	$aa,	$3,	$0		; とかいって,
	db	"FOR@@@@@",	$e0,	$3,	$0		; なの@@@,
	db	"ON@@@@@@",	$e2,	$3,	$0		; なのか@@,
	db	"OFF@@@@@",	$e4,	$3,	$0		; なのだ@@,
	db	"AS@@@@@@",	$e6,	$3,	$0		; なのよ@@,
	db	"TO@@@@@@",	$f2,	$3,	$0		; なんだね@,
	db	"WITH@@@@",	$f8,	$3,	$0		; なんです@,
	db	"BETTER@@",	$fa,	$3,	$0		; なんてね@,
	db	"EVER@@@@",	$12,	$4,	$0		; ね@@@@,
	db	"SINCE@@@",	$14,	$4,	$0		; ねー@@@,
	db	"OF@@@@@@",	$1c,	$4,	$0		; の@@@@,
	db	"BELONG@@",	$1e,	$4,	$0		; の？@@@,
	db	"AT@@@@@@",	$44,	$4,	$0		; ばっかり@,
	db	"IN@@@@@@",	$c2,	$4,	$0		; まーす！@,
	db	"OUT@@@@@",	$d8,	$4,	$0		; ます@@@,
	db	"TOO@@@@@",	$da,	$4,	$0		; ますわ@@,
	db	"LIKE@@@@",	$dc,	$4,	$0		; ません@@,
	db	"DID@@@@@",	$fa,	$4,	$0		; みたいな@,
	db	"WITHOUT@",	$60,	$5,	$0		; よ！@@@,
	db	"AFTER@@@",	$68,	$5,	$0		; よー@@@,
	db	"BEFORE@@",	$6c,	$5,	$0		; よーん@@,
	db	"WHILE@@@",	$78,	$5,	$0		; よね@@@,
	db	"THAN@@@@",	$a2,	$5,	$0		; るよ@@@,
	db	"ONCE@@@@",	$bc,	$5,	$0		; わけ@@@,
	db	"ANYWHERE",	$d2,	$5,	$0		; わよ！@@,

.ThisAndThat:
	db	"HIGHS@@@",	$12,	$0,	$0		; ああ@@@,
	db	"LOWS@@@@",	$3c,	$0,	$0		; あっち@@,
	db	"UM@@@@@@",	$4e,	$0,	$0		; あの@@@,
	db	"REAR@@@@",	$5c,	$0,	$0		; ありゃ@@,
	db	"THINGS@@",	$66,	$0,	$0		; あれ@@@,
	db	"THING@@@",	$68,	$0,	$0		; あれは@@,
	db	"BELOW@@@",	$6c,	$0,	$0		; あんな@@,
	db	"HIGH@@@@",	$dc,	$1,	$0		; こう@@@,
	db	"HERE@@@@",	$ec,	$1,	$0		; こっち@@,
	db	"INSIDE@@",	$f2,	$1,	$0		; この@@@,
	db	"OUTSIDE@",	$fe,	$1,	$0		; こりゃ@@,
	db	"BESIDE@@",	$0,	    $2,	$0		; これ@@@,
	db	"THIS ONE",	$2,	    $2,	$0		; これだ！@,
	db	"THIS@@@@",	$4,	    $2,	$0		; これは@@,
	db	"EVERY@@@",	$e,	    $2,	$0		; こんな@@,
	db	"SEEMS SO",	$be,	$2,	$0		; そう@@@,
	db	"DOWN@@@@",	$c0,	$2,	$0		; そっち@@,
	db	"THAT@@@@",	$c2,	$2,	$0		; その@@@,
	db	"THAT IS@",	$c6,	$2,	$0		; そりゃ@@,
	db	"THAT ONE",	$c8,	$2,	$0		; それ@@@,
	db	"THATS IT",	$cc,	$2,	$0		; それだ！@,
	db	"THAT'S..",	$d0,	$2,	$0		; それは@@,
	db	"THAT WAS",	$d2,	$2,	$0		; そんな@@,
	db	"UP@@@@@@",	$98,	$3,	$0		; どう@@@,
	db	"CHOICE@@",	$b2,	$3,	$0		; どっち@@,
	db	"FAR@@@@@",	$b4,	$3,	$0		; どの@@@,
	db	"AWAY@@@@",	$c0,	$3,	$0		; どりゃ@@,
	db	"NEAR@@@@",	$c2,	$3,	$0		; どれ@@@,
	db	"WHERE@@@",	$c8,	$3,	$0		; どれを@@,
	db	"WHEN@@@@",	$ca,	$3,	$0		; どんな@@,
	db	"WHAT@@@@",	$de,	$3,	$0		; なに@@@,
	db	"DEEP@@@@",	$ec,	$3,	$0		; なんか@@,
	db	"SHALLOW@",	$f0,	$3,	$0		; なんだ@@,
	db	"WHY@@@@@",	$f6,	$3,	$0		; なんで@@,
	db	"CONFUSED",	$0,	    $4,	$0		; なんなんだ,
	db	"OPPOSITE",	$2,	    $4,	$0		; なんの@@,
endc
MobileEZChatData_WordAndPageCounts:
macro_11f220: MACRO
; parameter: number of words
	db \1
; 12 words per page (0-based indexing)									  
x = \1 / (EZCHAT_WORD_COUNT * 2) ; 12 MENU_WIDTH to 8
if \1 % (EZCHAT_WORD_COUNT * 2) == 0 ; 12 MENU_WIDTH to 8
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
