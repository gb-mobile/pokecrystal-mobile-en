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
	ld b, $1
	call GetMysteryGift_MobileAdapterLayout
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
	ld hl, Strings_484fc
	call GetNthString
	ld d, h
	ld e, l
	hlcoord 11, 5 ; Default gender position in MOBILE menu
	call PlaceString
.asm_48113
	hlcoord 15, 7 ; Default age position in MOBILE menu
	call Function487ec
	ld a, [wd474]
	dec a
	ld hl, Prefectures
	call GetNthString
	ld d, h
	ld e, l
	hlcoord 13, 9 ; Default Prefectures position in MOBILE menu
	call PlaceString 
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip Code Position in MOBILE menu
	call DisplayZipCode
	hlcoord 0, 14 ; 'Personal Info' box position 
	ld b, $2
	ld c, $12
	call Textbox
	hlcoord 1, 16 ; 'Personal Info' text position
	ld de, MobileString_PersonalInfo
	call PlaceString
	call Function48187
	call WaitBGMap2
	call SetPalettes
	call StaticMenuJoypad
	ld hl, wMenuCursorY
	ld b, [hl]
	push bc
	jr asm_4815f

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
	pop bc
	call ClearTileMap
	ld a, $ff
	ret

Function48187:
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
	hlcoord 11, 5 ; Gender position
	call ClearBox
.asm_481c1
	bit 1, d
	jr nz, .asm_481ce
	lb bc, 1, 8
	hlcoord 11, 7 ; Age position ; Don't change
	call ClearBox
.asm_481ce
	bit 2, d
	jr nz, .asm_481db
	lb bc, 2, 8
	hlcoord 11, 9 ; prefecture position
	call ClearBox
.asm_481db
	bit 3, d
	jr nz, .asm_481f1
	ld a, [wd479]
	bit 0, a
	jr nz, .asm_481f8
	lb bc, 1, 8
	hlcoord 11, 11 ; Zip code location
	call ClearBox
	jr .asm_48201
.asm_481f1
	ld a, [wd479]
	bit 0, a
	jr nz, .asm_48201
.asm_481f8
	hlcoord 8, 11 ; Position of 'Tell Later' after selecting
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
	pop bc
	call ClearTileMap
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
	hlcoord 12, 2 ; Gender menu position
	ld b, $4
	ld c, $6
	call DisplayBlankGoldenBox
	hlcoord 14, 4 ; Position of Male Gender string in Gender menu
	ld de, String_484fb
	call PlaceString
	hlcoord 14, 6 ; Position of Female Gender string in Gender menu
	ld de, String_484ff
	call PlaceString
	call WaitBGMap
	ld a, [wPlayerGender]
	inc a
	ld [wMenuCursorBuffer], a
	call StaticMenuJoypad
	call PlayClickSFX
	call ExitMenu
	bit A_BUTTON_F, a
	jp z, ReturnToMobileProfileMenu
	ld hl, wMenuCursorY
	ld a, [hl]
	ld hl, Strings_484fc
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
	hlcoord 14, 5 ; Gender position
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
	hlcoord 10, 0
	ld b, $c
	ld c, $8
	call DisplayBlankGoldenBox ; This has to do with some display.
	ld a, [wMenuCursorBuffer]
	ld b, a
	ld a, [wMenuScrollPosition]
	ld c, a
	push bc
	ld a, [wd474]
	dec a
	cp NUM_REGION_CODES
	jr c, .asm_4833f
	sub NUM_REGION_CODES
	inc a
	ld [wMenuCursorBuffer], a
	ld a, NUM_REGION_CODES
.asm_4833f
	ld [wMenuScrollPosition], a
	farcall Mobile_OpenAndCloseMenu_HDMATransferTileMapAndAttrMap
.asm_48348
	call ScrollingMenu
	ld d, $6
	ld e, NUM_REGION_CODES
	call RegionCodeEdit_LeftRight
	jr c, .asm_48348
	ld d, a
	pop bc
	ld a, b
	ld [wMenuCursorBuffer], a
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
	call DisplayRegionCodesList
	ld a, [wMobileProfileParametersFilled]
	set 2, a
	ld [wMobileProfileParametersFilled], a
