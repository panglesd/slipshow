module Highlightjs_data = Highlightjs_data
module Languages = Languages
module S = Set.Make (String)

let lang_scripts lang_list =
  let s, unknown_language, ambiguous_language =
    S.fold
      (fun l (s, unknown_language, ambiguous_language) ->
        match Hashtbl.find_all Languages.map l with
        | [] ->
            let unknown_language = S.add l unknown_language in
            (s, unknown_language, ambiguous_language)
        | [ language_name ] ->
            let s = S.add language_name s in
            (s, unknown_language, ambiguous_language)
        | langs ->
            let ambiguous_language = (l, langs) :: ambiguous_language in
            let s = List.fold_left (Fun.flip S.add) s langs in
            (s, unknown_language, ambiguous_language))
      lang_list (S.empty, S.empty, [])
  in
  let () =
    S.iter
      (fun unknown_language ->
        (* TODO: make a proper error *)
        Logs.warn (fun m ->
            m
              "'%s' is unknown of highlightjs. Broken highlighting will happen \
               for this code block."
              unknown_language))
      unknown_language
  in
  let () =
    List.iter
      (fun (ambiguous_language, possible) ->
        (* TODO: make a proper error *)
        Logs.warn (fun m ->
            m
              "'%s' can refer to multiple languages: %s. Use one from this \
               list."
              ambiguous_language
              (String.concat ", " possible)))
      ambiguous_language
  in
  S.fold
    (fun lang acc ->
      let filename = "languages/" ^ lang ^ ".min.js" in
      Highlightjs_data.read filename |> Option.get |> fun x -> x :: acc)
    s []

let styles theme =
  let filename theme = "styles/" ^ theme ^ ".min.css" in
  match Highlightjs_data.read (filename theme) with
  | None ->
      (* TODO: make a proper error *)
      Logs.err (fun m ->
          m "Highlight js theme \"%s\" is not bundled in Slipshow" theme);
      Option.get @@ Highlightjs_data.read (filename "default")
  | Some s -> s

let script = Option.get @@ Highlightjs_data.read "highlight.min.js"
