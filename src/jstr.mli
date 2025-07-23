(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** JavaScript strings *)

type t
(** The type for JavaScript UTF-16 encoded strings. *)

external v : string -> t = "caml_jsstring_of_string"
(** [v s] is the UTF-8 encoded OCaml string [s] as a JavaScript string. *)

val length : t -> int
(** [length s] is the length of [s]. *)

val get : t -> int -> Uchar.t
(** [get s i] is the Unicode character at position [i] in [s]. If this
    happens to be a lone low or any high
    {{:http://www.unicode.org/glossary/#surrogate_code_point}surrogate}
    surrogate, {!Uchar.rep} is returned. Raises
    [Invalid_argument] if [i] is out of bounds. *)

val get_jstr : t -> int -> t
(** [get_jstr t i] is like {!get} but with the character as
    a string. *)

(** {1:csts Constants} *)

val empty : t
(** [empty] is an empty string. *)

val sp : t
(** [sp] is [Jstr.v " "]. *)

val nl : t
(** [nl] is [Jstr.v "\n"]. *)

(** {1:assemble Assembling} *)

val append : t -> t -> t
(** [append s0 s1] appends [s1] to [s0]. *)

val ( + ) : t -> t -> t
(** [s0 + s1] is [append s0 s1]. *)

val concat : ?sep:t -> t list -> t
(** [concat ?sep ss] is the concatenates the list of strings [ss]
      inserting [sep] between each of them (defaults to {!empty}). *)

val pad_start : ?pad:t -> int -> t -> t
(** [pad_start ~pad n s] is [s] with [pad] strings prepended to [s]
    until the length of the result is [n] or [s] if [length s >= n].
    The first prepended [pad] may be truncated to satisfy the
    constraint. [pad] defaults to {!sp}.

    {b Warning.} Since {!length} is neither the number of Unicode
    characters of [s] nor its number of
    {{:http://www.unicode.org/glossary/#grapheme}grapheme clusters},
    if you are using this for visual layout, it will fail in many
    cases. At least consider {{!normalized}normalizing} [s] to [`NFC]
    before. *)

val pad_end : ?pad:t -> int -> t -> t
(** [pad_end ~pad n s] is [s] with [pad] strings appended to [s] until
    the {!length} of the result is [n] or [s] if [length s >= n]. The
    last appended [pad] may be truncated to satisfy the constraint.
    [pad] defaults to {!sp}.

    {b Warning.} Since {!length} is neither the number of Unicode
    characters of [s] nor its number of
    {{:http://www.unicode.org/glossary/#grapheme}grapheme clusters},
    if you are using this for visual layout, it will fail in many
    cases. At least consider {{!normalized}normalizing} [s] to [`NFC]
    before. *)

val repeat : int -> t -> t
(** [repeat n s] is [s] repeated [n] times. Raises {!Jv.exception-Error} if [n]
    is negative. *)

(** {1:finding Finding} *)

val find_sub : ?start:int -> sub:t -> t -> int option
(** [find_sub ~start ~sub s] is the start index (if any) of the first occurence
    of [sub] in [s] at or after [start] . *)

val find_last_sub : ?before:int -> sub:t -> t -> int option
(** [find_last_sub ~before ~sub s] is the start index (if any) of the
    last occurence of [sub] in [s] before [before] (defaults to [length
    s]). *)

(** {1:breaking Breaking} *)

val slice : ?start:int -> ?stop:int -> t -> t
(** [slice ~start ~stop s] is the string s.[start], s.[start+1], ...
    s.[stop - 1]. [start] defaults to [0] and [stop] to
    [length s].

    If [start] or [stop] are negative they are subtracted from
    [length s]. This means that [-1] denotes the last
    character of the string. *)

val sub : ?start:int -> ?len:int -> t -> t
(** [sub ~start ~len s]  is the string s.[start], ... s.[start + len - 1].
    [start] default to [0] and [len] to [length s - start].

    If [start] is negative it is subtracted from [length s]. This
    means that [-1] denotes the last character of the string. If [len]
    is negative it is treated as [0]. *)

val cuts : sep:t -> t -> t list
(** [cuts sep s] is the list of all (possibly empty) substrings of [s]
    that are delimited by matches of the non empty separator string
    [sep]. *)

(** {1:traverse Traversing and transforming} *)

val fold_uchars : (Uchar.t -> 'a -> 'a) -> t -> 'a -> 'a
(** [fold_uchars f acc s] folds [f] over the Unicode characters of
    [s] starting with [acc]. Decoding errors (that is unpaired
    UTF-16 surrogates) are reported as {!Uchar.rep}. *)

val fold_jstr_uchars : (t -> 'a -> 'a) -> t -> 'a -> 'a
(** [fold_jstr_uchars] is like {!fold_uchars} but the characters
    are given as strings. *)

val trim : t -> t
(** [trim s] is [s] without whitespace from the beginning and end of
    the string. *)

(** {1:nf Normalization}

    For more information on normalization consult a short
    {{!page-unicode.equivalence}introduction}, the
    {{:http://www.unicode.org/reports/tr15/}UAX #15 Unicode
    Normalization Forms} and
    {{:http://www.unicode.org/charts/normalization/} normalization
    charts}. *)

type normalization = [`NFD | `NFC | `NFKD | `NFKC ]
(** The type for normalization forms.
    {ul
    {- [`NFD] {{:http://www.unicode.org/glossary/#normalization_form_d}
       normalization form D}, canonical decomposition.}
    {- [`NFC] {{:http://www.unicode.org/glossary/#normalization_form_c}
       normalization form C}, canonical decomposition followed by
       canonical composition.}
    {- [`NFKD] {{:http://www.unicode.org/glossary/#normalization_form_kd}
       normalization form KD}, compatibility decomposition.}
    {- [`NFKC] {{:http://www.unicode.org/glossary/#normalization_form_kc}
       normalization form KC}, compatibility decomposition,
       followed by canonical composition.}} *)

val normalized : normalization -> t -> t
(** [normalized nf t] is [t] normalized to [nf]. *)

(** {1:case Case mapping}

    For more information about case see the
    {{:http://unicode.org/faq/casemap_charprop.html#casemap}Unicode
    case mapping FAQ} and the
    {{:http://www.unicode.org/charts/case/}case mapping charts}. Note
    that these algorithms are insensitive to language and context and
    may produce sub-par results for some users. *)

val lowercased : t -> t
(** [lowercased s] is [s] lowercased according to Unicode's default case
    conversion. *)

val uppercased : t -> t
(** [lowercased s] is [s] uppercased according to Unicode's default case
    conversion. *)

(** {1:preds Predicates and comparisons} *)

val is_empty : t -> bool
(** [is_empty s] is [true] iff [s] is an empty string. *)

val starts_with : prefix:t -> t -> bool
(** [starts_with ~prefix s] is [true] iff [s] starts with [prefix] (as per
    {!equal}). *)

val includes : affix:t -> t -> bool
(** [includes ~suffix s] is [true] iff [s] includes [affix]
    (as per {!equal}). *)

val ends_with : suffix:t -> t -> bool
(** [ends_with ~suffix s] is [true] iff [s] ends with [suffix]
    (as per {!equal}). *)

val equal : t -> t -> bool
(** [equal s0 s1] is [true] iff [s0] and [s1] are equal. {b Warning.}
    Unless [s0] and [s1] are known to be in a particular normal form
    the test is {e textually} meaningless. *)

val compare : t -> t -> int
(** [compare s0 s1] is a total order on strings compatible with
    {!equal}. {b Warning.} The comparison is {e textually}
    meaningless. *)

(** {1:conv Conversions} *)

val of_uchar : Uchar.t -> t
(** [of_uchar u] is a string made of [u]. *)

val of_char : char -> t
(** [of_char c] is a string made of [c]. *)

external to_string : t -> string = "caml_string_of_jsstring"
(** [to_string s] is [s] as an UTF-8 encoded OCaml string. *)

external of_string : string -> t = "caml_jsstring_of_string"
(** [of_string s] is the UTF-8 encoded OCaml string [s] as a JavaScript
    string. *)

external binary_to_octets : t -> string = "caml_string_of_jsbytes"
(** [binary_to_octets s] is the JavaScript binary string [s] as an
    OCaml string of bytes. In [s] each 16-bit JavaScript character
    encodes a byte. *)

external binary_of_octets : string -> t = "caml_jsbytes_of_string"
(** [binary_of_octets s] is the OCaml string of bytes [s] as a
    JavaScript binary string in which each 16-bit character encodes
    a byte. *)

val to_int : ?base:int -> t -> int option
(** [to_int s] is the integer resulting from parsing [s] as a number
    in base [base] (guessed by default). The function uses
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseInt}[Number.parseInt]}
    and maps {!Float.nan} results to [None]. *)

val of_int : ?base:int -> int -> t
(** [of_int ~base i] formats [i] as a number in base [base] (defaults
    to [10]). Conversion is performed via
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toString}[Number.toString]}. *)

val to_float : t -> float
(** [to_float s] is the floating point number resulting from parsing
    [s]. This always succeeds and returns {!Float.nan} on unparseable
    inputs. The function uses
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseInt}[Number.parseFloat]}. *)

val of_float : ?frac:int -> float -> t
(** [of_float ~frac n] formats [n] with [frac] fixed fractional digits
    (or as needed if unspecified). This function uses {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toFixed}
    [Number.toFixed]} if [f] is specified and {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toString}[Number.toString]} otherwise. *)
