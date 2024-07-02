Function17c000:
	call DisableLCD

	ld hl, vTiles2
	ld bc, $31 tiles
	xor a
	call ByteFill

	call LoadStandardFont
	call LoadFontsExtra

	ld hl, HaveWantMap
	decoord 0, 0
	bccoord 0, 0, wAttrmap

	ld a, SCREEN_HEIGHT
.y
	push af
	ld a, SCREEN_WIDTH

	push hl
.x
	push af
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [bc], a
	inc bc
	pop af
	dec a
	jr nz, .x
	pop hl

	push bc
	ld bc, BG_MAP_WIDTH * 2
	add hl, bc
	pop bc

	pop af
	dec a
	jr nz, .y

	ldh a, [rSVBK]
	push af

	ld a, BANK(wBGPals1)
	ldh [rSVBK], a

	ld hl, HaveWantPals
	ld de, wBGPals1
	ld bc, 16 palettes
	call CopyBytes

	pop af
	ldh [rSVBK], a

	ld hl, MobileSelectGFX
	ld de, vTiles0 tile $30
	ld bc, $20 tiles
	call CopyBytes

	ld a, 1
	ldh [rVBK], a

	ld hl, HaveWantGFX
	ld de, vTiles2
	ld bc, $80 tiles
	call CopyBytes

	ld hl, HaveWantGFX + $80 tiles
	ld de, vTiles1
	ld bc, $10 tiles
	call CopyBytes

	xor a
	ldh [rVBK], a

	call EnableLCD
	farcall ReloadMapPart
	ret

HaveWantGFX:
INCBIN "gfx/mobile/havewant.2bpp"

MobileSelectGFX:
INCBIN "gfx/mobile/select.2bpp"

HaveWantMap:
; Interleaved tile/palette map.
INCBIN "gfx/mobile/havewant_map.bin"

HaveWantPals:
; BG and OBJ palettes.
	RGB  0,  0,  0
	RGB 21, 21, 21
	RGB  0,  0,  0
	RGB  0,  0,  0

	RGB  0,  0,  0
	RGB  4, 17, 29
	RGB  6, 19, 31
	RGB 31, 31, 31

	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0

	RGB  0,  0,  0
	RGB  2, 13, 18
	RGB  6, 19, 31
	RGB 31, 31, 31

	RGB  0,  0,  0
	RGB 31,  5,  5
	RGB 29, 21, 21
	RGB 31, 31, 31

	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0

	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0

	RGB  0,  0,  0
	RGB  4, 17, 29
	RGB  6, 19, 31
	RGB  2, 15, 27

	RGB  0,  0,  0
	RGB 28, 19, 18
	RGB 25,  9,  0
	RGB  0,  0,  0

	RGB  0,  0,  0
	RGB 31, 27, 27
	RGB 31, 10,  4
	RGB 29,  0,  0

	RGB  0,  0,  0
	RGB 31, 31, 31
	RGB 26,  8, 23
	RGB 22,  0, 16

	RGB  0,  0,  0
	RGB 31, 31, 31
	RGB 20,  8, 31
	RGB 15,  1, 26

	RGB  0,  0,  0
	RGB 31, 31, 31
	RGB 17, 12, 31
	RGB 12,  6, 31

	RGB  0,  0,  0
	RGB 11, 23,  0
	RGB  7, 17,  0
	RGB 31, 31, 31

	RGB  0, 31,  0
	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0

	RGB 16, 31,  0
	RGB  0,  0,  0
	RGB  0,  0,  0
	RGB  0,  0,  0

CheckStringForErrors:
; Valid character ranges:
; $0, $5 - $13, $19 - $1c, $26 - $34, $3a - $3e, $40 - $48, $60 - $ff
.loop
	ld a, [de]
	inc de
	and a ; "<NULL>"
	jr z, .NextChar
	cp FIRST_REGULAR_TEXT_CHAR
	jr nc, .NextChar
	cp "<NEXT>"
	jr z, .NextChar
	cp "@"
	jr z, .Done
	cp "ガ"
	jr c, .Fail
	cp "<PLAY_G>"
	jr c, .NextChar
	cp "<JP_18>" + 1
	jr c, .Fail
	cp "<NI>"
	jr c, .NextChar
	cp "<NO>" + 1
	jr c, .Fail
	cp "<ROUTE>"
	jr c, .NextChar
	cp "<GREEN>" + 1
	jr c, .Fail
	cp "<ENEMY>"
	jr c, .NextChar
	cp "<ENEMY>" + 1
	jr c, .Fail
	cp "<MOM>"
	jr c, .NextChar

.Fail:
	scf
	ret

.NextChar:
	dec c
	jr nz, .loop

.Done:
	and a
	ret

CheckStringForErrors_IgnoreTerminator:
; Find control chars
.loop
	ld a, [de]
	inc de
	and a
	jr z, .next
	cp "<DEXEND>" + 1
	jr nc, .next
	cp "<NEXT>"
	jr z, .next
	cp "@"
	jr z, .next

	cp "ガ"
	jr c, .end
	cp "<PLAY_G>"
	jr c, .next
	cp "<JP_18>" + 1
	jr c, .end
	cp "<NI>"
	jr c, .next
	cp "<NO>" + 1
	jr c, .end
	cp "<ROUTE>"
	jr c, .next
	cp "<GREEN>" + 1
	jr c, .end
	cp "<ENEMY>"
	jr c, .next
	cp "<ENEMY>" + 1
	jr c, .end
	cp "<MOM>"
	jr c, .next

.end
	scf
	ret

.next
	dec c
	jr nz, .loop
	and a
	ret

Function17d0f3:
	ld a, [wc608 + 5]
	ld [wOTTrademonSpecies], a
	ld [wCurPartySpecies], a
	ld a, [wcd81]
	ld [wc74e], a
	ld hl, wc608 + 53
	ld de, wOTTrademonOTName
	ld bc, PLAYER_NAME_LENGTH - 1
	call CopyBytes
	ld a, "@"
	ld [de], a
	ld a, [wc608 + 11]
	ld [wOTTrademonID], a
	ld a, [wc608 + 12]
	ld [wOTTrademonID + 1], a
	ld hl, wc608 + 26
	ld a, [hli]
	ld [wOTTrademonDVs], a
	ld a, [hl]
	ld [wOTTrademonDVs + 1], a
	ld bc, wc608 + 5
	farcall GetCaughtGender
	ld a, c
	ld [wOTTrademonCaughtData], a
	call SpeechTextbox
	call FadeToMenu
	farcall Function10804d
	farcall Function17d1f1
	ld a, $1
	ld [wForceEvolution], a
	ld a, LINK_TRADECENTER
	ld [wLinkMode], a
	farcall EvolvePokemon
	xor a
	ld [wLinkMode], a
	farcall SaveAfterLinkTrade
	ld a, BANK(s5_a800)
	call OpenSRAM
	ld a, BANK(s5_a800)
	ld [s5_a800], a
	call CloseSRAM
	ld a, [wMapGroup]
	ld b, a
	ld a, [wMapNumber]
	ld c, a
	call GetMapSceneID
	ld a, d
	or e
	jr z, .asm_17d180
	ld a, $1
	ld [de], a

.asm_17d180
	call CloseSubmenu
	call RestartMapMusic
	ret

Mobile_CopyDefaultOTName:
	ld hl, Mobile5F_PlayersName
	ld de, wMobileMonOT
	ld bc, PLAYER_NAME_LENGTH - 1
	call CopyBytes
	ret

Mobile5F_PlayersName:
	db "CHRIS@@"

Mobile_CopyDefaultNickname:
	ld hl, .DefaultNickname
	ld de, wMobileMonNick
	ld bc, MON_NAME_LENGTH - 1
	call CopyBytes
	ret

.DefaultNickname:
	db "??????????"

Mobile_CopyDefaultMail:
	ld a, "@"
	ld hl, wMobileMonMail
	ld bc, MAIL_MSG_LENGTH + 1
	call ByteFill
	ld hl, .DefaultMessage
	ld de, wMobileMonMail
	ld bc, .DefaultMessageEnd - .DefaultMessage
	call CopyBytes
	ret

.DefaultMessage:
	db "Hello@"
.DefaultMessageEnd:

Mobile_CopyDefaultMailAuthor:
	ld a, "@"
	ld de, wMobileMonMailAuthor
	ld bc, PLAYER_NAME_LENGTH - 1
	call ByteFill
	ld hl, Mobile5F_PlayersName
	ld de, wMobileMonMailAuthor
	ld bc, PLAYER_NAME_LENGTH - 1
	call CopyBytes
	ret

CheckStringContainsLessThanBNextCharacters:
.loop
	ld a, [de]
	inc de
	cp "<NEXT>"
	jr nz, .next_char
	dec b
	jr z, .done

.next_char
	dec c
	jr nz, .loop
	and a
	ret

.done
	scf
	ret

Function17d1f1:
	ld a, [wCurPartySpecies]
	dec a
	call SetSeenAndCaughtMon

	ld a, [wCurPartySpecies]
	cp UNOWN
	jr nz, .asm_17d223

	ld hl, wPartyMon1DVs
	ld a, [wPartyCount]
	dec a
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	predef GetUnownLetter
	callfar UpdateUnownDex
	ld a, [wFirstUnownSeen]
	and a
	jr nz, .asm_17d223

	ld a, [wUnownLetter]
	ld [wFirstUnownSeen], a

.asm_17d223
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Parameter: [wScriptVar] = 0..1
;
; if [wScriptVar] == FALSE
;    Show japanese menu options
;    - News - News - ??? - Cancel
; if [wScriptVar] == TRUE
;    Show BattleTower-Menu with 3 options in english language
;    - Challenge - Explanation - Cancel
Menu_ChallengeExplanationCancel:
	ld a, [wScriptVar]
	and a
	jr nz, .jr_05f_5234;.English
	ld a, $4
	ld [wScriptVar], a
	ld hl, MenuHeader_17d26a ; Japanese Menu, where you can choose 'News' as an option
	jr .Load_Interpret

.jr_05f_5234:
    farcall BattleTower_CheckSaveFileExistsAndIsYours
    ld a, [wScriptVar]
    and a
    jr nz, .jr_05f_524a

.English:
	ld a, $4
	ld [wScriptVar], a
	ld hl, MenuHeader_ChallengeExplanationCancel ; English Menu
	jr .Load_Interpret

.jr_05f_524a:
    call Call_05f_5261
    jr c, .English
    ld a, $05
    ld [wScriptVar], a
    ld hl, MenuHeader_ChallengeRegisterExplanationCancel;$52f2

.Load_Interpret:
	call LoadMenuHeader
	call Function17d246
	call CloseWindow
	ret

