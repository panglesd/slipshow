open Nottui
open Nottui_widgets

(* App-specific widgets *)

let simple_edit x =
  let var = Lwd.var (x, 0) in
  edit_field (Lwd.get var) ~on_change:(Lwd.set var) ~on_submit:ignore

let strict_table () =
  let columns = Lwd_table.make () in
  for colidx = 0 to 99 do
    let rows = Lwd_table.make () in
    Lwd_table.append' rows (printf "Column %d" colidx |> Lwd.pure);
    for rowidx = 0 to 99 do
      Lwd_table.append' rows
        (simple_edit (Printf.sprintf "Test-%03d-%03d" colidx rowidx))
    done;
    Lwd_table.append' columns
      ( rows
        |> Lwd_table.reduce (Lwd_utils.lift_monoid Ui.pack_y)
        |> Lwd.join );
    Lwd_table.append' columns (Lwd.return (string " "))
  done;
  scroll_area
  @@ Lwd.join (Lwd_table.reduce (Lwd_utils.lift_monoid Ui.pack_x) columns)

(*let lazy_table t =
  let t = scroll_area t in
  let column_header = Adom.transform' t Ui.pack_x in
  for col = 0 to 999 do
    let rec render_row row size =
      if size > 1 then
        let size' = size / 2 in
        [ Lazy {w = 10; h = size';
                f = lazy (render_row row size')};
          Lazy {w = 10; h = size - size';
                f = lazy (render_row (row + size') (size - size'))};
        ]
      else
        [ Sub (fun t -> edit_field t (Printf.sprintf "Test-%03d-%03d" col row)) ]
    in
    co_nodes
      (Adom.transform' column_header Ui.y)
      (render_row 0 1000);
    Adom.add column_header (string " ");
  done
*)

(*let rec make_splitview ?clear body =
  let body = Adom.transform' body Ui.y in
  let menu = Adom.transform' body Ui.x in
  let body = Adom.sub body in
  let rec view_menu () =
    Adom.clear menu;
    main_menu_item menu "View" (fun overlay ->
        sub_entry overlay "Split V"
          (fun _ ->
             Adom.clear body;
             let a, b = v_pane body in
             make_splitview ~clear:view_menu a;
             make_splitview b;
             Adom.clear menu;
          );
        sub_entry overlay "Split H"
          (fun _ ->
             Adom.clear body;
             let a, b = h_pane body in
             make_splitview ~clear:view_menu a;
             make_splitview b;
             Adom.clear menu;
          )
      );
    begin match clear with
      | None -> ()
      | Some f -> main_menu_item menu "Clear" (fun _ -> f())
    end;
    Adom.clear body;
    if false
    then strict_table body
    else lazy_table body;
  in
  view_menu ()
*)

(* Entry point *)

let top = Lwd.var (Lwd.return Ui.empty)

let bot = Lwd.var (Lwd.return Ui.empty)

let wm =
  Nottui_widgets.window_manager @@
  Lwd_utils.pack Ui.pack_y [ Lwd.join (Lwd.get top); Lwd.join (Lwd.get bot) ]

(*let () = Statmemprof_emacs.start 1E-4 30 5*)

let () =
  Lwd.set top @@
  Lwd_utils.pack Ui.pack_x
    [
      main_menu_item wm "File" (fun () ->
          Lwd_utils.pack Ui.pack_y
            [
              Lwd.return @@ sub_entry "New" ignore;
              Lwd.return @@ sub_entry "Open" ignore;
              sub_menu_item wm "Recent" (fun () ->
                  Lwd_utils.pack Ui.pack_y
                    [
                      Lwd.return @@ sub_entry "A" ignore;
                      Lwd.return @@ sub_entry "B" ignore;
                      Lwd.return @@ sub_entry "CD" ignore;
                    ]);
              Lwd.return @@ sub_entry "Quit" (fun () -> raise Exit);
            ]);
      main_menu_item wm "View" (fun _ ->
          Lwd.set bot (Lwd.return (string "<View>"));
          Lwd.return Ui.empty);
      main_menu_item wm "Edit" (fun _ ->
          Lwd.set bot (Lwd.return (string "<Edit>"));
          Lwd.return Ui.empty);
    ];
  Lwd.set bot @@
  Lwd_utils.pack Ui.pack_y
    [
      simple_edit "Hello world";
      v_pane (strict_table ()) (Lwd.return @@ string "B");
      h_pane (Lwd.return (string "A")) (Lwd.return (string "B"));
    ];
  try Nottui_unix.run ~tick_period:0.2 (window_manager_view wm)
  with Exit -> ()
