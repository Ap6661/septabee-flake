```nix

imports = [
    inputs.septabee.nixosModules.x86_64-linux.default
];

programs.septabee = {
    enable = true; # Install and enable realtime thread priority
    wayland-deps = true; # Install wayland dependencies (default)
    version = "latest_offline"; # Default is latest_offline (default)
};

```
