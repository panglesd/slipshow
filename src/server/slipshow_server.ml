type root = Server.root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : unit Lwt_condition.t;
  version : string;
}

type roots = (Fpath.t -> root option) * (unit -> Fpath.t list)

let do_watch entry_point compile =
  let callback () =
    let res = compile () in
    let () = Result.iter (fun _ -> Logs.app (fun m -> m "Recompiled!")) res in
    res
  in
  let initial =
    Fpath.Set.singleton @@ Fpath.normalize
    @@ Fpath.( // ) (Fpath.v (Sys.getcwd ())) entry_point
  in
  Lwt_main.run @@ Watcher.watch_and_compile initial ~callback

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

module Server = Server

let do_serve ~port entry_point
    (compile :
      unit -> ((Slipshow.Ast.units * Diagnosis.t list) * Fpath.set, _) result) =
  let () = if Sys.unix then Sys.(set_signal sigpipe Signal_ignore) in
  (* We need this, otherwise the program is killed when sending a long string to
     a closed connection... See https://github.com/aantron/dream/issues/378 *)

  let condition = Lwt_condition.create () in
  Lwt_main.run
  @@
  let content = ref None in
  let callback () =
    let res = compile () in
    match res with
    | Error _ as e -> e
    | Ok ((units, diagnostics), deps) ->
        content :=
          Some { units; diagnostics; version = generate_version (); condition };
        Lwt_condition.broadcast condition ();
        Ok deps
  in
  let initial =
    Fpath.Set.singleton @@ Fpath.normalize
    @@ Fpath.( // ) (Fpath.v (Sys.getcwd ())) entry_point
  in
  let wac = Watcher.watch_and_compile initial ~callback in
  let dream =
    let open Lwt.Syntax in
    let+ res =
      Server.do_serve ~port ((fun _ -> !content), fun () -> [ Fpath.v "-" ])
    in
    match res with
    | Ok () -> ()
    | Error `Addr_in_use ->
        Logs.err (fun m ->
            m "Port %d is already used, use --port to specify another." port);
        ()
  in
  Lwt.pick [ dream; wac ]
