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

(* -------------------------------------------------------------------------- *)

(* A type of integers with infinity. *)

type requirement =
  int (* with infinity *)

(* Infinity is encoded as [max_int]. *)

let infinity : requirement =
  max_int

(* Addition of integers with infinity. *)

let (++) (x : requirement) (y : requirement) : requirement =
  if x = infinity || y = infinity
  then infinity
  else x + y

(* --------------------------------------------------------------------------
   UI cache
   --------------------------------------------------------------------------

   It serves two purposes: representing intermediate UI and caching it.

   The cache part is used to speed-up re-computation. It stores the conditions
   under which the cached result is the "prettiest" solution.
   A flat layout cannot change, so there is no extra condition.
   Optimality of non-flat layout is determined by two intervals:
   - `min_rem..max_rem`, the remaining space on the current line
   - `min_wid..max_wid`, the width of new lines (e.g. maximum width - indent)

   The intermediate UI part is necessary because pretty-printing produces two
   type of shapes, line and span, while [Nottui.ui] can only represent lines.
   Conceptually [Nottui.ui] represents a box, with a width and a height.
   However in the middle of pretty-printing, we can get in situations where a
   few lines have already been typeset and we stop in the middle of a new line.
   In full generality, span represents UI that look like that:

     ... [ prefix ]
     [ 0 or more  ]
     [ body lines ]
     [ suffix ] ...

   Prefix is the first line of the intermediate UI, to which we might prepend
   something.
   Body is the lines that are fully typeset and won't change. It can be empty.
   Suffix is the last line of the intermediate UI, to which we might append
   something.

   FUTURE WORK: since flat layout never changes, it might be worth caching
   separately flat and non-flat results.  Flat cache would actually be a lazy
   computation.
 *)

(* We use a few OCaml tricks to implement caching without introducing too
   much indirections.
   These optimisations are worthy because of the live/interactive nature of
   Nottui_pretty (documents are long-lived). This is not the case for PPrint.
*)

type ui = Nottui.ui

(* Category of intermediate nodes *)
type flat
type nonflat
type uncached

type 'a ui_cache =
  | (* A placeholder for a cache that is empty *)
    Uncached : uncached ui_cache
  | (* A single line that is flat *)
    Flat_line : ui -> flat ui_cache
  | (* Flat_span is a bit strange...
       It can only occur when someone put a `Hardline` in a flat document.
       They lied: the document should have been flat, but it is not.
       Nevertheless, I chose to accept this case. *)
    Flat_span : { prefix: ui; body: ui; suffix: ui } -> flat ui_cache
  | (* A line in a non-flat context *)
    Nonflat_line : { min_rem: int; max_rem: int; ui: ui; } -> nonflat ui_cache
  | (* A span in a non-flat context *)
    Nonflat_span : {
      min_rem: int; max_rem: int; prefix: ui;
      min_wid: int; max_wid: int; body: ui; suffix: ui;
    } -> nonflat ui_cache

(* The type of an actual cache slot (stored in document nodes).
   It hides the category of the node. *)
type ui_cache_slot = Cache : 'a ui_cache -> ui_cache_slot [@@ocaml.unboxed]

(* -------------------------------------------------------------------------- *)

(* The type of documents. *)

type t =
  | Blank of int
  | Ui of Nottui.ui
  | If_flat of { then_: t; else_: t }
  | Hardline
  | Cat of { req: requirement; lhs: t; rhs: t; mutable cache : ui_cache_slot }
  | Nest of { req: requirement; indent: int; doc: t }
  | Group of { req: requirement; doc: t; mutable cache : ui_cache_slot }

(* Only [Cat] and [Group] nodes are cached.
   This is because [Cat] is the only place where two sub-documents are
   connected. Cache miss here can change the asymptotic complexity of the
   computation.
   [Group] nodes are the only one where decisions are made (flat or non-flat).
   Other nodes, are either leaves ([Blank], [Ui], [Hardline]) or
   should normally only have a fixed nesting ([Nest (Nest (Nest ...))] cannot
   happen). I suspect that caching is not beneficial, if detrimental, to these
   cases.
 *)

(* -------------------------------------------------------------------------- *)

(* Retrieving or computing the space requirement of a document. *)

