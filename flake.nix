{
  description = "helper for screenshots within Hyprland, based on grimshot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: function nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forAllSystems (pkgs: {
        moonblast = pkgs.callPackage ./default.nix { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.moonblast;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });

      overlays.default = final: _: { moonblast = final.callPackage ./default.nix { }; };
    };
}
