	object_const_def
	const GOLDENRODPOKECENTER1F_NURSE
	const GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST
	const GOLDENRODPOKECENTER1F_SUPER_NERD ; $04
	const GOLDENRODPOKECENTER1F_LASS2 ; $05
	const GOLDENRODPOKECENTER1F_YOUNGSTER
	const GOLDENRODPOKECENTER1F_TEACHER ; $07
	const GOLDENRODPOKECENTER1F_ROCKER ; $08
	const GOLDENRODPOKECENTER1F_GAMEBOY_KID
	const GOLDENRODPOKECENTER1F_GRAMPS ; $0A
	const GOLDENRODPOKECENTER1F_LASS
	const GOLDENRODPOKECENTER1F_POKEFAN_F

GoldenrodPokecenter1F_MapScripts:
	def_scene_scripts
	scene_script .Scene0, SCENE_GOLDENRODPOKECENTER1F_DEFAULT
	scene_script .Scene0, SCENE_GOLDENRODPOKECENTER1F_DEFAULT2

	def_callbacks
	callback MAPCALLBACK_OBJECTS, .prepareMap

.Scene0: ; stuff to handle the player turning his gb off without saving after a trade
	setval BATTLETOWERACTION_10 ; 5671d checks if a trade was made
	special BattleTowerAction
	iffalse .noTrade ; $2967
	prioritysjump scenejmp01 ; $6F68 received pokemon from trade corner dialogue
	end

.noTrade
	setval BATTLETOWERACTION_EGGTICKET ; check if player received the odd egg or still has the egg ticket
	special BattleTowerAction ; 5672b
	iffalse .notReceivedOddEgg ; $3467 still has egg ticket
	prioritysjump scenejmp02 ; $B568 received odd egg dialogue
.notReceivedOddEgg
	end

.prepareMap
	special CheckMobileAdapterStatusSpecial
	iftrue .mobile ; $5067
	moveobject GOLDENRODPOKECENTER1F_LASS2, 16, 9 ; this is 71 in jp crystal???
	moveobject GOLDENRODPOKECENTER1F_GRAMPS, 0, 7
	moveobject GOLDENRODPOKECENTER1F_SUPER_NERD, 8, 13
	moveobject GOLDENRODPOKECENTER1F_TEACHER, 27, 13
	moveobject GOLDENRODPOKECENTER1F_ROCKER, 21, 6
	return ; this is 8f in jp crystal
.mobile
	setevent EVENT_33F
	return

GoldenrodPokecenter1FNurseScript:
	setevent EVENT_WELCOMED_TO_POKECOM_CENTER
	jumpstd PokecenterNurseScript

GoldenrodPokecenter1FTradeCornerAttendantScript:
	special SetBitsForLinkTradeRequest
	opentext
	writetext GoldenrodPokecomCenterWelcomeToTradeCornerText ; $2d6a
	buttonsound ; 54 in jp crystal?
	checkitem EGG_TICKET ; 56762 in jp crystal
	iftrue PlayerHasEggTicket ; $7c68
	special Function11b879 ; check save file?
	ifequal $01, PokemonInTradeCorner ; $F667
	ifequal $02, LeftPokemonInTradeCornerRecently ; $6968
	readvar $01
	ifequal $01, .onlyHaveOnePokemon ; $CF67 ; 56772
	writetext GoldenrodPokecomCenterWeMustHoldYourMonText ; $726A
	yesorno
	iffalse PlayerCancelled ; $D567

	writetext GoldenrodPokecomCenterSaveBeforeTradeCornerText ; $756E
	yesorno
	iffalse PlayerCancelled ; $D567
	special TryQuickSave
	iffalse PlayerCancelled ; $D567
	writetext GoldenrodPokecomCenterWhichMonToTradeText ; $8F6E
	waitbutton ; 53 in jp crystal?
	special BillsGrandfather ; 56792
	ifequal $00, PlayerCancelled ; $D567
	ifequal $FD, CantAcceptEgg ; $EA67
	ifgreater $FB, PokemonAbnormal ; $F067
	special Function11ba38 ; check party pokemon fainted
	ifnotequal $00, CantTradeLastPokemon ; $E467
	writetext GoldenrodPokecomCenterWhatMonDoYouWantText ; $9E6A
	waitbutton
	special Function11ac3e
	ifequal $00, PlayerCancelled ; $D567
	ifequal $02, .tradePokemonNeverSeen ; $BB67
	writetext GoldenrodPokecomCenterWeWillTradeYourMonForMonText ; $B96A ; 567B5
	sjump  .tradePokemon ; $BE67
