InitMobileProfile:
	xor a
	set 6, a
	ld [wd002], a
	ld hl, wMobileProfileParametersFilled
	set 0, [hl]
	ld a, c
	and a
	call z, InitCrystalData
	call ClearBGPalettes
	call LoadZipcodeWithUniversalFormat
	call RetrieveZipcodeInfo
	call DisableLCD
	farcall Mobile22_Clear24FirstOAM
	;farcall Mobile22_LoadMobileAdapterGFXIntoVRAM
	farcall Mobile22_LoadCursorGFXIntoVRAM
	ld b, TRUE
	farcall Mobile22_LoadCardFolderPals
	call EnableLCD

	ld a, [wd479]
	bit 1, a
	jr z, .not_yet_initialized
	ld a, [wMobileProfileParametersFilled]
	set 0, a
	set 1, a
	set 2, a
	set 3, a
	ld [wMobileProfileParametersFilled], a
.not_yet_initialized
	call SetCursorParameters_MobileProfile
	call LoadFontsExtra
	ld de, MobileUpArrowGFX
	ld hl, vTiles2 tile $10
	lb bc, BANK(MobileUpArrowGFX), 1
	call Request1bpp
	ld de, MobileDownArrowGFX
	ld hl, vTiles2 tile $11 ; $11 = down arrow tile.
	lb bc, BANK(MobileDownArrowGFX), 1
	call Request1bpp
	call LoadTilesAndDisplayMobileMenuBackground
	call ClearBGPalettes
	ld a, [wd002]
	bit 6, a
	jr z, .load_uninitialized_mobile_profile
	call DisplayInitializedMobileProfileLayout
	jr .display_initialized_menu
.load_uninitialized_mobile_profile
	ld a, $5
	ld [wMusicFade], a
	ld a, LOW(MUSIC_MOBILE_ADAPTER_MENU)
	ld [wMusicFadeID], a
	ld a, HIGH(MUSIC_MOBILE_ADAPTER_MENU)
	ld [wMusicFadeID + 1], a
	ld c, 20
	call DelayFrames
	ld b, CRYSTAL_CGB_MOBILE_1
	call GetCrystalCGBLayout
	call ClearBGPalettes
	hlcoord 0, 0
	ld b,  2
	ld c, 20
	call ClearBox
	hlcoord 0, 1
	ld a, $c
	ld [hl], a
	ld bc, $13
	add hl, bc
	ld [hl], a
	ld de, MobileProfileString
	hlcoord 1, 1
	call PlaceString
	hlcoord 0, 2
	ld b, $a
	ld c, $12
	call DisplayBlankGoldenBox
	hlcoord 2, 4 ; Position of Gender string
	ld de, MobileString_Gender
	call PlaceString
.display_initialized_menu
	hlcoord 2, 6 ; Position of Age string
	ld de, MobileString_Age
	call PlaceString
	hlcoord 2, 8 ; Position of Address string
	ld de, MobileString_Address
	call PlaceString
	hlcoord 2, 10 ; Position of Zip Code string
	ld de, MobileString_ZipCode
	call PlaceString
	hlcoord 2, 12  ; Position of OK string
	ld de, MobileString_OK
	call PlaceString
	ld a, [wd002]
	bit 6, a
	jr nz, .asm_48113
	ld a, [wPlayerGender]
	ld hl, Strings_484fb
	call GetNthString
	ld d, h
	ld e, l
	if DEF(_CRYSTAL_AU)
	hlcoord 13, 5 ; Default gender position in MOBILE menu
	elif DEF(_CRYSTAL_EU)
	hlcoord 13, 5 ; Default gender position in MOBILE menu
	else
	hlcoord 13, 5 ; Default gender position in MOBILE menu
	endc
	call PlaceString
.asm_48113
	if DEF(_CRYSTAL_AU)
	hlcoord 12, 7 ; Default age position in MOBILE menu
	elif DEF(_CRYSTAL_EU)
	hlcoord 12, 7 ; Default age position in MOBILE menu
	else
	hlcoord 13, 7 ; Default age position in MOBILE menu
	endc
	call Function487ec
	ld a, [wPrefecture]
	dec a
	ld hl, Prefectures
	call GetNthString
	ld d, h
	ld e, l
	if DEF(_CRYSTAL_AU)
	hlcoord 19 - REGION_CODE_STRING_LENGTH, 9 ; Default Prefectures position in MOBILE menu
	elif DEF(_CRYSTAL_EU)
	hlcoord 17 - REGION_CODE_STRING_LENGTH, 9 ; Default Prefectures position in MOBILE menu
	else
	hlcoord 18 - REGION_CODE_STRING_LENGTH, 9 ; Default Prefectures position in MOBILE menu
	endc
	call PlaceString
	call DisplayZipCodeRightAlign
	hlcoord 0, 14 ; 'Personal Info' box position
	ld b, $2
	ld c, $12
	call Textbox
	hlcoord 1, 16 ; 'Personal Info' text position
	ld de, MobileString_PersonalInfo
	call PlaceString
	call Mobile12_ClearBlankUserParameters
	call WaitBGMap2
	call SetPalettes
	call StaticMenuJoypad
	ld hl, wMenuCursorY
	ld b, [hl]
	push bc
	jr asm_4815f

RetrieveZipcodeInfo:
	ld a, [wPrefecture]
	dec a

	; Country
	ld hl, PrefectureToCountry
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wZipcodeCountry], a

	; Format
	ld hl, PrefectureZipcodeFormat
	add hl, bc ; HL contains the address of the format index.
	ld a, [hl]
	ld [wZipcodeFormat], a

	; Length
	ld hl, ZipcodeFormatLengths
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wZipcodeFormatLength], a
	ret

Function48157:
	call ScrollingMenuJoypad
	ld hl, wMenuCursorY
	ld b, [hl]
	push bc
asm_4815f:
	bit A_BUTTON_F, a
	jp nz, MobileProfileOptionPressed
	ld b, a
	ld a, [wd002]
	bit 6, a
	jr z, .dont_check_b_button
	ld hl, wd479
	bit 1, [hl]
	jr z, .dont_check_b_button
	bit B_BUTTON_F, b
	jr nz, .b_button
.dont_check_b_button
	jp Function48272

.b_button
	call ClearBGPalettes
	call SaveZipcodeWithUniversalFormat
	pop bc
	call ClearTilemap
	ld a, $ff
	ret

Mobile12_ClearBlankUserParameters:
	ld a, [wd479]
	bit 1, a
	jr nz, .asm_481f1
	ld a, [wMobileProfileParametersFilled]
	ld d, a
	call CheckIfAllProfileParametersHaveBeenFilled
	jr c, .asm_481a2
	lb bc, 1, 4
	hlcoord 2, 12
	call ClearBox
	jr .asm_481ad
.asm_481a2
	push de
	hlcoord 2, 12
	ld de, MobileString_OK
	call PlaceString
	pop de
.asm_481ad
	ld a, [wd002]
	bit 6, a
	jr nz, .asm_481c1
	bit 0, d
	jr nz, .asm_481c1
	lb bc, 1, 8
	if DEF(_CRYSTAL_AU)
	hlcoord 8, 5 ; Gender position
	elif DEF(_CRYSTAL_EU)
	hlcoord 11, 5 ; Gender position
	else
	hlcoord 9, 5 ; Gender position
	endc
	call ClearBox
.asm_481c1
	bit 1, d
	jr nz, .asm_481ce
	lb bc, 1, 8
	if DEF(_CRYSTAL_AU)
	hlcoord 11, 7 ; Age position ; Don't change
	elif DEF(_CRYSTAL_EU)
	hlcoord 11, 7 ; Age position ; Don't change
	else
	hlcoord 8, 7 ; Age position ; Don't change
	endc
	call ClearBox
