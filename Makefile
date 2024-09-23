roms := \
    pokecrystal_plus.gbc \
	pokecrystalplus_debug.gbc \
	pokecrystalplus_au.gbc \
	pokecrystalplus_eu.gbc \
	pokecrystalplus_nofix.gbc
patches := pokecrystalvc.patch \
		   pokecrystalpink.patch

rom_obj := \
	audio.o \
	home.o \
	main.o \
	ram.o \
	data/text/common.o \
	data/maps/map_data.o \
	data/pokemon/dex_entries.o \
	data/pokemon/egg_moves.o \
	data/pokemon/evos_attacks.o \
	engine/movie/credits.o \
	engine/overworld/events.o \
	gfx/misc.o \
	gfx/pics.o \
	gfx/sprites.o \
	gfx/tilesets.o \
	lib/mobile/main.o \
	lib/mobile/mail.o

pokecrystal_plus_obj    := $(rom_obj:.o=plus.o)
pokecrystalplus_debug_obj := $(rom_obj:.o=plus_debug.o)
pokecrystalplus_au_obj      := $(rom_obj:.o=_au.o)
pokecrystalplus_eu_obj      := $(rom_obj:.o=_eu.o)
pokecrystalplus_nofix_obj    := $(rom_obj:.o=nofix.o)
pokecrystal11_vc_obj    := $(rom_obj:.o=11_vc.o)
pokecrystal_pink_obj    := $(rom_obj:.o=pink.o)

### Build tools

ifeq (,$(shell which sha1sum))
SHA1 := shasum
else
SHA1 := sha1sum
endif

RGBDS ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink


### Build targets      

.SUFFIXES:
.PHONY: all plus debug au eu nofix vc clean tidy compare tools
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:

all: plus
plus:            pokecrystal_plus.gbc
debug: 	 		 pokecrystalplus_debug.gbc
au:      		 pokecrystalplus_au.gbc
eu:      		 pokecrystalplus_eu.gbc
nofix:			 pokecrystalplus_nofix.gbc
vc:				 pokecrystalvc.patch
#pink:			 pokecrystalpink.patch

clean: tidy
	find gfx \
	     \( -name "*.[12]bpp" \
	        -o -name "*.lz" \
	        -o -name "*.gbcpal" \
	        -o -name "*.sgb.tilemap" \) \
	     -delete
	find gfx/pokemon -mindepth 1 \
	     ! -path "gfx/pokemon/unown/*" \
	     \( -name "bitmask.asm" \
	        -o -name "frames.asm" \
	        -o -name "front.animated.tilemap" \
	        -o -name "front.dimensions" \) \
	     -delete

tidy:
	$(RM) $(roms) \
	      $(roms:.gbc=.sym) \
	      $(roms:.gbc=.map) \
	      $(patches) \
	      $(patches:.patch=_vc.gbc) \
	      $(patches:.patch=_vc.sym) \
	      $(patches:.patch=_vc.map) \
	      $(patches:%.patch=vc/%.constants.sym) \
          $(pokecrystal_plus_obj) \
		  $(pokecrystalplus_debug_obj) \
	      $(pokecrystalplus_au_obj) \
		  $(pokecrystalplus_eu_obj) \
		  $(pokecrystalplus_nofix_obj) \
		  $(pokecrystal11_vc_obj) \
		  $(pokecrystal_pink_obj) \
	      rgbdscheck.o
	$(MAKE) clean -C tools/

compare: $(roms) $(patches)
	@$(SHA1) -c roms.sha1

tools:
	$(MAKE) -C tools/


RGBASMFLAGS = -hL -Q8 -P includes.asm -Weverything -Wnumeric-string=2 -Wtruncation=1
# Create a sym/map for debug purposes if `make` run with `DEBUG=1`
ifeq ($(DEBUG),1)
RGBASMFLAGS += -E
endif

