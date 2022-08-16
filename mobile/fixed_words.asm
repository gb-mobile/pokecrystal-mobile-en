EZCHAT_WORD_COUNT equ 4
EZCHAT_WORD_LENGTH equ 8
EZCHAT_WORDS_PER_ROW equ 2
EZCHAT_WORDS_PER_COL equ 4
EZCHAT_WORDS_IN_MENU equ EZCHAT_WORDS_PER_ROW * EZCHAT_WORDS_PER_COL

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
	ld [wEZChatSortedSelection], a
	ld [wcd35], a
	ld [wEZChatCategoryMode], a
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
	ld a, [wEZChatCategoryMode]
	and a
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
	ld a, EZCHAT_MAIN_OK
	ld [wEZChatSelection], a

.b
	ld a, EZCHAT_DRAW_CHAT_WORDS
	jr .go_to_function

.select
	ld a, [wEZChatCategoryMode]
	xor 1
	ld [wEZChatCategoryMode], a
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
	jr nz, .next_page
	ld a, [de]
	and SELECT
	jr z, .check_joypad

; select
	ld a, [wEZChatPageOffset]
	and a
	ret z
	sub EZCHAT_WORDS_IN_MENU
	jr nc, .prev_page
; page 0
	xor a
.prev_page
	ld [wEZChatPageOffset], a
	jr .navigate_to_page

.next_page
	ld hl, wEZChatLoadedItems
	ld a, [wEZChatPageOffset]
	add EZCHAT_WORDS_IN_MENU
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
	call Function11c7bc
	call EZChatMenu_WordSubmenuBottom
	ret

.check_joypad
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
	ld a, EZCHAT_DRAW_CHAT_WORDS
	ld [wcd35], a
	jr .jump_to_index

.b
	ld a, [wEZChatCategoryMode]
	and a
	jr nz, .to_sorted_menu
	ld a, EZCHAT_DRAW_CATEGORY_MENU
	jr .jump_to_index

.to_sorted_menu
	ld a, EZCHAT_DRAW_SORT_BY_CHARACTER
.jump_to_index
	ld [wJumptableIndex], a
	ld hl, wcd24
	set 3, [hl]
	call PlayClickSFX
	ret

.up
	ld a, [hl]
	cp EZCHAT_WORDS_PER_ROW
	jr c, .move_menu_up
	sub EZCHAT_WORDS_PER_ROW
	jr .finish_dpad

.move_menu_up
	ld a, [wEZChatPageOffset]
	sub EZCHAT_WORDS_PER_ROW
	ret c
	ld [wEZChatPageOffset], a
	jr .navigate_to_page

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
	jr .navigate_to_page

.down
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

.left
	ld a, [hl]
	and a ; cp a, 0
	ret z
x = EZCHAT_WORDS_PER_ROW
rept EZCHAT_WORDS_PER_COL - 1
	cp x
	ret z
x = x + EZCHAT_WORDS_PER_ROW
endr
	dec a
	jr .finish_dpad

.right
	ld a, [wEZChatLoadedItems]
	ld b, a
	ld a, [wEZChatPageOffset]
	add [hl]
	inc a
	cp b
	ret nc
	ld a, [hl]
x = EZCHAT_WORDS_PER_ROW
rept EZCHAT_WORDS_PER_COL
	cp x - 1
	ret z
x = x + EZCHAT_WORDS_PER_ROW
endr
	inc a

.finish_dpad
	ld [hl], a
	ret

Function11c770:
	xor a
	ld [wEZChatWordSelection], a
	ld [wEZChatPageOffset], a
	ld [wcd27], a
	ld a, [wEZChatCategoryMode]
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
	ld [wEZChatLoadedItems], a
	ld a, [hl]
.load
	ld [wcd29], a
	ret

.cd21_is_zero
	; compute from [wc7d2]
	ld a, [wc7d2]
	ld [wEZChatLoadedItems], a
.div_12
	ld c, EZCHAT_WORDS_IN_MENU
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
	ld a, [wEZChatSortedSelection]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hl]
	ld [wEZChatLoadedItems], a
	jr .div_12

Function11c7bc: ; Related to drawing words in the lower menu after picking a category
	ld bc, EZChatCoord_WordSubmenu
	ld a, [wEZChatCategoryMode]
	and a
	jr nz, .is_sorted
; grouped
	ld a, [wEZChatCategorySelection]
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
	ld d, $0
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
	ld d, $0
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
	ld d, $0
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

Function11c8f6:
	ld a, [wEZChatSelection]
	call EZChat_ClearWords
	push hl
	ld a, [wEZChatCategoryMode]
	and a
	jr nz, .asm_11c938
	ld a, [wEZChatCategorySelection]
	ld d, a
	and a
	jr z, .asm_11c927
	ld hl, wEZChatPageOffset
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
	ld hl, wEZChatPageOffset
	ld a, [wEZChatWordSelection]
	add [hl]
	ld c, a
	ld b, $0
	ld hl, wListPointer
	add hl, bc
	ld a, [hl]
	jr .asm_11c911
.asm_11c938
	ld hl, wEZChatSortedWordPointers
	ld a, [wEZChatSortedSelection]
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
	ld a, [wEZChatPageOffset]
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

EZChat_ClearWords:
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
	ld a, EZCHAT_WORD_LENGTH
	ld c, a
	ld a, " "
.asm_11c972
	ld [hli], a
	dec c
	jr nz, .asm_11c972
	dec hl
	ld bc, -SCREEN_WIDTH
	add hl, bc
	ld a, EZCHAT_WORD_LENGTH
	ld c, a
	ld a, " "
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
	call EZChat_ClearWords
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
	ld a, [wEZChatCategoryMode]
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
	ld [wEZChatCategoryMode], a
.b
	ld a, [wEZChatCategoryMode]
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

.a
	ld a, [wEZChatSortedSelection]
	cp NUM_KANA
	jr c, .place
	sub NUM_KANA
	jr z, .done
	dec a
	jr z, .mode
	jr .b ; cancel

.start
	ld hl, wcd24
	set 0, [hl]
	ld a, EZCHAT_MAIN_OK
	ld [wEZChatSelection], a
.b
	ld a, EZCHAT_DRAW_CHAT_WORDS
	jr .load

.select
	ld a, [wEZChatCategoryMode]
	xor 1
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
	ld [wEZChatSortedSelection], a
	ret