let rec requirement = function
  | Blank len -> len
  | Ui ui -> Nottui.Ui.layout_width ui
  | If_flat t -> requirement t.then_
  | Hardline -> infinity
  | Cat {req; _} | Nest {req; _} | Group {req; _} -> req

(* -------------------------------------------------------------------------- *)

(* Document constructors. *)

let empty = Blank 0

let ui ui = Ui ui

let hardline = Hardline

let blank = function
  | 0 -> Blank 0
  | 1 -> Blank 1
  | n -> Blank n

let if_flat (If_flat {then_; _} | then_) else_ =
  If_flat { then_; else_ }

let internal_break i =
  if_flat (blank i) hardline

let break =
  let break0 = internal_break 0 in
  let break1 = internal_break 1 in
  function
  | 0 -> break0
  | 1 -> break1
  | i -> internal_break i

let (^^) x y =
  match x, y with
  | (Blank 0, t) | (t, Blank 0) -> t
  | Blank i, Blank j -> Blank (i + j)
  | lhs, rhs ->
    Cat {req = requirement lhs ++ requirement rhs; lhs; rhs;
         cache = Cache Uncached}

let nest indent doc =
  assert (indent >= 0);
  match doc with
  | Nest t -> Nest {req = t.req; indent = indent + t.indent; doc = t.doc}
  | doc -> Nest {req = requirement doc; indent; doc}

let group = function
  | Group _ as doc -> doc
  | doc ->
    let req = requirement doc in
    if req = infinity then doc else Group {req; doc; cache = Cache Uncached}

(* -------------------------------------------------------------------------- *)

open Nottui

(* Some intermediate UI *)

let blank_ui n = Ui.space n 0

let flat_hardline =
  Flat_span { prefix = Ui.empty; body = Ui.empty; suffix = Ui.empty; }

let mk_body body1 suffix prefix body2 =
  Ui.join_y body1 (Ui.join_y (Ui.join_x suffix prefix) body2)

let mk_pad indent body suffix =
  let pad = Ui.space indent 0 in
  (Ui.join_x pad body, Ui.join_x pad suffix)

(* Flat renderer *)

let flat_cache (Cache slot) = match slot with
  | Flat_line _ as ui -> Some ui
  | Flat_span _ as ui -> Some ui
  | _ -> None

let rec pretty_flat = function
  | Ui ui -> Flat_line ui
  | Blank n -> Flat_line (blank_ui n)
  | Hardline -> flat_hardline
  | If_flat t -> pretty_flat t.then_
  | Cat t ->
    begin match flat_cache t.cache with
      | Some ui -> ui
      | None ->
        let result =
          let lhs = pretty_flat t.lhs and rhs = pretty_flat t.rhs in
          match lhs, rhs with
          | Flat_line l, Flat_line r ->
            Flat_line (Ui.join_x l r)
          | Flat_line l, Flat_span r ->
            Flat_span {r with prefix = Ui.join_x l r.prefix}
          | Flat_span l, Flat_line r ->
            Flat_span {l with suffix = Ui.join_x l.suffix r}
          | Flat_span l, Flat_span r ->
            Flat_span {prefix = l.prefix;
                       body = mk_body l.body l.suffix r.prefix r.body;
                       suffix = r.suffix}
        in
        t.cache <- Cache result;
        result
    end
  | Nest t ->
    begin match pretty_flat t.doc with
      | Flat_line _ as ui -> ui
      | Flat_span s ->
        let body, suffix = mk_pad t.indent s.body s.suffix in
        Flat_span {s with body; suffix}
    end
  | Group t ->
    begin match flat_cache t.cache with
      | Some ui -> ui
      | None ->
        let result = pretty_flat t.doc in
        t.cache <- Cache result;
        result
    end

(* Nonflat renderer.

   Steps:
   - check cache validity
   - compute normal, non-interactive pretty-printing
   - cache result and determine validity conditions

   The three steps could be implemented separately, but doing so would
   introduce redundant checks or indirections.
   For performance reasons and to reduce memory pressure, I preferred
   this ugly 100-lines long implementation.
*)

let mini, maxi = Lwd_utils.(mini, maxi)

let (+++) i j = let result = i + j in if result < 0 then max_int else result

let nonflat_line ui =
  Nonflat_line {min_rem = min_int; max_rem = max_int; ui}

