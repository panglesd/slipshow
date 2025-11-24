open Brr
open El

type t = El.t

type 'a col = [
  | `P of 'a
  (** Pure element *)
  | `R of 'a Lwd.t
  (** Reactive element *)
  | `S of 'a Lwd_seq.t Lwd.t
  (** Reactive sequence of elements *)
] list
(** Describing collections of elements *)

type handler (* An event handler *)
val handler : ?opts:Ev.listen_opts -> 'a Ev.type' -> ('a Ev.t -> unit) -> handler

val v :
  ?ns:[`HTML | `MathML | `SVG] ->
  ?d:document ->
  ?at:At.t col ->
  ?ev:handler col ->
  ?st:(El.Style.prop * Jstr.t) col ->
  ?prop:(Jstr.t * Jv.t) col ->
  tag_name -> t col -> t Lwd.t
(** [v ?d ?at name cs] is an element [name] with attribute [at]
    (defaults to [[]]) and children [cs]. If [at] specifies an
    attribute more thanonce, the last one takes over with the
    exception of {!At.class'} whose occurences accumulate to define
    the final value. [d] is the document on which the element is
    defined it defaults {!Brr.G.document}. *)

(** {1:els Element constructors} *)

type cons =
  ?d:document ->
  ?at:At.t col ->
  ?ev:handler col ->
  ?st:(El.Style.prop * Jstr.t) col ->
  ?prop:(Jstr.t * Jv.t) col ->
  t col -> t Lwd.t
(** The type for element constructors. This is simply {!v} with a
    pre-applied element name. *)

type void_cons = ?d:document -> ?at:At.t col -> ?ev:handler col -> ?st:(El.Style.prop * Jstr.t) col -> ?prop:(Jstr.t * Jv.t) col -> unit -> t Lwd.t
(** The type for void element constructors. This is simply {!v}
    with a pre-applied element name and without children. *)

val a : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a}a} *)

val abbr : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/abbr}abbr} *)

val address : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/address}
    address} *)

val area : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/area}
    area} *)

val article : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/article}
    article} *)

val aside : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/aside}
    aside} *)

val audio : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio}
    audio} *)

val b : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/b}b} *)

val base : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base}
    base} *)

val bdi : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdi}
    bdi} *)

val bdo : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdo}
    bdo} *)

val blockquote : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/blockquote}
    blockquote} *)

val body : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body}
    body} *)

val br : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/br}br} *)

val button : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button}
    button} *)

val canvas : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas}
    canvas} *)

val caption : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/caption}
    caption} *)

val cite : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/cite}
    cite} *)

val code : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/code}
    code} *)

val col : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/col}
    col} *)

val colgroup : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/colgroup}
    colgroup} *)

val command : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/command}
      command} *)

val datalist : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist}
    datalist} *)

val dd : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dd}dd} *)

val del : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/del}
    del} *)

val details : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details}
    details} *)

val dfn : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dfn}
    dfn} *)

val div : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/div}
    div} *)

val dl : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dl}dl} *)

val dt : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt}dt} *)

val em : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/em}em} *)

val embed : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/embed}
    embed} *)

val fieldset : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset}
    fieldset} *)

val figcaption : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figcaption}
    figcaption} *)

val figure : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figure}
    figure} *)

val footer : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/footer}
    footer} *)

val form : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form}
      form} *)

val h1 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h1}h1} *)

val h2 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h2}h2} *)

val h3 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h3}h3} *)

val h4 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h4}h4} *)

val h5 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h5}h5} *)

val h6 : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h6}h6} *)

val head : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head}
    head} *)

val header : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/header}
    header} *)

val hgroup : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hgroup}
      hgroup} *)

val hr : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hr}hr} *)

val html : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html}
      html} *)

val i : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/i}i} *)

val iframe : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe}
      iframe} *)

val img : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img}
      img} *)

val input : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input}
      input} *)

val ins : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins}
      ins} *)

val kbd : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/kbd}
      kbd} *)

val keygen : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/keygen}
      keygen} *)

val label : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label}
      label} *)

val legend : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/legend}
    legend} *)

val li : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/li}li} *)

val link : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link}link} *)

val map : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/map}map} *)

val mark : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mark}mark} *)

val menu : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/menu}menu} *)

val meta : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta}meta} *)

val meter : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter}
    meter} *)

val nav : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/nav}nav} *)

val noscript : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript}
    noscript} *)

val object' : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object}
    object} *)

val ol : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ol}ol} *)

val optgroup : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup}
    optgroup} *)

val option : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/option}
    option} *)

val output : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/output}
    output} *)

val p : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/p}p} *)

val param : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/param}
    param} *)

val pre : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/pre}
    pre} *)

val progress : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress}
    progress} *)

val q : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/q}q} *)

val rp : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rp}rp} *)

val rt : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rt}rt} *)

val ruby : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ruby}ruby} *)

val s : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/s}s} *)

val samp : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/samp}
    samp} *)

val script : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script}
    script} *)

val section : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/section}
    section} *)

val select : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select}
    select} *)

val small : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/small}
    small} *)

val source : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/source}
    source} *)

val span : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/span}
    span} *)

val strong : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/strong}
    strong} *)

val style : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/style}
    style} *)

val sub : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sub}
    sub} *)

val summary : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/summary}
    summary} *)

val sup : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sup}
    sup} *)

val table : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/table}
    table} *)

val tbody : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tbody}
    tbody} *)

val td : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td}td} *)

val textarea : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea}
    textarea} *)

val tfoot : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tfoot}
    tfoot} *)

val th : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th}th} *)

val thead : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/thead}
    thead} *)

val time : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time}
    time} *)

val title : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/title}
    title} *)

val tr : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tr}tr} *)

val track : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track}
    track} *)

val u : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/u}u} *)

val ul : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ul}ul} *)

val var : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/var}
    var} *)

val video : cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video}
    video} *)

val wbr : void_cons
(** {{:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/wbr}
    wbr} *)