.NeighboringCharacters: ; Sort Menu Letter tile values or coordinates?
	;  up   rgt  dwn  lft
	db $ff, $01, $05, $ff ;  5, 255
	db $ff, $02, $06, $00 ;  6, 0
	db $ff, $03, $07, $01 ;  7, 1
	db $ff, $04, $08, $02 ;  8, 2
	db $ff, $14, $09, $03 ;  9, 3
	db $00, $06, $0a, $ff ; 10, 255
	db $01, $07, $0b, $05 ; 11, 5
	db $02, $08, $0c, $06 ; 12, 6
	db $03, $09, $0d, $07 ; 13, 7
	db $04, $19, $0e, $08 ; 14, 8
	db $05, $0b, $0f, $ff ; 15, 255
	db $06, $0c, $10, $0a ; 16, 10
	db $07, $0d, $11, $0b ; 17, 11
	db $08, $0e, $12, $0c ; 18, 12
	db $09, $1e, $13, $0d ; 19, 13
	db $0a, $10, $2d, $ff ; 45, 255
	db $0b, $11, $2d, $0f ; 45, 15
	db $0c, $12, $2d, $10 ; 45, 16
	db $0d, $13, $2d, $11 ; 45, 17
	db $0e, $26, $2d, $12 ; 45, 18
	db $ff, $15, $19, $04 ; 25, 4
	db $ff, $16, $1a, $14 ; 26, 20
	db $ff, $17, $1b, $15 ; 27, 21
	db $ff, $18, $1c, $16 ; 28, 22
	db $ff, $23, $1d, $17 ; 29, 23
	db $14, $1a, $1e, $09 ; 30, 9
	db $15, $1b, $1f, $19 ; 31, 25
	db $16, $1c, $20, $1a ; 32, 26
	db $17, $1d, $21, $1b ; 33, 27
	db $18, $2b, $22, $1c ; 34, 28
	db $19, $1f, $26, $0e ; 38, 14
	db $1a, $20, $27, $1e ; 39, 30
	db $1b, $21, $28, $1f ; 40, 31
	db $1c, $22, $29, $20 ; 41, 32
	db $1d, $2c, $2a, $21 ; 42, 33
	db $ff, $24, $2b, $18 ; 43, 24
	db $ff, $25, $2b, $23 ; 43, 35
	db $ff, $ff, $2b, $24 ; 43, 36
	db $1e, $27, $2e, $13 ; 46, 19
	db $1f, $28, $2e, $26 ; 46, 38
	db $20, $29, $2e, $27 ; 46, 39
	db $21, $2a, $2e, $28 ; 46, 40
	db $22, $ff, $2e, $29 ; 46, 41
	db $23, $ff, $2c, $1d ; 44, 29
	db $2b, $ff, $2f, $22 ; 47, 34
	db $0f, $2e, $ff, $ff ; 255, 255
	db $26, $2f, $ff, $2d ; 255, 45
	db $2c, $ff, $ff, $2e ; 255, 46

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
	dbpixel  1,  3, 5, 2 ; Message 1 - 00
	dbpixel 10,  3, 5, 2 ; Message 2 - 01
	dbpixel  1,  5, 5, 2 ; Message 3 - 02
	dbpixel 10,  5, 5, 2 ; Message 4 - 03
	dbpixel  1, 17, 5, 2 ; RESET     - 04
	dbpixel  7, 17, 5, 2 ; QUIT      - 05
	dbpixel 13, 17, 5, 2 ; OK        - 06

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

	ld a, LOW(EZChat_SortedPokemon)
	ld [wcd2f], a
	ld a, HIGH(EZChat_SortedPokemon)
	ld [wcd30], a

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

ezchat_word: MACRO
	db \1 ; word
	dw \2 ; where to put the word relative to the start of the sorted words array (must be divisible by 2)
	db 0 ; padding
ENDM

.Types:
	ezchat_word "DARK@@@@", $026 ; あく@@@,
	ezchat_word "ROCK@@@@", $0aa ; いわ@@@,
	ezchat_word "PSYCHIC@", $0da ; エスパー@,
	ezchat_word "FIGHTING", $14e ; かくとう@,
	ezchat_word "GRASS@@@", $1ba ; くさ@@@,
	ezchat_word "GHOST@@@", $1e4 ; ゴースト@,
	ezchat_word "ICE@@@@@", $1e6 ; こおり@@,
	ezchat_word "GROUND@@", $268 ; じめん@@,
	ezchat_word "TYPE@@@@", $2e8 ; タイプ@@,
	ezchat_word "ELECTRIC", $38e ; でんき@@,
	ezchat_word "POISON@@", $3ae ; どく@@@,
	ezchat_word "DRAGON@@", $3bc ; ドラゴン@,
	ezchat_word "NORMAL@@", $422 ; ノーマル@,
	ezchat_word "STEEL@@@", $436 ; はがね@@,
	ezchat_word "FLYING@@", $45e ; ひこう@@,
	ezchat_word "FIRE@@@@", $4b2 ; ほのお@@,
	ezchat_word "WATER@@@", $4f4 ; みず@@@,
	ezchat_word "BUG@@@@@", $512 ; むし@@@,

.Greetings:
	ezchat_word "THANKS@@", $058 ; ありがと@,
	ezchat_word "THANK U@", $05a ; ありがとう,
	ezchat_word "LETS GO!", $080 ; いくぜ！@,
	ezchat_word "GO ON!@@", $082 ; いくよ！@,
	ezchat_word "DO IT!@@", $084 ; いくわよ！,
	ezchat_word "YEAH@@@@", $0a6 ; いやー@@,
	ezchat_word "HOW DO@@", $10a ; おっす@@,
	ezchat_word "HOWDY!@@", $122 ; おはつです,
	ezchat_word "CONGRATS", $12a ; おめでとう,
	ezchat_word "SORRY@@@", $1f8 ; ごめん@@,
	ezchat_word "SORRY!@@", $1fa ; ごめんよ@,
	ezchat_word "HI THERE", $1fc ; こらっ@@,
	ezchat_word "HI!@@@@@", $20a ; こんちは！,
	ezchat_word "HELLO@@@", $210 ; こんにちは,
	ezchat_word "GOOD-BYE", $228 ; さようなら,
	ezchat_word "CHEERS@@", $22e ; サンキュー,
	ezchat_word "I'M HERE", $230 ; さんじょう,
	ezchat_word "PARDON@@", $248 ; しっけい@,
	ezchat_word "EXCUSE@@", $24c ; しつれい@,
	ezchat_word "SEE YA@@", $26c ; じゃーね@,
	ezchat_word "YO!@@@@@", $28c ; すいません,
	ezchat_word "WELL...@", $2ca ; それじゃ@,
	ezchat_word "GRATEFUL", $3a6 ; どうも@@,
	ezchat_word "WASSUP?@", $3ee ; なんじゃ@,
	ezchat_word "HI@@@@@@", $42c ; ハーイ@@,
; rgbds 0.4.1 weird quirk where "," inside a string within a macro is parsed as if it's outside it
	db "YEA, YEA" ; はいはい@,
	dw $432
	db 0
	ezchat_word "BYE-BYE@", $434 ; バイバイ@,
	ezchat_word "HEY@@@@@", $48a ; へイ@@@,
	ezchat_word "SMELL@@@", $4de ; またね@@,
	ezchat_word "TUNED IN", $532 ; もしもし@,
	ezchat_word "HOO-HAH@", $53e ; やあ@@@,
	ezchat_word "YAHOO@@@", $54e ; やっほー@,
	ezchat_word "YO@@@@@@", $562 ; よう@@@,
	ezchat_word "GO OVER@", $564 ; ようこそ@,
	ezchat_word "COUNT ON", $580 ; よろしく@,
	ezchat_word "WELCOME@", $594 ; らっしゃい,

