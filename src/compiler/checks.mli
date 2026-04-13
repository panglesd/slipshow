open Actions_arguments

module Unknow_attributes : sig
  val no_unknown_attributes : Cmarkit.Attributes.t * 'a -> unit
end

type 'a checks :=
  Id_map.t -> args:'a -> val_loc:Diagnosis.loc -> Ast.Bol.t -> Id_map.t

val exec : Execute.args checks
val enter : Enter.args checks
val up : Up.args checks
val down : Down.args checks
val center : Center.args checks
val scroll : Scroll.args checks
val focus : Focus.args checks
val unfocus : Unfocus.args checks
val unstatic : Unstatic.args checks
val static : Static.args checks
val reveal : Reveal.args checks
val unreveal : Unreveal.args checks
val emph : Emph.args checks
val unemph : Unemph.args checks
val speaker_note : Speaker_note.args checks
val play_media : Play_media.args checks
val change_page : Change_page.args checks
val draw : Draw.args checks
val clear : Clear_draw.args checks
val pause : Pause.args checks
val step : Step.args checks
