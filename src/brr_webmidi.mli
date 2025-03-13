(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Web MIDI API.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Web_MIDI_API}
    Web MIDI API}. *)

open Brr

(** Web MIDI. *)
module Midi : sig

  (** MIDI port. *)
  module Port : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort}[MIDIPort]} objects. *)

    val as_target : t -> Brr.Ev.target
    (** [as_target p] is [p] as an event target. *)

    val open' : t -> unit Fut.or_error
    (** [open' p] {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/open}opens} the port. *)

    val close : t -> unit Fut.or_error
    (** [close p] {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/close}closes} the port. *)

    (** {1:properties Properties} *)

    val id : t -> Jstr.t
    (** [id p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/id}identifier} of [p]. *)

    val manufacturer : t -> Jstr.t
    (** [manufacturer p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/manufacturer}manufacturer} of [p]. *)

    val name : t -> Jstr.t
    (** [name p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/name}name} of [p]. *)

    val version : t -> Jstr.t
    (** [version p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/version}version} of [p]. *)

    val type' : t -> Jstr.t
    (** [type' p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/type}type} of [p]. *)

    val state : t -> Jstr.t
    (** [state p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/state}state} of [p]. *)

    val connection : t -> Jstr.t
    (** [connection p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/connection}connection} of [p]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** MIDI input. *)
  module Input : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput}[MIDIInput]} objects. *)

    val as_target : t -> Brr.Ev.target
    (** [as_target i] is [i] as an event target. *)

    val as_port : t -> Port.t
    (** [as_port i] is [i] as a port. *)

    val of_port : Port.t -> t
    (** [of_port p] is an input of [p]. Raises a JavaScript error if [p]
        is not an input. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** MIDI output. *)
  module Output : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIOutput}[MIDIOutput]} objects. *)

    val as_target : t -> Brr.Ev.target
    (** [as_target o] is [o] as an event target. *)

    val as_port : t -> Port.t
    (** [as_port o] is [o] as a port. *)

    val of_port : Port.t -> t
    (** [of_port p] is an input of [p]. Raises a JavaScript error if [p]
        is not an input. *)

    val send :
      ?timestamp_ms:float -> t -> Tarray.uint8 -> (unit, Jv.Error.t) result
    (** [send o msg] {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIOutput/send}sends} [msg] on [o]. *)

    val clear : t -> unit
    (** [clear o] {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIOutput/clear}clears} the output. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** MIDI access. *)
  module Access : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIAccess}[MIDIAccess]} objects. *)

    val inputs : t -> (Input.t -> 'a -> 'a) -> 'a -> 'a
    (** [inputs a f acc] folds over the MIDI inputs of [a] with [f]. *)

    val outputs : t -> (Output.t -> 'a -> 'a) -> 'a -> 'a
    (** [outputs a f acc] folds over the MIDI outputs [a] with [f]. *)

    (** {1:request Request} *)

    type opts
    (** The type for MIDI access options. *)

    val opts : ?sysex:bool -> ?software:bool -> unit -> opts
    (** [opts ()] are MIDI access options with given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator/requestMIDIAccess#parameters}parameters}. *)

    val of_navigator : ?opts:opts -> Brr.Navigator.t -> t Fut.or_error
    (** [of_navigator ()] {{:https://developer.mozilla.org/en-US/docs/Web/API/Navigator/requestMIDIAccess}requests} a MIDI access object. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** MIDI events. *)
  module Ev : sig

    (** MIDI message events. *)
    module Message : sig

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIMessageEvent}
          [MIDIMessageEvent]} objects. *)

      val data : t -> Tarray.uint8
      (** [data e] is the message's
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIMessageEvent/data}data}. *)
    end

    val midimessage : Message.t Ev.type'
    (** [midimessage] is the type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput/midimessage_event}[midimessage]} events. *)

    (** MIDI connection events. *)
    module Connection : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIConnectionEvent}[MIDIConnectionEvent]} objects. *)

      val port : t -> Port.t
      (** [port e] is
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIConnectionEvent/port}the port} which is affected. *)
    end

    val statechange : Connection.t Ev.type'
    (** [statechange] is the type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/MIDIAccess/statechange_event}statechange} events. *)
  end
end
