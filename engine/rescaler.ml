open Brr

let setup_rescalers () =
  let slip_rescalers =
    El.fold_find_by_selector (fun x a -> x :: a) (Jstr.v ".slip-rescaler") []
  in
  let rescale entry =
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
  let callback entries _observer =
    entries
    |> List.map (fun entry -> rescale (ResizeObserver.Entry.target entry))
    |> List.iter (fun f -> f ())
  in
  let observer = ResizeObserver.create callback in
  List.iter (ResizeObserver.observe observer) slip_rescalers