.People:
	ezchat_word "OPPONENT", $01c ; あいて@@,
	ezchat_word "I@@@@@@@", $036 ; あたし@@,
	ezchat_word "YOU@@@@@", $040 ; あなた@@,
	ezchat_word "YOURS@@@", $042 ; あなたが@,
	ezchat_word "SON@@@@@", $044 ; あなたに@,
	ezchat_word "YOUR@@@@", $046 ; あなたの@,
	ezchat_word "YOU'RE@@", $048 ; あなたは@,
	ezchat_word "YOU'VE@@", $04a ; あなたを@,
	ezchat_word "MOM@@@@@", $0e8 ; おかあさん,
	ezchat_word "GRANDPA@", $0fc ; おじいさん,
	ezchat_word "UNCLE@@@", $102 ; おじさん@,
	ezchat_word "DAD@@@@@", $10e ; おとうさん,
	ezchat_word "BOY@@@@@", $110 ; おとこのこ,
	ezchat_word "ADULT@@@", $114 ; おとな@@,
	ezchat_word "BROTHER@", $116 ; おにいさん,
	ezchat_word "SISTER@@", $118 ; おねえさん,
	ezchat_word "GRANDMA@", $11c ; おばあさん,
	ezchat_word "AUNT@@@@", $120 ; おばさん@,
	ezchat_word "ME@@@@@@", $134 ; おれさま@,
	ezchat_word "GIRL@@@@", $13a ; おんなのこ,
	ezchat_word "BABE@@@@", $140 ; ガール@@,
	ezchat_word "FAMILY@@", $152 ; かぞく@@,
	ezchat_word "HER@@@@@", $172 ; かのじょ@,
	ezchat_word "HIM@@@@@", $17c ; かれ@@@,
	ezchat_word "HE@@@@@@", $19a ; きみ@@@,
	ezchat_word "PLACE@@@", $19c ; きみが@@,
	ezchat_word "DAUGHTER", $19e ; きみに@@,
	ezchat_word "HIS@@@@@", $1a0 ; きみの@@,
	ezchat_word "HE'S@@@@", $1a2 ; きみは@@,
	ezchat_word "AREN'T@@", $1a4 ; きみを@@,
	ezchat_word "GAL@@@@@", $1ae ; ギャル@@,
	ezchat_word "SIBLINGS", $1b2 ; きょうだい,
	ezchat_word "CHILDREN", $1f0 ; こども@@,
	ezchat_word "MYSELF@@", $254 ; じぶん@@,
	ezchat_word "I WAS@@@", $256 ; じぶんが@,
	ezchat_word "TO ME@@@", $258 ; じぶんに@,
	ezchat_word "MY@@@@@@", $25a ; じぶんの@,
	ezchat_word "I AM@@@@", $25c ; じぶんは@,
	ezchat_word "I'VE@@@@", $25e ; じぶんを@,
	ezchat_word "WHO@@@@@", $318 ; だれ@@@,
	ezchat_word "SOMEONE@", $31a ; だれか@@,
	ezchat_word "WHO WAS@", $31c ; だれが@@,
	ezchat_word "TO WHOM@", $31e ; だれに@@,
	ezchat_word "WHOSE@@@", $320 ; だれの@@,
	ezchat_word "WHO IS@@", $322 ; だれも@@,
	ezchat_word "IT'S@@@@", $324 ; だれを@@,
	ezchat_word "LADY@@@@", $338 ; ちゃん@@,
	ezchat_word "FRIEND@@", $3b8 ; ともだち@,
	ezchat_word "ALLY@@@@", $3d4 ; なかま@@,
	ezchat_word "PEOPLE@@", $462 ; ひと@@@,
	ezchat_word "DUDE@@@@", $498 ; ボーイ@@,
	ezchat_word "THEY@@@@", $4a0 ; ボク@@@,
	ezchat_word "THEY ARE", $4a2 ; ボクが@@,
	ezchat_word "TO THEM@", $4a4 ; ボクに@@,
	ezchat_word "THEIR@@@", $4a6 ; ボクの@@,
	ezchat_word "THEY'RE@", $4a8 ; ボクは@@,
	ezchat_word "THEY'VE@", $4aa ; ボクを@@,
	ezchat_word "WE@@@@@@", $504 ; みんな@@,
	ezchat_word "BEEN@@@@", $506 ; みんなが@,
	ezchat_word "TO US@@@", $508 ; みんなに@,
	ezchat_word "OUR@@@@@", $50a ; みんなの@,
	ezchat_word "WE'RE@@@", $50c ; みんなは@,
	ezchat_word "RIVAL@@@", $58a ; ライバル@,
	ezchat_word "SHE@@@@@", $5c2 ; わたし@@,
	ezchat_word "SHE WAS@", $5c4 ; わたしが@,
	ezchat_word "TO HER@@", $5c6 ; わたしに@,
	ezchat_word "HERS@@@@", $5c8 ; わたしの@,
	ezchat_word "SHE IS@@", $5ca ; わたしは@,
	ezchat_word "SOME@@@@", $5cc ; わたしを@,

.Battle:
	ezchat_word "MATCH UP", $018 ; あいしょう,
	ezchat_word "GO!@@@@@", $088 ; いけ！@@,
	ezchat_word "NO. 1@@@", $096 ; いちばん@,
	ezchat_word "DECIDE@@", $14c ; かくご@@,
	ezchat_word "I WIN@@@", $154 ; かたせて@,
	ezchat_word "WINS@@@@", $156 ; かち@@@,
	ezchat_word "WIN@@@@@", $158 ; かつ@@@,
	ezchat_word "WON@@@@@", $160 ; かった@@,
	ezchat_word "IF I WIN", $162 ; かったら@,
	ezchat_word "I'LL WIN", $164 ; かって@@,
	ezchat_word "CANT WIN", $166 ; かてない@,
	ezchat_word "CAN WIN@", $168 ; かてる@@,
	ezchat_word "NO MATCH", $170 ; かなわない,
	ezchat_word "SPIRIT@@", $184 ; きあい@@,
	ezchat_word "DECIDED@", $1a8 ; きめた@@,
	ezchat_word "ACE CARD", $1b6 ; きりふだ@,
	ezchat_word "HI-YA!@@", $1c2 ; くらえ@@,
	ezchat_word "COME ON@", $1da ; こい！@@,
	ezchat_word "ATTACK@@", $1e0 ; こうげき@,
	ezchat_word "GIVE UP@", $1e2 ; こうさん@,
	ezchat_word "GUTS@@@@", $208 ; こんじょう,
	ezchat_word "TALENT@@", $216 ; さいのう@,
	ezchat_word "STRATEGY", $21a ; さくせん@,
	ezchat_word "SMITE@@@", $222 ; さばき@@,
	ezchat_word "MATCH@@@", $27e ; しょうぶ@,
	ezchat_word "VICTORY@", $280 ; しょうり@,
	ezchat_word "OFFENSE@", $2b4 ; せめ@@@,
	ezchat_word "SENSE@@@", $2b6 ; センス@@,
	ezchat_word "VERSUS@@", $2e6 ; たいせん@,
	ezchat_word "FIGHTS@@", $2f6 ; たたかい@,
	ezchat_word "POWER@@@", $332 ; ちから@@,
	ezchat_word "TASK@@@@", $336 ; チャレンジ,
	ezchat_word "STRONG@@", $358 ; つよい@@,
	ezchat_word "TOO MUCH", $35a ; つよすぎ@,
	ezchat_word "HARD@@@@", $35c ; つらい@@,
	ezchat_word "TERRIBLE", $35e ; つらかった,
	ezchat_word "GO EASY@", $36c ; てかげん@,
	ezchat_word "FOE@@@@@", $36e ; てき@@@,
	ezchat_word "GENIUS@@", $390 ; てんさい@,
	ezchat_word "LEGEND@@", $394 ; でんせつ@,
	ezchat_word "TRAINER@", $3c6 ; トレーナー,
	ezchat_word "ESCAPE@@", $404 ; にげ@@@,
	ezchat_word "LUKEWARM", $410 ; ぬるい@@,
	ezchat_word "AIM@@@@@", $416 ; ねらう@@,
	ezchat_word "BATTLE@@", $44a ; バトル@@,
	ezchat_word "FIGHT@@@", $472 ; ファイト@,
	ezchat_word "REVIVE@@", $478 ; ふっかつ@,
	ezchat_word "POINTS@@", $494 ; ポイント@,
	ezchat_word "POKÉMON@", $4ac ; ポケモン@,
	ezchat_word "SERIOUS@", $4bc ; ほんき@@,
	ezchat_word "OH NO!@@", $4c4 ; まいった！,
	ezchat_word "LOSS@@@@", $4c8 ; まけ@@@,
	ezchat_word "YOU LOSE", $4ca ; まけたら@,
	ezchat_word "LOST@@@@", $4cc ; まけて@@,
	ezchat_word "LOSE@@@@", $4ce ; まける@@,
	ezchat_word "GUARD@@@", $4ea ; まもり@@,
	ezchat_word "PARTNER@", $4f2 ; みかた@@,
	ezchat_word "REJECT@@", $4fe ; みとめない,
	ezchat_word "ACCEPT@@", $500 ; みとめる@,
	ezchat_word "UNBEATEN", $516 ; むてき@@,
	ezchat_word "GOT IT!@", $53c ; もらった！,
	ezchat_word "EASY@@@@", $57a ; よゆう@@,
	ezchat_word "WEAK@@@@", $582 ; よわい@@,
	ezchat_word "TOO WEAK", $584 ; よわすぎ@,
	ezchat_word "PUSHOVER", $58e ; らくしょう,
	ezchat_word "CHIEF@@@", $59e ; りーダー@,
	ezchat_word "RULE@@@@", $5a0 ; ルール@@,
	ezchat_word "LEVEL@@@", $5a6 ; レべル@@,
	ezchat_word "MOVE@@@@", $5be ; わざ@@@,

