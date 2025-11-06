open Nottui
module P = Nottui_pretty

let string ?attr text = P.ui (Nottui_widgets.string ?attr text)

let (^^) = P.(^^)
let (^/^) a b = P.(a ^^ break 1 ^^ b)

let base = Lwd.var Nottui_widgets.empty_lwd

let wm = Nottui_widgets.window_manager (Lwd.join (Lwd.get base))

let spring = P.ui (Ui.resize ~sw:1 Ui.empty)

let selector text f choices =
  Nottui_widgets.main_menu_item wm text (fun () ->
      Lwd.pure @@ Ui.vcat (
        List.map
          (fun choice ->
             Nottui_widgets.sub_entry choice (fun () -> f choice))
          choices
      )
    )

let fruit =
  let fruits = ["Apple"; "Orange"; "Strawberry"] in
  let choice = Lwd.var (List.hd fruits) in
  Lwd.join (
    Lwd.map (Lwd.get choice)
      ~f:(fun current -> selector current (Lwd.set choice) fruits)
  )

let doc = Lwd_table.make ()

let () =
  for _ = 0 to 99 do
    List.iter (fun doc' -> Lwd_table.append' doc (Lwd.pure doc'))
      [
        P.group (string "This" ^/^ string "is" ^/^ string "pretty.");
        P.hardline; P.ui (Ui.space 0 1); P.hardline;
        P.group (P.group (string "This" ^/^ string "is") ^/^ string "pretty.");
        P.hardline; P.ui (Ui.space 0 1); P.hardline;
        P.group (string "This" ^/^ P.group (string "is" ^/^ string "pretty."));
        P.hardline; P.ui (Ui.space 0 1); P.hardline;
        P.group (spring ^^ string "This" ^^ spring ^/^
                 P.group (string "is" ^^ spring ^/^ string "pretty.") ^^ spring);
        P.hardline; P.ui (Ui.space 0 1); P.hardline;
      ];
    Lwd_table.append' doc
      (Lwd.map fruit ~f:(fun fruit ->
           P.group (spring ^^ string "I" ^^ spring ^/^
                    P.group (string "like" ^^ spring ^/^
                             P.ui fruit ^^ spring ^/^
                             string "more.") ^^ spring);
         ))
  done

let varying_width f =
  let width = Lwd.var 0 in
  Lwd.map (f (Lwd.get width)) ~f:(fun ui ->
      Ui.size_sensor
        (fun ~w ~h:_ -> if Lwd.peek width <> w then Lwd.set width w)
        (Ui.resize ~sw:1 ~sh:1 ~w:0 ui)
    )

let doc =
  Lwd.join (Lwd_table.reduce (Lwd_utils.lift_monoid (P.empty, P.(^^))) doc)

let contents width = Lwd.map2 ~f:P.pretty width doc

let () =
  Lwd.set base (
    Nottui_widgets.h_pane
      (Nottui_widgets.scroll_area (varying_width contents))
      (Lwd.pure Ui.empty)
  );
  Nottui_unix.run (Nottui_widgets.window_manager_view wm)