.tradePokemonNeverSeen
	writetext GoldenrodPokecomCenterWeWillTradeYourMonForNewText ; $1E6B
.tradePokemon
	special TradeCornerHoldMon ; create data to send?
	ifequal $0A, PlayerCancelled ; $D567
	ifnotequal $00, MobileError ; $DB67
	writetext GoldenrodPokecomCenterYourMonHasBeenReceivedText ; $A86B
	waitbutton
	closetext
	end

.onlyHaveOnePokemon
	writetext GoldenrodPokecomCenterYouHaveOnlyOneMonText ; $D76B
	waitbutton
	closetext
	end

PlayerCancelled:
	writetext GoldenrodPokecomCenterWeHopeToSeeYouAgainText ; $0F6C
	waitbutton
	closetext
	end

MobileError:
	special BattleTowerMobileError
	writetext GoldenrodPokecomCenterTradeCanceledText ; $AA6E
	waitbutton
	closetext
	end

CantTradeLastPokemon:
	writetext GoldenrodPokecomCenterCantAcceptLastMonText ; $2C6C
	waitbutton
	closetext
	end

CantAcceptEgg:
	writetext GoldenrodPokecomCenterCantAcceptEggText ; $516C
	waitbutton
	closetext
	end

PokemonAbnormal:
	writetext GoldenrodPokecomCenterCantAcceptAbnormalMonText ; $6F6C
	waitbutton
	closetext
	end

PokemonInTradeCorner:
	writetext GoldenrodPokecomCenterSaveBeforeTradeCornerText ; $756E
	yesorno
	iffalse PlayerCancelled ; $D567
	special TryQuickSave
	iffalse PlayerCancelled ; $D567 ; 56800
	writetext GoldenrodPokecomCenterAlreadyHoldingMonText ; $896C
	buttonsound
	readvar $01
	ifequal $06, PartyFull ; $3868
	writetext GoldenrodPokecomCenterCheckingTheRoomsText ; $A56C
	special Function11b5e8 ; connect
	ifequal $0A, PlayerCancelled ; $D567
	ifnotequal $00, MobileError ; $DB67
	setval $0F
	special BattleTowerAction
	ifequal $00, NoTradePartnerFound ; $3E68 ; 56820
	ifequal $01, .receivePokemon ; $2B68
	sjump PokemonInTradeCornerForALongTime ; $5668

.receivePokemon
	writetext GoldenrodPokecomCenterTradePartnerHasBeenFoundText ; $C46C
	buttonsound
	special Function11b7e5 ; receive a pokemon animation?
	writetext GoldenrodPokecomCenterItsYourNewPartnerText ; $E66C
	waitbutton
	closetext
	end

PartyFull:
	writetext GoldenrodPokecomCenterYourPartyIsFullText ; $216D ; 56838
	waitbutton
	closetext
	end

NoTradePartnerFound:
	writetext GoldenrodPokecomCenterNoTradePartnerFoundText ; $576D ; 5683E
	yesorno
	iffalse ContinueHoldingPokemon ; $6368
	special Function11b920 ; something with mobile
	ifequal $0A, PlayerCancelled ; $D567
	ifnotequal $00, MobileError ; $DB67
	writetext GoldenrodPokecomCenterReturnedYourMonText ; $8A6D
	waitbutton
	closetext
	end

PokemonInTradeCornerForALongTime:
	writetext GoldenrodPokecomCenterYourMonIsLonelyText ; $9A6D ; 56856
	buttonsound
	special Function11b93b ; something with mobile
	writetext GoldenrodPokecenter1FWeHopeToSeeYouAgainText_2 ; $016E
	waitbutton
	closetext
	end

ContinueHoldingPokemon:
	writetext GoldenrodPokecomCenterContinueToHoldYourMonText ; $176E ; 56863
	waitbutton
	closetext
	end

LeftPokemonInTradeCornerRecently:
	writetext GoldenrodPokecomCenterRecentlyLeftYourMonText ; $306E ; 56869
	waitbutton
	closetext
	end

scenejmp01: ; ???
	setscene $01 ; 5686F
	refreshscreen
	writetext GoldenrodPokecomCenterTradePartnerHasBeenFoundText ; $C46C
	buttonsound
	writetext GoldenrodPokecomCenterItsYourNewPartnerText ; $E66C
	waitbutton
	closetext
	end

