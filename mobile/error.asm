BattleTowerMobileError: ; all of this moved from mobile_5f
	call FadeToMenu
	xor a
	ld [wc303], a
	ldh a, [rSVBK]
	push af
	ld a, $1
	ldh [rSVBK], a

	call DisplayMobileError

	pop af
	ldh [rSVBK], a
	call ExitAllMenus
	ret

DisplayMobileError:
.loop
	call JoyTextDelay
	call .RunJumptable
	ld a, [wc303]
	bit 7, a
	jr nz, .quit
	farcall HDMATransferAttrmapAndTilemapToWRAMBank3
	jr .loop

.quit
	call .deinit
	ret

.deinit
	ld a, [wMobileErrorCodeBuffer]
	cp $22
	jr z, .asm_17f597
	cp $31
	jr z, .asm_17f58a
	cp $33
	ret nz
	ld a, [wMobileErrorCodeBuffer + 1]
	cp $1
	ret nz
	ld a, [wMobileErrorCodeBuffer + 2]
	cp $2
	ret nz
	jr .asm_17f5a1

.asm_17f58a
	ld a, [wMobileErrorCodeBuffer + 1]
	cp $3
	ret nz
	ld a, [wMobileErrorCodeBuffer + 2]
	and a
	ret nz
	jr .asm_17f5a1

.asm_17f597
	ld a, [wMobileErrorCodeBuffer + 1]
	and a
	ret nz
	ld a, [wMobileErrorCodeBuffer + 2]
	and a
	ret nz

.asm_17f5a1
	ld a, BANK(sMobileLoginPassword)
	call OpenSRAM
	xor a
	ld [sMobileLoginPassword], a
	call CloseSRAM
	ret

.RunJumptable:
	jumptable .Jumptable, wc303

.Jumptable:
	dw Function17f5c3
	dw Function17ff23
	dw Function17f5d2

Function17f5c3:
	call Function17f5e4
	farcall FinishExitMenu
	ld a, $1
	ld [wc303], a
	ret

Function17f5d2:
	call Function17f5e4
	farcall HDMATransferAttrmapAndTilemapToWRAMBank3
	call SetPalettes
	ld a, $1
	ld [wc303], a
	ret

Function17f5e4:
	ld a, $8
	ld [wMusicFade], a
	ld de, MUSIC_NONE
	ld a, e
	ld [wMusicFadeID], a
	ld a, d
	ld [wMusicFadeID + 1], a
	ld a, " "
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	call ByteFill
	ld a, $6
	hlcoord 0, 0, wAttrmap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	call ByteFill
	hlcoord 2, 1
	ld b, $1
	ld c, $e
	call Function3eea
	hlcoord 0, 4;1, 4
	ld b, $c
	ld c, $12;$10
	call Function3eea
	hlcoord 3, 2
	ld de, String_17f6dc
	call PlaceString
	call Function17ff3c
	jr nc, .asm_17f632
	hlcoord 11, 2
	call Function17f6b7

.asm_17f632
	ld a, [wMobileErrorCodeBuffer]
	cp $d0
	jr nc, .asm_17f684
	cp $10
	jr c, .asm_17f679
	sub $10
	cp $24
	jr nc, .asm_17f679
	ld e, a
	ld d, $0
	ld hl, Table_17f706
	add hl, de
	add hl, de
	ld a, [wMobileErrorCodeBuffer + 1]
	ld e, a
	ld a, [wMobileErrorCodeBuffer + 2]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld h, a
	ld l, c
	ld a, [hli]
	and a
	jr z, .asm_17f679
	ld c, a
.asm_17f65d
	ld a, [hli]
	ld b, a
	ld a, [hli]
	cp $ff
	jr nz, .asm_17f667
	cp b
	jr z, .asm_17f66e

.asm_17f667
	xor d
	jr nz, .asm_17f674
	ld a, b
	xor e
	jr nz, .asm_17f674

.asm_17f66e
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	jr .asm_17f67d

.asm_17f674
	inc hl
	inc hl
	dec c
	jr nz, .asm_17f65d

.asm_17f679
	ld a, $d9
	jr .asm_17f684

