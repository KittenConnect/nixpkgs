{ system ? builtins.currentSystem
, config ? {}
, pkgs ? import ../.. { inherit system config; }
}:

with import ../lib/testing-python.nix { inherit system pkgs; };

let
  inherit (pkgs) lib;

  makePgjwtTest = postgresqlPackage:
    makeTest {
      name = "pgjwt-${postgresqlPackage.name}";
      meta = with lib.maintainers; {
        maintainers = [ spinus willibutz ];
      };

      nodes = {
        master = { ... }:
        {
          services.postgresql = {
            enable = true;
            package = postgresqlPackage;
            extraPlugins = ps: with ps; [ pgjwt pgtap ];
          };
        };
      };

      testScript = { nodes, ... }:
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
lib.concatMapAttrs (n: p: { ${n} = makePgjwtTest p; }) pkgs.postgresqlVersions
// {
  passthru.override = p: makePgjwtTest p;
}