PlayerHasEggTicket:
	writetext GoldenrodPokecomCenterEggTicketText ; $CD6E ; 5687C
	waitbutton
	readvar $01
	ifequal $06, PartyFull ; $3868
	writetext GoldenrodPokecomCenterOddEggBriefingText ; $106F
	waitbutton
	writetext GoldenrodPokecomCenterSaveBeforeTradeCornerText ; $756E
	yesorno
	iffalse PlayerCancelled ; $D567
	special TryQuickSave
	iffalse PlayerCancelled ; $D567
	writetext GoldenrodPokecomCenterPleaseWaitAMomentText ; $CC6F
	special GiveOddEgg
	ifequal $0B, .eggTicketExchangeNotRunning ; $AF68
	ifequal $0A, PlayerCancelled ; $D567
	ifnotequal $00, MobileError ; $DB67
.receivedOddEgg
	writetext GoldenrodPokecomCenterHereIsYourOddEggText ; $E66F
	waitbutton
	closetext
	end

.eggTicketExchangeNotRunning
	writetext GoldenrodPokecomCenterNoEggTicketServiceText ; $2270 ; 568AF
	waitbutton
	closetext
	end

scenejmp02: ; 568B5
	opentext
	sjump PlayerHasEggTicket.receivedOddEgg ; $A968

GoldenrodPokecenter1F_NewsMachineScript:
	special CheckMobileAdapterStatusSpecial ; 568B9
	iftrue .mobileEnabled ; $C268
	jumptext GoldenrodPokecomCenterNewsMachineNotYetText ; $1F76
.mobileEnabled
	opentext
	writetext GoldenrodPokecomCenterNewsMachineText ; $4D70
	buttonsound
	setval $14 ; (get battle tower save file flags if save is yours?)
	special BattleTowerAction
	ifnotequal $00, .skipExplanation ; $D968
	setval $15  ; (set battle tower save file flags?)
	special BattleTowerAction
	writetext GoldenrodPokecomCenterNewsMachineExplanationText ; $6370
	waitbutton
.skipExplanation
	writetext GoldenrodPokecomCenterSaveBeforeNewsMachineText ; $C371
	yesorno
	iffalse .cancel ; $FF68
	special TryQuickSave
	iffalse .cancel ; $FF68
	setval $15 ; (set battle tower save file flags?)
	special BattleTowerAction
.showMenu
	writetext GoldenrodPokecomCenterWhatToDoText ; $5970
	setval $00
	special Menu_ChallengeExplanationCancel ; show news machine menu
	ifequal $01, .getNews 		  ; $0869
	ifequal $02, .showNews 		  ; $1D69
	ifequal $03, .showExplanation ; $0169
.cancel
	closetext
	end

.showExplanation
	writetext GoldenrodPokecomCenterNewsMachineExplanationText ; $6370 ; 56901
	waitbutton
	sjump .showMenu; $EB68

.getNews
	writetext GoldenrodPokecomCenterWouldYouLikeTheNewsText ; $3E71 ; 56908
	yesorno
	iffalse .showMenu;$EB68
	writetext GoldenrodPokecomCenterReadingTheLatestNewsText ; $5471
	special Function17d2b6 ; download news?
	ifequal $0A, .showMenu ; $EB68
	ifnotequal $00, .mobileError ; $3569
.showNews
	special Function17d2ce ; show news?
	iffalse .quitViewingNews ; $3269
	ifequal $01, .noOldNews ; $2E69
	writetext GoldenrodPokecomCenterCorruptedNewsDataText ; $8971
	waitbutton
	sjump .showMenu ; $EB68

.noOldNews
	writetext GoldenrodPokecomCenterNoOldNewsText ; $7971 ; 5692E
	waitbutton
.quitViewingNews
	sjump .showMenu ; $EB68

.mobileError
	special BattleTowerMobileError ; 56935
	closetext
	end

Unreferenced:
	writetext GoldenrodPokecomCenterMakingPreparationsText ; ??? $AA71 ; 5693A no jump to here?
	waitbutton
	closetext
	end

GoldenrodPokecenter1F_GSBallSceneLeft:
	setval BATTLETOWERACTION_GSBALL ; 56940 (load mobile event index)
	special BattleTowerAction
	iffalse GoldenrodPokecenter1F_GSBallSceneRight.nogsball ; $9769
	checkevent EVENT_GOT_GS_BALL_FROM_GOLDENROD_POKEMON_CENTER ; 340
	iftrue GoldenrodPokecenter1F_GSBallSceneRight.nogsball ; $9769
	moveobject GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST, 12, 11
	sjump GoldenrodPokecenter1F_GSBallSceneRight.gsball ; 6769

GoldenrodPokecenter1F_GSBallSceneRight:
	setval BATTLETOWERACTION_GSBALL ; 56955 (load mobile event index)
	special BattleTowerAction
	iffalse .nogsball ; $9769
	checkevent EVENT_GOT_GS_BALL_FROM_GOLDENROD_POKEMON_CENTER ; 340
	iftrue .nogsball ; $9769
	moveobject GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST, 13, 11

