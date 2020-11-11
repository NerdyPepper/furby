{ pkgs ? import <nixpkgs> {} }:

let
  sources = import ./nix/sources.nix;
  nixpkgs-mozilla = import sources.nixpkgs-mozilla;
  pkgs = import sources.nixpkgs {
    overlays =
      [
        nixpkgs-mozilla
        (self: super:
        {
          rustc = self.latest.rustChannels.stable.rust;
          cargo = self.latest.rustChannels.stable.rust;
        }
        )
      ];
    };
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      cargo
      rustc
      rustfmt
      pkg-config
      openssl
      httpie
      curl
      diesel-cli
      libmysqlclient
    ];
  }
