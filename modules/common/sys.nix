{ pkgs, lib, ... }:

{
  # ── Bootloader: systemd-boot ─────────────────────────────
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # ── Kernel ───────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Network ──────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Audio ────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Power & Security ─────────────────────────────────────
  services.power-profiles-daemon.enable = true;
  security.polkit.enable = true;

  # ── Input Devices ────────────────────────────────────────
  services.libinput.enable = true;

  # ── Keymap (TTY & X11/Wayland) ───────────────────────────
  services.xserver.xkb = {
    layout = "us";
    options = "ctrl:swapcaps";
  };
  console.useXkbConfig = true;
}