.asm_48377
	call Function48187
	farcall Mobile_OpenAndCloseMenu_HDMATransferTileMapAndAttrMap
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
	ld [wMenuCursorBuffer], a
	scf
.quit
	pop bc
	ld a, b
	pop bc
	ret

DisplayRegionCodesList:
	ld hl, wScrollingMenuCursorPosition
	ld a, [hl]
	inc a
	ld [wd474], a
	dec a
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
	hlcoord 11, 8 ; ??? Clears the surrounding tiles when prefecture is selected, needs to be moved with preferectures
	call ClearBox
	hlcoord 13, 9 ; Prefectures position when selected
	call PlaceString
	ret

Function483e8:
	push de
	ld hl, Prefectures
	ld a, [wMenuSelection]
	cp $ff
	jr nz, .asm_483f8
	ld hl, Prefectures + (NUM_REGION_CODES - 1) * 6 ; last string
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
	call Function48187
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

Mobile12_Index2Char:
	push bc
	push af
	push de
	push hl
	ld hl, .DigitStrings
.loop
	and a
	jr z, .got_string
	inc hl
	inc hl
	dec a
	jr .loop
.got_string
	ld d, h
	ld e, l
	pop hl
	call PlaceString
	pop de
	pop af
	pop bc
	ret

.DigitStrings:
	db "0@"
	db "1@"
	db "2@"
	db "3@"
	db "4@"
	db "5@"
	db "6@"
	db "7@"
	db "8@"
	db "9@"
	db "A@"
	db "B@"
	db "C@"
	db "D@"
	db "E@"
	db "F@"
	db "G@"
	db "H@"
	db "I@"
	db "J@"
	db "K@"
	db "L@"
	db "M@"
	db "N@"
	db "O@"
	db "P@"
	db "Q@"
	db "R@"
	db "S@"
	db "T@"
	db "U@"
	db "V@"
	db "W@"
	db "X@"
	db "Y@"
	db "Z@"
	db " @"

MobileProfileString:         db "  Mobile Profile@"
MobileString_Gender:         db "Gender@"
MobileString_Age:            db "Age@"
MobileString_Address:        db "Address@"
MobileString_ZipCode:        db "Zip Code@"
MobileString_OK:             db "OK@"
MobileString_ProfileChanged: db "Profile Changed@"
MobileDesc_Gender:           db "Boy or girl?@"
MobileDesc_Age:              db "How old are you?@"
MobileDesc_Address:          db "Where do you live?@"
MobileDesc_ZipCode:          db "Your zip code?@"

MenuHeader_0x484f1:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 2, SCREEN_WIDTH - 1, 7 ; For clearing the Gender box
	dw MenuData_0x484f9
	db 1 ; default option

MenuData_0x484f9:
	db STATICMENU_CURSOR | STATICMENU_WRAP ; flags
	db 2 ; items
Strings_484fb:
String_484fb: db "Boy@"
String_484ff: db "Girl@"
Strings_484fc:
String_484fc: db " Boy@"
String_48500: db "Girl@"

MenuHeader_0x48504:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1 ; For clearing the Address Box

MenuHeader_0x48509:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 5, SCREEN_WIDTH - 1, 8 ; For clearing the Age Box

MenuHeader_ZipCodeEditBox:
	db MENU_BACKUP_TILES ; flags
	menu_coords 10, 10, SCREEN_WIDTH - 1, TEXTBOX_Y - 0 ; For clearing the Zip Code box
	
	;Bounding of left side ; bounding of top ; bounding of right side ; bounding of bottom

MenuHeader_0x48513:
	db MENU_BACKUP_TILES ; flags
	menu_coords 11, 1, 18, 12 ; The placement of the text in the address box
	dw MenuData_0x4851b
	db 1 ; default option

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
x = 0
rept NUM_REGION_CODES - 1 ; The number of locations in the prefectures list (-1 because it starts at 0)
	db x
x = x + 1
endr
	db -1

