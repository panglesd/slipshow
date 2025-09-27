let map_time time1 time2 new_duration time =
  if time <= time1 then time
  else if time >= time2 then time -. time2 +. time1 +. new_duration
  else time1 +. ((time -. time1) *. new_duration /. (time2 -. time1))

let change_path path time1 time2 new_duration =
  let map_time = map_time time1 time2 new_duration in
  List.map (fun (pos, time) -> (pos, map_time time)) path

let translate path t0 = List.map (fun (pos, time) -> (pos, time +. t0)) path

let add_time path from amount =
  List.map
    (fun ((pos, time) as s) ->
      if time <= from then s else (pos, time +. amount))
    path
