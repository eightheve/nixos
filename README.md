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
| SATELLITE | Laptop Workstation  | Mobile      | ThinkPad X1 Yoga        |
| CASTLE    | Laptop              | Mobile      | Dell Latitude E6420-XFR |
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
- [ ] Vintagestory server hosting for Wokestory group
- [ ] Change GARDEN's name. I'm not happy with it, I just can't come up with anything better right now.
- [ ] Buy a SIM card for GARDEN
- [ ] Add options for Niri for using SATELLITE and GARDEN in touchscreen/pen mode. Gesture support would be nice
- [ ] Move all rack servers (SAOTOME, HAMUKO, NYANKO, HIME, and another secret one that's missing RAM right now) to a closet. I bought a new DAS and the fans for all 4 machines running at once are getting too loud to sleep next to. 