.Exclamations:
	ezchat_word "!@@@@@@@", $000 ; ！@@@@,
	ezchat_word "!!@@@@@@", $002 ; ！！@@@,
	ezchat_word "!?@@@@@@", $004 ; ！？@@@,
	ezchat_word "?@@@@@@@", $006 ; ？@@@@,
	ezchat_word "…@@@@@@@", $008 ; ⋯@@@@,
	ezchat_word "…!@@@@@@", $00a ; ⋯！@@@,
	ezchat_word "………@@@@@", $00c ; ⋯⋯⋯@@,
	ezchat_word "-@@@@@@@", $00e ; ー@@@@,
	ezchat_word "- - -@@@", $010 ; ーーー@@,
	ezchat_word "UH-OH@@@", $014 ; あーあ@@,
	ezchat_word "WAAAH@@@", $016 ; あーん@@,
	ezchat_word "AHAHA@@@", $052 ; あははー@,
	ezchat_word "OH?@@@@@", $054 ; あら@@@,
	ezchat_word "NOPE@@@@", $072 ; いえ@@@,
	ezchat_word "YES@@@@@", $074 ; イエス@@,
	ezchat_word "URGH@@@@", $0ac ; うう@@@,
	ezchat_word "HMM@@@@@", $0ae ; うーん@@,
	ezchat_word "WHOAH@@@", $0b0 ; うおー！@,
	ezchat_word "WROOAAR!", $0b2 ; うおりゃー,
	ezchat_word "WOW@@@@@", $0bc ; うひょー@,
	ezchat_word "GIGGLES@", $0be ; うふふ@@,
	ezchat_word "SHOCKING", $0ca ; うわー@@,
	ezchat_word "CRIES@@@", $0cc ; うわーん@,
	ezchat_word "AGREE@@@", $0d2 ; ええ@@@,
	ezchat_word "EH?@@@@@", $0d4 ; えー@@@,
	ezchat_word "CRY@@@@@", $0d6 ; えーん@@,
	ezchat_word "EHEHE@@@", $0dc ; えへへ@@,
	ezchat_word "HOLD ON!", $0e0 ; おいおい@,
	db "OH, YEAH" ; おお@@@,
	dw $0e2
	db 0
	ezchat_word "OOPS@@@@", $10c ; おっと@@,
	ezchat_word "SHOCKED@", $142 ; がーん@@,
	ezchat_word "EEK@@@@@", $1aa ; キャー@@,
	ezchat_word "GRAAAH@@", $1ac ; ギャー@@,
	ezchat_word "HE-HE-HE", $1bc ; ぐふふふふ,
	ezchat_word "ICK!@@@@", $1ce ; げっ@@@,
	ezchat_word "WEEP@@@@", $23e ; しくしく@,
	ezchat_word "HMPH@@@@", $32e ; ちえっ@@,
	ezchat_word "BLUSH@@@", $386 ; てへ@@@,
	ezchat_word "NO@@@@@@", $420 ; ノー@@@,
	ezchat_word "HUH?@@@@", $42a ; はあー@@,
	ezchat_word "YUP@@@@@", $430 ; はい@@@,
	ezchat_word "HAHAHA@@", $448 ; はっはっは,
	ezchat_word "AIYEEH@@", $456 ; ひいー@@,
	ezchat_word "HIYAH@@@", $46a ; ひゃあ@@,
	ezchat_word "FUFU@@@@", $47c ; ふっふっふ,
	ezchat_word "MUTTER@@", $47e ; ふにゃ@@,
	ezchat_word "LOL@@@@@", $480 ; ププ@@@,
	ezchat_word "SNORT@@@", $482 ; ふふん@@,
	ezchat_word "HUMPH@@@", $488 ; ふん@@@,
	ezchat_word "HEHEHE@@", $48e ; へっへっへ,
	ezchat_word "HEHE@@@@", $490 ; へへー@@,
	ezchat_word "HOHOHO@@", $49c ; ほーほほほ,
	ezchat_word "UH-HUH@@", $4b6 ; ほら@@@,
	db "OH, DEAR" ; まあ@@@,
	dw $4c0
	db 0
	ezchat_word "ARRGH!@@", $510 ; むきー！！,
	ezchat_word "MUFU@@@@", $518 ; むふー@@,
	ezchat_word "MUFUFU@@", $51a ; むふふ@@,
	ezchat_word "MMM@@@@@", $51c ; むむ@@@,
	ezchat_word "OH-KAY@@", $56a ; よーし@@,
	ezchat_word "OKAY!@@@", $572 ; よし！@@,
	ezchat_word "LALALA@@", $598 ; ラララ@@,
	ezchat_word "YAY@@@@@", $5ac ; わーい@@,
	ezchat_word "AWW!@@@@", $5b0 ; わーん！！,
	ezchat_word "WOWEE@@@", $5b2 ; ワオ@@@,
	ezchat_word "GWAH!@@@", $5ce ; わっ！！@,
	ezchat_word "WAHAHA!@", $5d0 ; わははは！,

.Conversation:
	ezchat_word "LISTEN@@", $050 ; あのね@@,
	ezchat_word "NOT VERY", $06e ; あんまり@,
	ezchat_word "MEAN@@@@", $08e ; いじわる@,
	ezchat_word "LIE@@@@@", $0b6 ; うそ@@@,
	ezchat_word "LAY@@@@@", $0c4 ; うむ@@@,
	ezchat_word "OI@@@@@@", $0e4 ; おーい@@,
	ezchat_word "SUGGEST@", $106 ; おすすめ@,
	ezchat_word "NITWIT@@", $11e ; おばかさん,
	ezchat_word "QUITE@@@", $16e ; かなり@@,
	ezchat_word "FROM@@@@", $17a ; から@@@,
	ezchat_word "FEELING@", $198 ; きぶん@@,
	ezchat_word "BUT@@@@@", $1d6 ; けど@@@,
	ezchat_word "HOWEVER@", $1ea ; こそ@@@,
	ezchat_word "CASE@@@@", $1ee ; こと@@@,
	ezchat_word "MISS@@@@", $212 ; さあ@@@,
	ezchat_word "HOW@@@@@", $21e ; さっぱり@,
	ezchat_word "HIT@@@@@", $220 ; さて@@@,
	ezchat_word "ENOUGH@@", $272 ; じゅうぶん,
	ezchat_word "SOON@@@@", $294 ; すぐ@@@,
	ezchat_word "A LOT@@@", $298 ; すごく@@,
	ezchat_word "A LITTLE", $29a ; すこしは@,
	ezchat_word "AMAZING@", $2a0 ; すっっごい,
	ezchat_word "ENTIRELY", $2b0 ; ぜーんぜん,
	ezchat_word "FULLY@@@", $2b2 ; ぜったい@,
	ezchat_word "AND SO@@", $2ce ; それで@@,
	ezchat_word "ONLY@@@@", $2f2 ; だけ@@@,
	ezchat_word "AROUND@@", $2fc ; だって@@,
	ezchat_word "PROBABLY", $306 ; たぶん@@,
	ezchat_word "IF@@@@@@", $314 ; たら@@@,
	ezchat_word "VERY@@@@", $33a ; ちょー@@,
	ezchat_word "A BIT@@@", $33c ; ちょっと@,
	ezchat_word "WILD@@@@", $34e ; ったら@@,
	ezchat_word "THAT'S@@", $350 ; って@@@,
	ezchat_word "I MEAN@@", $362 ; ていうか@,
	db "EVEN SO," ; でも@@@,
	dw $388
	db 0
	ezchat_word "MUST BE@", $39c ; どうしても,
	ezchat_word "NATURALY", $3a0 ; とうぜん@,
	ezchat_word "GO AHEAD", $3a2 ; どうぞ@@,
	db "FOR NOW," ; とりあえず,
	dw $3be
	db 0
	ezchat_word "HEY?@@@@", $3cc ; なあ@@@,
	ezchat_word "JOKING@@", $3f4 ; なんて@@,
	ezchat_word "READY@@@", $3fc ; なんでも@,
	ezchat_word "SOMEHOW@", $3fe ; なんとか@,
	ezchat_word "ALTHOUGH", $408 ; には@@@,
	ezchat_word "PERFECT@", $446 ; バッチり@,
	ezchat_word "FIRMLY@@", $452 ; ばりばり@,
	ezchat_word "EQUAL TO", $4b0 ; ほど@@@,
	ezchat_word "REALLY@@", $4be ; ほんと@@,
	ezchat_word "TRULY@@@", $4d0 ; まさに@@,
	ezchat_word "SURELY@@", $4d2 ; マジ@@@,
	ezchat_word "FOR SURE", $4d4 ; マジで@@,
	ezchat_word "TOTALLY@", $4e4 ; まったく@,
	ezchat_word "UNTIL@@@", $4e6 ; まで@@@,
	ezchat_word "AS IF@@@", $4ec ; まるで@@,
	ezchat_word "MOOD@@@@", $50e ; ムード@@,
	ezchat_word "RATHER@@", $514 ; むしろ@@,
	ezchat_word "NO WAY@@", $524 ; めちゃ@@,
	ezchat_word "AWFULLY@", $528 ; めっぽう@,
	ezchat_word "ALMOST@@", $52c ; もう@@@,
	ezchat_word "MODE@@@@", $52e ; モード@@,
	ezchat_word "MORE@@@@", $536 ; もっと@@,
	ezchat_word "TOO LATE", $538 ; もはや@@,
	ezchat_word "FINALLY@", $54a ; やっと@@,
	ezchat_word "ANY@@@@@", $54c ; やっぱり@,
	ezchat_word "INSTEAD@", $57c ; より@@@,
	ezchat_word "TERRIFIC", $5a4 ; れば@@@,

