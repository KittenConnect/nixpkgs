{
  lib,
  stdenv,
  appdirs,
  buildPythonPackage,
  fetchFromGitHub,
  hatch-vcs,
  hatchling,
  pytest-mock,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "platformdirs";
  version = "4.3.6";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "platformdirs";
    repo = "platformdirs";
    rev = "refs/tags/${version}";
    hash = "sha256-Zo1fEqiUbrI3pbVp3ndjV8gd+sbcGgUm1PJhQudmiMQ=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  nativeCheckInputs = [
    appdirs
    pytest-mock
    pytestCheckHook
  ];

  pythonImportsCheck = [ "platformdirs" ];

  disabledTests = lib.optionals stdenv.isFreeBSD [
    # possibly related to incomplete build isolation on FreeBSD
    "test_xdg_variable_empty_value"
    "test_xdg_variable_not_set"
  ];

  meta = with lib; {
    description = "Module for determining appropriate platform-specific directories";
    homepage = "https://platformdirs.readthedocs.io/";
    changelog = "https://github.com/platformdirs/platformdirs/releases/tag/${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
