{ config, pkgs, ... }:
let
  # .obsidian.vimrc file for vim customizations
  vimrcContent = ''
    " Yank to system clipboard
    set clipboard=unnamed
    
    " jj to exit insert mode
    imap jj <Esc>
    
    " Navigate visual lines
    nmap j gj
    nmap k gk
    
    " Quick save
    nmap <Space>w :w<CR>
    
    " Go to next/previous tab
    exmap tabnext obcommand workspace:next-tab
    nmap gt :tabnext<CR>
    exmap tabprev obcommand workspace:previous-tab
    nmap gT :tabprev<CR>
    
    " Quick search
    exmap search obcommand global-search:open
    nmap <Space>/ :search<CR>
    
    " Toggle fold
    exmap togglefold obcommand editor:toggle-fold
    nmap za :togglefold<CR>
    
    " Follow link under cursor
    exmap followlink obcommand editor:follow-link
    nmap gd :followlink<CR>
    
    " Go back/forward
    exmap back obcommand app:go-back
    nmap <C-o> :back<CR>
    exmap forward obcommand app:go-forward
    nmap <C-i> :forward<CR>
    
    " Split navigation
    exmap focusleft obcommand editor:focus-left
    nmap <C-h> :focusleft<CR>
    exmap focusright obcommand editor:focus-right
    nmap <C-l> :focusright<CR>
    exmap focustop obcommand editor:focus-top
    nmap <C-k> :focustop<CR>
    exmap focusbottom obcommand editor:focus-bottom
    nmap <C-j> :focusbottom<CR>
  '';
  
  obsidianConfig = {
    vimMode = true;
    
    # Core plugins
    enabledCorePlugins = [
      "file-explorer"
      "global-search"
      "switcher"
      "graph"
      "backlink"
      "outgoing-link"
      "tag-pane"
      "page-preview"
      "daily-notes"
      "templates"
      "note-composer"
      "command-palette"
      "editor-status"
      "starred"
      "outline"
      "word-count"
      "file-recovery"
    ];
    
    # Community plugins to install manually
    communityPlugins = [
      # Vim improvements
      "obsidian-vimrc-support"
      
      # Navigation & Search
      "obsidian-omnisearch"
      "quick-switcher-plus"
      
      # Editor enhancements
      "obsidian-advanced-tables"
      "obsidian-editor-shortcuts"
      
      # Git integration
      "obsidian-git"
      
      # Calendar
      "calendar"
      
      # Dataview for queries
      "dataview"
      
      # Templater for advanced templates
      "templater-obsidian"
      
      # Graph analysis
      "juggl"
    ];
  };
in
{
  home.packages = with pkgs; [
    obsidian
  ];
  
  # Create Obsidian vim configuration
  home.file = {
    # Vim configuration
    ".obsidian.vimrc" = {
      text = vimrcContent;
    };
  };
  
  # Note: Obsidian doesn't have direct NixOS config like Spicetify
  # You'll need to manually enable plugins in Obsidian after first launch
  # The .obsidian.vimrc will be automatically loaded by the vimrc-support plugin
}
