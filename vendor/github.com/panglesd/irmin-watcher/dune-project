(lang dune 2.8)
(name irmin-watcher)

(generate_opam_files true)

(source (github mirage/irmin-watcher))
(license ISC)
(authors "Thomas Gazagnaire")
(maintainers "Thomas Gazagnaire")
(documentation "https://mirage.github.io/irmin-watcher/")

(package
 (name irmin-watcher)
 (synopsis "Portable Irmin watch backends using FSevents or Inotify")
 (description "irmin-watcher implements [Irmin's watch hooks][watch] for various OS,
using FSevents in macOS and Inotify on Linux.

irmin-watcher is distributed under the ISC license.

[watch]: http://mirage.github.io/irmin/irmin/Irmin/Private/Watch/index.html#type-hook
")
 (depends
   (ocaml (>= "4.02.0"))
   (alcotest :with-test)
   (mtime (and :with-test (>= "2.0.0")))
   (inotify (= :os "linux"))
   (cf-lwt (>="0.4"))
   lwt
   logs
   fmt
   astring
   fsevents-lwt
 )
)
