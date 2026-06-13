{config, ...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = with config.colorScheme.palette; {
      # Format
      format = ''
        $username$hostname$directory$git_branch$git_status$fill$cmd_duration$nix_shell$shell
        $character
      '';

      # Add newline before prompt
      add_newline = true;

      # Fill module to push content to the right
      fill = {
        symbol = "─";
      };

      character = {
        success_symbol = "[❯](bold #${base0D})";
        error_symbol = "[❯](bold #${base08})";
        vimcmd_symbol = "[ ❯](bold #${base0D})";
      };

      directory = {
        format = "[$path]($style) ";
        style = "bold #${base0D}";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        repo_root_format = "[](repo_root_style) [$repo_root$path]($style) ";
        repo_root_style = "bold #${base0E}";
      };

      # Git
      git_branch = {
        format = "[$symbol $branch(:$remote_branch)]($style) ";
        symbol = "";
        style = "bold #${base0E}";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold #${base08}";
        conflicted = "🏳";
        up_to_date = "";
        untracked = "?";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      # Nix shell
      nix_shell = {
        disabled = false;
        style = "bold #${base0C}";
        impure_msg = "impure";
        pure_msg = "pure";
        unknown_msg = "unknown";
        format = "[$symbol $state( \\($name\\))]($style) ";
        symbol = "";
      };

      # Shell indicator
      shell = {
        bash_indicator = "[bash](bold #${base09})";
        zsh_indicator = "";
        fish_indicator = "";
        disabled = false;
        format = "[$indicator ]($style)";
      };

      # Username and Hostname
      username = {
        style_user = "bold #${base0B}";
        style_root = "bold #${base08}";
        format = "[$user]($style) ";
        disabled = false;
        show_always = false;
      };

      hostname = {
        ssh_only = true;
        format = "[@$hostname]($style) ";
        style = "bold #${base0C}";
        disabled = false;
      };

      # Others
      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
        style = "bold #${base0A}";
      };
    };
  };
}
