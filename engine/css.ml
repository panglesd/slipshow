(* module Units = struct *)
(* let px_n n = Jstr.v (string_of_int n ^ "px") *)
(* let seconds s = Jstr.v (string_of_int s ^ "s") *)
(* let px p = Jstr.v (string_of_int (int_of_float p) ^ "px") *)
(* let css_scale s = Jstr.v ("scale(" ^ string_of_float s ^ ")") *)
(* let deg d = Jstr.v (string_of_float d ^ "deg") *)
(* let css_rotate d = Jstr.v ("rotate(" ^ string_of_float d ^ "deg)") *)
(* end *)

type property =
  | Scale of float
  | Rotate of float
  | Left of float
  | Right of float
  | Top of float
  | Bottom of float
  | TransitionDuration of float
  | Width of float
  | Height of float

let style_of_prop = function
  | Scale _ | Rotate _ -> Jstr.v "transform"
  | Left _ -> Brr.El.Style.left
  | Top _ -> Brr.El.Style.top
  | Right _ -> Brr.El.Style.right
  | Bottom _ -> Brr.El.Style.bottom
  | TransitionDuration _ -> Jstr.v "transition-duration"
  | Width _ -> Jstr.v "width"
  | Height _ -> Jstr.v "height"

let sof x = Printf.sprintf "%.15f" x

let value_of_prop = function
  | Scale x -> "scale(" ^ sof x ^ ")"
  | Rotate r -> "rotate( " ^ sof r ^ "deg)"
  | Left l -> sof l ^ "px"
  | Top t -> sof t ^ "px"
  | Right r -> sof r ^ "px"
  | Bottom b -> sof b ^ "px"
  | TransitionDuration td -> sof td ^ "s"
  | Width w -> sof w ^ "px"
  | Height h -> sof h ^ "px"

open Fut.Syntax

let set prop elem =
  let style = style_of_prop prop in
  let value = value_of_prop prop in
  let old_value =
    let old_value = Brr.El.inline_style style elem in
    if Jstr.equal old_value Jstr.empty then None else Some old_value
  in
  Brr.El.set_inline_style style (Jstr.v value) elem;
  let undo () =
    Fut.return
    @@
    match old_value with
    | None -> Brr.El.remove_inline_style style elem
    | Some old_value -> Brr.El.set_inline_style style old_value elem
  in
  Fut.return ((), [ undo ])

open UndoMonad.Syntax

let set props elem =
  let* res =
    List.fold_left
      (fun undo prop ->
        let> () = undo in
        set prop elem)
      (UndoMonad.return ()) props
  in
  let+ () = Fut.tick ~ms:0 in
  res

let set_pure props elem = set props elem |> UndoMonad.discard
