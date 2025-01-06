{
  lib,
  stdenv,
  automat,
  buildPythonPackage,
  cryptography,
  fetchPypi,
  geoip,
  incremental,
  lsof,
  mock,
  pytestCheckHook,
  pythonOlder,
  twisted,
  zope-interface,
}:

buildPythonPackage rec {
  pname = "txtorcon";
  version = "24.8.0";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vv4ZE42cjFMHtu5tT+RG0MIB/9HMQErrJl7ZAwmXitA=";
  };


  propagatedBuildInputs = [
    cryptography
    incremental
    twisted
    automat
    zope-interface
  ] ++ twisted.optional-dependencies.tls;

  nativeCheckInputs = [
    pytestCheckHook
    mock
    lsof
    geoip
  ];

  doCheck = !(stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64);

  meta = with lib; {
    description = "Twisted-based Tor controller client, with state-tracking and configuration abstractions";
    homepage = "https://github.com/meejah/txtorcon";
    changelog = "https://github.com/meejah/txtorcon/releases/tag/v${version}";
    maintainers = with maintainers; [
      jluttine
      exarkun
    ];
    license = licenses.mit;
  };
}
