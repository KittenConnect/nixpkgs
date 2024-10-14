{ stdenv
, lib
, fetchFromGitLab
, python3
, meson
, ninja
, elogind
, systemd
, enableSystemd ? stdenv.isLinux
, pkg-config
, docutils
, doxygen
, graphviz
, glib
, dbus
, alsa-lib
, libjack2
, libusb1
, udev
, libsndfile
, vulkanSupport ? true
, vulkan-headers
, vulkan-loader
, webrtc-audio-processing
, webrtc-audio-processing_1
, ncurses
, readline # meson can't find <7 as those versions don't have a .pc file
, lilv
, makeFontsConf
, nixosTests
, valgrind
, libcameraSupport ? !stdenv.isFreeBSD
, libcamera
, libdrm
, gst_all_1
, ffmpeg
, bluezSupport ? stdenv.isLinux
, bluez
, sbc
, libfreeaptx
, liblc3
, fdk_aac
, libopus
, ldacbt
, nativeHspSupport ? true
, nativeHfpSupport ? true
, nativeModemManagerSupport ? stdenv.isLinux
, modemmanager
, libpulseaudio
, zeroconfSupport ? true
, avahi
, raopSupport ? true
, openssl
, opusSupport ? true
, rocSupport ? !stdenv.isFreeBSD
, roc-toolkit
, x11Support ? true
, libcanberra
, xorg
, libmysofa
, ffadoSupport ? x11Support && stdenv.buildPlatform.canExecute stdenv.hostPlatform && lib.systems.equals stdenv.buildPlatform stdenv.hostPlatform && stdenv.isLinux
, ffado
, libselinux
, epoll-shim
, libinotify-kqueue
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "pipewire";
  version = "1.2.5";

  outputs = [
    "out"
    "jack"
    "dev"
    "doc"
    "man"
    "installedTests"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "pipewire";
    repo = "pipewire";
    rev = finalAttrs.version;
    sha256 = "sha256-cYzcEit5zW29GYhvH/pTXqnYFi6AEaS5wl8nD74eWVY=";
  };

  patches = [
    # Load libjack from a known location
    ./0060-libjack-path.patch
    # Move installed tests into their own output.
    ./0070-installed-tests-path.patch
    # fix module-roc-sink explicity specifying sender packet encoding
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/merge_requests/2048
    (fetchpatch {
      url = "https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/6acfb53884c6f3936030fe43a584bfa01c27d3ea.patch";
      hash = "sha256-UQTWnw2fJ8Sx+eMaUmbJEFopV3HPr63v4xVtk0z3/xM=";
    })
  ] ++ lib.optionals stdenv.isFreeBSD [
    # uncomment to attempt to build with alsa support
    #(fetchpatch {
    #  url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/6a6ba556400b5737ceabfc81f666aa536327e01e/multimedia/pipewire/files/patch-spa_plugins_meson.build";
    #  hash = "sha256-SCv1XMSp3nLSj0C9+rqPcUgXz3033WhfoLC0AndBKAE=";
    #  extraPrefix = "";
    #  postFetch = ''
    #    sed -E -i -e 's/\.orig//g' $out
    #  '';
    #})
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/6a6ba556400b5737ceabfc81f666aa536327e01e/multimedia/pipewire/files/patch-spa_plugins_vulkan_dmabuf__fallback.c";
      hash = "sha256-OX/jRNYXuKRhxZlszwlkB7oEmnCKBrZ+dmVFE3t10sU=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/6a6ba556400b5737ceabfc81f666aa536327e01e/multimedia/pipewire/files/patch-src_modules_module-netjack2-manager.c";
      hash = "sha256-L09TmEXt7H8Tmqpj+l1mGbEGXjVXfWv3JAJ5JQSr4Zo=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\.orig//g' $out
      '';
    })
  ];

  strictDeps = true;
  nativeBuildInputs = [
    docutils
    doxygen
    graphviz
    meson
    ninja
    pkg-config
    python3
    glib
  ];

  buildInputs = [
    alsa-lib
    bluez
    dbus
    fdk_aac
    ffmpeg
    glib
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    libcamera
    libjack2
    libfreeaptx
    liblc3
    libmysofa
    libopus
    libpulseaudio
    libusb1
    libsndfile
    lilv
    modemmanager
    ncurses
    readline
    sbc
  ] 
  ++ lib.optionals stdenv.isLinux (if enableSystemd then [ systemd ] else [ elogind udev ])
  ++ (if lib.meta.availableOn stdenv.hostPlatform webrtc-audio-processing_1 then [ webrtc-audio-processing_1 ] else [ webrtc-audio-processing ])
  ++ lib.optional (lib.meta.availableOn stdenv.hostPlatform ldacbt) ldacbt
  ++ lib.optional zeroconfSupport avahi
  ++ lib.optional raopSupport openssl
  ++ lib.optional rocSupport roc-toolkit
  ++ lib.optionals vulkanSupport [ libdrm vulkan-headers vulkan-loader ]
  ++ lib.optionals x11Support [ libcanberra xorg.libX11 xorg.libXfixes ]
  ++ lib.optional ffadoSupport ffado
  ++ lib.optional stdenv.isLinux libselinux
  ++ lib.optionals stdenv.isFreeBSD [ epoll-shim libinotify-kqueue libdrm ];

  # Valgrind binary is required for running one optional test.
  nativeCheckInputs =  lib.optional (lib.meta.availableOn stdenv.hostPlatform valgrind) valgrind;

  mesonFlags = [
    (lib.mesonEnable "docs" true)
    (lib.mesonOption "udevrulesdir" "lib/udev/rules.d")
    (lib.mesonEnable "installed_tests" true)
    (lib.mesonOption "installed_test_prefix" (placeholder "installedTests"))
    (lib.mesonOption "libjack-path" "${placeholder "jack"}/lib")
    (lib.mesonEnable "libcamera" true)
    (lib.mesonEnable "libffado" ffadoSupport)
    (lib.mesonEnable "roc" rocSupport)
    (lib.mesonEnable "libpulse" true)
    (lib.mesonEnable "avahi" zeroconfSupport)
    (lib.mesonEnable "gstreamer" gstreamerSupport)
    (lib.mesonEnable "gstreamer-device-provider" gstreamerSupport)
    (lib.mesonOption "logind-provider" (if enableSystemd then "libsystemd" else "libelogind"))
    (lib.mesonEnable "systemd" enableSystemd)
    (lib.mesonEnable "systemd-system-service" enableSystemd)
    (lib.mesonEnable "selinux" stdenv.isLinux)
    (lib.mesonEnable "avb" stdenv.isLinux)
    (lib.mesonEnable "v4l2" stdenv.isLinux)
    (lib.mesonEnable "pipewire-v4l2" stdenv.isLinux)
    (lib.mesonEnable "pipewire-alsa" stdenv.isLinux)
    (lib.mesonEnable "udev" (!enableSystemd))
    (lib.mesonEnable "ffmpeg" ffmpegSupport)
    (lib.mesonEnable "pw-cat-ffmpeg" ffmpegSupport)
    (lib.mesonEnable "bluez5" bluezSupport)
    (lib.mesonEnable "opus" bluezSupport)
    (lib.mesonEnable "bluez5-backend-hsp-native" nativeHspSupport)
    (lib.mesonEnable "bluez5-backend-hfp-native" nativeHfpSupport)
    (lib.mesonEnable "bluez5-backend-native-mm" nativeModemManagerSupport)
    (lib.mesonEnable "bluez5-backend-ofono" ofonoSupport)
    (lib.mesonEnable "bluez5-backend-hsphfpd" hsphfpdSupport)
    # source code is not easily obtainable
    (lib.mesonEnable "bluez5-codec-lc3plus" false)
    (lib.mesonEnable "bluez5-codec-lc3" true)
    (lib.mesonEnable "bluez5-codec-ldac" (lib.meta.availableOn stdenv.hostPlatform ldacbt))
    (lib.mesonEnable "opus" true)
    (lib.mesonOption "sysconfdir" "/etc")
    (lib.mesonEnable "raop" raopSupport)
    (lib.mesonOption "session-managers" "")
    (lib.mesonEnable "vulkan" vulkanSupport)
    (lib.mesonEnable "x11" x11Support)
    (lib.mesonEnable "x11-xfixes" x11Support)
    (lib.mesonEnable "libcanberra" x11Support)
    (lib.mesonEnable "libmysofa" true)
    (lib.mesonEnable "sdl2" false) # required only to build examples, causes dependency loop
    (lib.mesonBool "rlimits-install" false) # installs to /etc, we won't use this anyway
    (lib.mesonEnable "compress-offload" true)
    (lib.mesonEnable "man" true)
    (lib.mesonEnable "snap" false) # we don't currently have a working snapd
  ];

  env.CFLAGS = lib.optionalString stdenv.isFreeBSD "-Dthread_local=_Thread_local";
  postPatch = lib.optionalString stdenv.isFreeBSD ''
    sed -E -i -e "s/EBADFD/EINVAL/g" pipewire-alsa/alsa-plugins/ctl_pipewire.c
    sed -E -i -e "/threads.h/d" pipewire-jack/src/pipewire-jack.c
  '';

  # Fontconfig error: Cannot load default config file
  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  doCheck = true;

  postUnpack = ''
    patchShebangs source/doc/*.py
    patchShebangs source/doc/input-filter-h.sh
  '';

  postInstall = ''
    moveToOutput "bin/pw-jack" "$jack"
  '';

  passthru.tests.installed-tests = nixosTests.installed-tests.pipewire;

  meta = with lib; {
    description = "Server and user space API to deal with multimedia pipelines";
    changelog = "https://gitlab.freedesktop.org/pipewire/pipewire/-/releases/${finalAttrs.version}";
    homepage = "https://pipewire.org/";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.freebsd;
    maintainers = with maintainers; [ kranzes k900 ];
  };
})
