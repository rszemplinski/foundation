{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mach-nix.inputs.nixpkgs.follows = "nixpkgs";
    mach-nix.inputs.flake-utils.follows = "flake-utils";
    mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";
    pypi-deps-db.url = "github:DavHau/pypi-deps-db";
    pypi-deps-db.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages =
        let inherit (nixpkgs.legacyPackages.${system}.writers) writeBashBin;
        in {
          homeConfigurations.default =
            home-manager.lib.homeManagerConfiguration {
              inherit system;
              username = "ryan.szemplinski"; # UPDATE
              homeDirectory = "/Users/ryan.szemplinski"; # UPDATE
              configuration = { pkgs, ... }: {
                imports = [
                  ({ lib, ... }: {
                    _module.args = {
                      inherit self;
                    } // {
                      pkgs = lib.mkForce pkgs;
                    };
                  })
                  ./home.nix
                ];
                home.packages = with pkgs; [ hello ];
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
