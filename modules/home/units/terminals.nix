{ pkgs, lib, ... }: {

  # ── Ghostty ───────────────────────────────────────────────────
  # home-manager 25.05 已有 programs.ghostty
  programs.ghostty = {
    enable = true;
    settings = {
      theme                 = "Arthur";
      font-family           = "Lilex";
      font-style            = "Regular";
      font-size             = 11;
      shell-integration     = "detect";
      window-padding-x      = 2;
      window-padding-y      = 0;
      window-height         = 40;
      window-width          = 120;
      window-decoration     = false;
      command               = "zellij attach --create X";
      keybind = [
        "clear"
        "ctrl+shift+comma=reload_config"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+p=paste_from_selection"
        "ctrl+shift+m=toggle_maximize"
      ];
    };
  };

  # ── Alacritty ─────────────────────────────────────────────────
  # 备用终端
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "alacritty";
      font = {
        size = 10.5;
        normal.family = "Lilex";
        offset = { x = 0; y = 0; };
      };
      window = {
        decorations = "none";
        dimensions = { columns = 120; lines = 40; };
      };
      terminal.shell.program = "nu";
    };
  };

  # ── Zellij ────────────────────────────────────────────────────
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };

  # 直接使用原始 KDL 配置文件（兼容 zellij 0.44.x 新语法，覆盖 home-manager 默认生成）
  xdg.configFile."zellij/config.kdl".source = lib.mkForce (pkgs.writeText "zellij-config.kdl" ''
    default_shell "nu"
    simplified_ui true
    theme "gruvbox-dark"
    pane_frames false
    scrollback_editor "hx"

    keybinds clear-defaults=true {
        normal {
            bind "Alt Shift h" { MoveTab "Left"; }
            bind "Alt Shift l" { MoveTab "Right"; }
            bind "Ctrl Alt ," { PageScrollUp; }
            bind "Ctrl Alt ." { PageScrollDown; }
            bind "Ctrl Alt /" { NextSwapLayout; }
            bind "Ctrl Alt Space" { ToggleFloatingPanes; }
            bind "Ctrl Alt h" { MoveFocusOrTab "Left"; }
            bind "Ctrl Alt i" { SwitchToMode "Tab"; }
            bind "Ctrl Alt j" { MoveFocus "Down"; }
            bind "Ctrl Alt k" { MoveFocus "Up"; }
            bind "Ctrl Alt l" { MoveFocusOrTab "Right"; }
            bind "Ctrl Alt m" { SwitchToMode "Move"; }
            bind "Ctrl Alt n" { NewPane; }
            bind "Ctrl Alt o" { EditScrollback; }
            bind "Ctrl Alt p" { SwitchToMode "Pane"; }
            bind "Ctrl Alt q" { Quit; }
            bind "Ctrl Alt s" { SwitchToMode "Search"; SearchInput 0; }
            bind "Ctrl Alt w" { SwitchToMode "renametab"; TabNameInput 0; }
            bind "Ctrl Alt x" { CloseFocus; }
            unbind "Ctrl g" "Ctrl p" "Ctrl n" "Ctrl t" "Ctrl s" "Ctrl q"
        }
        pane {
            bind "left" { MoveFocus "Left"; }
            bind "down" { MoveFocus "Down"; }
            bind "up" { MoveFocus "Up"; }
            bind "right" { MoveFocus "Right"; }
            bind "h" { MoveFocus "Left"; }
            bind "j" { MoveFocus "Down"; }
            bind "k" { MoveFocus "Up"; }
            bind "l" { MoveFocus "Right"; }
            bind "x" { CloseFocus; }
        }
        tab {
            bind "h" { GoToPreviousTab; }
            bind "j" { MoveTab "Left"; }
            bind "k" { MoveTab "Right"; }
            bind "l" { GoToNextTab; }
            bind "n" { NewTab; }
            bind "x" { CloseTab; }
            bind "r" { SwitchToMode "renametab"; TabNameInput 0; }
            bind "1" { GoToTab 1; }
            bind "2" { GoToTab 2; }
            bind "3" { GoToTab 3; }
            bind "4" { GoToTab 4; }
            bind "5" { GoToTab 5; }
            bind "6" { GoToTab 6; }
            bind "7" { GoToTab 7; }
            bind "8" { GoToTab 8; }
            bind "9" { GoToTab 9; }
        }
        resize {
            bind "left" { Resize "Increase Left"; }
            bind "down" { Resize "Increase Down"; }
            bind "up" { Resize "Increase Up"; }
            bind "right" { Resize "Increase Right"; }
            bind "h" { Resize "Increase Left"; }
            bind "j" { Resize "Increase Down"; }
            bind "k" { Resize "Increase Up"; }
            bind "l" { Resize "Increase Right"; }
        }
        move {
            bind "left" { MovePane "Left"; }
            bind "down" { MovePane "Down"; }
            bind "up" { MovePane "Up"; }
            bind "right" { MovePane "Right"; }
            bind "h" { MovePane "Left"; }
            bind "j" { MovePane "Down"; }
            bind "k" { MovePane "Up"; }
            bind "l" { MovePane "Right"; }
        }
        search {
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
        }
        renametab {
            bind "Ctrl Alt w" { SwitchToMode "Normal"; }
        }
        renamepane {
            bind "Ctrl Alt w" { SwitchToMode "Normal"; }
        }
    }
  '');
}
