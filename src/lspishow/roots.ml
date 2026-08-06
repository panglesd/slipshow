type to_server = Slipshow_server.to_server

type root = Slipshow_server.root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type t = (Fpath.t, root) Hashtbl.t

let buffers : t = Hashtbl.create 10
let saved : t = Hashtbl.create 10

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

let update_root read_file roots_state units root currently_modified =
  let directory = Fpath.parent root in
  let units, diagnostics =
    Slipshow.Compile.compile_all ~directory ~read_file units root
  in
  let condition, old_version =
    match Hashtbl.find_opt roots_state root with
    | None -> (Lwt_condition.create (), generate_version ())
    | Some { condition; version; _ } ->
        if Option.is_none currently_modified then
          Lwt_condition.broadcast condition Update;
        (condition, version)
  in
  let version =
    match currently_modified with
    | Some _ ->
        Format.eprintf "not broadcasting%!\n";
        old_version
    | None ->
        Format.eprintf "broadcasting%!\n";
        generate_version ()
  in
  let updated = { units; diagnostics; condition; version } in
  Hashtbl.replace roots_state root updated;
  updated
