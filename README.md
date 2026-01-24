# EighthEve's NixOS Configuration(s)

Multi-host NixOS flake configuration. Will forever be a work in progress, but is especially WIP right now.

## Paradigm/motivation
This flake config is based on modules which provide options which are managed by hosts, all system modules are under config.myModules (stupid sounding name...), all users under config.myUsers, and all home manager modules are available under config.home-manager.users.[user].homeModules. 
The flake itself is minimal, it just generates a configuration that automatically imports the necessary modules as well as the host's default.nix file, which is the main entrypoint for each system, enabling each module and user that the system needs. Each module should be self contained, except maybe all the complex interdependencies of graphical systems, which are managed a little less well. DWM is included with this flake as a home-module option, since the intended use would be to declare an `~/.xinitrc` file and then use `startx`, instead of needing a display manager.

## Directory Structure
- `common.nix`: shared configuration across all systems (i18n, base packages, etc.)
- `hosts/`: per-host system configs (`default.nix`/`hardware.nix`)
- `users/`: per-user modules
- `modules/`: standalone reusable modules
	+ `modules/nixos/`: system-level modules
	+ `modules/home/`: Home Manager modules

## Hosts

### ACTIVE
| Host      | Role                | Location    | Model                   |
| :-------- | :-----------------: | :---------: | :---------------------: |
| PASSENGER | Desktop/Workstation | Home        | Custom Build            |
| SATELLITE | Laptop Workstation  | Mobile      | ThinkPad Yoga 260       |
| SAOTOME   | Home Server/NAS     | Home        | Dell R720               |
| KAZOOIE   | Proxy for SAOTOME   | VA (VPS)    | N/A                     |
| HAMUKO    | Build Server        | Home        | HP ProLiant DL360P Gen8 |
| NYANKO    | Build Server        | Home        | HP ProLiant DL360P Gen8 |
| HIME      | Build Server        | Home        | HP ProLiant DL360P Gen8 |

### INACTIVE
| Host      | Role                | Location    | Model                   |
| :-------- | :-----------------: | :---------: | :---------------------: |
| BANJO     | Future Pi-hole host | Home        | ThinkCentre M715Q       |

## To-Do
- [ ] Move Pi-hole to BANJO
- [ ] Vintagestory server hosting for Runovaris
- [ ] Minecraft server hosting for roommate
