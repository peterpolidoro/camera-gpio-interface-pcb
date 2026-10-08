;; Conventional repo-local manifest for an Orb Weaver KiCad repository.
;;
;; This mirrors .guix/manifest-kicad.scm for direct Guix users. Make targets use
;; task-specific manifests so routine agent/context work does not fetch KiCad or
;; FreeCAD unless those tools are needed.

((@ (guix profiles) concatenate-manifests)
 (list
  ((@ (guix profiles) packages->manifest)
   (list (@ (guix-agent-tools packages) guix-agent-tools)
         (@ (orb-weaver context packages) orb-weaver-context-kicad)
         (@ (orb-weaver packages) mcp-server-kicad)
         (@ (orb-weaver packages) orb-weaver-kicad-libs)
         (@ (orb-weaver packages) orb-weaver-kicad-tools)
         (@ (orb-weaver packages) sqliteodbc)))
  ((@ (gnu packages) specifications->manifest)
   '("kicad"
     "kicad-symbols"
     "kicad-footprints"
     "kicad-packages3d"
     "kicad-templates"
     "bash"
     "make"
     "python"
     "git"
     "nss-certs"
     "openjdk@25"
     "ripgrep"
     "poppler"
     "sqlite"
     "unixodbc"))))
