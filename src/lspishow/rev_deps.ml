let hashtbl_update h key f =
  match f (Hashtbl.find_opt h key) with
  | None -> ()
  | Some v -> Hashtbl.replace h key v

type t = {
  rev_deps : (Fpath.t, Fpath.Set.t) Hashtbl.t;
  deps : (Fpath.t, Fpath.Set.t) Hashtbl.t;
      (** We are only interested in the rev deps but we store the deps to know
          how to update when the deps change *)
}

let as_map (v : t) : Fpath.set Fpath.Map.t =
  v.rev_deps |> Hashtbl.to_seq |> Fpath.Map.of_seq

let current : t = { rev_deps = Hashtbl.create 10; deps = Hashtbl.create 10 }

let remove dependant depends =
  hashtbl_update current.rev_deps dependant
  @@ Option.map (Fpath.Set.remove depends)

let add dependant depends =
  hashtbl_update current.rev_deps dependant @@ function
  | None -> Some (Fpath.Set.singleton depends)
  | Some set -> Some (Fpath.Set.add depends set)

let get dependant =
  Hashtbl.find_opt current.rev_deps dependant
  |> Option.value ~default:Fpath.Set.empty

let update_state ~new_unit file =
  let () =
    match Hashtbl.find_opt current.deps file with
    | None -> ()
    | Some deps ->
        Fpath.Set.iter
          (fun dependant ->
            let dependant =
              Fpath.normalize @@ Fpath.( // ) (Fpath.parent file) dependant
            in
            remove dependant file)
          deps
  in
  let () =
    let new_deps =
      new_unit.Slipshow.Ast.deps |> Fpath.Map.to_seq |> Seq.map fst
      |> Fpath.Set.of_seq
    in
    Hashtbl.replace current.deps file new_deps
  in
  Fpath.Map.iter
    (fun dependant _locs ->
      let dependant =
        Fpath.normalize @@ Fpath.( // ) (Fpath.parent file) dependant
      in
      add dependant file)
    new_unit.Slipshow.Ast.deps

let get_roots u =
  let rec get_roots visited u =
    if Fpath.Set.mem u visited then
      (* TODO: Show as error that the thing is cyclic *)
      Fpath.Set.singleton u
    else
      let visited = Fpath.Set.add u visited in
      let parents = get u in
      if Fpath.Set.is_empty parents then Fpath.Set.singleton u
      else
        Fpath.Set.fold
          (fun u -> Fpath.Set.union @@ get_roots visited u)
          parents Fpath.Set.empty
  in
  get_roots Fpath.Set.empty u