.Feelings:
	ezchat_word "MEET@@@@", $01a ; あいたい@,
	ezchat_word "PLAY@@@@", $032 ; あそびたい,
	ezchat_word "GOES@@@@", $07c ; いきたい@,
	ezchat_word "GIDDY@@@", $0b4 ; うかれて@,
	ezchat_word "HAPPY@@@", $0c6 ; うれしい@,
	ezchat_word "GLEE@@@@", $0c8 ; うれしさ@,
	ezchat_word "EXCITE@@", $0d8 ; エキサイト,
	ezchat_word "CRUCIAL@", $0de ; えらい@@,
	ezchat_word "FUNNY@@@", $0ec ; おかしい@,
	ezchat_word "GOT@@@@@", $108 ; オッケー@,
	ezchat_word "GO HOME@", $148 ; かえりたい,
	ezchat_word "FAILS@@@", $15a ; がっくし@,
	ezchat_word "SAD@@@@@", $16c ; かなしい@,
	ezchat_word "TRY@@@@@", $180 ; がんばって,
	ezchat_word "HEARS@@@", $186 ; きがしない,
	ezchat_word "THINK@@@", $188 ; きがする@,
	ezchat_word "HEAR@@@@", $18a ; ききたい@,
	ezchat_word "WANTS@@@", $190 ; きになる@,
	ezchat_word "MISHEARD", $196 ; きのせい@,
	ezchat_word "DISLIKE@", $1b4 ; きらい@@,
	ezchat_word "ANGRY@@@", $1be ; くやしい@,
	ezchat_word "ANGER@@@", $1c0 ; くやしさ@,
	ezchat_word "LONESOME", $224 ; さみしい@,
	ezchat_word "FAIL@@@@", $232 ; ざんねん@,
	ezchat_word "JOY@@@@@", $236 ; しあわせ@,
	ezchat_word "GETS@@@@", $244 ; したい@@,
	ezchat_word "NEVER@@@", $246 ; したくない,
	ezchat_word "DARN@@@@", $264 ; しまった@,
	ezchat_word "DOWNCAST", $282 ; しょんぼり,
	ezchat_word "LIKES@@@", $292 ; すき@@@,
	ezchat_word "DISLIKES", $2da ; だいきらい,
	ezchat_word "BORING@@", $2dc ; たいくつ@,
	ezchat_word "CARE@@@@", $2de ; だいじ@@,
	ezchat_word "ADORE@@@", $2e4 ; だいすき@,
	ezchat_word "DISASTER", $2ea ; たいへん@,
	ezchat_word "ENJOY@@@", $300 ; たのしい@,
	ezchat_word "ENJOYS@@", $302 ; たのしすぎ,
	ezchat_word "EAT@@@@@", $308 ; たべたい@,
	ezchat_word "USELESS@", $30e ; ダメダメ@,
	ezchat_word "LACKING@", $316 ; たりない@,
	ezchat_word "BAD@@@@@", $334 ; ちくしょー,
	ezchat_word "SHOULD@@", $39e ; どうしよう,
	ezchat_word "EXCITING", $3ac ; ドキドキ@,
	ezchat_word "NICE@@@@", $3d0 ; ナイス@@,
	ezchat_word "DRINK@@@", $426 ; のみたい@,
	ezchat_word "SURPRISE", $460 ; びっくり@,
	ezchat_word "FEAR@@@@", $474 ; ふあん@@,
	ezchat_word "WOBBLY@@", $486 ; ふらふら@,
	ezchat_word "WANT@@@@", $4ae ; ほしい@@,
	ezchat_word "SHREDDED", $4b8 ; ボロボロ@,
	ezchat_word "YET@@@@@", $4e0 ; まだまだ@,
	ezchat_word "WAIT@@@@", $4e8 ; まてない@,
	ezchat_word "CONTENT@", $4f0 ; まんぞく@,
	ezchat_word "SEE@@@@@", $4f8 ; みたい@@,
	ezchat_word "RARE@@@@", $522 ; めずらしい,
	ezchat_word "FIERY@@@", $52a ; メラメラ@,
	ezchat_word "NEGATIVE", $546 ; やだ@@@,
	ezchat_word "DONE@@@@", $548 ; やったー@,
	ezchat_word "DANGER@@", $550 ; やばい@@,
	ezchat_word "DONE FOR", $552 ; やばすぎる,
	ezchat_word "DEFEATED", $554 ; やられた@,
	ezchat_word "BEAT@@@@", $556 ; やられて@,
	ezchat_word "GREAT@@@", $56e ; よかった@,
	ezchat_word "DOTING@@", $596 ; ラブラブ@,
	ezchat_word "ROMANTIC", $5a8 ; ロマン@@,
	ezchat_word "QUESTION", $5aa ; ろんがい@,
	ezchat_word "REALIZE@", $5b4 ; わから@@,
	ezchat_word "REALIZES", $5b6 ; わかり@@,
	ezchat_word "SUSPENSE", $5ba ; わくわく@,

