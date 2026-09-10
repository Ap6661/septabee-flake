{
  description = "A very basic flake to run Septabee";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      meta = {
        description = "A bespoke DAW filled with fruits and where Z stands for Pomegranate";
        platform = [ "${system}" ];
        mainProgram = "septabee";
      };

      version-list = import ./versions.nix;

      icon = pkgs.fetchurl {
        url = "https://septabee.nekoweb.org/important_stuff/icon.png";
        sha256 = "sha256-snq/nOYU2gPzC4VR558VjeQ8oXmQE82IolNDDixvtTU=";
      };

      septabee-pkg =
        {
          wayland-deps ? true,
          version ? version-list.latest_offline,
        }:
        pkgs.stdenv.mkDerivation {
          name = "septabee-${version}";
          version = version;
          src = pkgs.fetchurl {
            url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_${version}.7z";
            sha256 = version-list.hashes.${version};
          };

          runtimeDependencies =
            with pkgs;
            [
              pipewire
              vulkan-loader
            ]
            ++ (lib.optionals wayland-deps [
              wayland
              # kdePackages.wayland # Not sure if this is a hard requirement. cannot test myself
              libxkbcommon
            ]);

          nativeBuildInputs = with pkgs; [
            p7zip
            autoPatchelfHook
          ];

          buildInputs = with pkgs; [
            libpng
            vulkan-loader
            freetype
            pipewire
            libx11
            stdenv.cc.cc.lib
            lilv
            zstd
            ncurses
          ];

          unpackPhase = ''
            runHook preUnpack
            7z x "$src"
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin"
            cp -r ./linux/* "$out/bin/"
            cp -r "$desktopItems/share" "$out"
            runHook postInstall
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "Septabee";
              exec = "septabee";
              icon = icon;
              categories = [
                "AudioVideo"
                "Audio"
                "Music"
                "Midi"
              ];
              desktopName = "S e p t a b e e";
              genericName = "Septabee Digital Audio Workstation";
            })
          ];

          meta = meta;
        };

      septabee-pkgs = {
        default = pkgs.callPackage septabee-pkg { };
        xNoWayland = pkgs.callPackage septabee-pkg { wayland-deps = false; };
      };
    in
    {
      packages.${system} = septabee-pkgs;

      apps.${system} = pkgs.lib.mapAttrs (_: value: {
        inherit meta;
        type = "app";
        program = "${value}/bin/septabee";
      }) septabee-pkgs;

      nixosModules.default =
        { lib, config, ... }:
        let
          cfg = config.programs.septabee;

          make-version-string =
            version: offline:
            let
              offline-suffix = if offline then "_offline" else "";
            in
            if version == "latest" then
              "${version-list.latest}${offline-suffix}"
            else
              "${version}${offline-suffix}";
        in
        {

          options = {
            programs.septabee = {
              enable = lib.mkEnableOption "S E P T A B E E";
              version = lib.mkOption {
                type = lib.types.enum (
                  [ "latest" ]
                  ++ (builtins.filter (name: !(lib.strings.hasSuffix "_offline" name)) (
                    builtins.attrNames version-list.hashes
                  ))
                );
                default = "latest";
                example = [
                  "latest"
                ]
                ++ (builtins.filter (name: !(lib.strings.hasSuffix "_offline" name)) (
                  builtins.attrNames version-list.hashes
                ));
              };
              wayland-deps = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              offline = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              package = lib.mkOption {
                type = lib.types.package;
                default = septabee-pkg {
                  wayland-deps = cfg.wayland-deps;
                  version = make-version-string cfg.version cfg.offline;
                };
              };
            };
          };

          config = lib.mkIf cfg.enable {
            assertions = [
              {
                assertion = lib.traceValSeq (
                  !(version-list.hashes.${make-version-string cfg.version cfg.offline} or null == null)
                );
                message = ''
                  Version ${cfg.version} does not have an offline install, 
                  please set `programs.septabee.offline = false;` or choose a different version.
                '';
              }
            ];

            environment.systemPackages = [ cfg.package ];

            security.wrappers.septabee = {
              owner = "root";
              group = "root";
              permissions = "u-rwx,g=rx,o=rx";
              capabilities = "cap_sys_nice+ep";
              source = "${cfg.package}/bin/septabee";
            };

            security.wrappers.septabee-sounds = {
              owner = "root";
              group = "root";
              permissions = "u-rwx,g=rx,o=rx";
              capabilities = "cap_sys_nice+ep";
              source = "${cfg.package}/bin/septabee-sounds";
            };
          };

        };
    };
}
