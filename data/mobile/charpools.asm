	const_def
	const CHARPOOL_0_TO_9
	const CHARPOOL_A_TO_Z
	const CHARPOOL_A_TO_9
	const CHARPOOL_L
	const CHARPOOL_V
	const CHARPOOL_M
	const CHARPOOL_D
	const CHARPOOL_S
	const CHARPOOL_I
	const CHARPOOL_4
	const CHARPOOL_7
	const CHARPOOL_8
	const CHARPOOL_9
	const CHARPOOL_A_TO_Z_2
	const CHARPOOL_A_TO_Z_BLANK	
	const CHARPOOL_BLANK
	const CHARPOOL_DASH



Zipcode_CharPools:
	; address of the charpool,       char pool length in bytes
	dwb Zipcode_CharPool_0to9,       10 ; CHARPOOL_0_TO_9
	dwb Zipcode_CharPool_AtoZ,       26 ; CHARPOOL_A_TO_Z
	dwb Zipcode_CharPool_Ato9,       36 ; CHARPOOL_A_TO_9
	dwb Zipcode_CharPool_L,           1 ; CHARPOOL_L
	dwb Zipcode_CharPool_V,           1 ; CHARPOOL_V
	dwb Zipcode_CharPool_M,           1 ; CHARPOOL_M
	dwb Zipcode_CharPool_D,           1 ; CHARPOOL_D
	dwb Zipcode_CharPool_S,           1 ; CHARPOOL_S
	dwb Zipcode_CharPool_I,           1 ; CHARPOOL_I
	dwb Zipcode_CharPool_4,           1 ; CHARPOOL_4
	dwb Zipcode_CharPool_7,           1 ; CHARPOOL_7
	dwb Zipcode_CharPool_8,           1 ; CHARPOOL_8
	dwb Zipcode_CharPool_9,           1 ; CHARPOOL_9
	dwb Zipcode_CharPool_AtoZ_2,     26 ; CHARPOOL_A_TO_Z_2
	dwb Zipcode_CharPool_AtoZ_Blank, 27 ; CHARPOOL_BLANK_A_TO_Z
	dwb Zipcode_CharPool_Blank,       1 ; CHARPOOL_BLANK
	dwb Zipcode_CharPool_Dash,        1 ; CHARPOOL_DASH

Zipcode_CharPool_Ato9:
Zipcode_CharPool_AtoZ:
	db "ABC"
Zipcode_CharPool_D:
	db "DEFGH"
Zipcode_CharPool_I:
	db "IJK"
Zipcode_CharPool_L:
	db "L"
Zipcode_CharPool_M:
	db "MNOPQR"
Zipcode_CharPool_S:
	db "STU"
Zipcode_CharPool_V:
	db "VWXYZ"
Zipcode_CharPool_0to9:
	db "0123"
Zipcode_CharPool_4:
	db "456"
Zipcode_CharPool_7:
	db "7"
Zipcode_CharPool_8:
	db "8"
Zipcode_CharPool_9:
	db "9"
Zipcode_CharPool_AtoZ_Blank:
Zipcode_CharPool_AtoZ_2:
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZ"	
Zipcode_CharPool_Blank:
	db " "	
Zipcode_CharPool_Dash:
	db "-"