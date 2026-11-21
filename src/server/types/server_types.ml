type to_server =
  | Update
  | Control of Proto.Server_to_client.control
  | ActivateGUI of Common_types.gui_id
  | DeActivateGUI
  | Notify of string

type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type roots = (Fpath.t -> root option) * (unit -> Fpath.t list)