$(pokecrystal_plus_obj):    RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11
$(pokecrystalplus_debug_obj):RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11 -D _DEBUG
$(pokecrystalplus_au_obj):      RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11 -D _CRYSTAL_AU
$(pokecrystalplus_eu_obj):      RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11 -D _CRYSTAL_EU
$(pokecrystalplus_nofix_obj):	RGBASMFLAGS += -D _CRYSTAL11
$(pokecrystal11_vc_obj):    RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11 -D _CRYSTAL11_VC
$(pokecrystal_pink_obj):    RGBASMFLAGS += -D _CRYSTALFIX -D _CRYSTAL11 -D _PINK

%.patch: vc/%.constants.sym %_vc.gbc %.gbc vc/%.patch.template
	tools/make_patch $*_vc.sym $^ $@

rgbdscheck.o: rgbdscheck.asm
	$(RGBASM) -o $@ $<

# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean tidy tools,$(MAKECMDGOALS)))

$(info $(shell $(MAKE) -C tools))

# The dep rules have to be explicit or else missing files won't be reported.
# As a side effect, they're evaluated immediately instead of when the rule is invoked.
# It doesn't look like $(shell) can be deferred so there might not be a better way.
preinclude_deps := includes.asm $(shell tools/scan_includes includes.asm)
define DEP
$1: $2 $$(shell tools/scan_includes $2) $(preinclude_deps) | rgbdscheck.o
	$$(RGBASM) $$(RGBASMFLAGS) -o $$@ $$<
endef

# Dependencies for shared objects objects
$(foreach obj, $(pokecrystal_plus_obj), $(eval $(call DEP,$(obj),$(obj:plus.o=.asm))))
$(foreach obj, $(pokecrystalplus_debug_obj), $(eval $(call DEP,$(obj),$(obj:plus_debug.o=.asm))))
$(foreach obj, $(pokecrystalplus_au_obj), $(eval $(call DEP,$(obj),$(obj:_au.o=.asm))))
$(foreach obj, $(pokecrystalplus_eu_obj), $(eval $(call DEP,$(obj),$(obj:_eu.o=.asm))))
$(foreach obj, $(pokecrystalplus_nofix_obj), $(eval $(call DEP,$(obj),$(obj:nofix.o=.asm))))
$(foreach obj, $(pokecrystal11_vc_obj), $(eval $(call DEP,$(obj),$(obj:11_vc.o=.asm))))
$(foreach obj, $(pokecrystal_pink_obj), $(eval $(call DEP,$(obj),$(obj:pink.o=.asm))))

# Dependencies for VC files that need to run scan_includes
%.constants.sym: %.constants.asm $(shell tools/scan_includes %.constants.asm) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) $< > $@

endif

pokecrystal_plus_opt    = -Cjv -t PM_CRYSTAL -i BXTE -n 0 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystalplus_debug_opt= -Cjv -t PM_CRYSTAL -i BXTE -n 1 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystalplus_au_opt      = -Cjv -t PM_CRYSTAL -i BXTU -n 0 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystal_eu_opt      = -Cjv -t PM_CRYSTAL -i BXTP -n 0 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystal_nofix_opt   = -Cjv -t PM_CRYSTAL -i BXTE -n 0 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystal11_vc_opt    = -Cjv -t PM_CRYSTAL -i BXTE -n 1 -k 01 -l 0x33 -m 0x10 -r 5 -p 0
pokecrystal_pink_opt    = -Cjv -t PM_CRYSTAL -i BXTE -n 0 -k 01 -l 0x33 -m 0x10 -r 5 -p 0

%.gbc: $$(%_obj) layout.link
	$(RGBLINK) -n $*.sym -m $*.map -l layout.link -o $@ $(filter %.o,$^)
	$(RGBFIX) $($*_opt) $@
	#tools/stadium $@


### LZ compression rules

# Delete this line if you don't care about matching and just want optimal compression.
include gfx/lz.mk

%.lz: %
	tools/lzcomp $(LZFLAGS) -- $< $@


### Pokemon pic animation rules

