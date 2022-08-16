InitMobileProfile:
	xor a
	set 6, a
	ld [wd002], a
	ld hl, wd003
	set 0, [hl]
	ld a, c
	and a
	call z, InitCrystalData
	call ClearBGPalettes
	call Function48d3d
	ld a, [wd479]
	bit 1, a
	jr z, .not_yet_initialized
	ld a, [wd003]
	set 0, a
	set 1, a
	set 2, a
	set 3, a
	ld [wd003], a
.not_yet_initialized
	call Function486bf
	call LoadFontsExtra
	ld de, MobileUpArrowGFX
	ld hl, vTiles2 tile $10
	lb bc, BANK(MobileUpArrowGFX), 1
	call Request1bpp
	ld de, MobileDownArrowGFX
	ld hl, vTiles2 tile $11
	lb bc, BANK(MobileDownArrowGFX), 1
	call Request1bpp
	call Function4a3a7
	call ClearBGPalettes
	ld a, [wd002]
	bit 6, a
	jr z, .asm_4808a
	call Function48689
	jr .asm_480d7
.asm_4808a
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
	call Function48cdc
	hlcoord 2, 4 ; Position of Gender string
	ld de, MobileString_Gender
	call PlaceString
.asm_480d7
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
	hlcoord 13, 11 ; Zip Code Position in MOBILE menu
	call Function489ea
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
	jp nz, Function4820d
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
	call Function48d30
	pop bc
	call ClearTileMap
	ld a, $ff
	ret

Function48187:
	ld a, [wd479]
	bit 1, a
	jr nz, .asm_481f1
	ld a, [wd003]
	ld d, a
	call Function48725
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

Function4820d:
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
	jr z, asm_4828d
	cp $2
	jp z, Function4876f
	cp $3
	jp z, Function48304
	cp $4
	jp z, Function488d3
	ld a, $2
	call MenuClickSound
	ld a, [wd002]
	bit 6, a
	jr z, .asm_4825c
	jr .asm_4825c

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

.asm_4825c
	call ClearBGPalettes
	call Function48d30
	pop bc
	call ClearTileMap
	ld b, SCGB_DIPLOMA
	call GetSGBLayout
	ld hl, wd479
	set 1, [hl]
	xor a
	ret

Function48272:
	jp Function4840c

MobileString_PersonalInfo:
	db "Personal Info@"

Function48283:
	lb bc, 2, 18
	hlcoord 1, 15
	call ClearBox
	ret

asm_4828d:
	call Function48283
	hlcoord 1, 16
	ld de, MobileDesc_Gender
	call PlaceString
	ld hl, MenuHeader_0x484f1
	call LoadMenuHeader
	call Function4873c
	hlcoord 13, 2 ; Gender menu position
	ld b, $4
	ld c, $5
	call Function48cdc
	hlcoord 15, 4 ; Position of Male Gender string in Gender menu
	ld de, String_484fb
	call PlaceString
	hlcoord 15, 6 ; Position of Female Gender string in Gender menu
	ld de, String_484ff
	call PlaceString
	call WaitBGMap
	ld a, [wPlayerGender]
	inc a
	ld [wMenuCursorBuffer], a
	call StaticMenuJoypad
	call PlayClickSFX
	call ExitMenu
	bit 0, a
	jp z, Function4840c
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
	ld a, [wd003]
	set 0, a
	ld [wd003], a
	jp Function4840c

Function48304:
	call Function48283
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
	call Function48cdc
	ld a, [wMenuCursorBuffer]
	ld b, a
	ld a, [wMenuScrollPosition]
	ld c, a
	push bc
	ld a, [wd474]
	dec a
	cp $29
	jr c, .asm_4833f
	sub $29
	inc a
	ld [wMenuCursorBuffer], a
	ld a, $29
.asm_4833f
	ld [wMenuScrollPosition], a
	farcall Mobile_OpenAndCloseMenu_HDMATransferTileMapAndAttrMap
