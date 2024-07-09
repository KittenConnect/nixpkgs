{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  setuptools-scm,

  # optional-dependencies
  numpy,

  # tests
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "uncertainties";
  version = "3.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lmfit";
    repo = "uncertainties";
    rev = "refs/tags/${version}";
    hash = "sha256-cm0FeJCxyBLN0GCKPnscBCx9p9qCDQdwRfhBRgQIhAo=";
  };

  nativeBuildInputs = [
    setuptools-scm
  ];

  nativeCheckInputs = [
    pytestCheckHook
    numpy
  ];

  meta = with lib; {
    homepage = "https://pythonhosted.org/uncertainties/";
    description = "Transparent calculations with uncertainties on the quantities involved (aka error propagation)";
    maintainers = with maintainers; [ rnhmjoj ];
    license = licenses.bsd3;
  };
}
