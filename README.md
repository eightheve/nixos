# EighthEve's NixOS Configuration(s)

Multi-host NixOS flake configuration. Will forever be a work in progress, but is especially WIP right now.

## Paradigm/motivation
This flake config is based on modules which provide options which are managed by hosts, all system modules are under config.myModules (stupid sounding name...), all users under config.myUsers, and all home manager modules are available under config.home-manager.users.[user].homeModules. 
The flake itself is minimal, it just generates a configuration that automatically imports the necessary modules as well as the host's default.nix file, which is the main entry point for each system, enabling each module and user that the system needs. Each module should be self contained, except maybe all the complex interdependencies of graphical systems, which are managed a little less well.

## Graphics
Currently there are two WMs offered, Hyprland and DWM. Both are offered as user-level home manger modules, intended to be run from the TTY via `Hyprland` or `startx` respectively. No display manager is available, and I don't plan on adding one. The hyprland module is specifically optimized for my dual-monitor desktop, and the dwm module will only really look good on a single monitor.

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
- [ ] Make Hyprland module universal, so it can be installed on SATELLITE as backup
- [ ] Make DWM module universal, so it can be installed on PASSENGER as backup
- [ ] Make Hyprland and DWM modules have complete environments
- [ ] Swap out dwm's babashka status bar for something written in C or Zig. 100mb of memory is unacceptable for a status bar despite how much I love Clojure...
