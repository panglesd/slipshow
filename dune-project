(lang dune 3.6)

(name slipshow)

(generate_opam_files true)

(source
 (github panglesd/slipshow))

(authors "Paul-Elliot")

(maintainers "Paul-Elliot")

(license MIT)

(documentation https://slipshow.readthedocs.io)

(using directory-targets 0.1)

(package
 (name slipshow)
 (synopsis "A compiler from markdown to slipshow")
 (description "A longer description")
 (depends
  ocaml
  dune
  (crunch :with-dev-setup)
   cmdliner
   base64
   bos
   lwt
   irmin-watcher
   js_of_ocaml-compiler
   js_of_ocaml-lwt
   magic-mime
   dream
   fpath
   brr
   ppx_blob
  (odoc :with-doc)
  (ocamlformat
   (and :with-dev-setup (= 0.26.2))))
 (tags
  (slipsow presentation slideshow beamer)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
