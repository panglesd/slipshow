open Actions_arguments

type arg =
  | Enter of Enter.args
  | Clear_draw of Clear_draw.args
  | Draw of Draw.args
  | Pause of Pause.args
  | Step of Step.args
  | Up of Up.args
  | Down of Down.args
  | Center of Center.args
  | Scroll of Scroll.args
  | Change_page of Change_page.args
  | Focus of Focus.args
  | Unfocus of Unfocus.args
  | Execute of Execute.args
  | Unstatic of Unstatic.args
  | Static of Static.args
  | Reveal of Reveal.args
  | Unreveal of Unreveal.args
  | Emph of Emph.args
  | Unemph of Unemph.args
  | Speaker_note of Speaker_note.args
  | Play_media of Play_media.args

type action = arg * Cmarkit.Attributes.kv

type step = {
  actions : action list;
  elem : Ast.Bol.t;
  attrs : Cmarkit.Attributes.t Cmarkit.node;
}

type t = step list

val execute : id_map:Id_map.t -> Ast.t -> t
