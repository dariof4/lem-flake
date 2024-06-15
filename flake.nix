{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      cl-charms = pkgs.sbclPackages.cl-charms.overrideLispAttrs
        (oldAttrs: { nativeLibs = [ pkgs.ncurses ]; });
      jsonrpc = pkgs.sbclPackages.jsonrpc.overrideLispAttrs (oldAttrs: {
        src = pkgs.fetchFromGitHub {
          owner = "cxxxr";
          repo = "jsonrpc";
          rev = "6e3d23f9bec1af1a3155c21cc05dad9d856754bc";
          hash = "sha256-QbXesQbHHrDtcV2D4FTnKMacEYZJb2mRBIMC7hZM/A8=";
        };
        systems =
          [ "jsonrpc" "jsonrpc/transport/stdio" "jsonrpc/transport/tcp" ];
        lispLibs = with pkgs.sbclPackages;
          oldAttrs.lispLibs ++ [ cl_plus_ssl quri fast-io trivial-utf-8 ];
      });
      queues = pkgs.sbclPackages.queues.overrideLispAttrs (oldAttrs: {
        systems = [ "queues" "queues.priority-cqueue" "queues.priority-queue" "queues.simple-cqueue" "queues.simple-queue" ];
        lispLibs = oldAttrs.lispLibs ++ (with pkgs.sbclPackages; [bordeaux-threads]);
      });
    in {

      packages.x86_64-linux.micros = pkgs.sbcl.buildASDFSystem {
        pname = "micros";
        version = "unstable-2024-05-15";
        src = pkgs.fetchFromGitHub {
          owner = "lem-project";
          repo = "micros";
          rev = "f80d7772ca76e9184d9bc96bc227147b429b11ed";
          hash = "sha256-RiBHxKWVZsB4JPktLSVcup7WIUMk08VbxU1zeBfGrFQ=";
        };
        patches = [ ./micros.patch ];
      };
      
      packages.x86_64-linux.lem-mailbox = pkgs.sbcl.buildASDFSystem {
        pname = "lem-mailbox";
        version = "unstable-2023-09-10";
        src = pkgs.fetchFromGitHub {
          owner = "lem-project";
          repo = "lem-mailbox";
          rev = "12d629541da440fadf771b0225a051ae65fa342a";
          hash = "sha256-hb6GSWA7vUuvSSPSmfZ80aBuvSVyg74qveoCPRP2CeI=";
        };
        lispLibs = with pkgs.sbcl.pkgs; [ bordeaux-threads bt-semaphore queues ];
      };

      packages.x86_64-linux.lem-base16-themes = pkgs.sbcl.buildASDFSystem {
        pname = "lem-base16-themes";
        version = "unstable-2023-07-04";
        src = pkgs.fetchFromGitHub {
          owner = "lem-project";
          repo = "lem-base16-themes";
          rev = "07dacae6c1807beaeffc730063b54487d5c82eb0";
          hash = "sha256-UoVJfY2v4+Oc1MfJ9+4iT2ZwIzUEYs4jRi2Xu69nGkM=";
        };
        lispLibs = [self.packages.x86_64-linux.lem];
      };

      
      packages.x86_64-linux.lem = pkgs.callPackage ./default.nix { inherit cl-charms jsonrpc queues; micros = self.packages.x86_64-linux.micros; lem-mailbox = self.packages.x86_64-linux.lem-mailbox; lem = self.packages.x86_64-linux.lem; };
      packages.x86_64-linux.lem-exec = frontend: pkgs.sbcl.buildASDFSystem {
        inherit (self.packages.x86_64-linux.lem) src;
        pname = "lem-exec";
        version = "unstable";
        lispLibs = [self.packages.x86_64-linux.lem self.packages.x86_64-linux.lem-base16-themes jsonrpc cl-charms]
        ++ (with pkgs.sbcl.pkgs; [_3bmd _3bmd-ext-code-blocks lisp-preprocessor trivial-ws trivial-open-browser])
        ++ (if frontend == "sdl2" then (with pkgs.sbcl.pkgs; [sdl2 sdl2-ttf sdl2-image trivial-main-thread]) else []);
        nativeLibs = if frontend == "sdl2" then with pkgs; [SDL2 SDL2_ttf SDL2_image] else [];
        nativeBuildInputs = with pkgs; [ openssl makeWrapper ];
        buildScript = pkgs.writeText "build-lem.lisp" ''
          (load (concatenate 'string (sb-ext:posix-getenv "asdfFasl") "/asdf.fasl"))
          ; Uncomment this line to load the :lem-tetris contrib system
          ;(asdf:load-system :lem-tetris)
          ${if frontend == "sdl2" then "(asdf:load-system :lem-sdl2)" else "(asdf:load-system :lem-ncurses)"}
          (sb-ext:save-lisp-and-die
            "lem"
            :executable t
            :purify t
            #+sb-core-compression :compression
            #+sb-core-compression t
            :toplevel #'lem:main)
        '';
        patches = [ ./fix-quickload.patch ];
        installPhase = ''
          mkdir -p $out/bin
          cp -v lem $out/bin
          wrapProgram $out/bin/lem \
            --prefix LD_LIBRARY_PATH : $LD_LIBRARY_PATH \
        '';
        passthru = {
          withPackages = import ./wrapper.nix { inherit (pkgs) makeWrapper sbcl lib symlinkJoin; lem = self.packages.x86_64-linux.lem-exec frontend; };
        };
      };

      packages.x86_64-linux.lem-ncurses = self.packages.x86_64-linux.lem-exec "ncurses";
      packages.x86_64-linux.lem-sdl2 = self.packages.x86_64-linux.lem-exec "sdl2";
      packages.x86_64-linux.default = self.packages.x86_64-linux.lem-ncurses;

      overlays.default = final: prev: {lem-ncurses = packages.x86_64-linux.lem-ncurses;
                                       lem-sdl2 = packages.x86_64-linux.lem-sdl2;};

      devShells.x86_64-linux.default =
        let
          sbcl' = pkgs.sbcl.withPackages (ps: with ps; [cl-cram]);
        in
       pkgs.mkShell {

        #CL_SOURCE_REGISTRY = pkgs.lib.makeSearchPath "" (with pkgs.sbclPackages; [ cl-cram ]);
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [pkgs.openssl pkgs.ncurses pkgs.libffi pkgs.SDL2 pkgs.SDL2_ttf pkgs.SDL2_image pkgs.tree-sitter-grammars.tree-sitter-c];
        buildInputs = [pkgs.openssl pkgs.ncurses pkgs.roswell pkgs.SDL2 pkgs.SDL2_ttf pkgs.SDL2_image pkgs.pkg-config pkgs.libffi pkgs.tree-sitter-grammars.tree-sitter-c sbcl'];
      };
    };
}
