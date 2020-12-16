final: prev: with prev; with lib; with builtins; lib // rec {
  mapAttrValues = f: mapAttrs (n: v: f v);
  inherit (stdenv) isLinux isDarwin;
  sources = import ./nix/sources.nix { inherit system pkgs; };
  exe = pkg: with {
    binName =
      if hasAttr "pname" pkg then pkg.pname
      else if hasAttr "version" pkg then removeSuffix "-${pkg.version}" pkg.name
      else pkg.name;
  }; "${pkg}/bin/${binName}";
  prefixIf = b: x: y: if b then x + y else y;
  mapLines = f: s: concatMapStringsSep "\n"
    (l: if l != "" then f l else l)
    (splitString "\n" s);
  words = splitString " ";
  attrIf = check: name: if check then name else null;
  drvs = x: if isDerivation x || isList x then flatten x else flatten (mapAttrsToList (_: v: drvs v) x);
  drvsExcept = x: e: with {
    excludeNames = concatMap attrNames (attrValues e);
  }; flatten (drvs (filterAttrsRecursive (n: _: !elem n excludeNames) x));
  userName = "Keith Bauson";
  userEmail = "kwbauson@gmail.com";
  nixpkgs-branch = let urlParts = splitString "/" (import ./flake.nix).inputs.nixpkgs.url; in
    if length urlParts == 3 then elemAt urlParts 2 else "master";
  fakePlatform = x: x.overrideAttrs (attrs:
    { meta = attrs.meta or { } // { platforms = stdenv.lib.platforms.all; }; }
  );
  excludeLines = f: text: concatStringsSep "\n" (filter (x: !f x) (splitString "\n" text));
  unpack = src: stdenv.mkDerivation {
    src = if src ? url && src ? sha256 then fetchurl { inherit (src) url sha256; } else src;
    name = src.name or "source";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mv $PWD $out
    '';
  };
  runBin = name: script: runCommand
    name
    { } ''
    mkdir -p $out/bin
    ${exe (writeShellScriptBin "script" script)} > $out/bin/${name}
    chmod +x $out/bin/${name}
  '';
  desc = pkg: (x: trace "\n${concatStringsSep "\n" x}" null) [
    "  name: ${pkg.name or pkg.pname or "null"}"
    "  description: ${pkg.meta.description or "null"}"
    "  homepage: ${pkg.meta.homepage or "null"}"
  ];
  alias = name: x: writeShellScriptBin name ''exec ${if isDerivation x then exe x else x} "$@"'';
  mkDmgPackage = pname: src: stdenv.mkDerivation {
    name = pname + (if src ? version then "-${src.version}" else "");
    inherit pname src;
    ${attrIf (src ? version) "version"} = src.version;
    dontUnpack = true;
    nativeBuildInputs = [ undmg ];
    installPhase = ''
      mkdir -p $out/{Applications,bin}
      undmg "$src"
      mv *.app $out/Applications
      appdir=$(echo $out/Applications/*.app)
      [[ -d $appdir ]] || exit 1
      exe=$appdir/Contents/MacOS/${pname}
      if [[ -e $exe ]];then
        echo '#!/bin/sh' > $out/bin/${pname}
        echo "exec \"$exe\" \"\$@\"" >> $out/bin/${pname}
        chmod +x $out/bin/${pname}
      fi
    '';
  };
  dmgOverride = name: pkg: with rec {
    src = sources."dmg-${name}";
    msg = "${name}: src ${src.version} != pkg ${pkg.version}";
    checkVersion = lib.assertMsg (pkg.version == src.version) msg;
  }; if isDarwin then assert checkVersion; (mkDmgPackage name src) // { originalPackage = pkg; } else pkg;
  importNixpkgs = src: import src { inherit system; overlays = [ ]; };
  buildDir = paths:
    let cmds = concatMapStringsSep "\n" (p: "cp -r ${p} $out/${baseNameOf p}") (toList paths);
    in runCommand "build-dir" { } "mkdir $out\n${cmds}";
  copyPath = path: runCommand (baseNameOf path) { } "cp -Lr ${path} $out && chmod -R +rw $out";
  nodeEnv = callPackage "${sources.node2nix}/nix/node-env.nix" { nodejs = nodejs_latest; };
  pathAdd = pkgs: "PATH=${concatMapStringsSep ":" (pkg: "${pkg}/bin") (toList pkgs)}:$PATH";
  nixos-unstable-channel = importNixpkgs (unpack sources.nixos-unstable-channel);
  makeScript = name: script: writeShellScriptBin name (if isDerivation script then ''exec ${script} "$@"'' else script);
  makeScripts = mapAttrs makeScript;
  echo = text: writeShellScript "echo-script" ''echo "$(< ${writeText "text" text})"'';
  override = x: y:
    if x == null then y
    else if y ? _replace then y._replace
    else if isString x && isString y then x + y
    else if isList x && isList y then x ++ y
    else if isDerivation x && isAttrs y then
      override x.overrideAttrs y
    else if isFunction x && isAttrs y then
      x (attrs: mapAttrs (n: v: if hasAttr n attrs then override attrs.${n} v else v) y)
    else if isAttrs x && isAttrs y then
      mapAttrs (n: v: if hasAttr n y then override v y.${n} else v) (y // x)
    else throw "don't know how to override";
} // builtins
