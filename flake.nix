{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, nixpkgs-mozilla }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          
          overlays = [
            (import nixpkgs-mozilla)
          ];
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
            rustup
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
