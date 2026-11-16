{
  description = "Tinycast, a native macOS app launcher";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
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
    in
    {
      overlays.default = final: prev: { tinycast = final.callPackage package { }; };

      packages.aarch64-darwin = rec {
        tinycast = nixpkgs.legacyPackages.aarch64-darwin.callPackage package { };
        default = tinycast;
      };
    };
}
