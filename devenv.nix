{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in
{
  packages = with unstable; [
    gnumake
    git
  ];
  languages.python.enable = true;
  languages.python.uv.enable = true;
  languages.python.venv.enable = true;
  languages.python.venv.requirements = ''
    aider-chat
  '';
  enterTest = ''
    make test
  '';
}
