;; FreeCAD modeling environment for an Orb Weaver KiCad repository.
;;
;; Use this for 3D STEP/model work. It deliberately omits KiCad.

((@ (guix profiles) concatenate-manifests)
 (list
  ((@ (guix profiles) packages->manifest)
   (list (@ (orb-weaver context packages) orb-weaver-context-kicad)
         (@ (orb-weaver packages) orb-weaver-kicad-libs)
         (@ (orb-weaver packages) sqliteodbc)))
  ((@ (gnu packages) specifications->manifest)
   '("freecad"
     "bash"
     "python"
     "git"
     "nss-certs"
     "openjdk@25"
     "ripgrep"
     "sqlite"
     "unixodbc"))))
