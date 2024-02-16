let ( let+ ) a b = Result.bind a b

let do_watch input f =
  match input with
  | `Stdin -> Error (`Msg "--watch is incompatible with stdin input")
  | `File input ->
      let input = Fpath.to_string input in
      let inotify = Inotify.create () in
      let _watch_descriptor =
        Inotify.add_watch inotify input [ Inotify.S_Modify ]
      in
      let rec loop () =
        let _event = Inotify.read inotify in
        (* Logs.app (fun m -> m "Change detected, recompiling"); *)
        let+ _ = f () in
        loop ()
      in
      loop ()

let do_serve input f =
  let do_serve input f =
    match input with
    | `Stdin ->
        Lwt.return
        @@ Error (`Msg "--watch-and-serve is incompatible with stdin input")
    | `File input ->
        let open Lwt.Syntax in
        let input = Fpath.to_string input in
        let* inotify = Lwt_inotify.create () in
        let _watch_descriptor =
          Lwt_inotify.add_watch inotify input [ Inotify.S_Modify ]
        in
        let waiter, resolver = Lwt.wait () in
        let waiter = ref waiter in
        let resolver = ref resolver in
        let content = ref "" in
        let _ =
          (* We serve on [127.0.0.1] since in musl libc library, localhost would
             trigger a DNS request (which might not resolve) *)
          Dream.serve ~interface:"127.0.0.1"
          @@ Dream_livereload.inject_script ()
          @@ Dream.router
               [
                 Dream.get "/" (fun _ -> Dream.html !content);
                 Dream.get "/_livereload" (fun _ ->
                     Dream.websocket (fun socket ->
                         let* () = !waiter in
                         Dream.close_websocket socket));
               ]
        in
        let rec loop () =
          let new_content = match f () with Ok s -> s | Error (`Msg s) -> s in
          content := new_content;
          let* _event = Lwt_inotify.read inotify in
          Lwt.wakeup_later !resolver ();
          let nwaiter, nresolver = Lwt.wait () in
          waiter := nwaiter;
          resolver := nresolver;
          loop ()
        in
        loop ()
  in
  Logs.app (fun m ->
      m
        "Visit http://127.0.0.1:8080 to view your presentation, with \
         auto-reloading on file changes.");
  Lwt_main.run @@ do_serve input f
