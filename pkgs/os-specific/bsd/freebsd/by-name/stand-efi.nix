{ hostVersion, lib, stdenv, mkDerivation, include, buildPackages, buildFreebsd, hostMachineBsd, ... }:
mkDerivation {
  path = "stand/efi";
  extraPaths = [
    "contrib/bzip2"
    "contrib/llvm-project/compiler-rt/lib/builtins"
    "contrib/lua"
    "contrib/pnglite"
    "contrib/terminus"
    "lib/libc"
    "lib/liblua"
    "libexec/flua"
    "stand"
    "sys"
  ];
  nativeBuildInputs = [
    buildPackages.bsdSetupHook buildFreebsd.freebsdSetupHook
    buildFreebsd.bmakeMinimal
    buildFreebsd.install buildFreebsd.tsort buildFreebsd.lorder buildPackages.mandoc buildPackages.groff
    buildFreebsd.vtfontcvt
  ];

  makeFlags = [
    "STRIP=-s" # flag to install, not command
    "MK_MAN=no"
    "MK_TESTS=no"
    "OBJCOPY=${lib.getBin buildPackages.binutils-unwrapped}/bin/${buildPackages.binutils-unwrapped.targetPrefix}objcopy"
  ] ++ lib.optional (!stdenv.hostPlatform.isFreeBSD) "MK_WERROR=no";

  hardeningDisable = [ "stackprotector" ];

  # ???
  preBuild = ''
    NIX_CFLAGS_COMPILE+=" -I${include}/include -I$BSDSRCDIR/sys/sys -I$BSDSRCDIR/sys/${hostMachineBsd}/include"
    export NIX_CFLAGS_COMPILE

    make -C $BSDSRCDIR/stand/libsa $makeFlags
    make -C $BSDSRCDIR/stand/ficl $makeFlags
    make -C $BSDSRCDIR/stand/liblua $makeFlags
  '' + lib.optionalString stdenv.hostPlatform.isAarch64 ''
    make -C $BSDSRCDIR/sys/contrib/libfdt $makeFlags
  '';

  postPatch = ''
    sed -E -i -e 's|/bin/pwd|${buildPackages.coreutils}/bin/pwd|' $BSDSRCDIR/stand/defs.mk
    #sed -E -i -e 's|-e start|-Wl,-e,start|g' $BSDSRCDIR/stand/i386/Makefile.inc $BSDSRCDIR/stand/i386/*/Makefile
  '';

  postInstall = ''
    mkdir -p $out/bin/lua
    cp $BSDSRCDIR/stand/lua/*.lua $out/bin/lua
    cp -r $BSDSRCDIR/stand/defaults $out/bin/defaults
  '';

  meta.platforms = lib.platforms.freebsd;
}
