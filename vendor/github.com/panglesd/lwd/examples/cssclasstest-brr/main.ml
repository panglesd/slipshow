open Brr
open Brr_lwd

type square = On | Off

let flip = function On -> Off | Off -> On

let class_of_state =
  function
  | On -> Jstr.v "square-on"
  | Off -> Jstr.v "square-off"

let lwd_table_row_map ~f row =
  Lwd_table.get row |> Option.iter (fun v -> Lwd.set v (f (Lwd.peek v)))

let ui =
  let squares = Lwd_table.make () in
  let add_square () =
    let row = Lwd_table.append squares in
    Lwd_table.set row (Lwd.var Off)
  in
  for _ = 1 to 20 * 25 do
    add_square ()
  done;
  let board =
    Lwd_table.map_reduce
      (fun row state ->
         Lwd_seq.element @@
         Elwd.div
           ~at:[
             `P (At.class' (Jstr.v "square"));
             `R ((Lwd.map ~f:(fun x -> At.class' (class_of_state x)) (Lwd.get state)));
           ]
           ~ev:[
             `P (Elwd.handler Ev.click
                   (fun _ -> lwd_table_row_map row ~f:(fun state -> flip state)))
           ]
           []
      )
      Lwd_seq.monoid
      squares
  in
  Elwd.div ~at:[ `P (At.class' (Jstr.v "game-board")) ] [
    `S (Lwd_seq.lift board)
  ]

let () =
  let ui = Lwd.observe ui in
  let on_invalidate _ =
    ignore @@ G.request_animation_frame @@ fun _ ->
      ignore @@ Lwd.quick_sample ui
  in
  let on_load _ =
    El.append_children (Document.body G.document) [ Lwd.quick_sample ui ];
    Lwd.set_on_invalidate ui on_invalidate
  in
  ignore @@ Ev.listen Ev.dom_content_loaded on_load (Window.as_target G.window)
