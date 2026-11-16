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
# Home Manager: installs to ~/Applications/Tinycast.app
imports = [ inputs.tinycast.homeManagerModules.default ];

# or nix-darwin: installs to /Applications/Tinycast.app for system.primaryUser
imports = [ inputs.tinycast.darwinModules.default ];

programs.tinycast = {
  enable = true;
  launcherShortcut = "option+space"; # optional
};
```

The module:

- **Installs the app at a fixed path.** macOS ties permissions such as Accessibility and
  Automation to an app's location. The module copies Tinycast out of the Nix store, so
  updates keep the same path and you don't have to grant permissions again. It copies
  only when the version changes.
- **Turns off the built-in updater.** Updates come through this flake instead: run
  `nix flake update tinycast`. Quit and reopen Tinycast after an update.
- **Sets the launcher shortcut**, if you give one. Write modifiers and a key joined by
  `+`. Modifiers: `cmd`, `shift`, `option` (or `alt`), `ctrl`. Keys: `a`–`z`, `0`–`9`,
  `space`, `return`, `tab`, `escape`, `f1`–`f12`. If you leave it out, you set the
  shortcut in Tinycast's settings as usual.

Both settings are written to Tinycast's preferences on every switch, so changes made in
the app are replaced by your Nix config.

If you only want the package, use `inputs.tinycast.packages.aarch64-darwin.default`, or
add `inputs.tinycast.overlays.default` to `nixpkgs.overlays` and refer to `pkgs.tinycast`.

## Things to know

- **The app is not modified.** The flake unpacks the upstream `.dmg` and copies the app
  as is, so the original code signature stays valid.
- **The plain package runs from the Nix store.** If you use the package or overlay
  without a module, macOS may ask for permissions again after each update.

## License

The Nix code in this repository is MIT licensed. Tinycast itself is licensed under
AGPL-3.0-or-later by its authors.
