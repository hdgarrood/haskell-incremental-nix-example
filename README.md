## haskell-nix-incremental-example

This repository contains a proof-of-concept of one approach that can be used with GHC 9.4 to enable incremental Nix builds for Haskell projects.
Please note that this project configuration only works with GHC 9.4 and later, because previous versions of GHC use source file timestamps to determine whether source files have changed, and timestamps are not reliable enough for incremental builds in many settings (such as CI).

The idea is to create a separate Nix output `incremental` to hold the contents of the `dist/build` directory &mdash; in particular, `.o` and `.hi` files which, together, allow GHC to perform incremental builds.

To see this repository in action, begin by running:

```bash
$ nix-build -A build.all
```

This command should produce three symbolic links: `result`, `result-doc`, and `result-incremental`.

Now make a change to `M2.hs` like this:

```patch
 greetTarget :: String
 {-# NOINLINE greetTarget #-}
-greetTarget = "world"
+greetTarget = "incremental haskell nix"
```

And run `nix-build` again, like this:

```bash
$ nix-build -A build.all --argstr previousIncrementalOutput $(readlink result-incremental)
```

This builds the `build` target in `default.nix` again, except this time, the `previousIncrementalOutput` variable is set to the nix store path that contains the `.o` and `.hi` files from the previous compile, which enables incremental builds.
Note the following in the output:

```
building
Preprocessing executable 'haskell-incremental-example' for haskell-incremental-example-1.0.0..
Building executable 'haskell-incremental-example' for haskell-incremental-example-1.0.0..
[1 of 3] Compiling M2               ( M2.hs, dist/build/haskell-incremental-example/haskell-incremental-example-tmp/M2.o ) [Source file changed]
[4 of 4] Linking dist/build/haskell-incremental-example/haskell-incremental-example [Objects changed]
```

`M2` is recompiled because its source has changed, but neither of the other two modules are recompiled, even though they both depend on `M2`!
This is because the _interface_ of `M2` has not changed, and GHC is able to spot this and determine that no rebuild is necessary.
