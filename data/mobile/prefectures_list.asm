if DEF(_CRYSTAL_AU)
Prefectures: ; Quick and dirty solution for the margin offset. In this list, strings must be left-aligned.
	db "AU-ACT@"
	db "AU-NSW@"
	db "AU-NT @"
	db "AU-QLD@"
	db "AU-SA @"
	db "AU-TAS@"
	db "AU-VIC@"
	db "AU-WA @"
	db "NZ-AUK@"      ; Auckland
	db "NZ-BOP@"      ; Bay of Plenty
	db "NZ-CAN@"      ; Canterbury
	db "NZ-CIT@"      ; Chatham Islands Territory
	db "NZ-GIS@"      ; Gisborne
	db "NZ-WGN@"      ; Wellington	
	db "NZ-HKB@"      ; Hawke's Bay
	db "NZ-MWT@"      ; Manawatu-Wanganui	
	db "NZ-MBH@"      ; Marlborough
	db "NZ-NSN@"      ; Nelson
	db "NZ-NTL@"      ; Northland
	db "NZ-OTA@"      ; Otago
	db "NZ-STL@"      ; Southland
	db "NZ-TKI@"      ; Taranaki	
	db "NZ-TAS@"      ; Tasman
	db "NZ-WKO@"      ; Waikato
LastPrefecture: db "NZ-WTC@"      ; West Coast

elif DEF(_CRYSTAL_EU)
Prefectures:
	db "EU-AD@"     ; Andorra
	db "EU-AL@"     ; Albania
	db "EU-AT@"     ; Austria
	db "EU-BA@"     ; Bosnia and Herzegovina
	db "EU-BE@"     ; Belgium
	db "EU-BG@"     ; Bulgaria
	db "EU-BY@"     ; Belarus
	db "EU-CH@"     ; Switzerland
	db "EU-CZ@"     ; Czech Republic
	db "EU-DE@"     ; Germany
	db "EU-DK@"     ; Denmark
	db "EU-EE@"     ; Estonia
	db "EU-ES@"     ; Spain
	db "EU-FI@"     ; Finland
	db "EU-FR@"     ; France
	db "EU-GB@"     ; United Kingdom
	db "EU-GR@"     ; Greece
	db "EU-HR@"     ; Croatia
	db "EU-HU@"     ; Hungary
	db "EU-IE@"     ; Ireland
	db "EU-IS@"     ; Iceland
	db "EU-IT@"     ; Italy
	db "EU-LI@"     ; Liechtenstein
	db "EU-LT@"     ; Lithuania
	db "EU-LU@"     ; Luxembourg
	db "EU-LV@"     ; Latvia
	db "EU-MD@"     ; Moldova
	db "EU-MT@"     ; Malta
	db "EU-NL@"     ; Netherlands
	db "EU-NO@"     ; Norway
	db "EU-PL@"     ; Poland
	db "EU-PT@"     ; Portugal
	db "EU-RO@"     ; Romania
	db "EU-RS@"     ; Serbia
	db "EU-RU@"     ; Russian Federation
	db "EU-SE@"     ; Sweden
	db "EU-SI@"     ; Slovenia
	db "EU-SK@"     ; Slovakia
	db "EU-SM@"     ; San Marino
LastPrefecture: db "EU-UA@"     ; Ukraine
else
Prefectures:
	db	"US-AL@"  	;Alabama
	db	"US-AK@"  	;Alaska
	db	"US-AZ@"  	;Arizona
	db	"US-AR@"  	;Arkansas
	db	"US-CA@"  	;California
	db	"US-CO@"  	;Colorado
	db	"US-CT@"  	;Connecticut
	db	"US-DE@"  	;Delaware
	db	"US-FL@"  	;Florida
	db	"US-GA@"  	;Georgia
	db	"US-HI@"  	;Hawaii
	db	"US-ID@"  	;Idaho
	db	"US-IL@"  	;Illinois
	db	"US-IN@"  	;Indiana
	db	"US-IA@"  	;Iowa
	db	"US-KS@"  	;Kansas
	db	"US-KY@"  	;Kentucky
	db	"US-LA@"  	;Louisiana
	db	"US-ME@"  	;Maine
	db	"US-MD@"  	;Maryland
	db	"US-MA@"  	;Massachusetts
	db	"US-MI@"  	;Michigan
	db	"US-MN@"  	;Minnesota
	db	"US-MS@"  	;Mississippi
	db	"US-MO@"  	;Missouri
	db	"US-MT@"  	;Montana
	db	"US-NE@"  	;Nebraska
	db	"US-NV@"  	;Nevada
	db	"US-NH@"  	;New_Hampshire
	db	"US-NJ@"  	;New_Jersey
	db	"US-NM@"  	;New_Mexico
	db	"US-NY@"  	;New_York
	db	"US-NC@"  	;North_Carolina
	db	"US-ND@"  	;North_Dakota
	db	"US-OH@"  	;Ohio
	db	"US-OK@"  	;Oklahoma
	db	"US-OR@"  	;Oregon
	db	"US-PA@"  	;Pennsylvania
	db	"US-RI@"  	;Rhode_Island
	db	"US-SC@"  	;South_Carolina
	db	"US-SD@"  	;South_Dakota
	db	"US-TN@"  	;Tennessee
	db	"US-TX@"  	;Texas
	db	"US-UT@"  	;Utah
	db	"US-VT@"  	;Vermont
	db	"US-VA@"  	;Virginia
	db	"US-WA@"  	;Washington
	db	"US-WV@"  	;West_Virginia
	db	"US-WI@"  	;Wisconsin
	db	"US-WY@"  	;Wyoming
	db	"CA-AB@"
	db	"CA-BC@"
	db	"CA-MB@"
	db	"CA-NB@"
	db	"CA-NL@"
	db	"CA-NT@"
	db	"CA-NS@"
	db	"CA-NU@"
	db	"CA-ON@"
	db	"CA-PE@"
	db	"CA-QC@"
	db	"CA-SK@"
LastPrefecture: db	"CA-YT@"
endc