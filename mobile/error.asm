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
	farcall HDMATransferAttrMapAndTileMapToWRAMBank3
	jr .loop

.quit
	call .deinit
	ret

.deinit
	ld a, [wc300]
	cp $22
	jr z, .asm_17f597
	cp $31
	jr z, .asm_17f58a
	cp $33
	ret nz
	ld a, [wc301]
	cp $1
	ret nz
	ld a, [wc302]
	cp $2
	ret nz
	jr .asm_17f5a1

.asm_17f58a
	ld a, [wc301]
	cp $3
	ret nz
	ld a, [wc302]
	and a
	ret nz
	jr .asm_17f5a1

.asm_17f597
	ld a, [wc301]
	and a
	ret nz
	ld a, [wc302]
	and a
	ret nz

.asm_17f5a1
	ld a, BANK(sMobileLoginPassword)
	call GetSRAMBank
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
	farcall HDMATransferAttrMapAndTileMapToWRAMBank3
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
	hlcoord 0, 0, wAttrMap
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
	ld a, [wc300]
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
	ld a, [wc301]
	ld e, a
	ld a, [wc302]
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
	ld a, [wc300]
	call .bcd_two_digits
	inc hl
	ld a, [wc302]
	and $f
	call .bcd_digit
	ld a, [wc301]
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
	db   "Unknown Error" 	; "みていぎ<NO>エラーです"
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
	db   "The MOBILE ADAPTER" 	; "モバイルアダプタが　ただしく"
	next "is not connected" 	; "さしこまれていません"
	next "properly. Please" 	; "とりあつかいせつめいしょを"
	next "refer to the" 		; "ごらんのうえ　しっかりと"
	next "instruction" 			; "さしこんで　ください"
	next "manual."
	db   "@"

String_17f8d1:
	db   "Couldn't communi-" 	; "でんわが　うまく　かけられないか" ; longer than below?
	next "cate because the" 	; "でんわかいせんが　こんでいるので"
	next "line is busy." 		; "つうしん　できません"
	next "Please try again" 	; "しばらく　まって"
	next "later." 				; "かけなおして　ください"
	db   "@"

String_17f913:
	db   "Couldn't communi-" 	; "でんわかいせんが　こんでいるため"
	next "cate because the" 	; "でんわが　かけられません"
	next "line is busy." 		; "しばらく　まって"
	next "Please try again" 	; "かけなおして　ください"
	next "later."
	db   "@"

String_17f946:
	db   "MOBILE ADAPTER" 		; "モバイルアダプタの　エラーです"
	next "error. Please try" 	; "しばらく　まって"
	next "again later. If" 		; "かけなおして　ください"
	next "the problem per-" 	; "なおらない　ときは"
	next "sists, contact the" 	; "モバイルサポートセンターへ"
	next "Support Center." 		; "おといあわせください"
	db   "@"

String_17f98e:
	db   "Communication" 		; "つうしんエラーです"
	next "error. Please try" 	; "しばらく　まって"
	next "again later. If" 		; "かけなおして　ください"
	next "the problem per-" 	; "なおらない　ときは"
	next "sists, contact the" 	; "モバイルサポートセンターへ"
	next "support center." 		; "おといあわせください"
	db   "@"

String_17f9d0:
	db   "Invalid LOG-IN" 		; "ログインパスワードか"
	next "PASSWORD or LOG-" 	; "ログイン　アイディーに"
	next "IN-ID. Please" 		; "まちがいがあります"
	next "change your PASS-" 	; "パスワードを　かくにんして"
	next "WORD and try" 		; "しばらく　まって"
	next "again later." 		; "かけなおして　ください"
	db   "@"

String_17fa14:
	db   "The phone was" 		; "でんわが　きれました"
	next "disconnected." 		; "とりあつかいせつめいしょを"
	next "Please refer to" 		; "ごらんのうえ"
	next "the instruction" 		; "しばらく　まって"
	next "manual and try" 		; "かけなおして　ください"
	next "again later."
	db   "@"

