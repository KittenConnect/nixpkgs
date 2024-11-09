{
  lib,
  stdenv,
  linuxHeaders,
  fetchurl,
  freebsd,
  runCommandCC,
  buildPackages,
}:
let
  WRKSRC = "include/uapi/linux";
in
stdenv.mkDerivation rec {
  pname = "evdev-proto";
  version = "5.8";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
    hash = "sha256-5/dRhqoGQhFK+PGdmVWZNzAMonrK90UbNtT5sPhc8fU=";
  };
  allFiles = [ "input.h" "input-event-codes.h" "joystick.h" "uinput.h" ];

  nativeBuildInputs = [ buildPackages.freebsd.sed freebsd.makeMinimal ];

  useTempPrefix = true;

  ARCH = freebsd.makeMinimal.MACHINE_ARCH;
  OPSYS = "FreeBSD";
  _OSRELEASE = "${lib.versions.majorMinor freebsd.makeMinimal.version}-RELEASE";

  AWK = "awk";
  CHMOD = "chmod";
  FIND = "find";
  MKDIR = "mkdir -p";
  PKG_BIN = "${buildPackages.pkg}/bin/pkg";
  RM = "rm -f";
  SED = "${buildPackages.freebsd.sed}/bin/sed";
  SETENV = "env";
  SH = "sh";
  TOUCH = "touch";
  XARGS = "xargs";

  ABI_FILE = runCommandCC "abifile" { } "$CC -shared -o $out";
  CLEAN_FETCH_ENV = true;
  INSTALL_AS_USER = true;
  NO_CHECKSUM = true;
  NO_MTREE = true;
  SRC_BASE = freebsd.source;

  preUnpack = ''
    export MAKE_JOBS_NUMBER="$NIX_BUILD_CORES"

    export DISTDIR="$PWD/distfiles"
    export PKG_DBDIR="$PWD/pkg"
    export PREFIX="$prefix"

    mkdir -p "$DISTDIR/evdev-proto"
    tar -C "$DISTDIR/evdev-proto" \
        -xf ${linuxHeaders.src} \
        --strip-components 4 \
        linux-${linuxHeaders.version}/include/uapi/linux
  '';

  buildPhase = ":";

  installPhase = ''
    mkdir -p $out/include/linux
    for f in $allFiles; do
      cp ${WRKSRC}/$f $out/include/linux/$f
    done
  '';

  meta = with lib; {
    description = "Input event device header files for FreeBSD";
    maintainers = with maintainers; [ qyliss rhelmot ];
    platforms = platforms.freebsd;
    license = licenses.gpl2Only;
  };
}