.asm_481ce
	bit 2, d
	jr nz, .asm_481db
	lb bc, 1, 8
	if DEF(_CRYSTAL_AU)
	hlcoord 11, 9 ; prefecture position
	elif DEF(_CRYSTAL_EU)
	hlcoord 10, 9 ; prefecture position
	else
	hlcoord 10, 9 ; prefecture position
	endc
	call ClearBox
.asm_481db
	bit 3, d
	jr nz, .asm_481f1
	ld a, [wd479]
	bit 0, a
	jr nz, .asm_481f8
	lb bc, 1, 9
	if DEF(_CRYSTAL_AU)
	hlcoord 9, 11 ; Zip code location
	elif DEF(_CRYSTAL_EU)
	hlcoord 10, 11 ; Zip code location
	else
	hlcoord 10, 11 ; Zip code location
	endc
	call ClearBox
	jr .asm_48201
.asm_481f1
	ld a, [wd479]
	bit 0, a
	jr nz, .asm_48201
.asm_481f8
	hlcoord 9, 11 ; Position of 'Tell Later' after selecting
	ld de, .String_TellLater
	call PlaceString
.asm_48201
	ret

.String_TellLater:
	db "Tell Later@"

MobileProfileOptionPressed:
	call PlaceHollowCursor
	ld hl, wMenuCursorY
	ld a, [hl]
	push af
	ld a, [wd002]
	bit 6, a
	jr z, .asm_4821f
	pop af
	inc a
	push af
.asm_4821f
	pop af
	cp $1
	jr z, GenderPressed
	cp $2
	jp z, AgePressed
	cp $3
	jp z, RegionCodePressed
	cp $4
	jp z, ZipCodePressed
	ld a, $2
	call MenuClickSound
	ld a, [wd002]
	bit 6, a
	jr z, .LeaveMobileProfileMenu ; Useless.
	jr .LeaveMobileProfileMenu

	hlcoord 1, 15
	ld b, $2
	ld c, $12
	call ClearBox
	ld de, MobileString_ProfileChanged
	hlcoord 1, 16
	call PlaceString
	call WaitBGMap
	ld c, 48
	call DelayFrames

.LeaveMobileProfileMenu
	call ClearBGPalettes
	call SaveZipcodeWithUniversalFormat
	pop bc
	call ClearTilemap
	ld b, SCGB_DIPLOMA
	call GetSGBLayout
	ld hl, wd479
	set 1, [hl]
	xor a
	ret

Function48272:
	jp ReturnToMobileProfileMenu

MobileString_PersonalInfo:
	db "Personal Info@"

ClearMobileProfileBottomTextBox:
	lb bc, 2, 18
	hlcoord 1, 15
	call ClearBox
	ret

GenderPressed:
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileDesc_Gender
	call PlaceString
	ld hl, MenuHeader_0x484f1
	call LoadMenuHeader
	call SetCursorParameters_Gender
	if DEF(_CRYSTAL_AU)
	hlcoord 12, 2 ; Gender menu position
	ld b, $4
	ld c, $6
	call DisplayBlankGoldenBox
	hlcoord 14, 4 ; Position of Male Gender string in Gender menu
	ld de, String_484fb
	call PlaceString
	hlcoord 14, 6 ; Position of Female Gender string in Gender menu
	elif DEF(_CRYSTAL_EU)
	hlcoord 12, 2 ; Gender menu position
	ld b, $4
	ld c, $6
	call DisplayBlankGoldenBox
	hlcoord 14, 4 ; Position of Male Gender string in Gender menu
	ld de, String_484fb
	call PlaceString
	hlcoord 14, 6 ; Position of Female Gender string in Gender menu
	else
	hlcoord 13, 2 ; Gender menu position
	ld b, $4
	ld c, $5
	call DisplayBlankGoldenBox
	hlcoord 15, 4 ; Position of Male Gender string in Gender menu
	ld de, String_484fb
	call PlaceString
	hlcoord 15, 6 ; Position of Female Gender string in Gender menu	
	endc
	ld de, String_484ff
	call PlaceString
	call WaitBGMap
	ld a, [wPlayerGender]
	inc a
	ld [wMenuCursorPosition], a
	call StaticMenuJoypad
	call PlayClickSFX
	call ExitMenu
	bit A_BUTTON_F, a
	jp z, ReturnToMobileProfileMenu
	ld hl, wMenuCursorY
	ld a, [hl]
	ld hl, Strings_484fb
	cp $1
	jr z, .asm_482ed
.asm_482e1
	ld a, [hli]
	cp $50
	jr nz, .asm_482e1
	ld a, 1 << PLAYERGENDER_FEMALE_F
	ld [wPlayerGender], a
	jr .asm_482f1
.asm_482ed
	xor a
	ld [wPlayerGender], a
.asm_482f1
	ld d, h
	ld e, l
	if DEF(_CRYSTAL_AU)
	hlcoord 12, 5 ; Gender position
	elif DEF(_CRYSTAL_EU)
	hlcoord 12, 5 ; Gender position
	else
	hlcoord 13, 5 ; Gender position
	endc
	call PlaceString
	ld a, [wMobileProfileParametersFilled]
	set 0, a
	ld [wMobileProfileParametersFilled], a
	jp ReturnToMobileProfileMenu

RegionCodePressed:
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileDesc_Address
	call PlaceString
	ld hl, MenuHeader_0x48504
	call LoadMenuHeader
	ld hl, MenuHeader_0x48513
	call LoadMenuHeader
	hlcoord 16 - REGION_CODE_STRING_LENGTH, 0
	ld b, 12
	ld c, REGION_CODE_STRING_LENGTH + 2
	call DisplayBlankGoldenBox ; This has to do with some display.
	ld a, [wMenuCursorPosition]
	ld b, a
	ld a, [wMenuScrollPosition]
	ld c, a
	push bc
	ld a, [wPrefecture]
	dec a
	cp NUM_REGION_CODES
	jr c, .asm_4833f
	sub NUM_REGION_CODES
	inc a
	ld [wMenuCursorPosition], a
	ld a, NUM_REGION_CODES
.asm_4833f
	ld [wMenuScrollPosition], a
	farcall Mobile_OpenAndCloseMenu_HDMATransferTilemapAndAttrmap
.asm_48348
	call ScrollingMenu
	ld d, $6
	ld e, NUM_REGION_CODES
	call RegionCodeEdit_LeftRight
	jr c, .asm_48348
	ld d, a
	pop bc
	ld a, b
	ld [wMenuCursorPosition], a
	ld a, c
	ld [wMenuScrollPosition], a
	ld a, d
	push af
	call ExitMenu
	call ExitMenu
	pop af
	ldh a, [hJoyPressed]
	bit A_BUTTON_F, a
	jr z, .asm_48377
	call SavePrefectureAndDisplayIt
	ld a, [wMobileProfileParametersFilled]
	set 2, a
	ld [wMobileProfileParametersFilled], a
.asm_48377
	call Mobile12_ClearBlankUserParameters
	farcall Mobile_OpenAndCloseMenu_HDMATransferTilemapAndAttrmap
	jp ReturnToMobileProfileMenu

RegionCodeEdit_LeftRight:
	push bc
	push af
	bit D_LEFT_F, a
	jr nz, .pressed_left

	bit D_RIGHT_F, a
	jr nz, .pressed_right

	and a
	jr .quit

.pressed_left
	ld a, [wMenuScrollPosition]
	sub d
	ld [wMenuScrollPosition], a
	jr nc, .done
	xor a
	ld [wMenuScrollPosition], a
	jr .done

.pressed_right
	ld a, [wMenuScrollPosition]
	add d
	ld [wMenuScrollPosition], a
	cp e
	jr c, .done
	ld a, e
	ld [wMenuScrollPosition], a
	jr .done

.done
	ld hl, wMenuCursorY
	ld a, [hl]
	ld [wMenuCursorPosition], a
	scf
.quit
	pop bc
	ld a, b
	pop bc
	ret