String_17fa49:
	db   "Error communica-" 	; "モバイルセンターの"
	next "ting with the" 		; "つうしんエラーです"
	next "MOBILE CENTER." 		; "しばらくまって"
	next "Please try" 			; "かけなおして　ください"
	next "again later."
	db   "@"

String_17fa71:
	db   "The MOBILE ADAPTER" 	; "モバイルアダプタに"
	next "is not configured" 	; "とうろくされた　じょうほうが"
	next "properly. Please" 	; "ただしく　ありません"
	next "configure it using" 	; "モバイルトレーナーで"
	next "MOBILE TRAINER." 		; "しょきとうろくを　してください"
	db   "@"

String_17fab0:
	db   "The MOBILE CENTER" 	; "モバイルセンターが"
	next "is busy. Please" 		; "こんでいて　つながりません"
	next "try again later." 	; "しばらくまって"
	next "For details," 		; "かけなおして　ください"
	next "see the instruc-" 	; "くわしくは　とりあつかい"
	next "tion manual." 		; "せつめいしょを　ごらんください"
	db   "@"

String_17faf9:
	db   "The email address" 	; "あてさき　メールアドレスに" ; ???
	next "is incorrect." 		; "まちがいがあります"
	next "Please change" 		; "ただしい　メールアドレスを"
	next "your email" 			; "いれなおしてください"
	next "address."
	db   "@"

String_17fb2a:
	db   "There is an error" 	; "メールアドレスに"
	next "in your email" 		; "まちがいが　あります"
	next "address." 			; "とりあつかいせつめいしょを"
	next "Please confirm it" 	; "ごらんのうえ"
	next "using MOBILE" 		; "モバイルトレーナーで"
	next "TRAINER." 			; "しょきとうろくを　してください"
	db   "@"

String_17fb6e:
	db   "Incorrect LOG-IN" 	; "ログインパスワードに"
	next "PASSWORD or MOBILE" 	; "まちがいが　あるか"
	next "CENTER error." 		; "モバイルセンターの　エラーです"
	next "Please try again" 	; "パスワードを　かくにんして"
	next "later." 				; "しばらく　まって"
	;next						; "かけなおして　ください"
	db   "@"

String_17fbb6:
	db   "Communication" 		; "データの　よみこみが　できません"
	next "error. Please try" 	; "しばらくまって"
	next "again later. If" 		; "かけなおして　ください"
	next "the problem per-" 	; "なおらない　ときは"
	next "sists, contact the" 	; "モバイルサポートセンターへ"
	next "support center." 		; "おといあわせください"
	db   "@"

String_17fbfe:
	db   "Time is up, the" 		; "じかんぎれです" ; ???
	next "call ended." 			; "でんわが　きれました"
	next "Refer to the" 		; "でんわを　かけなおしてください"
	next "instruction manual" 	; "くわしくは　とりあつかい"
	next "for details." 		; "せつめいしょを　ごらんください"
	db   "@"

String_17fc3e:
	db   "Payment has not"		; "ごりよう　りょうきんの　"
	next "been processed."		; "おしはらいが　おくれたばあいには"
	next "The service is"		; "ごりようが　できなくなります"
	next "unavailable."			; "くわしくは　とりあつかい"
	next "See instructions"		; "せつめいしょを　ごらんください"
	db   "@"

String_17fc88:
	db   "The service is"		; "おきゃくさまの　ごつごうにより"
	next "unavailable at"		; "ごりようできません"
	next "this time."			; "くわしくは　とりあつかい"
	next "See instructions"		; "せつめいしょを　ごらんください"
	next "for more details."
	db   "@"

