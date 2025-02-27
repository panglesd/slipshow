(*---------------------------------------------------------------------------
   Copyright (c) 2021 The cmarkit programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Data needed for CommonMark parsing. *)

(** {1:unicode Unicode data} *)

val unicode_version : string
(** [unicode_version] is the supported Unicode version. *)

val is_unicode_whitespace : Uchar.t -> bool
(** [is_unicode_whitespace u] is [true] iff
    [u] is a CommonMark
    {{:https://spec.commonmark.org/current/#unicode-whitespace-character}
    Unicode whitespace character}. *)

val is_unicode_punctuation : Uchar.t -> bool
(** [is_unicode_punctuation u] is [true] iff
    [u] is a CommonMark
    {{:https://spec.commonmark.org/current/#unicode-punctuation-character}
    Unicode punctuation character}. *)

val unicode_case_fold : Uchar.t -> string option
(** [unicode_case_fold u] is the UTF-8 encoding of [u]'s Unicode
    {{:http://www.unicode.org/reports/tr44/#Case_Folding}case fold} or
    [None] if [u] case folds to itself. *)

(** {1:html HTML data} *)

val html_entity : string -> string option
(** [html_entity e] is the UTF-8 data for of the HTML entity {e name}
    (without [&] and [;]) [e]. *)
