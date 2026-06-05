type buffer = { source : string; unit : Slipshow.Ast.unit' }
type t = (Fpath.t, buffer) Hashtbl.t

let buffers : t = Hashtbl.create 10

let read_file parent s =
  let ( // ) = Fpath.( // ) in
  let fp = Fpath.normalize @@ (parent // s) in
  match Hashtbl.find_opt buffers fp with
  | None -> Ok None
  | Some buf -> Ok (Some buf.source)

let read_file parent =
  let open Read_file.Syntax in
  read_file parent ||| Read_file.fs parent

let to_units () =
  Hashtbl.fold (fun path u -> Fpath.Map.add path u.unit) buffers Fpath.Map.empty

(** Update the root of an updated buffer *)
let update_root root =
  let parent = Fpath.parent root in
  let units = to_units () in
  let _root = Roots.update_root (read_file parent) Roots.buffers units root in
  ()

(** Update the root of an updated buffer *)
let update_state ~old ~new_ file =
  Hashtbl.replace buffers file new_;
  let old_unit = Option.map (fun old -> old.unit) old in
  Rev_deps.update_state ~old_unit ~new_unit:new_.unit file

let update file source =
  match Hashtbl.find_opt buffers file with
  | Some { source = old_source; _ } when String.equal source old_source ->
      let rs = Rev_deps.get_roots file in
      let compile_missing_roots root =
        match Hashtbl.find_opt Roots.buffers root with
        | None -> update_root root
        | Some _ -> ()
      in
      Fpath.Set.iter compile_missing_roots rs
  | old ->
      let parent = Fpath.parent file in
      let open Read_file.Syntax in
      let read_file = Read_file.with_ file source ||| read_file parent in
      let unit = Slipshow.Compile.unit ~read_file file in
      let new_ = { source; unit } in
      update_state ~old ~new_ file;
      let roots = Rev_deps.get_roots file in
      roots |> Fpath.Set.iter update_root
