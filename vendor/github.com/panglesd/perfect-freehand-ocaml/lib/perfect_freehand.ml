let get_stroke = Jv.get Jv.global "getStroke"
let get_svg_path_from_stroke = Jv.get Jv.global "getSvgPathFromStroke"
module Point = struct
  type t = Jv.Jarray.t
  let v x y = Jv.of_list Jv.of_float [ x ; y]

            let get_x v = Jv.Jarray.get v 0 |> Jv.to_float
            let get_y v = Jv.Jarray.get v 1
 |> Jv.to_float
  include (Jv.Id : Jv.CONV with type t := t)
end

module Options = struct
  type t = Jv.t

  let v ?size ?thinning ?smoothing ?streamline ?last () =
    Jv.obj [|
        ("size", Jv.of_option ~none:Jv.undefined Jv.of_float size);
        ("thinning", Jv.of_option ~none:Jv.undefined  Jv.of_float thinning);
        ("smoothing", Jv.of_option ~none:Jv.undefined  Jv.of_float smoothing);
        ("streamline", Jv.of_option  ~none:Jv.undefined   Jv.of_float streamline);
        ("last", Jv.of_option  ~none:Jv.undefined   Jv.of_bool last);
      |]
  include (Jv.Id : Jv.CONV with type t := t)
end
let get_stroke ?options x =
  let x = Jv.of_list Point.to_jv x in
  let res =  match options with None ->  Jv.apply get_stroke [|x|] | Some options ->  Jv.apply get_stroke [|x; options|] in
  Jv.to_list Point.of_jv res

let get_svg_path_from_stroke x =
  let x = Jv.of_list Point.to_jv x in
  let res =   Jv.apply get_svg_path_from_stroke [|x|] in
  Jv.to_jstr res