Call_05f_5261:
    ld a, BANK(s5_aa8e);$05
    call OpenSRAM;$2f9d
    ld hl, s5_aa8e
    ld bc, BATTLE_TOWER_STRUCT_LENGTH * BATTLETOWER_STREAK_LENGTH;$0594
jr_05f_526c:
    ld a, [hl+]
    and a
    jr nz, jr_05f_527b
    dec bc
    ld a, b
    or a
    and a
    jr nz, jr_05f_526c
    call CloseSRAM;$2fad
    scf
    ret

jr_05f_527b:
    call CloseSRAM;$2fad
    ret

Function17d246:
	call VerticalMenu
	jr c, .Exit
	ld a, [wScriptVar]
	cp $5
	jr nz, .UsewMenuCursorY
	ld a, [wMenuCursorY]
	cp $3
	ret z
	jr c, .UsewMenuCursorY
	dec a
	jr .LoadToScriptVar

.UsewMenuCursorY:
	ld a, [wMenuCursorY]

.LoadToScriptVar:
	ld [wScriptVar], a
	ret

.Exit:
	ld a, $4
	ld [wScriptVar], a
	ret

MenuHeader_17d26a:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 14, 9
	dw MenuData_17d272
	db 1 ; default option

MenuData_17d272:
	db STATICMENU_CURSOR | STATICMENU_WRAP ; flags
	db 4
	db "Receive News@" 	; "ニュース¯よみこむ@"
	db "View News@" 	; "ニュース¯みる@"
	db "Explanation@" 	; "せつめい@"
	db "Cancel@" 		; "やめる@"

MenuHeader_ChallengeExplanationCancel:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 15, 9;14, 7
	dw MenuData_ChallengeExplanationCancel
	db 1 ; default option

MenuData_ChallengeExplanationCancel:
	db STATICMENU_CURSOR | STATICMENU_WRAP ; flags
	db 4
	db "Challenge@"
	db "Honor Roll@" ; check leaders?
	db "Explanation@"
	db "Cancel@"

MenuHeader_ChallengeRegisterExplanationCancel:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 15, 11
	dw MenuData_ChallengeRegisterExplanationCancel
	db 1 ; default option

MenuData_ChallengeRegisterExplanationCancel:
	db STATICMENU_CURSOR | STATICMENU_WRAP ; flags
	db 5
	db "Challenge@"
	db "Honor Roll@" ; check leaders?
	db "Previous Room@"
	db "Explanation@"
	db "Cancel@"

Function17d2b6:
	call Function17d2c0
	farcall Function1181da
	ret

Function17d2c0:
	xor a
	ld [wJumptableIndex], a
	ld [wcf64], a
	ld [wcf65], a
	ld [wcf66], a
	ret

Function17d2ce:
	ld a, BANK(s5_aa72)
	call OpenSRAM
	ld a, [s5_aa72]
	call CloseSRAM
	and a
	jr nz, .asm_17d2e2
	ld a, $1
	ld [wScriptVar], a
	ret

.asm_17d2e2
	call Function17d314
	ret c
	call SpeechTextbox
	call FadeToMenu
	ldh a, [rSVBK]
	push af
	ld a, $4
	ldh [rSVBK], a
	call Function17d370
	call Function17d45a
	pop af
	ldh [rSVBK], a
	ld de, MUSIC_MOBILE_CENTER
	ld a, e
	ld [wMapMusic], a
	ld [wMusicFadeID], a
	ld a, d
	ld [wMusicFadeID + 1], a
	call PlayMusic
	call ReturnToMapFromSubmenu
	call CloseSubmenu
	ret

Function17d314:
	ld a, BANK(s5_b1b1)
	call OpenSRAM
	ld a, [s5_b1b1]
	call CloseSRAM
	cp $21
	jr nc, .asm_17d354
	ld a, BANK(s6_a000)
	call OpenSRAM
	ld l, 0
	ld h, l
	ld de, s6_a000 + 6
	ld a, [s6_a000 + 4]
	ld c, a
	ld a, [s6_a000 + 5]
	ld b, a
.asm_17d336
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
	jr nz, .asm_17d336
	ld a, [s6_a000 + 2]
	cp l
	jr nz, .asm_17d354
	ld a, [s6_a000 + 3]
	cp h
	jr nz, .asm_17d354
	call CloseSRAM
	and a
	ret

.asm_17d354
	call CloseSRAM
	ld a, BANK(s5_aa73)
	call OpenSRAM
	xor a
	ld hl, s5_aa73
	ld bc, $c
	call ByteFill
	call CloseSRAM
	ld a, $2
	ld [wScriptVar], a
	scf
	ret

Function17d370:
	xor a
	ld [wcd77], a
	ld [wMobileCrashCheckPointer], a
	ld [wMobileCrashCheckPointer + 1], a
	dec a
	ld [wcd6c], a
	call ClearBGPalettes
	call ClearSprites
	call ClearScreen
	farcall ReloadMapPart
	call DisableLCD
	ld hl, vTiles0 tile $ee
	ld de, wc608
	ld bc, 1 tiles
	call CopyBytes
	ld a, $1
	ldh [rVBK], a
	ld hl, PokemonNewsGFX
	ld de, vTiles1
	ld bc, $48 tiles
	call CopyBytes
	xor a
	ld hl, vTiles2 tile $7f
	ld bc, 1 tiles
	call ByteFill
	ld hl, wc608
	ld de, vTiles0 tile $ee
	ld bc, 1 tiles
	call CopyBytes
	xor a
	ldh [rVBK], a
	ld hl, PostalMarkGFX
	ld de, vTiles2 tile $60
	ld bc, 1 tiles
	call CopyBytes
	call EnableLCD
	call Function17d60b
	ld a, $0
	ld [wBGMapBuffer], a
	ld a, $d0
	ld [wcd21], a
	ld a, BANK(s6_a000)
	call OpenSRAM
	ld hl, s6_a000 + 6
	ld de, w4_d000
	ld bc, $1000
	call CopyBytes
	call CloseSRAM
	ret

Function17d3f6:
	call ClearBGPalettes
	call ClearSprites
	call ClearScreen
	farcall ReloadMapPart

Function17d405:
	call DisableLCD
	ld hl, vTiles0 tile $ee
	ld de, wc608
	ld bc, 1 tiles
	call CopyBytes
	ld a, $1
	ldh [rVBK], a
	ld hl, PokemonNewsGFX
	ld de, vTiles1
	ld bc, $48 tiles
	call CopyBytes
	xor a
	ld hl, vTiles2 tile $7f
	ld bc, 1 tiles
	call ByteFill
	ld hl, wc608
	ld de, vTiles0 tile $ee
	ld bc, 1 tiles
	call CopyBytes
	xor a
	ldh [rVBK], a
	call EnableLCD
	ldh a, [rSVBK]
	push af
	ld a, $5
	ldh [rSVBK], a
	ld hl, PokemonNewsPalettes
	ld de, wBGPals1
	ld bc, 8 palettes
	call CopyBytes
	call SetPalettes
	pop af
	ldh [rSVBK], a
	ret

Function17d45a:
.asm_17d45a
	call JoyTextDelay
	ld a, [wcd77]
	bit 7, a
	jr nz, .asm_17d46f
	call Function17d474
	farcall ReloadMapPart
	jr .asm_17d45a

.asm_17d46f
	xor a
	ld [wScriptVar], a
	ret

Function17d474:
	jumptable Jumptable_17d483, wcd77

Jumptable_17d483:
	dw Function17d48d
	dw Function17d5be
	dw Function17d5c4
	dw Function17d6fd
	dw Function17e427

Function17d48d:
	ld hl, PokemonNewsPalettes
	ld de, wc608
	ld bc, $40
	call CopyBytes
	ld hl, PokemonNewsTileAttrmap
	decoord 0, 0
	bccoord 0, 0, wAttrmap
	ld a, $12
.asm_17d4a4
	push af
	ld a, $14
	push hl
.asm_17d4a8
	push af
	ld a, [hli]
	cp $7f
	jr z, .asm_17d4b0
	add $80

.asm_17d4b0
	ld [de], a
	inc de
	ld a, [hli]
	ld [bc], a
	inc bc
	pop af
	dec a
	jr nz, .asm_17d4a8
	pop hl
	push bc
	ld bc, $40
	add hl, bc
	pop bc
	pop af
	dec a
	jr nz, .asm_17d4a4
	ld a, [wBGMapBuffer]
	ld l, a
	ld a, [wcd21]
	ld h, a
	ld a, [hli]
	ld e, a
	ld a, [wcd6c]
	cp e
	jr z, .asm_17d4e0
	ld a, e
	ld [wcd6c], a
	ld [wMapMusic], a
	ld d, $0
	call PlayMusic2

.asm_17d4e0
	ld a, [hli]
	ld de, wc608
	ld c, $8
.asm_17d4e6
	srl a
	jr nc, .asm_17d4f6
	ld b, $8
	push af
.asm_17d4ed
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .asm_17d4ed
	pop af
	jr .asm_17d4fc

.asm_17d4f6
	push af
	ld a, e
	add $8
	ld e, a
	pop af

.asm_17d4fc
	dec c
	jr nz, .asm_17d4e6
	push hl
	call Function17d5f6
	pop hl
	ld a, [hli]
	and a
	jr z, .asm_17d539
.asm_17d508
	push af
	ld a, [hli]
	ld [wcd4f], a
	ld a, [hli]
	ld [wcd50], a
	ld a, [hli]
	ld [wcd51], a
	ld a, [hli]
	ld [wcd52], a
	ld a, [hli]
	sla a
	sla a
	sla a
	add $98
	ld [wcd53], a
	ld de, wcd4f
	call Function17e613
	ld a, [hli]
	ld [wcd53], a
	ld de, wcd4f
	call Function17e691
	pop af
	dec a
	jr nz, .asm_17d508

.asm_17d539
	ld a, [hli]
.asm_17d53a
	push af
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	push hl
	pop de
	hlcoord 0, 0
	add hl, bc
	call PlaceString
	push de
	pop hl
	inc hl
	pop af
	dec a
	jr nz, .asm_17d53a
	ld de, wCreditsTimer
	ld bc, $c
	call CopyBytes
	xor a
	ld [wcd2e], a
	ld [wcd2f], a
	inc a
	ld [wcd30], a
	ld [wcd31], a
	ld de, wcd32
	ld bc, $10
	call CopyBytes
	ld a, [hli]
	ld [wcd42], a
	ld a, [hli]
	ld [wcd43], a
	ld a, [hli]
	ld [wMobileInactivityTimerMinutes], a
	ld a, [hli]
	ld [wMobileInactivityTimerSeconds], a
	ld a, [hli]
	ld [wMobileInactivityTimerFrames], a
	ld a, [hli]
	and a
	jr z, .asm_17d58a
	call Function17d6a1