gfx/pokemon/%/front.animated.2bpp: gfx/pokemon/%/front.2bpp gfx/pokemon/%/front.dimensions
	tools/pokemon_animation_graphics -o $@ $^
gfx/pokemon/%/front.animated.tilemap: gfx/pokemon/%/front.2bpp gfx/pokemon/%/front.dimensions
	tools/pokemon_animation_graphics -t $@ $^
gfx/pokemon/%/bitmask.asm: gfx/pokemon/%/front.animated.tilemap gfx/pokemon/%/front.dimensions
	tools/pokemon_animation -b $^ > $@
gfx/pokemon/%/frames.asm: gfx/pokemon/%/front.animated.tilemap gfx/pokemon/%/front.dimensions
	tools/pokemon_animation -f $^ > $@


### Terrible hacks to match animations. Delete these rules if you don't care about matching.

# Dewgong has an unused tile id in its last frame. The tile itself is missing.
gfx/pokemon/dewgong/frames.asm: gfx/pokemon/dewgong/front.animated.tilemap gfx/pokemon/dewgong/front.dimensions
	tools/pokemon_animation -f $^ > $@
	echo "	db \$$4d" >> $@

# Lugia has two unused tile ids in its last frame. The tiles themselves are missing.
gfx/pokemon/lugia/frames.asm: gfx/pokemon/lugia/front.animated.tilemap gfx/pokemon/lugia/front.dimensions
	tools/pokemon_animation -f $^ > $@
	echo "	db \$$5e, \$$59" >> $@

# Girafarig has a redundant tile after the end. It is used in two frames, so it must be injected into the generated graphics.
# This is more involved, so it's hacked into pokemon_animation_graphics.
gfx/pokemon/girafarig/front.animated.2bpp: gfx/pokemon/girafarig/front.2bpp gfx/pokemon/girafarig/front.dimensions
	tools/pokemon_animation_graphics --girafarig -o $@ $^
gfx/pokemon/girafarig/front.animated.tilemap: gfx/pokemon/girafarig/front.2bpp gfx/pokemon/girafarig/front.dimensions
	tools/pokemon_animation_graphics --girafarig -t $@ $^


### Misc file-specific graphics rules

gfx/pokemon/%/back.2bpp: rgbgfx += -Z -c embedded
gfx/pokemon/%/front.2bpp: rgbgfx += -c embedded

gfx/trainers/%.2bpp: rgbgfx += -Z -c embedded

gfx/pokemon/egg/unused_front.2bpp: rgbgfx += -Z

gfx/new_game/shrink1.2bpp: rgbgfx += -Z
gfx/new_game/shrink2.2bpp: rgbgfx += -Z

gfx/mail/dragonite.1bpp: tools/gfx += --remove-whitespace
gfx/mail/large_note.1bpp: tools/gfx += --remove-whitespace
gfx/mail/surf_mail_border.1bpp: tools/gfx += --remove-whitespace
gfx/mail/flower_mail_border.1bpp: tools/gfx += --remove-whitespace
gfx/mail/litebluemail_border.1bpp: tools/gfx += --remove-whitespace

gfx/pokedex/pokedex.2bpp: tools/gfx += --trim-whitespace
gfx/pokedex/pokedex_sgb.2bpp: tools/gfx += --trim-whitespace
gfx/pokedex/question_mark.2bpp: rgbgfx += -Z
gfx/pokedex/slowpoke.2bpp: tools/gfx += --trim-whitespace
gfx/pokedex/slowpoke_mobile.2bpp: tools/gfx += --trim-whitespace

gfx/pokegear/pokegear.2bpp: rgbgfx += -x2
gfx/pokegear/pokegear_sprites.2bpp: tools/gfx += --trim-whitespace

gfx/mystery_gift/mystery_gift.2bpp: tools/gfx += --trim-whitespace

gfx/title/crystal.2bpp: tools/gfx += --interleave --png=$<
gfx/title/old_fg.2bpp: tools/gfx += --interleave --png=$<
gfx/title/logo.2bpp: rgbgfx += -x 4

