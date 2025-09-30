{ config, pkgs, ... }:

let
  colors = config.colorScheme.palette;
in
{
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      style = "numbers,changes,header";
      pager = "less -FR";
    };
    themes = {
      # Custom theme using nix-colors
      base16 = {
        src = pkgs.writeText "base16.tmTheme" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>name</key>
            <string>Base16</string>
            <key>settings</key>
            <array>
              <dict>
                <key>settings</key>
                <dict>
                  <key>background</key>
                  <string>#${colors.base00}</string>
                  <key>foreground</key>
                  <string>#${colors.base05}</string>
                  <key>caret</key>
                  <string>#${colors.base05}</string>
                  <key>lineHighlight</key>
                  <string>#${colors.base01}</string>
                  <key>selection</key>
                  <string>#${colors.base02}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Comment</string>
                <key>scope</key>
                <string>comment</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base03}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>String</string>
                <key>scope</key>
                <string>string</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0B}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Number</string>
                <key>scope</key>
                <string>constant.numeric</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base09}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Built-in constant</string>
                <key>scope</key>
                <string>constant.language</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base09}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>User-defined constant</string>
                <key>scope</key>
                <string>constant.character, constant.other</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base09}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Variable</string>
                <key>scope</key>
                <string>variable</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base08}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Keyword</string>
                <key>scope</key>
                <string>keyword</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0E}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Storage</string>
                <key>scope</key>
                <string>storage</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0E}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Storage type</string>
                <key>scope</key>
                <string>storage.type</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0A}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Class name</string>
                <key>scope</key>
                <string>entity.name.class</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0A}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Function name</string>
                <key>scope</key>
                <string>entity.name.function</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0D}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Function argument</string>
                <key>scope</key>
                <string>variable.parameter</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base05}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Tag name</string>
                <key>scope</key>
                <string>entity.name.tag</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base08}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Tag attribute</string>
                <key>scope</key>
                <string>entity.other.attribute-name</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0A}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Library function</string>
                <key>scope</key>
                <string>support.function</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0C}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Library constant</string>
                <key>scope</key>
                <string>support.constant</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0C}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Library class/type</string>
                <key>scope</key>
                <string>support.type, support.class</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base0C}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Library variable</string>
                <key>scope</key>
                <string>support.other.variable</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base05}</string>
                </dict>
              </dict>
              <dict>
                <key>name</key>
                <string>Invalid</string>
                <key>scope</key>
                <string>invalid</string>
                <key>settings</key>
                <dict>
                  <key>foreground</key>
                  <string>#${colors.base08}</string>
                </dict>
              </dict>
            </array>
          </dict>
          </plist>
        '';
      };
    };
  };
}
