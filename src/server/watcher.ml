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

(* A single function should be run in several cases. We don't want the function
   to be run twice at the same time. So we make it wait on a condition and each
   callback just signal that condition. *)

let watch_and_compile ~callback (* k *) =
  let depending_on_files = ref Fpath.Set.empty in
  let listened_directories = ref Fpath.Map.empty in
  (* let cond = Lwt_condition.create () in *)
  let rec compile_and_call_k () =
    match callback () with
    | Ok new_dependencies -> update new_dependencies listened_directories
    | Error (`Msg s) ->
        Logs.warn (fun m -> m "%s" s);
        Lwt.return_unit
  and watch =
    let callback prefix filename =
      let full_name = Fpath.normalize @@ Fpath.( / ) prefix filename in
      if Fpath.Set.mem full_name !depending_on_files then compile_and_call_k ()
      else Lwt.return_unit
    in
    fun dir ->
      Logs.info (fun m -> m "Watching %a" Fpath.pp dir);
      Irmin_watcher.hook 0 (Fpath.to_string dir) (callback dir)
  and update new_dependencies listened_directories =
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
    Logs.info (fun m ->
        m "updating file dependencies to %a"
          (Fmt.list ~sep:Fmt.sp Fpath.pp)
          (Fpath.Set.fold (fun a x -> a :: x) new_dependencies []));
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
  compile_and_call_k ()
