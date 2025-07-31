{
  description = "An integrated collection of cryptographic primitives written in Lua using the ComputerCraft system API.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    mcfly = {
      url = "https://raw.githubusercontent.com/cc-tweaked/CC-Tweaked/refs/heads/mc-1.20.x/projects/core/src/test/resources/test-rom/mcfly.lua";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, mcfly }:
    {
      checks."x86_64-linux".mcfly-tests = nixpkgs.legacyPackages."x86_64-linux".callPackage (
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

      formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".nixfmt-tree;
    };
}
