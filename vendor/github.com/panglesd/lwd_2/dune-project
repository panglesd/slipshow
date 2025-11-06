(lang dune 3.5)
(generate_opam_files true)
(formatting (enabled_for dune))

(name lwd)
(source (github let-def/lwd))
(license MIT)
(authors "Frédéric Bour")
(maintainers "fred@tarides.com")

(package
 (name lwd)
 (synopsis "Lightweight reactive documents")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends dune seq (ocaml (>= "4.03"))
          (qtest :with-test)
          (qcheck :with-test)))

(package
 (name nottui)
 (synopsis "UI toolkit for the terminal built on top of Notty and Lwd")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends (lwd (= :version)) (notty (>= 0.2))
          (cbor :with-test) ; for the examples
          (containers :with-test))) ; for the examples

(package
 (name nottui-unix)
 (synopsis "UI toolkit for the UNIX terminal built on top of Notty and Lwd")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends (lwd (= :version)) (notty (>= 0.2)) (nottui (= :version))
          (cbor :with-test) ; for the examples
          (containers :with-test)))

(package
 (name tyxml-lwd)
 (synopsis "Make reactive webpages in Js_of_ocaml using Tyxml and Lwd")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends (lwd (= :version)) (tyxml (>= 4.5.0)) js_of_ocaml js_of_ocaml-ppx))

(package
 (name brr-lwd)
 (synopsis "Make reactive webpages in Js_of_ocaml using Brr and Lwd")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends (lwd (= :version)) (brr (>= 0.0.4)) js_of_ocaml
          (js_of_ocaml-lwt :with-test))) ; for the examples

(package
 (name nottui-pretty)
 (synopsis "A pretty-printer based on PPrint rendering UIs")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends (nottui (= :version)) (notty (>= 0.2))))

(package
 (name nottui-lwt)
 (synopsis "Run Nottui UIs in Lwt")
 (documentation "https://let-def.github.io/lwd/doc")
 (depends lwt (nottui (= :version)) (notty (>= 0.2))))
