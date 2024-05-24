{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      cl-charms = pkgs.sbclPackages.cl-charms.overrideLispAttrs
        (oldAttrs: { nativeLibs = [ pkgs.ncurses ]; });
      queues = pkgs.sbclPackages.queues.overrideLispAttrs (oldAttrs: {
        systems = [ "queues" "queues.priority-cqueue" "queues.priority-queue" "queues.simple-cqueue" "queues.simple-queue" ];
        lispLibs = oldAttrs.lispLibs ++ (with pkgs.sbclPackages; [bordeaux-threads]);
      });
    in {

      packages.x86_64-linux.micros = pkgs.sbcl.buildASDFSystem {
        pname = "micros";
        version = "unstable-2023-12-23";
        src = pkgs.fetchFromGitHub {
          owner = "lem-project";
          repo = "micros";
          rev = "23f52d5349382d3d50c855b75a665f3158286390";
          hash = "sha256-Qgz1yi2JIm7QKIBAagiWl9c1BJdOhh4XT3NFyvXpHI4=";
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
        lispLibs = with pkgs.sbclPackages; [ bordeaux-threads bt-semaphore queues  ];
      };

      packages.x86_64-linux.jsonrpc = pkgs.sbcl.buildASDFSystem {
        pname = "jsonrpc";
        version = "20231021-git";
        asds = [ "jsonrpc" ];
        src = pkgs.fetchFromGitHub {
          owner = "cxxxr";
          repo = "jsonrpc";
          rev = "035ba8a8f2e9b9968786ee56b59c7f8afbea9ca2";
          sha256 = "sha256-3oO7KekG3V3c/crib4I9O2Vasmdz8V1vcJfIgJqsXQE=";
        };
        systems = [ "jsonrpc" "jsonrpc/transport/stdio" "jsonrpc/transport/tcp"  ];
        lispLibs = with pkgs.sbclPackages; [ alexandria bordeaux-threads chanl dissect event-emitter usocket vom yason  cl_plus_ssl quri fast-io trivial-utf-8 ];
      };

      packages.x86_64-linux.lem = pkgs.callPackage ./default.nix { inherit pkgs cl-charms queues; jsonrpc = self.packages.x86_64-linux.jsonrpc; lem-mailbox = self.packages.x86_64-linux.lem-mailbox; micros = self.packages.x86_64-linux.micros; lem = self.packages.x86_64-linux.lem; };

      packages.x86_64-linux.default = self.packages.x86_64-linux.lem;

      overlays.default = final: prev: {lem = self.packages.x86_64-linux.lem;};

    };
}
