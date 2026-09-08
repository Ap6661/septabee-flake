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

    depends = with pkgs; [
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

    waylandDepends = with pkgs; [
      wayland
      # kdePackages.wayland ## Not sure if this is a hard requirement. cannot test myself
      libxkbcommon
    ];

    runtimeDependencies = with pkgs; [
      pipewire
      vulkan-loader
    ];

    version = "B_T5_offline";

    hashes = {
      "B_T1" = "sha256-JlWmeDnMTjBNwLTADvSswbtfhJK6t1bu0xHkmBgLtvA=";
      "B_T2" = "sha256-OMnbRBTku8yi4b3Ay7d70EbB/e2Qh+PfzK2O8qRFoaA=";
      "B_T3" = "sha256-vdXJ4Qusvi/ehztmp2iibiFZLJvbU7+mRnR7KSmxrFA=";
      "B_T4" = "sha256-Uuu3g11TCczOSDx15AqEJTosPkPjBNaWjBAPFf8uNw8=";
      "B_T5" = "sha256-dBEdBy8PChrAxiTLYoIdOqTg77UsTGoogKhV1o6eiAk=";
      "B_T5_offline" = "sha256-+c8RUdz1EIPhubxDFYfhnevQN0v4cRKDQ2bcRmLn4sk=";
    };

    icon = pkgs.fetchurl {
      url = "https://septabee.nekoweb.org/important_stuff/septabee.png";
      sha256 = "sha256-eOi7RpU4niZoFjg3bw1NOYj9U96YxOr2TGj8d37D5FY=";
    };

    septabee-pkg = pkgs.stdenv.mkDerivation {
        name = "septabee-${version}";
        version = version;
        src = pkgs.fetchurl {
          url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_${version}.7z";
          sha256 = hashes.${version};
        };

        runtimeDependencies = waylandDepends ++ runtimeDependencies; 

        nativeBuildInputs = with pkgs; [
          p7zip
          autoPatchelfHook
        ];

        buildInputs = depends;

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
            desktopName = "Septabee DAW";
            genericName = "Septabee Digital Audio Workstation";
          })
        ];

        meta = meta;
    };

    septabeeXNoWayland = septabee-pkg.overrideAttrs {
      runtimeDependencies = runtimeDependencies;
    };
  in
  {
    packages.${system} = {
      default = septabee-pkg;
      xNoWayland = septabeeXNoWayland;
    };

    apps.${system} = {
      default = {
        type = "app";
        program = "${septabee-pkg}/bin/septabee";
        meta = meta;
      };

      xNoWayland = {
        type = "app";
        program = "${septabeeXNoWayland}/bin/septabee";
        meta = meta;
      };
    };

    nixosModules.${system}.default = { ... }: {
      security.wrappers.septabee = {
        owner = "root";
        group = "root";
        permissions = "u-rwx,g=rx,o=rx";
        capabilities = "cap_sys_nice+ep";
        source = "${septabee-pkg}/bin/septabee";
      };

      security.wrappers.septabee-sounds = {
        owner = "root";
        group = "root";
        permissions = "u-rwx,g=rx,o=rx";
        capabilities = "cap_sys_nice+ep";
        source = "${septabee-pkg}/bin/septabee-sounds";
      };
    };
  };
}
