{ callPackage, makeFontsConf, buildFHSEnv, tiling_wm ? false }:

let
  mkStudio = opts: callPackage (import ./common.nix opts) {
    fontsConf = makeFontsConf {
      fontDirectories = [];
    };
    inherit buildFHSEnv;
    inherit tiling_wm;
  };
  stableVersion = {
    version = "2024.1.1.12"; # "Android Studio Koala | 2024.1.1 Patch 1"
    sha256Hash = "sha256-Qvi/Mc4NEk3dERlfZiowBk2Pmqsgbl5mg56HamvG7aI=";
  };
  betaVersion = {
    version = "2024.1.1.10"; # "Android Studio Koala | 2024.1.1 RC 2"
    sha256Hash = "sha256-84CpZfoAvJHUCO3ZBJqDbuz9xuGE/5xJfXoetJDXju8=";
  };
  latestVersion = {
    version = "2024.1.3.1"; # "Android Studio Ladybug | 2024.1.3 Canary 1"
    sha256Hash = "sha256-BSrcPdkK4dU5/bV29NGKcCR10XYMJrPvC91fcJs5Vq8=";
  };
in {
  # Attributes are named by their corresponding release channels

  stable = mkStudio (stableVersion // {
    channel = "stable";
    pname = "android-studio";
  });

  beta = mkStudio (betaVersion // {
    channel = "beta";
    pname = "android-studio-beta";
  });

  dev = mkStudio (latestVersion // {
    channel = "dev";
    pname = "android-studio-dev";
  });

  canary = mkStudio (latestVersion // {
    channel = "canary";
    pname = "android-studio-canary";
  });
}
