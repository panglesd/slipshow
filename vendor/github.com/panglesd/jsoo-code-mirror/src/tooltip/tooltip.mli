open Code_mirror

module Tooltip_view : sig
  (** Describes the way a tooltip is displayed. *)

  type t
  (** TooltypeView *)

  include Jv.CONV with type t := t

  val dom : t -> Brr.El.t
  (** The DOM element to position over the editor. *)

  type offset = { x : int; y : int }
  type coords = { left : int; right : int; top : int; bottom : int }

  val offset : t -> offset

  val create :
    dom:Brr.El.t ->
    ?offset:offset ->
    ?get_coords:(int -> coords) ->
    ?overlap:bool ->
    ?mount:(Editor.View.t -> unit) ->
    ?update:(Editor.View.Update.t -> unit) ->
    ?positioned:(unit -> unit) ->
    unit ->
    t
  (** Creates a TooltipView:

    @param dom The DOM element to position over the editor.
    @param offset Adjust the position of the tooltip relative to its anchor
      position.
    @param get_coords This method can be provided to make the tooltip view
      itself responsible for finding its screen position.
    @param overlap By default, tooltips are moved when they overlap with other
      tooltips. Set this to true to disable that behavior for this tooltip.
    @param mount Called after the tooltip is added to the DOM for the first
      time.
    @param update Update the DOM element for a change in the view's state.
    @param positioned Called when the tooltip has been (re)positioned.

    {{:https://codemirror.net/6/docs/ref/#tooltip.TooltipView} See the
    reference for additional information.} *)
end

(** Creates a Tooltip:

  @param pos The document position at which to show the tooltip.
  @param end The end of the range annotated by this tooltip, if different from
    pos.
  @param create A constructor function that creates the tooltip's DOM
    representation.
  @param above Whether the tooltip should be shown above or below the target
    position.
  @param strict_side Whether the above option should be honored when there
    isn't enough space on that side to show the tooltip inside the viewport.
  @param arrow When set to true, show a triangle connecting the tooltip element
    to position pos.

  {{:https://codemirror.net/6/docs/ref/#tooltip.Tooltip} See the
  reference for additional information.} *)
module Tooltip : sig
  (** Describes a tooltip. Values of this type, when provided through the
  show_tooltip facet, control the individual tooltips on the editor. *)

  type t
  (** Tooltip *)

  include Jv.CONV with type t := t

  val pos : t -> int
  (** The document position at which to show the tooltip. *)

  val end_ : t -> int option
  (** The end of the range annotated by this tooltip, if different from pos. *)

  val create :
    pos:int ->
    ?end_:int ->
    create:(Editor.View.t -> Tooltip_view.t) ->
    ?above:bool ->
    ?strict_side:bool ->
    ?arrow:bool ->
    unit ->
    t
end

type hover_config

val hover_config :
  ?hide_on_change:bool -> ?hover_time:int -> unit -> hover_config
(** Options for hover tooltips:

  @param hover_on_change When enabled (this defaults to false), close the
    tooltip whenever the document changes.
@param hover_time Hover time after which the tooltip should appear, in
milliseconds. Defaults to 300ms. *)

val hover_tooltip :
  ?config:hover_config ->
  (view:Editor.View.t -> pos:int -> side:int -> Tooltip.t option Fut.t) ->
  Extension.t
(** Enable a hover tooltip, which shows up when the pointer hovers over ranges
  of text. The callback is called when the mouse hovers over the document text.
  It should, if there is a tooltip associated with position pos return the
  tooltip description (either directly or in a promise). The side argument
  indicates on which side of the position the pointer is—it will be -1 if the
  pointer is before the position, 1 if after the position.

  Note that all hover tooltips are hosted within a single tooltip container
  element. This allows multiple tooltips over the same range to be "merged"
  together without overlapping. *)