gfx/trade/ball.2bpp: tools/gfx += --remove-whitespace
gfx/trade/game_boy.2bpp: tools/gfx += --remove-duplicates --preserve=0x23,0x27
gfx/trade/game_boy_cable.2bpp: gfx/trade/game_boy.2bpp gfx/trade/link_cable.2bpp ; cat $^ > $@

gfx/slots/slots_1.2bpp: tools/gfx += --trim-whitespace
gfx/slots/slots_2.2bpp: tools/gfx += --interleave --png=$<
gfx/slots/slots_3.2bpp: tools/gfx += --interleave --png=$< --remove-duplicates --keep-whitespace --remove-xflip

gfx/card_flip/card_flip_1.2bpp: tools/gfx += --trim-whitespace
gfx/card_flip/card_flip_2.2bpp: tools/gfx += --remove-whitespace

gfx/battle_anims/angels.2bpp: tools/gfx += --trim-whitespace
gfx/battle_anims/beam.2bpp: tools/gfx += --remove-xflip --remove-yflip --remove-whitespace
gfx/battle_anims/bubble.2bpp: tools/gfx += --trim-whitespace
gfx/battle_anims/charge.2bpp: tools/gfx += --trim-whitespace
gfx/battle_anims/egg.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/explosion.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/hit.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/horn.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/lightning.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/misc.2bpp: tools/gfx += --remove-duplicates --remove-xflip
gfx/battle_anims/noise.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/objects.2bpp: tools/gfx += --remove-whitespace --remove-xflip
gfx/battle_anims/pokeball.2bpp: tools/gfx += --remove-xflip --keep-whitespace
gfx/battle_anims/reflect.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/rocks.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/skyattack.2bpp: tools/gfx += --remove-whitespace
gfx/battle_anims/status.2bpp: tools/gfx += --remove-whitespace

gfx/player/chris.2bpp: rgbgfx += -Z
gfx/player/chris_back.2bpp: rgbgfx += -Z
gfx/player/kris.2bpp: rgbgfx += -Z
gfx/player/kris_back.2bpp: rgbgfx += -Z

gfx/trainer_card/chris_card.2bpp: rgbgfx += -Z
gfx/trainer_card/kris_card.2bpp: rgbgfx += -Z
gfx/trainer_card/leaders.2bpp: tools/gfx += --trim-whitespace

gfx/overworld/chris_fish.2bpp: tools/gfx += --trim-whitespace
gfx/overworld/kris_fish.2bpp: tools/gfx += --trim-whitespace

gfx/sprites/big_onix.2bpp: tools/gfx += --remove-whitespace --remove-xflip

gfx/battle/dude.2bpp: rgbgfx += -Z

gfx/font/unused_bold_font.1bpp: tools/gfx += --trim-whitespace

gfx/sgb/sgb_border.2bpp: tools/gfx += --trim-whitespace
gfx/sgb/sgb_border.sgb.tilemap: gfx/sgb/sgb_border.bin ; tr < $< -d '\000' > $@

gfx/mobile/ascii_font.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/dialpad.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/dialpad_cursor.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/electro_ball.2bpp: tools/gfx += --remove-duplicates --remove-xflip --preserve=0x39
gfx/mobile/mobile_splash.2bpp: tools/gfx += --remove-duplicates --remove-xflip
gfx/mobile/card.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/card_2.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/card_folder.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/phone_tiles.2bpp: tools/gfx += --remove-whitespace
gfx/mobile/pichu_animated.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/stadium2_n64.2bpp: tools/gfx += --trim-whitespace
gfx/mobile/mobile_adapter.2bpp: tools/gfx += --trim-whitespace


### Catch-all graphics rules

%.2bpp: %.png
	$(RGBGFX) $(rgbgfx) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -o $@ $@)

%.1bpp: %.png
	$(RGBGFX) $(rgbgfx) -d1 -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -d1 -o $@ $@)

%.gbcpal: %.png
	$(RGBGFX) -c embedded -p $@ $<

%.dimensions: %.png
	tools/png_dimensions $< $@
