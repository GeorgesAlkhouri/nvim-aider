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

  env.LUA_PATH = "$LUA_PATH;?.lua";
  packages = with unstable; [
    gnumake
    git
    lua-language-server
    stylua
    lua
    luajitPackages.luafilesystem
    luajitPackages.luarocks
  ];
  languages.lua.enable = true;
  languages.lua.package = unstable.lua;
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
