SECTION "Scratch", SRAM

sScratch:: ds $60 tiles


SECTION "SRAM Bank 0", SRAM

sPartyMail::
; sPartyMon1Mail - sPartyMon6Mail
for n, 1, PARTY_LENGTH + 1
sPartyMon{d:n}Mail:: mailmsg sPartyMon{d:n}Mail
endr

sPartyMailBackup::
; sPartyMon1MailBackup - sPartyMon6MailBackup
for n, 1, PARTY_LENGTH + 1
sPartyMon{d:n}MailBackup:: mailmsg sPartyMon{d:n}MailBackup
endr

sMailboxCount:: db
sMailboxes::
; sMailbox1 - sMailbox10
for n, 1, MAILBOX_CAPACITY + 1
sMailbox{d:n}:: mailmsg sMailbox{d:n}
endr

sMailboxCountBackup:: db
sMailboxesBackup::
; sMailbox1Backup - sMailbox10Backup
for n, 1, MAILBOX_CAPACITY + 1
sMailbox{d:n}Backup:: mailmsg sMailbox{d:n}Backup
endr

sMysteryGiftData::
sMysteryGiftItem:: db
sMysteryGiftUnlocked:: db
sBackupMysteryGiftItem:: db
sNumDailyMysteryGiftPartnerIDs:: db
sDailyMysteryGiftPartnerIDs:: ds MAX_MYSTERY_GIFT_PARTNERS * 2
sMysteryGiftDecorationsReceived:: flag_array NUM_NON_TROPHY_DECOS
	ds 4
sMysteryGiftTimer:: dw
	ds 1
sMysteryGiftTrainerHouseFlag:: db
sMysteryGiftPartnerName:: ds NAME_LENGTH
sMysteryGiftUnusedFlag:: db
sMysteryGiftTrainer:: ds wMysteryGiftTrainerEnd - wMysteryGiftTrainer
sBackupMysteryGiftItemEnd::

	ds $30

sRTCStatusFlags:: db
	ds 7
sLuckyNumberDay:: db
sLuckyIDNumber::  dw

SECTION "Backup Save", SRAM

sBackupOptions:: ds wOptionsEnd - wOptions

sBackupCheckValue1:: db ; loaded with SAVE_CHECK_VALUE_1, used to check save corruption

sBackupGameData::
sBackupPlayerData::  ds wPlayerDataEnd - wPlayerData
sBackupCurMapData::  ds wCurMapDataEnd - wCurMapData
sBackupPokemonData:: ds wPokemonDataEnd - wPokemonData
sBackupGameDataEnd::

	ds $18a

sBackupChecksum:: dw

sBackupCheckValue2:: db ; loaded with SAVE_CHECK_VALUE_2, used to check save corruption

sStackTop:: dw

if DEF(_DEBUG)
sRTCHaltCheckValue:: dw
sSkipBattle:: db
sDebugTimeCyclesSinceLastCall:: db
sOpenedInvalidSRAM:: db
sIsBugMon:: db
endc


SECTION "Save", SRAM

sOptions:: ds wOptionsEnd - wOptions

sCheckValue1:: db ; loaded with SAVE_CHECK_VALUE_1, used to check save corruption

sGameData::
sPlayerData::  ds wPlayerDataEnd - wPlayerData
sCurMapData::  ds wCurMapDataEnd - wCurMapData
sPokemonData:: ds wPokemonDataEnd - wPokemonData
sGameDataEnd::

	ds $18a

sChecksum:: dw

sCheckValue2:: db ; loaded with SAVE_CHECK_VALUE_2, used to check save corruption


SECTION "Active Box", SRAM

sBox:: box sBox

	ds $100


SECTION "Link Battle Data", SRAM

sLinkBattleStats::
sLinkBattleWins::   dw
sLinkBattleLosses:: dw
sLinkBattleDraws::  dw

sLinkBattleRecord::
; sLinkBattleRecord1 - sLinkBattleRecord5
for n, 1, NUM_LINK_BATTLE_RECORDS + 1
sLinkBattleRecord{d:n}:: link_battle_record sLinkBattleRecord{d:n}
endr
sLinkBattleStatsEnd::


SECTION "SRAM Hall of Fame", SRAM

sHallOfFame::
; sHallOfFame1 - sHallOfFame30
for n, 1, NUM_HOF_TEAMS + 1
sHallOfFame{d:n}:: hall_of_fame sHallOfFame{d:n}
endr
sHallOfFameEnd::


SECTION "SRAM Crystal Data", SRAM

;sMobileEventIndex:: db
	ds 1

sCrystalData:: ds wCrystalDataEnd - wCrystalData