.gsball ; 56769
	disappear GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST
	appear GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST
	playmusic MUSIC_SHOW_ME_AROUND
	applymovement GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST, GoldenrodPokeCenter1FLinkReceptionistApproachPlayerMovement ; $0F6A
	turnobject PLAYER, UP
	opentext
	writetext GoldenrodPokeCenter1FLinkReceptionistPleaseAcceptGSBallText
	waitbutton
	verbosegiveitem GS_BALL
	setevent EVENT_GOT_GS_BALL_FROM_GOLDENROD_POKEMON_CENTER
	setevent EVENT_CAN_GIVE_GS_BALL_TO_KURT
	writetext GoldenrodPokeCenter1FLinkReceptionistPleaseDoComeAgainText
	waitbutton
	closetext
	applymovement GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST, GoldenrodPokeCenter1FLinkReceptionistWalkBackMovement ; $196A
	special RestartMapMusic
	moveobject GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST, 16,  8
	disappear GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST
	appear GOLDENRODPOKECENTER1F_PCC_TRADE_CORNER_RECEPTIONIST

.nogsball
	end

GoldenrodPokecenter1FSuperNerdScript:
	special CheckMobileAdapterStatusSpecial ; 56998
	iftrue .mobile ; $A169
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffSuperNerdText  ; $E071

.mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnSuperNerdText ; $1E72

GoldenrodPokecenter1FLass2Script:
	special CheckMobileAdapterStatusSpecial ; 569A4
	iftrue .mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffLassText ; $AD72

.mobile
	checkevent EVENT_33F
	iftrue .alreadyMoved ; $D369
	faceplayer
	opentext
	writetext GoldenrodPokecenter1FMobileOnLassText1 ; $EB72
	waitbutton
	closetext
	readvar $09
	ifequal $02, .talkedToFromRight ; $C769
	applymovement GOLDENRODPOKECENTER1F_LASS2, GoldenrodPokeCenter1FLass2WalkRightMovement ; $236A
	sjump .skip ; $CB69
.talkedToFromRight
	applymovement GOLDENRODPOKECENTER1F_LASS2, GoldenrodPokeCenter1FLassWalkRightAroundPlayerMovement ; $276A
.skip
	setevent EVENT_33F
	moveobject GOLDENRODPOKECENTER1F_LASS2, $12, $09
	end

.alreadyMoved
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnLassText2 ; $2373

GoldenrodPokecenter1FYoungsterScript:
	special CheckMobileAdapterStatusSpecial ; 569D6
	iftrue .mobile ; $DF69
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffYoungsterText ; $5473

.mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnYoungsterText ; $1074

GoldenrodPokecenter1FTeacherScript:
	special CheckMobileAdapterStatusSpecial ; 569E2
	iftrue .mobile ; $EB69
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffTeacherText ; $8273

.mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnTeacherText ; $3274

GoldenrodPokecenter1FRockerScript:
	special CheckMobileAdapterStatusSpecial ; 569EE
	iftrue .mobile ; $F769
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffRockerText ; $D073

.mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnRockerText ; $5474

GoldenrodPokecenter1FGrampsScript:
	special CheckMobileAdapterStatusSpecial ; 569FD
	iftrue .mobile ; $066A
	jumptextfaceplayer GoldenrodPokecenter1FMobileOffGrampsText ; $D674

.mobile
	jumptextfaceplayer GoldenrodPokecenter1FMobileOnGrampsText ; $1875

PokeComCenterInfoSign:
	jumptext GoldenrodPokecomCenterSignText

GoldenrodPokecenter1FGameboyKidScript:
	jumptextfaceplayer GoldenrodPokecenter1FGameboyKidText

GoldenrodPokecenter1FLassScript:
	jumptextfaceplayer GoldenrodPokecenter1FLassText

;GoldenrodPokecenter1FPokefanF:
;	faceplayer
;	opentext
;	writetext GoldenrodPokecenter1FPokefanFDoYouHaveEonMailText
;	waitbutton
;	writetext GoldenrodPokecenter1FAskGiveAwayAnEonMailText
;	yesorno
;	iffalse .NoEonMail
;	takeitem EON_MAIL
;	iffalse .NoEonMail
;	writetext GoldenrodPokecenter1FPlayerGaveAwayTheEonMailText
;	waitbutton
;	writetext GoldenrodPokecenter1FPokefanFThisIsForYouText
;	waitbutton
;	verbosegiveitem REVIVE
;	iffalse .NoRoom
;	writetext GoldenrodPokecenter1FPokefanFDaughterWillBeDelightedText
;	waitbutton
;	closetext
;	end
;
;.NoEonMail:
;	writetext GoldenrodPokecenter1FPokefanFTooBadText
;	waitbutton
;	closetext
;	end
;
;.NoRoom:
;	giveitem EON_MAIL
;	writetext GoldenrodPokecenter1FPokefanFAnotherTimeThenText
;	waitbutton
;	closetext
;	end

