open Code_mirror

let lsp_client_class = lazy (Jv.get Jv.global "__CM__LSPClient")

let language_server_extensions_fn =
  lazy (Jv.get Jv.global "__CM__languageServerExtensions")

module LSPClientConfig = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let create ?root_uri ?workspace ?timeout ?sanitize_html ?highlight_language
      ?notification_handlers ?unhandled_notification ?extensions () =
    let o = Jv.obj [||] in
    Jv.set_if_some o "rootUri" (Option.map Jv.of_string root_uri);
    Jv.set_if_some o "workspace"
      (Option.map
         (fun f -> Jv.callback ~arity:1 (fun client -> f client))
         workspace);
    Jv.set_if_some o "timeout" (Option.map Jv.of_int timeout);
    Jv.set_if_some o "sanitizeHTML"
      (Option.map
         (fun f ->
           Jv.callback ~arity:1 (fun html ->
               Jv.of_string (f (Jv.to_string html))))
         sanitize_html);
    Jv.set_if_some o "highlightLanguage"
      (Option.map
         (fun f ->
           Jv.callback ~arity:1 (fun name ->
               match f (Jv.to_string name) with
               | Some lang -> lang
               | None -> Jv.null))
         highlight_language);
    Jv.set_if_some o "notificationHandlers"
      (Option.map
         (fun handlers ->
           let obj = Jv.obj [||] in
           List.iter
             (fun (method_, handler) ->
               Jv.set obj method_
                 (Jv.callback ~arity:2 (fun client params ->
                      Jv.of_bool (handler client params))))
             handlers;
           obj)
         notification_handlers);
    Jv.set_if_some o "unhandledNotification"
      (Option.map
         (fun f ->
           Jv.callback ~arity:3 (fun client method_ params ->
               f client (Jv.to_string method_) params))
         unhandled_notification);
    Jv.set_if_some o "extensions"
      (Option.map (Jv.of_list Extension.to_jv) extensions);
    o

  let undefined : t = Jv.undefined
end

module Transport = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let create ~send ~subscribe ~unsubscribe =
    let o = Jv.obj [||] in
    Jv.set o "send" (Jv.callback ~arity:1 (fun msg -> send (Jv.to_jstr msg)));
    Jv.set o "subscribe"
      (Jv.callback ~arity:1 (fun handler ->
           subscribe (fun msg ->
               Jv.apply handler [| Jv.of_jstr msg |] |> ignore)));
    Jv.set o "unsubscribe"
      (Jv.callback ~arity:1 (fun handler ->
           unsubscribe (fun msg ->
               Jv.apply handler [| Jv.of_jstr msg |] |> ignore)));
    o
end

module LSPClient = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let create ?(config : LSPClientConfig.t = LSPClientConfig.undefined) () : t =
    Jv.new' (Lazy.force lsp_client_class) [| LSPClientConfig.to_jv config |]

  let connect t transport = Jv.call t "connect" [| Transport.to_jv transport |]
  let disconnect t = Jv.call t "disconnect" [||] |> ignore

  let plugin t ~file_uri ?language_id () =
    let args =
      match language_id with
      | None -> [| Jv.of_string file_uri |]
      | Some lid -> [| Jv.of_string file_uri; Jv.of_string lid |]
    in
    Jv.call t "plugin" args |> Extension.of_jv

  let initializing t =
    let promise = Jv.get t "initializing" in
    Fut.of_promise ~ok:(fun _ -> ()) promise

  let notification t ~method_ ~params =
    Jv.call t "notification" [| Jv.of_string method_; params |] |> ignore

  let request t ~method_ ~params =
    let promise = Jv.call t "request" [| Jv.of_string method_; params |] in
    Fut.of_promise ~ok:Fun.id promise

  let connected t = Jv.Bool.get t "connected"
end

module Extensions = struct
  let language_server_extensions () =
    Jv.apply (Lazy.force language_server_extensions_fn) [||]
    |> Jv.to_list Extension.of_jv

  let jump_to_definition_keymap : Keymap.t =
    Jv.get Jv.global "__CM__jumpToDefinitionKeymap"
end