.asm_48348
	call ScrollingMenu
	ld de, $629
	call Function48383
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
	bit 0, a
	jr z, .asm_48377
	call Function483bb
	ld a, [wd003]
	set 2, a
	ld [wd003], a
.asm_48377
	call Function48187
	farcall Mobile_OpenAndCloseMenu_HDMATransferTileMapAndAttrMap
	jp Function4840c

Function48383:
	push bc
	push af
	bit 5, a
	jr nz, .asm_48390
	bit 4, a
	jr nz, .asm_4839f
	and a
	jr .asm_483b7
.asm_48390
	ld a, [wMenuScrollPosition]
	sub d
	ld [wMenuScrollPosition], a
	jr nc, .asm_483af
	xor a
	ld [wMenuScrollPosition], a
	jr .asm_483af
.asm_4839f
	ld a, [wMenuScrollPosition]
	add d
	ld [wMenuScrollPosition], a
	cp e
	jr c, .asm_483af
	ld a, e
	ld [wMenuScrollPosition], a
	jr .asm_483af
.asm_483af
	ld hl, wMenuCursorY
	ld a, [hl]
	ld [wMenuCursorBuffer], a
	scf
.asm_483b7
	pop bc
	ld a, b
	pop bc
	ret

Function483bb:
	ld hl, wScrollingMenuCursorPosition
	ld a, [hl]
	inc a
	ld [wd474], a
	dec a
	ld b, a
	ld hl, Prefectures
.asm_483c8
	and a
	jr z, .asm_483d5
.asm_483cb
	ld a, [hli]
	cp "@"
	jr nz, .asm_483cb
	ld a, b
	dec a
	ld b, a
	jr .asm_483c8
.asm_483d5
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
	ld hl, Wyoming ; last string
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

Function4840c:
	call Function48187
	call Function48283
	hlcoord 1, 16
	ld de, MobileString_PersonalInfo
	call PlaceString
	call Function486bf
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

Mobile12_Bin2Dec:
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

MenuHeader_0x4850e:
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
	db 63 ; The number of locations in the prefectures list (-1 because it starts at 0)
x = 0
rept 63 ; The number of locations in the prefectures list (-1 because it starts at 0)
	db x
x = x + 1
endr
	db -1

