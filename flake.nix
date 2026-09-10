{
  description = "A very basic flake to run Septabee";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
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

    hashes = {
      "B_T1" = "sha256-JlWmeDnMTjBNwLTADvSswbtfhJK6t1bu0xHkmBgLtvA=";
      "B_T2" = "sha256-OMnbRBTku8yi4b3Ay7d70EbB/e2Qh+PfzK2O8qRFoaA=";
      "B_T3" = "sha256-vdXJ4Qusvi/ehztmp2iibiFZLJvbU7+mRnR7KSmxrFA=";
      "B_T4" = "sha256-Uuu3g11TCczOSDx15AqEJTosPkPjBNaWjBAPFf8uNw8=";
      "B_T5" = "sha256-dBEdBy8PChrAxiTLYoIdOqTg77UsTGoogKhV1o6eiAk=";
      "B_T5_offline" = "sha256-+c8RUdz1EIPhubxDFYfhnevQN0v4cRKDQ2bcRmLn4sk=";
      "B_T6" = "sha256-tkBRI8GcpOjtZs9sA0ycIPeq6eaFjDVH2YBfTXl7Leo=";
      "B_T6_offline" = "sha256-f2oR3nxSrBZHPhPN0eWWZlbFSQa34EWBEDyQmoRjvAA=";
      "B_T7" = "sha256-+BRkf4TrJZqCjnQmUg0sMoJTsmnSyXiXNovTKo72k54=";
      "B_T7_offline" = "sha256-tVxMALnZewmrKTWnn5C0mNmvfM84scScbwGl0Hfk+LA=";
    };

    icon = pkgs.fetchurl {
      url = "https://septabee.nekoweb.org/important_stuff/icon.png";
      sha256 = "sha256-snq/nOYU2gPzC4VR558VjeQ8oXmQE82IolNDDixvtTU=";
    };

    latest_offline = "B_T7_offline";

    septabee-pkg = {
      wayland-deps ? true,
      version ? latest_offline
    }:
    pkgs.stdenv.mkDerivation {
        name = "septabee-${version}";
        version = version;
        src = pkgs.fetchurl {
          url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_${version}.7z";
          sha256 = hashes.${version};
        };

        runtimeDependencies = with pkgs; [
          pipewire
          vulkan-loader
        ] ++ (lib.optionals wayland-deps [
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
      default = pkgs.callPackage septabee-pkg {};
      xNoWayland = pkgs.callPackage septabee-pkg { wayland-deps = false; };
    };
  in
  {
    packages.${system} = septabee-pkgs;

    apps.${system} = pkgs.lib.mapAttrs (_: value: { inherit meta; type = "app"; program = "${value}/bin/septabee"; }) septabee-pkgs;

    nixosModules.${system}.default = { lib, config, ... }: 
    let
      cfg = config.programs.septabee;
    in
    {

      options = {
        programs.septabee = {
          enable = lib.mkEnableOption "S E P T A B E E";
          version = lib.mkOption {
            type = lib.types.str;
            default = latest_offline;
            example = builtins.attrNames hashes;
          };
          wayland-deps = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = septabee-pkg {
              wayland-deps = cfg.wayland-deps;
              version = cfg.version;
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
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
