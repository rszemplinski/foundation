{ path, pkgs, source }:
with builtins;
with pkgs;
with mylib;
rec {
  hasFiles = fs: words fs != [ ] && all (f: pathExists (file f)) (words fs);
  ifFiles = fs: optional (hasFiles fs);
  ifFilesAndNot = fs: fs2: optional (hasFiles fs && !hasFiles fs2);
  file = f: path + ("/" + f);
  read = f: optionalString (hasFiles f) (readFile (file f));
  hasSource = source != null;

  nle-conf = fixSelfWith (import ./nle.nix) {
    source = path;
    inherit pkgs;
  };
  nleFiles = name:
    ifFilesAndNot
    "${nle-conf.${name}.files or ""} ${nle-conf.${name}.generated or ""}"
    (nle-conf.notFiles or "");

  wrapScriptWithPackages = src: env:
    rec {
      text = read src;
      name = baseNameOf src;
      lines = splitString "\n" text;
      pkgsMark = " with-packages ";
      pkgsLines =
        map (x: splitString pkgsMark x) (filter (hasInfix pkgsMark) lines);
      pkgsNames = flatten (map (x: splitString " " (elemAt x 1)) pkgsLines);
      buildInputs = map (x: getAttrFromPath (splitString "." x) pkgs) pkgsNames
        ++ build-paths;
      makeScriptText = replaceStrings [ "CFG_STORE_PATH" ] [ "${self-source}" ];
      isBash = hasSuffix "bash" (head lines);
      script = stdenv.mkDerivation {
        name = "${name}-unwrapped";
        text = makeScriptText text;
        inherit buildInputs;
        passAsFile = "text";
        dontUnpack = true;
        installPhase = ''
          cp $textPath $out
          chmod +x $out
        '';
      };
      scriptTail = makeScriptText (concatStringsSep "\n" (tail lines));
      contents = if hasSource then
        ''exec ${source}/${src} "$@"''
      else if isBash then
        scriptTail
      else
        ''exec ${script} "$@"'';
      out = writeBashBin name ''
        export PATH_added=${makeBinPath buildInputs}
        export ${pathAdd buildInputs}
        ${contents}
      '';
    }.out;

  fileForPlatform = n: !isLinux && hasInfix "ONLY_LINUX" (read n);
  localfile = file "local.nix";
  local-bin-pkgs = optionalAttrs (hasFiles "bin")
    (mapAttrs (x: _: wrapScriptWithPackages "bin/${x}" { })
      (filterAttrs (n: v: !fileForPlatform "bin/${n}") (readDir (file "bin"))));
  local-bin-paths = attrValues local-bin-pkgs;
  local-nix = rec {
    imported = scopedImport scope localfile;
    scope = mylib // pkgs // { inherit source; };
    result = if isFunction imported then imported scope else imported;
    out = if pathExists localfile then result else null;
  }.out;
  local-nix-paths = ifFiles "local.nix" [ local-nix.paths or local-nix ];
  node-modules-paths = ifFilesAndNot nle-conf.npm.files nle-conf.npm.notFiles
    (lowPrio nle-conf.npm.out);

  pnpm-paths = nleFiles "pnpm" rec {
    package = (pnpm2nix.override { nodejs = nodejs_latest; }).mkPnpmModule rec {
      name = pname;
      pname = "pnpm-modules";
      version = "";
      packageJSON = file "package.json";
      pnpmLock = file "pnpm-lock.lock";
      pnpmNix = file "pnpm.nix";
    };
    out = runCommand "pnpm-env" { passthru = { inherit package; }; } ''
      mkdir $out
      [[ -e ${package}/node_modules/.bin ]] && ln -s ${package}/node_modules/.bin $out/bin
      ln -s ${package}/node_modules $out/node_modules
    '';
  }.out;

  mach-nix-paths = with rec {
    hasRequirements = pathExists (file "requirements.txt");
    hasRequirementsDev = pathExists (file "requirements.dev.txt");
  };
    optional nle-conf.pip.out;

  build-paths =
    flatten [ local-nix-paths node-modules-paths pnpm-paths mach-nix-paths ];

  paths = flatten [ local-bin-paths build-paths ];

  packages = listToAttrs (map (x: {
    name = x.name;
    value = x;
  }) build-paths) // local-bin-pkgs;

  out = buildEnv {
    name = "local-env";
    inherit paths;
    ignoreCollisions = true;
    passthru = {
      inherit paths;
      pkgs = packages;
    };
  };
}.out
