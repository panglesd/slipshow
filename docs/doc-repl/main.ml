open Code_mirror

let view ~dimension ~preview_el ~editor_el starting =
  let open Editor in
  let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv in
  let dark_mode =
    let dark = Jv.get Jv.global "__CM__dark" in
    let oneDark = Jv.get dark "oneDark" in
    Extension.of_jv oneDark
  in
  let markdown_extension =
    Jv.apply (Jv.get Jv.global "__CM__markdown") [||] |> Extension.of_jv
  in
  let frontmatter =
    (Resolved
       {
         toplevel_attributes = None;
         math_link = None;
         theme = None;
         css_links = [];
         js_links = [];
         dimension;
         highlightjs_theme = None;
       }
      : _ Slipshow.Frontmatter.t)
  in
  let config =
    State.Config.create ~doc:(Jstr.v starting)
      ~extensions:
        [|
          basic_setup;
          markdown_extension;
          dark_mode;
          Slipshow_communication.slipshow_plugin ~frontmatter preview_el;
        |]
      ()
  in
  let state = State.create ~config () in
  let opts = Editor.View.opts ~state ~parent:editor_el () in
  Editor.View.create ~opts ()

let ( !! ) = Jstr.v

let do_ ~dimension ~editor_el ~preview_el starting =
  let _view = view ~dimension ~preview_el ~editor_el starting in
  ()

type mode = Show_editor | Show_presentation | Show_both

let all_modes = [ Show_both; Show_editor; Show_presentation ]

let () =
  let _ =
    Brr.Ev.listen Brr.Ev.load
      (fun _ ->
        let _ =
          Brr.El.fold_find_by_selector
            (fun el () ->
              let open Brr in
              let dimension =
                El.at !!"dimension" el |> Option.map Jstr.to_string |> fun x ->
                Option.bind x (fun s ->
                    match Slipshow.Frontmatter.String_to.dimension s with
                    | Ok x -> Some x
                    | Error _ -> None)
              in
              let ffbs_unsafe c =
                El.find_first_by_selector ~root:el !!c |> Option.get
              in
              let content =
                let source = ffbs_unsafe ".source" in
                Jv.get (Brr.El.to_jv source) "textContent" |> Jv.to_string
              in
              let editor_el = ffbs_unsafe ".editor" in
              let preview_el = ffbs_unsafe ".preview" in
              let editor_button = ffbs_unsafe ".editor-button" in
              let pres_button = ffbs_unsafe ".pres-button" in
              let both_button = ffbs_unsafe ".both-button" in
              let fullscreen_button = ffbs_unsafe ".fullscreen-button" in
              let () =
                let fullscreen = ref false in
                Ev.(listen click)
                  (fun _ ->
                    fullscreen := not !fullscreen;
                    El.set_class !!"fullscreen" !fullscreen el)
                  (El.as_target fullscreen_button)
                |> ignore
              in
              let new_el = ffbs_unsafe ".entry" in
              (* See also the python file _ext/slipshowexample.py *)
              let mode_to_string = function
                | Show_editor -> Jstr.v "show-editor"
                | Show_presentation -> Jstr.v "show-presentation"
                | Show_both -> Jstr.v "show-both"
              in
              let () =
                let set_class v =
                  let set v b = El.set_class (mode_to_string v) b new_el in
                  List.iter (fun m -> set m false) all_modes;
                  set v true
                in
                let listen v el =
                  Ev.(listen click) (fun _ -> set_class v) (El.as_target el)
                  |> ignore
                in
                listen Show_editor editor_button;
                listen Show_presentation pres_button;
                listen Show_both both_button
              in
              do_ ~dimension ~preview_el ~editor_el content)
            !!".running-example" ()
        in
        ())
      (Brr.Window.as_target Brr.G.window)
  in
  ()
