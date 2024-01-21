EZCHAT_WORD_COUNT equ EASY_CHAT_MESSAGE_WORD_COUNT
EZCHAT_WORD_LENGTH equ 8
EZCHAT_WORDS_PER_ROW equ 2
EZCHAT_WORDS_PER_COL equ 4
EZCHAT_WORDS_IN_MENU equ EZCHAT_WORDS_PER_ROW * EZCHAT_WORDS_PER_COL
EZCHAT_PKMN_WORDS_PER_ROW equ 1
EZCHAT_PKMN_WORDS_PER_COL equ 4
EZCHAT_PKMN_WORDS_IN_MENU equ EZCHAT_PKMN_WORDS_PER_ROW * EZCHAT_PKMN_WORDS_PER_COL

	const_def
	const EZCHAT_SORTED_A
	const EZCHAT_SORTED_B
	const EZCHAT_SORTED_C
	const EZCHAT_SORTED_D
	const EZCHAT_SORTED_E
	const EZCHAT_SORTED_F
	const EZCHAT_SORTED_G
	const EZCHAT_SORTED_H
	const EZCHAT_SORTED_I
	const EZCHAT_SORTED_J
	const EZCHAT_SORTED_K
	const EZCHAT_SORTED_L
	const EZCHAT_SORTED_M
	const EZCHAT_SORTED_N
	const EZCHAT_SORTED_O
	const EZCHAT_SORTED_P
	const EZCHAT_SORTED_Q
	const EZCHAT_SORTED_R
	const EZCHAT_SORTED_S
	const EZCHAT_SORTED_T
	const EZCHAT_SORTED_U
	const EZCHAT_SORTED_V
	const EZCHAT_SORTED_W
	const EZCHAT_SORTED_X
	const EZCHAT_SORTED_Y
	const EZCHAT_SORTED_Z
	const EZCHAT_SORTED_ETC
	const EZCHAT_SORTED_PKMN
	const EZCHAT_SORTED_ERASE
	const EZCHAT_SORTED_MODE
	const EZCHAT_SORTED_CANCEL
DEF NUM_EZCHAT_SORTED EQU const_value
DEF EZCHAT_SORTED_NULL EQU $ff

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
	ld a, EZCHAT_WORDS_PER_ROW ; Determines the number of easy chat words displayed before going onto the next line
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
	ld a, EZCHAT_WORDS_PER_ROW
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
	; Preserve [wJumptableIndex], [wcf64]
	ld a, [wJumptableIndex]
	ld l, a
	ld a, [wcf64]
	ld h, a
	push hl
	; reset value at [wc618] (not preserved)
	ld hl, wc618
	ld a, $0
	ld [hli], a
	; preserve de
	push de
	; [wJumptableIndex] keeps track of which line we're on (0, 1, or 2)
	; [wcf64] keeps track of how much room we have left in the current line
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
	
	cp $ff
	jr nz, .d_not_ff
	ld a, e
	cp $ff
	jr z, .done ; de == $ffff, done

.d_not_ff
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
	; now, let's place the string from wc618 to bc
	pop bc
	ld hl, wc618
	call PlaceHLTextAtBC
	; restore the original values of [wJumptableIndex] and [wcf64]
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
	ld bc, NAME_LENGTH + 1
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
	ld [wNamedObjectIndex], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld a, 1
	ld [wEZChatPokemonNameRendered], a
	ld bc, NAME_LENGTH
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
	ld [wEZChatBlinkingMask], a
	ld [wEZChatSelection], a
	ld [wEZChatCategorySelection], a
	ld [wEZChatSortedSelection], a
	ld [wEZChatPokemonNameRendered], a
	ld [wcd35], a
	ld [wEZChatCategoryMode], a
	ld a, $ff
	ld [wEZChatSpritesMask], a
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
	ld hl, wc6d0
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
	ld a, BANK(sEZChatIntroductionMessage)
	call OpenSRAM
	ld hl, sEZChatIntroductionMessage
	pop af
; a * 4 * 2
	sla a
	sla a
	sla a
	ld c, a
	ld b, 0
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
	call InitSpriteAnimStruct
	depixel 8, 1, 2, 5

	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	ld a, $1 ; Message Menu Index (?)
	ld [hl], a

	depixel 9, 2, 2, 0
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	ld a, $3 ; Word Menu Index (?)
	ld [hl], a

	depixel 10, 16
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	ld a, $4
	ld [hl], a

	depixel 10, 4
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	ld a, $5 ; Sort By Menu Index (?)
	ld [hl], a

	depixel 10, 2
	ld a, SPRITE_ANIM_INDEX_EZCHAT_CURSOR
	call InitSpriteAnimStruct
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	ld a, $2 ; Sort By Letter Menu Index (?)
	ld [hl], a

	ld hl, wEZChatBlinkingMask
	set 1, [hl]
	set 2, [hl]
	jp EZChat_IncreaseJumptable

.InitRAM:
	ld a, $9
	ld [wcd2d], a
	ld a, $2
	ld [wcd2e], a
	ld [wcd2f], a
	ld [wcd30], a
	ld de, wcd2d
	call EZChat_Textbox
	jp EZChat_IncreaseJumptable

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
	jp EZChat_IncreaseJumptable

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
	jp EZChat_IncreaseJumptable

EZChatMenu_RerenderMessage:
; nugget of a solution
	ld de, EZChatBKG_ChatWords
	call EZChat_Textbox

EZChatMenu_MessageSetup:
	xor a
	ld [wEZChatPokemonNameRendered], a
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
	ld a, [wEZChatPokemonNameRendered]
	and a
	jr nz, .clear_rendered_flag
	ld de, EZChatString_EmptyWord
	call PlaceString
.clear_rendered_flag
	xor a
	ld [wEZChatPokemonNameRendered], a
.asm_11c3b5
	pop bc
	pop hl
	pop af
	dec a
	jr nz, .asm_11c392
	ret

EZChatString_EmptyWord: ; EZChat Unassigned Words
	db "--------@"

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
	ld hl, wEZChatSpritesMask
	res 0, [hl]
	call EZChat_IncreaseJumptable

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
	jp nz, .up
	ld a, [de]
	and D_DOWN
	jp nz, .down
	ld a, [de]
	and D_LEFT
	jp nz, .left
	ld a, [de]
	and D_RIGHT
	jp nz, .right
; manage blinkies
	ld a, [wEZChatSelection]
	cp EZCHAT_MAIN_RESET
	ld hl, wEZChatBlinkingMask
	jr nc, .blink
; no blink
	res 0, [hl]
	ret
.blink
	set 0, [hl]
	ret

.click_sound_and_quit
	call PlayClickSFX
.to_quit_prompt
	ld hl, wEZChatSpritesMask
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
	ld hl, wEZChatSpritesMask
	set 0, [hl]
	ld a, EZCHAT_DRAW_MESSAGE_TYPE_MENU
	jr .move_jumptable_index

.if_all_empty
	ld hl, wEZChatSpritesMask
	set 0, [hl]
	ld a, EZCHAT_MENU_WARN_EMPTY_MESSAGE
	jr .move_jumptable_index

.to_reset_prompt
	ld hl, wEZChatSpritesMask
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
	cp EZCHAT_MAIN_WORD3
	ret c
; if at QUIT
	cp EZCHAT_MAIN_QUIT
	jr z, .up_on_quit
; if in 2nd row and 2nd column
	cp EZCHAT_MAIN_WORD4
	jr nz, .up_normal
; to first row
	ld a, [wEZChatWord1 + 1]
	and a
	jr nz, .up_normal
; 1st word not empty
	ld a, [wEZChatWord1]
	and a
	jr z, .up_normal
; pokemon is 1st word
	ld a, EZCHAT_MAIN_WORD1
	jr .finish_dpad
.up_normal
	ld a, [hl]
	sub 2
	jr .finish_dpad
.up_on_quit
	ld a, EZCHAT_MAIN_WORD3
	jr .finish_dpad

.down
	ld a, [hl]
	cp 4
	ret nc
; if in top row	
	cp 2
	jr nc, .down_normal
; to second row
	ld a, [wEZChatWord3 + 1]
	and a
	jr nz, .down_normal
; 3rd word not empty
	ld a, [wEZChatWord3]
	and a
	jr z, .down_normal
; pokemon is 3rd word
	ld a, EZCHAT_MAIN_WORD3
	jr .finish_dpad
.down_normal
	ld a, [hl]
	add 2
	jr .finish_dpad

.left
	ld a, [hl]
	and a ; cp a, 0
	ret z
	cp 2
	ret z
	cp 4
	ret z
	dec a
	jr .finish_dpad
.right
	ld a, [hl]
; rightmost side of everything
	cp 1
	ret z
	cp 3
	ret z
	cp 6
	ret z
; prevent selection if it's a pokemon
	and a
	jr nz, .right_not_0th
; for word 0
	ld c, a
	ld a, [wEZChatWord1 + 1]
	and a
	ld a, c
	jr nz, .right_normal
; is category 0
	ld a, [wEZChatWord1]
	and a
	ret nz ; stop here if is pokemon
.right_not_0th
	cp 2
	jr nz, .right_normal
; for word 2
	ld c, a
	ld a, [wEZChatWord3 + 1]
	and a
	ld a, c
	jr nz, .right_normal
; is category 0
	ld a, [wEZChatWord3]
	and a
	ret nz ; stop here if is pokemon
	ld a, 2 ; jank
.right_normal
	inc a
.finish_dpad
	ld [hl], a
	ret

EZChat_CheckCategorySelectionConsistency:
	ld a, [wEZChatCategoryMode]
	bit 7, a
	ret z
	set 0, a
	ld [wEZChatCategoryMode], a
	ret

EZChat_MoveToCategoryOrSortMenu:
	call EZChat_CheckCategorySelectionConsistency
	ld hl, wEZChatBlinkingMask
	res 0, [hl]
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .to_sort_menu
	xor a
	ld [wEZChatCategorySelection], a
	ld a, EZCHAT_DRAW_CATEGORY_MENU ; from where this is called, it sets jumptable stuff
	ret

.to_sort_menu
	xor a
	ld [wEZChatSortedSelection], a
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
	ret

EZChatDrawBKG_ChatWords:
	ld a, $1
	hlcoord 0, 6, wAttrmap 	; Draws the pink background for 'Combine words'
	ld bc, $a0 				; Area to fill
	call ByteFill
	ld a, $7
	hlcoord 0, 14, wAttrmap ; Clears white area at bottom of menu
	ld bc, $28 				; Area to clear
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatString_ChatExplanation: ; Explanation string
	db   "Combine four words";"６つのことば¯くみあわせます"
	next "or phrases.";"かえたいところ¯えらぶと　でてくる"
	next "Select a space";"ことばのグループから　いれかえたい"
	next "and choose a word.";"たんご¯えらんでください"
	db   "@"

EZChatString_ChatExplanationBottom: ; Explanation commands string
	db "RESET　QUIT  　OK@";"ぜんぶけす　やめる　　　けってい@"

; ezchat categories defines
def EZCHAT_CATEGORIES_ROWS EQU 5
def EZCHAT_CATEGORIES_COLUMNS EQU 2
def EZCHAT_DISPLAYED_CATEGORIES EQU (EZCHAT_CATEGORIES_ROWS * EZCHAT_CATEGORIES_COLUMNS)
def EZCHAT_NUM_CATEGORIES EQU 15
def EZCHAT_NUM_EXTRA_ROWS EQU ((EZCHAT_NUM_CATEGORIES + 1 - EZCHAT_DISPLAYED_CATEGORIES) / 2)
def EZCHAT_EMPTY_VALUE EQU ((EZCHAT_NUM_EXTRA_ROWS << 5) | (EZCHAT_DISPLAYED_CATEGORIES - 1))

	const_def EZCHAT_DISPLAYED_CATEGORIES
	const EZCHAT_CATEGORY_CANC
	const EZCHAT_CATEGORY_MODE
	const EZCHAT_CATEGORY_OK

