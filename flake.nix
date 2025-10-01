{
    description = "My system's flake";
    inputs = {

        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        hyprland.url = "github:hyprwm/Hyprland";
        nix-colors.url = "github:misterio77/nix-colors";
        spicetify-nix.url = "github:Gerg-L/spicetify-nix";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # NEOVIM with nvf
        # Optional, if you intend to follow nvf's obsidian-nvim input
        # you must also add it as a flake input.
        # obsidian-nvim.url = "github:epwalsh/obsidian.nvim";

        # Required, nvf works best and only directly supports flakes
        nvf = {
            url = "github:NotAShelf/nvf";
            # You can override the input nixpkgs to follow your system's
            # instance of nixpkgs. This is safe to do as nvf does not depend
            # on a binary cache.
            inputs.nixpkgs.follows = "nixpkgs";
            # Optionally, you can also override individual plugins
            # for example:
            # inputs.obsidian-nvim.follows = "obsidian-nvim"; # <- this will use the obsidian-nvim from your inputs
        };
    };
    outputs = { nixpkgs, home-manager, ... } @ inputs:
    {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [
                ./system/configuration.nix
                home-manager.nixosModules.home-manager
                {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.extraSpecialArgs = { inherit inputs; };
                    home-manager.users.duartesj = import ./home;
                }

                {
                    nixpkgs.config.allowUnfree = true;
                }

            ];
        };
    };
}
