## Information 

A fork of pokecrystal designed to restore and localize Mobile Adapter functionality such as online battles and trades to Crystal using disassembled code from the Japanese ROM designed for use with Mobile System recreation projects like the REON Project.

The intention of this project is to create a build of pokecrystal with all of the content that was featured in the Japanese version of the game and was cut from the international release(s).
We've been very strict on ensuring that any decisions made on the localization or presentation of this content match the standards of a hypothetical scenario in which the Mobile Adapter was released outside of Japan and Crystal received a complete English release back in 2001.

This repository is built upon a substantial amount of work done by Sudel-Matze.

A link to Matze’s repository can be found here:
https://github.com/Sudel-Matze/pokecrystal

## Screenshots

![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/38f43741-10cb-44e3-adff-2a13f1c1a15c)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/2dcac8d6-9b58-47d6-9b0a-004d112267d0)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/ea64d517-1069-4cdb-a68d-3d657613d16e)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/5959587a-651b-4a45-9511-0977323aaa0a)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/42c3949c-ad17-4452-981d-5bb19647e022)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/a2753b55-920e-4ed9-bcc4-913655fdc87e)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/6c3f6fe9-9362-4f07-b5bf-f1ae785febf9)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/3f056306-7409-4c91-8c84-eb046ef6ba11)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/5cdd65ee-700d-4921-924a-c55ea29bc2ce)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/4942f0e5-8599-4bfb-a149-b06d487d29c7)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/1349bf82-7668-4573-8dce-021792013571)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/46af69c9-da9f-4656-90e4-e46cc5aec4b2)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/040a1f18-441b-4bc7-819c-8fc7ef43f949)
![image](https://user-images.githubusercontent.com/110418063/196129175-eebdad9e-f4a0-44ae-8432-7aa538b3c722.png)
![image](https://github.com/gb-mobile/pokecrystal-mobile-eng/assets/110418063/bd6ae5da-1994-474a-a21e-4b03b837fff5)




## Setup [![Build Status][ci-badge]][ci]

For more information, please see [INSTALL.md](INSTALL.md)

After setup has been completed, you can choose which version you wish to build.
To build a specific version, run one of these commands inside the repository directory in cygwin64:

- US Version:   `make`

- EUR Version:	`make crystal_eu` 

- AUS Version:	`make crystal_au`

For a more accurate experience, we advising picking the build version based on where you live as this will make different 'address' options available to you which are selectable for personal information.

The US Version covers the United States and Canada.

The EUR Version covers all countries in Europe (as of 2001).

The AUS Version covers Australia & New Zealand.

Other languages are being worked on, but are not complete and still require a lot of polish.

## Using Mobile Adapter Features

To take advantage of the Mobile Adapter features, we currently recommend the GameBoy Emulator BGB:
https://bgb.bircd.org/

and libmobile-bgb:
https://github.com/REONTeam/libmobile-bgb/releases

Simply open BGB, right click the ‘screen’ and select `Link > Listen`, then accept the port it provides by clicking `OK`.
Once done, run the latest version of libmobile for your operating system (`mobile-windows.exe` or windows and `mobile-linux` for linux).
Now right click the ‘screen’ on BGB again and select `Load ROM…`, then choose the pokecrystal-mobile `.gbc` file you have built.

## Mobile Adapter Features

A full list of Mobile Adapter features for Pokémon Crystal can be found here:
https://github.com/gb-mobile/pokecrystal-mobile-en/wiki/Pok%C3%A9mon-Crystal-Mobile-Features

## Contributors

- Pret           : Initial disassembly
- Matze          : Mobile Restoration & Japanese Code Disassembly
- Damien         : Code
- DS             : GFX & Code
- Nob Ogasawara  : Consultation on minor menu translations
- Ryuzac         : Code & Japanese Translation
- Vulcandth      : Rebasing and keeping the repo up to date
- Zumilsawhat?   : Code (Large amounts of work on the EZ Chat system)
- REON Community : Support and Assistance

[ci]: https://github.com/pret/pokecrystal/actions
[ci-badge]: https://github.com/pret/pokecrystal/actions/workflows/main.yml/badge.svg
