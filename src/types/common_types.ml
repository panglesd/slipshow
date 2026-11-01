open Sexplib.Std
module Special_strings = Special_strings

type gui_id = Id of string | Loc of { file : string; gui_id : string }
[@@deriving sexp]

type to_server =
  | Update
  | Control of Proto.Server_to_client.control
  | ActivateGUI of gui_id
  | DeActivateGUI
  | Notify of string

type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}