EZChatDraw_CategoryMenu: ; Open category menu
; might need no change here
	call EZChat_ClearBottom12Rows
	call EZChat_PlaceCategoryNames
	call EZChat_SortMenuBackground
	ld hl, wEZChatSpritesMask
	res 1, [hl]
	call EZChat_IncreaseJumptable

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
	jp nz, .up

	ld a, [de]
	and D_DOWN
	jp nz, .down

	ld a, [de]
	and D_LEFT
	jp nz, .left

	ld a, [de]
	and D_RIGHT
	jp nz, .right

; manage blinkies
	ld a, [hl]
	and $0f
	cp EZCHAT_CATEGORY_CANC
	ld hl, wEZChatBlinkingMask
	jr nc, .blink
; no blink
	res 1, [hl]
	ret
.blink
	set 1, [hl]
	ret

.a
	ld a, [wEZChatCategorySelection]
	and $0f
	cp EZCHAT_CATEGORY_CANC
	jr c, .got_category
	sub EZCHAT_CATEGORY_CANC
	jr z, .done
	dec a
	jr z, .mode
	jr .b

.start
	ld hl, wEZChatSpritesMask
	set 0, [hl]
	ld a, EZCHAT_MAIN_OK
	ld [wEZChatSelection], a

.b
	ld a, EZCHAT_DRAW_CHAT_WORDS
	jr .go_to_function

.select
	ld a, [wEZChatCategoryMode]
	xor (1 << 0) + (1 << 7)
	ld [wEZChatCategoryMode], a
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
	jr .go_to_function

.mode
	ld a, EZCHAT_DRAW_SORT_BY_MENU
	jr .go_to_function

.got_category
	ld a, EZCHAT_DRAW_WORD_SUBMENU

.go_to_function
	ld hl, wEZChatSpritesMask
	set 1, [hl]
	ld [wJumptableIndex], a
	call PlayClickSFX
	ret

.done
	ld a, [wEZChatSelection]
	call EZChatDraw_EraseWordsLoop
	call EZChatMenu_RerenderMessage
	call PlayClickSFX
	ret

.up
	ld a, [hl]
	cp EZCHAT_CATEGORIES_COLUMNS
	ret c
	ld e, a
	and $f0
	ld d, a
	ld a, e
	and $0f
	cp EZCHAT_CATEGORIES_COLUMNS
	jr nc, .normal_up
	ld a, e
	sub EZCHAT_CATEGORIES_COLUMNS << 4
	ld [hl], a
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .go_to_function

.normal_up
	ld a, e
	and $0f
	cp EZCHAT_CATEGORY_MODE
	jr c, .continue_normal_up
	ld a, EZCHAT_CATEGORY_CANC
.continue_normal_up
	sub EZCHAT_CATEGORIES_COLUMNS
.up_end
	or d
	jr .finish_dpad

.down
	ld a, [hl]
	cp EZCHAT_EMPTY_VALUE - EZCHAT_CATEGORIES_COLUMNS
	jr nz, .continue_down
	dec a
.continue_down
	ld e, a
	and $f0
	ld d, a
	ld a, e
	and $0f
	cp EZCHAT_CATEGORY_CANC
	ret nc
	cp EZCHAT_DISPLAYED_CATEGORIES - EZCHAT_CATEGORIES_COLUMNS
	jr c, .normal_down
	ld a, d
	cp EZCHAT_NUM_EXTRA_ROWS << 5
	jr nz, .print_down
	ld a, EZCHAT_CATEGORY_CANC
	jr .down_end
.print_down
	ld a, e
	add EZCHAT_CATEGORIES_COLUMNS << 4
	cp EZCHAT_EMPTY_VALUE
	jr nz, .continue_print_down
	dec a
.continue_print_down
	ld [hl], a
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .go_to_function

.normal_down
	add EZCHAT_CATEGORIES_COLUMNS
.down_end
	or d
	jr .finish_dpad

.left
	ld a, [hl]
	and $0f
	cp EZCHAT_CATEGORY_OK
	jr z, .left_okay
	bit 0, a
	ret z
.left_okay
	ld a, [hl]
	dec a
	jr .finish_dpad

.right
	ld a, [hl]
	cp EZCHAT_EMPTY_VALUE - 1
	ret z
	and $0f
	cp EZCHAT_CATEGORY_MODE
	jr z, .right_okay
	bit 0, a
	ret nz
	cp EZCHAT_CATEGORY_OK
	ret z
.right_okay
	ld a, [hl]
	inc a

.finish_dpad
	ld [hl], a
	ret

EZChat_FindNextCategoryName:
	; The category names are padded with "@".
	; To find the next category, the system must
	; find the first character at de that is not "@".
.find_end_loop
	ld a, [de]
	inc de
	cp "@"
	jr nz, .find_end_loop
.find_next_loop
	ld a, [de]
	inc de
	cp "@"
	jr z, .find_next_loop
	dec de
	ret

EZChat_GetSelectedCategory:
	push de
	ld e, a
	and $0f
	ld d, a
	ld a, e
	swap a
	and $0f
	add d
	pop de
	ret

EZChat_PlaceCategoryNames:
	ld de, MobileEZChatCategoryNames
	ld a, [wEZChatCategorySelection]
	swap a
	and $0f
	jr z, .setup_start
.start_loop
	push af
	call EZChat_FindNextCategoryName
	pop af
	dec a
	jr nz, .start_loop
.setup_start
	hlcoord  1,  7
	ld a, 10 / 2 ; Number of EZ Chat categories displayed
.loop
	push af
	call PlaceString
	call EZChat_FindNextCategoryName
	ld bc, 10
	add hl, bc
	call PlaceString
	call EZChat_FindNextCategoryName
	ld bc, 30
	add hl, bc
	pop af
	dec a
	jr nz, .loop
	ld de, EZChatString_Stop_Mode_Cancel
	call PlaceString
	ret

EZChat_SortMenuBackground:
	ld a, $2
	hlcoord 0, 6, wAttrmap
	ld bc, $c8
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatString_Stop_Mode_Cancel:
	db " DEL 　MODE　　QUIT@";"けす　　　　モード　　　やめる@"

EZChatDraw_WordSubmenu: ; Opens/Draws Word Submenu
	call EZChat_ClearBottom12Rows
	call EZChat_ForcePokemonSubmenu
	call EZChat_DetermineWordAndPageCounts
	ld de, EZChatBKG_WordSubmenu
	call EZChat_Textbox2
	call EZChat_WhiteOutLowerMenu
	call EZChat_RenderWordChoices
	call EZChatMenu_WordSubmenuBottom
	ld hl, wEZChatSpritesMask
	res 3, [hl]
	call EZChat_IncreaseJumptable

EZChatMenu_WordSubmenu: ; Word Submenu Controls
	ld hl, wEZChatWordSelection
	ld de, hJoypadPressed
	ld a, [de]
	and A_BUTTON
	jp nz, .a
	ld a, [de]
	and B_BUTTON
	jp nz, .b
	ld a, [de]
	and START
	jr nz, .next_page
	ld a, [de]
	and SELECT
	jr z, .check_joypad

; select
	ld a, [wEZChatPageOffset]
	and a
	ret z
	call EZChat_IsPKMNMenu
	jr nc, .prev_page_normal
	ld a, [wEZChatPageOffset]
	sub EZCHAT_PKMN_WORDS_IN_MENU
	jr .prev_page_cont
.prev_page_normal
	ld a, [wEZChatPageOffset]
	sub EZCHAT_WORDS_IN_MENU
.prev_page_cont
	jr nc, .prev_page_ok
; page 0
	xor a
.prev_page_ok
	ld [wEZChatPageOffset], a
	jr .navigate_to_page

.next_page
	call EZChat_IsPKMNMenu
	jr nc, .next_page_normal
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
	add EZCHAT_PKMN_WORDS_IN_MENU
	jr .next_page_cont
.next_page_normal
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
	add EZCHAT_WORDS_IN_MENU
.next_page_cont
	cp [hl]
	ret nc
	ld [wEZChatPageOffset], a
	ld a, [hl]
	ld b, a
	ld hl, wEZChatWordSelection
	ld a, [wEZChatPageOffset]
	add [hl]
	jr c, .asm_11c6b9
	cp b
	jr c, .navigate_to_page
.asm_11c6b9
	ld a, [wEZChatLoadedItems]
	ld hl, wEZChatPageOffset
	sub [hl]
	dec a
	ld [wEZChatWordSelection], a
.navigate_to_page
	call Function11c992
	call EZChat_RenderWordChoices
	call EZChatMenu_WordSubmenuBottom
	ret

.check_joypad
	ld de, hJoyLast
	ld a, [de]
	and D_UP
	jr nz, .up
	ld a, [de]
	and D_DOWN
	jp nz, .down
	ld a, [de]
	and D_LEFT
	jp nz, .left
	ld a, [de]
	and D_RIGHT
	jp nz, .right
	ret

.a
	call EZChat_SetOneWord
	call EZChat_VerifyWordPlacement
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wcd35], a

; autoselect "OK" if all words filled
; not when only word #4 is filled
	push af
	ld hl, wEZChatWords
	ld c, EZCHAT_WORD_COUNT
.check_word
	ld b, [hl]
	inc hl
	ld a, [hli]
	or b
	jr z, .check_done
	dec c
	jr nz, .check_word
	ld a, $6 ; OK
	ld [wEZChatSelection], a
.check_done
	pop af
	jr .jump_to_index

.b
	call EZChat_CheckCategorySelectionConsistency
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .to_sorted_menu
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .jump_to_index

.to_sorted_menu
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
.jump_to_index
	ld [wJumptableIndex], a
	ld hl, wEZChatSpritesMask
	set 3, [hl]
	call PlayClickSFX
	ret

.up
	call EZChat_IsPKMNMenu
	jr c, .up_in_pkmn_menu
	ld a, [hl]
	cp EZCHAT_WORDS_PER_ROW
	jr c, .move_menu_up
	sub EZCHAT_WORDS_PER_ROW
	jp .finish_dpad

.up_in_pkmn_menu
	ld a, [hl]
	cp EZCHAT_PKMN_WORDS_PER_ROW
	jr c, .move_pkmn_menu_up
	sub EZCHAT_PKMN_WORDS_PER_ROW
	jp .finish_dpad

.move_menu_up
	ld a, [wEZChatPageOffset]
	sub EZCHAT_WORDS_PER_ROW
	ret c
	ld [wEZChatPageOffset], a
	jp .navigate_to_page

.move_pkmn_menu_up
	ld a, [wEZChatPageOffset]
	sub EZCHAT_PKMN_WORDS_PER_ROW
	ret c
	ld [wEZChatPageOffset], a
	jp .navigate_to_page

.move_menu_down
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
	add EZCHAT_WORDS_IN_MENU
	ret c
	cp [hl]
	ret nc
	ld a, [wEZChatPageOffset]
	add EZCHAT_WORDS_PER_ROW
	ld [wEZChatPageOffset], a
	jp .navigate_to_page

.move_pkmn_menu_down
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
	add EZCHAT_PKMN_WORDS_IN_MENU
	ret c
	cp [hl]
	ret nc
	ld a, [wEZChatPageOffset]
	add EZCHAT_PKMN_WORDS_PER_ROW
	ld [wEZChatPageOffset], a
	jp .navigate_to_page

.down
	call EZChat_IsPKMNMenu
	jr c, .down_in_pkmn_menu
	ld a, [wEZChatLoadedItems]
	ld b, a
	ld a, [wEZChatPageOffset]
	add [hl]
	add EZCHAT_WORDS_PER_ROW
	cp b
	ret nc
	ld a, [hl]
	cp EZCHAT_WORDS_IN_MENU - EZCHAT_WORDS_PER_ROW
	jr nc, .move_menu_down
	add EZCHAT_WORDS_PER_ROW
	jr .finish_dpad

.down_in_pkmn_menu
	ld a, [wEZChatLoadedItems]
	ld b, a
	ld a, [wEZChatPageOffset]
	add [hl]
	add EZCHAT_PKMN_WORDS_PER_ROW
	cp b
	ret nc
	ld a, [hl]
	cp EZCHAT_PKMN_WORDS_IN_MENU - EZCHAT_PKMN_WORDS_PER_ROW
	jr nc, .move_pkmn_menu_down
	add EZCHAT_PKMN_WORDS_PER_ROW
	jr .finish_dpad

