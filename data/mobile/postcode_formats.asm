if DEF(_CRYSTAL_AU) ; AU build
Zipcode_CharPool_Formats:
	dw Zipcode_CharPools_Format0
;________________________________
Zipcode_CharPools_Format0:         ; 0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9








elif DEF(_CRYSTAL_EU) ; EU build
Zipcode_CharPool_Formats:
	dw Zipcode_CharPools_Format0
	dw Zipcode_CharPools_Format1
	dw Zipcode_CharPools_Format2
	dw Zipcode_CharPools_Format3
	dw Zipcode_CharPools_Format4
	dw Zipcode_CharPools_Format5
	dw Zipcode_CharPools_Format6
	dw Zipcode_CharPools_Format7
	dw Zipcode_CharPools_Format8
	dw Zipcode_CharPools_Format9
	dw Zipcode_CharPools_Format10
	dw Zipcode_CharPools_Format11
	dw Zipcode_CharPools_Format12
	dw Zipcode_CharPools_Format13
	dw Zipcode_CharPools_Format14
	dw Zipcode_CharPools_Format15
;________________________________
Zipcode_CharPools_Format0:         ; -     -     -
	db CHARPOOL_DASH
	db CHARPOOL_DASH
	db CHARPOOL_DASH

Zipcode_CharPools_Format9:         ; A-Z   A-Z   A-Z   0-9   0-9
	db CHARPOOL_A_TO_Z
	db CHARPOOL_A_TO_Z
	db CHARPOOL_A_TO_Z
	db CHARPOOL_BLANK
Zipcode_CharPools_Format5:         ; 0-9   0-9   0-9   0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_DASH
Zipcode_CharPools_Format4:         ; 0-9   0-9   0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
Zipcode_CharPools_Format3:         ; 0-9   0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
Zipcode_CharPools_Format6:         ; 0-9   0-9   0-9   0-9   A-Z   A-Z
Zipcode_CharPools_Format2:         ; 0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
Zipcode_CharPools_Format1:         ; 0-9   0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_A_TO_Z
Zipcode_CharPools_Format7:         ; A-Z   0-9   0-Z   0-Z   0-Z   0-Z   0-Z
	db CHARPOOL_A_TO_Z
	db CHARPOOL_0_TO_9
	db CHARPOOL_A_TO_9
	db CHARPOOL_BLANK
	db CHARPOOL_A_TO_9
	db CHARPOOL_A_TO_9
	db CHARPOOL_A_TO_9
	db CHARPOOL_A_TO_9

Zipcode_CharPools_Format8:         ; A-Z   0-Z   0-Z   0-Z   0-Z   A-Z_Blank   A-Z+Blank
	db CHARPOOL_A_TO_Z
	db CHARPOOL_A_TO_9
	db CHARPOOL_A_TO_9_BLANK
	db CHARPOOL_A_TO_9_BLANK
	db CHARPOOL_BLANK
	db CHARPOOL_A_TO_9
	db CHARPOOL_A_TO_Z
	db CHARPOOL_A_TO_Z

Zipcode_CharPools_Format10:        ; L     V     0-9   0-9   0-9   0-9
	db CHARPOOL_L
	db CHARPOOL_V
	db CHARPOOL_DASH
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9

Zipcode_CharPools_Format11:        ; M     D     0-9   0-9   0-9   0-9
	db CHARPOOL_M
	db CHARPOOL_D
	db CHARPOOL_DASH
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9

Zipcode_CharPools_Format12:        ; S     I     0-9   0-9   0-9   0-9
	db CHARPOOL_S
	db CHARPOOL_I
	db CHARPOOL_DASH
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	
Zipcode_CharPools_Format13:        ; 4     7     8   9   0-9
	db CHARPOOL_4
	db CHARPOOL_7
	db CHARPOOL_8
	db CHARPOOL_9
	db CHARPOOL_0_TO_9
Zipcode_CharPools_Format14:         ; 0-9   0-9   0-9         0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_DASH

Zipcode_CharPools_Format15:         ; 0-9   0-9   0-9         0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_BLANK
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9


else ; US build
Zipcode_CharPool_Formats:
	dw Zipcode_CharPools_Format0
	dw Zipcode_CharPools_Format1
;________________________________
Zipcode_CharPools_Format1:          ; A-Z   0-9   A-Z   0-9   A-Z   0-9
	db CHARPOOL_A_TO_Z
	db CHARPOOL_0_TO_9
	db CHARPOOL_A_TO_Z
	db CHARPOOL_BLANK
	db CHARPOOL_0_TO_9
	db CHARPOOL_A_TO_Z
Zipcode_CharPools_Format0:          ; 0-9   0-9   0-9   0-9   0-9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
	db CHARPOOL_0_TO_9
endc