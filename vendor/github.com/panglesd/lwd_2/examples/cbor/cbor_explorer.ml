module Ui = Nottui
module W = Nottui_widgets
module C = CBOR.Simple
module A = Notty.A

let body = Lwd.var W.empty_lwd

let wm = Nottui_widgets.window_manager (Lwd.join (Lwd.get body))

let ui_of_cbor (c:C.t) =
  let quit = Lwd.var false in
  let w_q = W.main_menu_item wm "[quit]"
      (fun () -> Lwd.set quit true; W.empty_lwd)
  in
  let rec traverse ?(fold=false) (c:C.t) : Ui.ui Lwd.t =
    match c with
    | `Bool b -> Lwd.return (W.printf ~attr:A.(fg blue) "%B" b)
    | `Bytes s -> Lwd.return (W.printf ~attr:A.(fg @@ gray 14) "<bytes(%d)>" (String.length s))
    | `Text s -> Lwd.return (W.string s)
    | `Int i -> Lwd.return @@ W.printf "%d" i
    | `Float f -> Lwd.return @@ W.printf "%f" f
    | `Null -> Lwd.return (W.string "null")
    | `Undefined -> Lwd.return (W.string "undefined")
    | `Simple i -> Lwd.return (W.printf "simple(%d)" i)
    | `Array [] -> Lwd.return (W.string "[]")
    | `Array l ->
      if fold then (
        let summary =
          Lwd.return @@ W.printf ~attr:A.(fg yellow) "<array(%d)>" (List.length l) in
        W.unfoldable summary
          (fun () ->
             let l = List.map (traverse ~fold:true) l in
             Lwd_utils.pack Ui.Ui.pack_y l)
      ) else (
        let l = List.map (traverse ~fold:true) l in
        Lwd_utils.pack Ui.Ui.pack_y l
      )
    | `Map [] -> Lwd.return (W.string "{}")
    | `Map [x,y] -> mk_k_v x y
    | `Map l ->
      let summary = Lwd.return @@ W.printf ~attr:A.(fg yellow) "<map(%d)>" (List.length l) in
      W.unfoldable summary
        (fun () ->
           let tbl = Lwd_table.make () in
           List.iter (fun (x,y) ->
               let row = Lwd_table.append tbl in
               let kv = mk_k_v x y in
               Lwd_table.set row kv)
             l;
           Lwd.join @@ Lwd_table.reduce (Lwd_utils.lift_monoid Ui.Ui.pack_y) tbl)
    | `Tag (tag, payload) ->
      Lwd.map ~f:(Ui.Ui.join_y (W.printf "tag(%d)" tag)) (traverse payload)
  and mk_k_v x y =
    let tr_x = traverse x in
    let summary = match y with
      | `Array _ | `Map _ ->
        W.hbox [tr_x; Lwd.return (W.string ~attr:A.(bg @@ gray 15) "/")]
      | _ -> tr_x
    in
    W.unfoldable summary (fun () -> traverse ~fold:false y)
  in
  let w = Lwd.map2 ~f:Ui.Ui.join_y
      w_q (Nottui_widgets.scroll_area @@ traverse ~fold:true c)
  in
  quit, w

let show_file f =
  let cbor = CCIO.with_in f (fun ic -> CCIO.read_all ic |> C.decode) in
  let quit, ui = ui_of_cbor cbor in
  Lwd.set body ui;
  Nottui_unix.run ~quit ~tick_period:0.2 (W.window_manager_view wm)

let () =
  let f = ref "" in
  Arg.parse (Arg.align [
    ]) (fun x -> f := x) "cbor_explorer <file>";
  if !f = "" then failwith "please provide a cbor file";
  show_file !f
