; Input: DE = the memory address were the string should be written. Also, wPrefecture should be set to the prefecture of the user.
; Output: it edits the bytes pointed by DE.
WriteCurrencyName::
	call DetermineCurrencyName
	call CopyCurrencyString
	ret

; Input: none. wPrefecture should be set to the prefecture of the user.
; Output: HL = the address of the string to use for the currency.
DetermineCurrencyName:
if DEF(_CRYSTAL_EU) 
	; EU region.
	ld a, [wPrefecture] ; Loads the Prefectures index (starts at 0) selected by the player. The Prefectures list is stored into mobile_12.asm
	dec a ; Beware: it the value is 0, dec will underflow and default to the default value

	ld hl, String_Currency_Lek
	cp 1 ; "EU-AL@"     ; Albania
	ret z

	ld hl, String_Currency_Fening
	cp 3  ; "EU-BA@"     ; Bosnia and Herzegovina
	ret z	

	ld hl, String_Currency_Stotinki
	cp 5  ; "EU-BG@"     ; Bulgaria
	ret z	

	ld hl, String_Currency_Copecks
	cp 6  ; "EU-BY@"     ; Belarus
	ret z	
	cp 22  ; "EU-LI@"     ; Liechtenstein
	ret z	

	ld hl, String_Currency_Rappen
	cp 7  ; "EU-CH@"     ; Switzerland
	ret z		

	ld hl, String_Currency_Crowns
	cp 8  ; "EU-CZ@"     ; Czech Republic
	ret z	

	ld hl, String_Currency_Ore
	cp 10  ; "EU-DK@"     ; Denmark
	ret z		
	cp 29  ; "EU-NO@"     ; Norway
	ret z

	ld hl, String_Currency_Krooni
	cp 11  ; "EU-EE@"     ; Estonia
	ret z			

	ld hl, String_Currency_Lp
	cp 17  ; "EU-HR@"     ; Croatia
	ret z		

	ld hl, String_Currency_Filler
	cp 18  ; "EU-HU@"     ; Hungary
	ret z	

	ld hl, String_Currency_Pence
	cp 15 ; "EU-GB@"     ; United Kingdom
	ret z
	cp 19 ; "EU-IE@"     ; Ireland
	ret z		

	ld hl, String_Currency_Kronur
	cp 20 ; "EU-IS@"     ; Iceland
	ret z

	ld hl, String_Currency_Centai
	cp 23  ; "EU-LT@"     ; Lithuania
	ret z		

	ld hl, String_Currency_Santimi
	cp 25  ; "EU-LV@"     ; Lavia
	ret z

	ld hl, String_Currency_Lei
	cp 26  ; "EU-MD@"     ; Moldova
	ret z	

	ld hl, String_Currency_Liri
	cp 27  ; "EU-MT@"     ; Malta
	ret z		

	ld hl, String_Currency_Groszy
	cp 30  ; "EU-PL@"     ; Poland
	ret z		

	ld hl, String_Currency_Bani
	cp 32  ; "EU-RO@"     ; Romania
	ret z		

	ld hl, String_Currency_Dinari
	cp 33 ; "EU-RS@"     ; Serbia
	ret z	

	ld hl, String_Currency_Rubles
	cp 34 ; "EU-RU@"     ; Russia
	ret z	

	ld hl, String_Currency_Kronor
	cp 35 ; "EU-SE@"     ; Sweden
	ret z	

	ld hl, String_Currency_Tolars
	cp 36 ; "EU-SI@"     ; Slovenia
	ret z	
	
	ld hl, String_Currency_Haliers
	cp 37 ; "EU-SK@"     ; Slovakia
	ret z		
	
	ld hl, String_Currency_Kopikyk
	cp 39 ; "EU-UA@"     ; Ukraine
	ret z		

	ld hl, String_Currency_Cents ; Default case. Anything that uses Cents doesn't need to be added into this check list.
else
	; AU and US regions. Cents in all cases.
	ld hl, String_Currency_Cents
endc
	ret

; Input: HL = the address to copy from.
; Output: DE = the address to copy into.
; Stops the copy when the EOL char is found ($50 or '@').
CopyCurrencyString: ; I know this is ugly, I copied and pasted this function from mobile_46.asm
.loop
	ld a, [hli]
	cp $50
	ret z
	ld [de], a
	inc de
	jr .loop



String_Currency_Cents: ; Note that this is unoptimized, as the string "Is this OK?@" is repeted.
	db   " cents";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"
	
String_Currency_Lek: ; Note that this is unoptimized, as the string "Is this OK?@" is repeted.
	db   " lek";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Fening:
	db   " fening";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	

String_Currency_Stotinki:
	db   " st.";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Copecks:
	db   " copecks";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Rappen:
	db   " rappen";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	

String_Currency_Crowns:
	db   " crowns";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Ore:
	db   " öre";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Krooni:
	db   " krooni";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Kronur:
	db   " kronur";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	

String_Currency_Pence:
	db   " pence";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"
	
String_Currency_Lp:
	db   " lp";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Filler:
	db   " fillér";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"

String_Currency_Centai:
	db   " centai";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Santimi:
	db   " santimi";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Lei:
	db   " lei";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Liri:
	db   " liri";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Groszy:
	db   " groszy";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Bani:
	db   " bani";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"		

String_Currency_Dinari:
	db   " dinari";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"
	
String_Currency_Rubles:
	db   " rubles";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"
	
String_Currency_Kronor:
	db   " kronor";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Tolars:
	db   " tolars";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"	
	
String_Currency_Haliers:
	db   " haliers";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"

String_Currency_Kopikyk:
	db   " kopikyk";"えん"
	next "Is this OK?@";"かかります　よろしい　ですか？@"		
	