.asm_17d58a
	ld a, l
	ld [wcd49], a
	ld a, h
	ld [wcd4a], a
	ld a, [wcd42]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, l
	ld [wcd4b], a
	ld a, h
	ld [wcd4c], a
	add hl, bc
	add hl, bc
	ld a, l
	ld [wcd4d], a
	ld a, h
	ld [wcd4e], a
	call Function17e451
	call Function17e55b
	call Function17e5af
	farcall ReloadMapPart
	jp Function17e438

Function17d5be:
	call SetPalettes
	call Function17e438

Function17d5c4:
	ldh a, [hJoyPressed]
	and a
	ret z
	ld c, 0
	ld b, c
	ld hl, wcd32
.loop
	srl a
	jr c, .got_button
	inc c
	inc c
	jr .loop

.got_button
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	and c
	cp $ff
	ret z
	ld a, [wcd20]
	ld l, a
	ld a, [wcd21]
	ld h, a
	add hl, bc
	ld a, l
	ld [wMobileCrashCheckPointer], a
	ld a, h
	ld [wMobileCrashCheckPointer + 1], a
	ld a, $3
	ld [wcd77], a
	ret

Function17d5f6:
	ld a, $5
	ldh [rSVBK], a
	ld hl, wc608
	ld de, wBGPals1
	ld bc, 8 palettes
	call CopyBytes
	ld a, $4
	ldh [rSVBK], a
	ret

Function17d60b:
	ld a, $5
	call OpenSRAM
	ld hl, s5_b1d3
	ld de, wc608
	ld bc, $20
	call CopyBytes
	ld a, [s5_b1b1]
	ld c, a
	ld a, [s5_b1b1 + 1]
	ld b, a
	ld a, [s5_b1b3]
	ld l, a
	ld a, [s5_b1b3 + 1]
	ld h, a
	call CloseSRAM
	ld a, $6
	call OpenSRAM
	ld de, wc708
	ld a, c
	and a
	jr z, .asm_17d684
.asm_17d63b
	push bc
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld bc, $a
	add hl, bc
	pop bc
	ld a, [hli]
	ld [wcd4a], a
	ld a, [hli]
	ld [wcd49], a
	push hl
	push de
	ld hl, wc608
	ld e, b
	ld d, $0
	add hl, de
	ld a, [hli]
	ld [wcd4b], a
	ld a, [hl]
	ld [wcd4c], a
	pop de
	pop hl
	inc b
	inc b
	dec c
	dec c
	jr z, .asm_17d684
	push bc
	push de
	ld a, [wcd49]
	ld c, a
	ld a, [wcd4a]
	ld b, a
	ld a, [wcd4b]
	ld e, a
	ld a, [wcd4c]
	ld d, a
.asm_17d67a
	add hl, de
	dec bc
	ld a, c
	or b
	jr nz, .asm_17d67a
	pop de
	pop bc
	jr .asm_17d63b

.asm_17d684
	call CloseSRAM
	ld a, $5
	call OpenSRAM
	ld hl, wc708
	ld de, s5_b1b3
	ld a, [s5_b1b1]
	ld c, a
	ld a, [s5_b1b1 + 1]
	ld b, a
	call CopyBytes
	call CloseSRAM
	ret

Function17d6a1:
	push hl
	ld a, [wcd6e]
	ld c, a
	ld b, 0
	ld a, $5
	call OpenSRAM
	ld hl, s5_b1d3
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld [wcd47], a
	ld a, [hl]
	ld [wBGMapPalBuffer], a
	ld hl, s5_b1b3
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld h, a
	ld l, c
	call CloseSRAM
	ld a, $6
	call OpenSRAM
	ld a, l
	ld [wcd5e], a
	ld a, h
	ld [wcd5f], a
	ld de, wcd60
	ld bc, $4
	call CopyBytes
	inc hl
	inc hl
	ld de, wcd64
	ld bc, $4
	call CopyBytes
	ld a, [hli]
	ld [wcd69], a
	ld a, [hli]
	ld [wcd68], a
	ld a, l
	ld [wcd6a], a
	ld a, h
	ld [wcd6b], a
	call CloseSRAM
	pop hl
	ret

Function17d6fd:
	ld a, [wcd77]
	bit 7, a
	jr nz, asm_17d721
	ld a, [wMobileCrashCheckPointer]
	ld l, a
	ld a, [wMobileCrashCheckPointer + 1]
	ld h, a
	ld a, [hl]
	cp $ff
	jr z, asm_17d721

Function17d711:
.crash_loop
	cp $31
	jr nc, .crash_loop
	ld e, a
	ld d, 0
	ld hl, Jumptable17d72a
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

asm_17d721:
	call Function17e5af
	ld a, $2
	ld [wcd77], a
	ret

Jumptable17d72a: ; news script commands
	dw Function17d78c ; 0
	dw Function17d78d ; 1
	dw Function17d7b4 ; 2
	dw Function17d7c2 ; 3
	dw Function17d7d3 ; 4
	dw Function17d7e5 ; 5
	dw Function17d818 ; 6
	dw Function17d833 ; 7
	dw Function17d85d ; 8
	dw Function17d902 ; 9
	dw Function17d93a ; a
	dw Function17d98b ; b
	dw Function17d9e3 ; c
	dw Function17da31 ; d
	dw Function17da9c ; e
	dw Function17dadc ; f
	dw Function17db2d ; 10
	dw Function17db56 ; 11
	dw Function17db77 ; 12
	dw Function17dbe9 ; 13
	dw Function17dc1f ; 14
	dw Function17dc9f ; 15
	dw Function17dca9 ; 16
	dw Function17dccf ; 17
	dw Function17dd13 ; 18
	dw Function17dd30 ; 19
	dw Function17dd49 ; 1a
	dw Function17ddcd ; 1b
	dw Function17de32 ; 1c
	dw Function17de91 ; 1d
	dw Function17ded9 ; 1e
	dw Function17e0fd ; 1f
	dw Function17e133 ; 20
	dw Function17e165 ; 21
	dw Function17e1a1 ; 22
	dw Function17e254 ; 23
	dw Function17e261 ; 24
	dw Function17e270 ; 25
	dw Function17e27f ; 26
	dw Function17e293 ; 27
	dw Function17e2a7 ; 28
	dw IncCrashCheckPointer_SaveGameData ; 29
	dw IncCrashCheckPointer_SaveAfterLinkTrade ; 2a
	dw IncCrashCheckPointer_SaveBox ; 2b
	dw IncCrashCheckPointer_SaveChecksum ; 2c
	dw IncCrashCheckPointer_SaveTrainerRankingsChecksum ; 2d
	dw Function17e3e0 ; 2e
	dw Function17e3f0 ; 2f
	dw Function17e409 ; 30

Function17d78c:
	ret

Function17d78d:
	call IncCrashCheckPointer
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	call HlToCrashCheckPointer
	ld a, BANK(s6_a000)
	call OpenSRAM
	ld hl, s6_a000 + 6
	add hl, bc
	ld de, w4_d000
	ld bc, $1000
	call CopyBytes
	call CloseSRAM
	xor a
	ld [wcd77], a
	call ClearBGPalettes
	ret

Function17d7b4:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld d, 0
	call PlayMusic2
	call HlToCrashCheckPointer
	ret

Function17d7c2:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld d, 0
	call PlaySFX
	call WaitSFX
	call HlToCrashCheckPointer
	ret

Function17d7d3:
	call IncCrashCheckPointer
	ld a, [hli]
	dec a
	ld e, a
	ld d, 0
	call PlayCry
	call WaitSFX
	call HlToCrashCheckPointer
	ret

Function17d7e5:
	call IncCrashCheckPointer
	ld a, [hli]
	ld [wcd4f], a
	ld a, [hli]
	ld [wcd50], a
	ld a, [hli]
	ld [wcd51], a
	ld a, [hli]
	ld [wcd52], a
	ld a, [hli]
	sla a
	sla a
	sla a
	add $98
	ld [wcd53], a
	ld de, wcd4f
	call Function17e613
	ld a, [hli]
	ld [wcd53], a
	ld de, wcd4f
	call Function17e691
	call HlToCrashCheckPointer
	ret

Function17d818:
	call IncCrashCheckPointer
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	call HlToCrashCheckPointer
	call Function17e447
	ld e, l
	ld d, h
	hlcoord 0, 0
	add hl, bc
	call PlaceString
	ret

Function17d833:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	call HlToCrashCheckPointer
	push de
	push bc
	call Function17e32b
	pop bc
	pop de
	call Function17e43d
	ld c, l
	ld b, h
	hlcoord 0, 0
	add hl, de
	ld e, l
	ld d, h
	farcall Function11c08f
	call Function17e349
	ret

Function17d85d:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	ld hl, wBGPals1
	add hl, de
	ld de, wcc60
.asm_17d86c
	ld a, [hli]
	ld [de], a
	inc de
	and a
	jr nz, .asm_17d86c
	pop hl
	ld de, wc608
	ld c, $0
.asm_17d878
	ld a, [hli]
	cp $ff
	jr z, .asm_17d8c7
	ld [wcd4f], a
	ld a, [hli]
	ld [wcd50], a
	ld a, [hli]
	ld [wcd51], a
	ld a, [hli]
	ld [wcd52], a
	ld a, [wcd51]
	push af
	cp $c0
	jr c, .asm_17d89b
	ld a, [wcd4f]
	ldh [rSVBK], a
	jr .asm_17d8a1

.asm_17d89b
	ld a, [wcd4f]
	call OpenSRAM

.asm_17d8a1
	push hl
	ld a, [wcd50]
	ld l, a
	ld a, [wcd51]
	ld h, a
	ld a, [wcd52]
.asm_17d8ad
	push af
	ld a, [hli]
	ld [de], a
	inc de
	inc c
	pop af
	dec a
	jr nz, .asm_17d8ad
	pop hl
	pop af
	cp $c0
	jr c, .asm_17d8c2
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17d878

.asm_17d8c2
	call CloseSRAM
	jr .asm_17d878

.asm_17d8c7
	call HlToCrashCheckPointer
	push bc
	ld a, $3
	ldh [rSVBK], a
	ld hl, wc608
	ld de, wBGPals1
	ld b, $0
	call CopyBytes
	ld a, $4
	ldh [rSVBK], a
	call Function17e32b
	pop bc
	ld a, c
	ld [wcd3b], a
	xor a
	ld [wcf66], a
	farcall Function118329
	ld a, [wMobileErrorCodeBuffer]
	and a
	jr z, .asm_17d8fe
	cp $a
	jr z, .asm_17d8fe
	call Function17e309
	ret