;sMobileEventIndexBackup:: db
	ds 1


SECTION "SRAM Battle Tower", SRAM

; Battle Tower data must be in SRAM because you can save and leave between battles
;sBattleTowerChallengeState::
; 0: normal
; 2: battle tower
;	db
	ds 1

;sNrOfBeatenBattleTowerTrainers:: db
;sBTChoiceOfLevelGroup:: db
	ds 2
; Battle Tower trainers are saved here, so nobody appears more than once
;sBTTrainers:: ds BATTLETOWER_STREAK_LENGTH
	ds 7
;sBattleTowerSaveFileFlags:: db
;sBattleTowerReward:: db
	ds 2


sBTMonOfTrainers::
; team of previous trainer
; sBTMonPrevTrainer1 - sBTMonPrevTrainer3
for n, 1, BATTLETOWER_PARTY_LENGTH + 1
sBTMonPrevTrainer{d:n}:: db
endr
; team of preprevious trainer
; sBTMonPrevPrevTrainer1 - sBTMonPrevPrevTrainer3
for n, 1, BATTLETOWER_PARTY_LENGTH + 1
sBTMonPrevPrevTrainer{d:n}:: db
endr


; The PC boxes will not fit into one SRAM bank,
; so they use multiple SECTIONs
DEF box_n = 0
MACRO boxes
	rept \1
		DEF box_n += 1
	sBox{d:box_n}:: box sBox{d:box_n}
	endr
ENDM

SECTION "Boxes 1-7", SRAM

; sBox1 - sBox7
	boxes 7

SECTION "Boxes 8-14", SRAM

; sBox8 - sBox14
	boxes 7

; All 14 boxes fit exactly within 2 SRAM banks
	assert box_n == NUM_BOXES, \
		"boxes: Expected {d:NUM_BOXES} total boxes, got {d:box_n}"


SECTION "SRAM Mobile 1", SRAM

	ds $7 ; former location of sCrystalData
sEZChatIntroductionMessage:: ds EASY_CHAT_MESSAGE_LENGTH
sEZChatBeginBattleMessage:: ds EASY_CHAT_MESSAGE_LENGTH
sEZChatWinBattleMessage:: ds EASY_CHAT_MESSAGE_LENGTH
sEZChatLoseBattleMessage:: ds EASY_CHAT_MESSAGE_LENGTH
sCardFolderPasscode:: ds 4
sCardFolderData:: ds CARD_FOLDER_ENTRY_LENGTH * NUM_CARD_FOLDER_ENTRIES ; a03b
sPhoneNumber:: ds PHONE_NUMBER_LENGTH
s4_a60b:: ds 1
s4_a60c:: ds 2
s4_a60e:: ds 2
	ds 496
sMobileBattleTimer:: ds 3
	ds 797
s4_b000:: ds 1


SECTION "SRAM Mobile 2", SRAM

sMobileEventIndex:: db ; JP: location of sMobileEventIndex

sTrainerRankings::
sTrainerRankingGameTimeHOF:: ds 4
sTrainerRankingStepCountHOF:: ds 4
sTrainerRankingHealingsHOF:: ds 4
sTrainerRankingBattlesHOF:: ds 3
sTrainerRankingStepCount:: ds 4
sTrainerRankingBattleTowerWins:: ds 4
sTrainerRankingTMsHMsTaught:: ds 3
sTrainerRankingBattles:: ds 3
sTrainerRankingWildBattles:: ds 3
sTrainerRankingTrainerBattles:: ds 3
sTrainerRankingUnused1:: ds 3
sTrainerRankingHOFEntries:: ds 3
sTrainerRankingWildMonsCaught:: ds 3
sTrainerRankingHookedEncounters:: ds 3
sTrainerRankingEggsHatched:: ds 3
sTrainerRankingMonsEvolved:: ds 3
sTrainerRankingFruitPicked:: ds 3
sTrainerRankingHealings:: ds 3
sTrainerRankingMysteryGift:: ds 3
sTrainerRankingTrades:: ds 3
sTrainerRankingFly:: ds 3
sTrainerRankingSurf:: ds 3
sTrainerRankingWaterfall:: ds 3
sTrainerRankingWhiteOuts:: ds 3
sTrainerRankingLuckyNumberShow:: ds 3
sTrainerRankingPhoneCalls:: ds 3
sTrainerRankingUnused2:: ds 3
sTrainerRankingLinkBattles:: ds 3
sTrainerRankingSplash:: ds 3
sTrainerRankingTreeEncounters:: ds 3
sTrainerRankingUnused3:: ds 3
sTrainerRankingColosseumWins:: ds 3
sTrainerRankingColosseumLosses:: ds 3
sTrainerRankingColosseumDraws:: ds 3
sTrainerRankingSelfdestruct:: ds 3
sTrainerRankingCurrentSlotsStreak:: ds 2
sTrainerRankingLongestSlotsStreak:: ds 2
sTrainerRankingTotalSlotsPayouts:: ds 4
sTrainerRankingTotalBattlePayouts:: ds 4
sTrainerRankingLongestMagikarp:: ds 2
sTrainerRankingShortestMagikarp:: ds 2
sTrainerRankingBugContestScore:: ds 2
sTrainerRankingsChecksum:: ds 2
sTrainerRankingsEnd::