let nonflat_cache (Cache slot) rem wid = match slot with
  | Nonflat_line t' as t when t'.min_rem <= rem && rem < t'.max_rem -> Some t
  | Nonflat_span t' as t
    when t'.min_rem <= rem && rem < t'.max_rem &&
         t'.min_wid <= wid && wid < t'.max_wid -> Some t
  | _ -> None

let span_hardline = Nonflat_span {
    min_rem = min_int; max_rem = max_int;
    min_wid = min_int; max_wid = max_int;
    prefix = Ui.empty; body = Ui.empty; suffix = Ui.empty;
  }

let rec pretty (rem: int) (wid : int) = function
  | Ui ui -> nonflat_line ui
  | Blank n -> nonflat_line (blank_ui n)
  | Hardline -> span_hardline
  | If_flat t -> pretty rem wid t.else_
  | Cat t ->
    begin match nonflat_cache t.cache rem wid with
      | Some ui -> ui
      | None ->
        let lhs = pretty rem wid t.lhs in
        let result = match lhs with
          | Nonflat_line l ->
            let lw = Ui.layout_width l.ui in
            begin match pretty (rem - lw) wid t.rhs with
              | Nonflat_line r ->
                Nonflat_line {
                  min_rem = maxi l.min_rem (r.min_rem + lw);
                  max_rem = mini l.max_rem (r.max_rem +++ lw);
                  ui = Ui.join_x l.ui r.ui;
                }
              | Nonflat_span r ->
                Nonflat_span {
                  r with
                  min_rem = maxi l.min_rem (r.min_rem + lw);
                  max_rem = mini l.max_rem (r.max_rem +++ lw);
                  prefix = Ui.join_x l.ui r.prefix;
                }
            end
          | Nonflat_span l ->
            let lw = Ui.layout_width l.suffix in
            begin match pretty (wid - lw) wid t.rhs with
              | Nonflat_line r ->
                Nonflat_span {
                  l with
                  min_wid = maxi l.min_wid (r.min_rem + lw);
                  max_wid = mini l.max_wid (r.max_rem +++ lw);
                  suffix = Ui.join_x l.suffix r.ui;
                }
              | Nonflat_span r ->
                Nonflat_span {
                  prefix = l.prefix; min_rem = l.min_rem; max_rem = l.max_rem;
                  min_wid = maxi (maxi l.min_wid (r.min_rem + lw)) r.min_wid;
                  max_wid = mini (mini l.max_wid (r.max_rem +++ lw)) r.max_wid;
                  body = mk_body l.body l.suffix r.prefix r.body;
                  suffix = r.suffix;
                }
            end
        in
        t.cache <- Cache result;
        result
    end
  | Nest t ->
    begin match pretty rem (wid - t.indent) t.doc with
      | Nonflat_line _ as ui -> ui
      | Nonflat_span s ->
        let body, suffix = mk_pad t.indent s.body s.suffix in
        Nonflat_span {
          min_rem = s.min_rem; max_rem = s.max_rem;
          min_wid = s.min_wid + t.indent;
          max_wid = s.max_wid +++ t.indent;
          prefix = s.prefix; body; suffix;
        }
    end
  | Group t as self ->
    begin if t.req <= rem then
        match pretty_flat self with
        | Flat_line ui ->
          Nonflat_line { min_rem = t.req; max_rem = max_int; ui }
        | Flat_span ui ->
          Nonflat_span {
            min_rem = t.req; max_rem = max_int;
            min_wid = min_int; max_wid = max_int;
            prefix = ui.prefix;
            body = ui.body;
            suffix = ui.suffix;
          }
      else match nonflat_cache t.cache rem wid with
        | Some ui -> ui
        | None ->
          let result = match pretty rem wid t.doc with
            | Nonflat_line ui -> Nonflat_line {ui with max_rem = t.req}
            | Nonflat_span ui ->
              Nonflat_span {ui with max_rem = mini t.req ui.max_rem}
          in
          t.cache <- Cache result;
          result
    end

(* -------------------------------------------------------------------------- *)

(* The engine's entry point. *)

let pretty width doc =
  match pretty width width doc with
  | Nonflat_line t -> t.ui
  | Nonflat_span t -> Ui.join_y t.prefix (Ui.join_y t.body t.suffix)
