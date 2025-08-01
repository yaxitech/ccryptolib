{
  description = "An integrated collection of cryptographic primitives written in Lua using the ComputerCraft system API.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    mcfly = {
      url = "https://raw.githubusercontent.com/cc-tweaked/CC-Tweaked/refs/heads/mc-1.20.x/projects/core/src/test/resources/test-rom/mcfly.lua";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mcfly,
    }:
    let
      recursiveMerge = with nixpkgs.lib; foldl recursiveUpdate { };
    in
    recursiveMerge [
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          luaWithBusted = lua: lua.withPackages (ps: [ ps.busted ]);
          mkDevShell =
            lua:
            pkgs.mkShell {
              name = "ccryptolib-${lua.name}";
              packages = [ (luaWithBusted lua) ];
            };
        in
        {
          checks.busted-lua5_4 = pkgs.callPackage (
            { runCommand, lua }:
            runCommand "busted-ccryptolib-${lua.name}" { buildInputs = [ (luaWithBusted lua) ]; } ''
              cp -r ${self}/spec       .
              cp -r ${self}/ccryptolib .
              lua -v
              busted spec/
              touch "$out"
            ''
          ) { lua = pkgs.lua5_4; };

          checks.busted-lua5_3 = self.checks.${system}.busted-lua5_4.override { lua = pkgs.lua5_3; };
          checks.busted-lua5_2 = self.checks.${system}.busted-lua5_4.override { lua = pkgs.lua5_2; };

          formatter = pkgs.nixfmt-tree;

          devShells = rec {
            lua5_4 = mkDevShell pkgs.lua5_4;
            lua5_3 = mkDevShell pkgs.lua5_3;
            lua5_2 = mkDevShell pkgs.lua5_2;
            default = lua5_2;
          };
        }
      ))

      (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
        checks.mcfly-tests = nixpkgs.legacyPackages.${system}.callPackage (
          { runCommand, craftos-pc }:
          runCommand "mcfly-tests" { } ''
            export HOME="$(mktemp -d)"
            COMPUTER_DIR="$HOME/computer/0"
            mkdir -p "$COMPUTER_DIR"

            cp ${mcfly}              "$COMPUTER_DIR/mcfly.lua"
            cp -r ${self}/spec       "$COMPUTER_DIR"
            cp -r ${self}/ccryptolib "$COMPUTER_DIR"

            ${craftos-pc}/bin/craftos \
              --headless \
              --directory "$HOME" \
              --exec 'shell.run("mcfly.lua spec"); os.shutdown()' \
              | tee output.log

            if grep -q "passed (100%)" output.log; then
              touch "$out"
            else
              echo "Tests failed"
            fi
          ''
        ) { };
      }))
    ];

}
