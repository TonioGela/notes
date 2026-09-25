let
  pins = import ./npins;
  pkgs = import pins.nixpkgs-unstable { };
  inherit (pkgs) lib;

  # Kept out of the repo on purpose: the deploy config is part of the build,
  # not something to hand-edit next to the notes.
  wrangler = pkgs.writeText "wrangler.jsonc" (
    builtins.toJSON {
      name = "notes";
      compatibility_date = "2026-09-25";
      # no "main": assets-only, so requests never start an isolate
      assets = {
        directory = "./public";
        # mdbook renders src/404.md, hence input-404 in book.toml
        not_found_handling = "404-page";
      };
      routes = [
        {
          pattern = "notes.toniogela.dev";
          custom_domain = true;
        }
      ];
    }
  );

  # Applied by Cloudflare to every static asset response. HSTS is not here:
  # the zone-level setting already sends it, on redirects too.
  #
  # CSP: mdbook ships every asset itself (css, js, the woff2 faces), so there
  # is no third party to allow. 'unsafe-inline' covers the theme-bootstrap
  # scripts and the style attributes mdbook emits.
  headers = pkgs.writeText "_headers" ''
    /*
      Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'
      X-Content-Type-Options: nosniff
      Referrer-Policy: strict-origin-when-cross-origin
      X-Frame-Options: SAMEORIGIN
      Permissions-Policy: accelerometer=(), camera=(), geolocation=(), gyroscope=(), microphone=(), payment=(), usb=()
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  name = "notes";
  # only what mdbook reads, so README/CI edits don't rebuild the book
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./book.toml
      ./custom.css
      ./src
    ];
  };
  nativeBuildInputs = [ pkgs.mdbook ];
  buildPhase = "mdbook build --dest-dir public";
  installPhase = ''
    mkdir -p $out
    cp -r public $out/public
    cp ${headers} $out/public/_headers
    cp ${wrangler} $out/wrangler.jsonc
  '';
}