Prefectures: ; Some names shortened to fit, check for official initials later.
Alberta:                       db	"CA-AB@"  ;Alberta
British_Columbia:              db	"CA-BC@"  ;British_Columbia
Manitoba:                      db	"CA-MB@"  ;Manitoba
New_Brunswick:                 db	"CA-NB@"  ;New_Brunswick
Newfoundland_and_Labrador:     db	"CA-NL@"  ;Newfoundland_and_Labrador
Nova_Scotia:                   db	"CA-NS@"  ;Nova_Scotia
Northwest_Territories:         db	"CA-NT@"  ;Northwest_Territories
Nunavut:                       db	"CA-NU@"  ;Nunavut
Ontario:                       db	"CA-ON@"  ;Ontario
Prince_Edward_Island:          db	"CA-PE@"  ;Prince_Edward_Island
Quebec:                        db	"CA-QC@"  ;Quebec
Saskatchewan:                  db	"CA-SK@"  ;Saskatchewan
Yukon:                         db	"CA-YT@"  ;Yukon
Alaska:                        db	"US-AK@"  ;Alaska
Alabama:                       db	"US-AL@"  ;Alabama
Arkansas:                      db	"US-AR@"  ;Arkansas
Arizona:                       db	"US-AZ@"  ;Arizona
California:                    db	"US-CA@"  ;California
Colorado:                      db	"US-CO@"  ;Colorado
Connecticut:                   db	"US-CT@"  ;Connecticut
District_Of_Columbia:          db	"US-DC@"  ;District_Of_Columbia
Delaware:                      db	"US-DE@"  ;Delaware
Florida:                       db	"US-FL@"  ;Florida
Georgia:                       db	"US-GA@"  ;Georgia
Hawaii:                        db	"US-HI@"  ;Hawaii
Iowa:                          db	"US-IA@"  ;Iowa
Idaho:                         db	"US-ID@"  ;Idaho
Illinois:                      db	"US-IL@"  ;Illinois
Indiana:                       db	"US-IN@"  ;Indiana
Kansas:                        db	"US-KS@"  ;Kansas
Kentucky:                      db	"US-KY@"  ;Kentucky
Louisiana:                     db	"US-LA@"  ;Louisiana
Massachusetts:                 db	"US-MA@"  ;Massachusetts
Maryland:                      db	"US-MD@"  ;Maryland
Maine:                         db	"US-ME@"  ;Maine
Michigan:                      db	"US-MI@"  ;Michigan
Minnesota:                     db	"US-MN@"  ;Minnesota
Missouri:                      db	"US-MO@"  ;Missouri
Mississippi:                   db	"US-MS@"  ;Mississippi
Montana:                       db	"US-MT@"  ;Montana
North_Carolina:                db	"US-NC@"  ;North_Carolina
North_Dakota:                  db	"US-ND@"  ;North_Dakota
Nebraska:                      db	"US-NE@"  ;Nebraska
New_Hampshire:                 db	"US-NH@"  ;New_Hampshire
New_Jersey:                    db	"US-NJ@"  ;New_Jersey
New_Mexico:                    db	"US-NM@"  ;New_Mexico
Nevada:                        db	"US-NV@"  ;Nevada
New_York:                      db	"US-NY@"  ;New_York
Ohio:                          db	"US-OH@"  ;Ohio
Oklahoma:                      db	"US-OK@"  ;Oklahoma
Oregon:                        db	"US-OR@"  ;Oregon
Pennsylvania:                  db	"US-PA@"  ;Pennsylvania
Rhode_Island:                  db	"US-RI@"  ;Rhode_Island
South_Carolina:                db	"US-SC@"  ;South_Carolina
South_Dakota:                  db	"US-SD@"  ;South_Dakota
Tennessee:                     db	"US-TN@"  ;Tennessee
Texas:                         db	"US-TX@"  ;Texas
Utah:                          db	"US-UT@"  ;Utah
Virginia:                      db	"US-VA@"  ;Virginia
Vermont:                       db	"US-VT@"  ;Vermont
Washington:                    db	"US-WA@"  ;Washington
Wisconsin:                     db	"US-WI@"  ;Wisconsin
West_Virginia:                 db	"US-WV@"  ;West_Virginia
Wyoming:                       db	"US-WY@"  ;Wyoming

Function48689:
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
	ld a, $c
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
	call Function48cdc
	ret

Function486bf:
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
	call Function48725
	ld a, 4
	jr nc, .got_num_rows_1
	ld a, 5
.got_num_rows_1
	ld [hli], a
	jr .got_num_rows_2

.check_wd479
	ld a, [wd479]
	bit 1, a
	jr nz, .four_rows
	call Function48725
	jr c, .four_rows
	ld a, 3
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
	ld a, $20
	ld [hli], a ; cursor offsets
	ld a, A_BUTTON
	add D_UP
	add D_DOWN
	push af
	ld a, [wd002]
	bit 6, a
	jr z, .got_joypad_mask
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

Function48725:
;	 ld a, [wd003]
;	 and $f
;	 cp $f
;	 jr nz, .clear_carry
;	 scf
;	 ret
; .clear_carry
;	 and a
;	 ret

	ld a, [wd003]
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

Function4873c:
	ld hl, w2DMenuCursorInitY
	ld a, 4
	ld [hli], a
	ld a, 14 ; x axis position of the gender cursor
	ld [hli], a ; init x
	ld a, 2
	ld [hli], a ; num rows
	ld a, 1
	ld [hli], a ; num cols
	ld [hl], 0 ; flags 1
	set 5, [hl]
	inc hl
	xor a
	ld [hli], a ; flags 2
	ln a, 2, 0
	ld [hli], a ; cursor offsets
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