.left
	call EZChat_IsPKMNMenu
	ret c
	ld a, [hl]
	and a ; cp a, 0
	ret z
DEF x = EZCHAT_WORDS_PER_ROW
rept EZCHAT_WORDS_PER_COL - 1
	cp x
	ret z
	DEF x = x + EZCHAT_WORDS_PER_ROW
endr
	dec a
	jr .finish_dpad

.right
	call EZChat_IsPKMNMenu
	ret c
	ld a, [wEZChatLoadedItems]
	ld b, a
	ld a, [wEZChatPageOffset]
	add [hl]
	inc a
	cp b
	ret nc
	ld a, [hl]
DEF x = EZCHAT_WORDS_PER_ROW
rept EZCHAT_WORDS_PER_COL
	cp x - 1
	ret z
	DEF x = x + EZCHAT_WORDS_PER_ROW
endr
	inc a

.finish_dpad
	ld [hl], a
	ret
	
EZChat_IsPKMNMenu:
	or a
	ld a, [wEZChatCategoryMode]
	bit 0, a
	ret nz
	ld a, [wEZChatCategorySelection]
	and a
	ret nz
	scf ; this is the pkmn menu
	ret
	

EZChat_DetermineWordAndPageCounts:
	xor a
	ld [wEZChatWordSelection], a
	ld [wEZChatPageOffset], a
	ld [wcd27], a
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .is_sorted_mode
	ld a, [wEZChatCategorySelection]
	and a
	jr z, .is_pokemon_selection
	; load from data array
	call EZChat_GetSelectedCategory
	dec a
	sla a
	ld hl, MobileEZChatData_WordAndPageCounts
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld [wEZChatLoadedItems], a
	ld a, [hl]
.load
	ld [wcd29], a
	ret

.is_pokemon_selection
	; compute from [wc7d2]
	ld a, [wc7d2]
	ld [wEZChatLoadedItems], a
.div_12
	ld c, EZCHAT_PKMN_WORDS_IN_MENU
	call SimpleDivide
	and a
	jr nz, .no_need_to_floor
	dec b
.no_need_to_floor
	ld a, b
	jr .load

.is_sorted_mode
	; compute from [c6a8 + 2 * [cd22]]
	ld hl, wc6a8 ; $c68a + 30
	ld a, [wEZChatSortedSelection]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hl]
	ld [wEZChatLoadedItems], a
	jr .div_12

EZChat_ForcePokemonSubmenu:
	ld a, [wEZChatCategoryMode]
	bit 0, a
	ret z
	ld a, [wEZChatSortedSelection]
	cp EZCHAT_SORTED_PKMN
	ret nz
	ld a, [wEZChatCategoryMode]
	res 0, a
	ld [wEZChatCategoryMode], a
	xor a
	ld [wEZChatCategorySelection], a
	ret
	
EZChat_RenderWordChoices:
	ld bc, EZChatCoord_WordSubmenu
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .is_sorted
; grouped
	ld a, [wEZChatCategorySelection]
	and a
	jr nz, .not_pkmn_submenu
	ld bc, EZChatCoord_PkmnWordSubmenu
.not_pkmn_submenu
	call EZChat_GetSelectedCategory
	ld d, a
	and a
	jr z, .at_page_0
	ld a, [wEZChatPageOffset]
	ld e, a
.loop
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	and l
	cp -1
	ret z
	push bc
	push de
	call EZChat_RenderOneWord
	pop de
	pop bc
	inc e
	ld a, [wEZChatLoadedItems]
	cp e
	jr nz, .loop
	ret

.at_page_0
	ld hl, wListPointer
	ld a, [wEZChatPageOffset]
	ld e, a
	add hl, de
.loop2
	push de
	ld a, [hli]
	ld e, a
	ld d, 0
	push hl
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	and l
	cp -1
	jr z, .page_0_done
	push bc
	call EZChat_RenderOneWord
	pop bc
	pop hl
	pop de
	inc e
	ld a, [wEZChatLoadedItems]
	cp e
	jr nz, .loop2
	ret

.page_0_done
	pop hl
	pop de
	ret

.is_sorted
	ld hl, wEZChatSortedWordPointers
	ld a, [wEZChatSortedSelection]
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
; got word
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
; de -> hl
	push de
	pop hl
	ld a, [wEZChatPageOffset]
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	ld a, [wEZChatPageOffset]
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
	ld a, [wEZChatLoadedItems]
	cp e
	jr nz, .asm_11c831
	ret

.asm_11c851
	pop hl
	pop de
	ret

EZChatCoord_WordSubmenu: ; Word coordinates (within category submenu)
	dwcoord  2,  8
	dwcoord  11,  8 ; 8, 8 MENU_WIDTH
	dwcoord  2, 10
	dwcoord  11, 10 ; 8, 10 MENU_WIDTH
	dwcoord  2, 12
	dwcoord  11, 12 ; 8, 12 MENU_WIDTH
	dwcoord  2, 14
	dwcoord  11, 14 ; 8, 14 MENU_WIDTH
	dw -1

EZChatCoord_PkmnWordSubmenu:
	dwcoord  2,  8
	dwcoord  2, 10
	dwcoord  2, 12
	dwcoord  2, 14
	dw -1

EZChatMenu_WordSubmenuBottom: ; Seems to handle the bottom of the word menu.
	ld a, [wEZChatPageOffset]
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
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
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

EZChat_VerifyWordPlacement:
; make sure that if one row contains a mon name
; that row only contain the pokemon name
	push hl
	push bc
; fix selection placement
	ld a, [wEZChatSelection]
	cp 1
	jr z, .one
	cp 3
	jr z, .three
	jr .limit_words ; out of range
.one
; is current word a pokemon?
	ld hl, wEZChatWord2 + 1
	ld a, [hld]
	and a
	jr nz, .limit_words
	ld a, [hl]
	jr nz, .limit_words
; change selection
	ld a, 0
	ld [wEZChatSelection], a
	jr .limit_words
.three
; is current word a pokemon?
	ld hl, wEZChatWord4 + 1
	ld a, [hld]
	and a
	jr nz, .limit_words
	ld a, [hl]
	jr nz, .limit_words
; change selection
	ld a, 2
	ld [wEZChatSelection], a
	; jr .limit_words
.limit_words
; row 1
	ld hl, wEZChatWord1
	ld bc, 0
.loop
	call .iterate
	ld b, 0
	ld a, c
	cp EZCHAT_WORD_COUNT
	jr nc, .done
	jr .loop
.done
; rerender words
	call EZChatMenu_RerenderMessage
	
	pop bc
	pop hl
	ret

.iterate
	ld a, [hli]
	ld b, a
	ld a, [hli]
	and a
	jr nz, .skip_iteration ; skip if category != 0
	or b
	jr z, .skip_iteration ; skip if category||index == 0000
	ld a, b
	and a
	jr z, .skip_iteration ; skip if index == 0
; is pokemon
	ld a, c
	and $1
	jr z, .even_index
; odd index
	dec hl
	dec hl
	ld a, [hl]
	dec hl
	dec hl
	ld [hli], a
	ld [hl], 0
	inc hl
	ld [hl], 0
	inc hl
	ld [hl], 0
	inc hl
	;inc c
	jr .skip_iteration
.even_index
	ld [hl], 0
	inc hl
	ld [hl], 0
	inc hl
	inc c
	jr .skip_iteration
.skip_iteration
	inc c
	ret

EZChat_SetOneWord:
; clear the word that it's occupying
	ld a, [wEZChatSelection]
	call EZChat_ClearOneWord
; get which category mode
	push hl
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .alphabetical
; categorical
	ld a, [wEZChatCategorySelection]
	call EZChat_GetSelectedCategory
	ld d, a
	and a
	jr z, .pokemon
	ld hl, wEZChatPageOffset
	ld a, [wEZChatWordSelection]
	add [hl]
.got_word_entry
	ld e, a
.put_word
	pop hl
	push de
	call EZChat_RenderOneWord
	pop de
	ld a, [wEZChatSelection]
	ld c, a
	ld b, 0
	ld hl, wEZChatWords
	add hl, bc
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
; finished
	ret

.pokemon
	ld hl, wEZChatPageOffset
	ld a, [wEZChatWordSelection]
	add [hl]
	ld c, a
	ld b, 0
	ld hl, wListPointer
	add hl, bc
	ld a, [hl]
	jr .got_word_entry

.alphabetical
	ld hl, wEZChatSortedWordPointers
	ld a, [wEZChatSortedSelection]
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	pop hl
	ld a, [wEZChatPageOffset]
	ld e, a
	ld d, 0
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
	jr .put_word

EZChat_ClearOneWord:
; a = idx of which word
; get starting coordinate to clear out
	sla a
	ld c, a
	ld b, 0
	ld hl, EZChatCoord_ChatWords
	add hl, bc
; coord -> bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	push bc
; bc -> hl
		push bc
		pop hl
		ld c, EZCHAT_WORD_LENGTH
		ld a, " "
.clear_word
		ld [hli], a
		dec c
		jr nz, .clear_word
; clear the row above it
		dec hl
		ld bc, -SCREEN_WIDTH
		add hl, bc
		ld c, EZCHAT_WORD_LENGTH
		ld a, " "
.clear_row_above
		ld [hld], a
		dec c
		jr nz, .clear_row_above
	pop hl
	ret

EZChatCoord_ChatWords: ; EZChat Message Coordinates
	dwcoord  2,  2
	dwcoord 11,  2 ;  7, 2
	;dwcoord  7,  7 ; 13, 2 (Pushed under 'Combine 4 words' menu) WORD_COUNT
	dwcoord  2,  4
	dwcoord 11,  4 ;  7, 4
	;dwcoord 12, 12 ; 13, 4 (Pushed under 'Combine 4 words' menu) WORD_COUNT

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
	hlcoord 0, 6, wAttrmap
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
	ld hl, wEZChatSpritesMask
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
	hlcoord 14, 7, wAttrmap
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
	hlcoord 0, 12, wAttrmap
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
	db   "All words will";"とうろくちゅう<NO>あいさつ¯ぜんぶ"
	next "be erased. OK?@";"けしても　よろしいですか？@"

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
	cp EZCHAT_WORD_COUNT
	jr nz, .loop
	call EZChatMenu_RerenderMessage
	ret

EZChatDraw_EraseWordsLoop:
	ld hl, wEZChatWords
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld [hl], b
	inc hl
	ld [hl], b
	call EZChat_ClearOneWord
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
	ld hl, wEZChatSpritesMask
	res 4, [hl]
	call EZChat_IncreaseJumptable
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
	ld hl, wEZChatSpritesMask
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
	next "setting a message?@";"しますか？@"

EZChatString_ExitConfirmation: ; Exit menu confirmation string
	db   "Quit without";"とうろくちゅう<NO>あいさつ<WA>ほぞん"
	next "saving a message?@";"されません<GA>よろしい　ですか？@"

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
	ld a, BANK(sEZChatIntroductionMessage)
	call OpenSRAM
	ld hl, sEZChatIntroductionMessage
	ld a, [wMenuCursorY]
	dec a
	sla a
	sla a
	sla a
	ld c, a
	ld b, 0
	add hl, bc
	ld de, wEZChatWords
	ld c, EZCHAT_WORD_COUNT * 2
.save_message
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .save_message
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
	call EZChatMenu_RerenderMessage
	ld hl, wEZChatSpritesMask
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
	db   "Shown as an";"じこしょうかい　は"
	next "introduction. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleStartDescription:
	db   "Shown when a";"たいせん　<GA>はじまるとき　は"
	next "battle starts. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleWinDescription:
	db   "Shown if you";"たいせん　<NI>かったとき　は"
	next "win a battle. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageBattleLoseDescription:
	db   "Shown if you";"たいせん　<NI>まけたとき　は"
	next "lose a battle. OK?@";"この　あいさつで　いいですか？@"

EZChatString_MessageSet: ; message accept strings, one for each type of message.
	dw EZChatString_MessageIntroSet
	dw EZChatString_MessageBattleStartSet
	dw EZChatString_MessageBattleWinSet
	dw EZChatString_MessageBattleLoseSet

