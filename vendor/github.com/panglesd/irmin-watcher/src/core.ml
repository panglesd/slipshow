(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Astring
open Lwt.Infix

let src = Logs.Src.create "irmin-watcher" ~doc:"Irmin watcher logging"

module Log = (val Logs.src_log src : Logs.LOG)

(* run [t] and returns an handler to stop the task. *)
let stoppable t =
  let s, u = Lwt.task () in
  Lwt.async (fun () -> Lwt.pick [ s; t () ]);
  function
  | () ->
      Lwt.wakeup u ();
      Lwt.return_unit

external unix_realpath : string -> string = "irmin_watcher_unix_realpath"

let realpath dir =
  let ( / ) x y = match y with None -> x | Some y -> Filename.concat x y in
  let rec aux dir file =
    try unix_realpath dir / file
    with Unix.Unix_error (Unix.ENOENT, _, _) ->
      let file = Filename.basename dir / file in
      aux (Filename.dirname dir) (Some file)
  in
  aux dir None

module Digests = struct
  include Set.Make (struct
    type t = string * Digest.t

    let compare = compare
  end)

  let of_list l = List.fold_left (fun set elt -> add elt set) empty l

  let sdiff x y = union (diff x y) (diff y x)

  let digest_pp ppf d = Fmt.string ppf @@ Digest.to_hex d

  let pp_elt = Fmt.(Dump.pair string digest_pp)

  let pp ppf t = Fmt.(Dump.list pp_elt) ppf @@ elements t

  let files t =
    elements t |> List.map fst |> String.Set.of_list |> String.Set.elements
end

module Dispatch = struct
  type t = (string, (int * (string -> unit Lwt.t)) list) Hashtbl.t

  let empty () : t = Hashtbl.create 10

  let clear t = Hashtbl.clear t

  let stats t ~dir = try List.length (Hashtbl.find t dir) with Not_found -> 0

  (* call all the callbacks on the file *)
  let apply t ~dir ~file =
    let fns = try Hashtbl.find t dir with Not_found -> [] in
    Lwt_list.iter_p
      (fun (id, f) ->
        Log.debug (fun f -> f "callback %d" id);
        f file)
      fns

  let add t ~id ~dir fn =
    let fns = try Hashtbl.find t dir with Not_found -> [] in
    let fns = (id, fn) :: fns in
    Hashtbl.replace t dir fns

  let remove t ~id ~dir =
    let fns = try Hashtbl.find t dir with Not_found -> [] in
    let fns = List.filter (fun (x, _) -> x <> id) fns in
    if fns = [] then Hashtbl.remove t dir else Hashtbl.replace t dir fns

  let length t = Hashtbl.fold (fun _ v acc -> acc + List.length v) t 0
end

module Watchdog = struct
  type t = { t : (string, unit -> unit Lwt.t) Hashtbl.t; d : Dispatch.t }

  let length t = Hashtbl.length t.t

  let dispatch t = t.d

  type hook = (string -> unit Lwt.t) -> (unit -> unit Lwt.t) Lwt.t

  let empty () : t = { t = Hashtbl.create 10; d = Dispatch.empty () }

  let clear { t; d } =
    Hashtbl.fold (fun _dir stop acc -> acc >>= stop) t Lwt.return_unit
    >|= fun () ->
    Hashtbl.clear t;
    Dispatch.clear d

  let watchdog t dir = try Some (Hashtbl.find t dir) with Not_found -> None

  let start { t; d } ~dir listen =
    match watchdog t dir with
    | Some _ ->
        assert (Dispatch.stats d ~dir <> 0);
        Lwt.return_unit
    | None -> (
        (* Note: multiple threads can wait here *)
        listen (fun file -> Dispatch.apply d ~dir ~file)
        >>= fun u ->
        match watchdog t dir with
        | Some _ ->
            (* Note: someone else won the race, cancel our own thread
               to avoid avoid having too many wathdogs for [dir]. *)
            u ()
        | None ->
            Log.debug (fun f -> f "Start watchdog for %s" dir);
            Hashtbl.add t dir u;
            Lwt.return_unit)

  let stop { t; d } ~dir =
    match watchdog t dir with
    | None ->
        assert (Dispatch.stats d ~dir = 0);
        Lwt.return_unit
    | Some stop ->
        if Dispatch.stats d ~dir <> 0 then (
          Log.debug (fun f -> f "Active allback are registered for %s" dir);
          Lwt.return_unit)
        else (
          Log.debug (fun f -> f "Stop watchdog for %s" dir);
          Hashtbl.remove t dir;
          stop ())
end

type hook =
  int -> string -> (string -> unit Lwt.t) -> (unit -> unit Lwt.t) Lwt.t

type t = {
  mutable listen : int -> string -> (string -> unit Lwt.t) -> unit Lwt.t;
  mutable stop : unit -> unit Lwt.t;
  watchdog : Watchdog.t;
}

let watchdog t = t.watchdog

let hook t id dir f = t.listen id dir f >|= fun () -> t.stop

let create listen =
  let watchdog = Watchdog.empty () in
  let t =
    {
      listen = (fun _ _ _ -> Lwt.return_unit);
      stop = (fun _ -> Lwt.return_unit);
      watchdog;
    }
  in
  let listen id dir fn =
    let dir = realpath dir in
    let d = Watchdog.dispatch watchdog in
    Dispatch.add d ~id ~dir fn;
    Watchdog.start watchdog ~dir (listen dir) >|= fun () ->
    let stop () =
      Dispatch.remove d ~id ~dir;
      Watchdog.stop watchdog ~dir
    in
    t.stop <- stop
  in
  t.listen <- listen;
  t

let default_polling_time = ref 1.

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
