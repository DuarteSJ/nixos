{ config, pkgs, ... }:
{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      # Browser settings via user.js with nix-colors integration
      settings = {
        # Privacy settings
        "browser.contentblocking.category" = "strict";
        "privacy.donottrackheader.enabled" = true;

        # File handling (open inline instead of auto-download)
        "browser.download.useDownloadDir" = false;
        "browser.download.always_ask_before_save" = true;
        "browser.download.always_ask_before_handling_new_types" = true;
        "browser.download.improvements_to_download_panel" = false;
        "browser.download.open_pdf_attachments_inline" = true;
        "pdfjs.disabled" = false;
        "browser.helperApps.neverAsk.openFile" = "application/pdf,text/plain,text/html,application/json,image/png,image/jpeg,image/gif,audio/mpeg,audio/ogg,video/mp4,video/webm";
        "browser.helperApps.neverAsk.saveToDisk" = "";

        # Performance
        "browser.sessionstore.interval" = 15000;

        # UI preferences
        "browser.tabs.warnOnClose" = false;

        # Enable dark theme
        "browser.theme.dark-private-windows" = false;
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";

        # Force dark mode
        "ui.systemUsesDarkTheme" = 1;
        "browser.in-content.dark-mode" = true;
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;

        # Enable custom CSS
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Better dark colors for content
        "layout.css.prefers-color-scheme.content-override" = 0;

        # Simplify new tab page
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSearch" = true;
      };

      # Custom userChrome.css for system colors
      userChrome = ''
        :root {
          --nix-base00: #${config.colorScheme.palette.base00};
          --nix-base01: #${config.colorScheme.palette.base01};
          --nix-base02: #${config.colorScheme.palette.base02};
          --nix-base03: #${config.colorScheme.palette.base03};
          --nix-base04: #${config.colorScheme.palette.base04};
          --nix-base05: #${config.colorScheme.palette.base05};
          --nix-base06: #${config.colorScheme.palette.base06};
          --nix-base07: #${config.colorScheme.palette.base07};
          --nix-base08: #${config.colorScheme.palette.base08};
          --nix-base09: #${config.colorScheme.palette.base09};
          --nix-base0A: #${config.colorScheme.palette.base0A};
          --nix-base0B: #${config.colorScheme.palette.base0B};
          --nix-base0C: #${config.colorScheme.palette.base0C};
          --nix-base0D: #${config.colorScheme.palette.base0D};
          --nix-base0E: #${config.colorScheme.palette.base0E};
          --nix-base0F: #${config.colorScheme.palette.base0F};
        }

        /* Main window background */
        #main-window,
        #navigator-toolbox {
          background-color: var(--nix-base00) !important;
        }

        /* Toolbar */
        toolbar {
          background-color: var(--nix-base00) !important;
          color: var(--nix-base05) !important;
        }

        /* Tab bar */
        #TabsToolbar {
          background-color: var(--nix-base00) !important;
        }

        /* Individual tabs */
        .tabbrowser-tab {
          background-color: var(--nix-base01) !important;
          color: var(--nix-base05) !important;
        }

        .tabbrowser-tab:hover {
          background-color: var(--nix-base02) !important;
        }

        .tabbrowser-tab[selected="true"] {
          background-color: var(--nix-base02) !important;
          color: var(--nix-base07) !important;
        }

        /* URL bar */
        #urlbar,
        #searchbar {
          background-color: var(--nix-base01) !important;
          color: var(--nix-base05) !important;
          border-color: var(--nix-base03) !important;
        }

        #urlbar:focus-within,
        #searchbar:focus-within {
          background-color: var(--nix-base02) !important;
          border-color: var(--nix-base0D) !important;
        }

        /* Dropdown and autocomplete */
        #urlbar-results,
        .urlbarView {
          background-color: var(--nix-base01) !important;
          color: var(--nix-base05) !important;
          border-color: var(--nix-base03) !important;
        }

        .urlbarView-row:hover {
          background-color: var(--nix-base0D) !important;
          color: var(--nix-base00) !important;
        }

        /* Sidebar */
        #sidebar-box,
        #sidebar-header {
          background-color: var(--nix-base00) !important;
          color: var(--nix-base05) !important;
        }

        /* Context menus */
        menupopup,
        popup,
        panel {
          background-color: var(--nix-base01) !important;
          color: var(--nix-base05) !important;
          border-color: var(--nix-base03) !important;
        }

        menuitem:hover,
        menu:hover {
          background-color: var(--nix-base0D) !important;
          color: var(--nix-base00) !important;
        }

        /* Buttons */
        toolbarbutton {
          fill: var(--nix-base05) !important;
          color: var(--nix-base05) !important;
        }

        toolbarbutton:hover {
          background-color: var(--nix-base02) !important;
        }

        /* New tab page and content area */
        browser {
          background-color: var(--nix-base00) !important;
        }
      '';

      # Custom userContent.css for webpage new tab
      userContent = ''
        @-moz-document url("about:home"), url("about:newtab") {
          body {
            background-color: #${config.colorScheme.palette.base00} !important;
            color: #${config.colorScheme.palette.base05} !important;
          }

          .search-wrapper input {
            background-color: #${config.colorScheme.palette.base01} !important;
            color: #${config.colorScheme.palette.base05} !important;
            border-color: #${config.colorScheme.palette.base03} !important;
          }

          .top-site-outer {
            background-color: #${config.colorScheme.palette.base01} !important;
          }

          .top-site-outer:hover {
            background-color: #${config.colorScheme.palette.base02} !important;
          }

          .top-site-outer .title {
            color: #${config.colorScheme.palette.base05} !important;
          }
        }

        @media (prefers-color-scheme: dark) {
          :root {
            color-scheme: dark;
          }
        }
      '';

      # Search engines
      search = {
        force = true;
        default = "ddg";
        engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "Home Manager" = {
            urls = [{
              template = "https://mynixos.com/home-manager/options/programs.{searchTerms}";
            }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@hm" ];
          };

          "reddit" = {
            urls = [{
              template = "https://www.reddit.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];
            icon = "https://www.reddit.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = [ "@r" ];
          };
        };
      };
    };
  };
}