Prefectures: ; Some names shortened to fit, check for official initials later.
	db	"CA-AB@"  ;Alberta
	db	"CA-BC@"  ;British_Columbia
	db	"CA-MB@"  ;Manitoba
	db	"CA-NB@"  ;New_Brunswick
	db	"CA-NL@"  ;Newfoundland_and_Labrador
	db	"CA-NS@"  ;Nova_Scotia
	db	"CA-NT@"  ;Northwest_Territories
	db	"CA-NU@"  ;Nunavut
	db	"CA-ON@"  ;Ontario
	db	"CA-PE@"  ;Prince_Edward_Island
	db	"CA-QC@"  ;Quebec
	db	"CA-SK@"  ;Saskatchewan
	db	"CA-YT@"  ;Yukon
	db	"US-AK@"  ;Alaska
	db	"US-AL@"  ;Alabama
	db	"US-AR@"  ;Arkansas
	db	"US-AZ@"  ;Arizona
	db	"US-CA@"  ;California
	db	"US-CO@"  ;Colorado
	db	"US-CT@"  ;Connecticut
	db	"US-DC@"  ;District_Of_Columbia
	db	"US-DE@"  ;Delaware
	db	"US-FL@"  ;Florida
	db	"US-GA@"  ;Georgia
	db	"US-HI@"  ;Hawaii
	db	"US-IA@"  ;Iowa
	db	"US-ID@"  ;Idaho
	db	"US-IL@"  ;Illinois
	db	"US-IN@"  ;Indiana
	db	"US-KS@"  ;Kansas
	db	"US-KY@"  ;Kentucky
	db	"US-LA@"  ;Louisiana
	db	"US-MA@"  ;Massachusetts
	db	"US-MD@"  ;Maryland
	db	"US-ME@"  ;Maine
	db	"US-MI@"  ;Michigan
	db	"US-MN@"  ;Minnesota
	db	"US-MO@"  ;Missouri
	db	"US-MS@"  ;Mississippi
	db	"US-MT@"  ;Montana
	db	"US-NC@"  ;North_Carolina
	db	"US-ND@"  ;North_Dakota
	db	"US-NE@"  ;Nebraska
	db	"US-NH@"  ;New_Hampshire
	db	"US-NJ@"  ;New_Jersey
	db	"US-NM@"  ;New_Mexico
	db	"US-NV@"  ;Nevada
	db	"US-NY@"  ;New_York
	db	"US-OH@"  ;Ohio
	db	"US-OK@"  ;Oklahoma
	db	"US-OR@"  ;Oregon
	db	"US-PA@"  ;Pennsylvania
	db	"US-RI@"  ;Rhode_Island
	db	"US-SC@"  ;South_Carolina
	db	"US-SD@"  ;South_Dakota
	db	"US-TN@"  ;Tennessee
	db	"US-TX@"  ;Texas
	db	"US-UT@"  ;Utah
	db	"US-VA@"  ;Virginia
	db	"US-VT@"  ;Vermont
	db	"US-WA@"  ;Washington
	db	"US-WI@"  ;Wisconsin
	db	"US-WV@"  ;West_Virginia
	db	"US-WY@"  ;Wyoming

DisplayInitializedMobileProfileLayout: ; Clears the 4 top lines, displays the "Mobile Profile" title, and displays an empty golden box.
	ld c, 7
	call DelayFrames
	ld b, $1
	call GetMysteryGift_MobileAdapterLayout
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
	ld a, 13 ; x axis position of the gender cursor
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
	hlcoord 14, 6 ; Age menu position
	ld b, $1
	ld c, $4
	call DisplayBlankGoldenBox
	call WaitBGMap
	ld a, [wd473]
	and a
	jr z, .asm_487ab
	cp $64
	jr z, .asm_487b2
	hlcoord 16, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 16, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
	jr .asm_487b7
.asm_487ab
	hlcoord 16, 6 ; Age menu up arrow position
	ld [hl], $10
	jr .asm_487b7
.asm_487b2
	hlcoord 16, 8 ; Age menu down arrow position (probably)
	ld [hl], $11
.asm_487b7
	hlcoord 15, 7 ; Age position
	call Function487ec
	ld c, 10
	call DelayFrames
	ld a, [wd473]
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
	ld [wd473], a
.asm_487da
	ld a, [wd473]
	call ExitMenu
	hlcoord 15, 7 ; Age position
	call Function487ec
	pop af
	ldh [hInMenu], a
	jp ReturnToMobileProfileMenu

Function487ec:
	push hl
	ld de, wd473
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
	ld hl, wd473
	ld a, [hl]
	and a
	jr z, .asm_48840
	dec a
