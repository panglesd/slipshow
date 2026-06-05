type to_server = Slipshow_server.to_server

type root = Slipshow_server.root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type t = (Fpath.t, root) Hashtbl.t

let buffers : t = Hashtbl.create 10

let generate_version () =
  String.init 10 (fun _ -> Char.chr (97 + Random.int 26))

let update_root read_file roots_state units root =
  let units, diagnostics = Slipshow.Compile.compile_all ~read_file units root in
  let condition =
    match Hashtbl.find_opt roots_state root with
    | None -> Lwt_condition.create ()
    | Some { condition; _ } ->
        Lwt_condition.broadcast condition Update;
        condition
  in
  let version = generate_version () in
  Hashtbl.replace roots_state root { units; diagnostics; condition; version }