SavePrefectureAndDisplayIt:
	ld hl, wScrollingMenuCursorPosition
	ld a, [hl]
	inc a
	ld [wPrefecture], a
	
	ld a, [wZipcodeCountry]
	ld e, a
	call RetrieveZipcodeInfo
	ld a, [wZipcodeCountry]
	cp e
	jr z, .zipcode_reset_managed ; If the previous and current zipcode formats match, there's no need to reset the zipcode.	

	; We simulate a press on Tell Later.
	call TellNowTellLaterMenu.pressed_tell_later

.zipcode_reset_managed
	ld hl, wScrollingMenuCursorPosition
	ld a, [hl]
	ld b, a
	ld hl, Prefectures
.outer_loop
	and a
	jr z, .loop_end
.inner_loop
	ld a, [hli]
	cp "@"
	jr nz, .inner_loop
	ld a, b
	dec a
	ld b, a
	jr .outer_loop
.loop_end
	ld d, h
	ld e, l
	ld b, $2
	ld c, $8
	if DEF(_CRYSTAL_AU)
	hlcoord 11, 8 ; ??? Clears the surrounding tiles when prefecture is selected, needs to be moved with preferectures
	call ClearBox
	hlcoord 18 - REGION_CODE_STRING_LENGTH, 9 ; Prefectures position when selected
	elif DEF(_CRYSTAL_EU)
	hlcoord 10, 8 ; ??? Clears the surrounding tiles when prefecture is selected, needs to be moved with preferectures
	call ClearBox
	hlcoord 17 - REGION_CODE_STRING_LENGTH, 9 ; Prefectures position when selected
	else
	hlcoord 11, 8 ; ??? Clears the surrounding tiles when prefecture is selected, needs to be moved with preferectures
	call ClearBox
	hlcoord 18 - REGION_CODE_STRING_LENGTH, 9 ; Prefectures position when selected
	endc
	call PlaceString
	ret

Function483e8:
	push de
	ld hl, Prefectures
	ld a, [wMenuSelection]
	cp $ff
	jr nz, .asm_483f8
	ld hl, LastPrefecture ; Prefectures + (NUM_REGION_CODES - 1) * REGION_CODE_STRING_LENGTH ; last string
	jr .asm_48405

.asm_483f8
	ld d, a
	and a
	jr z, .asm_48405
.asm_483fc
	ld a, [hli]
	cp "@"
	jr nz, .asm_483fc
	ld a, d
	dec a
	jr .asm_483f8

.asm_48405
	ld d, h
	ld e, l
	pop hl
	call PlaceString
	ret

ReturnToMobileProfileMenu:
	call Mobile12_ClearBlankUserParameters
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileString_PersonalInfo
	call PlaceString
	call SetCursorParameters_MobileProfile
	pop bc
	ld hl, wMenuCursorY
	ld [hl], b
	ld a, [wd002]
	bit 6, a
	jr nz, .narrower_box
	ld b, 9
	ld c, 1
	hlcoord 1, 4
	call ClearBox
	jp Function48157

.narrower_box
	ld b, 7
	ld c, 1
	hlcoord 1, 6
	call ClearBox
	jp Function48157

; Inputs: char pool index in D, char index (within char pool) in A, left offset in B, screen tile coord in HL.
Mobile12_Index2CharDisplay:
	push hl
	push de

	push af
	ld a, d
	call GetCurCharpoolAddress
	pop af

	ld e, a ; A is the char index within the current char pool, given as a parameter of this function.
	add hl, de
	pop de
	ld a, [hl]
	pop hl
	ld [hl], a
	ret

MobileProfileString:         db "  Mobile Profile@"
MobileString_Gender:         db "Gender@"
MobileString_Age:            db "Age@"
MobileString_Address:        db "Address@"
	if DEF(_CRYSTAL_AU)
MobileString_ZipCode:        db "Postcode@"
	elif DEF(_CRYSTAL_EU)
MobileString_ZipCode:        db "Postcode@"
	else
MobileString_ZipCode:        db "Zip Code@"
	endc
MobileString_OK:             db "OK@"
MobileString_ProfileChanged: db "Profile Changed@"
MobileDesc_Gender:           db "Boy or girl?@"
MobileDesc_Age:              db "How old are you?@"
MobileDesc_Address:          db "Where do you live?@"
	if DEF(_CRYSTAL_AU)
MobileDesc_ZipCode:          db "Your post code?@"
	elif DEF(_CRYSTAL_EU)
MobileDesc_ZipCode:          db "Your post code?@"
	else
MobileDesc_ZipCode:          db "Your zip code?@"
	endc

MenuHeader_0x484f1:
	db MENU_BACKUP_TILES ; flags
if DEF(_CRYSTAL_AU)
	menu_coords 8, 2, SCREEN_WIDTH - 1, 7 ; For clearing the Gender box
elif DEF(_CRYSTAL_EU)
	menu_coords 10, 2, SCREEN_WIDTH - 1, 7 ; For clearing the Gender box
else
	menu_coords 10, 2, SCREEN_WIDTH - 1, 7 ; For clearing the Gender box
endc
	dw MenuData_0x484f9
	db 1 ; default option

MenuData_0x484f9:
	db STATICMENU_CURSOR | STATICMENU_WRAP ; flags
	db 2 ; items
Strings_484fb:
String_484fb: db "Boy @"
String_484ff: db "Girl@"

	if DEF(_CRYSTAL_AU)
MenuHeader_0x48504:
	db MENU_BACKUP_TILES ; flags
	menu_coords 16 - REGION_CODE_STRING_LENGTH, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1 ; For clearing the Address Box

MenuHeader_0x48509:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 5, SCREEN_WIDTH - 1, 8 ; For clearing the Age Box

MenuHeader_ZipCodeEditBox:
	if DEF(_CRYSTAL_AU)
	db MENU_BACKUP_TILES ; flags
	menu_coords 15 - ZIPCODE_LENGTH, 10, SCREEN_WIDTH - 1, TEXTBOX_Y - 0 ; For clearing the Zip Code box
	else
	db MENU_BACKUP_TILES ; flags
	menu_coords 18 - ZIPCODE_LENGTH, 10, SCREEN_WIDTH - 1, TEXTBOX_Y - 0 ; For clearing the Zip Code box
	endc
	;Bounding of left side ; bounding of top ; bounding of right side ; bounding of bottom

MenuHeader_0x48513:
	db MENU_BACKUP_TILES ; flags
	menu_coords 17 - REGION_CODE_STRING_LENGTH, 1, 18, 12 ; The placement of the text in the address box
	dw MenuData_0x4851b
	db 1 ; default option
	elif DEF(_CRYSTAL_EU)
MenuHeader_0x48504:
	db MENU_BACKUP_TILES ; flags
	menu_coords 16 - REGION_CODE_STRING_LENGTH, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1 ; For clearing the Address Box

MenuHeader_0x48509:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 5, SCREEN_WIDTH - 1, 8 ; For clearing the Age Box

MenuHeader_ZipCodeEditBox:
	db MENU_BACKUP_TILES ; flags
	menu_coords 18 - ZIPCODE_LENGTH, 10, SCREEN_WIDTH - 1, TEXTBOX_Y - 0 ; For clearing the Zip Code box

	;Bounding of left side ; bounding of top ; bounding of right side ; bounding of bottom

MenuHeader_0x48513:
	db MENU_BACKUP_TILES ; flags
	menu_coords 17 - REGION_CODE_STRING_LENGTH, 1, 18, 12 ; The placement of the text in the address box
	dw MenuData_0x4851b
	db 1 ; default option
	else
MenuHeader_0x48504:
	db MENU_BACKUP_TILES ; flags
	menu_coords 16 - REGION_CODE_STRING_LENGTH, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1 ; For clearing the Address Box