GoldenrodPokeCenter1FLinkReceptionistApproachPlayerMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step DOWN
	step DOWN
	step DOWN
	step_end

GoldenrodPokeCenter1FLinkReceptionistWalkBackMovement:
	step UP
	step UP
	step UP
	step RIGHT
	step RIGHT
	step RIGHT
	step RIGHT
	step RIGHT
	step RIGHT
	step_end

GoldenrodPokeCenter1FLass2WalkRightMovement:
	slow_step RIGHT ; db $0B
	slow_step RIGHT ; db $0B
	turn_head UP    ; db $01
	step_end        ; db $47

GoldenrodPokeCenter1FLassWalkRightAroundPlayerMovement:
	slow_step DOWN  ; db $08
	slow_step RIGHT ; db $0B
	slow_step RIGHT ; db $0B
	slow_step UP    ; db $09
	turn_head UP    ; db $01
	step_end        ; db $47

GoldenrodPokecomCenterWelcomeToTradeCornerText:
	text "Hello! Welcome to"
	line "#COM CENTER"
	cont "TRADE CORNER."

	para "You can trade"
	line "#MON with other"
	cont "people far away."
	done

GoldenrodPokecomCenterWeMustHoldYourMonText:
	text "To make a trade,"
	line "we must hold your"
	cont "#MON."

	para "Would you like to"
	line "trade?"
	done

GoldenrodPokecomCenterWhatMonDoYouWantText:
	text "What kind of"
	line "#MON do you"
	cont "want in return?"
	done

GoldenrodPokecomCenterWeWillTradeYourMonForMonText:
	text "Fine. We will try"
	line "to trade your"

	para "@"
	text_ram wStringBuffer3
	text " for"
	line "@"
	text_ram wStringBuffer4
	text "."

	para "We'll have to hold"
	line "your #MON"
	cont "during the trade."

	para "Please wait while"
	line "we prepare the"
	cont "room for it."
	done

GoldenrodPokecomCenterWeWillTradeYourMonForNewText:
	text "Fine. We will try"
	line "to trade your"

	para "@"
	text_ram wStringBuffer3
	text " for a"
	line "#MON that you"
	cont "have never seen."

	para "We'll have to hold"
	line "your #MON"
	cont "during the trade."

	para "Please wait while"
	line "we prepare the"
	cont "room for it."
	done

GoldenrodPokecomCenterYourMonHasBeenReceivedText:
	text "Your trade #MON"
	line "has been received."

	para "It will take time"
	line "to find a trade"

	para "partner. Please"
	line "come back later."
	done

GoldenrodPokecomCenterYouHaveOnlyOneMonText:
	text "Oh? You have only"
	line "one #MON in"
	cont "your party. "

	para "Please come back"
	line "once you've in-"
	cont "creased the size"
	cont "of your party."
	done

GoldenrodPokecomCenterWeHopeToSeeYouAgainText:
	text "We hope to see you"
	line "again."
	done

GoldenrodPokecomCenterCommunicationErrorText: ; unreferenced
	text "Communication"
	line "error…"
	done

GoldenrodPokecomCenterCantAcceptLastMonText:
	text "If we accept that"
	line "#MON, what will"
	cont "you battle with?"
	done

GoldenrodPokecomCenterCantAcceptEggText:
	text "Sorry. We can't"
	line "accept an EGG."
	done

GoldenrodPokecomCenterCantAcceptAbnormalMonText:
	text "Sorry, but your"
	line "#MON appears to"

	para "be abnormal. We"
	line "can't accept it."
	done

GoldenrodPokecomCenterAlreadyHoldingMonText:
	text "Oh? Aren't we"
	line "already holding a"
	cont "#MON of yours?"
	done

GoldenrodPokecomCenterCheckingTheRoomsText:
	text "We'll check the"
	line "rooms."

	para "Please wait."
	done

GoldenrodPokecomCenterTradePartnerHasBeenFoundText:
	text "Thank you for your"
	line "patience."

	para "A trade partner"
	line "has been found."
	done

