(lang dune 3.6)

(name perfect_freehand)

(generate_opam_files true)

(source
 (github panglesd/perfect-freehand-ocaml))

(authors "Paul-Elliot <peada@free.fr>")

(maintainers "Paul-Elliot <peada@free.fr>")

(license MIT)

(package
 (name perfect_freehand)
 (synopsis "JSOO bindings to perfect freehand")
 (description "JSOO bindings to perfect freehand")
 (depends ocaml brr)
 (tags
  ("jsoo bindings" "perfect freehand")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
