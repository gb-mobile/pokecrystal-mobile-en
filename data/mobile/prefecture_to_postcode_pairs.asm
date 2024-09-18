if DEF(_CRYSTAL_AU) ; AU build.
PrefectureZipcodeFormat:
	db 0 ; AU-NSW
	db 0 ; AU-QLD
	db 0 ; AU-SA
	db 0 ; AU-TAS
	db 0 ; AU-VIC
	db 0 ; AU-WA
	db 0 ; AU-ACT
	db 0 ; AU-NT
	db 0 ; NZ-AUK
	db 0 ; NZ-BOP
	db 0 ; NZ-CAN
	db 0 ; NZ-CIT
	db 0 ; NZ-GIS
	db 0 ; NZ-WGN
	db 0 ; NZ-HKB
	db 0 ; NZ-MWT
	db 0 ; NZ-MBH
	db 0 ; NZ-NSN
	db 0 ; NZ-NTL
	db 0 ; NZ-OTA
	db 0 ; NZ-STL
	db 0 ; NZ-TKI
	db 0 ; NZ-TAS
	db 0 ; NZ-WKO
	db 0 ; NZ-WTC

ZipcodeFormatLengths:
	db 4 ;  0:   0-9   0-9   0-9   0-9







elif DEF(_CRYSTAL_EU) ; EU build.
PrefectureZipcodeFormat:
	db 0  ; EU-AD
	db 2  ; EU-AL
	db 2  ; EU-AT
	db 3  ; EU-BA
	db 2  ; EU-BE
	db 2  ; EU-BG
	db 4  ; EU-BY
	db 2  ; EU-CH
	db 3  ; EU-CZ
	db 3  ; EU-DE
	db 2  ; EU-DK
	db 3  ; EU-EE
	db 3  ; EU-ES
	db 3  ; EU-FI
	db 3  ; EU-FR
	db 8  ; EU-GB
	db 3  ; EU-GR
	db 3  ; EU-HR
	db 2  ; EU-HU
	db 7  ; EU-IE
	db 1  ; EU-IS
	db 3  ; EU-IT
	db 2  ; EU-LI
	db 2  ; EU-LT
	db 2  ; EU-LU
	db 10 ; EU-LV
	db 11 ; EU-MD
	db 9  ; EU-MT
	db 6  ; EU-NL
	db 2  ; EU-NO
	db 14 ; EU-PL
	db 5  ; EU-PT
	db 4  ; EU-RO
	db 3  ; EU-RS
	db 4  ; EU-RU
	db 15 ; EU-SE
	db 12 ; EU-SI
	db 3  ; EU-SK
	db 13 ; EU-SM
	db 3  ; EU-UA

ZipcodeFormatLengths:
	db 3 ;  0:   -     -     -
	db 3 ;  1:   0-9   0-9   0-9
	db 4 ;  2:   0-9   0-9   0-9   0-9
	db 5 ;  3:   0-9   0-9   0-9   0-9   0-9
	db 6 ;  4:   0-9   0-9   0-9   0-9   0-9   0-9
	db 8 ;  5:   0-9   0-9   0-9   0-9   0-9   0-9   0-9
	db 6 ;  6:   0-9   0-9   0-9   0-9   A-Z   A-Z
	db 8 ;  7:   A-Z   0-9         0-Z   0-Z   0-Z   0-Z   0-Z
	db 8 ;  8:   A-Z   0-Z   0-Z   0-Z   0-Z   Blank+A-Z   Blank+A-Z
	db 6 ;  9:   A-Z   A-Z   A-Z         0-9   0-9
	db 7 ; 10:   L     V     0-9   0-9   0-9   0-9
	db 7 ; 11:   M     D     0-9   0-9   0-9   0-9
	db 7 ; 12:   S     I     0-9   0-9   0-9   0-9
	db 5 ; 13:   4     7      8     9    0-9
	db 6 ; 14:   0-9   0-9    -    0-9   0-9   0-9
	db 6 ; 15:   0-9   0-9   0-9         0-9   0-9







else ; US build.
PrefectureZipcodeFormat:
	db 0 ; US-AL
	db 0 ; US-AK
	db 0 ; US-AZ
	db 0 ; US-AR
	db 0 ; US-CA
	db 0 ; US-CO
	db 0 ; US-CT
	db 0 ; US-DE
	db 0 ; US-FL
	db 0 ; US-GA
	db 0 ; US-HI
	db 0 ; US-ID
	db 0 ; US-IL
	db 0 ; US-IN
	db 0 ; US-IA
	db 0 ; US-KS
	db 0 ; US-KY
	db 0 ; US-LA
	db 0 ; US-ME
	db 0 ; US-MD
	db 0 ; US-MA
	db 0 ; US-MI
	db 0 ; US-MN
	db 0 ; US-MS
	db 0 ; US-MO
	db 0 ; US-MT
	db 0 ; US-NE
	db 0 ; US-NV
	db 0 ; US-NH
	db 0 ; US-NJ
	db 0 ; US-NM
	db 0 ; US-NY
	db 0 ; US-NC
	db 0 ; US-ND
	db 0 ; US-OH
	db 0 ; US-OK
	db 0 ; US-OR
	db 0 ; US-PA
	db 0 ; US-RI
	db 0 ; US-SC
	db 0 ; US-SD
	db 0 ; US-TN
	db 0 ; US-TX
	db 0 ; US-UT
	db 0 ; US-VT
	db 0 ; US-VA
	db 0 ; US-WA
	db 0 ; US-WV
	db 0 ; US-WI
	db 0 ; US-WY
	db 1 ; CA-AB
	db 1 ; CA-BC
	db 1 ; CA-MB
	db 1 ; CA-NB
	db 1 ; CA-NL
	db 1 ; CA-NS
	db 1 ; CA-ON
	db 1 ; CA-PE
	db 1 ; CA-QC
	db 1 ; CA-SK
	db 1 ; CA-NT
	db 1 ; CA-NU
	db 1 ; CA-YT

ZipcodeFormatLengths:
	db 5 ;  0:   0-9   0-9   0-9   0-9   0-9
	db 7 ;  1:   A-Z   0-9   A-Z         0-9   A-Z   0-9
endc