.Conditions:
	ezchat_word "HOT@@@@@", $038 ; あつい@@,
	ezchat_word "EXISTS@@", $03a ; あった@@,
	ezchat_word "APPROVED", $056 ; あり@@@,
	ezchat_word "HAS@@@@@", $05e ; ある@@@,
	ezchat_word "HURRIED@", $06a ; あわてて@,
	ezchat_word "GOOD@@@@", $070 ; いい@@@,
	ezchat_word "LESS@@@@", $076 ; いか@@@,
	ezchat_word "MEGA@@@@", $078 ; イカス@@,
	ezchat_word "MOMENTUM", $07a ; いきおい@,
	ezchat_word "GOING@@@", $08a ; いける@@,
	ezchat_word "WEIRD@@@", $08c ; いじょう@,
	ezchat_word "BUSY@@@@", $090 ; いそがしい,
	ezchat_word "TOGETHER", $09a ; いっしょに,
	ezchat_word "FULL@@@@", $09c ; いっぱい@,
	ezchat_word "ABSENT@@", $0a0 ; いない@@,
	ezchat_word "BEING@@@", $0a4 ; いや@@@,
	ezchat_word "NEED@@@@", $0a8 ; いる@@@,
	ezchat_word "TASTY@@@", $0c0 ; うまい@@,
	ezchat_word "SKILLED@", $0c2 ; うまく@@,
	ezchat_word "BIG@@@@@", $0e6 ; おおきい@,
	ezchat_word "LATE@@@@", $0f2 ; おくれ@@,
	ezchat_word "CLOSE@@@", $0fa ; おしい@@,
	ezchat_word "AMUSING@", $12c ; おもしろい,
	ezchat_word "ENGAGING", $12e ; おもしろく,
	ezchat_word "COOL@@@@", $15c ; かっこいい,
	ezchat_word "CUTE@@@@", $17e ; かわいい@,
	ezchat_word "FLAWLESS", $182 ; かんぺき@,
	ezchat_word "PRETTY@@", $1d0 ; けっこう@,
	ezchat_word "HEALTHY@", $1d8 ; げんき@@,
	ezchat_word "SCARY@@@", $206 ; こわい@@,
	ezchat_word "SUPERB@@", $214 ; さいこう@,
	ezchat_word "COLD@@@@", $226 ; さむい@@,
	ezchat_word "LIVELY@@", $22c ; さわやか@,
	ezchat_word "FATED@@@", $238 ; しかたない,
	ezchat_word "MUCH@@@@", $296 ; すごい@@,
	ezchat_word "IMMENSE@", $29c ; すごすぎ@,
	ezchat_word "FABULOUS", $2a4 ; すてき@@,
	ezchat_word "ELSE@@@@", $2e0 ; たいした@,
	ezchat_word "ALRIGHT@", $2e2 ; だいじょぶ,
	ezchat_word "COSTLY@@", $2ec ; たかい@@,
	ezchat_word "CORRECT@", $2f8 ; ただしい@,
	ezchat_word "UNLIKELY", $30c ; だめ@@@,
	ezchat_word "SMALL@@@", $32c ; ちいさい@,
	ezchat_word "VARIED@@", $330 ; ちがう@@,
	ezchat_word "TIRED@@@", $348 ; つかれ@@,
	ezchat_word "SKILL@@@", $3b0 ; とくい@@,
	ezchat_word "NON-STOP", $3b6 ; とまらない,
	ezchat_word "NONE@@@@", $3ce ; ない@@@,
	ezchat_word "NOTHING@", $3d2 ; なかった@,
	ezchat_word "NATURAL@", $3d8 ; なし@@@,
	ezchat_word "BECOMES@", $3dc ; なって@@,
	ezchat_word "FAST@@@@", $450 ; はやい@@,
	ezchat_word "SHINE@@@", $45a ; ひかる@@,
	ezchat_word "LOW@@@@@", $45c ; ひくい@@,
	ezchat_word "AWFUL@@@", $464 ; ひどい@@,
	ezchat_word "ALONE@@@", $466 ; ひとりで@,
	ezchat_word "BORED@@@", $468 ; ひま@@@,
	ezchat_word "LACKS@@@", $476 ; ふそく@@,
	ezchat_word "LOUSY@@@", $48c ; へた@@@,
	ezchat_word "MISTAKE@", $4e2 ; まちがって,
	ezchat_word "KIND@@@@", $542 ; やさしい@,
	ezchat_word "WELL@@@@", $570 ; よく@@@,
	ezchat_word "WEAKENED", $586 ; よわって@,
	ezchat_word "SIMPLE@@", $58c ; らく@@@,
	ezchat_word "SEEMS@@@", $590 ; らしい@@,
	ezchat_word "BADLY@@@", $5d4 ; わるい@@,

.Life:
	ezchat_word "CHORES@@", $064 ; アルバイト,
	ezchat_word "HOME@@@@", $0ba ; うち@@@,
	ezchat_word "MONEY@@@", $0ee ; おかね@@,
	ezchat_word "SAVINGS@", $0f4 ; おこづかい,
	ezchat_word "BATH@@@@", $124 ; おふろ@@,
	ezchat_word "SCHOOL@@", $15e ; がっこう@,
	ezchat_word "REMEMBER", $192 ; きねん@@,
	ezchat_word "GROUP@@@", $1c6 ; グループ@,
	ezchat_word "GOTCHA@@", $1d2 ; ゲット@@,
	ezchat_word "EXCHANGE", $1de ; こうかん@,
	ezchat_word "WORK@@@@", $240 ; しごと@@,
	ezchat_word "TRAINING", $274 ; しゅぎょう,
	ezchat_word "CLASS@@@", $276 ; じゅぎょう,
	ezchat_word "LESSONS@", $278 ; じゅく@@,
	ezchat_word "EVOLVE@@", $288 ; しんか@@,
	ezchat_word "HANDBOOK", $290 ; ずかん@@,
	ezchat_word "LIVING@@", $2ae ; せいかつ@,
	ezchat_word "TEACHER@", $2b8 ; せんせい@,
	ezchat_word "CENTER@@", $2ba ; センター@,
	ezchat_word "TOWER@@@", $328 ; タワー@@,
	ezchat_word "LINK@@@@", $340 ; つうしん@,
	ezchat_word "TEST@@@@", $37e ; テスト@@,
	ezchat_word "TV@@@@@@", $38c ; テレビ@@,
	ezchat_word "PHONE@@@", $396 ; でんわ@@,
	ezchat_word "ITEM@@@@", $39a ; どうぐ@@,
	ezchat_word "TRADE@@@", $3c4 ; トレード@,
	ezchat_word "NAME@@@@", $3e8 ; なまえ@@,
	ezchat_word "NEWS@@@@", $40a ; ニュース@,
	ezchat_word "POPULAR@", $40c ; にんき@@,
	ezchat_word "PARTY@@@", $42e ; パーティー,
	ezchat_word "STUDY@@@", $492 ; べんきょう,
	ezchat_word "MACHINE@", $4d6 ; マシン@@,
	ezchat_word "CARD@@@@", $51e ; めいし@@,
	ezchat_word "MESSAGE@", $526 ; メッセージ,
	ezchat_word "MAKEOVER", $53a ; もようがえ,
	ezchat_word "DREAM@@@", $55a ; ゆめ@@@,
	ezchat_word "DAY CARE", $566 ; ようちえん,
	ezchat_word "RADIO@@@", $592 ; ラジオ@@,
	ezchat_word "WORLD@@@", $5ae ; ワールド@,

.Hobbies:
	ezchat_word "IDOL@@@@", $01e ; アイドル@,
	ezchat_word "ANIME@@@", $04c ; アニメ@@,
	ezchat_word "SONG@@@@", $0b8 ; うた@@@,
	ezchat_word "MOVIE@@@", $0d0 ; えいが@@,
	ezchat_word "CANDY@@@", $0ea ; おかし@@,
	ezchat_word "CHAT@@@@", $104 ; おしゃべり,
	ezchat_word "TOYHOUSE", $128 ; おままごと,
	ezchat_word "TOYS@@@@", $130 ; おもちゃ@,
	ezchat_word "MUSIC@@@", $138 ; おんがく@,
	ezchat_word "CARDS@@@", $13e ; カード@@,
	ezchat_word "SHOPPING", $146 ; かいもの@,
	ezchat_word "GOURMET@", $1c8 ; グルメ@@,
	ezchat_word "GAME@@@@", $1cc ; ゲーム@@,
	ezchat_word "MAGAZINE", $21c ; ざっし@@,
	ezchat_word "WALK@@@@", $234 ; さんぽ@@,
	ezchat_word "BIKE@@@@", $250 ; じてんしゃ,
	ezchat_word "HOBBIES@", $27a ; しゅみ@@,
	ezchat_word "SPORTS@@", $2a8 ; スポーツ@,
	ezchat_word "DIET@@@@", $2d8 ; ダイエット,
	ezchat_word "TREASURE", $2f0 ; たからもの,
	ezchat_word "TRAVEL@@", $304 ; たび@@@,
	ezchat_word "DANCE@@@", $32a ; ダンス@@,
	ezchat_word "FISHING@", $360 ; つり@@@,
	ezchat_word "DATE@@@@", $36a ; デート@@,
	ezchat_word "TRAIN@@@", $392 ; でんしゃ@,
	ezchat_word "PLUSHIE@", $40e ; ぬいぐるみ,
	ezchat_word "PC@@@@@@", $43e ; パソコン@,
	ezchat_word "FLOWERS@", $44c ; はな@@@,
	ezchat_word "HERO@@@@", $458 ; ヒーロー@,
	ezchat_word "NAP@@@@@", $46e ; ひるね@@,
	ezchat_word "HEROINE@", $470 ; ヒロイン@,
	ezchat_word "JOURNEY@", $496 ; ぼうけん@,
	ezchat_word "BOARD@@@", $49a ; ボード@@,
	ezchat_word "BALL@@@@", $49e ; ボール@@,
	ezchat_word "BOOK@@@@", $4ba ; ほん@@@,
	ezchat_word "MANGA@@@", $4ee ; マンガ@@,
	ezchat_word "PROMISE@", $540 ; やくそく@,
	ezchat_word "HOLIDAY@", $544 ; やすみ@@,
	ezchat_word "PLANS@@@", $574 ; よてい@@,