.asm_17d8fe
	call Function17e349
	ret

Function17d902:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de
	call HlToCrashCheckPointer
	call Function17e32b
	pop de
	ld hl, wBGPals1
	add hl, de
	ld de, wcc60
.asm_17d918
	ld a, [hli]
	ld [de], a
	inc de
	and a
	jr nz, .asm_17d918
	xor a
	ld [wcf66], a
	farcall Function11837a
	ld a, [wMobileErrorCodeBuffer]
	and a
	jr z, .asm_17d936
	cp $a
	jr z, .asm_17d936
	call Function17e309
	ret

.asm_17d936
	call Function17e349
	ret

Function17d93a:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $5
	call CopyBytes
	call HlToCrashCheckPointer
	call Function17e32b
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld a, [wc70c]
	call Function17e6de
	ld a, [wc70a]
	ld [wCurPartySpecies], a
	ld a, [wc70c]
	ld e, a
	farcall LoadMonPaletteAsNthBGPal
	call SetPalettes
	ld a, [wc708]
	ld l, a
	ld a, [wc709]
	ld h, a
	ld a, [wc70b]
	ld c, a
	decoord 0, 0
	add hl, de
	ld e, l
	ld d, h
	farcall HOF_AnimateFrontpic
	pop af
	ldh [rSVBK], a
	call Function17e349
	ret

Function17d98b:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $4
	call CopyBytes
	call HlToCrashCheckPointer
	call Function17e32b
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld a, [wc70b]
	call Function17e6de
	ld a, [wc70a]
	ld [wTrainerClass], a
	ld a, [wc70b]
	ld e, a
	farcall LoadTrainerClassPaletteAsNthBGPal
	call SetPalettes
	ld a, [wc708]
	ld e, a
	ld a, [wc709]
	ld d, a
	push de
	ld de, vTiles2
	farcall GetTrainerPic
	pop hl
	decoord 0, 0
	add hl, de
	ld bc, $707
	predef PlaceGraphic
	pop af
	ldh [rSVBK], a
	call Function17e349
	ret

Function17d9e3:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $7
	call CopyBytes
	call HlToCrashCheckPointer
	ld a, [wc70b]
	push af
	cp $c0
	jr c, .asm_17da01
	ld a, [wc70c]
	ldh [rSVBK], a
	jr .asm_17da07

.asm_17da01
	ld a, [wc70c]
	call OpenSRAM

.asm_17da07
	ld a, [wc708]
	ld l, a
	ld a, [wc709]
	ld h, a
	ld a, [wc70a]
	ld e, a
	ld a, [wc70b]
	ld d, a
	ld a, [wc70d]
	ld c, a
	ld a, [wc70e]
	ld b, a
	call CopyBytes
	pop af
	cp $c0
	jr c, .asm_17da2d
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17da30

.asm_17da2d
	call CloseSRAM

.asm_17da30
	ret

Function17da31:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $4
	call CopyBytes
	call HlToCrashCheckPointer
	ld a, [wc709]
	push af
	cp $c0
	jr c, .asm_17da4f
	ld a, [wc70a]
	ldh [rSVBK], a
	jr .asm_17da55

.asm_17da4f
	ld a, [wc70a]
	call OpenSRAM

.asm_17da55
	ld a, [wc708]
	ld e, a
	ld a, [wc709]
	ld d, a
	ld a, [wc70b]
	ld c, a
	bit 7, c
	jr nz, .asm_17da70
	ld hl, Unknown_17da8c
	ld b, $0
	add hl, bc
	ld a, [de]
	or [hl]
	ld [de], a
	jr .asm_17da7d

.asm_17da70
	ld hl, Unknown_17da94
	ld a, c
	and $7f
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	and [hl]
	ld [de], a

.asm_17da7d
	pop af
	cp $c0
	jr c, .asm_17da88
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17da8b

.asm_17da88
	call CloseSRAM

.asm_17da8b
	ret

Unknown_17da8c:
for x, 8
	db 1 << x
endr

Unknown_17da94:
for x, 8
	db ~(1 << x)
endr

Function17da9c:
	ld a, [wcd31]
	dec a
	jr z, .asm_17dabd
	push af
	call Function17e566
	pop af
	ld [wcd31], a
	ld hl, wcd24
	ld a, [wcd2e]
	sub [hl]
	ld [wcd2e], a
	call Function17e55b
	call Function17e5af
.asm_17daba
	jp IncCrashCheckPointer

.asm_17dabd
	ld a, [wcd2f]
	and a
	jr z, .asm_17daba
	ld hl, wcd24
	sub [hl]
	ld [wcd2f], a
	ld a, [wcd2e]
	sub [hl]
	ld [wcd2e], a
	call Function17e451
	call Function17e55b
	call Function17e5af
	jr .asm_17daba

Function17dadc:
	ld a, [wcd2e]
	ld hl, wcd24
	add [hl]
	ld hl, wcd42
	cp [hl]
	jr z, .asm_17db0e
	jr nc, .asm_17db0e
	ld hl, wcd31
	ld a, [wcd2b]
	cp [hl]
	jr z, .asm_17db11
	call Function17e566
	ld a, [wcd31]
	inc a
	ld [wcd31], a
	ld hl, wcd24
	ld a, [wcd2e]
	add [hl]
	ld [wcd2e], a
	call Function17e55b
	call Function17e5af

.asm_17db0e
	jp IncCrashCheckPointer

.asm_17db11
	ld hl, wcd24
	ld a, [wcd2f]
	add [hl]
	ld [wcd2f], a
	ld a, [wcd2e]
	add [hl]
	ld [wcd2e], a
	call Function17e451
	call Function17e55b
	call Function17e5af
	jr .asm_17db0e

Function17db2d:
	ld a, [wcd30]
	ld hl, wcd24
	cp [hl]
	jr z, .asm_17db53
	ld hl, wcd42
	ld a, [wcd2e]
	inc a
	cp [hl]
	jr z, .asm_17db53
	ld [wcd2e], a
	call Function17e566
	ld a, [wcd30]
	inc a
	ld [wcd30], a
	call Function17e55b
	call Function17e5af

.asm_17db53
	jp IncCrashCheckPointer

Function17db56:
	ld a, [wcd30]
	cp $1
	jr z, .asm_17db74
	call Function17e566
	ld a, [wcd30]
	dec a
	ld [wcd30], a
	ld a, [wcd2e]
	dec a
	ld [wcd2e], a
	call Function17e55b
	call Function17e5af

.asm_17db74
	jp IncCrashCheckPointer

Function17db77:
	ld hl, wcd2d
	ld a, [wcd2f]
	add [hl]
	ld hl, wcd42
	cp [hl]
	jr z, .asm_17dbae
	jr nc, .asm_17dbae
	call Function17e566
	ld hl, wcd2d
	ld a, [wcd2f]
	add [hl]
	ld [wcd2f], a
	ld a, [wcd2e]
	add [hl]
	ld hl, wcd42
	cp [hl]
	jr c, .asm_17db9f
	ld a, [hl]
	dec a

.asm_17db9f
	ld [wcd2e], a
	call Function17dbb1
	call Function17e451
	call Function17e55b
	call Function17e5af

.asm_17dbae
	jp IncCrashCheckPointer

Function17dbb1:
	ld hl, wcd2f
	ld a, [wcd42]
	sub [hl]
	ld hl, wcd2d
	cp [hl]
	ret nc
	ld a, $1
	ld [wcd30], a
	ld [wcd31], a
	ld a, [wcd24]
	ld c, a
	ld a, [wcd24]
	ld b, a
	ld a, [wcd2e]
	ld hl, wcd2f
	sub [hl]
.asm_17dbd4
	and a
	ret z
	push af
	ld hl, wcd30
	ld a, b
	cp [hl]
	jr nz, .asm_17dbe4
	ld a, $1
	ld [hl], a
	ld hl, wcd31

.asm_17dbe4
	inc [hl]
	pop af
	dec a
	jr .asm_17dbd4

Function17dbe9:
	ld hl, wcd2d
	ld a, [wcd2f]
	sub [hl]
	bit 7, a
	jr z, .asm_17dbf5
	xor a

.asm_17dbf5
	ld [wcd2f], a
	ld a, [wcd30]
	dec a
	ld c, a
	ld a, [wcd31]
	ld b, a
	xor a
	ld hl, wcd24
.asm_17dc05
	dec b
	jr z, .asm_17dc0b
	add [hl]
	jr .asm_17dc05

.asm_17dc0b
	add c
	ld hl, wcd2f
	add [hl]
	ld [wcd2e], a
	call Function17e451
	call Function17e55b
	call Function17e5af
	jp IncCrashCheckPointer

Function17dc1f:
	call IncCrashCheckPointer
	ld de, wc688
	ld bc, $6
	call CopyBytes
	call Function17e32b
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld hl, wc688
	ld a, $40
	ld [wc708], a
	ld a, [hli]
	ld [wc70a], a
	add $5
	ld [wc70c], a
	ld a, [hli]
	ld [wc709], a
	add $4
	ld [wc70b], a
	ld a, $96
	ld [wc70d], a
	ld a, $5c
	ld [wc70e], a
	ld a, $1
	ld [wc70f], a
	ld hl, wc708
	call LoadMenuHeader
	call VerticalMenu
	jr nc, .asm_17dc6e
	ld a, $2
	ld [wMenuCursorY], a

.asm_17dc6e
	call CloseWindow
	pop af
	ldh [rSVBK], a
	ld a, [wMenuCursorY]
	cp $1
	jr nz, .asm_17dc85
	ld a, [wc68a]
	ld l, a
	ld a, [wc68a + 1]
	ld h, a
	jr .asm_17dc8d

.asm_17dc85
	ld a, [wc68a + 2]
	ld l, a
	ld a, [wc68a + 3]
	ld h, a

.asm_17dc8d
	push hl
	call Function17e349
	pop hl
	call Function17e40f
	ret

MenuData_17dc96: ; unreferenced
	db STATICMENU_CURSOR | STATICMENU_NO_TOP_SPACING | STATICMENU_WRAP ; flags
	db 2
	db "YES@"	; "はい@"
	db "NO@"	; "いいえ@"

Function17dc9f:
	call IncCrashCheckPointer
	call HlToCrashCheckPointer
	call RotateFourPalettesLeft
	ret

Function17dca9:
	call IncCrashCheckPointer
	call HlToCrashCheckPointer

Function17dcaf:
	ld a, $5
	ldh [rSVBK], a
	ld hl, wBGPals1
	ld de, 1 palettes
	ld c, 8
