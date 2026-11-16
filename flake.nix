{
  description = "Tinycast, a native macOS app launcher";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      bundleId = "com.abueammar.tinycast";
      package = { lib, stdenvNoCC, fetchurl, _7zz }:
        stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "tinycast";
          version = "0.12.15";

          src = fetchurl {
            url = "https://github.com/abue-ammar/tinycast/releases/download/v${finalAttrs.version}/Tinycast-${finalAttrs.version}.dmg";
            hash = "sha256-6ZFd23uDOUKGZOIsWuHRa1BrtLr39x1JbDfbBuf0RYk=";
          };

          # APFS dmg, which undmg cannot read.
          nativeBuildInputs = [ _7zz ];
          sourceRoot = "Tinycast.app";

          installPhase = ''
            runHook preInstall
            mkdir -p $out/Applications/Tinycast.app
            cp -R . $out/Applications/Tinycast.app
            runHook postInstall
          '';

          # Keep the upstream code signature intact.
          dontFixup = true;

          meta = {
            description = "Native macOS app launcher (Raycast alternative)";
            homepage = "https://tinycast.dev/";
            license = lib.licenses.agpl3Plus;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            platforms = [ "aarch64-darwin" ];
          };
        });

      options = lib: {
        enable = lib.mkEnableOption "Tinycast";
        launcherShortcut = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "cmd+space";
          description = ''
            Global shortcut that opens Tinycast, as modifiers and a key joined by "+".
            Modifiers: cmd, shift, option (alt), ctrl. Keys: a-z, 0-9, space, return,
            tab, escape, f1-f12. Null leaves the shortcut to the app's settings.
          '';
        };
      };

      # ANSI virtual key codes, as Carbon stores them.
      keyCodes = {
        a = 0; s = 1; d = 2; f = 3; h = 4; g = 5; z = 6; x = 7; c = 8; v = 9; b = 11;
        q = 12; w = 13; e = 14; r = 15; y = 16; t = 17; "1" = 18; "2" = 19; "3" = 20;
        "4" = 21; "6" = 22; "5" = 23; "9" = 25; "7" = 26; "8" = 28; "0" = 29; o = 31;
        u = 32; i = 34; p = 35; return = 36; l = 37; j = 38; k = 40; n = 45; m = 46;
        tab = 48; space = 49; escape = 53; f1 = 122; f2 = 120; f3 = 99; f4 = 118;
        f5 = 96; f6 = 97; f7 = 98; f8 = 100; f9 = 101; f10 = 109; f11 = 103; f12 = 111;
      };
      modifierBits = { cmd = 256; shift = 512; option = 2048; alt = 2048; ctrl = 4096; };

      # Tinycast keeps its settings in UserDefaults, so these leave the app unmodified.
      preferences = lib: cfg:
        let
          parts = lib.splitString "+" cfg.launcherShortcut;
          lookup = table: kind: name: table.${name}
            or (throw "programs.tinycast.launcherShortcut: unknown ${kind} '${name}'");
          shortcut = {
            combo._0 = {
              carbonKeyCode = lookup keyCodes "key" (lib.last parts);
              carbonModifiers = lib.foldl' builtins.bitOr 0
                (map (lookup modifierBits "modifier") (lib.init parts));
            };
          };
        in
        # The built-in updater cannot replace an app managed by Nix.
        { automaticallyCheckForUpdates = false; }
        // lib.optionalAttrs (cfg.launcherShortcut != null) {
          "hotkey.togglePalette" = builtins.toJSON shortcut;
        };

      # macOS ties permissions such as Accessibility to the app's path, so copy the
      # app to a fixed location instead of running it from a changing /nix/store path.
      copyApp = pkg: dest: ''
        src=${pkg}/Applications/Tinycast.app
        dest="${dest}"
        if ! cmp -s "$src/Contents/Info.plist" "$dest/Contents/Info.plist" \
          || ! cmp -s "$src/Contents/_CodeSignature/CodeResources" "$dest/Contents/_CodeSignature/CodeResources"; then
          echo "Installing Tinycast to $dest"
          rm -rf "$dest"
          mkdir -p "$(dirname "$dest")"
          cp -R "$src" "$dest"
          chmod -R u+w "$dest"
        fi
      '';
    in
    {
      overlays.default = final: prev: { tinycast = final.callPackage package { }; };

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.tinycast; in {
          options.programs.tinycast = options lib;
          config = lib.mkIf cfg.enable {
            targets.darwin.defaults.${bundleId} = preferences lib cfg;
            home.activation.tinycast = lib.hm.dag.entryAfter [ "writeBoundary" ]
              (copyApp (pkgs.callPackage package { }) "$HOME/Applications/Tinycast.app");
          };
        };

      darwinModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.tinycast; in {
          options.programs.tinycast = options lib;
          config = lib.mkIf cfg.enable {
            # Applies to system.primaryUser.
            system.defaults.CustomUserPreferences.${bundleId} = preferences lib cfg;
            system.activationScripts.postActivation.text = lib.mkAfter
              (copyApp (pkgs.callPackage package { }) "/Applications/Tinycast.app");
          };
        };

      packages.aarch64-darwin = rec {
        tinycast = nixpkgs.legacyPackages.aarch64-darwin.callPackage package { };
        default = tinycast;
      };
    };
}