.Actions:
	ezchat_word "MEETS@@@", $020 ; あう@@@,
	ezchat_word "CONCEDE@", $024 ; あきらめ@,
	ezchat_word "GIVE@@@@", $028 ; あげる@@,
	ezchat_word "GIVES@@@", $02e ; あせる@@,
	ezchat_word "PLAYED@@", $030 ; あそび@@,
	ezchat_word "PLAYS@@@", $034 ; あそぶ@@,
	ezchat_word "COLLECT@", $03e ; あつめ@@,
	ezchat_word "WALKING@", $060 ; あるき@@,
	ezchat_word "WALKS@@@", $062 ; あるく@@,
	ezchat_word "WENT@@@@", $07e ; いく@@@,
	ezchat_word "GO@@@@@@", $086 ; いけ@@@,
	ezchat_word "WAKE UP@", $0f0 ; おき@@@,
	ezchat_word "WAKES UP", $0f6 ; おこり@@,
	ezchat_word "ANGERS@@", $0f8 ; おこる@@,
	ezchat_word "TEACH@@@", $0fe ; おしえ@@,
	ezchat_word "TEACHES@", $100 ; おしえて@,
	ezchat_word "PLEASE@@", $11a ; おねがい@,
	ezchat_word "LEARN@@@", $126 ; おぼえ@@,
	ezchat_word "CHANGE@@", $14a ; かえる@@,
	ezchat_word "TRUST@@@", $174 ; がまん@@,
	ezchat_word "HEARING@", $18c ; きく@@@,
	ezchat_word "TRAINS@@", $18e ; きたえ@@,
	ezchat_word "CHOOSE@@", $1a6 ; きめ@@@,
	ezchat_word "COME@@@@", $1c4 ; くる@@@,
	ezchat_word "SEARCH@@", $218 ; さがし@@,
	ezchat_word "CAUSE@@@", $22a ; さわぎ@@,
	ezchat_word "THESE@@@", $242 ; した@@@,
	ezchat_word "KNOW@@@@", $24a ; しって@@,
	ezchat_word "KNOWS@@@", $24e ; して@@@,
	ezchat_word "REFUSE@@", $252 ; しない@@,
	ezchat_word "STORES@@", $260 ; しまう@@,
	ezchat_word "BRAG@@@@", $266 ; じまん@@,
	ezchat_word "IGNORANT", $284 ; しらない@,
	ezchat_word "THINKS@@", $286 ; しる@@@,
	ezchat_word "BELIEVE@", $28a ; しんじて@,
	ezchat_word "SLIDE@@@", $2aa ; する@@@,
	ezchat_word "EATS@@@@", $30a ; たべる@@,
	ezchat_word "USE@@@@@", $342 ; つかう@@,
	ezchat_word "USES@@@@", $344 ; つかえ@@,
	ezchat_word "USING@@@", $346 ; つかって@,
	ezchat_word "COULDN'T", $370 ; できない@,
	ezchat_word "CAPABLE@", $372 ; できる@@,
	ezchat_word "VANISH@@", $384 ; でない@@,
	ezchat_word "APPEAR@@", $38a ; でる@@@,
	ezchat_word "THROW@@@", $3d6 ; なげる@@,
	ezchat_word "WORRY@@@", $3ea ; なやみ@@,
	ezchat_word "SLEPT@@@", $418 ; ねられ@@,
	ezchat_word "SLEEP@@@", $41a ; ねる@@@,
	ezchat_word "RELEASE@", $424 ; のがし@@,
	ezchat_word "DRINKS@@", $428 ; のむ@@@,
	ezchat_word "RUNS@@@@", $43a ; はしり@@,
	ezchat_word "RUN@@@@@", $43c ; はしる@@,
	ezchat_word "WORKS@@@", $440 ; はたらき@,
	ezchat_word "WORKING@", $442 ; はたらく@,
	ezchat_word "SINK@@@@", $44e ; はまって@,
	ezchat_word "SMACK@@@", $47a ; ぶつけ@@,
	ezchat_word "PRAISE@@", $4b4 ; ほめ@@@,
	ezchat_word "SHOW@@@@", $4f6 ; みせて@@,
	ezchat_word "LOOKS@@@", $4fc ; みて@@@,
	ezchat_word "SEES@@@@", $502 ; みる@@@,
	ezchat_word "SEEK@@@@", $520 ; めざす@@,
	ezchat_word "OWN@@@@@", $534 ; もって@@,
	ezchat_word "TAKE@@@@", $558 ; ゆずる@@,
	ezchat_word "ALLOW@@@", $55c ; ゆるす@@,
	ezchat_word "FORGET@@", $55e ; ゆるせ@@,
	ezchat_word "FORGETS@", $59a ; られない@,
	ezchat_word "APPEARS@", $59c ; られる@@,
	ezchat_word "FAINT@@@", $5b8 ; わかる@@,
	ezchat_word "FAINTED@", $5c0 ; わすれ@@,

.Time:
	ezchat_word "FALL@@@@", $022 ; あき@@@,
	ezchat_word "MORNING@", $02a ; あさ@@@,
	ezchat_word "TOMORROW", $02c ; あした@@,
	ezchat_word "DAY@@@@@", $094 ; いちにち@,
	ezchat_word "SOMETIME", $098 ; いつか@@,
	ezchat_word "ALWAYS@@", $09e ; いつも@@,
	ezchat_word "CURRENT@", $0a2 ; いま@@@,
	ezchat_word "FOREVER@", $0ce ; えいえん@,
	ezchat_word "DAYS@@@@", $112 ; おととい@,
	ezchat_word "END@@@@@", $136 ; おわり@@,
	ezchat_word "TUESDAY@", $178 ; かようび@,
	ezchat_word "Y'DAY@@@", $194 ; きのう@@,
	ezchat_word "TODAY@@@", $1b0 ; きょう@@,
	ezchat_word "FRIDAY@@", $1b8 ; きんようび,
	ezchat_word "MONDAY@@", $1d4 ; げつようび,
	ezchat_word "LATER@@@", $1f4 ; このあと@,
	ezchat_word "EARLIER@", $1f6 ; このまえ@,
	ezchat_word "ANOTHER@", $20c ; こんど@@,
	ezchat_word "TIME@@@@", $23c ; じかん@@,
	ezchat_word "DECADE@@", $270 ; じゅうねん,
	ezchat_word "WEDNSDAY", $28e ; すいようび,
	ezchat_word "START@@@", $29e ; スタート@,
	ezchat_word "MONTH@@@", $2a2 ; ずっと@@,
	ezchat_word "STOP@@@@", $2a6 ; ストップ@,
	ezchat_word "NOW@@@@@", $2c4 ; そのうち@,
	ezchat_word "FINAL@@@", $33e ; ついに@@,
	ezchat_word "NEXT@@@@", $34a ; つぎ@@@,
	ezchat_word "SATURDAY", $3ba ; どようび@,
	ezchat_word "SUMMER@@", $3da ; なつ@@@,
	ezchat_word "SUNDAY@@", $406 ; にちようび,
	ezchat_word "OUTSET@@", $438 ; はじめ@@,
	ezchat_word "SPRING@@", $454 ; はる@@@,
	ezchat_word "DAYTIME@", $46c ; ひる@@@,
	ezchat_word "WINTER@@", $484 ; ふゆ@@@,
	ezchat_word "DAILY@@@", $4c6 ; まいにち@,
	ezchat_word "THURSDAY", $530 ; もくようび,
	ezchat_word "NITETIME", $576 ; よなか@@,
	ezchat_word "NIGHT@@@", $57e ; よる@@@,
	ezchat_word "WEEK@@@@", $588 ; らいしゅう,

