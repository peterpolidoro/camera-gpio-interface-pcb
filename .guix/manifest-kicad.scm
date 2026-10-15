;; KiCad editing environment for an Orb Weaver KiCad repository.
;;
;; Use this for interactive KiCad work. It deliberately omits FreeCAD.

((@ (guix profiles) concatenate-manifests)
 (list
  ((@ (guix profiles) packages->manifest)
   (list (@ (guix-agent-tools packages) guix-agent-tools)
         (@ (orb-weaver context packages) orb-weaver-context-kicad)
         (@ (orb-weaver packages) mcp-server-kicad)
         (@ (orb-weaver packages) orb-weaver-kicad-libs)
         (@ (orb-weaver packages) orb-weaver-kicad-tools)
         (@ (orb-weaver packages) sqliteodbc)
         (@ (orb-weaver packages) freerouting)))
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
     "ghostscript"
     "poppler"
     "sqlite"
     "unixodbc"))))