Function4876f:
	call Function48283
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
	call Function48cdc
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
	jp Function4840c

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
	call Function48cdc
	hlcoord 16, 6 ; Age menu up arrow position when using D-Pad
	ld [hl], $10
	jr .asm_488a7
.asm_48898
	hlcoord 14, 6 ; Age menu up arrow position when using D-Pad
	ld b, $1
	ld c, $4
	call Function48cdc
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
	ld a, [wd003]
	set 1, a
	ld [wd003], a
	scf
	ret

MobileUpArrowGFX:
INCBIN "gfx/mobile/up_arrow.2bpp"

MobileDownArrowGFX:
INCBIN "gfx/mobile/down_arrow.2bpp"

Function488d3:
	call Function48283
	hlcoord 1, 16
	ld de, MobileDesc_ZipCode
	call PlaceString
	call Function48a3a
	jp c, Function4840c
	ld hl, MenuHeader_0x4850e
	call LoadMenuHeader
	ldh a, [hInMenu]
	push af
	ld a, $1
	ldh [hInMenu], a
	hlcoord 12, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, $6 ; Zip Code Menu width
	call Function48cdc
	ld a, [wd475]
	and $f
	ld d, $0
	hlcoord 13, 11 ; Zip Code Position
	call Function489ea
	call WaitBGMap
	ld a, [wd475]
	ld b, a
	ld a, [wd476]
	ld c, a
	ld a, [wd477]
	ld d, a
	ld a, [wd478]
	ld e, a
	push de
	push bc
	ld d, $0
	ld b, $0

asm_48922:
	push bc
	call JoyTextDelay
	ldh a, [hJoyDown]
	and a
	jp z, Function4896e
	bit 0, a
	jp nz, Function4896e
	bit 1, a
	jp nz, Function4896e
	ld a, [wd002]
	and %11001111
	res 7, a
	ld [wd002], a
	pop bc
	inc b
	ld a, b
	cp $5
	push bc
	jr c, .asm_4894c
	pop bc
	ld b, $4
	push bc
.asm_4894c
	pop bc
	push bc
	ld a, b
	cp $4
	jr nz, asm_48972
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
	call Function48ab5
	push af
	cp $f0
	jr z, .asm_48994
	cp $f
	jr nz, .asm_48988
	ld a, [wd002]
	set 7, a
	and $cf
	ld [wd002], a
.asm_48988
	hlcoord 13, 11 ; Zip code location
	ld b, $0
	ld c, d
	add hl, bc
	ld b, $3
	call Function48c11
.asm_48994
	call WaitBGMap
	pop af
	pop bc
	jr nc, asm_48922
	jr nz, .asm_489b1
	pop bc
	ld a, b
	ld [wd475], a
	ld a, c
	ld [wd476], a
	pop bc
	ld a, b
	ld [wd477], a
	ld a, c
	ld [wd478], a
	jr .asm_489c5
.asm_489b1
	push af
	ld a, [wd479]
	set 0, a
	ld [wd479], a
	ld a, [wd003]
	set 3, a
	ld [wd003], a
	pop af
	pop bc
	pop bc
.asm_489c5
	push af
	push bc
	push de
	push hl
	ld a, $1
	call MenuClickSound
	pop hl
	pop de
	pop bc
	pop af
	call ExitMenu
	hlcoord 13, 11 ; Zip Code location
	call Function489ea
	hlcoord 8, 11 ; Location of a clear box to clear any excess characters if 'Tell Now' is selected, but cannot overlap the position of the zip code itself, because otherwise it will clear that too.
	lb bc, 1, 4 ; Determines the size of the clearing box
	call ClearBox
	pop af
	ldh [hInMenu], a
	jp Function4840c

