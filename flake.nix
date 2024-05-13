{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, naersk, nixpkgs-mozilla }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          
          overlays = [
            (import nixpkgs-mozilla)
          ];
        };
        
        toolchain = (pkgs.rustChannelOf {
          rustToolchain = ./src-tauri/rust-toolchain.toml;
          sha256 = "sha256-WzO5hWsH0tF9O3VDgmURQr/tkSo4DjmVJ4INlB/MGL4=";
        }).rust;
        
        naersk-lib = pkgs.callPackage naersk {
          cargo = toolchain;
          rustc = toolchain;
        };
        
        neededDeps = with pkgs; [
          udev
          alsaLib
          vulkan-loader
          # xlibsWrapper
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          libxkbcommon
          wayland
          clang

          glib
          cairo
          libsoup
          pango
          gdk-pixbuf
          atk
          gtk3
          webkitgtk
        ];
        
        neededNativeDeps = with pkgs; [
          openssl
          pkg-config
          mold
        ];
        
        libPath = with pkgs; lib.makeLibraryPath neededDeps;
      in {
        devShell = with pkgs; mkShell {
          shellHook = ''
            export WEBKIT_DISABLE_COMPOSITING_MODE=1
          '';
          buildInputs = [
            toolchain
            # rustup
            rust-analyzer
            cargo-tauri
            nodejs
            yarn
          ] ++ neededDeps;
          nativeBuildInputs = [] ++ neededNativeDeps;
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
          LD_LIBRARY_PATH = libPath;
        };
      });
}
