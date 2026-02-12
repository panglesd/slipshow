type payload =
  | State of int * [ `Fast | `Normal ]
  | Ready
  | Set_state of int * [ `Fast | `Normal ]
  | Open_speaker_notes
  | Close_speaker_notes
  | Open_recording_panel
  | Close_recording_panel
  | Speaker_notes of string
  | Drawing of string
  | Send_all_drawing
  | Receive_all_drawing of string list
  | Save_drawing of string * string (* path * content *)
  | Next
  | Previous
  | Can_save
  | Can_gui
  | ActivateGUI of Common_types.gui_id
  | DeActivateGUI
  | SaveCoordinates of {
      id : Common_types.gui_id;
      x : int option;
      y : int option;
      w : int option;
      h : int option;
      scale : float option;
    }
  | GotoLoc of string
  | Stop_moving

type t = { payload : payload; id : string }

val of_string : string -> t option
val to_string : t -> string