EZChatString_MessageIntroSet:
	db   "Introduction"		;"じこしょうかい　の"
	next "greeting set!@"	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleStartSet:
	db   "Begin battle"		;"たいせん　<GA>はじまるとき　の"
	next "greeting set!@"	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleWinSet:
	db   "Win battle"		;"たいせん　<NI>かったとき　の"
	next "greeting set!@"	;next "あいさつ¯とうろくした！@"

EZChatString_MessageBattleLoseSet:
	db   "Lose battle"		;"たいせん　<NI>まけたとき　の"
	next "greeting set!@"	;next "あいさつ¯とうろくした！@"

EZChatMenu_WarnEmptyMessage:
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	hlcoord 1, 14
	ld de, EZChatString_EnterSomeWords
	call PlaceString
	call Function11ca19
	call EZChat_IncreaseJumptable

Function11cd04:
	ld de, hJoypadPressed
	ld a, [de]
	and a
	ret z
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wJumptableIndex], a
	ret

EZChatString_EnterSomeWords:
	db 	 "Please enter a";"なにか　ことば¯いれてください@"
	next "phrase or word.@"

EZChatDraw_SortByMenu: ; Draws/Opens Sort By Menu
	call EZChat_ClearBottom12Rows
	ld de, EZChatBKG_SortBy
	call EZChat_Textbox
	hlcoord 1, 14
	ld a, [wEZChatCategoryMode]
	ld [wcd2c], a
	bit 0, a
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
	ld hl, wEZChatSpritesMask
	res 5, [hl]
	call EZChat_IncreaseJumptable

EZChatMenu_SortByMenu: ; Sort Menu Controls
	ld hl, wcd2c
	res 7, [hl]
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
	bit 0, a
	jr z, .a_skip_setting_7
	set 7, a
	jr .a_ok
.a_skip_setting_7
	res 7, a
.a_ok
	ld [wEZChatCategoryMode], a
.b
	ld a, [wEZChatCategoryMode]
	bit 0, a
	jr nz, .asm_11cd7d
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .jump_to_index

.asm_11cd7d
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
.jump_to_index
	ld [wJumptableIndex], a
	ld hl, wEZChatSpritesMask
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
	hlcoord 0, 6, wAttrmap
	ld bc, 6 * SCREEN_WIDTH
	call ByteFill
	ld a, $7
	hlcoord 0, 12, wAttrmap
	ld bc, 4 * SCREEN_WIDTH
	call ByteFill
	farcall ReloadMapPart
	ret

EZChatString_SortByCategory:
; Words will be displayed by category
	db   "Words are listed";"ことば¯しゅるいべつに"
	next "by category.@";"えらべます@"

EZChatString_SortByAlphabetical:
; Words will be displayed in alphabetical order
	db   "Words are listed";"ことば¯アイウエオ　の"
	next "alphabetically.@";"じゅんばんで　ひょうじ　します@"

EZChatString_SortByMenu:
	db   "GROUP MODE";"しゅるいべつ　モード"  ; Category mode
	next "A to Z MODE@";"アイウエオ　　モード@" ; ABC mode

EZChatDraw_SortByCharacter: ; Sort by Character Menu
	call EZChat_ClearBottom12Rows
	hlcoord 1, 7
	ld de, EZChatScript_SortByCharacterTable
	call PlaceString
	hlcoord 1, 17
	ld de, EZChatString_Stop_Mode_Cancel
	call PlaceString
	call EZChat_SortMenuBackground
	ld hl, wEZChatSpritesMask
	res 2, [hl]
	call EZChat_IncreaseJumptable

EZChatMenu_SortByCharacter: ; Sort By Character Menu Controls
	ld a, [wEZChatSortedSelection] ; x 4
	sla a
	sla a
	ld c, a
	ld b, 0
	ld hl, .NeighboringCharacters
	add hl, bc

; got character
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
	
;.invalid ; Removed to be more in line with Gen 3
;	ld de, SFX_WRONG
;	call PlaySFX
;	jp WaitSFX

.a
	ld a, [wEZChatSortedSelection]
; exit early on "no words begin with this letter" - sort count 0
	cp EZCHAT_SORTED_X
;	jr z, .invalid ; Removed to be more in line with Gen 3
	ret z
	cp EZCHAT_SORTED_Z
;	jr z, .invalid ; Removed to be more in line with Gen 3
	ret z
; otherwise
	cp EZCHAT_SORTED_ERASE
	jr c, .place
	sub EZCHAT_SORTED_ERASE
	jr z, .done
	dec a
	jr z, .mode
	jr .b ; cancel

.start
	ld hl, wEZChatSpritesMask
	set 0, [hl]
	ld a, EZCHAT_MAIN_OK
	ld [wEZChatSelection], a
.b
	ld a, EZCHAT_DRAW_CHAT_WORDS
	jr .load

.select
	ld a, [wEZChatCategoryMode]
	xor (1 << 0) + (1 << 7)
	ld [wEZChatCategoryMode], a
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .load

.place
	ld a, EZCHAT_DRAW_WORD_SUBMENU
	jr .load

.mode
	ld a, EZCHAT_DRAW_SORT_BY_MENU
.load
	ld [wJumptableIndex], a
	ld hl, wEZChatSpritesMask
	set 2, [hl]
	call PlayClickSFX
	ret

.done
	ld a, [wEZChatSelection]
	call EZChatDraw_EraseWordsLoop
	call EZChatMenu_RerenderMessage
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
	cp EZCHAT_SORTED_NULL
	ret z
	ld [wEZChatSortedSelection], a
	ret

.NeighboringCharacters: ; Sort Menu Letter tile values or coordinates?
	table_width 4, .NeighboringCharacters
; A
	;  Up                  Right               Down                  Left
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_B,      EZCHAT_SORTED_J,      EZCHAT_SORTED_NULL
; B
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_C,      EZCHAT_SORTED_K,      EZCHAT_SORTED_A
; C
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_D,      EZCHAT_SORTED_L,      EZCHAT_SORTED_B
; D
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_E,      EZCHAT_SORTED_M,      EZCHAT_SORTED_C
; E
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_F,      EZCHAT_SORTED_N,      EZCHAT_SORTED_D
; F
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_G,      EZCHAT_SORTED_O,      EZCHAT_SORTED_E
; G
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_H,      EZCHAT_SORTED_P,      EZCHAT_SORTED_F
; H
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_I,      EZCHAT_SORTED_Q,      EZCHAT_SORTED_G
; I
	db EZCHAT_SORTED_NULL, EZCHAT_SORTED_NULL,   EZCHAT_SORTED_R,      EZCHAT_SORTED_H
; J
	db EZCHAT_SORTED_A,    EZCHAT_SORTED_K,      EZCHAT_SORTED_S,      EZCHAT_SORTED_NULL
; K
	db EZCHAT_SORTED_B,    EZCHAT_SORTED_L,      EZCHAT_SORTED_T,      EZCHAT_SORTED_J
; L
	db EZCHAT_SORTED_C,    EZCHAT_SORTED_M,      EZCHAT_SORTED_U,      EZCHAT_SORTED_K
; M
	db EZCHAT_SORTED_D,    EZCHAT_SORTED_N,      EZCHAT_SORTED_V,      EZCHAT_SORTED_L
; N
	db EZCHAT_SORTED_E,    EZCHAT_SORTED_O,      EZCHAT_SORTED_W,      EZCHAT_SORTED_M
; O
	db EZCHAT_SORTED_F,    EZCHAT_SORTED_P,      EZCHAT_SORTED_X,      EZCHAT_SORTED_N
; P
	db EZCHAT_SORTED_G,    EZCHAT_SORTED_Q,      EZCHAT_SORTED_Y,      EZCHAT_SORTED_O
; Q
	db EZCHAT_SORTED_H,    EZCHAT_SORTED_R,      EZCHAT_SORTED_Z,      EZCHAT_SORTED_P
; R
	db EZCHAT_SORTED_I,    EZCHAT_SORTED_NULL,   EZCHAT_SORTED_CANCEL, EZCHAT_SORTED_Q
; S
	db EZCHAT_SORTED_J,    EZCHAT_SORTED_T,      EZCHAT_SORTED_ETC,    EZCHAT_SORTED_NULL
; T
	db EZCHAT_SORTED_K,    EZCHAT_SORTED_U,      EZCHAT_SORTED_ETC,    EZCHAT_SORTED_S
; U
	db EZCHAT_SORTED_L,    EZCHAT_SORTED_V,      EZCHAT_SORTED_PKMN,   EZCHAT_SORTED_T
; V
	db EZCHAT_SORTED_M,    EZCHAT_SORTED_W,      EZCHAT_SORTED_MODE,   EZCHAT_SORTED_U
; W
	db EZCHAT_SORTED_N,    EZCHAT_SORTED_X,      EZCHAT_SORTED_MODE,   EZCHAT_SORTED_V
; X
	db EZCHAT_SORTED_O,    EZCHAT_SORTED_Y,      EZCHAT_SORTED_CANCEL, EZCHAT_SORTED_W
; Y
	db EZCHAT_SORTED_P,    EZCHAT_SORTED_Z,      EZCHAT_SORTED_CANCEL, EZCHAT_SORTED_X
; Z
	db EZCHAT_SORTED_Q,    EZCHAT_SORTED_NULL,   EZCHAT_SORTED_CANCEL, EZCHAT_SORTED_Y
; ETC.
	db EZCHAT_SORTED_S,    EZCHAT_SORTED_PKMN,   EZCHAT_SORTED_ERASE,  EZCHAT_SORTED_NULL
; PKMN
	db EZCHAT_SORTED_U,    EZCHAT_SORTED_NULL,   EZCHAT_SORTED_MODE,   EZCHAT_SORTED_ETC
; ERASE
	db EZCHAT_SORTED_ETC,  EZCHAT_SORTED_MODE,   EZCHAT_SORTED_NULL,   EZCHAT_SORTED_NULL
; MODE
	db EZCHAT_SORTED_PKMN, EZCHAT_SORTED_CANCEL, EZCHAT_SORTED_NULL,   EZCHAT_SORTED_ERASE
; CANCEL
	db EZCHAT_SORTED_X,    EZCHAT_SORTED_NULL,   EZCHAT_SORTED_NULL,   EZCHAT_SORTED_MODE
	assert_table_length NUM_EZCHAT_SORTED

EZChatScript_SortByCharacterTable:
	db   "A B C D E F G H I"
	next "J K L M N O P Q R"
	next "S T U V W X Y Z"
	next "!? <PK><MN>"
	db   "@"

EZChat_IncreaseJumptable:
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
	ld b, 0
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
	ld b, 0
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
	ld hl, SPRITEANIMSTRUCT_VAR1
	add hl, bc
	jumptable .Jumptable, hl

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

.is_pkmn
	or a ; reset carry
	push bc
	push hl
		ld c, a
		ld b, 0
		ld hl, wEZChatWords
		add hl, bc
		add hl, bc
		ld a, [hli]
		ld b, a
		ld a, [hl]
		or b
		jr z, .chk_pkmn_ok ; == 0
		ld a, [hl]
		and a
		jr nz, .chk_pkmn_ok ; != 0
		scf
.chk_pkmn_ok
	pop hl
	pop bc
	ret

.zero ; EZChat Message Menu
; reinit sprite
	ld a, [wEZChatSelection]
	cp EZCHAT_MAIN_RESET
	jr nc, .shorter_cursor
	call .is_pkmn
	jr nc, .normal
; is pokemon
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
	call ReinitSpriteAnimFrame
	jr .cont0
.normal
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
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
	and $0f
	cp EZCHAT_CATEGORY_CANC
	push af
	jr c, .not_menu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1
	call ReinitSpriteAnimFrame
	jr .got_sprite
.not_menu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2
	call ReinitSpriteAnimFrame
.got_sprite
	pop af
	sla a
	ld hl, .Coords_One
	ld e, $2 ; Sort by Letter Menu Index (?)
	jr .load

.two ; Sort By Letter Menu
	ld hl, .FramesetsIDs_Two
	ld a, [wEZChatSortedSelection]
	ld e, a
	ld d, $0 ; Message Menu Index (?)
	add hl, de
	ld a, [hl]
	call ReinitSpriteAnimFrame

	ld a, [wEZChatSortedSelection]
	sla a
	ld hl, .Coords_Two
	ld e, $4 ; Yes/No Menu Index (?)
	jr .load

