{
  pkgs,
  makeTest,
}:

let
  inherit (pkgs) lib;

  makeTestFor =
    package:
    makeTest {
      name = "pgjwt-${package.name}";
      meta = with lib.maintainers; {
        maintainers = [
          spinus
          willibutz
        ];
      };

      nodes.master =
        { ... }:
        {
          services.postgresql = {
            inherit package;
            enable = true;
            enableJIT = lib.hasInfix "-jit-" package.name;
            extraPlugins =
              ps: with ps; [
                pgjwt
                pgtap
              ];
          };
        };

      testScript =
        { nodes, ... }:
        let
          sqlSU = "${nodes.master.services.postgresql.superUser}";
          pgProve = "${pkgs.perlPackages.TAPParserSourceHandlerpgTAP}";
          inherit (nodes.master.services.postgresql.package.pkgs) pgjwt;
        in
        ''
          start_all()
          master.wait_for_unit("postgresql")
          master.succeed(
              "${pkgs.gnused}/bin/sed -e '12 i SET search_path TO tap,public;' ${pgjwt.src}/test.sql > /tmp/test.sql"
          )
          master.succeed(
              "${pkgs.sudo}/bin/sudo -u ${sqlSU} PGOPTIONS=--search_path=tap,public ${pgProve}/bin/pg_prove -d postgres -v -f /tmp/test.sql"
          )
        '';
    };
in
lib.recurseIntoAttrs (
  lib.concatMapAttrs (n: p: { ${n} = makeTestFor p; }) (
    lib.filterAttrs (_: p: !p.pkgs.pgjwt.meta.broken) pkgs.postgresqlVersions
  )
  // {
    passthru.override = p: makeTestFor p;
  }
)
