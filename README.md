```nix

imports = [
    inputs.septabee.nixosModules.x86_64-linux.default
];

programs.septabee = {
    enable = true; # Install and enable realtime thread priority
    wayland-deps = false; # Don't install wayland dependencies
    version = "B_T7_offline"; # Default is latest
};

```
