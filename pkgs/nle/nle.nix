{ self, source, pkgs }:
with pkgs;
with mylib;
with self.lib; {
  lib = {
    file = f: source + ("/" + f);
    fileExistBools = fs: map pathExists (words fs);
    read = f: let p = file f; in optionalString (pathExists p) (readFile p);
    matches =
      { enable ? false, files ? "", extraFiles ? "", generated ? "", ... }:
      enable && all (fileExistBools "${files} ${generated}")
      || any (fileExistBools extraFiles);
  };

  bin = { files = "bin"; };
  niv = { files = "nix"; };
  npm = {
    files = "package.json package-lock.json .enable-nle-npm";
    extraFiles = ".npmrc";
    notFiles = "pnpm-lock.lock";
    out = npmlock2nix.node_modules {
      pname = "node_modules";
      version = "0.0.0";
      src = buildDir (map file (words self.npm.files));
    };
  };
  pnpm = {
    files = "package.json pnpm-lock.lock .enable-nle-pnpm";
    generated = "pnpm.nix";
    extraFiles = ".npmrc";
  };
  pip = {
    enable = true;
    files = "requirements.txt";
    extraFiles = "requirements.dev.txt";
    out = override (inputs.mach-nix.lib.${system}.mkPython {
      ignoreDataOutdated = true;
      ignoreCollisions = true;
      requirements = excludeLines (hasPrefix "itomate") ''
        ${read "requirements.txt"}
        ${read "requirements.dev.txt"}
      '';
      _.curtsies.patches = [ ];
    }) { name = "pip-env"; };
  };
  nix = { extraFiles = "default.nix flake.nix flake.lock local.nix"; };
  nixpkgs = { extraFiles = "config.nix overlays.nix"; };
  pkgs = { files = "pkgs"; };
}
