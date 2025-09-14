{
  description = "tiny-tapeput env flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.librelane.url = "github:librelane/librelane";
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  nixConfig = {
   extra-substituters = [
     "https://nix-cache.fossi-foundation.org"
   ];
   extra-trusted-public-keys = [
     "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
   ];
  };

  outputs = { self, nixpkgs, flake-utils, librelane }@inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      nixpkgs_cfg = {
        allowUnfree = true;
      };
      pkgs = import nixpkgs {
        inherit system;
        config = nixpkgs_cfg;
      };

      env_packages = with pkgs; [
          yosys
          verilator

          # # HW synthesis tools
          # DANGER: librelane adds its own python environment to the path.
          # If it has a different python version than our myPythonWithPackages, then it seems to overshadow the results of find_libpython.
          # This results in the usage of the wrong libpython and breaks cocotb simulations.
          librelane.packages."${system}".librelane

          # # Core simulation dependencies

          gcc # The cocotb/verilator simulation uses gcc
          cmake
          ccache
          ninja
          gnumake # get-or-tools.sh
          #(hiPrio clang_18) # Fix /bin/c++ collision with gcc
          #llvmPackages_18.bintoolsNoLibc # ld.lld required for "awesome compiler patcher"
          #llvmPackages_18.clang-unwrapped.python # git-clang-format
          zlib.dev # Needed for verilator fst exports

          SDL2 # Needed for the TB
      ];


    in rec {
      devShell = pkgs.mkShellNoCC {
        packages = env_packages ++ (with pkgs; [
          # Non essential packages
          gtkwave
        ]);
      };
    });}
