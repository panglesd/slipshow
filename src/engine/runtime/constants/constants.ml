(* Be very careful when using this that the width and height need to have been
   initialized. Otherwise, they have their default value, which is likely wrong.

   If you use them in a function, that's probably right: setting them is one of
   the first thing slipshow does. What can go wrong is if we access them as a
   toplevel. See [universe/state.ml] for an example.

   Imperative programming is confusing!
*)
(* let width = ref 1440. *)
(* let height = ref 1080. *)
(* let set_width = ( := ) width *)
(* let set_height = ( := ) height *)
(* let width () = !width *)
(* let height () = !height *)
