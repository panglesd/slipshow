open Brr

(* We need to listen on resize for both slip-rescalers (the containers) as well as their only child. *)
let setup_rescalers () =
  let slip_rescalers =
    El.fold_find_by_selector (fun x a -> x :: a) (Jstr.v ".slip-rescaler") []
  in
  let slips =
    List.filter_map
      (fun e ->
        match El.children ~only_els:true e with [ c ] -> Some c | _ -> None)
      slip_rescalers
  in
  let rescaled_rescaler entry =
    match El.children ~only_els:true entry with
    | [ c ] ->
        let scale = El.inner_w entry /. El.inner_w c in
        let height = El.inner_h c *. scale in
        fun () ->
          El.set_inline_style (Jstr.v "transform")
            (scale |> fun x -> "scale(" ^ string_of_float x ^ ")" |> Jstr.v)
            c;
          El.set_inline_style El.Style.height
            (height |> fun x -> string_of_float x ^ "px" |> Jstr.v)
            entry
    | [] | _ :: _ :: _ -> fun () -> Console.(log [ "problem!" ])
  in
  let rescale entry =
    if Brr.El.class' (Jstr.v "slip-rescaler") entry then rescaled_rescaler entry
    else
      match Brr.El.parent entry with
      | None -> fun () -> ()
      | Some parent -> rescaled_rescaler parent
  in
  let callback entries _observer =
    entries
    |> List.map (fun entry -> rescale (ResizeObserver.Entry.target entry))
    (* We need to do all the size computations at once, and then execute them,
         otherwise they influence each others *)
    |> List.iter (fun f -> f ())
  in
  let observer = ResizeObserver.create callback in
  List.iter (ResizeObserver.observe observer) slip_rescalers;
  List.iter (ResizeObserver.observe observer) slips
