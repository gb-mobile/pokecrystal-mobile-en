if DEF(_CRYSTAL_AU) ; AU build.
PrefectureToCountry:
	db 0 ; AU-NSW
	db 0 ; AU-QLD
	db 0 ; AU-SA
	db 0 ; AU-TAS
	db 0 ; AU-VIC
	db 0 ; AU-WA
	db 0 ; AU-ACT
	db 0 ; AU-NT
	db 1 ; NZ-AUK
	db 1 ; NZ-BOP
	db 1 ; NZ-CAN
	db 1 ; NZ-CIT
	db 1 ; NZ-GIS
	db 1 ; NZ-WGN
	db 1 ; NZ-HKB
	db 1 ; NZ-MWT
	db 1 ; NZ-MBH
	db 1 ; NZ-NSN
	db 1 ; NZ-NTL
	db 1 ; NZ-OTA
	db 1 ; NZ-STL
	db 1 ; NZ-TKI
	db 1 ; NZ-TAS
	db 1 ; NZ-WKO
	db 1 ; NZ-WTC







elif DEF(_CRYSTAL_EU) ; EU build.
PrefectureToCountry:
	db  0 ; EU-AD
	db  1 ; EU-AL
	db  2 ; EU-AT
	db  3 ; EU-BA
	db  4 ; EU-BE
	db  5 ; EU-BG
	db  6 ; EU-BY
	db  7 ; EU-CH
	db  8 ; EU-CZ
	db  9 ; EU-DE
	db 10 ; EU-DK
	db 11 ; EU-EE
	db 12 ; EU-ES
	db 13 ; EU-FI
	db 14 ; EU-FR
	db 15 ; EU-GB
	db 16 ; EU-GR
	db 17 ; EU-HR
	db 18 ; EU-HU
	db 19 ; EU-IE
	db 20 ; EU-IS
	db 21 ; EU-IT
	db 22 ; EU-LI
	db 23 ; EU-LT
	db 24 ; EU-LU
	db 25 ; EU-LV
	db 26 ; EU-MD
	db 27 ; EU-MT
	db 28 ; EU-NL
	db 29 ; EU-NO
	db 30 ; EU-PL
	db 31 ; EU-PT
	db 32 ; EU-RO
	db 33 ; EU-RS
	db 34 ; EU-RU
	db 35 ; EU-SE
	db 36 ; EU-SI
	db 37 ; EU-SK
	db 38 ; EU-SM
	db 39 ; EU-UA







else ; US build.
PrefectureToCountry:
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
endc