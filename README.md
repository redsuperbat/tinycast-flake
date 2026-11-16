# tinycast-flake

A Nix flake for [Tinycast](https://tinycast.dev/), a native macOS app launcher and
open-source alternative to Raycast. Tinycast is not in nixpkgs, so this flake packages
the official, signed and notarized release from
[abue-ammar/tinycast](https://github.com/abue-ammar/tinycast).

- **Platform:** Apple Silicon (`aarch64-darwin`) only. Tinycast needs macOS 26 or later.
- **Updates:** a GitHub Action checks for new Tinycast releases every day and updates
  the version and hash in `flake.nix` after a successful build.

## Try it

```sh
nix build github:redsuperbat/tinycast-flake
open result/Applications/Tinycast.app
```

## Install with Home Manager or nix-darwin

Add the flake as an input:

```nix
inputs.tinycast.url = "github:redsuperbat/tinycast-flake";
inputs.tinycast.inputs.nixpkgs.follows = "nixpkgs";
```

Then import the module for your setup and enable it:

```nix
# Home Manager
imports = [ inputs.tinycast.homeManagerModules.default ];
programs.tinycast.enable = true;

# or nix-darwin (the setting applies to system.primaryUser)
imports = [ inputs.tinycast.darwinModules.default ];
programs.tinycast.enable = true;
```

The module installs Tinycast and turns off its built-in updater. The updater cannot
replace an app in the read-only Nix store, so updates come through this flake instead:
run `nix flake update tinycast`.

If you only want the package, use `inputs.tinycast.packages.aarch64-darwin.default`, or
add `inputs.tinycast.overlays.default` to `nixpkgs.overlays` and refer to `pkgs.tinycast`.

## Things to know

- **macOS permissions may need granting again after updates.** macOS links permissions
  such as Accessibility and Automation to the app's location. Each update moves the app
  to a new `/nix/store` path, so you may be asked again. Tools that copy apps to a fixed
  location, such as [mac-app-util](https://github.com/hraban/mac-app-util), can help.
- **The app is not modified.** The flake unpacks the upstream `.dmg` and copies the app
  as is, so the original code signature stays valid.

## License

The Nix code in this repository is MIT licensed. Tinycast itself is licensed under
AGPL-3.0-or-later by its authors.
