# generic builder for Emacs packages

{ lib, stdenv, emacs, texinfo, writeText, ... }:

let
  inherit (lib) optionalAttrs;
  handledArgs = [ "buildInputs" "nativeBuildInputs" "packageRequires" "propagatedBuildInputs" "propagatedUserEnvPkgs" "meta" ]
    ++ lib.optionals (emacs.withNativeCompilation or false) [ "postInstall" ];

  setupHook = writeText "setup-hook.sh" ''
    source ${./emacs-funcs.sh}

    if [[ ! -v emacsHookDone ]]; then
      emacsHookDone=1

      # If this is for a wrapper derivation, emacs and the dependencies are all
      # run-time dependencies. If this is for precompiling packages into bytecode,
      # emacs is a compile-time dependency of the package.
      addEnvHooks "$hostOffset" addEmacsVars
      addEnvHooks "$targetOffset" addEmacsVars
    fi
  '';

  libBuildHelper = import ./lib-build-helper.nix { inherit lib; };

in

libBuildHelper.adaptMkDerivation { } stdenv.mkDerivation (finalAttrs:

{ pname
, version
, buildInputs ? []
, nativeBuildInputs ? []
, packageRequires ? []
, propagatedBuildInputs ? []
, propagatedUserEnvPkgs ? []
, postInstall ? ""
, meta ? {}
, turnCompilationWarningToError ? false
, ignoreCompilationError ? true
, ...
}@args:

{
  name = "emacs-${finalAttrs.pname}-${finalAttrs.version}";

  unpackCmd = ''
    case "$curSrc" in
      *.el)
        # keep original source filename without the hash
        local filename=$(basename "$curSrc")
        filename="''${filename:33}"
        cp $curSrc $filename
        chmod +w $filename
        sourceRoot="."
        ;;
      *)
        _defaultUnpack "$curSrc"
        ;;
    esac
  '';

  buildInputs = packageRequires ++ buildInputs;
  nativeBuildInputs = [ emacs texinfo ] ++ nativeBuildInputs;
  propagatedBuildInputs = packageRequires ++ propagatedBuildInputs;
  propagatedUserEnvPkgs = packageRequires ++ propagatedUserEnvPkgs;

  inherit setupHook;

  meta = {
    broken = false;
    platforms = emacs.meta.platforms;
  } // optionalAttrs ((args.src.meta.homepage or "") != "") {
    homepage = args.src.meta.homepage;
  } // meta;
}

// optionalAttrs (emacs.withNativeCompilation or false) {

  addEmacsNativeLoadPath = true;

  inherit turnCompilationWarningToError ignoreCompilationError;

  postInstall = ''
    # Besides adding the output directory to the native load path, make sure
    # the current package's elisp files are in the load path, otherwise
    # (require 'file-b) from file-a.el in the same package will fail.
    mkdir -p $out/share/emacs/native-lisp
    source ${./emacs-funcs.sh}
    addEmacsVars "$out"

    find $out/share/emacs -type f -name '*.el' -print0 \
      | xargs -0 -I {} -n 1 -P $NIX_BUILD_CORES sh -c \
          "emacs --batch \
            --eval '(setq large-file-warning-threshold nil)' \
            --eval '(setq byte-compile-error-on-warn ${if finalAttrs.turnCompilationWarningToError then "t" else "nil"})' \
           -f batch-native-compile {} || true"
  '' + postInstall;
}

// removeAttrs args handledArgs)