GoldenrodPokecomCenterItsYourNewPartnerText:
	text "It's your new"
	line "partner."

	para "Please take care"
	line "of it with love."

	para "We hope to see you"
	line "again."
	done

GoldenrodPokecomCenterYourPartyIsFullText:
	text "Uh-oh. Your party"
	line "is already full."

	para "Please come back"
	line "when you have room"
	cont "in your party."
	done

GoldenrodPokecomCenterNoTradePartnerFoundText:
	text "It's unfortunate,"
	line "but no one has"

	para "come forward as a"
	line "trade partner."

	para "Would you like"
	line "your #MON back?"
	done

GoldenrodPokecomCenterReturnedYourMonText:
	text "We have returned"
	line "your #MON."
	done

GoldenrodPokecomCenterYourMonIsLonelyText:
	text "It's unfortunate,"
	line "but no one has"

	para "come forward as a"
	line "trade partner."

	para "We've held your"
	line "#MON for a long"

	para "time. As a result,"
	line "it is very lonely."

	para "Sorry, but we must"
	line "return it to you."
	done

GoldenrodPokecenter1FWeHopeToSeeYouAgainText_2:
	text "We hope to see you"
	line "again."
	done

GoldenrodPokecomCenterContinueToHoldYourMonText:
	text "Fine. We will"
	line "continue to hold"
	cont "your #MON."
	done

GoldenrodPokecomCenterRecentlyLeftYourMonText:
	text "Oh? You left your"
	line "#MON with us"
	cont "only recently."

	para "Please come back"
	line "later."
	done

GoldenrodPokecomCenterSaveBeforeTradeCornerText:
	text "We'll SAVE before"
	line "connecting to the"
	cont "CENTER."
	done

GoldenrodPokecomCenterWhichMonToTradeText:
	text "Which #MON do"
	line "you want to trade?"
	done

GoldenrodPokecomCenterTradeCanceledText:
	text "Sorry, but we must"
	line "cancel the trade."
	done

GoldenrodPokecomCenterEggTicketText:
	text "Oh!"

	para "I see you have an"
	line "EGG TICKET!"

	para "It's a coupon that"
	line "special people can"

	para "redeem for a"
	line "special #MON!"
	done

GoldenrodPokecomCenterOddEggBriefingText:
	text "Let me give you a"
	line "quick briefing."

	para "Trades held at the"
	line "TRADE CORNER are"

	para "between two"
	line "trainers who don't"

	para "know each other's"
	line "identity."

	para "As a result, it"
	line "may take time."

	para "However, an ODD"
	line "EGG is available"
	cont "just for you."

	para "It will be sent to"
	line "you right away."

	para "Please choose one"
	line "of the rooms in"

	para "the CENTER."
	line "An ODD EGG will be"

	para "sent from the"
	line "chosen room."
	done

GoldenrodPokecomCenterPleaseWaitAMomentText:
	text "Please wait a"
	line "moment."
	done

GoldenrodPokecomCenterHereIsYourOddEggText:
	text "Thank you for"
	line "waiting."

	para "We received your"
	line "ODD EGG."

	para "Here it is!"

	para "Please raise it"
	line "with loving care."
	done

GoldenrodPokecomCenterNoEggTicketServiceText:
	text "I'm awfully sorry."

	para "The EGG TICKET"
	line "exchange service"
	cont "isn't running now."
	done

GoldenrodPokecomCenterNewsMachineText:
	text "It's a #MON"
	line "NEWS MACHINE."
	done

GoldenrodPokecomCenterWhatToDoText:
	text "What would you"
	line "like to do?"
	done

GoldenrodPokecomCenterNewsMachineExplanationText:
	text "#MON NEWS is"
	line "news compiled from"

	para "the SAVE files of"
	line "#MON trainers."

	para "When reading the"
	line "NEWS, your SAVE"

	para "file may be sent"
	line "out."

	para "The SAVE file data"
	line "will contain your"

	para "adventure log and"
	line "mobile profile."

	para "Your phone number"
	line "will not be sent."

	para "The contents of"
	line "the NEWS will vary"

	para "depending on the"
	line "SAVE files sent by"

	para "you and the other"
	line "#MON trainers."

	para "You might even be"
	line "in the NEWS!"
	done

GoldenrodPokecomCenterWouldYouLikeTheNewsText:
	text "Would you like to"
	line "get the NEWS?"
	done

GoldenrodPokecomCenterReadingTheLatestNewsText:
	text "Reading the latest"
	line "NEWS… Please wait."
	done

GoldenrodPokecomCenterNoOldNewsText:
	text "There is no old"
	line "NEWS…"
	done

