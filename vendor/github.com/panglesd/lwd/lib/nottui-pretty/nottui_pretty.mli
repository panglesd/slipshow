(**************************************************************************)
(*                                                                        *)
(*  Nottui_pretty, pretty-printer for Nottui                              *)
(*  Frédéric Bour, Tarides                                                *)
(*  Copyright 2020 Tarides. All rights reserved.                          *)
(*                                                                        *)
(*  Based on PPrint                                                       *)
(*  François Pottier, Inria Paris                                         *)
(*  Nicolas Pouillard                                                     *)
(*                                                                        *)
(*  Copyright 2007-2019 Inria. All rights reserved. This file is          *)
(*  distributed under the terms of the GNU Library General Public         *)
(*  License, with an exception, as described in the file LICENSE.         *)
(**************************************************************************)

(* The type of documents *)
type t

(* The empty document *)
val empty : t

(* A document representing a UI widget *)
val ui : Nottui.ui -> t

(* Forced line break *)
val hardline : t

(* White space *)
val blank : int -> t

(* Choose between two documents based on whether we are in flat-mode or not.
   First document should not force any hardline, otherwise it will completely
   disable flat mode (... it is not possible to be flat and have hardlines).
*)
val if_flat : t -> t -> t

(* [break n] behaves like [blank n] if flat or [hardline] if non-flat:
   If it fits on current line it displays [n] whitespaces, if not it breaks the
   current line. *)
val break : int -> t

(* Concatenate two documents *)
val ( ^^ ) : t -> t -> t

(* [nest n t] increases indentation level by [n] inside document [t]:
   if a new line has to be introduced in the layout [t], it will be shifted on
   the right by [n] columns. *)
val nest : int -> t -> t

(* [group t] introduces a choice point.
   If sub-documnet [t] fits on the current-line, it will be printed in flat
   mode.
   Otherwise [t] is printed as usual. *)
val group : t -> t

(* [pretty w t] renders document [t] targetting optimal width [w]. *)
val pretty : int -> t -> Nottui.ui
