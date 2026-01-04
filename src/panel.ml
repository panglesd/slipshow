open Brr

type t = Jv.t

include (Jv.Id : Jv.CONV with type t := t)

let create ?mount ?update ?top ?pos dom =
  let o = Jv.obj [||] in
  Jv.set_if_some o "mount" (Option.map Jv.repr mount);
  Jv.set_if_some o "update"
    (Option.map
       (fun u ->
         let u' jv = u (Editor.View.Update.of_jv jv) in
         u')
       update
    |> Option.map Jv.repr);
  Jv.Bool.set_if_some o "top" top;
  Jv.Int.set_if_some o "pos" pos;
  Jv.set o "dom" (El.to_jv dom);
  o
