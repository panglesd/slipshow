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
//Provides: caml_thread_exit
function caml_thread_exit(unit) { return 0; }
//Provides: caml_thread_sigmask
function caml_thread_sigmask(cmd, sigs) { return 0; }
//Provides: caml_wait_signal
function caml_wait_signal(sigs) { return 0; }
//Provides: caml_thread_uncaught_exception
function caml_thread_uncaught_exception(exn) { return 0; }

//Provides: caml_mutex_new
function caml_mutex_new(unit) { return 0; }
//Provides: caml_mutex_lock
function caml_mutex_lock(m) { return 0; }
//Provides: caml_mutex_try_lock
function caml_mutex_try_lock(m) { return 1; }
//Provides: caml_mutex_unlock
function caml_mutex_unlock(m) { return 0; }

//Provides: caml_condition_new
function caml_condition_new(unit) { return 0; }
//Provides: caml_condition_wait
function caml_condition_wait(c, m) { return 0; }
//Provides: caml_condition_signal
function caml_condition_signal(c) { return 0; }
//Provides: caml_condition_broadcast
function caml_condition_broadcast(c) { return 0; }
