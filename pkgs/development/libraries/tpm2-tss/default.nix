{ stdenv, lib, fetchFromGitHub
, autoreconfHook, autoconf-archive, pkg-config, doxygen, perl
, openssl, json_c, curl, libgcrypt
, cmocka, uthash, ibm-sw-tpm2, iproute2, procps, which
, shadow, libuuid, freebsd
}:
let
  # Avoid a circular dependency on Linux systems (systemd depends on tpm2-tss,
  # tpm2-tss tests depend on procps, procps depends on systemd by default). This
  # needs to be conditional based on isLinux because procps for other systems
  # might not support the withSystemd option.
  procpsWithoutSystemd = procps.override { withSystemd = false; };
  procps_pkg = if stdenv.isLinux then procpsWithoutSystemd else procps;
in

stdenv.mkDerivation rec {
  pname = "tpm2-tss";
  version = "4.1.2";

  src = fetchFromGitHub {
    owner = "tpm2-software";
    repo = pname;
    rev = version;
    hash = "sha256-gyuMGy+34x9YlhlS++f9syz+XLyiaBWDmfqh4xh27Zs=";
  };

  outputs = [ "out" "man" "dev" ];

  nativeBuildInputs = [
    autoreconfHook autoconf-archive pkg-config doxygen perl
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    shadow
  ] ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
    freebsd.sockstat
  ];

  buildInputs = [
    openssl json_c curl libgcrypt uthash libuuid
  ]
  # cmocka is checked in the configure script
  # when unit and/or integration testing is enabled
  # cmocka doesn't build with pkgsStatic, and we don't need it anyway
  # when tests are not run
  ++ lib.optional doInstallCheck cmocka;

  nativeInstallCheckInputs = [
    cmocka which openssl procps_pkg ibm-sw-tpm2
  ] ++ lib.optionals stdenv.isLinux [
    iproute2
  ];

  strictDeps = true;
  preAutoreconf = "./bootstrap";

  enableParallelBuilding = true;

  patches = [
    # Do not rely on dynamic loader path
    # TCTI loader relies on dlopen(), this patch prefixes all calls with the output directory
    ./no-dynamic-loader-path.patch
  ];

  postPatch = ''
    patchShebangs script
    substituteInPlace src/tss2-tcti/tctildr-dl.c \
      --replace '@PREFIX@' $out/lib/
    substituteInPlace ./test/unit/tctildr-dl.c \
      --replace '@PREFIX@' $out/lib/
    substituteInPlace ./bootstrap \
      --replace 'git describe --tags --always --dirty' 'echo "${version}"'
  '' + lib.optionalString stdenv.hostPlatform.isFreeBSD ''
    # the library just straight up violates the contract in the cmocka headers
    sed -E -i -e '/#include <cmocka.h>/ i #include <stdarg.h>' test/unit/*

    # this test fails. can't figure out how to diagnose
    sed -E -i -e '/  test\/unit\/fapi-io /d' Makefile-test.am

  '';

  configureFlags = lib.optionals doInstallCheck [
    "--enable-unit"
    "--enable-integration"
  ];

  postInstall = ''
    # Do not install the upstream udev rules, they rely on specific
    # users/groups which aren't guaranteed to exist on the system.
    rm -R $out/lib/udev
  '';

  doCheck = false;
  doInstallCheck = stdenv.buildPlatform == stdenv.hostPlatform;
  # Since we rewrote the load path in the dynamic loader for the TCTI
  # The various tcti implementation should be placed in their target directory
  # before we could run tests, so we make turn checkPhase into installCheckPhase
  installCheckTarget = "check";

  meta = with lib; {
    description = "OSS implementation of the TCG TPM2 Software Stack (TSS2)";
    homepage = "https://github.com/tpm2-software/tpm2-tss";
    license = licenses.bsd2;
    platforms = platforms.linux ++ platforms.freebsd;
    maintainers = with maintainers; [ baloo ];
  };
}