sMobileEventIndexBackup:: db ; JP: location of sMobileEventIndexBackup

sTrainerRankingsBackup:: ds sTrainerRankingsEnd - sTrainerRankings

	ds $6fa

s5_a800:: db

sOfferEmail::      ds MOBILE_EMAIL_LENGTH
sOfferTrainerID::  dw
sOfferSecretID::   dw
sOfferGender::     db
sOfferSpecies::    db
sOfferReqGender::  db
sOfferReqSpecies:: db
sOfferMonSender::  ds PLAYER_NAME_LENGTH - 1
sOfferMon::        party_struct sOfferMon
sOfferMonOT::      ds PLAYER_NAME_LENGTH - 1
sOfferMonNick::    ds MON_NAME_LENGTH - 1
sOfferMonMail::    mailmsg sOfferMonMail
s5_a890:: ds 4
s5_a894:: ds 6 ; a894
s5_a89a:: dw
s5_a89c:: ds 22 ; a89c honor roll level and room string

s5_a8b2:: ds HONOR_ROLL_DATA_LENGTH ; a8b2 honor roll downloaded names

s5_a948:: ds BATTLE_TOWER_DATA_UPLOAD_LENGTH ; a948 battle tower data to upload

; Battle Tower data must be in SRAM because you can save and leave between battles
sBattleTowerChallengeState::
; 0: normal
; 2: battle tower
	db

sBattleTower:: ; aa3f
sNrOfBeatenBattleTowerTrainers:: db
sBTChoiceOfLevelGroup:: db ; aa40
s5_aa41:: ds 6
s5_aa47:: db
s5_aa48:: db

	ds $1

s5_aa4a:: db

sMobileLoginPassword:: ds MOBILE_LOGIN_PASSWORD_LENGTH

	ds $1

s5_aa5d:: ds MOBILE_LOGIN_PASSWORD_LENGTH

	ds $4

s5_aa72:: db
s5_aa73:: ds 12
s5_aa7f:: ds 12

s5_aa8b:: db
s5_aa8c:: db
s5_aa8d:: db
s5_aa8e:: ds BATTLE_TOWER_STRUCT_LENGTH * BATTLETOWER_STREAK_LENGTH ; aa8e battle tower room data

sBattleTowerSaveFileFlags:: db

s5_b023:: ds 105 + 2 + 2 + 5 + 5 ; b023
s5_b08c:: ds 4 ; b08c
s5_b090:: ds 2
s5_b092:: ds 31
s5_b0b1:: ds $40
	ds $c0

s5_b1b1:: ds 2
s5_b1b3:: ds 2

	ds $1e

s5_b1d3:: ds 2

	ds $1e

s5_b1f3:: ds $19

	ds $d4

sZipcodeCharIndexes:: ds ZIPCODE_MAX_LENGTH ; Stores the char indexes of the zipcode, for fast and easy retrieval.

	ds $10 - ZIPCODE_MAX_LENGTH
	;ds 3 ; 3 bytes moved to sDownloadedContentPrefectureAndZipcode, for the new zipcode length (now 7 chars instead of 4). Breaks save compatibility with vanilla.

sDownloadedContentPrefectureAndZipcode:: ds 8 ; Backs up the player's prefecture and zipcode before downloaded region-based content. Thanks to this, if the player updates his/her zipcode after having downloaded some content, the downloaded content will still be displayed as comming from where it was downloaded.

	ds 1
s5_b2f9:: db ; b2f9
s5_b2fa:: db ; b2fa
s5_b2fb:: db ; b2fb
	ds $c0e;$d03
s5_bfff:: ds 1


SECTION "SRAM Mobile 3", SRAM


s6_a000:: db ; start of news data
	db
s6_a002:: db
s6_a003:: db
s6_a004:: db
s6_a005:: db
s6_a006:: ds $1000





SECTION "SRAM Mobile 4", SRAM

; Bank 7 in bank 6??
s7_a000:: db
s7_a001:: ds $799
s7_a800:: ds $800
s7_b000:: ds $fea
s7_bfea:: ds 1