Function489ea: ; Flashing zip code numbers?
	push de
	ld a, [wd475]
	and $f
	call Mobile12_Bin2Dec
	ld a, [wd476]
	and $f0
	swap a
	inc hl
	call Mobile12_Bin2Dec
	ld a, [wd476]
	and $f
	inc hl
	call Mobile12_Bin2Dec
	;inc hl ; Responsible for the gap where "-" existed
	;ld de, String_48a38
	;call PlaceString
	ld a, [wd477]
	and $f0
	swap a
	inc hl
	call Mobile12_Bin2Dec
	ld a, [wd477]
	and $f
	inc hl
	call Mobile12_Bin2Dec
	;ld a, [wd478]
	;and $f
	;swap a
	;inc hl
	;call Mobile12_Bin2Dec
	;ld a, [wd478]
	;and $f
	;inc hl
	;call Mobile12_Bin2Dec
	pop de
	ret

String_48a38:
	db "-@" ; Unused

Function48a3a:
	ld hl, MenuHeader_0x48a9c
	call LoadMenuHeader
	call Function4873c
	ld a, $a
	ld [w2DMenuCursorInitY], a
	ld a, $8 ; Y Placement of 'Tell Now' 'Tell Later' Cursor
	ld [w2DMenuCursorInitX], a
	ld a, $1 ; X Placement of 'Later' Cursor
	ld [wMenuCursorY], a
	hlcoord 7, 8 ; Placement of 'Tell Now' 'Tell Later' Box
	ld b, $4
	ld c, $b
	call Function48cdc
	hlcoord 9, 10 ; Placement of 'Tell Now' 'Tell Later' Text
	ld de, String_48aa1
	call PlaceString
	call StaticMenuJoypad
	push af
	call PlayClickSFX
	call ExitMenu
	pop af
	bit 1, a
	jp nz, Function48a9a
	ld a, [wMenuCursorY]
	cp $1
	jr z, .asm_48a98
	ld a, [wd003]
	set 3, a
	ld [wd003], a
	ld a, [wd479]
	res 0, a
	ld [wd479], a
	xor a
	ld bc, $4
	ld hl, wd475
	call ByteFill
	jr Function48a9a
.asm_48a98
	and a
	ret

Function48a9a:
	scf
	ret

MenuHeader_0x48a9c:
	db MENU_BACKUP_TILES ; flags
	menu_coords 5, 8, SCREEN_WIDTH - 1, 13 ; For clearing the 'Tell Later' 'Tell Now' Box

String_48aa1:
	db   "Tell Now"
	next "Tell Later@"

Function48ab5: ; Zip code menu controls
	ldh a, [hJoyPressed]
	and A_BUTTON
	jp nz, Function48c0f
	ldh a, [hJoyPressed]
	and B_BUTTON
	jp nz, Function48c0d
	ld a, d
	and a
	jr z, .asm_48adf
	cp $1
	jr z, .asm_48ae7
	cp $2
	jr z, .asm_48af1
	cp $3
	jr z, .asm_48af9
	cp $4
	jr z, .asm_48b03
	cp $5
	jr z, .asm_48b0b
	cp $6
	jr .asm_48b15
.asm_48adf
	ld hl, wd475
	ld a, [hl]
	and $f
	jr .asm_48b1d
.asm_48ae7
	ld hl, wd476
	ld a, [hl]
	swap a
	or $f0
	jr .asm_48b1d
.asm_48af1
	ld hl, wd476
	ld a, [hl]
	and $f
	jr .asm_48b1d
.asm_48af9
	ld hl, wd477
	ld a, [hl]
	swap a
	or $f0
	jr .asm_48b1d
.asm_48b03
	ld hl, wd477
	ld a, [hl]
	and $f
	jr .asm_48b1d
.asm_48b0b
	ld hl, wd478
	ld a, [hl]
	swap a
	or $f0
	jr .asm_48b1d
.asm_48b15
	ld hl, wd478
	ld a, [hl]
	and $f
	jr .asm_48b1d
.asm_48b1d
	push hl
	push af
	ld e, $0
	hlcoord 13, 11 ; Zip code location
	ld a, d
.asm_48b25
	and a
	jr z, .asm_48b2c
	inc e
	dec a
	jr .asm_48b25
