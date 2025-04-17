(lang dune 3.6)

(name slipshow)

(generate_opam_files true)

(source
 (github panglesd/slipshow))

(authors "Paul-Elliot")

(maintainers "Paul-Elliot")

(license GPL-3.0-or-later)

(documentation https://slipshow.readthedocs.io)

(using directory-targets 0.1)

(package
 (name slipshow)
 (synopsis "A compiler from markdown to slipshow")
 (description "Slipshow is an engine to write slips, a concept evolved from slides.")
 (depends
  (ocaml (>= 4.14))
  dune
  (crunch :with-dev-setup)
  (cmdliner (>= 1.3.0))
   base64
   bos
   lwt
   irmin-watcher
   js_of_ocaml-compiler
   js_of_ocaml-lwt
   magic-mime
   (dream (>= "1.0.0~alpha5"))
   fpath
  (ppx_blob (>= "0.8.0"))
   sexplib
   ppx_sexp_conv
  (odoc :with-doc)
  (ocamlformat
   (and :with-dev-setup (= 0.27.0))))
 (tags
  (slipshow presentation slideshow beamer)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
