;; Lightweight repo-local environment for an Orb Weaver KiCad repository.
;;
;; Use this for agent sessions, context work, catalog tooling, and ODBC
;; validation. It deliberately omits KiCad and FreeCAD.

((@ (guix profiles) concatenate-manifests)
 (list
  ((@ (guix profiles) packages->manifest)
   (list (@ (guix-agent-tools packages) guix-agent-tools)
         (@ (orb-weaver context packages) orb-weaver-context-kicad)
         (@ (orb-weaver packages) mcp-server-kicad)
         (@ (orb-weaver packages) orb-weaver-kicad-libs)
         (@ (orb-weaver packages) sqliteodbc)))
  ((@ (gnu packages) specifications->manifest)
   '("bash"
     "python"
     "git"
     "nss-certs"
     "ripgrep"
     "poppler"
     "sqlite"
     "unixodbc"))))