.asm_17f67d
	hlcoord 1, 6;2, 6
	call PlaceString
	ret

.asm_17f684
	sub $d0
	ld e, a
	ld d, 0
	ld hl, Table_17f699
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	hlcoord 1, 6;2, 6
	call PlaceString
	ret

Table_17f699:
	dw String_17fedf
	dw String_17fdd9
	dw String_17fdd9
	dw String_17fe03
	dw String_17fd84
	dw String_17fe63
	dw String_17fdb2
	dw String_17fe4b
	dw String_17fe03
	dw String_17fe03
	dw String_17fe03

Palette_17f6af:
	RGB  5,  5, 16
	RGB  8, 19, 28
	RGB  0,  0,  0
	RGB 31, 31, 31

Function17f6b7:
	ld a, [wMobileErrorCodeBuffer]
	call .bcd_two_digits
	inc hl
	ld a, [wMobileErrorCodeBuffer + 2]
	and $f
	call .bcd_digit
	ld a, [wMobileErrorCodeBuffer + 1]
	call .bcd_two_digits
	ret

.bcd_two_digits
	ld c, a
	and $f0
	swap a
	call .bcd_digit
	ld a, c
	and $f

.bcd_digit
	add "0"
	ld [hli], a
	ret

String_17f6dc:
	db "ERROR: 　　　-@"		; "つうしんエラー　　　ー@"

String_17f6e8:
	db   "Unknown error." 	; "みていぎ<NO>エラーです"
	next "Please check"		; "プログラム<WO>"
	next "the program."		; "かくにん　してください"
	db   "@"

Table_17f706:
	dw Unknown_17f74e
	dw Unknown_17f753
	dw Unknown_17f758
	dw Unknown_17f75d
	dw Unknown_17f762
	dw Unknown_17f767
	dw Unknown_17f778
	dw Unknown_17f77d
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f782
	dw Unknown_17f787
	dw Unknown_17f78c
	dw Unknown_17f791
	dw Unknown_17f796
	dw Unknown_17f79b
	dw Unknown_17f7a0
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7a5
	dw Unknown_17f7ea
	dw Unknown_17f7ff
	dw Unknown_17f844

Unknown_17f74e: db 1
	dbbw $0, $0, String_17f891

Unknown_17f753: db 1
	dbbw $0, $0, String_17f8d1

Unknown_17f758: db 1
	dbbw $0, $0, String_17f913

Unknown_17f75d: db 1
	dbbw $0, $0, String_17f8d1

Unknown_17f762: db 1
	dbbw $0, $0, String_17fa71

Unknown_17f767: db 4
	dbbw $0, $0, String_17f946
	dbbw $1, $0, String_17f946
	dbbw $2, $0, String_17f946
	dbbw $3, $0, String_17f946

Unknown_17f778: db 1
	dbbw $0, $0, String_17f98e

Unknown_17f77d: db 1
	dbbw $0, $0, String_17f98e

Unknown_17f782: db 1
	dbbw $0, $0, String_17f98e

Unknown_17f787: db 1
	dbbw $0, $0, String_17f98e

Unknown_17f78c: db 1
	dbbw $0, $0, String_17f9d0

Unknown_17f791: db 1
	dbbw $0, $0, String_17fa14

Unknown_17f796: db 1
	dbbw $0, $0, String_17fcbf

Unknown_17f79b: db 1
	dbbw $0, $0, String_17fa71

Unknown_17f7a0: db 1
	dbbw $0, $0, String_17fbfe

Unknown_17f7a5: db 17
	dbbw $0, $0, String_17f98e
	dbbw $21, $2, String_17fcbf
	dbbw $21, $4, String_17fcbf
	dbbw $50, $4, String_17faf9
	dbbw $51, $4, String_17fcbf
	dbbw $52, $4, String_17fcbf
	dbbw $0, $5, String_17f98e
	dbbw $1, $5, String_17f98e
	dbbw $2, $5, String_17f98e
	dbbw $3, $5, String_17f98e
	dbbw $4, $5, String_17f98e
	dbbw $50, $5, String_17faf9
	dbbw $51, $5, String_17faf9
	dbbw $52, $5, String_17fcbf
	dbbw $53, $5, String_17faf9
	dbbw $54, $5, String_17fcbf
	dbbw $ff, $ff, String_17fcbf