GoldenrodPokecomCenterCorruptedNewsDataText:
	text "The NEWS data is"
	line "corrupted."

	para "Please download"
	line "the NEWS again."
	done

GoldenrodPokecomCenterMakingPreparationsText:
	text "We're making"
	line "preparations."

	para "Please come back"
	line "later."
	done

GoldenrodPokecomCenterSaveBeforeNewsMachineText:
	text "We will SAVE your"
	line "progress before"

	para "starting the NEWS"
	line "MACHINE."
	done

GoldenrodPokecenter1FMobileOffSuperNerdText:
	text "Whoa, this #MON"
	line "CENTER is huge."

	para "They just built"
	line "this place. They"

	para "installed lots of"
	line "new machines too."
	done

GoldenrodPokecenter1FMobileOnSuperNerdText:
	text "I thought up a fun"
	line "new thing for the"
	cont "TRADE CORNER!"

	para "I make a PIDGEY"
	line "hold MAIL, then"

	para "put it up for"
	line "trade for another"
	cont "one!"

	para "If everyone did"
	line "that, MAIL could"

	para "be traded with all"
	line "sorts of people!"

	para "I call it PIDGEY"
	line "MAIL!"

	para "If it becomes"
	line "popular, I might"

	para "make lots of new"
	line "friends!"
	done

GoldenrodPokecenter1FMobileOffLassText:
	text "They said you can"
	line "trade #MON with"

	para "total strangers up"
	line "here."

	para "But they're still"
	line "adjusting things."
	done

GoldenrodPokecenter1FMobileOnLassText1:
	text "Some girl I don't"
	line "know sent me her"

	para "HOPPIP."
	line "You should trade"

	para "for a #MON that"
	line "you want."
	done

GoldenrodPokecenter1FMobileOnLassText2:
	text "I received a"
	line "female HOPPIP, but"
	cont "its named STANLEY!"

	para "That's my dad's"
	line "name!"
	done

GoldenrodPokecenter1FMobileOffYoungsterText:
	text "What is the NEWS"
	line "MACHINE?"

	para "Does it get news"
	line "from a wider area"
	cont "than the radio?"
	done

GoldenrodPokecenter1FMobileOffTeacherText:
	text "The #COM CENTER"
	line "will link with all"

	para "#MON CENTERS in"
	line "a wireless net."

	para "That must mean"
	line "I'll be able to"

	para "link with all"
	line "sorts of people."
	done

GoldenrodPokecenter1FMobileOffRockerText:
	text "The machines here"
	line "can't be used yet."

	para "Still, it's nice"
	line "coming to a trendy"

	para "place before other"
	line "people."
	done

GoldenrodPokecenter1FMobileOnYoungsterText:
	text "My friend was in"
	line "the NEWS a while"

	para "back. I was really"
	line "surprised!"
	done

GoldenrodPokecenter1FMobileOnTeacherText:
	text "I get anxious if I"
	line "don't check out"
	cont "the latest NEWS!"
	done

GoldenrodPokecenter1FMobileOnRockerText:
	text "If I get in the"
	line "NEWS and become"

	para "famous, I bet I'll"
	line "be adored."

	para "I wonder how I"
	line "could get in the"
	cont "NEWS?"
	done

GoldenrodPokecenter1FGameboyKidText:
	text "The COLOSSEUM"
	line "upstairs is for"
	cont "link battles."

	para "Battle records are"
	line "posted on the"

	para "wall, so I can't"
	line "afford to lose."
	done

GoldenrodPokecenter1FMobileOffGrampsText:
	text "I came over here"
	line "when I got word"

	para "that GOLDENROD's"
	line "#MON CENTER has"

	para "new machines that"
	line "no one's ever seen"
	cont "before."

	para "But it looks like"
	line "they're still busy"

	para "with all their"
	line "preparations…"
	done

GoldenrodPokecenter1FMobileOnGrampsText:
	text "Just seeing all"
	line "these new things"

	para "here makes me feel"
	line "younger!"
	done

GoldenrodPokecenter1FLassText:
	text "A higher level"
	line "#MON doesn't"
	cont "always win."

	para "After all, it may"
	line "have a type dis-"
	cont "advantage."

	para "I don't think"
	line "there is a single"

	para "#MON that is"
	line "the toughest."
	done

GoldenrodPokeCenter1FLinkReceptionistPleaseAcceptGSBallText:
	text "<PLAYER>, isn't it?"

	para "Congratulations!"

	para "As a special deal,"
	line "a GS BALL has been"
	cont "sent just for you!"

	para "Please accept it!"
	done

GoldenrodPokeCenter1FLinkReceptionistPleaseDoComeAgainText:
	text "Please do come"
	line "again!"
	done

