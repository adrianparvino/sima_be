(lang dune 3.17)

(using melange 0.1)

(name jsoo_hello)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (allow_empty)
 (name jsoo_hello)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  ocaml
  (melange
   (>= 5.1))
  (dune
   (>= 3.13))
  cf_workers
  ppx_deriving
  odoc
  melange-webapi
  melange-json
  cf_workers)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
