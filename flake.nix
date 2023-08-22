{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      cl-charms = pkgs.sbclPackages.cl-charms.overrideLispAttrs
        (oldAttrs: { nativeLibs = [ pkgs.ncurses ]; });
      jsonrpc = pkgs.sbclPackages.jsonrpc.overrideLispAttrs (oldAttrs: {
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
        version = "unstable-2023-08-05";
        src = pkgs.fetchFromGitHub {
          owner = "lem-project";
          repo = "micros";
          rev = "991d5c8e52cc3be475abb91e24e178753a037842";
          hash = "sha256-446DgGCmtNdGQ3pyR/GI/ZqPPCamoMEc+AGVELI15zI=";
        };
        patches = [ ./micros.patch ];
      };

      packages.x86_64-linux.lem = pkgs.callPackage ./default.nix { inherit cl-charms jsonrpc queues; micros = self.packages.x86_64-linux.micros; lem = self.packages.x86_64-linux.lem; };

      packages.x86_64-linux.default = self.packages.x86_64-linux.lem;

      overlays.default = final: prev: {lem = self.packages.x86_64-linux.lem;};

    };
}