GoldenrodPokecomCenterSignText:
	text "#COM CENTER"
	line "1F INFORMATION"

	para "Left:"
	line "ADMINISTRATION"

	para "Center:"
	line "TRADE CORNER"

	para "Right:"
	line "#MON NEWS"
	done

GoldenrodPokecomCenterNewsMachineNotYetText:
	text "It's a #MON"
	line "NEWS MACHINE!"

	para "It's not in"
	line "operation yet…"
	done

GoldenrodPokecenter1FPokefanFDoYouHaveEonMailText:
	text "Oh my, your pack"
	line "looks so heavy!"

	para "Oh! Do you happen"
	line "to have something"
	cont "named EON MAIL?"

	para "My daughter is"
	line "after one."

	para "You can part with"
	line "one, can't you?"
	done

GoldenrodPokecenter1FAskGiveAwayAnEonMailText:
	text "Give away an EON"
	line "MAIL?"
	done

GoldenrodPokecenter1FPokefanFThisIsForYouText:
	text "Oh, that's great!"
	line "Thank you, honey!"

	para "Here, this is for"
	line "you in return!"
	done

GoldenrodPokecenter1FPokefanFDaughterWillBeDelightedText:
	text "My daughter will"
	line "be delighted!"
	done

GoldenrodPokecenter1FPokefanFTooBadText:
	text "Oh? You don't have"
	line "one? Too bad."
	done

GoldenrodPokecenter1FPokefanFAnotherTimeThenText:
	text "Oh… Well, another"
	line "time, then."
	done

GoldenrodPokecenter1FPlayerGaveAwayTheEonMailText:
	text "<PLAYER> gave away"
	line "the EON MAIL."
	done

GoldenrodPokecenter1F_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  6, 15, GOLDENROD_CITY, 15
	warp_event  7, 15, GOLDENROD_CITY, 15
	warp_event  0,  6, POKECOM_CENTER_ADMIN_OFFICE_MOBILE, 1
	warp_event  0, 15, POKECENTER_2F, 1

	def_coord_events
	coord_event  6, 15, SCENE_DEFAULT, GoldenrodPokecenter1F_GSBallSceneLeft
	coord_event  7, 15, SCENE_DEFAULT, GoldenrodPokecenter1F_GSBallSceneRight

	def_bg_events
	bg_event 24,  5, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript ; 57666
	bg_event 24,  6, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 24,  7, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 24,  9, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 24, 10, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 25, 11, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 26, 11, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 27, 11, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 28, 11, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29,  5, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29,  6, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29,  7, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29,  8, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29,  9, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event 29, 10, BGEVENT_READ, GoldenrodPokecenter1F_NewsMachineScript
	bg_event  2,  9, BGEVENT_READ, PokeComCenterInfoSign

	def_object_events
	object_event  7,  7, SPRITE_NURSE, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FNurseScript, -1
	 ; 576C4
	object_event 16,  8, SPRITE_LINK_RECEPTIONIST, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_BLUE, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FTradeCornerAttendantScript, -1
	 ; boy left of trade corner 576D1
	object_event 13,  5, SPRITE_SUPER_NERD, SPRITEMOVEDATA_WALK_UP_DOWN, 16, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FSuperNerdScript, -1
	 ; girl in front of trade corner 576DE
	object_event 18,  9, SPRITE_LASS, SPRITEMOVEDATA_STANDING_UP, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FLass2Script, -1
	 ; boy left of news machine 576EB
	object_event 23, 08, SPRITE_YOUNGSTER, SPRITEMOVEDATA_STANDING_RIGHT, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FYoungsterScript, -1
	 ; girl right of news machine 576F8
	object_event 30, 09, SPRITE_TEACHER, SPRITEMOVEDATA_STANDING_LEFT, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FTeacherScript, -1
	 ; boy right of news machine 57705
	object_event 30, 05, SPRITE_ROCKER, SPRITEMOVEDATA_STANDING_LEFT, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FRockerScript, -1
	 ; 57712
	object_event 11, 12, SPRITE_GAMEBOY_KID, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FGameboyKidScript, -1
	 ; old man 5771F
	object_event 19, 14, SPRITE_GRAMPS, SPRITEMOVEDATA_STANDING_UP, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FGrampsScript, -1
	 ; 5772C
	object_event  4, 11, SPRITE_LASS, SPRITEMOVEDATA_WALK_LEFT_RIGHT, 1, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FLassScript, -1
	;object_event 15, 12, SPRITE_POKEFAN_F, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_BROWN, OBJECTTYPE_SCRIPT, 0, GoldenrodPokecenter1FPokefanF, -1