MenuHeader_0x48509:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 5, SCREEN_WIDTH - 1, 8 ; For clearing the Age Box

MenuHeader_ZipCodeEditBox:
	db MENU_BACKUP_TILES ; flags
	menu_coords 18 - ZIPCODE_LENGTH, 10, SCREEN_WIDTH - 1, TEXTBOX_Y - 0 ; For clearing the Zip Code box

	;Bounding of left side ; bounding of top ; bounding of right side ; bounding of bottom

MenuHeader_0x48513:
	db MENU_BACKUP_TILES ; flags
	menu_coords 17 - REGION_CODE_STRING_LENGTH, 1, 18, 12 ; The placement of the text in the address box
	dw MenuData_0x4851b
	db 1 ; default option
	endc

MenuData_0x4851b:
	db SCROLLINGMENU_DISPLAY_ARROWS | SCROLLINGMENU_ENABLE_RIGHT | SCROLLINGMENU_ENABLE_LEFT | SCROLLINGMENU_CALL_FUNCTION1_CANCEL ; flags
	db 6, 0 ; rows, columns
	db SCROLLINGMENU_ITEMS_NORMAL ; item format
	dba .Items
	dba Function483e8
	dba NULL
	dba NULL

.Items:
	db NUM_REGION_CODES - 1 ; The number of locations in the prefectures list (-1 because it starts at 0)
DEF x = 0
rept NUM_REGION_CODES - 1 ; The number of locations in the prefectures list (-1 because it starts at 0)
	db x
	DEF x = x + 1
endr
	db -1

DisplayInitializedMobileProfileLayout: ; Clears the 4 top lines, displays the "Mobile Profile" title, and displays an empty golden box.
	ld c, 7
	call DelayFrames
	ld b, CRYSTAL_CGB_MOBILE_1
	call GetCrystalCGBLayout
	call ClearBGPalettes
	hlcoord 0, 0
	ld b, 4
	ld c, SCREEN_WIDTH
	call ClearBox
	hlcoord 0, 2
	ld a, $c ; $c == pokeball char.
	ld [hl], a
	ld bc, SCREEN_WIDTH - 1
	add hl, bc
	ld [hl], a
	ld de, MobileProfileString
	hlcoord 1, 2
	call PlaceString
	hlcoord 0, 4
	ld b, $8
	ld c, $12
	call DisplayBlankGoldenBox
	ret

SetCursorParameters_MobileProfile:
	ld hl, w2DMenuCursorInitY
	ld a, [wd002]
	bit 6, a
	jr nz, .start_at_6
	ld a, 4
	ld [hli], a
	jr .got_init_y

.start_at_6
	ld a, 6
	ld [hli], a
.got_init_y
	ld a, 1
	ld [hli], a ; init x
	ld a, [wd002]
	bit 6, a
	jr nz, .check_wd479
	call CheckIfAllProfileParametersHaveBeenFilled
	ld a, 4
	jr nc, .got_num_rows_1
	ld a, 5
.got_num_rows_1
	ld [hli], a
	jr .got_num_rows_2

.check_wd479 ; We only reach this line when the Mobile Profile had been previously initialized.
	ld a, [wd479]
	bit 1, a ; Is this the same as wd002 bit 6?
	jr nz, .four_rows
	call CheckIfAllProfileParametersHaveBeenFilled
	jr c, .four_rows
	ld a, 3 ; In case the player managed to skip the initial Mobile Profile setup (that you can only skip after filling all parameters), we only set 3 rows, as the OK button should be hidden.
	ld [hli], a
	jr .got_num_rows_2

.four_rows
	ld a, 4
	ld [hli], a
.got_num_rows_2
	ld a, 1
	ld [hli], a ; num cols
	ld [hl], 0 ; flags 1
	set 5, [hl]
	inc hl
	xor a
	ld [hli], a ; flags 2
	ld a, $20 ; == ln a, 2, 0 -> Y offset = 2; X offset = 0.
	ld [hli], a ; cursor offsets
	ld a, A_BUTTON
	add D_UP
	add D_DOWN
	push af
	ld a, [wd002]
	bit 6, a
	jr z, .got_joypad_mask ; If the Mobile Profile has not been initialized yet, we prevent the player from leaving this screen until all parameters are filled and the OK button shows.
	pop af
	add B_BUTTON
	push af
.got_joypad_mask
	pop af
	ld [hli], a
	ld a, $1
	ld [hli], a ; cursor y
	ld [hli], a ; cursor x
	xor a
	ld [hli], a ; off char
	ld [hli], a ; cursor tile
	ld [hli], a ; cursor tile + 1
	ret

CheckIfAllProfileParametersHaveBeenFilled: ; Returns carry if all parameters have been filled.
;	 ld a, [wMobileProfileParametersFilled]
;	 and $f
;	 cp $f
;	 jr nz, .clear_carry
;	 scf
;	 ret
; .clear_carry
;	 and a
;	 ret

	; The following code bit does the same as the code commented out above, but is slower.
	ld a, [wMobileProfileParametersFilled]
	bit 0, a
	jr z, .clear_carry
	bit 1, a
	jr z, .clear_carry
	bit 2, a
	jr z, .clear_carry
	bit 3, a
	jr z, .clear_carry
	scf
	ret

.clear_carry
	and a
	ret

SetCursorParameters_Gender:
	ld hl, w2DMenuCursorInitY
	ld a, 4
	ld [hli], a
	if DEF(_CRYSTAL_AU)
	ld a, 13 ; x axis position of the gender cursor
	elif DEF(_CRYSTAL_EU)
	ld a, 13 ; x axis position of the gender cursor
	else
	ld a, 14 ; x axis position of the gender cursor
	endc
	ld [hli], a ; init x
	ld a, 2
	ld [hli], a ; num rows
	ld a, 1
	ld [hli], a ; num cols
	ld [hl], 0 ; flags 1
	set 5, [hl] ; Wrap around vertically.
	inc hl
	xor a
	ld [hli], a ; flags 2
	ln a, 2, 0 ; Y offset = 2; X offset = 0.
	ld [hli], a ; Sets cursor offsets.
	ld a, A_BUTTON
	add B_BUTTON
	ld [hli], a ; joypad filter
	; ld a, [wPlayerGender]
	; xor 1 << PLAYERGENDER_FEMALE_F
	; inc a
	ld a, [wPlayerGender]
	and a
	jr z, .male
	ld a, 2
	jr .okay_gender

.male
	ld a, 1
.okay_gender
	ld [hli], a ; cursor y
	ld a, $1
	ld [hli], a ; cursor x
	xor a
	ld [hli], a ; off char
	ld [hli], a ; cursor tile
	ld [hli], a ; cursor tile + 1
	ret

AgePressed:
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileDesc_Age
	call PlaceString
	ld hl, MenuHeader_0x48509
	call LoadMenuHeader
	ldh a, [hInMenu]
	push af
	ld a, $1
	ldh [hInMenu], a
	if DEF(_CRYSTAL_AU)
	hlcoord 11, 6 ; Age menu position
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	call WaitBGMap
	ld a, [wAge]
	and a
	jr z, .asm_487ab
	cp $64
	jr z, .asm_487b2
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 13, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
	jr .asm_487b7
.asm_487ab
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	jr .asm_487b7
.asm_487b2
	hlcoord 13, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
.asm_487b7
	hlcoord 12, 7 ; Age position
	elif DEF(_CRYSTAL_EU)
	hlcoord 11, 6 ; Age menu position
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	call WaitBGMap
	ld a, [wAge]
	and a
	jr z, .asm_487ab
	cp $64
	jr z, .asm_487b2
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 13, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
	jr .asm_487b7
.asm_487ab
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	jr .asm_487b7
.asm_487b2
	hlcoord 13, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
