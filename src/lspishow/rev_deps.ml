let hashtbl_update h key f =
  match f (Hashtbl.find_opt h key) with
  | None -> ()
  | Some v -> Hashtbl.replace h key v

type t = (Fpath.t, Fpath.Set.t) Hashtbl.t

let current : t = Hashtbl.create 10

let remove dependant depends =
  hashtbl_update current dependant @@ Option.map (Fpath.Set.remove depends)

let add dependant depends =
  hashtbl_update current dependant @@ function
  | None -> Some (Fpath.Set.singleton depends)
  | Some set -> Some (Fpath.Set.add depends set)

let get dependant =
  Hashtbl.find_opt current dependant |> Option.value ~default:Fpath.Set.empty

let rec get_roots u =
  let parents = get u in
  if Fpath.Set.is_empty parents then Fpath.Set.singleton u
  else
    Fpath.Set.fold
      (fun u -> Fpath.Set.union @@ get_roots u)
      parents Fpath.Set.empty
