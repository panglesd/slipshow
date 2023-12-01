(lang dune 3.6)

(name slip_of_mark)

(generate_opam_files true)

(source
 (github panglesd/slip_of_mark))

(authors "Paul-Elliot")

(maintainers "Paul-Elliot")

(license MIT)

(documentation https://url/to/documentation)

(using directory-targets 0.1)

(package
 (name slip_of_mark)
 (synopsis "A compiler from markdown to slipshow")
 (description "A longer description")
 (depends
  ocaml
  dune
  (crunch :with-dev-setup)
   cmdliner
   base64
   bos
   cmarkit
  (odoc :with-doc)
  (ocamlformat
   (and :with-dev-setup (= 0.26.1))))
 (tags
  (slipsow presentation slideshow beamer)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