.asm_487b7
	hlcoord 12, 7 ; Age position
	else
	hlcoord 12, 6 ; Age menu position
	ld b, $1
	ld c, $6
	call DisplayBlankGoldenBox
	call WaitBGMap
	ld a, [wAge]
	and a
	jr z, .asm_487ab
	cp $64
	jr z, .asm_487b2
	hlcoord 14, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 14, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
	jr .asm_487b7
.asm_487ab
	hlcoord 14, 6 ; Age menu up arrow position
	ld [hl], $10
	jr .asm_487b7
.asm_487b2
	hlcoord 14, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
.asm_487b7
	hlcoord 13, 7 ; Age position
	endc
	call Function487ec
	ld c, 10
	call DelayFrames
	ld a, [wAge]
	push af
.asm_487c6
	call JoyTextDelay
	call Function4880e
	jr nc, .asm_487c6
	ld a, $1
	call MenuClickSound
	pop bc
	jr nz, .asm_487da
	ld a, b
	ld [wAge], a
.asm_487da
	ld a, [wAge]
	call ExitMenu
	if DEF(_CRYSTAL_AU)
	hlcoord 12, 7 ; Age position
	elif DEF(_CRYSTAL_EU)
	hlcoord 12, 7 ; Age position
	else
	hlcoord 13, 7 ; Age position
	endc
	call Function487ec
	pop af
	ldh [hInMenu], a
	jp ReturnToMobileProfileMenu

Function487ec:
	push hl
	ld de, wAge
	call Function487ff
	pop hl
rept 4
	inc hl
endr
	ld de, String_4880d
	call PlaceString
	ret

Function487ff:
	push hl
	ld a, " "
	ld [hli], a
	ld [hl], a
	pop hl
	ld b, PRINTNUM_LEADINGZEROS | 1
	ld c, 3
	call PrintNum
	ret

String_4880d:
	db "@"

Function4880e:
	ldh a, [hJoyPressed]
	and A_BUTTON
	jp nz, Function488b9
	ldh a, [hJoyPressed]
	and B_BUTTON
	jp nz, Function488b4
	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .asm_48843
	ld a, [hl]
	and D_DOWN
	jr nz, .asm_48838
	ld a, [hl]
	and D_LEFT
	jr nz, .asm_4884f
	ld a, [hl]
	and D_RIGHT
	jr nz, .asm_4885f
	call DelayFrame
	and a
	ret
.asm_48838
	ld hl, wAge
	ld a, [hl]
	and a
	jr z, .asm_48840
	dec a
.asm_48840
	ld [hl], a
	jr .asm_4886f
.asm_48843
	ld hl, wAge
	ld a, [hl]
	cp $64
	jr nc, .asm_4884c
	inc a
.asm_4884c
	ld [hl], a
	jr .asm_4886f
.asm_4884f
	ld a, [wAge]
	cp $5b
	jr c, .asm_48858
	ld a, $5a
.asm_48858
	add $a
	ld [wAge], a
	jr .asm_4886f
.asm_4885f
	ld a, [wAge]
	cp $a
	jr nc, .asm_48868
	ld a, $a
.asm_48868
	sub $a
	ld [wAge], a
	jr .asm_4886f
.asm_4886f
	ld a, [wAge]
	and a
	jr z, .asm_48887
	cp $64
	jr z, .asm_48898
	jr z, .asm_488a7
	if DEF(_CRYSTAL_AU)
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 13, 8 ; Age menu down arrow position
	ld [hl], $11
	jr .asm_488a7
.asm_48887
	hlcoord 11, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	hlcoord 13, 6 ; Age menu up arrow position when using D-Pad
	ld [hl], $10
	jr .asm_488a7
.asm_48898
	hlcoord 11, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	hlcoord 13, 8 ; Age menu down arrow position when using D-Pad
	ld [hl], $11
.asm_488a7
	hlcoord 12, 7 ; Age position
	elif DEF(_CRYSTAL_EU)
	hlcoord 13, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 13, 8 ; Age menu down arrow position
	ld [hl], $11
	jr .asm_488a7
.asm_48887
	hlcoord 11, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	hlcoord 13, 6 ; Age menu up arrow position when using D-Pad
	ld [hl], $10
	jr .asm_488a7
.asm_48898
	hlcoord 11, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $7
	call DisplayBlankGoldenBox
	hlcoord 13, 8 ; Age menu down arrow position when using D-Pad
	ld [hl], $11
.asm_488a7
	hlcoord 12, 7 ; Age position
	else
	hlcoord 14, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 14, 8 ; Age menu down arrow position
	ld [hl], $11
	jr .asm_488a7
.asm_48887
	hlcoord 12, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $6
	call DisplayBlankGoldenBox
	hlcoord 14, 6 ; Age menu up arrow position when using D-Pad
	ld [hl], $10
	jr .asm_488a7
.asm_48898
	hlcoord 12, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $6
	call DisplayBlankGoldenBox
	hlcoord 14, 8 ; Age menu down arrow position when using D-Pad
	ld [hl], $11
.asm_488a7
	hlcoord 13, 7 ; Age position
	endc
	call Function487ec
	call WaitBGMap
	ld a, $1
	and a
	ret

Function488b4:
	ld a, $0
	and a
	scf
	ret

Function488b9:
	ld a, [wMobileProfileParametersFilled]
	set 1, a
	ld [wMobileProfileParametersFilled], a
	scf
	ret

MobileUpArrowGFX:
INCBIN "gfx/mobile/up_arrow.1bpp"

MobileDownArrowGFX:
INCBIN "gfx/mobile/down_arrow.1bpp"

ZipCodePressed:
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileDesc_ZipCode
	call PlaceString
	call TellNowTellLaterMenu
	jp c, ReturnToMobileProfileMenu

	if DEF(_CRYSTAL_AU)
	hlcoord 8, 12 ; Clearing the potential "Tell Later" text.
	lb bc, 1, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	elif DEF(_CRYSTAL_EU)
	hlcoord 8, 12 ; Clearing the potential "Tell Later" text.
	lb bc, 1, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	else
	hlcoord 8, 12 ; Clearing the potential "Tell Later" text.
	lb bc, 1, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	endc
	call ClearBox

	ld hl, MenuHeader_ZipCodeEditBox
	call LoadMenuHeader

	ldh a, [hInMenu]
	push af
	ld a, TRUE
	ldh [hInMenu], a

	if DEF(_CRYSTAL_AU)
	hlcoord 15 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH + 3; Zip Code Menu width
	call DisplayBlankGoldenBox
	hlcoord 16 - ZIPCODE_LENGTH, 11 ; Zip Code Position
	elif DEF(_CRYSTAL_EU)
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	call DisplayBlankGoldenBox
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position
	else
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	call DisplayBlankGoldenBox
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position
	endc
	call DisplayZipCode
	call WaitBGMap
	; Backup of the zip code, in case the player cancels.
	ld a, [wZipCode + 0]
	ld b, a
	ld a, [wZipCode + 1]
	ld c, a
	push bc
	ld a, [wZipCode + 2]
	ld b, a
	ld a, [wZipCode + 3]
	ld c, a
	push bc
	ld a, [wZipCode + 4]
	ld b, a
	ld a, [wZipCode + 5]
	ld c, a
	push bc
	ld a, [wZipCode + 6]
	ld b, a
	ld c, 0
	push bc
	
	; We look for the starting char index. We skip all non-editable chars (those with a charpool length of 1 or 0).
	ld b, $0
	ld d, -1
.check_editable_char_loop
	inc d
	ld a, [wZipcodeFormatLength]
	cp d
	jp z, ZipCodeEditMenu ; None of the chars of this zipcode format are editable (EU-AD only), so we automatically save it and quit.
	jp c, ZipCodeEditMenu ; None of the chars of this zipcode format are editable (EU-AD only), so we automatically save it and quit.

	call Zipcode_GetCharPoolLengthForGivenCharSlot
	cp 2
	jr c, .check_editable_char_loop


