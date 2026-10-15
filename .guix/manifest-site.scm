;; The documentation site: mkdocs-material from Guix for `make site` and
;; `make site-serve`. The Pages workflow installs mkdocs-material from pip
;; instead; the two share mkdocs 1.6 and the Markdown extensions the pages use.
((@ (gnu packages) specifications->manifest)
 '("python"
   "python-mkdocs"
   "python-mkdocs-material"))
