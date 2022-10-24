{ previousIncrementalOutput ? null
}:
let
  pkgs = import <nixpkgs> { };
  compilerName = "ghc942";
  hsPkgs = pkgs.haskell.packages.${compilerName};
  pkg = { mkDerivation, base, lib }:
    mkDerivation {
      pname = "haskell-incremental-example";
      version = "1.0.0";
      src = ./.;
      isLibrary = false;
      isExecutable = true;
      executableHaskellDepends = [ base ];
      license = lib.licenses.bsd3;
    };

in
  { build = (pkgs.haskell.lib.overrideCabal (hsPkgs.callPackage pkg { })
      (drv: {
        postInstall = ''
          # After the install phase, copy incremental build products to the
          # "incremental" output. Setting the mtime to the Unix epoch means
          # that the output is not dependent on the time at which the
          # derivation is built.
          mkdir $incremental
          tar czf $incremental/dist.tar.gz -C dist/build --mtime='1970-01-01T00:00:00Z' .
        '';
        preBuild = pkgs.lib.optionalString (previousIncrementalOutput != null) ''
          # Before building, if we have previous incremental output, copy it
          # into dist/build.
          mkdir -p dist/build
          tar xzf ${previousIncrementalOutput}/dist.tar.gz -C dist/build
        '';
        preFixup = ''
          # Don't try to strip incremental build outputs. This command removes
          # "incremental" from the "outputs" array.
          outputs=(''\${outputs[@]/incremental})
        '';
      }))
      # TODO: try to move this higher up
      .overrideAttrs (old: {
        outputs = old.outputs ++ ["incremental"];
      });
  }


