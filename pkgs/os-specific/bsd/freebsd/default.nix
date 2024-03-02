{ stdenv, lib, config, newScope, buildPackages, pkgsHostHost, makeSetupHook, substituteAll, runtimeShell, ... }:
let
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
in lib.makeScope newScope (self: with self; { inherit stdenv;
  #stdenv = if stdenv.cc.isClang then stdenv else llvmPackages.stdenv;
  compatIsNeeded = !self.stdenv.hostPlatform.isFreeBSD;

  # build a self which is parameterized with whatever the targeted version is
  # so e.g. pkgsCross.x86_64-freebsd.freebsd.branches."releng/14.0".buildFreebsd will get you
  # freebsd.branches."releng/14.0"
  buildFreebsd = buildPackages.freebsd.overrideScope (_: _: { inherit hostBranch; });
  branches = lib.flip lib.mapAttrs versions (branch: _: self.overrideScope (_: _: { hostBranch = branch; }));

  packages13 = self.overrideScope (_: _: { hostBranch = "release/13.2.0"; });
  packages14 = self.overrideScope (_: _: { hostBranch = "release/14.0.0"; });
  packagesGit = self.overrideScope (_: _: { hostBranch = "main"; });

  hostBranch = let
    supportedBranches = builtins.attrNames (lib.filterAttrs (k: v: v.supported) versions);
    fallbackBranch = let
        branchRegex = "releng/.*";
        candidateBranches = builtins.filter (name: builtins.match branchRegex name != null) supportedBranches;
      in
        lib.last (lib.naturalSort candidateBranches);
    envBranch = builtins.getEnv "NIXPKGS_FREEBSD_BRANCH";
    selectedBranch =
      if config.freebsdBranch != null then
        config.freebsdBranch
      else if envBranch != "" then
        envBranch
      else null;
    chosenBranch = if selectedBranch != null then selectedBranch else fallbackBranch;
  in
    if versions ? ${chosenBranch} then chosenBranch else throw ''
      Unknown FreeBSD branch ${chosenBranch}!
      FreeBSD branches normally look like one of:
      * `release/<major>.<minor>.0` for tagged releases without security updates
      * `releng/<major>.<minor>` for release update branches with security updates
      * `stable/<major>` for stable versions working towards the next minor release
      * `main` for the latest development version

      Set one with the NIXPKGS_FREEBSD_BRANCH environment variable or by setting `nixpkgs.config.freebsdBranch`.
    '';

  sourceData = versions.${hostBranch};
  versionData = sourceData.version;
  hostVersion = versionData.revision;

  hostArchBsd = {
    x86_64 = "amd64";
    aarch64 = "arm64";
    i486 = "i386";
    i586 = "i386";
    i686 = "i386";
  }.${self.stdenv.hostPlatform.parsed.cpu.name} or self.stdenv.hostPlatform.parsed.cpu.name;

  patchesRoot = ./patches/${hostVersion};

  freebsdSetupHook = makeSetupHook {
    name = "freebsd-setup-hook";
  } ./setup-hook.sh;

  source = callPackage ./source.nix {};
  compatIfNeeded = lib.optional compatIsNeeded compat;
  filterSource = callPackage ./filter-src.nix {};
  mkDerivation = callPackage ./make-derivation.nix {};

  # for cross-compiling or bootstrapping
  compat = callPackage ./compat.nix { stdenv = pkgsHostHost.stdenv; };
  bmakeMinimal = callPackage ./bmake-minimal.nix {};
  libmd = callPackage ./libmd.nix {};  # used for both
  install-wrapper = builtins.readFile ./install-wrapper.sh;
  xinstallBootstrap = callPackage ./boot-install.nix {};
  boot-install = buildPackages.writeShellScriptBin "boot-install" (install-wrapper + ''
    ${xinstallBootstrap}/bin/xinstall "''${args[@]}"
  '');
  xargs-j = substituteAll {
    name = "xargs-j";
    shell = runtimeShell;
    src = ../xargs-j.sh;
    dir = "bin";
    isExecutable = true;
  };

  # core c/c++ deps
  csu = callPackage ./csu.nix {};
  include = callPackage ./include.nix {};
  libc = callPackage ./libc.nix {};
  libcxx = callPackage ./libcxx.nix {};
  libcxxrt = callPackage ./libcxxrt.nix {};

  # soft-deprecated (folded into libc but necessary in isolation for bootstrap)
  libelf = callPackage ./libelf.nix {};
  libexecinfo = callPackage ./libexecinfo.nix {};
  libdevstat = callPackage ./libdevstat.nix {};
  libmemstat = callPackage ./libmemstat.nix {};
  libprocstat = callPackage ./libprocstat.nix {};
  libkvm = callPackage ./libkvm.nix {};

  # libs, bins, and data
  bin = callPackage ./bin.nix {};
  bintrans = callPackage ./bintrans.nix {};
  bmake = callPackage ./bmake.nix {};
  btxld = callPackage ./btxld.nix {};
  cap_mkdb = callPackage ./cap_mkdb.nix {};
  config = callPackage ./config.nix {};
  cp = callPackage ./cp.nix {};
  daemon = callPackage ./daemon.nix {};
  fdisk = callPackage ./fdisk.nix {};
  file2c = callPackage ./file2c.nix {};
  fsck = callPackage ./fsck.nix {};
  gencat = callPackage ./gencat.nix {};
  geom = callPackage ./geom.nix {};
  getent = callPackage ./getent.nix {};
  getty = callPackage ./getty.nix {};
  iconv = callPackage ./iconv.nix {};
  id = callPackage ./id.nix {};
  ifconfig = callPackage ./ifconfig.nix {};
  init = callPackage ./init.nix {};
  install = callPackage ./install.nix {};
  kldconfig = callPackage ./kldconfig.nix {};
  kldload = callPackage ./kldload.nix {};
  kldstat = callPackage ./kldstat.nix {};
  kldunload = callPackage ./kldunload.nix {};
  ldd = callPackage ./ldd.nix {};
  less = callPackage ./less.nix {};
  lib80211 = callPackage ./lib80211.nix {};
  libbsdxml = callPackage ./libbsdxml.nix {};
  libbsm = callPackage ./libbsm.nix {};
  libcapsicum = callPackage ./libcapsicum.nix {};
  libcasper = callPackage ./libcasper.nix {};
  libcrypt = callPackage ./libcrypt.nix {};
  libdl = callPackage ./libdl.nix {};
  libedit = callPackage ./libedit.nix {};
  libgeom = callPackage ./libgeom.nix {};
  libifconfig = callPackage ./libifconfig.nix {};
  libjail = callPackage ./libjail.nix {};
  libkiconv = callPackage ./libkiconv.nix {};
  libncurses = callPackage ./libncurses.nix {};
  libncurses-tinfo = if hostVersion == "13.2" then libncurses else callPackage ./libncurses-tinfo.nix {};
  libnetbsd = callPackage ./libnetbsd.nix {};
  libnv = callPackage ./libnv.nix {};
  libpam = callPackage ./libpam.nix {};
  libradius = callPackage ./libradius.nix {};
  libsbuf = callPackage ./libsbuf.nix {};
  libsm = callPackage ./libsm.nix {};
  libspl = callPackage ./libspl.nix {};
  libssh = callPackage ./libssh.nix {};
  libstdthreads = callPackage ./libstdthreads.nix {};
  libsysdecode = callPackage ./libsysdecode.nix {};
  libtacplus = callPackage ./libtacplus.nix {};
  libufs = callPackage ./libufs.nix {};
  libutil = callPackage ./libutil.nix {};
  libxo = callPackage ./libxo.nix {};
  libypclnt = callPackage ./libypclnt.nix {};
  libzfs = callPackage ./libzfs.nix {};
  limits = callPackage ./limits.nix {};
  locale = callPackage ./locale.nix {};
  localedef = callPackage ./localedef.nix {};
  locales = callPackage ./locales.nix {};
  login = callPackage ./login.nix {};
  lorder = callPackage ./lorder.nix {};
  makefs = callPackage ./makefs.nix {};
  mkcsmapper = callPackage ./mkcsmapper.nix {};
  mkesdb = callPackage ./mkesdb.nix {};
  mkimg = callPackage ./mkimg.nix {};
  mknod = callPackage ./mknod.nix {};
  mount = callPackage ./mount.nix {};
  mount_msdosfs = callPackage ./mount_msdosfs.nix {};
  mtree = callPackage ./mtree.nix {};
  newfs = callPackage ./newfs.nix {};
  newsyslog = callPackage ./newsyslog.nix {};
  nscd = callPackage ./nscd.nix {};
  protect = callPackage ./protect.nix {};
  pwd_mkdb = callPackage ./pwd_mkdb.nix {};
  rc = callPackage ./rc.nix {};
  rcorder = callPackage ./rcorder.nix {};
  reboot = callPackage ./reboot.nix {};
  route = callPackage ./route.nix {};
  rpcgen = callPackage ./rpcgen.nix {};
  sed = callPackage ./sed.nix {};
  services_mkdb = callPackage ./services_mkdb.nix {};
  shutdown = callPackage ./shutdown.nix {};
  sockstat = callPackage ./sockstat.nix {};
  stat = callPackage ./stat.nix {};
  sysctl = callPackage ./sysctl.nix {};
  syslogd = callPackage ./syslogd.nix {};
  truss = callPackage ./truss.nix {};
  tsort = callPackage ./tsort.nix {};
  vtfontcvt = callPackage ./vtfontcvt.nix {};
  zfs = callPackage ./zfs.nix {};
  zfs-data = callPackage ./zfs-data.nix {};

  # kernel
  sys = callPackage ./sys.nix {};

  # bootloader
  stand = callPackage ./stand.nix {};
  stand-efi = callPackage ./stand-efi.nix {};

  # haha funny linux headers
  v4l-compat = callPackage ./v4l-compat {};

  xf86-video-scfb = callPackage ./xf86-video-scfb.nix {};
})
