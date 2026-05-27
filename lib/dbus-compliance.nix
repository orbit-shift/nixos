{ config, pkgs, lib, ... }: {
  options.services.dbus.complianceDiagnostics.enable =
    lib.mkEnableOption "classic dbus fallback + systemd config compliance check after rebuild";

  config = lib.mkIf config.services.dbus.complianceDiagnostics.enable {
    services.dbus.implementation = "dbus";

    system.activationScripts.checkSystemdErrors = {
      supportsDryActivation = true;
      text = ''
        echo "========= 🛠️ System Config Compliance Check ========="
        errors=$(${pkgs.systemd}/bin/journalctl -b 0 --since "5 minutes ago" | grep -i "ignoring line" || true)
        if [ -n "$errors" ]; then
          echo -e "\e[31m⚠️ WARNING: systemd syntax errors detected in new config!\e[0m"
          echo "$errors"
        else
          echo -e "\e[32m✓ All service config files parsed correctly.\e[0m"
        fi
        echo "========================================="
      '';
    };
  };
}
