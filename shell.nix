let
  pins = import ./npins;
  pkgs = import pins.nixpkgs-unstable { };
in
pkgs.mkShellNoCC {
  packages = [
    pkgs.mdbook
    (pkgs.writeShellScriptBin "build" ''
      ${pkgs.lib.getExe pkgs.mdbook} serve -o
    '')
  ];
}
