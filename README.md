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

## Install with nix-darwin or Home Manager

Add the flake as an input:

```nix
inputs.tinycast.url = "github:redsuperbat/tinycast-flake";
inputs.tinycast.inputs.nixpkgs.follows = "nixpkgs";
```

Then use the package directly:

```nix
home.packages = [ inputs.tinycast.packages.aarch64-darwin.default ];
# or, in nix-darwin:
environment.systemPackages = [ inputs.tinycast.packages.aarch64-darwin.default ];
```

Or use the overlay and refer to `pkgs.tinycast`:

```nix
nixpkgs.overlays = [ inputs.tinycast.overlays.default ];
```

## Things to know

- **Turn off the built-in updater.** The app cannot update itself inside the read-only
  Nix store. Disable automatic update checks in Tinycast's General settings and update
  through this flake instead (`nix flake update tinycast`).
- **macOS permissions may need granting again after updates.** macOS links permissions
  such as Accessibility and Automation to the app's location. Each update moves the app
  to a new `/nix/store` path, so you may be asked again. Tools that copy apps to a fixed
  location, such as [mac-app-util](https://github.com/hraban/mac-app-util), can help.
- **The app is not modified.** The flake unpacks the upstream `.dmg` and copies the app
  as is, so the original code signature stays valid.

## License

The Nix code in this repository is MIT licensed. Tinycast itself is licensed under
AGPL-3.0-or-later by its authors.
