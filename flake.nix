{
  description = "A helper for screenshots within Hyprland, based on grimshot";

  inputs.nixpkgs = {
    type = "indirect";
    id = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlay];
      });
  in {
    # A Nixpkgs overlay.
    overlay = _: prev: {
      moonblast = prev.callPackage ./default.nix {hyprland = null;};
    };

    # Provide some binary packages for selected system types.
    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) moonblast;
    });

    # The default package for 'nix build'. This makes sense if the
    # flake provides only one package or there is a clear "main"
    # package.
    defaultPackage = forAllSystems (system: self.packages.${system}.moonblast);

    # A NixOS module, if applicable (e.g. if the package provides a system service).
    nixosModules.moonblast = {pkgs, ...}: {
      nixpkgs.overlays = [self.overlay];

      environment.systemPackages = [pkgs.moonblast];

      #systemd.services = { ... };
    };

    # Tests run by 'nix flake check' and by Hydra.
    checks =
      forAllSystems
      (
        system:
          with nixpkgsFor.${system};
            {
              inherit (self.packages.${system}) moonblast;

              # Additional tests, if applicable.
              test = stdenv.mkDerivation {
                name = "moonblast-test-${version}";

                buildInputs = [moonblast];

                unpackPhase = "true";

                buildPhase = ''
                  moonblast
                '';

                installPhase = "mkdir -p $out";
              };
            }
            // lib.optionalAttrs stdenv.isLinux {
              # A VM test of the NixOS module.
              vmTest = with import (nixpkgs + "/nixos/lib/testing-python.nix") {
                inherit system;
              };
                makeTest {
                  nodes = {
                    client = {...}: {
                      imports = [self.nixosModules.moonblast];
                    };
                  };

                  testScript = ''
                    start_all()
                    client.wait_for_unit("multi-user.target")
                    client.succeed("moonblast")
                  '';
                };
            }
      );
  };
}