Unknown_17f7ea: db 5
	dbbw $0, $0, String_17f98e
	dbbw $2, $0, String_17fb2a
	dbbw $3, $0, String_17fb6e
	dbbw $4, $0, String_17f98e
	dbbw $ff, $ff, String_17fcbf

Unknown_17f7ff: db 17
	dbbw $0, $0, String_17f98e
	dbbw $1, $3, String_17f98e
	dbbw $2, $3, String_17f98e
	dbbw $0, $4, String_17f98e
	dbbw $1, $4, String_17f98e
	dbbw $3, $4, String_17fbb6
	dbbw $4, $4, String_17fbb6
	dbbw $5, $4, String_17f98e
	dbbw $6, $4, String_17f98e
	dbbw $7, $4, String_17f98e
	dbbw $8, $4, String_17fbfe
	dbbw $0, $5, String_17fa49
	dbbw $1, $5, String_17f98e
	dbbw $2, $5, String_17fa49
	dbbw $3, $5, String_17fab0
	dbbw $4, $5, String_17fa49
	dbbw $ff, $ff, String_17fa49

Unknown_17f844: db 19
	dbbw $1, $1, String_17fc3e
	dbbw $2, $1, String_17fc88
	dbbw $3, $1, String_17fcff
	dbbw $4, $1, String_17fd84
	dbbw $5, $1, String_17fd84
	dbbw $6, $1, String_17fd47
	dbbw $1, $2, String_17fb6e
	dbbw $2, $2, String_17f98e
	dbbw $3, $2, String_17fd84
	dbbw $4, $2, String_17f98e
	dbbw $5, $2, String_17fa49
	dbbw $6, $2, String_17fd84
	dbbw $99, $2, String_17fc88
	dbbw $1, $3, String_17fa49
	dbbw $1, $4, String_17fa49
	dbbw $2, $4, String_17fa49
	dbbw $3, $4, String_17fa49
	dbbw $4, $4, String_17fa49
	dbbw $ff, $ff, String_17fa49

String_17f891: ; 18 max!
	db   "The Mobile Adapter" ; "モバイルアダプタが　ただしく"
	next "is not connected" ; "さしこまれていません"
	next "properly." ; "とりあつかいせつめいしょを"
	next "Please check the" ; "ごらんのうえ　しっかりと"
	next "manual." ; "さしこんで　ください"
	db   "@"

String_17f8d1:
	db   "Could not connect" ; "でんわが　うまく　かけられないか"
	next "because the line" ; "でんわかいせんが　こんでいるので"
	next "is busy." ; "つうしん　できません"
	next "Please try again" ; "しばらく　まって"
	next "later." ; "かけなおして　ください"
	db   "@" 

String_17f913:
	db   "Could not connect" ; "でんわかいせんが　こんでいるため"
	next "due to a high" ; "でんわが　かけられません"
	next "volume of calls." ; "しばらく　まって"
	next "Please try again" ; "かけなおして　ください"
	next "later." 
	db   "@" 

String_17f946:
	db   "Mobile Adapter" ; "モバイルアダプタの　エラーです"
	next "error." ; "しばらく　まって"
	next "Please try again." ; "かけなおして　ください"
	next "If the problem" ; "なおらない　ときは"
	next "persists, please" ; "モバイルサポートセンターへ"
	next "contact support." ; "おといあわせください"
	db   "@" 

String_17f98e:
	db   "Communication" ; "つうしんエラーです"
	next "error." ; "しばらく　まって"
	next "Please try again." ; "かけなおして　ください"
	next "If the problem" ; "なおらない　ときは"
	next "persists, please" ; "モバイルサポートセンターへ"
	next "contact support." ; "おといあわせください"
	db   "@" 

String_17f9d0:
    db   "Invalid Log-in" ; "ログインパスワードか"
    next "ID or Password." ; "ログイン　アイディーに"
    next "Please confirm" ; "まちがいがあります"
    next "your Log-in" ; "パスワードを　かくにんして"
    next "information" ; "しばらく　まって"
    next "and try again." ; "かけなおして　ください"
    db   "@"