.asm_48840
	ld [hl], a
	jr .asm_4886f
.asm_48843
	ld hl, wd473
	ld a, [hl]
	cp $64
	jr nc, .asm_4884c
	inc a
.asm_4884c
	ld [hl], a
	jr .asm_4886f
.asm_4884f
	ld a, [wd473]
	cp $5b
	jr c, .asm_48858
	ld a, $5a
.asm_48858
	add $a
	ld [wd473], a
	jr .asm_4886f
.asm_4885f
	ld a, [wd473]
	cp $a
	jr nc, .asm_48868
	ld a, $a
.asm_48868
	sub $a
	ld [wd473], a
	jr .asm_4886f
.asm_4886f
	ld a, [wd473]
	and a
	jr z, .asm_48887
	cp $64
	jr z, .asm_48898
	jr z, .asm_488a7
	hlcoord 16, 6 ; Age menu up arrow position
	ld [hl], $10
	hlcoord 16, 8 ; Age menu down arrow position
	ld [hl], $11
	jr .asm_488a7
.asm_48887
	hlcoord 14, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $4
	call DisplayBlankGoldenBox
	hlcoord 16, 6 ; Age menu up arrow position when using D-Pad
	ld [hl], $10
	jr .asm_488a7
.asm_48898
	hlcoord 14, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $4
	call DisplayBlankGoldenBox
	hlcoord 16, 8 ; Age menu down arrow position when using D-Pad
	ld [hl], $11
.asm_488a7
	hlcoord 15, 7 ; Age position
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
INCBIN "gfx/mobile/up_arrow.2bpp"

MobileDownArrowGFX:
INCBIN "gfx/mobile/down_arrow.2bpp"

ZipCodePressed: 
	call ClearMobileProfileBottomTextBox
	hlcoord 1, 16
	ld de, MobileDesc_ZipCode
	call PlaceString
	call TellNowTellLaterMenu
	jp c, ReturnToMobileProfileMenu

	hlcoord 8, 11 ; Clearing the potential "Tell Later" text.
	lb bc, 1, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	call ClearBox

	ld hl, MenuHeader_ZipCodeEditBox
	call LoadMenuHeader
	
	ldh a, [hInMenu]
	push af
	ld a, TRUE
	ldh [hInMenu], a

	hlcoord 17 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH ; Zip Code Menu width
	call DisplayBlankGoldenBox
	ld d, $0
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip Code Position
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
	ld d, $0
	ld b, $0

ZipCodeEditMenu:
	push bc
	call JoyTextDelay
	ldh a, [hJoyDown]
	and a
	jp z, Function4896e ; If no button is pressed, jump to Function4896e.
	
	bit A_BUTTON_F, a
	jp nz, Function4896e ; If button A is pressed, jump to Function4896e.
	
	bit B_BUTTON_F, a
	jp nz, Function4896e ; If button B is pressed, jump to Function4896e.
	
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

Function4895a:
	ldh a, [hJoyPressed]
	and a
	jr z, .asm_48965
	
	pop bc
	ld b, $1
	push bc
	jr asm_48972

.asm_48965
	ldh a, [hJoyLast]
	and a
	jr z, asm_48972

	pop bc
	ld b, $1
	push bc

Function4896e:
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
	ld c, (18 - ZIPCODE_LENGTH + 1) * 8; X.
	call Mobile12_MoveAndBlinkCursor
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
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip code location
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
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip Code location
	call DisplayZipCode
	hlcoord 8, 11 ; Location of a clear box to clear any excess characters if 'Tell Now' is selected, but cannot overlap the position of the zip code itself, because otherwise it will clear that too.
	lb bc, 1, 10 - ZIPCODE_LENGTH ; Determines the size of the clearing box
	call ClearBox
	pop af
	ldh [hInMenu], a
	jp ReturnToMobileProfileMenu

DisplayZipCode:
	push de
	ld a, [wZipCode + 0]
	call Mobile12_Index2Char
	ld a, [wZipCode + 1]
	inc hl
	call Mobile12_Index2Char
	ld a, [wZipCode + 2]
	inc hl
	call Mobile12_Index2Char
	ld a, [wZipCode + 3]
	inc hl
	call Mobile12_Index2Char
	ld a, [wZipCode + 4]
	inc hl
	call Mobile12_Index2Char
	ld a, [wZipCode + 5]
	inc hl
	call Mobile12_Index2Char
	ld a, [wZipCode + 6]
	inc hl
	call Mobile12_Index2Char
	pop de
	ret