.asm_17dcbb
	push hl
	ld a, $ff
	ld [hli], a
	ld a, $7f
	ld [hl], a
	pop hl
	add hl, de
	dec c
	jr nz, .asm_17dcbb
	call RotateThreePalettesRight
	ld a, $4
	ldh [rSVBK], a
	ret

Function17dccf:
	call IncCrashCheckPointer
	push hl
	ld a, [wcd4b]
	ld l, a
	ld a, [wcd4c]
	ld h, a
	ld a, [wcd2e]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	call Function17e43d
	call HlToCrashCheckPointer
.asm_17dced
	ld a, [wMobileCrashCheckPointer]
	ld l, a
	ld a, [wMobileCrashCheckPointer + 1]
	ld h, a
	ld a, [hl]
	cp $ff
	jr z, .asm_17dd0d
.crash_loop
	cp $31
	jr nc, .crash_loop
	call Function17d711
	ld a, [wcd77]
	bit 7, a
	jr nz, .asm_17dd0d
	and a
	jr z, .asm_17dd11
	jr .asm_17dced

.asm_17dd0d
	pop hl
	jp HlToCrashCheckPointer

.asm_17dd11
	pop hl
	ret

Function17dd13:
	call IncCrashCheckPointer
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	call HlToCrashCheckPointer
	call Function17e447
	push hl
	hlcoord 0, 0
	add hl, bc
	push hl
	pop bc
	pop hl
	call PlaceHLTextAtBC
	ret

Function17dd30:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld b, 0
	ld a, [hli]
	push af
	call HlToCrashCheckPointer
	pop af
	hlcoord 0, 0
	add hl, de
	call Function17e600
	ret

Function17dd49:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $a
	call CopyBytes
	ld a, [wc711]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, [wc70a]
	cp $c0
	jr c, .sram
	ld a, [wc708]
	ldh [rSVBK], a
	jr .got_bank

.sram
	ld a, [wc708]
	call OpenSRAM

.got_bank
	ld a, [wc709]
	ld l, a
	ld a, [wc70a]
	ld h, a
	ld de, wc688
	ld a, [wc711]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, [wc70a]
	cp $c0
	jr c, .close_sram
	ld a, $4
	ldh [rSVBK], a
	jr .exited_bank

.close_sram
	call CloseSRAM

.exited_bank
	ld a, [wc711]
	ld c, a
	ld hl, wc712
	ld de, wc688
.loop
	ld a, [de]
	inc de
	cp [hl]
	inc hl
	jr z, .next
	jr c, .load
	jr .load2

.next
	dec c
	jr nz, .loop
	ld a, [wc70d]
	ld l, a
	ld a, [wc70e]
	ld h, a
	jr .done

.load2
	ld a, [wc70f]
	ld l, a
	ld a, [wc710]
	ld h, a
	jr .done

.load
	ld a, [wc70b]
	ld l, a
	ld a, [wc70c]
	ld h, a

.done
	call Function17e40f
	ret

Function17ddcd:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $8
	call CopyBytes
	ld a, [wc70a]
	cp $c0
	jr c, .asm_17dde7
	ld a, [wc708]
	ldh [rSVBK], a
	jr .asm_17dded

.asm_17dde7
	ld a, [wc708]
	call OpenSRAM

.asm_17dded
	ld a, [wc709]
	ld e, a
	ld a, [wc70a]
	ld d, a
	ld a, [de]
	ld [wc710], a
	ld a, [wc70b]
	ld c, a
	ld b, 0
	ld a, [wc70a]
	cp $c0
	jr c, .asm_17de0c
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17de0f

.asm_17de0c
	call CloseSRAM

.asm_17de0f
	push hl
	ld hl, Unknown_17da8c
	add hl, bc
	ld a, [hl]
	ld hl, wc710
	and [hl]
	pop hl
	jr nz, .asm_17de26
	ld a, [wc70e]
	ld l, a
	ld a, [wc70f]
	ld h, a
	jr .asm_17de2e

.asm_17de26
	ld a, [wc70c]
	ld l, a
	ld a, [wc70d]
	ld h, a

.asm_17de2e
	call Function17e40f
	ret

Function17de32:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $9
	call CopyBytes
	ld a, [wc710]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, $6
	call OpenSRAM
	call Function17f4f6
	ld a, [wc708]
	ld e, a
	ld a, [wc709]
	ld d, a
	add hl, de
	ld e, l
	ld d, h
	ld a, [wc710]
	ld c, a
	ld hl, wc711
.asm_17de61
	ld a, [de]
	inc de
	cp [hl]
	inc hl
	jr z, .asm_17de6b
	jr c, .asm_17de82
	jr .asm_17de78

.asm_17de6b
	dec c
	jr nz, .asm_17de61
	ld a, [wc70c]
	ld l, a
	ld a, [wc70d]
	ld h, a
	jr .asm_17de8a

.asm_17de78
	ld a, [wc70e]
	ld l, a
	ld a, [wc70f]
	ld h, a
	jr .asm_17de8a

.asm_17de82
	ld a, [wc70a]
	ld l, a
	ld a, [wc70b]
	ld h, a

.asm_17de8a
	call CloseSRAM
	call Function17e40f
	ret

Function17de91:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $7
	call CopyBytes
	ld a, $6
	call OpenSRAM
	call Function17f4f6
	ld a, [wc708]
	ld e, a
	ld a, [wc709]
	ld d, a
	add hl, de
	ld e, l
	ld d, h
	ld a, [wc70a]
	ld c, a
	ld b, 0
	ld hl, Unknown_17da8c
	add hl, bc
	ld a, [hl]
	ld l, e
	ld h, d
	and [hl]
	jr nz, .asm_17deca
	ld a, [wc70d]
	ld l, a
	ld a, [wc70e]
	ld h, a
	jr .asm_17ded2

.asm_17deca
	ld a, [wc70b]
	ld l, a
	ld a, [wc70c]
	ld h, a

.asm_17ded2
	call CloseSRAM
	call Function17e40f
	ret

Function17ded9:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $1f
	call CopyBytes
	call Function17e32b
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld hl, wc708
	ld a, [hli]
	ld [wCurPartySpecies], a
	ld [wTempEnemyMonSpecies], a
	ld a, [hli]
	ld [wCurPartyLevel], a
	ld a, [hli]
	ld b, a
	ld a, [wPartyCount]
	cp $6
	jp nc, Function17e026
	xor a
	ld [wMonType], a
	push hl
	push bc
	predef TryAddMonToParty
	farcall SetCaughtData
	pop bc
	pop hl
	bit 1, b
	jr z, .asm_17df33
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMonNicknames
	call SkipNames
	ld d, h
	ld e, l
	pop hl
	call CopyBytes
	pop bc
	jr .asm_17df37

.asm_17df33
	ld de, $6
	add hl, de

.asm_17df37
	bit 2, b
	jr z, .asm_17df5a
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMonOTs
	call SkipNames
	ld d, h
	ld e, l
	pop hl
	call CopyBytes
	ld a, [hli]
	ld b, a
	push hl
	farcall SetGiftPartyMonCaughtData
	pop hl
	pop bc
	jr .asm_17df5e

.asm_17df5a
	ld de, $7
	add hl, de

.asm_17df5e
	bit 3, b
	jr z, .asm_17df79
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1ID
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	pop bc
	jr .asm_17df7b

.asm_17df79
	inc hl
	inc hl

.asm_17df7b
	bit 4, b
	jr z, .asm_17dfd0
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1DVs
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1Species
	call GetPartyLocation
	ld a, [hl]
	ld [wCurSpecies], a
	call GetBaseData
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1MaxHP
	call GetPartyLocation
	ld d, h
	ld e, l
	push hl
	ld b, FALSE
	farcall CalcMonStats
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1HP
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	pop hl
	pop bc
	jr .asm_17dfd2

.asm_17dfd0
	inc hl
	inc hl

.asm_17dfd2
	bit 5, b
	jr z, .asm_17dfea
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1Item
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	ld a, [hli]
	ld [de], a
	pop bc
	jr .asm_17dfeb

.asm_17dfea
	inc hl

.asm_17dfeb
	bit 6, b
	jr z, .asm_17e01f
	push bc
	push hl
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1Moves
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	push de
	ld bc, $4
	call CopyBytes
	pop de
	push hl
	push de
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMon1PP
	call GetPartyLocation
	ld d, h
	ld e, l
	pop hl
	predef FillPP
	pop hl
	pop bc
	jp asm_17e0ee

.asm_17e01f
	ld de, $4
	add hl, de
	jp asm_17e0ee

Function17e026:
	ld a, BANK(sBoxCount)
	call OpenSRAM
	ld a, [sBoxCount]
	call CloseSRAM
	cp $14
	jp nc, .asm_17e0ea
	bit 0, b
	jp z, .asm_17e0ea
	push bc
	push hl
	farcall LoadEnemyMon
	farcall SendMonIntoBox
	farcall SetBoxMonCaughtData
	pop hl
	pop bc
	ld a, BANK(sBoxMonNicknames)
	call OpenSRAM
	bit 1, b
	jr z, .asm_17e067
	push bc
	ld bc, $b
	ld de, sBoxMonNicknames
	call CopyBytes
	pop bc
	jr .asm_17e06b

.asm_17e067
	ld de, $6
	add hl, de

.asm_17e06b
	bit 2, b
	jr z, .asm_17e08e
	push bc
	ld bc, $6
	ld de, sBoxMonOTs
	call CopyBytes
	ld a, [hli]
	ld b, a
	push hl
	call CloseSRAM
	farcall SetGiftBoxMonCaughtData
	ld a, $1
	call OpenSRAM
	pop hl
	pop bc
	jr .asm_17e092

.asm_17e08e
	ld de, $7
	add hl, de

.asm_17e092
	bit 3, b
	jr z, .asm_17e0a2
	push bc
	ld de, sBoxMon1ID
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	pop bc
	jr .asm_17e0a4

.asm_17e0a2
	inc hl
	inc hl

.asm_17e0a4
	bit 4, b
	jr z, .asm_17e0b4
	push bc
	ld de, sBoxMon1DVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	pop bc
	jr .asm_17e0b6

.asm_17e0b4
	inc hl
	inc hl

.asm_17e0b6
	bit 5, b
	ld a, [hli]
	jr z, .asm_17e0be
	ld [sBoxMon1Item], a

.asm_17e0be
	bit 6, b
	jr z, .asm_17e0e1
	push bc
	ld de, sBoxMon1Moves
	ld bc, $4
	call CopyBytes
	push hl
	ld hl, sBoxMon1Moves
	ld de, sBoxMon1PP
	predef FillPP
	call CloseSRAM
	pop hl
	pop bc
	inc hl
	inc hl
	jr asm_17e0ee

