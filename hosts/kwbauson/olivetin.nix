{ pkgs, ... }:
let olivetin = with pkgs; with mylib; stdenv.mkDerivation {
  pname = "olivetin";
  version = sources.olivetin.version;
  src = sources.olivetin;
  nativeBuildInputs = [ autoPatchelfHook ];
  config = ''
    listenAddressSingleHTTPFrontend: localhost:1337
    actions:
      - title: Restart Jitsi
        icon: "&#128577;"
        shell: systemctl restart prosody jitsi-meet-init-secrets jicofo jitsi-videobridge2
        timeout: 10

      - title: Reboot Server
        icon: "&#128683;"
        shell: reboot
  '';
  passAsFile = "config";
  installPhase = ''
    cp -r . $out
    cp $configPath $out/config.yaml
  '';
};
in
{
  systemd.services.olivetin = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      export "PATH=/run/current-system/sw/bin:$PATH"
      cd ${olivetin}
      exec ./OliveTin
    '';
  };
}