String_17fa14:
	db   "The phone was" ; "でんわが　きれました"
	next "disconnected." ; "とりあつかいせつめいしょを"
	next "Please check the" ; "ごらんのうえ"
	next "manual and try" ; "しばらく　まって"
	next "again later." ; "かけなおして　ください"
	db   "@" 

String_17fa49:
	db   "Error connecting" ; "モバイルセンターの"
	next "to the" ; "つうしんエラーです"
	next "Mobile Center." ; "しばらくまって"
	next "Please try" ; "しばらくまって"
	next "again later." ; "かけなおして　ください"
	db   "@" 

String_17fa71:
	db   "The Mobile Adapter" ; "モバイルアダプタに"
	next "is not configured" ; "とうろくされた　じょうほうが"
	next "properly." ; "ただしく　ありません"
	next "Please register" ; "モバイルトレーナーで"
	next "your information" ; "しょきとうろくを　してください"
	next "in Mobile Trainer." 
	db   "@" 

String_17fab0:
	db   "The Mobile Center" ; "モバイルセンターが"
	next "is busy." ; "こんでいて　つながりません"
	next "Please check the" ; "しばらくまって"
	next "manual and try" ; "かけなおして　ください"
	next "calling again" ; "くわしくは　とりあつかい"
	next "later." ; "せつめいしょを　ごらんください"
	db   "@" 

String_17faf9:
	db   "The email address" ; "あてさき　メールアドレスに"
	next "is incorrect." ; "まちがいがあります"
	next "Please re-enter" ; "ただしい　メールアドレスを"
	next "the email" ; "いれなおしてください"
	next "address." 
	db   "@" 

String_17fb2a:
	db   "Your email address" ; "メールアドレスに"
	next "is incorrect." ; "まちがいが　あります"
	next "Please check the" ; "とりあつかいせつめいしょを"
	next "manual and" ; "ごらんのうえ"
	next "register using" ; "モバイルトレーナーで"
	next "Mobile Trainer." 
	db   "@" 

String_17fb6e:
	db   "Incorrect Log-in" ; "ログインパスワードに"
	next "Password or" ; "まちがいが　あるか"
	next "Mobile Center" ; "モバイルセンターの　エラーです"
	next "error." ; "パスワードを　かくにんして"
	next "Please try again" ; "しばらく　まって"
	next "later." ; "かけなおして　ください"
	db   "@" 

String_17fbb6:
	db   "Unable to read" ; "データの　よみこみが　できません"
	next "the data." ; "しばらくまって"
	next "Please try again." ; "かけなおして　ください"
	next "If the problem" ; "なおらない　ときは"
	next "persists, please" ; "モバイルサポートセンターへ"
	next "contact support." ; "おといあわせください"
	db   "@" 
	
String_17fbfe:
	db   "Time's up!" ; "じかんぎれです"
	next "The call has" ; "でんわが　きれました"
	next "ended." ; "でんわを　かけなおしてください"
	next "Please check the" ; "くわしくは　とりあつかい"
	next "manual and try" ; "せつめいしょを　ごらんください"
	next "again later"
	db   "@" 

String_17fc3e:
	db   "The service is" ; "おきゃくさまの　ごつごうにより"
	next "unavailable due to" ; "ごりようできません"
	next "a missed payment." ; "ごりようが　できなくなります"
	next "Please check the" ; "くわしくは　とりあつかい"
	next "manual." ; "せつめいしょを　ごらんください"
	db   "@" 

String_17fc88:
	db   "The service is" ; "おきゃくさまの　ごつごうにより"
	next "unavailable at" ; "ごりようできません"
	next "this time." ; "くわしくは　とりあつかい"
	next "Please check the" ; "せつめいしょを　ごらんください"
	next "manual." 
	db   "@" 

String_17fcbf:
	db   "There was an error" ; "でんわかいせんが　こんでいるか"
	next "with the phone or" ; "モバイルセンターの　エラーで"
	next "the Mobile Center." ; "つうしんが　できません"
	next "Please try again" ; "しばらく　まって"
	next "later." ; "かけなおして　ください"
	db   "@" 

