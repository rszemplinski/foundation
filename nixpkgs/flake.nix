{
  inputs = { home-manager.inputs.nixpkgs.follows = "nixpkgs"; };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    let
      username = "ryan.szemplinski";
      homeDirectory = "/Users/ryan.szemplinski";
    in with builtins;
    flake-utils.lib.eachDefaultSystem (system: {
      packages =
        let inherit (nixpkgs.legacyPackages.${system}.writers) writeBashBin;
        in {
          homeConfigurations.default =
            home-manager.lib.homeManagerConfiguration {
              inherit system username homeDirectory;
              configuration = {
                imports = [
                  ({ lib, ... }: {
                    _module.args = { inherit self username homeDirectory; };
                  })
                  ./home.nix
                ];
              };
            };

          hm = writeBashBin "hm" ''
            ${home-manager.packages.${system}.home-manager}/bin/home-manager \
              --flake ${self}#default \
              "$@"
          '';
          build = writeBashBin "build" "nix run ${self}#hm build";
          switch = writeBashBin "switch" "nix run ${self}#hm switch";
        };
    });
}
