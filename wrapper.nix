{ lem, lib, symlinkJoin, makeWrapper, sbcl }:
packagesFun:

symlinkJoin {
  name = lib.appendToName "with-packages" lem;

  paths = [ lem ];

  nativeBuildInputs = [ makeWrapper ];

  passthru.unwrapped = lem;

  postBuild = ''
    rm $out/bin/lem
    makeWrapper "${lem}/bin/lem" "$out/bin/lem" \
    --prefix CL_SOURCE_REGISTRY : ${lib.makeSearchPath "" (packagesFun sbcl.pkgs)} \
    --prefix ASDF_OUTPUT_TRANSLATIONS : "$(echo $CL_SOURCE_REGISTRY | sed s,//:,::,g):" \
  '';
}