.asm_48b2c ; zip code number controls
	ld hl, hJoyLast
	ld a, [hl]
	and D_UP
	jr nz, .asm_48b8d
	ld a, [hl]
	and D_DOWN
	jr nz, .asm_48b55
	ld a, [hl]
	and D_LEFT
	jp nz, Function48bd7
	ld a, [hl]
	and D_RIGHT
	jr nz, .asm_48b9d
	hlcoord 13, 11 ; Zip Code Location
	call Function489ea
	ld a, [wd002]
	bit 7, a
	jr nz, .asm_48b51
.asm_48b51
	pop bc
	pop bc
	and a
	ret
.asm_48b55 ; press down, zip code number menu
	pop af
	ld b, a
	and $f
	and a
	ld a, b
	jr nz, .asm_48b61
	and $f0
	add $a
.asm_48b61 ; change value when pressing down?
	dec a
.asm_48b62
	push de
	push af
	hlcoord 12, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, $6 ; Zip Code Menu width
	call Function48cdc
	pop af
	pop de
	hlcoord 10, 9 ; hlcoord 11, 10
	ld b, a
	ld a, d
	cp $3
	jr c, .asm_48b7a
	inc hl
.asm_48b7a ; changes zip code number tiles
	ld a, b
	pop hl
	bit 7, a
	jr z, .asm_48b85
	call Function48c4d
	jr .asm_48b88
.asm_48b85
	call Function48c5a
.asm_48b88
	ld a, $f0
	jp Function48c00
.asm_48b8d ; press up, zip code number menu
	pop af
	ld b, a
	and $f
	cp $9
	ld a, b
	jr c, .asm_48b9a
	and $f0
	add $ff
.asm_48b9a ; press up, zip code number menu
	inc a
	jr .asm_48b62
.asm_48b9d ; press up, zip code number menu
	push de
	hlcoord 12, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, $6 ; Zip Code Menu width
	call Function48cdc
	pop de
	ld a, d
	cp $4 ; Limits how far you can press D_RIGHT
	jr nc, .asm_48baf
	inc d
.asm_48baf
	pop af
	pop hl
	ld b, a
	ld a, d
	cp $5
	ld a, b
	jr z, .asm_48bc4
	bit 7, a
	jr nz, .asm_48bc4
	inc hl
	ld a, [hl]
	swap a
	and $f
	jr asm_48bc7
.asm_48bc4 ; press left, zip code number menu
	ld a, [hl]
	and $f

asm_48bc7:
	hlcoord 10, 9
	push af
	ld a, d
	cp $3
	pop bc
	ld a, b
	jr c, .asm_48bd3
	inc hl
.asm_48bd3
	ld a, $f
	jr Function48c00

Function48bd7:
	push de
	hlcoord 12, 10
	ld b, $1 ; Zip Code Menu starting point
	ld c, $6 ; Zip Code Menu width
	call Function48cdc
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
	jr asm_48bc7
.asm_48bf8
	dec d
	ld a, [hl]
	swap a
	and $f
	jr asm_48bc7

Function48c00:
	push af
	hlcoord 13, 11 ; Zip code location
	call Function489ea
	ld a, $1
	and a
	pop bc
	ld a, b
	ret

Function48c0d:
	xor a
	and a

Function48c0f:
	scf
	ret

Function48c11:
	ld a, [wd002]
	bit 7, a
	jr z, .asm_48c20
	ld a, d
	cp $6 ; Controls the location of the jump in Zip code digit highlights after the dash
	jr c, .asm_48c1e
	inc hl
.asm_48c1e
	ld [hl], $7f
.asm_48c20
	ld a, [wd002]
	swap a
	and $3
	inc a
	cp b
	jr nz, .asm_48c40
	ld a, [wd002]
	bit 7, a
	jr z, .asm_48c3a
	res 7, a
	ld [wd002], a
	xor a
	jr .asm_48c40
.asm_48c3a
	set 7, a
	ld [wd002], a
	xor a
.asm_48c40
	swap a
	ld b, a
	ld a, [wd002]
	and $cf
	or b
	ld [wd002], a
	ret

