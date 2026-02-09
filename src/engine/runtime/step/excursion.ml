let excursion = ref None

let start () =
  match !excursion with
  | None -> excursion := Some (Universe.State.get_coord ())
  | Some _ -> ()

(* When we [move_away] using [ijkl] and [zZ], we store the position we
     left. When we change the presentation step, we [move_back] to where we
     were. *)

let end_ window () =
  match !excursion with
  | None -> Fut.return ()
  | Some last_pos ->
      excursion := None;
      Universe.Window.move_pure Fast.slow window last_pos ~duration:1.
