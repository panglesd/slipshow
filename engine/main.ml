let window = Window.setup ()
let () = Rescaler.setup_rescalers ()

let _ : unit Fut.t =
  let open Fut.Syntax in
  let* () = Window.move window ~x:0.5 ~y:0.3 ~scale:1. ~rotate:0. ~delay:1. in
  let* () = Fut.tick ~ms:2000 in
  Window.move window ~x:0.3 ~y:0.5 ~scale:1. ~rotate:0. ~delay:1.
