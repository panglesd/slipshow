val watch_and_compile :
  callback:(unit -> (Fpath.set, [ `Msg of string ]) result) -> unit Lwt.t