ZipCodeEditMenu:
	if DEF(_CRYSTAL_AU)	
	hlcoord 11 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	ld c, a
	ld b, 0
	ld a, " "
	call ByteFill ; fill bc bytes with the value of a, starting at hl
	ld b, e
	elif DEF(_CRYSTAL_EU)
	hlcoord 11 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	ld c, a
	ld b, 0
	ld a, " "
	call ByteFill ; fill bc bytes with the value of a, starting at hl
	ld b, e	
	else
	hlcoord 12 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	ld c, a
	ld b, 0
	ld a, " "
	call ByteFill ; fill bc bytes with the value of a, starting at hl
	ld b, e
	endc
	push bc
	call JoyTextDelay
	ldh a, [hJoyDown]
	and a
	jp z, InputZipcodeCharacters_B0 ; If no button is pressed, jump to InputZipcodeCharacters_B0.

	bit A_BUTTON_F, a
	jp nz, InputZipcodeCharacters_B0 ; If button A is pressed, jump to InputZipcodeCharacters_B0.

	bit B_BUTTON_F, a
	jp nz, InputZipcodeCharacters_B0 ; If button B is pressed, jump to InputZipcodeCharacters_B0.

	ld a, [wd002]
	and %11001111
	res 7, a
	ld [wd002], a
	pop bc ; On the first loop, B contains 0 and C contains [wZipCode + 1]
	inc b ; Converts b from 0-index to 1-index.
	ld a, b
	cp $5
	push bc
	jr c, .b_ceiled

	pop bc
	ld b, $4 ; Min(b, 4).
	push bc
.b_ceiled
	pop bc
	push bc
	ld a, b
	cp $4
	jr nz, asm_48972 ; If b is within [0;3], jump to asm_48972.

	ld c, 10
	call DelayFrames
	jr asm_48972

InputZipcodeCharacters_B0:
	pop bc
	ld b, $0
	push bc

asm_48972:
	call InputZipcodeCharacters

	push af
	push de
	ld e, d
	ld d, $0
	ld b, $71; Y. Supposed to be $70 with GFX_underscore.
	if DEF(_CRYSTAL_AU)	
	ld c, (19 - ZIPCODE_LENGTH + 1) * 8; X.
	elif DEF(_CRYSTAL_EU)	
	ld c, (19 - ZIPCODE_LENGTH + 1) * 8; X.	
	else
	ld c, (16 - ZIPCODE_LENGTH + 1) * 8; X.
	endc
	if DEF(_CRYSTAL_EU)
	call Mobile12_MoveAndBlinkCursor
	endc
	;farcall Mobile22_MoveAndBlinkCursor
	pop de
	pop af

	push af
	cp $f0
	jr z, .skip_all_blinking ; Jump if last input was up or down (zip code value changed).

	cp $f
	jr nz, .regular_blinking ; Jump if last input WASN'T left or right.

;.reset_blinking ; We reach this line if the last input was left or right.
	ld a, [wd002]
	set 7, a
	and $cf ; %1100 1111
	ld [wd002], a

.regular_blinking
	if DEF(_CRYSTAL_AU)	
	hlcoord 16 - ZIPCODE_LENGTH, 11 ; Zip code location
	else
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip code location
	endc
	ld b, $0
	ld c, d
	add hl, bc
	call BlinkSelectedCharacter

.skip_all_blinking
	call WaitBGMap
	pop af
	pop bc
	jp nc, ZipCodeEditMenu ; If the player didn't validate the zipcode save (didn't press A).
	; If we reach this line, it means the player saved by pressing A in the zipcode edit menu.
	jr nz, .confirm_save ; If nz, it means InputZipcodeCharacters returned a value (either $f or $f0) because the player pressed an arrow.

; Reset zip code to previous value.
	pop bc
	ld a, b
	ld [wZipCode + 6], a

	pop bc
	ld a, b
	ld [wZipCode + 4], a
	ld a, c
	ld [wZipCode + 5], a

	pop bc
	ld a, b
	ld [wZipCode + 2], a
	ld a, c
	ld [wZipCode + 3], a

	pop bc
	ld a, b
	ld [wZipCode + 0], a
	ld a, c
	ld [wZipCode + 1], a

	jr .quit_zip_code_edit_menu

.confirm_save
	push af

	ld a, [wd479]
	set 0, a
	ld [wd479], a

	ld a, [wMobileProfileParametersFilled]
	set 3, a
	ld [wMobileProfileParametersFilled], a

	pop af

rept 4
	pop bc ; Flush the stack that was holding the previous value of the zip code.
endr

.quit_zip_code_edit_menu
	push af
	push bc
	push de
	push hl
	ld a, $1
	call MenuClickSound ; We hear this sound when we leave the zipcode edition code.
	farcall Mobile22_Clear24FirstOAM
	pop hl
	pop de
	pop bc
	pop af
	call ExitMenu
	call DisplayZipCodeRightAlign
	if DEF(_CRYSTAL_AU)
	hlcoord 16, 11 ; Location of a clear box to clear any excess characters if 'Tell Now' is selected, but cannot overlap the position of the zip code itself, because otherwise it will clear that too.
	ld a, 7 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	elif DEF(_CRYSTAL_EU)
	hlcoord 9, 11 ; Location of a clear box to clear any excess characters if 'Tell Now' is selected, but cannot overlap the position of the zip code itself, because otherwise it will clear that too.
	ld a, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	else
	hlcoord 9, 11 ; Location of a clear box to clear any excess characters if 'Tell Now' is selected, but cannot overlap the position of the zip code itself, because otherwise it will clear that too.
	ld a, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	endc
	add b ; We increase the clearbox width, in case the zipcode has been shifted to the right.
	ld c, a
	ld b, 1
	call ClearBox
	pop af
	ldh [hInMenu], a
	jp ReturnToMobileProfileMenu

; Input: B = left offset.
DisplayZipCodeRightAlign:
	push de
	; We first clear the area.
	if DEF(_CRYSTAL_AU)
	hlcoord 13 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	elif DEF(_CRYSTAL_EU)
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	else
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	ld a, ZIPCODE_LENGTH
	endc
	ld c, a
	ld b, 0
	ld a, " "
	call ByteFill ; fill bc bytes with the value of a, starting at hl
	ld b, e

	; Aligning to the right, based on wZipcodeFormatLength.
	if DEF(_CRYSTAL_AU)
	hlcoord 16 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	elif DEF(_CRYSTAL_EU)
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	else
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	endc
	ld a, [wZipcodeFormatLength]
    ld b, a
    ld a, ZIPCODE_LENGTH
    sub b
    ld e, a
    ld d, 0
    ;add hl, de ; Shifting HL coord to the right, based on wZipcodeFormatLength. It's so that the zipcode stays aligned to the right.

	call CountZipcodeRightBlanks
	ld d, 0
	ld e, a
	add hl, de
	pop de

	ld b, a

	jr DisplayZipCodeWithOffset

; Input: HL contains the coords (using hlcoord) on the screen of the first char (leftmost) of the zipcode. B = left offset.
; Output: the number of blanks on the right in B. This is the equivalent of the desired left offset.
DisplayZipCode:
	ld b, 0
DisplayZipCodeWithOffset:
	push de

	ld de, 0
	ld a, [wZipcodeFormatLength]
	sub b ; Note that B must always be strictly smaller than ZIPCODE_LENGTH.
	ld c, a

.loop
	ld a, e
	cp c
	jr nc, .end_loop

	push hl
	ld hl, wZipCode
	ld d, 0
	add hl, de ; We get the zipcode char offset.
	ld a, [hl]
	pop hl

	ld d, e
	call Mobile12_Index2CharDisplay
	inc hl

	inc e
	jr .loop

.end_loop
	pop de
	ret

