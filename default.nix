{ sbcl, cl-charms, jsonrpc, queues, openssl, micros, makeWrapper, fetchFromGitHub, writeText, lib, symlinkJoin, lem }:
  sbcl.buildASDFSystem rec {
        pname = "lem";
        version = "v2.1.0";
        src = fetchFromGitHub {
          owner = "lem-project";
          repo = "lem";
          rev = "v2.1.0";
          sha256 = "sha256-8xdHWJYYr8kfznytn+EEU37Wcy0ryssXRwHosSoQpEQ=";
          fetchSubmodules = true;
        };
        lispLibs = [ micros cl-charms jsonrpc  queues ] ++ (with sbcl.pkgs;
          [
            alexandria
            trivial-gray-streams
            trivial-types
            cl-ppcre
            inquisitor
            babel
            bordeaux-threads
            yason
            log4cl
            split-sequence
            dexador
            iterate
            closer-mop
            trivia
            str
            parse-number
            trivial-clipboard
            cl-setlocale
            cl-package-locks
            trivial-utf-8
            async-process
            cl-change-case
            swank
            esrap
            bt-semaphore]);
        nativeBuildInputs = [ openssl makeWrapper ];
        buildScript = writeText "build-lem.lisp" ''
          (load (concatenate 'string (sb-ext:posix-getenv "asdfFasl") "/asdf.fasl"))
          ; Uncomment this line to load the :lem-tetris contrib system
          ;(asdf:load-system :lem-tetris)
          (asdf:operate :program-op :lem/executable)
        '';
        patches = [ ./remove-quicklisp.patch ./remove-build-operation.patch ];
        installPhase = ''
          mkdir -p $out/bin
          cp -v lem $out/bin
          wrapProgram $out/bin/lem \
            --prefix LD_LIBRARY_PATH : $LD_LIBRARY_PATH \
        '';

        passthru = {
          withPackages = import ./wrapper.nix { inherit makeWrapper sbcl lib lem symlinkJoin; };
        };
      }
