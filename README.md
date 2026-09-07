```nix
# Realtime Thread Priority 
imports = [ inputs.septabee.nixosModules.x86_64-linux.default ];

# Actually install the package
environment.systemPackages = [ inputs.septabee.packages.x86_64-linux.default ];

# Optionally say no to wayland
environment.systemPackages = [ inputs.septabee.packages.x86_64-linux.xNoWayland ];

# Install a previous version
environment.systemPackages = [ (inputs.septabee.packages.x86_64-linux.default.override { version = "B_T3"; }) ];
```