TellNowTellLaterMenu:
	ld hl, MenuHeader_0x48a9c
	call LoadMenuHeader
	call SetCursorParameters_Gender
	ld a, $a
	ld [w2DMenuCursorInitY], a
	ld a, $8 ; Y Placement of 'Tell Now' 'Tell Later' Cursor
	ld [w2DMenuCursorInitX], a
	ld a, $1 ; X Placement of 'Later' Cursor
	ld [wMenuCursorY], a
	hlcoord 7, 8 ; Placement of 'Tell Now' 'Tell Later' Box
	ld b, $4
	ld c, $b
	call DisplayBlankGoldenBox
	hlcoord 9, 10 ; Placement of 'Tell Now' 'Tell Later' Text
	ld de, TellNowLaterStrings
	call PlaceString
	call StaticMenuJoypad ; Waits for a user input from the input filter.
	push af
	call PlayClickSFX
	call ExitMenu
	pop af
	bit B_BUTTON_F, a
	jp nz, .leave ; Jump to .leave if B is pressed. If not jumping, then it's A that has been pressed.
	ld a, [wMenuCursorY]
	cp $1
	jr z, .a_pressed ; The player pressed "Tell later".
	
.pressed_tell_later
	ld a, [wMobileProfileParametersFilled]
	set 3, a
	ld [wMobileProfileParametersFilled], a
	ld a, [wd479]
	res 0, a
	ld [wd479], a
	xor a
	ld bc, ZIPCODE_LENGTH
	ld hl, wZipCode + 0
	call ByteFill
	jr .leave
.a_pressed
	and a
	ret

.leave
	scf
	ret

MenuHeader_0x48a9c:
	db MENU_BACKUP_TILES ; flags
	menu_coords 6, 8, SCREEN_WIDTH - 1, 13 ; For clearing the 'Tell Later' 'Tell Now' Box

TellNowLaterStrings:
	db   "Tell Now"
	next "Tell Later@"

InputZipcodeCharacters: ; Function48ab5. Zip code menu controls.
	ldh a, [hJoyPressed]
	and A_BUTTON
	jp nz, ExitAndSaveZipcode
	ldh a, [hJoyPressed]
	and B_BUTTON
	jp nz, ExitAndDontSaveZipcode
	ld hl, wZipCode + 0
	push de
	ld e, d
	ld d, 0
	add hl, de
	pop de
	ld a, [hl]

	push hl
	push af ; Stores the value of the zip code char from A.
	ld e, d
	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .press_up
	ld a, [hl]
	and D_DOWN
	jr nz, .press_down
	ld a, [hl]
	and D_LEFT
	jp nz, .press_left
	ld a, [hl]
	and D_RIGHT
	jr nz, .press_right

	; If we reach this line, it means the player didn't press any button this frame.
	if DEF(_CRYSTAL_AU)
	hlcoord 16 - ZIPCODE_LENGTH, 11 ; Zip Code Location
	elif DEF(_CRYSTAL_EU)
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Location
	else
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip Code Location
	endc
	call DisplayZipCode
	ld a, [wd002]
	bit 7, a

	pop bc
	pop bc
	and a
	ret

.press_down ; press down, zip code number menu
	pop af
	sub 1 ; We use this because dec doesn't set the carry flag.
	jr nc, .no_underflow

	; We find the last char index (from the char pool) of the current char slot.
	call Zipcode_GetCharPoolLengthForGivenCharSlot
	dec a ; array length - 1 = last index of the array.

.no_underflow
	push de
	push af
	if DEF(_CRYSTAL_AU)
	hlcoord 15 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH + 3; Zip Code Menu width
	elif DEF(_CRYSTAL_EU)
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	else
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	endc
	call DisplayBlankGoldenBox
	pop af
	pop de
	pop hl
	ld [hl], a
	ld a, $f0 ; Return value. It means the last input was up or down (zip code value changed).
	jp DisplayZipCodeAfterChange
.press_up ; press up, zip code number menu
	call Zipcode_GetCharPoolLengthForGivenCharSlot
	ld e, a
	pop af
	inc a
	cp e
	jr c, .no_underflow ; Actually means "no overflow".
	xor a
	jr .no_underflow

.press_right
	push de
	if DEF(_CRYSTAL_AU)
	hlcoord 15 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH + 3; Zip Code Menu width
	elif DEF(_CRYSTAL_EU)
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	else
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	endc
	call DisplayBlankGoldenBox
	pop de
	ld a, [wZipcodeFormatLength]
	dec a
	cp d ; Limits how far you can press D_RIGHT
	jr c, .asm_48baf ; useless, but kept in case the memory got corrupted.
	jr z, .asm_48baf
	inc d
.asm_48baf
	pop af
	pop hl
	inc hl
	ld a, [hl]

.asm_48bc7
	hlcoord 10, 9
	push af
	ld a, d
	pop bc
	ld a, b
	inc hl
	ld a, $f ; Return value. It means the last input was left or right.
	jr DisplayZipCodeAfterChange

.press_left
	push de
	if DEF(_CRYSTAL_AU)
	hlcoord 15 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH + 3; Zip Code Menu width
	elif DEF(_CRYSTAL_EU)
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	else
	hlcoord 18 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH; Zip Code Menu width
	endc
	call DisplayBlankGoldenBox
	pop de
	pop af
	pop hl
	ld b, a
	ld a, d
	and a
	jr z, .asm_48bf3

	dec d ; We know that D isn't zero, so decreasing won't underflow.
	call Zipcode_GetCharPoolLengthForGivenCharSlot ; Doesn't clobber B.
	inc d ; We cancel the decrease.
	and a
	jr z, .asm_48bf3
	cp 1
	jr z, .asm_48bf3

	ld a, b
	bit 7, a
	jr z, .asm_48bf8
	dec d
	dec hl
.asm_48bf3
	ld a, [hl]
	and $f
	jr .asm_48bc7
.asm_48bf8
	dec d
	ld a, [hl]
	swap a
	and $f
	jr .asm_48bc7

; Input in D: char slot index.
; Output in A: char pool length of the given char slot in input.
Zipcode_GetCharPoolLengthForGivenCharSlot:
	push hl
	push de
	push bc

	ld hl, Zipcode_CharPool_Formats
	ld a, [wZipcodeFormat]
	add a ; dw
	ld c, a
	ld b, 0
	add hl, bc
	
	ld a, [hli]
	ld h, [hl]
	ld l, a ; HL now points to the zipcode format structure.

	ld e, d
	ld d, 0
	add hl, de
	ld a, [hl] ; A contains the index of the used charpool.

	ld hl, Zipcode_CharPools + 2 ; HL points to the charpool length list.
	ld e, a
	add a
	add e 
	ld e, a ; dwb
	add hl, de
	ld a, [hl] ; A contains the length of the charpool we are looking for.

	pop bc
	pop de
	pop hl
	ret

DisplayZipCodeAfterChange:
	push af
	if DEF(_CRYSTAL_AU)
	hlcoord 16 - ZIPCODE_LENGTH, 11 ; Zip code location
	elif DEF(_CRYSTAL_EU)
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip code location
	else
	hlcoord 19 - ZIPCODE_LENGTH, 11 ; Zip code location
	endc
	call DisplayZipCode
	ld a, $1
	and a
	pop bc
	ld a, b
	ret

ExitAndDontSaveZipcode:
	xor a
	and a

ExitAndSaveZipcode:
	scf
	ret

BlinkSelectedCharacter:
	ld a, [wd002]
	bit 7, a
	jr z, .skip_blinking

	ld [hl], $7f ; Makes the selected character blink/flash. 7f is the last tile before tile "A".

.skip_blinking
	ld a, [wd002]
	swap a
	and $3 ; Masking bits 4 and 5 (0011 0000) that are now bits 0 and 1 (0000 0011) after the swap.
	inc a
	cp 3
	jr nz, .save_counter_in_wd002 ; When the counter reaches its maximum value, we immediately save.

	ld a, [wd002]
	bit 7, a
	jr z, .set_blinking_flag ; If bit 7 is not set (meaning the blinking just happened), then we set the blinking flag.

