open Code_mirror

module Tooltip_view = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let dom t = Jv.get t "dom" |> Brr.El.of_jv

  type offset = { x : int; y : int }
  type coords = { left : int; right : int; top : int; bottom : int }

  let offset_of_jv o = { x = Jv.Int.get o "x"; y = Jv.Int.get o "y" }

  let offset_to_jv { x; y } =
    let o = Jv.obj [||] in
    Jv.Int.set o "x" x;
    Jv.Int.set o "y" y;
    o

  let _coords_of_jv o =
    {
      left = Jv.Int.get o "left";
      right = Jv.Int.get o "right";
      top = Jv.Int.get o "top";
      bottom = Jv.Int.get o "bottom";
    }

  let coords_to_jv { left; right; top; bottom } =
    let o = Jv.obj [||] in
    Jv.Int.set o "left" left;
    Jv.Int.set o "right" right;
    Jv.Int.set o "top" top;
    Jv.Int.set o "bottom" bottom;
    o

  let offset t = Jv.get t "offset" |> offset_of_jv

  let create ~dom ?offset ?get_coords ?overlap ?mount ?update ?positioned () =
    let get_coords =
      Option.map
        (fun get_coords ->
          Jv.repr (fun pos -> get_coords (Jv.to_int pos) |> coords_to_jv))
        get_coords
    in
    let o = Jv.obj [||] in
    Jv.set o "dom" (Brr.El.to_jv dom);
    Jv.set_if_some o "offset" @@ Option.map offset_to_jv offset;
    Jv.set_if_some o "getCoords" get_coords;
    Jv.Bool.set_if_some o "overlap" overlap;
    Jv.set_if_some o "mount"
    @@ Option.map
         (fun mount -> Jv.repr (fun view -> mount (Editor.View.of_jv view)))
         mount;
    Jv.set_if_some o "update"
    @@ Option.map
         (fun update ->
           Jv.repr (fun view_up -> update (Editor.View.Update.of_jv view_up)))
         update;
    Jv.set_if_some o "positioned" @@ Option.map Jv.repr positioned;
    o
end

module Tooltip = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let pos t = Jv.Int.get t "pos"
  let end_ t = Jv.to_option Jv.to_int @@ Jv.get t "end"

  let create ~pos ?end_ ~create ?above ?strict_side ?arrow () =
    let o = Jv.obj [||] in
    Jv.Int.set o "pos" pos;
    Jv.Int.set_if_some o "end" end_;
    Jv.set o "create"
    @@ Jv.repr (fun view ->
           create (Editor.View.of_jv view) |> Tooltip_view.to_jv);
    Jv.Bool.set_if_some o "above" above;
    Jv.Bool.set_if_some o "strictSide" strict_side;
    Jv.Bool.set_if_some o "arrow" arrow;
    o
end

type hover_config = Jv.t

let hover_config ?hide_on_change ?hover_time () =
  let o = Jv.obj [||] in
  Jv.Bool.set_if_some o "hide_on_change" hide_on_change;
  Jv.Int.set_if_some o "hover_time" hover_time;
  o

let hover_tooltip ?config source =
  (* let g = Jv.get Jv.global "__CM__hoverTooltip" in *)
  let source =
    Jv.repr @@ fun view pos side ->
    let fut =
      source ~view:(Editor.View.of_jv view) ~pos:(Jv.to_int pos)
        ~side:(Jv.to_int side)
    in
    let fut = Fut.map (fun v -> Ok v) fut in
    Fut.to_promise fut ~ok:(fun t ->
        Option.value ~default:Jv.null (Option.map Tooltip.to_jv t))
  in
  let args =
    if Option.is_none config then [| source |]
    else [| source; Option.get config |]
  in
  Jv.call Jv.global "__CM__hoverTooltip" args |> Extension.of_jv