.three ; Words Submenu
	ld a, SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_2 ; $27
	call ReinitSpriteAnimFrame
	call EZChat_IsPKMNMenu
	jr nc, .three_normal
	ld a, [wEZChatWordSelection]
	sla a
	ld hl, .Coords_Six
	jr .three_cont
.three_normal
	ld a, [wEZChatWordSelection]
	sla a
	ld hl, .Coords_Three
.three_cont
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
	dbpixel  1,  3, 8, 8 ; Message 1 - 00
	dbpixel 10,  3, 8, 8 ; Message 2 - 01
	dbpixel  1,  5, 8, 8 ; Message 3 - 02
	dbpixel 10,  5, 8, 8 ; Message 4 - 03
	dbpixel  1, 17, 5, 2 ; RESET     - 04
	dbpixel  7, 17, 5, 2 ; QUIT      - 05
	dbpixel 13, 17, 5, 2 ; OK        - 06

.Coords_One: ; Category Menu
	dbpixel  0,  8, 8, 8 ; Category 1
	dbpixel 10,  8, 8, 8 ; Category 2
	dbpixel  0, 10, 8, 8 ; Category 3
	dbpixel 10, 10, 8, 8 ; Category 4
	dbpixel  0, 12, 8, 8 ; Category 5
	dbpixel 10, 12, 8, 8 ; Category 6
	dbpixel  0, 14, 8, 8 ; Category 7
	dbpixel 10, 14, 8, 8 ; Category 8
	dbpixel  0, 16, 8, 8 ; Category 9
	dbpixel 10, 16, 8, 8 ; Category 10
	dbpixel  1, 18, 5, 2 ; DEL
	dbpixel  7, 18, 5, 2 ; MODE
	dbpixel 13, 18, 5, 2 ; QUIT

.Coords_Two: ; Sort By Letter Menu
	table_width 2, .Coords_Two
	dbpixel  2,  9 ; A
	dbpixel  4,  9 ; B
	dbpixel  6,  9 ; C
	dbpixel  8,  9 ; D
	dbpixel 10,  9 ; E
	dbpixel 12,  9 ; F
	dbpixel 14,  9 ; G
	dbpixel 16,  9 ; H
	dbpixel 18,  9 ; I
	dbpixel  2, 11 ; J
	dbpixel  4, 11 ; K
	dbpixel  6, 11 ; L
	dbpixel  8, 11 ; M
	dbpixel 10, 11 ; N
	dbpixel 12, 11 ; O
	dbpixel 14, 11 ; P
	dbpixel 16, 11 ; Q
	dbpixel 18, 11 ; R
	dbpixel  2, 13 ; S
	dbpixel  4, 13 ; T
	dbpixel  6, 13 ; U
	dbpixel  8, 13 ; V
	dbpixel 10, 13 ; W
	dbpixel 12, 13 ; X
	dbpixel 14, 13 ; Y
	dbpixel 16, 13 ; Z
	dbpixel  2, 15 ; ETC.
	dbpixel  5, 15 ; PKMN
	dbpixel  1, 18, 5, 2 ; ERASE
	dbpixel  7, 18, 5, 2 ; MODE
	dbpixel 13, 18, 5, 2 ; CANCEL
	assert_table_length NUM_EZCHAT_SORTED

.Coords_Three: ; Words Submenu Arrow Positions
	dbpixel  2, 10
	dbpixel  11, 10 ; 8, 10 MENU_WIDTH
	dbpixel  2, 12
	dbpixel  11, 12 ; 8, 12 MENU_WIDTH
	dbpixel  2, 14
	dbpixel  11, 14 ; 8, 14 MENU_WIDTH
	dbpixel  2, 16
	dbpixel  11, 16 ; 8, 16 MENU_WIDTH

.Coords_Four: ; Yes/No Box
	dbpixel 16, 10 ; YES
	dbpixel 16, 12 ; NO

.Coords_Five: ; Sort By Menu
	dbpixel  4, 10 ; Group Mode
	dbpixel  4, 12 ; ABC Mode

.Coords_Six
	dbpixel  2, 10
	dbpixel  2, 12
	dbpixel  2, 14
	dbpixel  2, 16