String_17fcbf:
	db   "There was an error" 	; "でんわかいせんが　こんでいるか"
	next "with the phone or" 	; "モバイルセンターの　エラーで"
	next "the MOBILE CENTER." 	; "つうしんが　できません"
	next "Please try again" 	; "しばらく　まって"
	next "later." 				; "かけなおして　ください"
	db   "@"

String_17fcff:
	db   "The spending limit" 	; "ごりよう　りょうきんが"
	next "for this month "		; "じょうげんを　こえているため"
	next "has been reached."	; "こんげつは　ごりようできません"
	next "Refer to instruct-"	; "くわしくは　とりあつかい"
	next "ions for details." 	; "せつめいしょを　ごらんください"
	db   "@"

String_17fd47:
	db   "The MOBILE CENTER" 	; "げんざい　モバイルセンターの" ; ???
	next "is undergoing" 		; "てんけんを　しているので"
	next "maintenance." 		; "つうしんが　できません"
	next "Please try again" 	; "しばらく　まって"
	next "later." 				; "かけなおして　ください"
	db   "@"

String_17fd84:
	db   "Communication" 		; "データの　よみこみが　できません"
	next "error." 				; "くわしくは　とりあつかい"
	next "See the instruc-" 	; "せつめいしょを　ごらんください"
	next "tion manual for"
	next "details."
	db   "@"

String_17fdb2:
	db   "Hung up the phone" 	; "３ぷん　いじょう　なにも"
	next "because there was" 	; "にゅうりょく　しなかったので"
	next "no input for 3" 		; "でんわが　きれました"
	next "minutes."
	db   "@"

String_17fdd9:
	db   "Communication" 		; "つうしんが　うまく"
	next "failed." 				; "できませんでした"
	next "Please try" 			; "もういちど　はじめから"
	next "again." 				; "やりなおしてください"
	db   "@"

String_17fe03:
	db   "Communication" 		; "データの　よみこみが　できません" ; duplicate?
	next "error. Please try" 	; "しばらくまって"
	next "again later. If" 		; "かけなおして　ください"
	next "the problem per-" 	; "なおらない　ときは"
	next "sists, contact the" 	; "モバイルサポートセンターへ"
	next "support center." 		; "おといあわせください"
	db   "@"

String_17fe4b:
	db   "Due to the long" 		; "まちじかんが　ながいので"
	next "waiting time, the" 	; "でんわが　きれました"
	next "phone was hung up."
	db   "@"

String_17fe63:
	db   "The types of" 		; "あいての　モバイルアダプタと"
	next "MOBILE ADAPTERS" 		; "タイプが　ちがいます"
	next "used differ." 		; "くわしくは　とりあつかい"
	next "See the instruc-" 	; "せつめいしょを　ごらんください"
	next "tion manual for"
	next "details."
	db   "@"

String_17fe9a: ; unused
	db   "The #MON NEWS" 		; "ポケモンニュースが"
	next "were updated." 		; "あたらしくなっているので"
	next "Please load the" 		; "レポートを　おくれません"
	next "new NEWS before" 		; "あたらしい　ポケモンニュースの"
	next "updating the" 		; "よみこみを　さきに　してください"
	next "RANKINGS."
	db   "@"

String_17fedf:
	db   "Unable to connect." 	; "つうしんの　じょうきょうが"
	next "The signal is poor" 	; "よくないか　かけるあいてが"
	next "or the number is"		; "まちがっています"
	next "not recognized."		; "もういちど　かくにんをして"
	next "Please try again."	; "でんわを　かけなおして　ください"
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
	ld a, [wc300]
	cp $d0
	ret c
	hlcoord 10, 2
	ld de, String_17ff68
	call PlaceString
	ld a, [wc300]
	push af
	sub $d0
	inc a
	ld [wc300], a
	hlcoord 14, 2
	ld de, wc300
	lb bc, PRINTNUM_LEADINGZEROS | 1, 3
	call PrintNum
	pop af
	ld [wc300], a
	and a
	ret

String_17ff68:
	db "１０１@"