.Farewells:
	ezchat_word "WILL@@@@", $092 ; いたします,
	ezchat_word "AYE@@@@@", $132 ; おります@,
	ezchat_word "?!@@@@@@", $13c ; か！？@@,
	ezchat_word "HM?@@@@@", $144 ; かい？@@,
	ezchat_word "Y'THINK?", $150 ; かしら？@,
	ezchat_word "IS IT?@@", $16a ; かな？@@,
	ezchat_word "BE@@@@@@", $176 ; かも@@@,
	ezchat_word "GIMME@@@", $1ca ; くれ@@@,
	ezchat_word "COULD@@@", $1e8 ; ございます,
	ezchat_word "TEND TO@", $23a ; しがち@@,
	ezchat_word "WOULD@@@", $262 ; します@@,
	ezchat_word "IS@@@@@@", $26a ; じゃ@@@,
	ezchat_word "ISNT IT?", $26e ; じゃん@@,
	ezchat_word "LET'S@@@", $27c ; しよう@@,
	ezchat_word "OTHER@@@", $2ac ; ぜ！@@@,
	ezchat_word "ARE@@@@@", $2bc ; ぞ！@@@,
	ezchat_word "WAS@@@@@", $2d4 ; た@@@@,
	ezchat_word "WERE@@@@", $2d6 ; だ@@@@,
	ezchat_word "THOSE@@@", $2ee ; だからね@,
	ezchat_word "ISN'T@@@", $2f4 ; だぜ@@@,
	ezchat_word "WON'T@@@", $2fa ; だった@@,
	ezchat_word "CAN'T@@@", $2fe ; だね@@@,
	ezchat_word "CAN@@@@@", $310 ; だよ@@@,
	ezchat_word "DON'T@@@", $312 ; だよねー！,
	ezchat_word "DO@@@@@@", $326 ; だわ@@@,
	ezchat_word "DOES@@@@", $34c ; ッス@@@,
	ezchat_word "WHOM@@@@", $352 ; ってかんじ,
	ezchat_word "WHICH@@@", $354 ; っぱなし@,
	ezchat_word "WASN'T@@", $356 ; つもり@@,
	ezchat_word "WEREN'T@", $364 ; ていない@,
	ezchat_word "HAVE@@@@", $366 ; ている@@,
	ezchat_word "HAVEN'T@", $368 ; でーす！@,
	ezchat_word "A@@@@@@@", $374 ; でした@@,
	ezchat_word "AN@@@@@@", $376 ; でしょ？@,
	ezchat_word "NOT@@@@@", $378 ; でしょー！,
	ezchat_word "THERE@@@", $37a ; です@@@,
	ezchat_word "OK?@@@@@", $37c ; ですか？@,
	ezchat_word "SO@@@@@@", $380 ; ですよ@@,
	ezchat_word "MAYBE@@@", $382 ; ですわ@@,
	ezchat_word "ABOUT@@@", $3a4 ; どうなの？,
	ezchat_word "OVER@@@@", $3a8 ; どうよ？@,
	ezchat_word "IT@@@@@@", $3aa ; とかいって,
	ezchat_word "FOR@@@@@", $3e0 ; なの@@@,
	ezchat_word "ON@@@@@@", $3e2 ; なのか@@,
	ezchat_word "OFF@@@@@", $3e4 ; なのだ@@,
	ezchat_word "AS@@@@@@", $3e6 ; なのよ@@,
	ezchat_word "TO@@@@@@", $3f2 ; なんだね@,
	ezchat_word "WITH@@@@", $3f8 ; なんです@,
	ezchat_word "BETTER@@", $3fa ; なんてね@,
	ezchat_word "EVER@@@@", $412 ; ね@@@@,
	ezchat_word "SINCE@@@", $414 ; ねー@@@,
	ezchat_word "OF@@@@@@", $41c ; の@@@@,
	ezchat_word "BELONG@@", $41e ; の？@@@,
	ezchat_word "AT@@@@@@", $444 ; ばっかり@,
	ezchat_word "IN@@@@@@", $4c2 ; まーす！@,
	ezchat_word "OUT@@@@@", $4d8 ; ます@@@,
	ezchat_word "TOO@@@@@", $4da ; ますわ@@,
	ezchat_word "LIKE@@@@", $4dc ; ません@@,
	ezchat_word "DID@@@@@", $4fa ; みたいな@,
	ezchat_word "WITHOUT@", $560 ; よ！@@@,
	ezchat_word "AFTER@@@", $568 ; よー@@@,
	ezchat_word "BEFORE@@", $56c ; よーん@@,
	ezchat_word "WHILE@@@", $578 ; よね@@@,
	ezchat_word "THAN@@@@", $5a2 ; るよ@@@,
	ezchat_word "ONCE@@@@", $5bc ; わけ@@@,
	ezchat_word "ANYWHERE", $5d2 ; わよ！@@,

.ThisAndThat:
	ezchat_word "HIGHS@@@", $012 ; ああ@@@,
	ezchat_word "LOWS@@@@", $03c ; あっち@@,
	ezchat_word "UM@@@@@@", $04e ; あの@@@,
	ezchat_word "REAR@@@@", $05c ; ありゃ@@,
	ezchat_word "THINGS@@", $066 ; あれ@@@,
	ezchat_word "THING@@@", $068 ; あれは@@,
	ezchat_word "BELOW@@@", $06c ; あんな@@,
	ezchat_word "HIGH@@@@", $1dc ; こう@@@,
	ezchat_word "HERE@@@@", $1ec ; こっち@@,
	ezchat_word "INSIDE@@", $1f2 ; この@@@,
	ezchat_word "OUTSIDE@", $1fe ; こりゃ@@,
	ezchat_word "BESIDE@@", $200 ; これ@@@,
	ezchat_word "THIS ONE", $202 ; これだ！@,
	ezchat_word "THIS@@@@", $204 ; これは@@,
	ezchat_word "EVERY@@@", $20e ; こんな@@,
	ezchat_word "SEEMS SO", $2be ; そう@@@,
	ezchat_word "DOWN@@@@", $2c0 ; そっち@@,
	ezchat_word "THAT@@@@", $2c2 ; その@@@,
	ezchat_word "THAT IS@", $2c6 ; そりゃ@@,
	ezchat_word "THAT ONE", $2c8 ; それ@@@,
	ezchat_word "THATS IT", $2cc ; それだ！@,
	ezchat_word "THAT'S..", $2d0 ; それは@@,
	ezchat_word "THAT WAS", $2d2 ; そんな@@,
	ezchat_word "UP@@@@@@", $398 ; どう@@@,
	ezchat_word "CHOICE@@", $3b2 ; どっち@@,
	ezchat_word "FAR@@@@@", $3b4 ; どの@@@,
	ezchat_word "AWAY@@@@", $3c0 ; どりゃ@@,
	ezchat_word "NEAR@@@@", $3c2 ; どれ@@@,
	ezchat_word "WHERE@@@", $3c8 ; どれを@@,
	ezchat_word "WHEN@@@@", $3ca ; どんな@@,
	ezchat_word "WHAT@@@@", $3de ; なに@@@,
	ezchat_word "DEEP@@@@", $3ec ; なんか@@,
	ezchat_word "SHALLOW@", $3f0 ; なんだ@@,
	ezchat_word "WHY@@@@@", $3f6 ; なんで@@,
	ezchat_word "CONFUSED", $400 ; なんなんだ,
	ezchat_word "OPPOSITE", $402 ; なんの@@,

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
	macro_11f23c $09 ; end = MISC
.End
