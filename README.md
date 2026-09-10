```nix

imports = [
    inputs.septabee.nixosModules.default
];

# Septabee's options and their defaults
programs.septabee = {
    enable = false; 
    wayland-deps = true; # Install wayland only dependencies 
    version = "latest"; # like [ "latest" "B_T1" "B_T2" ... ]
    offline = true; # Doesn't require downloading LLVM stuff

    package = pkgs.septabee # Septabee of version + wayland-deps
};

```