.asm_17e0e1
	call CloseSRAM
	ld de, $6
	add hl, de
	jr asm_17e0ee

.asm_17e0ea
	ld bc, $1a
	add hl, bc

asm_17e0ee:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	ldh [rSVBK], a
	push hl
	call Function17e349
	pop hl
	call Function17e40f
	ret

Function17e0fd:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $6
	call CopyBytes
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld hl, wc708
	ld a, [hli]
	ld [wCurItem], a
	ld a, [hli]
	ld [wItemQuantityChange], a
	push hl
	ld hl, wNumItems
	call ReceiveItem
	pop hl
	jr c, .asm_17e127
	inc hl
	inc hl

.asm_17e127
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld h, a
	ld l, b
	pop af
	ldh [rSVBK], a
	call Function17e40f
	ret

Function17e133:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $5
	call CopyBytes
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld hl, wc708
	ld a, [hli]
	ld [wScriptVar], a
	push hl
	farcall MobileCheckOwnMonAnywhere
	pop hl
	jr c, .asm_17e159
	inc hl
	inc hl

.asm_17e159
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld h, a
	ld l, b
	pop af
	ldh [rSVBK], a
	call Function17e40f
	ret

Function17e165:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $5
	call CopyBytes
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	ld hl, wc708
	ld a, [hli]
	ld [wCurItem], a
	push hl
	ld hl, wNumItems
	call CheckItem
	pop hl
	jr c, .asm_17e195
	push hl
	ld hl, wNumPCItems
	call CheckItem
	pop hl
	jr c, .asm_17e195
	inc hl
	inc hl

.asm_17e195
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld h, a
	ld l, b
	pop af
	ldh [rSVBK], a
	call Function17e40f
	ret

Function17e1a1:
	call IncCrashCheckPointer
	ld de, wc708
	ld bc, $d
	call CopyBytes
	ld a, [wc70a]
	cp $c0
	jr c, .asm_17e1bb
	ld a, [wc708]
	ldh [rSVBK], a
	jr .asm_17e1c1

.asm_17e1bb
	ld a, [wc708]
	call OpenSRAM

.asm_17e1c1
	ld a, [wc709]
	ld l, a
	ld a, [wc70a]
	ld h, a
	ld de, wc608
	ld a, [wc70b]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, [wc70a]
	cp $c0
	jr c, .asm_17e1e2
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17e1e5

.asm_17e1e2
	call CloseSRAM

.asm_17e1e5
	ld a, [wc70e]
	cp $c0
	jr c, .asm_17e1f3
	ld a, [wc70c]
	ldh [rSVBK], a
	jr .asm_17e1f9

.asm_17e1f3
	ld a, [wc70c]
	call OpenSRAM

.asm_17e1f9
	ld a, [wc70d]
	ld l, a
	ld a, [wc70e]
	ld h, a
	ld de, wc688
	ld a, [wc70b]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, [wc70e]
	cp $c0
	jr c, .asm_17e21a
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17e21d

.asm_17e21a
	call CloseSRAM

.asm_17e21d
	ld a, [wc70b]
	ld c, a
	ld hl, wc688
	ld de, wc608
.asm_17e227
	ld a, [de]
	inc de
	cp [hl]
	inc hl
	jr z, .asm_17e231
	jr c, .asm_17e23e
	jr .asm_17e248

.asm_17e231
	dec c
	jr nz, .asm_17e227
	ld a, [wc711]
	ld l, a
	ld a, [wc712]
	ld h, a
	jr .asm_17e250

.asm_17e23e
	ld a, [wc70f]
	ld l, a
	ld a, [wc710]
	ld h, a
	jr .asm_17e250

.asm_17e248
	ld a, [wc712 + 1]
	ld l, a
	ld a, [wc712 + 2]
	ld h, a

.asm_17e250
	call Function17e40f
	ret

Function17e254:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld [de], a
	call HlToCrashCheckPointer
	ret

Function17e261:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [de]
	add [hl]
	ld [de], a
	inc hl
	call HlToCrashCheckPointer
	ret

Function17e270:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [de]
	sub [hl]
	ld [de], a
	inc hl
	call HlToCrashCheckPointer
	ret

Function17e27f:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	call HlToCrashCheckPointer
	ld l, c
	ld h, b
	ld a, [de]
	add [hl]
	ld [de], a
	ret

Function17e293:
	call IncCrashCheckPointer
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	call HlToCrashCheckPointer
	ld l, c
	ld h, b
	ld a, [de]
	sub [hl]
	ld [de], a
	ret

Function17e2a7:
	call IncCrashCheckPointer
	call HlToCrashCheckPointer
	call Function17e32b
	xor a
	ld [wcf66], a
	farcall Function118233
	ld de, PostalMarkGFX
	ld hl, vTiles2 tile $60
	lb bc, BANK(PostalMarkGFX), 1
	call Get2bpp
	ld a, [wMobileErrorCodeBuffer]
	and a
	jr z, .asm_17e2d8
	cp $a
	jr z, .asm_17e2f7
	cp $b
	jr z, .asm_17e300
	call Function17e309
	ret

.asm_17e2d8
	call Function17d60b
	call Function17e349
	xor a
	ld [wcd7a], a
	ld a, BANK(s5_aa73)
	call OpenSRAM
	ld hl, s5_aa73
	ld de, s5_aa7f
	ld bc, $c
	call CopyBytes
	call CloseSRAM
	ret

.asm_17e2f7
	call Function17e349
	ld a, $1
	ld [wcd7a], a
	ret

.asm_17e300
	call Function17e349
	ld a, $2
	ld [wcd7a], a
	ret

Function17e309:
	ld a, $2
	ld [wc303], a
	call Function17dcaf
	call ClearScreen
	call Function17e349
	call Function17d5f6
	farcall DisplayMobileError
	call Function17e349
	call Function17dcaf
	xor a
	ld [wcd77], a
	ret

Function17e32b:
	ld a, $5
	call OpenSRAM
	ld hl, wc608
	ld de, s5_b0b1
	ld bc, $40
	call CopyBytes
	ld hl, wBGMapBuffer
	ld bc, $5b
	call CopyBytes
	call CloseSRAM
	ret

Function17e349:
	ld a, $5
	call OpenSRAM
	ld hl, s5_b0b1
	ld de, wc608
	ld bc, $40
	call CopyBytes
	ld de, wBGMapBuffer
	ld bc, $5b
	call CopyBytes
	call CloseSRAM
	ret

MACRO inc_crash_check_pointer_farcall
	call IncCrashCheckPointer
	call HlToCrashCheckPointer ; redundant
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a
	rept _NARG
		farcall \1
		shift
	endr
	pop af
	ldh [rSVBK], a
	ret
ENDM

IncCrashCheckPointer_SaveGameData:
	inc_crash_check_pointer_farcall _SaveGameData

IncCrashCheckPointer_SaveAfterLinkTrade:
	inc_crash_check_pointer_farcall SaveAfterLinkTrade

IncCrashCheckPointer_SaveBox:
	inc_crash_check_pointer_farcall SaveBox

IncCrashCheckPointer_SaveChecksum:
	inc_crash_check_pointer_farcall SaveChecksum

IncCrashCheckPointer_SaveTrainerRankingsChecksum:
	inc_crash_check_pointer_farcall UpdateTrainerRankingsChecksum2, BackupGSBallFlag

Function17e3e0:
	call IncCrashCheckPointer
	ld a, [hli]
	ld c, a
	call HlToCrashCheckPointer
	ld a, $1
	ldh [hBGMapMode], a
	call DelayFrames
	ret

Function17e3f0:
	call IncCrashCheckPointer
	call HlToCrashCheckPointer
.asm_17e3f6
	call JoyTextDelay
	ld hl, hJoyPressed
	ld a, [hl]
	and $1
	ret nz
	ld a, [hl]
	and $2
	ret nz
	call WaitBGMap
	jr .asm_17e3f6

Function17e409:
	ld hl, wcd77
	set 7, [hl]
	ret

Function17e40f:
	ld de, wBGPals1
	add hl, de
	jr HlToCrashCheckPointer

IncCrashCheckPointer:
	ld a, [wMobileCrashCheckPointer]
	ld l, a
	ld a, [wMobileCrashCheckPointer + 1]
	ld h, a
	inc hl

HlToCrashCheckPointer:
	ld a, l
	ld [wMobileCrashCheckPointer], a
	ld a, h
	ld [wMobileCrashCheckPointer + 1], a
	ret

Function17e427:
	ld hl, hJoyPressed
	ld a, [hl]
	and $1
	jr nz, .asm_17e432
	and $2
	ret z

.asm_17e432
	ld a, $3
	ld [wcd77], a
	ret

Function17e438:
	ld hl, wcd77
	inc [hl]
	ret

Function17e43d:
	ld a, [wBGMapBuffer]
	ld l, a
	ld a, [wcd21]
	ld h, a
	add hl, bc
	ret

Function17e447:
	ld a, [wBGMapBuffer]
	ld l, a
	ld a, [wcd21]
	ld h, a
	add hl, de
	ret

Function17e451:
	ld a, [wcd42]
	and a
	ret z
	call Function17e51b
	call Function17e4dd
	ld a, [wcd2e]
	push af
	ld a, [wcd49]
	ld l, a
	ld a, [wcd4a]
	ld h, a
	ld a, [wcd2f]
	ld [wcd2e], a
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	push hl
	hlcoord 0, 0
	ld bc, $14
	ld a, [wcd23]
	call AddNTimes
	ld a, [wCreditsTimer]
	ld c, a
	ld b, 0
	add hl, bc
	pop bc
	ld a, [wMobileCommsJumptableIndex]
.asm_17e48b
	push af
	push hl
	ld a, [wcd24]
.asm_17e490
	push af
	push hl
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	inc bc
	ld d, a
	push bc
	push hl
	ld a, [wBGMapBuffer]
	ld l, a
	ld a, [wcd21]
	ld h, a
	add hl, de
	push hl
	pop de
	pop hl
	call PlaceString
	pop bc
	pop hl
	ld a, [wcd26]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [wcd2e]
	inc a
	ld [wcd2e], a
	ld e, a
	ld a, [wcd42]
	cp e
	jr z, .asm_17e4d5
	pop af
	dec a
	jr nz, .asm_17e490
	pop hl
	ld a, [wcd27]
	ld de, $14
.asm_17e4cb
	add hl, de
	dec a
	jr nz, .asm_17e4cb
	pop af
	dec a
	jr nz, .asm_17e48b
	jr .asm_17e4d8

