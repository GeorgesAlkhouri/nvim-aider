{
  description = "Description for the project";

  inputs = {
    noospherix.url = "github:GeorgesAlkhouri/noospherix";
    nixpkgs.follows = "noospherix/nixpkgs";
    nixpkgs-unstable.follows = "noospherix/nixpkgs-unstable";
    flake-parts.follows = "noospherix/flake-parts";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.noospherix.hub.devenv.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          unstable = import inputs.noospherix.hub.nixpkgs-unstable {
            inherit system;
          };
          python' = unstable.python312Full.withPackages (
            ps: with ps; [
            ]
          );
        in
        {
          devenv.shells.default = {
            name = "nvim-aider";

            languages.python.enable = true;
            languages.python.package = python';
            languages.python.uv.enable = true;
            languages.python.venv.enable = true;
            git-hooks.hooks = {
              trim-trailing-whitespace.enable = true;
              check-merge-conflicts.enable = true;
            };

            languages.python.venv.requirements = ''
              aider-chat
            '';

            dotenv.enable = true;

            # enterTest = ''
            #   make test
            # '';
            enterShell = ''
              echo "✨ Updating flake.lock"
              # nix flake update --quiet --option warn-dirty false

              if [ -f .env ]; then
                    export $(grep -v '^#' .env | xargs)
              fi
            '';
          };

        };
    };
}