; Resets the blinking flag AND the counter.
	res 7, a
	ld [wd002], a
	xor a
	jr .save_counter_in_wd002

.set_blinking_flag
	set 7, a
	ld [wd002], a
	xor a

.save_counter_in_wd002
	swap a
	ld b, a
	ld a, [wd002]
	and $cf ; and %1100 1111
	or b
	ld [wd002], a
	ret

Mobile_DisplayPrefecture:
	ld a, "@"
	ld [de], a
	ld a, c
	cp NUM_REGION_CODES + 1
	jr nc, .exit
	and a
	jr z, .exit
	dec c
	push de
	ld h, d
	ld l, e
	ld a, "@"
	ld b, REGION_NAME_MAX_LENGTH
.buffer_clear_loop
	ld [hli], a
	dec b
	jr nz, .buffer_clear_loop
	ld hl, Prefectures
	ld a, c
	call GetNthString
.write_buffer_loop
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	cp "@"
	jr nz, .write_buffer_loop
	and a
	pop de
	ret

.exit
	scf ; The carry is actually never used.
	ret

DisplayBlankGoldenBox_DE:
	ld h, d
	ld l, e

DisplayBlankGoldenBox:
	push bc
	push hl
	call DisplayGoldenBoxBorders
	pop hl
	pop bc
	ld de, wAttrmap - wTilemap
	add hl, de
	inc b
	inc b
	inc c
	inc c
	ld a, $0
.outer_loop
	push bc
	push hl
.inner_loop
	ld [hli], a
	dec c
	jr nz, .inner_loop
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	pop bc
	dec b
	jr nz, .outer_loop
	ret

DisplayGoldenBoxBorders:
	push hl
	ld a, $4 ; This represents the top-left corner of the golden box border, which is at tile address $9040 in VRAM 0.
	ld [hli], a
	inc a
	call Fill_HL_with_A_C_times
	inc a
	ld [hl], a
	pop hl
	ld de, SCREEN_WIDTH ; Going to the next line / 1 tile down on the screen.
	add hl, de
.loop
	push hl
	ld a, $7
	ld [hli], a
	ld a, $7f
	call Fill_HL_with_A_C_times
	ld [hl], $8
	pop hl
	ld de, $14
	add hl, de
	dec b
	jr nz, .loop
	ld a, $9
	ld [hli], a
	ld a, $a
	call Fill_HL_with_A_C_times
	ld [hl], $b
	ret

Fill_HL_with_A_C_times:
	ld d, c
.loop
	ld [hli], a
	dec d
	jr nz, .loop
	ret

; Input: BC: coords of the cursor under the first PIN char. D: contains the tile ID. E: index of the char.
Mobile12_MoveAndBlinkCursor:
	ld a, [wPrefecture]
	cp $10 ; EU-GB special case.
	jr nz, .hide_cursor

	ld a, e
	cp 5
	jr c, .hide_cursor

	push hl
	push bc
	ld hl, wZipCode
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	cp 26
	pop bc
	pop hl
	jr nz, .hide_cursor

	;call Mobile22_IncCursorFrameCounter
	ld a, [wd002]
	bit 4, a
	jr z, .skip_cursor_hiding

.hide_cursor
	push de
	farcall Mobile22_Clear24FirstOAM
	pop de
	ret

.skip_cursor_hiding
	ld hl, wShadowOAMSprite00
	push de
	ld a, b
	ld [hli], a ; y
	ld d, $8
	ld a, e
	and a
	ld a, c
	jr z, .skip_offset

.offset_loop
	add d
	dec e
	jr nz, .offset_loop

.skip_offset
	pop de
	ld [hli], a ; x
	ld a, d
	ld [hli], a ; tile id
	xor a
	ld [hli], a ; attributes
	ret

; Input: In A, the char index in the zipcode string between 0 and ZIPCODE_LENGTH.
; Output: Address in HL.
; Clobbers DE.
GetCurCharpoolAddress:
	push af
	ld a, [wZipcodeFormat]
	add a ; dw
	ld e, a
	ld d, 0
	ld hl, Zipcode_CharPool_Formats
	add hl, de

	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af

	ld e, a ; db
	add hl, de ; HL shifted by the index in the charpool (from 0 to ZIPCODE_LENGTH).
	ld a, [hl] ; A contains the index of the used char pool.

	ld hl, Zipcode_CharPools
	ld e, a
	add a
	add e ; We multiply A by 3, as we are going through a dwb list.
	ld e, a
	add hl, de

	ld a, [hli]
	ld h, [hl]
	ld l, a ; HL points to the used charpool.
	ret

; Output: in A: the number of blank chars at the right of the zipcode.
CountZipcodeRightBlanks:
	push hl
	push de
	push bc

	ld d, 0
	ld a, [wZipcodeFormatLength]
	dec a
	ld e, a
	;ld e, ZIPCODE_LENGTH - 1

	ld b, 0 ; B is the counter.

.loop
	ld hl, wZipCode
	add hl, de ; Current zipcode char.

	ld a, [hl] ; We get the index of the current char.
	add a ; We double the index to find its position within the array.
	ld c, a ; Save the index in C for future use.

	ld a, e
	push de
	call GetCurCharpoolAddress
	;pop de
	;push de
	;add hl, de ; Get the char pool for the current zipcode char.
	;ld a, [hli]
	;ld h, [hl]
	;ld l, a ; We have the address of the current char pool in HL.

	ld d, 0
	ld e, c ; We retrieve our zipcode char index (already multiplied by 2).
	add hl, de
	ld a, [hl] ; A contains the current zipcode char value.
	pop de

	;dec e ; Preparing for the next (actually previous) char loop.
	;inc b ; Increase the number of found blanks.
	;cp " "
	;jr z, .loop ; As long as we find blanks, we keep searching for some more.
	;
	;dec b ; We increased B on the last loop even though a blank hasn't been found. So we need to negate it by decreasing B.
	
	;ld a, [wZipcodeFormatLength]
	;ld e, a
	;ld a, ZIPCODE_LENGTH
	;sub e
	;add b ; Return value goes into A.

	ld a, b ; Return value goes into A.
	pop bc
	pop de
	pop hl
	ret

SaveZipcodeWithUniversalFormat:
	push de

	ld a, BANK(sZipcodeCharIndexes)
	call OpenSRAM
	ld hl, wZipCode
	ld de, sZipcodeCharIndexes
	ld bc, ZIPCODE_MAX_LENGTH
	call CopyBytes
	call CloseSRAM

	ld hl, wZipCode + ZIPCODE_LENGTH
	ld bc, ZIPCODE_MAX_LENGTH - ZIPCODE_LENGTH
	ld a, "@"
	call ByteFill

	ld hl, wZipCode
	ld c, 0
	ld d, 0
	xor a
.loop
	ld e, [hl]
	push hl

	; Input: In A, the char index in the zipcode string between 0 and ZIPCODE_LENGTH.
	; Output: Address in HL.
	; Clobbers DE.
	push de
	call GetCurCharpoolAddress
	pop de

	add hl, de
	ld a, [hl]
	pop hl

	ld [hl], a

	inc hl
	inc c
	ld a, c
	cp ZIPCODE_LENGTH
	jr nz, .loop

.truncate_trailing_spaces
	dec hl
	ld a, [hl]
	cp " "
	jr nz, .truncate_done

	ld a, "@"
	ld [hl], a
	jr .truncate_trailing_spaces

.truncate_done
	pop de
	ret

LoadZipcodeWithUniversalFormat:
	ld a, BANK(sZipcodeCharIndexes)
	call OpenSRAM
	ld hl, sZipcodeCharIndexes
	ld de, wZipCode
	ld bc, ZIPCODE_MAX_LENGTH
	call CopyBytes
	call CloseSRAM
	ret
