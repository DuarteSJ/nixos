{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
in {
  home.packages = with pkgs; [
    beeper
  ];

  # Custom CSS styling for Beeper
  xdg.configFile."BeeperTexts/custom.css".text = ''
    :root, html {
      /* Use system font - line can be commented out/removed if you want to stick with Inter */
      --font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif !important;
    }

    /* Applied unconditionally: the repo ships a single dark scheme (nord),
       so theme always; no light variant to fall back to. */
    :root {
      --theme-accent: #${colors.base03};
      --theme-frame: #${colors.base00};
      --theme-bg: #${colors.base01};
      --theme-text: #${colors.base05};
      --color-primary: var(--theme-accent);
      --color-surface: var(--theme-bg);
      --color-background-sidebar-opaque: var(--theme-frame);
      --color-background-grouped-weak: var(--theme-frame);
      --color-background-grouped: var(--theme-frame);
      --color-border-neutrals-weak: var(--theme-bg);
      --color-text-neutrals: var(--theme-text);
      --color-background-preferences-option-selected: var(--theme-accent);
      --color-background-commandbar-opaque: var(--theme-frame);
      --color-background-commandbar-command-highlighted: var(--theme-accent);
      --color-secondary-container: var(--theme-bg);
      --color-tertiary-container: var(--theme-frame);
      --color-background-selected: var(--theme-accent);
      --color-background-button-primary: var(--theme-accent);
      --color-background-button-primary-active: var(--theme-accent);
    }
    .command.highlighted .command-children {
      background: var(--theme-accent) !important;
    }
    .panes, .compose-message-container > * {
      background: #${colors.base01}55;
    }
    .linked-message {
      color: inherit !important;
    }
    .sidebar-thread.isSelected > section:before {
      background: var(--theme-bg);
    }
  '';
}
