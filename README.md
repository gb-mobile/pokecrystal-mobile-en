WIP Pokemon Crystal mobile restoration and localization. Built on Matze's substantial work 
restoring mobile functionality to Pokemon Crystal using code disassembled from the Japanese ROM.

Matze's original project can be found here: https://github.com/Sudel-Matze/pokecrystal

Old version of RGBDS required, 0.3.8 should work.

Primary To-Do List:
- Adjust Easy Chat to function with other languages. Trim word count from 6 to 4 and increase word length from 5 to 8.
- Graphical changes to accomodate other languages.
- Some languages could have minor bugs.
- Testing is needed from native speakers of other languages, preferably anyone able to assess issues in assembly.

To use this properly with an already existing save file for normal Crystal:
- let the emulator create a new save for this mod, start a new game and save once you can
- open your normal Crystal save and the newly created one in a hex editor and replace the first 0x8000 bytes of the new save with the first 0x8000 bytes of your normal Crystal save

# Pokémon Crystal [![Build Status][travis-badge]][travis]

This is a disassembly of Pokémon Crystal.

It builds the following ROMs:

- Pokemon - Crystal Version (UE) (V1.0) [C][!].gbc `sha1: f4cd194bdee0d04ca4eac29e09b8e4e9d818c133`
- Pokemon - Crystal Version (UE) (V1.1) [C][!].gbc `sha1: f2f52230b536214ef7c9924f483392993e226cfb`
- Pokemon - Crystal Version (A) [C][!].gbc `sha1: a0fc810f1d4e124434f7be2c989ab5b5892ddf36`

To set up the repository, see [INSTALL.md](INSTALL.md).

## See also

- [**FAQ**](FAQ.md)
- [**Documentation**][docs]
- [**Wiki**][wiki] (includes [tutorials][tutorials])
- **Discord:** [pret][discord]
- **IRC:** [freenode#pret][irc]

Other disassembly projects:

- [**Pokémon Red/Blue**][pokered]
- [**Pokémon Yellow**][pokeyellow]
- [**Pokémon Gold**][pokegold]
- [**Pokémon Pinball**][pokepinball]
- [**Pokémon TCG**][poketcg]
- [**Pokémon Ruby**][pokeruby]
- [**Pokémon Fire Red**][pokefirered]
- [**Pokémon Emerald**][pokeemerald]

[pokered]: https://github.com/pret/pokered
[pokeyellow]: https://github.com/pret/pokeyellow
[pokegold]: https://github.com/pret/pokegold
[pokepinball]: https://github.com/pret/pokepinball
[poketcg]: https://github.com/pret/poketcg
[pokeruby]: https://github.com/pret/pokeruby
[pokefirered]: https://github.com/pret/pokefirered
[pokeemerald]: https://github.com/pret/pokeemerald
[docs]: https://pret.github.io/pokecrystal/
[wiki]: https://github.com/pret/pokecrystal/wiki
[tutorials]: https://github.com/pret/pokecrystal/wiki/Tutorials
[discord]: https://discord.gg/6EuWgX9
[irc]: https://kiwiirc.com/client/irc.freenode.net/?#pret
[travis]: https://travis-ci.org/pret/pokecrystal
[travis-badge]: https://travis-ci.org/pret/pokecrystal.svg?branch=master

## Primary Contributors

- Matze          : Mobile Restoration & Japanese Code Disassembly

- Darkshade      : Graphics and Project Management
- Ryuzac         : Code and Japanese Translation

- Zumilsawhat?   : Code (Large amounts of work on the EZ Chat system)
- mid-kid        : For his previous work on i18n builds.

- Arves          : Italian Mobile Translation
- Federx         : Italian Mobile Translation
- FerozElMejor   : Spanish Mobile Translation
- FrenchOrange   : French Mobile Translation
- Lesserkuma     : German Mobile Translation
- Muffet         : German Mobile Translation

- REON Community : Support and Assistance
