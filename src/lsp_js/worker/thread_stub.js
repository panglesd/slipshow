// Taken from https://github.com/voodoos/merlin-js/blob/a7367198d332f153ed27de2136d3c6a4af8e206f/src/lsp/thread_stubs.js

//Provides: caml_thread_initialize
function caml_thread_initialize(unit) { return 0; }
//Provides: caml_thread_cleanup
function caml_thread_cleanup(unit) { return 0; }
//Provides: caml_thread_self
function caml_thread_self(unit) { return 0; }
//Provides: caml_thread_id
function caml_thread_id(t) { return 0; }
//Provides: caml_thread_new
function caml_thread_new(f, unit) { return 0; }
//Provides: caml_thread_join
function caml_thread_join(t) { return 0; }
//Provides: caml_thread_yield
function caml_thread_yield(unit) { return 0; }
//Provides: caml_thread_uncaught_exception
function caml_thread_uncaught_exception(exn) { return 0; }
