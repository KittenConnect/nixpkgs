{
  lib,
  makeScopeWithSplicing',
  generateSplicesForMkScope,
  callPackage,
  crossLibcStdenv,
  attributePathToSplice ? [ "freebsd" ],
  branch ? "release/14.0.0",
}:

let
  inherit (buildPackages.buildPackages) rsync;

  versions = builtins.fromJSON (builtins.readFile ./versions.json);

  version = "13.1.0";
  branch = "release/${version}";
in makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "freebsd";
  f = (self: lib.packagesFromDirectoryRecursive {
    callPackage = self.callPackage;
    directory = ./pkgs;
  } // {
    sourceData = versions.${branch};

      Branches can be selected by overriding the `branch` attribute on the freebsd package set.
    '';

  # `./package-set.nix` should never know the name of the package set we
  # are constructing; just this function is allowed to know that. This
  # is why we:
  #
  #  - do the splicing for cross compilation here
  #
  #  - construct the *anonymized* `buildFreebsd` attribute to be passed
  #    to `./package-set.nix`.
  callFreeBSDWithAttrs =
    extraArgs:
    let
      # we do not include the branch in the splice here because the branch
      # parameter to this file will only ever take on one value - more values
      # are provided through overrides.
      otherSplices = generateSplicesForMkScope attributePathToSplice;
    in
    makeScopeWithSplicing' {
      inherit otherSplices;
      f =
        self:
        {
          inherit branch;
        }
        // callPackage ./package-set.nix (
          {
            sourceData = versions.${self.branch} or (throw (badBranchError self.branch));
            versionData = self.sourceData.version;
            buildFreebsd = otherSplices.selfBuildHost;
            patchesRoot = ./patches/${self.versionData.revision};
          }
          // extraArgs
        ) self;
    };
in
{
  freebsd = callFreeBSDWithAttrs { };
  freebsdCross = callFreeBSDWithAttrs { stdenv = crossLibcStdenv; };
}