.FramesetsIDs_Two:
	table_width 1, .FramesetsIDs_Two
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
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_4 ; 1a (Misc selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_4 ; 1b (Pkmn selection box for the sort by menu)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 1c (Bottom Menu Selection box?)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 1d (Bottom Menu Selection box?)
	db SPRITE_ANIM_FRAMESET_EZCHAT_CURSOR_1 ; 1e (Bottom Menu Selection box?)
	assert_table_length NUM_EZCHAT_SORTED

.UpdateObjectFlags:
	ld hl, wEZChatSpritesMask
	and [hl]
	jr nz, .update_y_offset
	ld a, e
	ld hl, wEZChatBlinkingMask
	and [hl]
	jr z, .reset_y_offset
	ld hl, SPRITEANIMSTRUCT_VAR3
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
; final placement of words in the sorted category, stored in 5:D800
	ldh a, [rSVBK]
	push af
	ld hl, wEZChatSortedWordPointers
	ld a, LOW(wEZChatSortedWords)
	ld [wcd2d], a
	ld [hli], a
	ld a, HIGH(wEZChatSortedWords)
	ld [wcd2e], a
	ld [hl], a

	;ld a, LOW(EZChat_SortedPokemon)
	;ld [wcd2f], a
	;ld a, HIGH(EZChat_SortedPokemon)
	;ld [wcd30], a

	ld a, LOW(wc6a8)
	ld [wcd31], a
	ld a, HIGH(wc6a8)
	ld [wcd32], a

	ld a, LOW(wc64a)
	ld [wcd33], a
	ld a, HIGH(wc64a)
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

; bc == 0?
	;ld a, b
	and a
	jr c, .continue
	jr nz, .continue
	ld a, c
	and a
	jr z, .save_without_copy

.continue
; save the pointer to the next row
	push hl
; add de to w3_d000
	ld hl, w3_d000
	add hl, de
; recover de from wcd2d (default: wEZChatSortedWords)
	ld a, [wcd2d]
	ld e, a
	ld a, [wcd2e]
	ld d, a
; save bc for later
	push bc
	jr .loop1

.save_without_copy
; save the pointer to the next row
	push hl
; add de to w3_d000
	ld hl, w3_d000
	add hl, de
; recover de from wcd2d (default: wEZChatSortedWords)
	ld a, [wcd2d]
	ld e, a
	ld a, [wcd2e]
	ld d, a
	push bc
	jr .done_copying

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

.done_copying
; recover the pointer from wcd2f (default: EZChat_SortedPokemon)
	;ld a, [wcd2f]
	;ld l, a
	;ld a, [wcd30]
	;ld h, a
; copy the pointer from [hl] to bc
	;ld a, [hli]
	;ld c, a
	;ld a, [hli]
	;ld b, a
; store the pointer to the next pointer back in wcd2f
	;ld a, l
	;ld [wcd2f], a
	;ld a, h
	;ld [wcd30], a
; push pop that pointer to hl
	;push bc
	;pop hl
	;ld c, $0
.loop2
; Have you seen this Pokemon?
	;ld a, [hl]
	;cp $ff
	;jr z, .done
	;call .CheckSeenMon
	;jr nz, .next
; If not, skip it.
	;inc hl
	;jr .loop2

.next
; If so, append it to the list at 5:de, and increase the count.
	;ld a, [hli]
	;ld [de], a
	;inc de
	;xor a
	;ld [de], a
	;inc de
	;inc c
	;jr .loop2

.done
; Remember the original value of bc from the table?
; Well, the stack remembers it, and it's popping it to hl.
	pop hl
; Add the number of seen Pokemon from the list.
;	ld b, $0
;	add hl, bc
; Push pop to bc.
	push hl
	pop bc
; Load the pointer from [wcd31] (default: wc6a8)
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
; Recover the pointer from [wcd33] (default: wc64a)
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
; initial sort of words, stored in 3:D000
	ldh a, [rSVBK]
	push af
	ld a, BANK(w3_d000)
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
	ld a, 14 ; number of categories
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

	; load word placement offset from [hl] -> de
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
INCBIN "gfx/mobile/select_start.2bpp"

EZChatSlowpokeLZ:
INCBIN "gfx/pokedex/slowpoke_mobile.2bpp.lz"

MobileEZChatCategoryNames:
; Fixed message categories
	db "POKéMON@" 	; 00 ; Pokemon 		; "ポケモン@@" ; this could've also been rendered as <PK><MN> but it looks odd
	db "TYPES@" 	; 01 ; Types		; "タイプ@@@"
	db "GREETINGS@" 	; 02 ; Greetings	; "あいさつ@@"
	db "PEOPLE@" 	; 03 ; People		; "ひと@@@@"
	db "BATTLE@" 	; 04 ; Battle		; "バトル@@@"
	db "VOICES@" 	; 05 ; Voices		; "こえ@@@@"
	db "SPEECH@" 	; 06 ; Speech		; "かいわ@@@"
	db "FEELINGS@" 	; 07 ; Feelings		; "きもち@@@"
	db "CONDITION@" 	; 08 ; Conditions	; "じょうたい@"
	db "LIFESTYLE@" 	; 09 ; Lifestyle	; "せいかつ@@"
	db "HOBBIES@" 	; 0a ; Hobbies		; "しゅみ@@@"
	db "ACTIONS@" 	; 0b ; Actions		; "こうどう@@"
	db "TIME@@" 	; 0c ; Time			; "じかん@@@"
	db "ENDINGS@@" 	; 0d ; Endings		; "むすび@@@"
	db "MISC.@" 	; 0e ; Misc			; "あれこれ@@"
	db " @@@@@"	    ; 0f ; EMPTY

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

MACRO ezchat_word
	db \1 ; word
	dw \2 ; where to put the word relative to the start of the sorted words array (must be divisible by 2)
	db 0 ; padding
ENDM

.Types:
	ezchat_word "DARK@@@@", $110
	ezchat_word "ROCK@@@@", $3fe
	ezchat_word "PSYCHIC@", $3da
	ezchat_word "FIGHTING", $1a0
	ezchat_word "GRASS@@@", $20e
	ezchat_word "GHOST@@@", $1d8
	ezchat_word "ICE@@@@@", $294
	ezchat_word "GROUND@@", $214
	ezchat_word "TYPE@@@@", $518
	ezchat_word "ELECTRIC", $15e
	ezchat_word "POISON@@", $3ca
	ezchat_word "DRAGON@@", $146
	ezchat_word "NORMAL@@", $372
	ezchat_word "STEEL@@@", $474
	ezchat_word "FLYING@@", $1b2
	ezchat_word "FIRE@@@@", $1a8
	ezchat_word "WATER@@@", $558
	ezchat_word "BUG@@@@@", $0ae

.Greetings:
	ezchat_word "THANKS@@", $4a8
	ezchat_word "THANKYOU", $4a6
	ezchat_word "LETS GO!", $2da
	ezchat_word "GO ON!@@", $1f2
	ezchat_word "DO IT!@@", $136
	ezchat_word "YEAH@@@@", $5be
	ezchat_word "HOW DO@@", $278
	ezchat_word "HOWDY!@@", $27a
	ezchat_word "CONGRATS", $0ee
	ezchat_word "SORRY@@@", $468
	ezchat_word "SORRY!@@", $46a
	ezchat_word "HI THERE", $250
	ezchat_word "HI!@@@@@", $252
	ezchat_word "HELLO@@@", $23e
	ezchat_word "GOOD-BYE", $1fe
	ezchat_word "CHEERS@@", $0d2
	ezchat_word "I'M HERE", $290
	ezchat_word "PARDON@@", $3ac
	ezchat_word "EXCUSE@@", $180
	ezchat_word "SEE YA@@", $416
	ezchat_word "YO!@@@@@", $5c6
	ezchat_word "WELL…@@@", $56e
	ezchat_word "GRATEFUL", $210
	ezchat_word "WASSUP?@", $556
	ezchat_word "HI@@@@@@", $24e
	ezchat_word "YEA, YEA", $5bc
	ezchat_word "BYE-BYE@", $0b4
	ezchat_word "HEY@@@@@", $24a
	ezchat_word "SMELL@@@", $452
	ezchat_word "TUNED IN", $514
	ezchat_word "HOO-HAH@", $272
	ezchat_word "YAHOO@@@", $5b8
	ezchat_word "YO@@@@@@", $5c4
	ezchat_word "GO OVER@", $1f4
	ezchat_word "COUNT ON", $0fc
	ezchat_word "WELCOME@", $56a

.People:
	ezchat_word "OPPONENT", $39a
	ezchat_word "I@@@@@@@", $284
	ezchat_word "YOU@@@@@", $5c8
	ezchat_word "YOURS@@@", $5d2
	ezchat_word "SON@@@@@", $462
	ezchat_word "YOUR@@@@", $5d0
	ezchat_word "YOU'RE@@", $5cc
	ezchat_word "YOU'VE@@", $5ce
	ezchat_word "MOM@@@@@", $324
	ezchat_word "GRANDPA@", $20c
	ezchat_word "UNCLE@@@", $522
	ezchat_word "DAD@@@@@", $108
	ezchat_word "BOY@@@@@", $0a8
	ezchat_word "ADULT@@@", $026
	ezchat_word "BROTHER@", $0ac
	ezchat_word "SISTER@@", $442
	ezchat_word "GRANDMA@", $20a
	ezchat_word "AUNT@@@@", $06c
	ezchat_word "ME@@@@@@", $30e
	ezchat_word "GIRL@@@@", $1e0
	ezchat_word "BABE@@@@", $078
	ezchat_word "FAMILY@@", $190
	ezchat_word "HER@@@@@", $240
	ezchat_word "HIM@@@@@", $25a
	ezchat_word "HE@@@@@@", $22c
	ezchat_word "PLACE@@@", $3ba
	ezchat_word "DAUGHTER", $116
	ezchat_word "HIS@@@@@", $25c
	ezchat_word "HE'S@@@@", $22e
	ezchat_word "AREN'T@@", $05e
	ezchat_word "GAL@@@@@", $1d0
	ezchat_word "SIBLINGS", $43a
	ezchat_word "CHILDREN", $0d6
	ezchat_word "MYSELF@@", $346
	ezchat_word "I WAS@@@", $28a
	ezchat_word "TO ME@@@", $4e0
	ezchat_word "MY@@@@@@", $344
	ezchat_word "I AM@@@@", $286
	ezchat_word "I'VE@@@@", $292
	ezchat_word "WHO@@@@@", $580
	ezchat_word "SOMEONE@", $45e
	ezchat_word "WHO WAS@", $584
	ezchat_word "TO WHOM@", $4e6
	ezchat_word "WHOSE@@@", $58a
	ezchat_word "WHO IS@@", $582
	ezchat_word "IT'S@@@@", $2b2
	ezchat_word "LADY@@@@", $2c6
	ezchat_word "FRIEND@@", $1c4
	ezchat_word "ALLY@@@@", $034
	ezchat_word "PEOPLE@@", $3b4
	ezchat_word "DUDE@@@@", $14e
	ezchat_word "THEY@@@@", $4be
	ezchat_word "THEY ARE", $4c0
	ezchat_word "TO THEM@", $4e2
	ezchat_word "THEIR@@@", $4b8
	ezchat_word "THEY'RE@", $4c2
	ezchat_word "THEY'VE@", $4c4
	ezchat_word "WE@@@@@@", $55a
	ezchat_word "BEEN@@@@", $08a
	ezchat_word "TO US@@@", $4e4
	ezchat_word "OUR@@@@@", $3a0
	ezchat_word "WE'RE@@@", $55c
	ezchat_word "RIVAL@@@", $3fc
	ezchat_word "SHE@@@@@", $426
	ezchat_word "SHE WAS@", $42a
	ezchat_word "TO HER@@", $4de
	ezchat_word "HERS@@@@", $248
	ezchat_word "SHE IS@@", $428
	ezchat_word "SOME@@@@", $45a

.Battle:
	ezchat_word "MATCH UP", $30a
	ezchat_word "GO!@@@@@", $1f6
	ezchat_word "NO. 1@@@", $36a
	ezchat_word "DECIDE@@", $122
	ezchat_word "I WIN@@@", $28c
	ezchat_word "WINS@@@@", $594
	ezchat_word "WIN@@@@@", $592
	ezchat_word "WON@@@@@", $59e
	ezchat_word "IF I WIN", $29c
	ezchat_word "I'LL WIN", $28e
	ezchat_word "CANT WIN", $0be
	ezchat_word "CAN WIN@", $0b8
	ezchat_word "NO MATCH", $366
	ezchat_word "SPIRIT@@", $46c
	ezchat_word "DECIDED@", $124
	ezchat_word "ACE CARD", $022
	ezchat_word "HI-YA!@@", $254
	ezchat_word "COME ON@", $0e8
	ezchat_word "ATTACK@@", $06a
	ezchat_word "GIVE UP@", $1e4
	ezchat_word "GUTS@@@@", $21a
	ezchat_word "TALENT@@", $490
	ezchat_word "STRATEGY", $47a
	ezchat_word "SMITE@@@", $454
	ezchat_word "MATCH@@@", $308
	ezchat_word "VICTORY@", $53c
	ezchat_word "OFFENSE@", $380
	ezchat_word "SENSE@@@", $420
	ezchat_word "VERSUS@@", $538
	ezchat_word "FIGHTS@@", $1a2
	ezchat_word "POWER@@@", $3d0
	ezchat_word "TASK@@@@", $492
	ezchat_word "STRONG@@", $47c
	ezchat_word "TOO MUCH", $4f2
	ezchat_word "HARD@@@@", $224
	ezchat_word "TERRIBLE", $49e
	ezchat_word "GO EASY@", $1ee
	ezchat_word "FOE@@@@@", $1b4
	ezchat_word "GENIUS@@", $1d4
	ezchat_word "LEGEND@@", $2d2
	ezchat_word "TRAINER@", $502
	ezchat_word "ESCAPE@@", $170
	ezchat_word "LUKEWARM", $2fe
	ezchat_word "AIM@@@@@", $02e
	ezchat_word "BATTLE@@", $082
	ezchat_word "FIGHT@@@", $19e
	ezchat_word "REVIVE@@", $3fa
	ezchat_word "POINTS@@", $3c8
	ezchat_word "POKéMON@", $3cc ; small e to conform better to existing style
	ezchat_word "SERIOUS@", $422
	ezchat_word "OH NO!@@", $382
	ezchat_word "LOSS@@@@", $2f4
	ezchat_word "YOU LOSE", $5ca
	ezchat_word "LOST@@@@", $2f6
	ezchat_word "LOSE@@@@", $2f2
	ezchat_word "GUARD@@@", $218
	ezchat_word "PARTNER@", $3ae
	ezchat_word "REJECT@@", $3f4
	ezchat_word "ACCEPT@@", $020
	ezchat_word "UNBEATEN", $520
	ezchat_word "GOT IT!@", $202
	ezchat_word "EASY@@@@", $152
	ezchat_word "WEAK@@@@", $55e
	ezchat_word "TOO WEAK", $4f4
	ezchat_word "PUSHOVER", $3dc
	ezchat_word "CHIEF@@@", $0d4
	ezchat_word "RULE@@@@", $402
	ezchat_word "LEVEL@@@", $2dc
	ezchat_word "MOVE@@@@", $334

.Exclamations:
	ezchat_word "!@@@@@@@", $000
	ezchat_word "!!@@@@@@", $002
	ezchat_word "!?@@@@@@", $004
	ezchat_word "?@@@@@@@", $006
	ezchat_word "…@@@@@@@", $008
	ezchat_word "…!@@@@@@", $00a
	ezchat_word "………@@@@@", $00c
	ezchat_word "-@@@@@@@", $00e
	ezchat_word "- - -@@@", $010
	ezchat_word "UH-OH@@@", $51c
	ezchat_word "WAAAH@@@", $53e
	ezchat_word "AHAHA@@@", $02c
	ezchat_word "OH?@@@@@", $38a
	ezchat_word "NOPE@@@@", $370
	ezchat_word "YES@@@@@", $5c0
	ezchat_word "URGH@@@@", $52a
	ezchat_word "HMM@@@@@", $264
	ezchat_word "WHOAH@@@", $586
	ezchat_word "WROOAAR!", $5b2
	ezchat_word "WOW@@@@@", $5ae
	ezchat_word "GIGGLES@", $1dc
	ezchat_word "SHOCKING", $430
	ezchat_word "CRIES@@@", $0fe
	ezchat_word "AGREE@@@", $02a
	ezchat_word "EH?@@@@@", $15a
	ezchat_word "CRY@@@@@", $102
	ezchat_word "EHEHE@@@", $15c
	ezchat_word "HOLD ON!", $26c
	ezchat_word "OH, YEAH", $386
	ezchat_word "OOPS@@@@", $398
	ezchat_word "SHOCKED@", $42e
	ezchat_word "EEK@@@@@", $158
	ezchat_word "GRAAAH@@", $208
	ezchat_word "HE-HE-HE", $230
	ezchat_word "ICK!@@@@", $296
	ezchat_word "WEEP@@@@", $566
	ezchat_word "HMPH@@@@", $266
	ezchat_word "BLUSH@@@", $09e
	ezchat_word "NO@@@@@@", $364
	ezchat_word "HUH?@@@@", $27e
	ezchat_word "YUP@@@@@", $5d4
	ezchat_word "HAHAHA@@", $21e
	ezchat_word "AIYEEH@@", $030
	ezchat_word "HIYAH@@@", $260
	ezchat_word "FUFU@@@@", $1c8
	ezchat_word "MUTTER@@", $342
	ezchat_word "LOL@@@@@", $2ec
	ezchat_word "SNORT@@@", $456
	ezchat_word "HUMPH@@@", $280
	ezchat_word "HEHEHE@@", $23c
	ezchat_word "HEHE@@@@", $23a
	ezchat_word "HOHOHO@@", $26a
	ezchat_word "UH-HUH@@", $51a
	ezchat_word "OH, DEAR", $384
	ezchat_word "ARRGH!@@", $062
	ezchat_word "MUFU@@@@", $33a
	ezchat_word "MUFUFU@@", $33c
	ezchat_word "MMM@@@@@", $320
	ezchat_word "OH-KAY@@", $388
	ezchat_word "OKAY!@@@", $390
	ezchat_word "LALALA@@", $2c8
	ezchat_word "YAY@@@@@", $5ba
	ezchat_word "AWW!@@@@", $074
	ezchat_word "WOWEE@@@", $5b0
	ezchat_word "GWAH!@@@", $21c
	ezchat_word "WAHAHA!@", $540

.Conversation:
	ezchat_word "LISTEN@@", $2e6
	ezchat_word "NOT VERY", $376
	ezchat_word "MEAN@@@@", $310
	ezchat_word "LIE@@@@@", $2de
	ezchat_word "LAY@@@@@", $2ce
	ezchat_word "OI@@@@@@", $38c
	ezchat_word "SUGGEST@", $480
	ezchat_word "NITWIT@@", $362
	ezchat_word "QUITE@@@", $3e0
	ezchat_word "FROM@@@@", $1c6
	ezchat_word "FEELING@", $19a
	ezchat_word "BUT@@@@@", $0b2
	ezchat_word "HOWEVER@", $27c
	ezchat_word "CASE@@@@", $0c8
	ezchat_word "MISS@@@@", $31c
	ezchat_word "HOW@@@@@", $276
	ezchat_word "HIT@@@@@", $25e
	ezchat_word "ENOUGH@@", $16a
	ezchat_word "SOON@@@@", $466
	ezchat_word "A LOT@@@", $01a
	ezchat_word "A LITTLE", $018
	ezchat_word "AMAZING@", $040
	ezchat_word "ENTIRELY", $16c
	ezchat_word "FULLY@@@", $1cc
	ezchat_word "AND SO@@", $046
	ezchat_word "ONLY@@@@", $396
	ezchat_word "AROUND@@", $060
	ezchat_word "PROBABLY", $3d6
	ezchat_word "IF@@@@@@", $29a
	ezchat_word "VERY@@@@", $53a
	ezchat_word "A BIT@@@", $016
	ezchat_word "WILD@@@@", $58e
	ezchat_word "THAT'S@@", $4b2
	ezchat_word "I MEAN@@", $288
	ezchat_word "EVEN SO,", $172
	ezchat_word "MUST BE@", $340
	ezchat_word "NATURALY", $34e
	ezchat_word "GO AHEAD", $1ec
	ezchat_word "FOR NOW,", $1b8
	ezchat_word "HEY?@@@@", $24c
	ezchat_word "JOKING@@", $2b6
	ezchat_word "READY@@@", $3e8
	ezchat_word "SOMEHOW@", $45c
	ezchat_word "ALTHOUGH", $03c
	ezchat_word "PERFECT@", $3b6
	ezchat_word "FIRMLY@@", $1aa
	ezchat_word "EQUAL TO", $16e
	ezchat_word "REALLY@@", $3ee
	ezchat_word "TRULY@@@", $50c
	ezchat_word "SURELY@@", $488
	ezchat_word "FOR SURE", $1ba
	ezchat_word "TOTALLY@", $4f6
	ezchat_word "UNTIL@@@", $526
	ezchat_word "AS IF@@@", $066
	ezchat_word "MOOD@@@@", $32e
	ezchat_word "RATHER@@", $3e6
	ezchat_word "NO WAY@@", $368
	ezchat_word "AWFULLY@", $072
	ezchat_word "ALMOST@@", $036
	ezchat_word "MODE@@@@", $322
	ezchat_word "MORE@@@@", $330
	ezchat_word "TOO LATE", $4f0
	ezchat_word "FINALLY@", $1a6
	ezchat_word "ANY@@@@@", $052
	ezchat_word "INSTEAD@", $2a6
	ezchat_word "TERRIFIC", $4a0

.Feelings:
	ezchat_word "MEET@@@@", $312
	ezchat_word "PLAY@@@@", $3be
	ezchat_word "GOES@@@@", $1f8
	ezchat_word "GIDDY@@@", $1da
	ezchat_word "HAPPY@@@", $222
	ezchat_word "GLEE@@@@", $1e8
	ezchat_word "EXCITE@@", $17c
	ezchat_word "CRUCIAL@", $100
	ezchat_word "FUNNY@@@", $1ce
	ezchat_word "GOT@@@@@", $200
	ezchat_word "GO HOME@", $1f0
	ezchat_word "FAILS@@@", $188
	ezchat_word "SAD@@@@@", $408
	ezchat_word "TRY@@@@@", $510
	ezchat_word "HEARS@@@", $238
	ezchat_word "THINK@@@", $4ca
	ezchat_word "HEAR@@@@", $234
	ezchat_word "WANTS@@@", $550
	ezchat_word "MISHEARD", $31a
	ezchat_word "DISLIKE@", $130
	ezchat_word "ANGRY@@@", $04c
	ezchat_word "ANGER@@@", $048
	ezchat_word "LONESOME", $2ee
	ezchat_word "FAIL@@@@", $186
	ezchat_word "JOY@@@@@", $2ba
	ezchat_word "GETS@@@@", $1d6
	ezchat_word "NEVER@@@", $356
	ezchat_word "DARN@@@@", $112
	ezchat_word "DOWNCAST", $144
	ezchat_word "LIKES@@@", $2e2
	ezchat_word "DISLIKES", $132
	ezchat_word "BORING@@", $0a6
	ezchat_word "CARE@@@@", $0c6
	ezchat_word "ADORE@@@", $024
	ezchat_word "DISASTER", $12e
	ezchat_word "ENJOY@@@", $166
	ezchat_word "ENJOYS@@", $168
	ezchat_word "EAT@@@@@", $154
	ezchat_word "USELESS@", $52e
	ezchat_word "LACKING@", $2c2
	ezchat_word "BAD@@@@@", $07a
	ezchat_word "SHOULD@@", $434
	ezchat_word "EXCITING", $17e
	ezchat_word "NICE@@@@", $35c
	ezchat_word "DRINK@@@", $14a
	ezchat_word "SURPRISE", $48a
	ezchat_word "FEAR@@@@", $198
	ezchat_word "WOBBLY@@", $59c
	ezchat_word "WANT@@@@", $54e
	ezchat_word "SHREDDED", $438
	ezchat_word "YET@@@@@", $5c2
	ezchat_word "WAIT@@@@", $542
	ezchat_word "CONTENT@", $0f0
	ezchat_word "SEE@@@@@", $414
	ezchat_word "RARE@@@@", $3e4
	ezchat_word "FIERY@@@", $19c
	ezchat_word "NEGATIVE", $354
	ezchat_word "DONE@@@@", $13c
	ezchat_word "DANGER@@", $10e
	ezchat_word "DONE FOR", $13e
	ezchat_word "DEFEATED", $128
	ezchat_word "BEAT@@@@", $086
	ezchat_word "GREAT@@@", $212
	ezchat_word "DOTING@@", $140
	ezchat_word "ROMANTIC", $400
	ezchat_word "QUESTION", $3de
	ezchat_word "REALIZE@", $3ea
	ezchat_word "REALIZES", $3ec
	ezchat_word "SUSPENSE", $48c

.Conditions:
	ezchat_word "HOT@@@@@", $274
	ezchat_word "EXISTS@@", $182
	ezchat_word "APPROVED", $05a
	ezchat_word "HAS@@@@@", $226
	ezchat_word "HURRIED@", $282
	ezchat_word "GOOD@@@@", $1fc
	ezchat_word "LESS@@@@", $2d4
	ezchat_word "MEGA@@@@", $316
	ezchat_word "MOMENTUM", $326
	ezchat_word "GOING@@@", $1fa
	ezchat_word "WEIRD@@@", $568
	ezchat_word "BUSY@@@@", $0b0
	ezchat_word "TOGETHER", $4ea
	ezchat_word "FULL@@@@", $1ca
	ezchat_word "ABSENT@@", $01e
	ezchat_word "BEING@@@", $08e
	ezchat_word "NEED@@@@", $352
	ezchat_word "TASTY@@@", $494
	ezchat_word "SKILLED@", $446
	ezchat_word "BIG@@@@@", $09a
	ezchat_word "LATE@@@@", $2ca
	ezchat_word "CLOSE@@@", $0e0
	ezchat_word "AMUSING@", $042
	ezchat_word "ENGAGING", $164
	ezchat_word "COOL@@@@", $0f2
	ezchat_word "CUTE@@@@", $106
	ezchat_word "FLAWLESS", $1ae
	ezchat_word "PRETTY@@", $3d4
	ezchat_word "HEALTHY@", $232
	ezchat_word "SCARY@@@", $40e
	ezchat_word "SUPERB@@", $486
	ezchat_word "COLD@@@@", $0e2
	ezchat_word "LIVELY@@", $2e8
	ezchat_word "FATED@@@", $196
	ezchat_word "MUCH@@@@", $338
	ezchat_word "IMMENSE@", $2a0
	ezchat_word "FABULOUS", $184
	ezchat_word "ELSE@@@@", $160
	ezchat_word "ALRIGHT@", $03a
	ezchat_word "COSTLY@@", $0f6
	ezchat_word "CORRECT@", $0f4
	ezchat_word "UNLIKELY", $524
	ezchat_word "SMALL@@@", $450
	ezchat_word "VARIED@@", $536
	ezchat_word "TIRED@@@", $4da
	ezchat_word "SKILL@@@", $444
	ezchat_word "NON-STOP", $36c
	ezchat_word "NONE@@@@", $36e
	ezchat_word "NOTHING@", $378
	ezchat_word "NATURAL@", $34c
	ezchat_word "BECOMES@", $088
	ezchat_word "FAST@@@@", $194
	ezchat_word "SHINE@@@", $42c
	ezchat_word "LOW@@@@@", $2fa
	ezchat_word "AWFUL@@@", $070
	ezchat_word "ALONE@@@", $038
	ezchat_word "BORED@@@", $0a4
	ezchat_word "LACKS@@@", $2c4
	ezchat_word "LOUSY@@@", $2f8
	ezchat_word "MISTAKE@", $31e
	ezchat_word "KIND@@@@", $2bc
	ezchat_word "WELL@@@@", $56c
	ezchat_word "WEAKENED", $560
	ezchat_word "SIMPLE@@", $43c
	ezchat_word "SEEMS@@@", $41a
	ezchat_word "BADLY@@@", $07c

.Life:
	ezchat_word "CHORES@@", $0dc
	ezchat_word "HOME@@@@", $270
	ezchat_word "MONEY@@@", $32a
	ezchat_word "SAVINGS@", $40c
	ezchat_word "BATH@@@@", $080
	ezchat_word "SCHOOL@@", $410
	ezchat_word "REMEMBER", $3f8
	ezchat_word "GROUP@@@", $216
	ezchat_word "GOTCHA@@", $204
	ezchat_word "EXCHANGE", $17a
	ezchat_word "WORK@@@@", $5a2
	ezchat_word "TRAINING", $504
	ezchat_word "CLASS@@@", $0de
	ezchat_word "LESSONS@", $2d6
	ezchat_word "EVOLVE@@", $178
	ezchat_word "HANDBOOK", $220
	ezchat_word "LIVING@@", $2ea
	ezchat_word "TEACHER@", $498
	ezchat_word "CENTER@@", $0cc
	ezchat_word "TOWER@@@", $4f8
	ezchat_word "LINK@@@@", $2e4
	ezchat_word "TEST@@@@", $4a2
	ezchat_word "TV@@@@@@", $516
	ezchat_word "PHONE@@@", $3b8
	ezchat_word "ITEM@@@@", $2b4
	ezchat_word "TRADE@@@", $4fe
	ezchat_word "NAME@@@@", $348
	ezchat_word "NEWS@@@@", $358
	ezchat_word "POPULAR@", $3ce
	ezchat_word "PARTY@@@", $3b0
	ezchat_word "STUDY@@@", $47e
	ezchat_word "MACHINE@", $300
	ezchat_word "CARD@@@@", $0c2
	ezchat_word "MESSAGE@", $318
	ezchat_word "MAKEOVER", $304
	ezchat_word "DREAM@@@", $148
	ezchat_word "DAY CARE", $11a
	ezchat_word "RADIO@@@", $3e2
	ezchat_word "WORLD@@@", $5a8

.Hobbies:
	ezchat_word "IDOL@@@@", $298
	ezchat_word "ANIME@@@", $04e
	ezchat_word "SONG@@@@", $464
	ezchat_word "MOVIE@@@", $336
	ezchat_word "CANDY@@@", $0bc
	ezchat_word "CHAT@@@@", $0d0
	ezchat_word "TOYHOUSE", $4fa
	ezchat_word "TOYS@@@@", $4fc
	ezchat_word "MUSIC@@@", $33e
	ezchat_word "CARDS@@@", $0c4
	ezchat_word "SHOPPING", $432
	ezchat_word "GOURMET@", $206
	ezchat_word "GAME@@@@", $1d2
	ezchat_word "MAGAZINE", $302
	ezchat_word "WALK@@@@", $548
	ezchat_word "BIKE@@@@", $09c
	ezchat_word "HOBBIES@", $268
	ezchat_word "SPORTS@@", $46e
	ezchat_word "DIET@@@@", $12c
	ezchat_word "TREASURE", $50a
	ezchat_word "TRAVEL@@", $508
	ezchat_word "DANCE@@@", $10c
	ezchat_word "FISHING@", $1ac
	ezchat_word "DATE@@@@", $114
	ezchat_word "TRAIN@@@", $500
	ezchat_word "PLUSHIE@", $3c6
	ezchat_word "PC@@@@@@", $3b2
	ezchat_word "FLOWERS@", $1b0
	ezchat_word "HERO@@@@", $244
	ezchat_word "NAP@@@@@", $34a
	ezchat_word "HEROINE@", $246
	ezchat_word "JOURNEY@", $2b8
	ezchat_word "BOARD@@@", $0a0
	ezchat_word "BALL@@@@", $07e
	ezchat_word "BOOK@@@@", $0a2
	ezchat_word "MANGA@@@", $306
	ezchat_word "PROMISE@", $3d8
	ezchat_word "HOLIDAY@", $26e
	ezchat_word "PLANS@@@", $3bc

.Actions:
	ezchat_word "MEETS@@@", $314
	ezchat_word "CONCEDE@", $0ea
	ezchat_word "GIVE@@@@", $1e2
	ezchat_word "GIVES@@@", $1e6
	ezchat_word "PLAYED@@", $3c0
	ezchat_word "PLAYS@@@", $3c2
	ezchat_word "COLLECT@", $0e4
	ezchat_word "WALKING@", $54a
	ezchat_word "WALKS@@@", $54c
	ezchat_word "WENT@@@@", $570
	ezchat_word "GO@@@@@@", $1ea
	ezchat_word "WAKE UP@", $544
	ezchat_word "WAKES UP", $546
	ezchat_word "ANGERS@@", $04a
	ezchat_word "TEACH@@@", $496
	ezchat_word "TEACHES@", $49a
	ezchat_word "PLEASE@@", $3c4
	ezchat_word "LEARN@@@", $2d0
	ezchat_word "CHANGE@@", $0ce
	ezchat_word "TRUST@@@", $50e
	ezchat_word "HEARING@", $236
	ezchat_word "TRAINS@@", $506
	ezchat_word "CHOOSE@@", $0da
	ezchat_word "COME@@@@", $0e6
	ezchat_word "SEARCH@@", $412
	ezchat_word "CAUSE@@@", $0ca
	ezchat_word "THESE@@@", $4bc
	ezchat_word "KNOW@@@@", $2be
	ezchat_word "KNOWS@@@", $2c0
	ezchat_word "REFUSE@@", $3f2
	ezchat_word "STORES@@", $478
	ezchat_word "BRAG@@@@", $0aa
	ezchat_word "IGNORANT", $29e
	ezchat_word "THINKS@@", $4cc
	ezchat_word "BELIEVE@", $090
	ezchat_word "SLIDE@@@", $44c
	ezchat_word "EATS@@@@", $156
	ezchat_word "USE@@@@@", $52c
	ezchat_word "USES@@@@", $530
	ezchat_word "USING@@@", $532
	ezchat_word "COULDN'T", $0fa
	ezchat_word "CAPABLE@", $0c0
	ezchat_word "VANISH@@", $534
	ezchat_word "APPEAR@@", $056
	ezchat_word "THROW@@@", $4d4
	ezchat_word "WORRY@@@", $5aa
	ezchat_word "SLEPT@@@", $44a
	ezchat_word "SLEEP@@@", $448
	ezchat_word "RELEASE@", $3f6
	ezchat_word "DRINKS@@", $14c
	ezchat_word "RUNS@@@@", $406
	ezchat_word "RUN@@@@@", $404
	ezchat_word "WORKS@@@", $5a6
	ezchat_word "WORKING@", $5a4
	ezchat_word "SINK@@@@", $440
	ezchat_word "SMACK@@@", $44e
	ezchat_word "PRAISE@@", $3d2
	ezchat_word "SHOW@@@@", $436
	ezchat_word "LOOKS@@@", $2f0
	ezchat_word "SEES@@@@", $41e
	ezchat_word "SEEK@@@@", $418
	ezchat_word "OWN@@@@@", $3aa
	ezchat_word "TAKE@@@@", $48e
	ezchat_word "ALLOW@@@", $032
	ezchat_word "FORGET@@", $1be
	ezchat_word "FORGETS@", $1c0
	ezchat_word "APPEARS@", $058
	ezchat_word "FAINT@@@", $18a
	ezchat_word "FAINTED@", $18c

.Time:
	ezchat_word "FALL@@@@", $18e
	ezchat_word "MORNING@", $332
	ezchat_word "TOMORROW", $4ec
	ezchat_word "DAY@@@@@", $118
	ezchat_word "SOMETIME", $460
	ezchat_word "ALWAYS@@", $03e
	ezchat_word "CURRENT@", $104
	ezchat_word "FOREVER@", $1bc
	ezchat_word "DAYS@@@@", $11c
	ezchat_word "END@@@@@", $162
	ezchat_word "TUESDAY@", $512
	ezchat_word "Y'DAY@@@", $5b4
	ezchat_word "TODAY@@@", $4e8
	ezchat_word "FRIDAY@@", $1c2
	ezchat_word "MONDAY@@", $328
	ezchat_word "LATER@@@", $2cc
	ezchat_word "EARLIER@", $150
	ezchat_word "ANOTHER@", $050
	ezchat_word "TIME@@@@", $4d8
	ezchat_word "DECADE@@", $120
	ezchat_word "WEDNSDAY", $562
	ezchat_word "START@@@", $472
	ezchat_word "MONTH@@@", $32c
	ezchat_word "STOP@@@@", $476
	ezchat_word "NOW@@@@@", $37a
	ezchat_word "FINAL@@@", $1a4
	ezchat_word "NEXT@@@@", $35a
	ezchat_word "SATURDAY", $40a
	ezchat_word "SUMMER@@", $482
	ezchat_word "SUNDAY@@", $484
	ezchat_word "OUTSET@@", $3a4
	ezchat_word "SPRING@@", $470
	ezchat_word "DAYTIME@", $11e
	ezchat_word "WINTER@@", $596
	ezchat_word "DAILY@@@", $10a
	ezchat_word "THURSDAY", $4d6
	ezchat_word "NITETIME", $360
	ezchat_word "NIGHT@@@", $35e
	ezchat_word "WEEK@@@@", $564

.Farewells:
	ezchat_word "WILL@@@@", $590
	ezchat_word "AYE@@@@@", $076
	ezchat_word "?!@@@@@@", $012
	ezchat_word "HM?@@@@@", $262
	ezchat_word "Y'THINK?", $5b6
	ezchat_word "IS IT?@@", $2aa
	ezchat_word "BE@@@@@@", $084
	ezchat_word "GIMME@@@", $1de
	ezchat_word "COULD@@@", $0f8
	ezchat_word "TEND TO@", $49c
	ezchat_word "WOULD@@@", $5ac
	ezchat_word "IS@@@@@@", $2a8
	ezchat_word "ISNT IT?", $2ae
	ezchat_word "LET'S@@@", $2d8
	ezchat_word "OTHER@@@", $39e
	ezchat_word "ARE@@@@@", $05c
	ezchat_word "WAS@@@@@", $552
	ezchat_word "WERE@@@@", $572
	ezchat_word "THOSE@@@", $4d2
	ezchat_word "ISN'T@@@", $2ac
	ezchat_word "WON'T@@@", $5a0
	ezchat_word "CAN'T@@@", $0ba
	ezchat_word "CAN@@@@@", $0b6
	ezchat_word "DON'T@@@", $13a
	ezchat_word "DO@@@@@@", $134
	ezchat_word "DOES@@@@", $138
	ezchat_word "WHOM@@@@", $588
	ezchat_word "WHICH@@@", $57c
	ezchat_word "WASN'T@@", $554
	ezchat_word "WEREN'T@", $574
	ezchat_word "HAVE@@@@", $228
	ezchat_word "HAVEN'T@", $22a
	ezchat_word "A@@@@@@@", $014
	ezchat_word "AN@@@@@@", $044
	ezchat_word "NOT@@@@@", $374
	ezchat_word "THERE@@@", $4ba
	ezchat_word "OK?@@@@@", $38e
	ezchat_word "SO@@@@@@", $458
	ezchat_word "MAYBE@@@", $30c
	ezchat_word "ABOUT@@@", $01c
	ezchat_word "OVER@@@@", $3a8
	ezchat_word "IT@@@@@@", $2b0
	ezchat_word "FOR@@@@@", $1b6
	ezchat_word "ON@@@@@@", $392
	ezchat_word "OFF@@@@@", $37e
	ezchat_word "AS@@@@@@", $064
	ezchat_word "TO@@@@@@", $4dc
	ezchat_word "WITH@@@@", $598
	ezchat_word "BETTER@@", $098
	ezchat_word "EVER@@@@", $174
	ezchat_word "SINCE@@@", $43e
	ezchat_word "OF@@@@@@", $37c
	ezchat_word "BELONG@@", $092
	ezchat_word "AT@@@@@@", $068
	ezchat_word "IN@@@@@@", $2a2
	ezchat_word "OUT@@@@@", $3a2
	ezchat_word "TOO@@@@@", $4ee
	ezchat_word "LIKE@@@@", $2e0
	ezchat_word "DID@@@@@", $12a
	ezchat_word "WITHOUT@", $59a
	ezchat_word "AFTER@@@", $028
	ezchat_word "BEFORE@@", $08c
	ezchat_word "WHILE@@@", $57e
	ezchat_word "THAN@@@@", $4a4
	ezchat_word "ONCE@@@@", $394
	ezchat_word "ANYWHERE", $054

.ThisAndThat:
	ezchat_word "HIGHS@@@", $258
	ezchat_word "LOWS@@@@", $2fc
	ezchat_word "UM@@@@@@", $51e
	ezchat_word "REAR@@@@", $3f0
	ezchat_word "THINGS@@", $4c8
	ezchat_word "THING@@@", $4c6
	ezchat_word "BELOW@@@", $094
	ezchat_word "HIGH@@@@", $256
	ezchat_word "HERE@@@@", $242
	ezchat_word "INSIDE@@", $2a4
	ezchat_word "OUTSIDE@", $3a6
	ezchat_word "BESIDE@@", $096
	ezchat_word "THIS ONE", $4d0
	ezchat_word "THIS@@@@", $4ce
	ezchat_word "EVERY@@@", $176
	ezchat_word "SEEMS SO", $41c
	ezchat_word "DOWN@@@@", $142
	ezchat_word "THAT@@@@", $4aa
	ezchat_word "THAT IS@", $4ac
	ezchat_word "THAT ONE", $4ae
	ezchat_word "THATS IT", $4b6
	ezchat_word "THAT'S..", $4b4
	ezchat_word "THAT WAS", $4b0
	ezchat_word "UP@@@@@@", $528
	ezchat_word "CHOICE@@", $0d8
	ezchat_word "FAR@@@@@", $192
	ezchat_word "AWAY@@@@", $06e
	ezchat_word "NEAR@@@@", $350
	ezchat_word "WHERE@@@", $57a
	ezchat_word "WHEN@@@@", $578
	ezchat_word "WHAT@@@@", $576
	ezchat_word "DEEP@@@@", $126
	ezchat_word "SHALLOW@", $424
	ezchat_word "WHY@@@@@", $58c
	ezchat_word "CONFUSED", $0ec
	ezchat_word "OPPOSITE", $39c

MobileEZChatData_WordAndPageCounts:
MACRO macro_11f220
; parameter: number of words
	db \1
; 12 words per page (0-based indexing)
	DEF x = \1 / (EZCHAT_WORD_COUNT * 2) ; 12 MENU_WIDTH to 8
	if \1 % (EZCHAT_WORD_COUNT * 2) == 0 ; 12 MENU_WIDTH to 8
		DEF x = x + -1
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
; any Pokemon you've seen that starts with each kana.
MACRO macro_11f23c
	dw x - w3_d000, \1
	DEF x = x + 2 * \1
ENDM
DEF x = $d014
	macro_11f23c  50 ; A
	macro_11f23c  31 ; B
	macro_11f23c  41 ; C
	macro_11f23c  36 ; D
	macro_11f23c  26 ; E
	macro_11f23c  38 ; F
	macro_11f23c  39 ; G
	macro_11f23c  51 ; H
	macro_11f23c  25 ; I
	macro_11f23c   3 ; J
	macro_11f23c   3 ; K
	macro_11f23c  31 ; L
	macro_11f23c  36 ; M
	macro_11f23c  26 ; N
	macro_11f23c  24 ; O
	macro_11f23c  25 ; P
	macro_11f23c   2 ; Q
	macro_11f23c  19 ; R
	macro_11f23c  67 ; S
	macro_11f23c  70 ; T
	macro_11f23c  13 ; U
	macro_11f23c   5 ; V
	macro_11f23c  59 ; W
	macro_11f23c   0 ; X
	macro_11f23c  17 ; Y
	macro_11f23c   0 ; Z
DEF x = $d000
	macro_11f23c  10 ; !?
.End