.asm_17e4d5
	pop af
	pop hl
	pop af

.asm_17e4d8
	pop af
	ld [wcd2e], a
	ret

Function17e4dd:
	ld a, [wcd2c]
	and $1
	ret z
	ld a, [wcd29]
	hlcoord 0, 0
	ld bc, $14
	call AddNTimes
	ld a, [wcd28]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wcd2f]
	and a
	jr z, .asm_17e4ff
	ld a, $61
	ld [hl], a

.asm_17e4ff
	ld a, [wcd2a]
	ld bc, $14
	call AddNTimes
	ld a, [wcd42]
	ld c, a
	ld a, [wcd2e]
	ld b, a
	ld a, [wcd24]
	add b
	cp c
	ret z
	ret nc
	ld a, $ee
	ld [hl], a
	ret

Function17e51b:
	ld a, [wcd28]
	ld hl, wCreditsTimer
	sub [hl]
	inc a
	ld [wcd4f], a
	hlcoord 0, 0
	ld bc, $14
	ld a, [wcd23]
	dec a
	call AddNTimes
	ld a, [wCreditsTimer]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wMobileCommsJumptableIndex]
	ld c, a
	ld a, [wcd27]
	call SimpleMultiply
.asm_17e544
	push af
	push hl
	ld a, [wcd4f]
	ld c, a
	ld b, 0
	ld a, $7f
	call ByteFill
	pop hl
	ld bc, $14
	add hl, bc
	pop af
	dec a
	jr nz, .asm_17e544
	ret

Function17e55b:
	ld a, [wcd42]
	and a
	ret z
	ld a, $ed
	call Function17e571
	ret

Function17e566:
	ld a, [wcd42]
	and a
	ret z
	ld a, $7f
	call Function17e571
	ret

Function17e571:
	push af
	hlcoord 0, 0
	ld bc, $14
	ld a, [wcd23]
	call AddNTimes
	ld a, [wCreditsTimer]
	ld c, a
	ld b, 0
	add hl, bc
	dec hl
	push hl
	ld a, [wcd31]
	dec a
	ld c, a
	ld a, [wcd27]
	call SimpleMultiply
	ld l, $0
	ld h, l
	ld bc, $14
	call AddNTimes
	ld a, [wcd30]
	dec a
	ld c, a
	ld a, [wcd26]
	call SimpleMultiply
	ld c, a
	ld b, 0
	add hl, bc
	pop bc
	add hl, bc
	pop af
	ld [hl], a
	ret

Function17e5af:
	ld a, [wcd2c]
	and $2
	ret z
	ld a, [wcd43]
	ld l, a
	ld a, [wMobileInactivityTimerMinutes]
	ld h, a
	bccoord 0, 0
	add hl, bc
	ld bc, $ffec
	add hl, bc
	ld a, [wMobileInactivityTimerSeconds]
	ld c, a
	ld b, 0
	ld a, [wMobileInactivityTimerFrames]
	call Function17e600
	ld a, [wcd2e]
	ld c, a
	ld b, 0
	ld a, [wcd4d]
	ld l, a
	ld a, [wcd4e]
	ld h, a
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [wBGMapBuffer]
	ld l, a
	ld a, [wcd21]
	ld h, a
	add hl, de
	push hl
	pop de
	ld a, [wcd43]
	ld l, a
	ld a, [wMobileInactivityTimerMinutes]
	ld h, a
	bccoord 0, 0
	add hl, bc
	call PlaceString
	ret

Function17e600:
.asm_17e600
	push af
	push hl
	push bc
	ld a, $7f
	call ByteFill
	pop bc
	pop hl
	ld de, $14
	add hl, de
	pop af
	dec a
	jr nz, .asm_17e600
	ret

Function17e613:
	push hl
	hlcoord 0, 0
	ld bc, $14
	ld a, [de]
	inc de
	push af
	ld a, [de]
	inc de
	and a
.asm_17e620
	jr z, .asm_17e626
	add hl, bc
	dec a
	jr .asm_17e620

.asm_17e626
	pop af
	ld c, a
	ld b, 0
	add hl, bc
	push hl
	ld a, [wcd53]
	ld [hli], a
	ld a, [de]
	inc de
	dec a
	dec a
	jr z, .asm_17e63f
	ld c, a
	ld a, [wcd53]
	inc a
.asm_17e63b
	ld [hli], a
	dec c
	jr nz, .asm_17e63b

.asm_17e63f
	ld a, [wcd53]
	add $2
	ld [hl], a
	pop hl
	ld bc, $14
	add hl, bc
	ld a, [de]
	dec de
	dec a
	dec a
	jr z, .asm_17e674
	ld b, a
.asm_17e651
	push hl
	ld a, [wcd53]
	add $3
	ld [hli], a
	ld a, [de]
	dec a
	dec a
	jr z, .asm_17e664
	ld c, a
	ld a, $7f
.asm_17e660
	ld [hli], a
	dec c
	jr nz, .asm_17e660

.asm_17e664
	ld a, [wcd53]
	add $4
	ld [hl], a
	pop hl
	push bc
	ld bc, $14
	add hl, bc
	pop bc
	dec b
	jr nz, .asm_17e651

.asm_17e674
	ld a, [wcd53]
	add $5
	ld [hli], a
	ld a, [de]
	dec a
	dec a
	jr z, .asm_17e689
	ld c, a
	ld a, [wcd53]
	add $6
.asm_17e685
	ld [hli], a
	dec c
	jr nz, .asm_17e685

.asm_17e689
	ld a, [wcd53]
	add $7
	ld [hl], a
	pop hl
	ret

Function17e691:
	push hl
	ld hl, NULL
	ld bc, $14
	ld a, [de]
	inc de
	push af
	ld a, [de]
	inc de
	inc de
	and a
.asm_17e69f
	jr z, .asm_17e6a5
	add hl, bc
	dec a
	jr .asm_17e69f

.asm_17e6a5
	pop af
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	dec de
.asm_17e6ac
	push af
	push hl
	ld a, [de]
.asm_17e6af
	push af
	push hl
	push hl
	bccoord 0, 0
	add hl, bc
	ld a, [hl]
	cp $7f
	jr z, .asm_17e6c2
	ld a, [wcd53]
	add $8
	jr .asm_17e6c7

.asm_17e6c2
	ld a, [wcd53]
	jr .asm_17e6c7

.asm_17e6c7
	pop hl
	bccoord 0, 0, wAttrmap
	add hl, bc
	ld [hl], a
	pop hl
	inc hl
	pop af
	dec a
	jr nz, .asm_17e6af
	pop hl
	ld bc, $14
	add hl, bc
	pop af
	dec a
	jr nz, .asm_17e6ac
	pop hl
	ret

Function17e6de:
	push af
	ld a, [wc708]
	ld l, a
	ld a, [wc709]
	ld h, a
	decoord 0, 0, wAttrmap
	add hl, de
	pop af
	ld b, $7
.asm_17e6ee
	push hl
	ld c, $7
.asm_17e6f1
	ld [hli], a
	dec c
	jr nz, .asm_17e6f1
	pop hl
	ld de, $14
	add hl, de
	dec b
	jr nz, .asm_17e6ee
	ret

PokemonNewsGFX:
INCBIN "gfx/mobile/pokemon_news.2bpp"

PostalMarkGFX:
INCBIN "gfx/font/postal_mark.2bpp"

PokemonNewsTileAttrmap:
INCBIN "gfx/mobile/pokemon_news.bin"

PokemonNewsPalettes:
INCLUDE "gfx/mobile/pokemon_news.pal"

RunMobileScript::
	ld a, $6
	call OpenSRAM
	inc de
.loop
	call _RunMobileScript
	jr c, .finished
	jr .loop

.finished
	call CloseSRAM
	ret

_RunMobileScript:
	ld a, [de]
	inc de
	cp "@"
	jr z, .finished
	cp $10 ; jumptable size
	jr nc, .finished
	dec a
	push de
	ld e, a
	ld d, 0
	ld hl, .Jumptable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.finished
	scf
	ret

; news text commands
.Jumptable:
	dw Function17f081 ; 1
	dw Function17f0f8 ; 2
	dw Function17f154 ; 3
	dw Function17f181 ; 4
	dw Function17f1d0 ; 5
	dw Function17f220 ; 6
	dw Function17f27b ; 7
	dw Function17f2cb ; 8
	dw MobileScript_PlayerName ; 9
	dw MobileScript_Prefecture ; a
	dw MobileScript_Zipcode    ; b
	dw Function17f3c9 ; c
	dw Function17f3f0 ; d
	dw Function17f41d ; e
	dw Function17f44f ; f
	dw Function17f44f ; 10

Function17f081:
	pop hl
	call Function17f524
	jr c, .asm_17f09f
	ld de, 4
	add hl, de
	ld a, [hli]
	inc hl
	inc hl
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f09d
	and a
	ret

.asm_17f09d
	scf
	ret

.asm_17f09f
	push bc
	ld de, wcd54
	ld bc, 7
	call CopyBytes
	pop bc
	push hl
	push bc
	call Function17f4f6
	pop bc
	ld a, [wcd54]
	ld e, a
	ld a, [wcd55]
	ld d, a
	add hl, de
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	push hl
	ld a, [wcd56]
	ld b, a
	ld a, [wcd57]
	ld c, a
	call MobilePrintNum
	ld a, l
	ld [wcd52], a
	ld a, h
	ld [wcd53], a
	ld a, [wcd59]
	and a
	jr z, .asm_17f0ee
	ld c, a
	ld a, [wcd57]
	inc a
	ld b, a
	ld e, l
	ld d, h
	dec de
.asm_17f0e0
	ld a, c
	cp b
	jr z, .asm_17f0ea
	ld a, [de]
	dec de
	ld [hld], a
	dec b
	jr .asm_17f0e0

.asm_17f0ea
	ld a, [wcd5a]
	ld [hl], a

.asm_17f0ee
	pop hl
	ld a, [wcd58]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f0f8:
	pop hl
	call Function17f524
	jr c, .asm_17f114
	ld de, $3
	add hl, de
	ld a, [hli]
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f112
	and a
	ret

.asm_17f112
	scf
	ret

.asm_17f114
	push bc
	ld de, wcd54
	ld bc, $4
	call CopyBytes
	pop bc
	push hl
	push bc
	call Function17f4f6
	ld a, [wcd54]
	ld e, a
	ld a, [wcd55]
	ld d, a
	add hl, de
	ld de, wc608
	ld a, [wcd56]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, "@"
	ld [de], a
	pop hl
	ld de, wc608
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, [wcd57]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f154:
	pop hl
	call Function17f524
	jr c, .asm_17f167
	inc hl
	inc hl
	ld e, l
	ld d, h
	ld a, [de]
	cp "@"
	jr z, .asm_17f165
	and a
	ret

