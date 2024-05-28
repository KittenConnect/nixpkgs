{ lib, stdenv, fetchFromGitHub, cmake, unstableGitUpdater }:

stdenv.mkDerivation {
  pname = "libcxxrt";
  version = "4.0.10-unstable-2024-05-26";

  src = fetchFromGitHub {
    owner = "libcxxrt";
    repo = "libcxxrt";
    rev = "c62fe9963148f283b2fbb7eb9888785cfb16d77c";
    sha256 = "XxXH6pE2v6WTh1ATJ7Fgd3SFw49L44YchtMlPKX4kYw=";
  };

  nativeBuildInputs = [ cmake ];

  outputs = [ "out" "dev" ];

  # NOTE: the libcxxrt readme advises against installing both the shared and static libraries.
  # I (@rhelmot) have noticed that various static builds fail without the static library present, due to -lcxxrt.
  # I don't know if the ecosystem will still work with only the staticlib.
  installPhase = ''
    mkdir -p $dev/include $out/lib
    cp ../src/cxxabi.h $dev/include
    cp lib/libcxxrt${stdenv.hostPlatform.extensions.library} $out/lib
    cp lib/libcxxrt${stdenv.hostPlatform.extensions.staticLibrary} $out/lib
    ln -s $out/lib/libcxxrt${stdenv.hostPlatform.extensions.library} $out/lib/libcxxrt${stdenv.hostPlatform.extensions.library}.1
  '';

  passthru = {
    libName = "cxxrt";
    updateScript = unstableGitUpdater { };
  };

  meta = with lib; {
    homepage = "https://github.com/libcxxrt/libcxxrt";
    description = "Implementation of the Code Sourcery C++ ABI";
    maintainers = with maintainers; [ qyliss ];
    platforms = platforms.all;
    license = licenses.bsd2;
  };
}
