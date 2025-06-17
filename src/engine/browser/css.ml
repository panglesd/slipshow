type property =
  | Scale of float
  | Rotate of float
  | Translate of { x : float; y : float }
  | Left of float
  | Right of float
  | Top of float
  | Bottom of float
  | TransitionDuration of float
  | TransitionDelay of float
  | TransitionTiming of string
  | Width of float
  | Height of float

let style_of_prop = function
  | Scale _ | Translate _ | Rotate _ -> Jstr.v "transform"
  | Left _ -> Brr.El.Style.left
  | Top _ -> Brr.El.Style.top
  | Right _ -> Brr.El.Style.right
  | Bottom _ -> Brr.El.Style.bottom
  | TransitionDuration _ -> Jstr.v "transition-duration"
  | TransitionTiming _ -> Jstr.v "transition-timing-function"
  | TransitionDelay _ -> Jstr.v "transition-delay"
  | Width _ -> Jstr.v "width"
  | Height _ -> Jstr.v "height"

let sof x = Printf.sprintf "%.15f" x

let value_of_prop = function
  (* | Scale x -> "scale(" ^ sof x ^ ")" *)
  | Scale x -> "scale3d(" ^ sof x ^ ", " ^ sof x ^ ", 1)"
  | Rotate r -> "rotate( " ^ sof r ^ "deg)"
  (* | Translate { x; y } -> "translate( " ^ sof x ^ "px, " ^ sof y ^ "px)" *)
  | Translate { x; y } -> "translate3d( " ^ sof x ^ "px, " ^ sof y ^ "px, 0)"
  | Left l -> sof l ^ "px"
  | Top t -> sof t ^ "px"
  | Right r -> sof r ^ "px"
  | Bottom b -> sof b ^ "px"
  | TransitionDuration td -> sof td ^ "s"
  | TransitionDelay td -> sof td ^ "s"
  | TransitionTiming t -> t
  | Width w -> sof w ^ "px"
  | Height h -> sof h ^ "px"

let set prop elem =
  let style = style_of_prop prop in
  let value = value_of_prop prop in
  Brr.El.set_inline_style style (Jstr.v value) elem

let set props elem =
  let () = List.iter (fun prop -> set prop elem) props in
  Fut.tick ~ms:0

(* let set prop elem = *)
(*   let style = style_of_prop prop in *)
(*   let value = value_of_prop prop in *)
(*   let old_value = *)
(*     let old_value = Brr.El.inline_style style elem in *)
(*     if Jstr.equal old_value Jstr.empty then None else Some old_value *)
(*   in *)
(*   Brr.El.set_inline_style style (Jstr.v value) elem; *)
(*   let undo () = *)
(*     Fut.return *)
(*     @@ *)
(*     match old_value with *)
(*     | None -> Brr.El.remove_inline_style style elem *)
(*     | Some old_value -> Brr.El.set_inline_style style old_value elem *)
(*   in *)
(*   Fut.return ((), undo) *)

(* open UndoMonad.Syntax *)

(* let set props elem = *)
(*   let* res = *)
(*     List.fold_left *)
(*       (fun undo prop -> *)
(*         let> () = undo in *)
(*         set prop elem) *)
(*       (UndoMonad.return ()) props *)
(*   in *)
(*   let+ () = Fut.tick ~ms:0 in *)
(*   res *)

(* let set_pure props elem = set props elem |> UndoMonad.discard *)