.asm_17f165
	scf
	ret

.asm_17f167
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	pop bc
	push hl
	push bc
	call Function17f4f6
	add hl, de
	ld c, l
	ld b, h
	pop de
	farcall Function11c08f
	ld c, l
	ld b, h
	pop de
	and a
	ret

Function17f181:
	pop hl
	call Function17f524
	jr c, .asm_17f19d
	ld de, $2
	add hl, de
	ld a, [hli]
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f19b
	and a
	ret

.asm_17f19b
	scf
	ret

.asm_17f19d
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld [wcd54], a
	pop bc
	push hl
	push bc
	call Function17f4f6
	add hl, de
	ld a, [hl]
	ld c, a
	ld de, wc608
	farcall Mobile_DisplayPrefecture
	pop hl
	ld de, wc608
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f1d0:
	pop hl
	call Function17f524
	jr c, .asm_17f1ec
	ld de, $2
	add hl, de
	ld a, [hli]
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f1ea
	and a
	ret

.asm_17f1ea
	scf
	ret

.asm_17f1ec
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld [wcd54], a
	pop bc
	push hl
	push bc
	call Function17f4f6
	add hl, de
	ld a, [hl]
	ld a, BANK(wNamedObjectIndex)
	ldh [rSVBK], a
	ld [wNamedObjectIndex], a
	call GetPokemonName
	pop hl
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, $4
	ldh [rSVBK], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f220:
	pop hl
	call Function17f524
	jr c, .asm_17f23c
	ld de, $2
	add hl, de
	ld a, [hli]
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f23a
	and a
	ret

.asm_17f23a
	scf
	ret

.asm_17f23c
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld [wcd54], a
	pop bc
	push hl
	push bc
	call Function17f4f6
	add hl, de
	ld a, [hl]
	ld e, a
	ld d, 0
	ld hl, .Genders
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	pop hl
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

.Genders: dw .Boy, .Girl
.Boy:     db "Boy@"
.Girl:    db "Girl@"

Function17f27b:
	pop hl
	call Function17f524
	jr c, .asm_17f297
	ld de, $2
	add hl, de
	ld a, [hli]
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f295
	and a
	ret

.asm_17f295
	scf
	ret

.asm_17f297
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld [wcd54], a
	pop bc
	push hl
	push bc
	call Function17f4f6
	add hl, de
	ld a, [hl]
	ld a, $1
	ldh [rSVBK], a
	ld [wNamedObjectIndex], a
	call GetItemName
	pop hl
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, $4
	ldh [rSVBK], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f2cb:
	pop hl
	push bc
	ld a, [hli]
	ld [wcd54], a
	ld a, [hli]
	ld [wcd55], a
	ld a, [wcd2e]
	inc a
	ld [wcd56], a
	pop bc
	push hl
	ld l, c
	ld h, b
	push hl
	ld de, wcd56
	ld b, $1
	ld a, [wcd54]
	ld c, a
	call MobilePrintNum
	ld a, l
	ld [wcd52], a
	ld a, h
	ld [wcd53], a
	pop hl
	ld a, [wcd55]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

MobileScript_PlayerName:
	pop hl
	push bc
	ld a, [hli]
	ld [wcd54], a
	pop bc
	push hl
	push bc
	ld a, $1
	ldh [rSVBK], a
	ld hl, wPlayerName
	ld de, wc608
	ld bc, PLAYER_NAME_LENGTH
	call CopyBytes
	ld a, $4
	ldh [rSVBK], a
	pop hl
	ld de, wc608
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

MobileScript_Prefecture:
	pop hl
	push bc
	ld a, [hli]
	ld [wcd55], a
	and $f
	ld [wcd54], a
	pop bc
	push hl
	ld l, c
	ld h, b
	push hl
	ld a, [wcd55]
	bit 7, a
	jr nz, .read_downloaded_content_address
	ld a, BANK(sCrystalData)
	call OpenSRAM
	ld a, [sCrystalData + (wPrefecture - wCrystalData)]
	jr .display

.read_downloaded_content_address
	ld a, BANK(sDownloadedContentPrefectureAndZipcode)
	call OpenSRAM
	ld a, [sDownloadedContentPrefectureAndZipcode]

.display
	ld c, a
	call CloseSRAM
	ld de, wc608
	farcall Mobile_DisplayPrefecture
	pop hl
	ld de, wc608
	call PlaceString
	ld a, c
	ld [wcd52], a
	ld a, b
	ld [wcd53], a
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

MobileScript_Zipcode:
	pop hl
	push bc
	ld a, [hli]
	ld [wcd55], a
	and $f
	ld [wcd54], a
	pop bc
	push hl
	push bc
	ld l, c
	ld h, b
	ld a, [wcd55]
	bit 7, a
	jr nz, .read_downloaded_content_address
	ld a, BANK(sCrystalData)
	call OpenSRAM
	ld de, sCrystalData + (wZipCode - wCrystalData)
	jr .display

.read_downloaded_content_address
	ld a, BANK(sDownloadedContentPrefectureAndZipcode)
	call OpenSRAM
	ld de, sDownloadedContentPrefectureAndZipcode + 1

.display
	; We can't just use PrintText, because there may be no "@" at the end of the wZipCode (because I wanted to save 1 stupid byte of WRAM...).
	ld b, ZIPCODE_LENGTH + 1
.display_loop
	dec b
	jr z, .display_done

	ld a, [de]
	cp "@"
	jr z, .display_done

	cp -1
	jr nz, .no_overflow

	ld a, "0"

.no_overflow
	ld [hli], a
	inc de
	jr .display_loop

.display_done
	call CloseSRAM
	ld a, l
	ld [wcd52], a
	ld a, h
	ld [wcd53], a
	pop hl
	ld a, [wcd54]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f3c9:
	push bc
	ld hl, wcd36
	ld de, wc708
	ld bc, 12
	call CopyBytes
	pop de
	ld c, $0
	farcall Function11c075
	push hl
	ld hl, wc708
	ld de, wcd36
	ld bc, 12
	call CopyBytes
	pop bc
	pop de
	and a
	ret

Function17f3f0:
	pop hl
	push hl
	ld a, [hli]
	push af
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [de]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld hl, wBGPals1
	add hl, de
	ld e, l
	ld d, h
	pop hl
	call PlaceString
	pop af
	ld e, a
	ld d, 0
	pop hl
	add hl, de
	add hl, de
	inc hl
	inc hl
	inc hl
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	scf
	ret

Function17f41d:
	pop hl
	ld a, [hli]
	push hl
	push af
	ld l, c
	ld h, b
	ld bc, -wTilemap + $10000
	add hl, bc
	ld de, -SCREEN_WIDTH
	ld c, $1
.asm_17f42c
	ld a, h
	and a
	jr nz, .asm_17f435
	ld a, l
	cp SCREEN_WIDTH
	jr c, .asm_17f439

.asm_17f435
	add hl, de
	inc c
	jr .asm_17f42c

.asm_17f439
	hlcoord 0, 0
	ld de, SCREEN_WIDTH
	ld a, c
.asm_17f440
	and a
	jr z, .asm_17f447
	add hl, de
	dec a
	jr .asm_17f440

.asm_17f447
	pop af
	ld e, a
	ld d, 0
	add hl, de
	pop de
	and a
	ret

Function17f44f:
	pop hl
	call Function17f524
	jr c, .asm_17f46d
	ld de, $5
	add hl, de
	ld a, [hli]
	inc hl
	inc hl
	ld e, l
	ld d, h
	ld l, c
	ld h, b
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	cp "@"
	jr z, .asm_17f46b
	and a
	ret

.asm_17f46b
	scf
	ret

.asm_17f46d
	push bc
	ld de, wcd54
	ld bc, $8
	call CopyBytes
	pop bc
	push hl
	push bc
	ld a, [wcd56]
	cp $c0
	jr c, .asm_17f488
	ld a, [wcd54]
	ldh [rSVBK], a
	jr .asm_17f48e

.asm_17f488
	ld a, [wcd54]
	call OpenSRAM

.asm_17f48e
	ld a, [wcd55]
	ld l, a
	ld a, [wcd56]
	ld h, a
	ld de, wc608
	ld a, [wcd57]
	ld c, a
	ld b, 0
	call CopyBytes
	ld a, [wcd56]
	cp $c0
	jr c, .asm_17f4af
	ld a, $4
	ldh [rSVBK], a
	jr .asm_17f4b7

.asm_17f4af
	call CloseSRAM
	ld a, $6
	call OpenSRAM

.asm_17f4b7
	ld de, wc608
	pop hl
	push hl
	ld a, [wcd57]
	ld b, a
	ld a, [wcd58]
	ld c, a
	call MobilePrintNum
	ld a, l
	ld [wcd52], a
	ld a, h
	ld [wcd53], a
	ld a, [wcd5a]
	and a
	jr z, .asm_17f4ec
	ld c, a
	ld a, [wcd58]
	inc a
	ld b, a
	ld e, l
	ld d, h
	dec de
.asm_17f4de
	ld a, c
	cp b
	jr z, .asm_17f4e8
	ld a, [de]
	dec de
	ld [hld], a
	dec b
	jr .asm_17f4de

.asm_17f4e8
	ld a, [wcd5b]
	ld [hl], a

.asm_17f4ec
	pop hl
	ld a, [wcd59]
	call OffsetTextBasedOnScriptParameter
	pop de
	and a
	ret

Function17f4f6:
	ld a, [wcd6a]
	ld l, a
	ld a, [wcd6b]
	ld h, a
	ld a, [wcd47]
	ld c, a
	ld a, [wBGMapPalBuffer]
	ld b, a
	ld a, [wcd2e]
.asm_17f509
	and a
	ret z
	dec a
	add hl, bc
	jr .asm_17f509

OffsetTextBasedOnScriptParameter:
	and a
	jr z, .auto_adjust_offset
	ld c, a
	ld b, 0
	add hl, bc
	ld c, l
	ld b, h
	ret

.auto_adjust_offset
	ld a, [wcd52]
	ld c, a
	ld l, a
	ld a, [wcd53]
	ld b, a
	ld h, a
	ret

Function17f524:
	push hl
	push bc
	push de
	ld a, [wcd42]
	dec a
	ld b, a
	ld a, [wcd2e]
	cp b
	jr z, .asm_17f53a
	ld hl, wcd68
	cp [hl]
.asm_17f536
	pop de
	pop bc
	pop hl
	ret

.asm_17f53a
	scf
	jr .asm_17f536
