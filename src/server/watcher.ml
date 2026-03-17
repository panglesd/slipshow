open Lwt.Syntax

(* We need:
   - A list of directories we are watching
   - A list of files we depend on

   We need to keep those lists in sync:
   - If we do not depend on any files in a directory, we should stop watching it
   - When we start depending on a file, we should listen its parent directory if not already the case

   When we compile the presentation, we should record a list of the files we depend on.
   We should then update the list of directories we watch,
   start listening new directories
   stop listening some of them
   ...
 *)

let watch_and_compile initial_deps ~callback =
  let mutex = Lwt_mutex.create () in
  let depending_on_files = ref Fpath.Set.empty in
  let listened_directories = ref Fpath.Map.empty in
  let rec compile_and_watch () =
    match callback () with
    | Ok new_dependencies -> update new_dependencies
    | Error (`Msg s) ->
        Logs.warn (fun m -> m "%s" s);
        Lwt.return_unit
  and watch =
    let callback prefix filename =
      let full_name = Fpath.normalize @@ Fpath.( / ) prefix filename in
      if Fpath.Set.mem full_name !depending_on_files then compile_and_watch ()
      else Lwt.return_unit
    in
    fun dir ->
      Logs.info (fun m -> m "Watching %a" Fpath.pp dir);
      Irmin_watcher.hook 0 (Fpath.to_string dir) (callback dir)
  and update new_dependencies =
    Lwt_mutex.with_lock mutex @@ fun () ->
    let* new_listened_directories =
      (* Some new dependencies may require new directories to be watched *)
      Fpath.Set.fold
        (fun dir map ->
          match Fpath.Map.find_opt dir !listened_directories with
          | Some u ->
              let+ map = map in
              Fpath.Map.add dir u map
          | None ->
              if
                try Sys.is_directory (Fpath.to_string dir)
                with Sys_error _ -> false
              then
                let+ u = watch dir and+ map = map in
                Fpath.Map.add dir u map
              else map)
        (Fpath.Set.map
           (* Fold on the parent's set to avoid duplication on file's parent dir *)
           (fun file -> file |> Fpath.parent |> Fpath.normalize)
           new_dependencies)
        (Lwt.return Fpath.Map.empty)
    in
    let to_add = Fpath.Set.diff new_dependencies !depending_on_files in
    let to_remove = Fpath.Set.diff !depending_on_files new_dependencies in
    let () =
      let to_list set = Fpath.Set.fold (fun a x -> a :: x) set [] in
      let log set verb =
        match to_list set with
        | [] -> ()
        | l ->
            Logs.app (fun m ->
                m "%s dependency on %a" verb (Fmt.list ~sep:Fmt.sp Fpath.pp) l)
      in
      log to_add "Adding";
      log to_remove "Removing"
    in
    let+ () =
      (* The new set of file dependencies may NOT need some directories to be
         watched anymore *)
      Fpath.Map.fold
        (fun dir unwatch acc ->
          let* () = acc in
          if not (Fpath.Map.mem dir new_listened_directories) then (
            Logs.info (fun m -> m "Unwatching: %a" Fpath.pp dir);
            unwatch ())
          else Lwt.return ())
        !listened_directories Lwt.return_unit
    in
    depending_on_files := new_dependencies;
    listened_directories := new_listened_directories
  in
  let* () = update initial_deps in
  let* () = compile_and_watch () in
  (* Just a way to never return *)
  Lwt.wait () |> fst
