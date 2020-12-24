{
  description = "Frontend and backend for Furby";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;
    mozillapkgs = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };


  outputs = { self, nixpkgs, mozillapkgs }: 
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};
    rust = (mozilla.rustChannelOf {
      date = "2020-12-23";
      channel = "nightly";
      sha256 = "LbKHsCOFXWpg/SEyACfzZuWjKbkXdH6EJKOPSGoO01E="; # set zeros after modifying channel or date
      }).rust;
    frontendPackages = with pkgs; [
      elmPackages.elm
      elmPackages.elm-language-server
      elmPackages.elm-format
      nodePackages.elm-oracle
      elmPackages.elm-test
    ];
    backendPackages = with pkgs; [
      cargo rust pkg-config
      openssl httpie curl diesel-cli
      libmysqlclient jq python3
    ];
  in
  with pkgs;
  {
    defaultPackage.x86_64-linux = stdenv.mkDerivation {
      name = "furby";
      src = "./.";
      buildInputs = [ 
        tokei
      ] ++ frontendPackages ++ backendPackages;
    };
  };
}
