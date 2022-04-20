prev: with prev; with lib; with builtins;
cli // generators // lib // builtins // rec {
  inherit (writers) writeBash writeBashBin;
  ap = x: f: f x;
  mapAttrValues = f: mapAttrs (n: v: f v);
  inherit (stdenv) isLinux isDarwin;
  sources = import ./nix/sources.nix { inherit system pkgs; };
  alias = name:
    if isString name
    then arg:
      let
        cmd = if isDerivation arg then exe arg else arg;
        pre = if any (s: hasInfix s arg) [ "&&" "||" ";" "|" "\n" ] then "" else "exec";
        post = if any (s: hasInfix s arg) [ ''"$@"'' "\n" ] then "" else ''"$@"'';
      in
      writeBashBin name "${pre} ${cmd} ${post}"
    else mapAttrs alias name;
}