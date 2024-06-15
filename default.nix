{ sbcl, cl-charms, jsonrpc, queues, openssl, micros, lem-mailbox, makeWrapper, fetchFromGitHub, writeText, lib, symlinkJoin, lem }:
  sbcl.buildASDFSystem rec {
        pname = "lem";
        version = "unstable";
        src = fetchFromGitHub {
          owner = "lem-project";
          repo = "lem";
          rev = "4dd7e27e8435873cc45f83439d0142c94dc0f25f";
          sha256 = "sha256-9hqc2N0xtltLTPlNzcYWpXNnmVBpGctkNedaZ8ak4ZE=";
          fetchSubmodules = true;
        };
        lispLibs = [ micros lem-mailbox cl-charms jsonrpc  queues ] ++ (with sbcl.pkgs;
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
            bt-semaphore
          ]);
        nativeBuildInputs = [ openssl makeWrapper ];
      }
