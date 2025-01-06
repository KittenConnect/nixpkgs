{
  lib,
  fetchFromGitHub,
  smassh,
  python311,
  testers,
}:

let
  python3 = python311;
in
python3.pkgs.buildPythonApplication rec {
  pname = "smassh";
  version = "3.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kraanzu";
    repo = "smassh";
    rev = "v${version}";
    hash = "sha256-1XwuvEDROG4XLUs9uP7VKBOnho4WMyrZU884U+OMHkQ=";
  };

  nativeBuildInputs = with python3.pkgs; [ poetry-core ];

  pythonRelaxDeps = [
    "platformdirs"
    "textual"
  ];

  propagatedBuildInputs = with python3.pkgs; [
    click
    platformdirs
    requests
    textual
  ];

  # No tests available
  doCheck = false;

  passthru.tests.version = testers.testVersion {
    package = smassh;
    command = "HOME=$(mktemp -d) smassh --version";
  };

  meta = with lib; {
    description = "TUI based typing test application inspired by MonkeyType";
    homepage = "https://github.com/kraanzu/smassh";
    changelog = "https://github.com/kraanzu/smassh/blob/main/CHANGELOG.md";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ aimpizza ];
    mainProgram = "smassh";
  };
}