String_17fcff:
	db   "You have reached" ; "ごりよう　りょうきんが"
	next "the monthly" ; "じょうげんを　こえているため"
	next "spending limit." ; "こんげつは　ごりようできません"
	next "Please check the" ; "くわしくは　とりあつかい"
	next "manual for" ; "せつめいしょを　ごらんください"
	next "details." 
	db   "@" 

String_17fd47:
	db   "The Mobile Center" ; "げんざい　モバイルセンターの"
	next "is undergoing" ; "てんけんを　しているので"
	next "maintenance." ; "つうしんが　できません"
	next "Please try again" ; "しばらく　まって"
	next "later." ; "かけなおして　ください"
	db   "@" 
	
String_17fd84:
	db   "Unable to read" ; "データの　よみこみが　できません"
	next "the data." ; くわしくは　とりあつかい
	next "Please check the" ; "せつめいしょを　ごらんください"
	next "manual for" 
	next "details." 
	db   "@" 

String_17fdb2:
	db   "The call was" ; "３ぷん　いじょう　なにも"
	next "ended due to" ; "にゅうりょく　しなかったので"
	next "no input being" ; "でんわが　きれました"
	next "received for " 
	next "three minutes." 
	db   "@"

String_17fdd9:
	db   "Communication" ; "つうしんが　うまく"
	next "failed." ; "できませんでした"
	next "Please start" ; "もういちど　はじめから"
	next "over and try" ; "やりなおしてください"
	next "again." 
	db   "@" 

String_17fe03:
	db   "Unable to read" ; "データの　よみこみが　できません"
	next "the data." ; "しばらくまって"
	next "Please try again." ; "かけなおして　ください"
	next "If the problem" ; "なおらない　ときは"
	next "persists, please" ; "モバイルサポートセンターへ"
	next "contact support." ; "おといあわせください"
	db   "@" 

String_17fe4b:
    db   "The call was" ; "まちじかんが　ながいので"
    next "ended because" ; "でんわが　きれました"
    next "of inactivity." 
    db   "@"

String_17fe63:
	db   "Your friend is" ; "あいての　モバイルアダプタと"
	next "using a different" ; "タイプが　ちがいます"
	next "kind of" ; "くわしくは　とりあつかい"
	next "Mobile Adapter." ; "せつめいしょを　ごらんください"
	next "Check the manual" 
	next "for details." 
	db   "@" 

String_17fe9a: ; unused
	db   "The #MON NEWS" ; "ポケモンニュースが"
	next "was updated." ; "あたらしくなっているので"
	next "Please download" ; "レポートを　おくれません"
	next "the latest NEWS" ; "あたらしい　ポケモンニュースの"
	next "before updating" ; "よみこみを　さきに　してください"
	next "the rankings." 
	db   "@" 

String_17fedf:
	db   "The signal is poor" ; "つうしんの　じょうきょうが"
	next "or the number is" ; "よくないか　かけるあいてが"
	next "incorrect." ; "まちがっています"
	next "Please try again" ; "もういちど　かくにんをして"
	next "later." ; "でんわを　かけなおして　ください"
	db   "@" 

Function17ff23:
	ldh a, [hJoyPressed]
	and a
	ret z
	ld a, $8
	ld [wMusicFade], a
	ld a, [wMapMusic]
	ld [wMusicFadeID], a
	xor a
	ld [wMusicFadeID + 1], a
	ld hl, wc303
	set 7, [hl]
	ret

Function17ff3c:
	nop
	ld a, [wMobileErrorCodeBuffer]
	cp $d0
	ret c
	hlcoord 10, 2
	ld de, String_17ff68
	call PlaceString
	ld a, [wMobileErrorCodeBuffer]
	push af
	sub $d0
	inc a
	ld [wMobileErrorCodeBuffer], a
	hlcoord 14, 2
	ld de, wMobileErrorCodeBuffer
	lb bc, PRINTNUM_LEADINGZEROS | 1, 3
	call PrintNum
	pop af
	ld [wMobileErrorCodeBuffer], a
	and a
	ret

String_17ff68:
	db "１０１@"
