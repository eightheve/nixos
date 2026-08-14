# Sana's NixOS Configuration

Multi-host Nixos flake-based configuration

## Paradigm
This flake is based on a multi-layer system made up of `modules`, `profiles`, and `hosts`. Each layer composes the previous layers along with plain NixOS options in order to construct a single coherent system or feature. Most options provided by this flake are under the local namespace `config.site`.

- `modules` compose plain NixOS options together to construct one single scoped feature
- `profiles` are made of both `module` and NixOS options, and are meant to be applied to entire classes of host based on role or hardware.
- `hosts` are meant to define all of the options necessary to construct individual usable systems.

All modules and profiles are imported unconditionally, and so all contain `options.`and conditionally applied `config.` sections. 

## Graphics

The only WM offered is `dwm`, with minimal patches and configuration. There is no display manager, the intended usage is to log in via the tty and run `startx`.

## Directory Structure

- `assets/` images and other binary files
- `colors/` per-file nix attribute sets containing color schemes
- `hosts/` contains subdirectories which are searched for when building systems. e.g. the host `#PASSENGER` will look for `hosts/PASSENGER/default.nix`
- `modules/` unconditionally imported module declarations
- `overlays/` nixpkgs overlays
- `packages/` self contained package declarations
- `profiles/` unconditionally imported profile declarations
- `secrets/` contains agenix secrets, not currently used
- `users/` unconditionally imported user declarations

## Hosts

### Active

| Host      | Role                | Hardware         |
| :-------: | :-----------------: | :--------------: |
| PASSENGER | Desktop/Workstation | Custom Tower     |
| SATELLITE | Laptop/Workstation  | ThinkPad X1 Yoga |
| SAOTOME   | Home Server/NAS     | Dell R720        |
| KAZOOIE   | VPS Entrypoint      | N/A              |

### Inactive

| Host | Role        | Hardware     |
| :--: | :---------: | :----------: |
| HIME | Home Server | HP DL360P G8 |

## To-Do
- [ ] General code review cleanup
- [ ] Tighten security on KAZOOIE
- [ ] Properly integrate agenix
- [ ] Possibly integrate some of my external flakes directly into this config
