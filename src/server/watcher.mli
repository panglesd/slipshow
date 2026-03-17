val watch_and_compile :
  Fpath.set ->
  callback:(unit -> (Fpath.set, [ `Msg of string ]) result) ->
  unit Lwt.t