String_48a38:
	db "-@" ; Unused

TellNowTellLaterMenu:
	ld hl, MenuHeader_0x48a9c
	call LoadMenuHeader
	call SetCursorParameters_Gender
	ld a, $a
	ld [w2DMenuCursorInitY], a
	ld a, $7 ; Y Placement of 'Tell Now' 'Tell Later' Cursor
	ld [w2DMenuCursorInitX], a
	ld a, $1 ; X Placement of 'Later' Cursor
	ld [wMenuCursorY], a
	hlcoord 6, 8 ; Placement of 'Tell Now' 'Tell Later' Box
	ld b, $4
	ld c, $c
	call DisplayBlankGoldenBox
	hlcoord 8, 10 ; Placement of 'Tell Now' 'Tell Later' Text
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
	menu_coords 5, 8, SCREEN_WIDTH - 1, 13 ; For clearing the 'Tell Later' 'Tell Now' Box

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
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip Code Location
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
	ld a, 36
.no_underflow
	push de
	push af
	hlcoord 17 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH ; Zip Code Menu width
	call DisplayBlankGoldenBox
	pop af
	pop de
	pop hl
	ld [hl], a
	ld a, $f0 ; Return value. It means the last input was up or down (zip code value changed).
	jp DisplayZipCodeAfterChange
.press_up ; press up, zip code number menu
	pop af
	inc a
	cp 37
	jr c, .no_underflow ; Actually means "no overflow".
	xor a
	jr .no_underflow

.press_right
	push de
	hlcoord 17 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH ; Zip Code Menu width
	call DisplayBlankGoldenBox
	pop de
	ld a, d
	cp ZIPCODE_LENGTH - 1 ; Limits how far you can press D_RIGHT
	jr nc, .asm_48baf
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
	hlcoord 17 - ZIPCODE_LENGTH, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, ZIPCODE_LENGTH ; Zip Code Menu width
	call DisplayBlankGoldenBox
	pop de
	ld a, d
	and a
	pop af
	pop hl
	ld b, a
	ld a, d
	and a
	ld a, b
	jr z, .asm_48bf3
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

DisplayZipCodeAfterChange:
	push af
	hlcoord 18 - ZIPCODE_LENGTH, 11 ; Zip code location
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

Function48c63:
	ld a, "@"
	ld [de], a
	ld a, c
	cp $30
	jr nc, .asm_48c8c
	and a
	jr z, .asm_48c8c
	dec c
	push de
	ld h, d
	ld l, e
	ld a, "@"
	ld b, 7
.asm_48c76
	ld [hli], a
	dec b
	jr nz, .asm_48c76
	ld hl, Prefectures
	ld a, c
	call GetNthString
.asm_48c81
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	cp "@"
	jr nz, .asm_48c81
	and a
	pop de
	ret

.asm_48c8c
	scf
	ret

Function48ca3:
	push af
	push bc
	push de
	push hl
	ld b, 0
	ld c, 0
	ld d, 0
.asm_48cad
	cp 100
	jr c, .asm_48cb6
	sub 100
	inc b
	jr .asm_48cad

.asm_48cb6
	cp 10
	jr c, .asm_48cbf
	sub 10
	inc c
	jr .asm_48cb6

.asm_48cbf
	cp 1
	jr c, .asm_48cc7
	dec a
	inc d
	jr .asm_48cbf

.asm_48cc7
	ld a, b
	call Mobile12_Index2Char
	inc hl
	ld a, c
	call Mobile12_Index2Char
	inc hl
	ld a, d
	call Mobile12_Index2Char
	pop hl
	pop de
	pop bc
	pop af
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
	ld de, wAttrMap - wTileMap
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
	;call Mobile22_IncCursorFrameCounter
	ld a, [wd002]
	bit 4, a
	jr z, .skip_cursor_hiding

	push de
	farcall Mobile22_Clear24FirstOAM
	pop de
	ret

.skip_cursor_hiding
	ld hl, wVirtualOAMSprite00
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