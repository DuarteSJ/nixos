{
  pkgs,
  inputs,
  ...
}: {
  home.packages =
    (with pkgs; [
      # CLI tools (the host-agnostic ones are in ../common/packages.nix)
      wl-clipboard
      brightnessctl
      playerctl
      alejandra
      statix
      mcp-nixos
      ffmpeg
      swayimg
      mpv
      usbutils
      qpdf

      # Desktop utilities (blueman comes from services.blueman in
      # hosts/laptop/hardware.nix, together with its D-Bus helper)
      hyprpicker
      pavucontrol
      networkmanagerapplet

      # Fonts & themes
      nerd-fonts.jetbrains-mono

      # Applications
      obsidian
      scrcpy
      vial
      stremio-linux-shell

      (texliveSmall.withPackages (ps:
        with ps; [
          # tools: vimtex compiles through latexmk; biblatex needs biber
          latexmk
          biber

          abstract
          acmart
          acronym
          algorithm2e
          biblatex
          biblatex-software
          biblatex-trad
          bigfoot
          bookman
          catchfile
          changes
          charter
          cleveref
          cm-super
          comment
          csquotes
          datatool
          datatool-english
          draftwatermark
          enumitem
          environ
          epsf
          figureversions
          fontawesome5
          fontaxes
          fontname
          fvextra
          glossaries
          glossaries-english
          glossaries-portuges
          helvetic
          hyperxmp
          ifmtarg
          ifoddpage
          inconsolata
          kastrup
          latex2pydata
          libertine
          libertinus-fonts
          lipsum
          logreq
          luacode
          lualatex-math
          mfirstuc
          minitoc
          minted
          mmap
          multirow
          mweights
          ncctools
          newtx
          paralist
          pgfgantt
          pgfopts
          preprint
          simplekv
          spreadtab
          subfigure
          supertabular
          textpos
          titlesec
          todonotes
          totpages
          tracklang
          trimspaces
          truncate
          ucs
          units
          xfor
          xstring
          xurl
        ]))
    ])
    ++ [
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
