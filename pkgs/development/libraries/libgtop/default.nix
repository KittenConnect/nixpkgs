{ lib, stdenv
, fetchurl
, fetchpatch
, glib
, freebsd
, pkg-config
, perl
, gettext
, gobject-introspection
, gnome
, gtk-doc
, deterministic-uname
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libgtop";
  version = "2.41.3";

  outputs = [ "out" "dev" ];

  src = fetchurl {
    url = "mirror://gnome/sources/libgtop/${lib.versions.majorMinor finalAttrs.version}/libgtop-${finalAttrs.version}.tar.xz";
    hash = "sha256-d1Z235WOLqJFL3Vo8osupYEGPTEnc91cC3Ykwbmy2ow=";
  };

  patches = lib.optionals stdenv.hostPlatform.isFreeBSD [
    # adapted from https://raw.githubusercontent.com/freebsd/freebsd-ports/aeaade466005efceda321b5fe9a1246eaf802517/devel/libgtop/files/patch-sysdeps_freebsd_procmap.c
    ./freebsd-procmap.patch
  ];

  nativeBuildInputs = [
    # uname output embedded in https://gitlab.gnome.org/GNOME/libgtop/-/blob/master/src/daemon/Makefile.am
    deterministic-uname
    pkg-config
    gtk-doc
    perl
    gettext
    gobject-introspection
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isFreeBSD [
    freebsd.libkvm
  ];

  propagatedBuildInputs = [
    glib
  ];

  preConfigure = lib.optionalString (stdenv.buildPlatform.isFreeBSD && stdenv.hostPlatform.isFreeBSD) ''
    sed -E -i -e 's/uname -p/uname -m/g' -e 's/uname -r/echo/g' config.guess
    sed -E -i -e 's/uname -p/uname -m/g' -e 's/uname -r/echo/g' configure
  '';

  passthru = {
    updateScript = gnome.updateScript {
      packageName = "libgtop";
      versionPolicy = "odd-unstable";
    };
  };

  meta = with lib; {
    description = "A library that reads information about processes and the running system";
    license = licenses.gpl2Plus;
    maintainers = teams.gnome.members;
    platforms = platforms.unix;
  };
})