Function48c4d:
	swap a
	and $f0
	push af
	ld a, [hl]
	and $f
	ld [hl], a
	pop af
	or [hl]
	ld [hl], a
	ret

Function48c5a:
	push af
	ld a, [hl]
	and $f0
	ld [hl], a
	pop af
	or [hl]
	ld [hl], a
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

Unreferenced_Function48c8e: ; unreferenced
	ld hl, wd019 + $11
	ld d, h
	ld e, l
	farcall Function48c63
	hlcoord 10, 7
	call PlaceString
	call WaitBGMap
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
	call Mobile12_Bin2Dec
	inc hl
	ld a, c
	call Mobile12_Bin2Dec
	inc hl
	ld a, d
	call Mobile12_Bin2Dec
	pop hl
	pop de
	pop bc
	pop af
	ret

Function48cda:
	ld h, d
	ld l, e

Function48cdc:
	push bc
	push hl
	call Function48cfd
	pop hl
	pop bc
	ld de, wAttrMap - wTileMap
	add hl, de
	inc b
	inc b
	inc c
	inc c
	ld a, $0
.asm_48ced
	push bc
	push hl
.asm_48cef
	ld [hli], a
	dec c
	jr nz, .asm_48cef
	pop hl
	ld de, $14
	add hl, de
	pop bc
	dec b
	jr nz, .asm_48ced
	ret

Function48cfd:
	push hl
	ld a, $4
	ld [hli], a
	inc a
	call Function48d2a
	inc a
	ld [hl], a
	pop hl
	ld de, $14
	add hl, de
.asm_48d0c
	push hl
	ld a, $7
	ld [hli], a
	ld a, $7f
	call Function48d2a
	ld [hl], $8
	pop hl
	ld de, $14
	add hl, de
	dec b
	jr nz, .asm_48d0c
	ld a, $9
	ld [hli], a
	ld a, $a
	call Function48d2a
	ld [hl], $b
	ret

Function48d2a:
	ld d, c
.asm_48d2b
	ld [hli], a
	dec d
	jr nz, .asm_48d2b
	ret

Function48d30:
	ld hl, wd475
	call Function48d4a
	ld hl, wd477
	call Function48d4a
	ret

Function48d3d:
	ld hl, wd475
	call Function48d94
	ld hl, wd477
	call Function48d94
	ret

Function48d4a:
	inc hl
	ld a, [hl]
	ld b, a
	and $f
	ld c, a
	srl b
	srl b
	srl b
	srl b
	push bc
	ld c, 10
	ld a, b
	call SimpleMultiply
	pop bc
	add c
	ld [hld], a
	xor a
	ldh [hMultiplicand + 0], a
	ldh [hMultiplicand + 1], a
	ld a, [hl]
	srl a
	srl a
	srl a
	srl a
	ld c, 10
	call SimpleMultiply
	ld b, a
	ld a, [hli]
	and $f
	add b
	ldh [hMultiplicand + 2], a
	ld a, 100
	ldh [hMultiplier], a
	call Multiply
	ldh a, [hProduct + 2]
	ld b, a
	ldh a, [hProduct + 3]
	ld c, a
	ld e, [hl]
	add e
	ld c, a
	ld a, b
	adc 0
	ld b, a
	ld a, c
	ld [hld], a
	ld [hl], b
	ret

Function48d94:
	xor a
	ldh [hDividend + 0], a
	ldh [hDividend + 1], a
	ld a, [hli]
	ldh [hDividend + 0], a
	ld a, [hl]
	ldh [hDividend + 1], a
	ld a, 100
	ldh [hDivisor], a
	ld b, 2
	call Divide
	ldh a, [hRemainder]
	ld c, 10
	call SimpleDivide
	sla b
	sla b
	sla b
	sla b
	or b
	ld [hld], a
	ldh a, [hQuotient + 3]
	ld c, 10
	call SimpleDivide
	sla b
	sla b
	sla b
	sla b
	or b
	ld [hl], a
	ret
