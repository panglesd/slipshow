module Types = Types
open Types
module Color = Color
module Width = Width
module Tool = Tool
module State = State
module Event = Event
module Stroke = Stroke
module Tools = Tools
module Record = Record
module Replay = Replay
module Strokes = Strokes
module Utils = Utils

val setup : Brr.El.t -> unit
val send_all_strokes : unit -> unit
val receive_all_strokes : string list -> unit
