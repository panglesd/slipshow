(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Web Audio API.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API}
    Web Audio API}. *)

open Brr

(** Web Audio. *)
module Audio : sig

  (** Audio parameters. *)
  module Param : sig

    (** Automation rate enumeration. *)
    module Automation_rate : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParamDescriptor#Properties}[AutomationRate]} values. *)

      val a_rate : t
      val k_rate : t
    end

    type descriptor
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParamDescriptor}[AudioParamDescriptor]} objects. *)

    val descriptor :
        ?automation_rate:Automation_rate.t -> ?min_value:float ->
        ?max_value:float -> ?default_value:float -> Jstr.t -> descriptor
      (** [create name] is an audio parameter descriptor with
          given {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParamDescriptor#Properties}properties}. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam}
        [AudioParam]} objects. *)

    val value : t -> float
    (** [value p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/value}
        value} of [p]. *)

    val set_value : t -> float -> unit
    (** [set_value p v] sets the {!value} of [p] to [v]. *)

    val automation_rate : t -> Automation_rate.t
    (** [automation_rate p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/automationRate}automation rate} of [p]. *)

    val set_automation_rate : t -> Automation_rate.t -> unit
    (** [set_automation_rate p r] sets the {!automation_rate} of [p] to [r]. *)

    val default_value : t -> float
    (** [default_value p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/defaultValue} default value} of [p]. *)

    val min_value : t -> float
    (** [min_value p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/minValue}
        minimal value} of [p]. *)

    val max_value : t -> float
    (** [max_value p] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/maxValue}
        maximal value} of [p]. *)

    val set_value_at_time : t -> value:float -> time:float -> unit
    (** [set_value_at_time p ~value ~time]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/setValueAtTime}sets} [p]'s value to [value] at time [time]. *)

    val linear_ramp_to_value_at_time :
      t -> value:float -> end_time:float -> unit
    (** [linear_ramp_to_value_at_time p ~value ~end_time]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/linearRampToValueAtTime}sets} [p]'s value to [value] at time [end_time] by linearly
        changing it starting from the previous event. *)

    val exponential_ramp_to_value_at_time :
      t -> value:float -> end_time:float -> unit
    (** [exponential_ramp_to_value_at_time p ~value ~time]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/exponentialRampToValueAtTime}sets} [p]'s value to [value] at time [end_time] by exponentially changing it starting from the previous event. *)

    val set_target_at_time :
      t -> target:float -> start_time:float -> decay_rate:float -> unit
    (** [set_target_at_time p ~value ~time ~decay_rate]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/setTargetAtTime}transition} [p]'s value towards [value] at time [time]. *)

    val set_value_curve_at_time :
      t -> Tarray.float32 -> start_time:float -> dur_s:float -> unit
    (** [set_value_curve_at_time p vs ~start_time ~dur_s]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/setValueCurveAtTime}transitions} [p]'s values through [vs] during [dur_s] seconds
        starting at time [start_time]. *)

    val cancel_scheduled_values : t -> time:float -> unit
    (** [cancel_scheduled_value p ~time] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/cancelScheduledValues}cancels} scheduled changes to
        [p]. *)

    val cancel_and_hold_at_time : t -> time:float -> unit
    (** [cancel_and_hold_at_time p ~time] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/cancelAndHoldAtTime}cancels} scheduled changes to
        [p] and holds the value at the given time. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Audio listeners. *)
  module Listener : sig

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener}
        [AudioListener]} objects. *)

    val position_x : t -> Param.t
    (** [position_x l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/positionX}x position} of [l]. *)

    val position_y : t -> Param.t
    (** [position_y l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/positionY}y position} of [l]. *)

    val position_z : t -> Param.t
    (** [position_z l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/positionZ}z position} of [l]. *)

    val forward_x : t -> Param.t
    (** [forward_x l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/forwardX}x forward direction} of [l]. *)

    val forward_y : t -> Param.t
    (** [forward_y l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/forwardY}y forward direction} of [l]. *)

    val forward_z : t -> Param.t
    (** [forward_z l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/forwardZ}z forward direction} of [l]. *)

    val up_x : t -> Param.t
    (** [up_x l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/upX}x up direction} of [l]. *)

    val up_y : t -> Param.t
    (** [up_y l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/upY}y up direction} of [l]. *)

    val up_z : t -> Param.t
    (** [up_z l] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioListener/upZ}z up direction} of [l]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Audio worklets, their global scope and processors. *)
  module Worklet : sig

    (** {1:worklets Worklets} *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorklet}
        [AudioWorklet]} objects. *)

    val add_module : t -> Jstr.t -> unit Fut.or_error
    (** [add_module w url] {{:https://developer.mozilla.org/en-US/docs/Web/API/Worklet/addModule}adds} module [url] to [w]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)

    (** {1:global_scope Worklet global scope} *)


    (** Audio worklet global scope definitions.

        This has the defintions of the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletGlobalScope}[AudioWorkletGlobalScope]}. *)
    module G : sig

      val register_processor : Jstr.t -> Jv.t -> unit
      (** [register_processor n c]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletGlobalScope/registerProcessor}registers} class
          contructor [c] with [n]. *)

      val current_frame : unit -> int
      (** [current_frame ()] is the current
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletGlobalScope#Properties}current sample-frame}. *)

      val current_time : unit -> float
      (** [current_time ()] is the current
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletGlobalScope#Properties}current audio time}. *)

      val sample_rate : unit -> float
      (** [sample_rate ()] is the current
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletGlobalScope#Properties}current sample rate}. *)
    end

    (** {1:processors Worklet processors} *)

    (** Audio worklet processors. *)
    module Processor : sig

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletProcessor}[AudioWorkletProcessor]} objects. *)

      val port : t -> Brr_io.Message.Port.t
      (** [port p] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletProcessor/port}port} of [p]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
    end
  end

  (** Audio buffers. *)
  module Buffer : sig

    type opts
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/AudioBuffer#Parameters}[AudioBufferOptions]}. *)

    val opts :
      channel_count:int -> length:int -> sample_rate_hz:float -> unit -> opts
    (** [opts ~channel_count ~length ~sample_rate_ht ()] are audio context
          options with the given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/AudioBuffer#Parameters}properties}. *)

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer}[AudioBuffer]} objects. *)

    val create : opts -> t
    (** [create opts] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/AudioBuffer}creates} an audio buffer with given options. *)

    val sample_rate : t -> float
    (** [sample_rate b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/sampleRate}sample rate} of [b]. *)

    val length : t -> int
    (** [length b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/length}length} of [b]. *)

    val duration_s : t -> float
    (** [duration_s b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/duration}duration} of [b]. *)

    val channel_count : t -> int
    (** [channel_count b] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/numberOfChannels}number of channels} of [b]. *)

    val get_channel_data : t -> channel:int -> Tarray.float32
    (** [get_channel_data b ~channel] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/getChannelData}channel data} of [channel] in [b]. *)

    val copy_from_channel :
      ?dst_start:int -> t -> channel:int -> dst:Tarray.float32 -> unit
    (** [copy_from_channel b ~channel ~dst]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/copyFromChannel}copies} data of channel [channel] of [b] into [dst]. *)

    val copy_to_channel :
      ?dst_start:int -> t -> src:Tarray.float32 -> channel:int -> unit
    (** [copy_to_channel b ~src ~channel]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer/copyToChannel}copies} data of [src] to channel [channel] of [b]. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Audio nodes. *)
  module Node : sig

    (** {1:nodes Nodes} *)

    (** Channel count mode enumeration. *)
    module Channel_count_mode : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/channelCountMode}[ChannelCountMode]} values. *)

      val max : t
      val clamped_max : t
      val explicit : t
    end

    (** Channel intepretation enumeration. *)
    module Channel_interpretation : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/channelIntepretation}[ChannelInterpretation]} values. *)

      val speakers : t
      val discrete : t
    end

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode}
        [AudioNode]} objects. *)

    type node = t
    (** See {!t}. *)

    type context
    (** See {!Context.Base.t}. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target n] is [n] as an event target. *)

    val context : t -> context
    (** [context n] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/context}
        audio context} of [n]. *)

    val input_count : t -> int
    (** [input_count n] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/numberOfInputs}number of inputs} of [n]. *)

    val output_count : t -> int
    (** [output_count n] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/numberOfOutputs}number of outputs} of [n]. *)

    val channel_count : t -> int
    (** [channel_count n] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/channelCount}number of channels} used by [n]. *)

    val set_channel_count : t -> int -> unit
    (** [set_channel_count n c] sets {!channel_count} of [n] to [c]. *)

    val channel_count_mode : t -> Channel_count_mode.t
    (** [channel_count_mode n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/channelCountMode}channel count mode} of [n]. *)

    val set_channel_count_mode : t -> Channel_count_mode.t -> unit
    (** [set_channel_count_mode n m] sets the {!channel_count_mode} of [n]
        to [m]. *)

    val channel_interpretation : t -> Channel_interpretation.t
    (** [channel_interpretation n] is the
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/channelInterpretation}channel interpretation} of [n]. *)

    val set_channel_interpretation : t -> Channel_interpretation.t -> unit
    (** [set_channel_interpretation n i] sets the {!channel_interpretation}
        of [n] to [i]. *)

    val connect_node : ?output:int -> ?input:int -> t -> dst:t -> unit
    (** [connect_node n ~output ~input ~dst]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/connect}
        connects} [n] to [dst]. *)

    val connect_param : ?output:int -> t -> dst:Param.t -> unit
    (** [connect_param n ~output ~dst]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/connect}
        connects} [n] to [dst]. *)

    val disconnect : t -> unit
    (** [disconnect n]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/disconnect}disconnects}
        all outgoing connections. *)

    val disconnect_node : ?output:int -> ?input:int -> t -> dst:t -> unit
    (** [disconnect_node n ~dst]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/disconnect}disconnects} [n] from [dst]. *)

    val disconnect_param : ?output:int -> t -> dst:Param.t -> unit
    (** [disconnect_param n ~dst]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/disconnect}disconnects} [n] from [dst]. *)

    (** {1:types Node types} *)

    (** Analyser nodes. *)
    module Analyser : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/AnalyserNode#Parameters}[AnalyserOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?fft_size:int -> ?max_decibels:float -> ?min_decibels:float ->
        ?smoothing_time_constant:float -> unit -> opts
      (** [opts ()] are analyser node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/AnalyserNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode}
          [AnalyserNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/AnalyserNode}creates} an analyser node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val get_float_frequency_data : t -> Tarray.float32 -> unit
      (** [get_float_frequency_data n d] {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/getFloatFrequencyData}copies} frequency data into
          [d]. *)

      val get_byte_frequency_data : t -> Tarray.uint8 -> unit
      (** [get_byte_frequency_data n d] {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/getByteFrequencyData}copies} frequency data into
          [d]. *)

      val get_float_time_domain_data : t -> Tarray.float32 -> unit
      (** [get_float_time_domain_data n d] {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/getFloatTimeDomainData}copies} time-domain data into
          [d]. *)

      val get_byte_time_domain_data : t -> Tarray.uint8 -> unit
      (** [get_byte_frequency_data n d] {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/getByteTimeDomainData}copies} time-domain data into
          [d]. *)

      (** {1:properties Properties} *)

      val fft_size : t -> int
      (** [fft_size n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/fftSize}window size} of [n]. *)

      val set_fft_size : t -> int -> unit
      (** [set_fft_size n v] sets {!fft_size} of [n] to [v]. *)

      val frequency_bin_count : t -> int
      (** [frequency_bin_count n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/frequencyBinCount}frequency bin count} of [n]. *)

      val min_decibels : t -> float
      (** [min_decibels n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/minDecibels}lower bound} on results of [n]. *)

      val set_min_decibels : t -> float -> unit
      (** [set_min_decibels n v] sets {!min_decibels} of [n] to [v]. *)

      val max_decibels : t -> float
      (** [max_decibels n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/maxDecibels}upper bound} on results of [n]. *)

      val set_max_decibels : t -> float -> unit
      (** [set_max_decibels n v] sets {!max_decibels} of [n] to [v]. *)

      val smoothing_time_constant : t -> float
      (** [smoothing_time_constant n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/smoothingTimeConstant}averaging constant}
          of [n]. *)

      val set_smoothing_time_constant : t -> float -> unit
      (** [set_smoothing_time_constant n v] sets {!smoothing_time_constant}
          of [n] to [v]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Biquad filter nodes. *)
    module Biquad_filter : sig

      (** Biquad filter type. *)
      module Type : sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/type#type_values_and_their_meaning}[BiquadFilterType]} values. *)

        val lowpass : t
        val highpass : t
        val bandpass : t
        val lowshelf : t
        val highshelf : t
        val peaking : t
        val notch : t
        val allpass : t
      end

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/BiquadFilterNode#Parameters}[BiquadFilterOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t -> ?type':Type.t ->
        ?q:float -> ?detune:float -> ?frequency:float -> ?gain:float -> unit ->
        opts
      (** [opts ()] are analyser node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/BiquadFilterNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode}
          [BiquadFilter]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/BiquadFilterNode}creates} a biquad filter node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val type' : t -> Type.t
      (** [type' n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/type}type} of [n]. *)

      val set_type : t -> Type.t -> unit
      (** [set_type n t] sets the {!type'} of [n] to [t]. *)

      val detune : t -> Param.t
      (** [detune n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/detune}frequency detuning} of [n]. *)

      val frequency : t -> Param.t
      (** [frequency n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/frequency}frequency} of [n]. *)

      val q : t -> Param.t
      (** [q n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/Q}quality factor} of [n]. *)

      val gain : t -> Param.t
      (** [gain n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/gain}gain} of [n]. *)

      val get_frequency_response :
        t -> frequencies:Tarray.float32 -> mag_response:Tarray.float32 ->
        phase_response:Tarray.float32 -> unit
      (** [get_frequency_response n ~frequencies_hz ~mag_response
          ~phase_response] calculates
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BiquadFilterNode/getFrequencyResponse}frequency
          responses} for [frequencies]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Buffer source nodes. *)
    module Buffer_source : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/AudioBufferSourceNode#Parameters}[AudioBufferSourceOptions]}. *)

      val opts :
        ?buffer:Buffer.t -> ?detune:float -> ?loop:bool -> ?loop_start:float ->
        ?loop_end:float -> ?playback_rate:float -> unit -> opts
      (** [opts ()] are buffer source node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/AudioBufferSourceNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode}[AudioBufferSourceNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/AudioBufferSourceNode}creates} a buffer source node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val buffer : t -> Buffer.t option
      (** [buffer n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/buffer}buffer} of [n]. *)

      val set_buffer : t -> Buffer.t option -> unit
      (** [set_buffer n b] sets the {!buffer} of [n] to [b]. *)

      val playback_rate : t -> Param.t
      (** [playback_rate n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/playbackRate}playback rate} of [n]. *)

      val detune : t -> Param.t
      (** [detune n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/detune}detune} parameter of [n]. *)

      val loop : t -> bool
      (** [loop n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/loop}loop} parameter of [n]. *)

      val set_loop : t -> bool -> unit
      (** [set_loop n b] sets the {!loop} parameter of [n] to [b]. *)

      val loop_start : t -> float
      (** [loop_start n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/loopStart}loop_start} parameter of [n]. *)

      val set_loop_start : t -> float -> unit
      (** [set_loop_start n v] sets the {!loop_start} parameter of [n] to
          [v]. *)

      val loop_end : t -> float
      (** [loop_end n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/loopEnd}loop_end} parameter of [n]. *)

      val set_loop_end : t -> float -> unit
      (** [set_loop_end n v] sets the {!loop_end} parameter of [n] to
          [v]. *)

      val start : ?time:float -> ?offset:float -> ?dur_s:float -> t -> unit
      (** [start n] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/start}starts} the source. *)

      val stop : ?time:float -> t -> unit
      (** [stop n] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/stop}stops} the source. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Channel merger nodes. *)
    module Channel_merger : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode/ChannelMergerNode#Parameters}[ChannelMergeOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?input_count:int -> unit -> opts
      (** [opts ()] are channel merger node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode/ChannelMergerNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode}[ChannelMergerNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelMergerNode/ChannelMergerNode}creates} a channel merger node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Channel splitter nodes. *)
    module Channel_splitter : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelSplitterNode/ChannelSplitterNode#Parameters}[ChannelSplitterOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?output_count:int -> unit -> opts
      (** [opts ()] are channel splitter node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelSplitterNode/ChannelSplitterNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelSplitterNode}[ChannelSplitterNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/ChannelSplitterNode/ChannelSplitterNode}creates} a channel splitter node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Constant source nodes. *)
    module Constant_source : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/ConstantSourceNode#Parameters}[ConstantSourceOptions]}. *)

      val opts : ?offset:float -> unit -> opts
      (** [opts ()] are constant source node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/ConstantSourceNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode}[ConstantSourceNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/ConstantSourceNode}creates} a constant source node node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val offset : t -> Param.t
      (** [offset n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/offset}offset} of [n]. *)

      val start : ?time:float -> t -> unit
      (** [start n] {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/start}starts} node [n]. *)

      val stop : ?time:float -> t -> unit
      (** [stop n] {{:https://developer.mozilla.org/en-US/docs/Web/API/ConstantSourceNode/stop}stops} node [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Convolver node. *)
    module Convolver : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode/ConvolverNode#Parameters}[ConvolverOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?buffer:Buffer.t -> ?disable_normalization:bool -> unit -> opts
      (** [opts ()] are channel splitter node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode/ConvolverNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode}[ConvlverNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode/ConvolverNode}creates} a channel splitter node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val buffer : t -> Buffer.t option
      (** [buffer n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode/buffer}buffer} of [n]. *)

      val set_buffer : t -> Buffer.t option -> unit
      (** [set_buffer n b] sets the {!buffer} of [n] to [b]. *)

      val normalize : t -> bool
      (** [normalize n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/ConvolverNode/normalize}normalization behaviour} of [n]. *)

      val set_normalize : t -> bool -> unit
      (** [set_normalize n b] sets {!normalize} of [n] to [b]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Delay node. *)
    module Delay : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/DelayNode/DelayNode#Parameters}[DelayOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?delay_time:float -> ?max_delay_time:float -> unit -> opts
      (** [opts ()] are delay node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/DelayNode/DelayNode#Parameters}parameters}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/DelayNode}[DelayNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/DelayNode/DelayNode}creates} a delay node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val delay_time : t -> Param.t
      (** [delay_time d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DelayNode/delayTime}delay time} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Destination nodes. *)
    module Destination : sig
      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode}[AudioDestinationNode]} objects. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val max_channel_count : t -> int
      (** [max_channel_count n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioDestinationNode/maxChannelCount}maximum} amount of channels
          supported by [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Dyamics compressor nodes. *)
    module Dynamics_compressor : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/DynamicsCompressorNode#Parameters}[DynamicsCompressorOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?attack:float -> ?knee:float -> ?ratio:float -> ?release:float ->
        ?threshold:float -> unit -> opts
      (** [opts ()] are dynamics compressor node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/DynamicsCompressorNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode}[DynamicsCompressorNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/DynamicsCompressorNode}creates} a dynamics compressor
          node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val attack : t -> Param.t
      (** [attack n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/attack}attack} of [n]. *)

      val knee : t -> Param.t
      (** [knee n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/knee}knee} of [n]. *)

      val ratio : t -> Param.t
      (** [ratio n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/ratio}ratio} of [n]. *)

      val reduction : t -> float
      (** [reduction n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/reduction}reduction} of [n]. *)

      val release : t -> Param.t
      (** [release n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/release}release} of [n]. *)

      val threshold : t -> Param.t
      (** [threshold n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/DynamicsCompressorNode/threshold}threshold} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Gain nodes. *)
    module Gain : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/GainNode/GainNode#Parameters}[GainOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?gain:float -> unit -> opts
      (** [opts ()] are gain node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GainNode/GainNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/GainNode}
          [GainNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/GainNode/GainNode}creates} a gain node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val gain : t -> Param.t
      (** [gain d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/GainNode/gain}gain} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** IIR filter nodes. *)
    module Iir_filter : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode/IIRFilterNode#Parameters}[IIRFilterOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        feedforward:Tarray.float32 -> feedback:Tarray.float32 -> unit -> opts
      (** [opts ()] are IIR filter node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode/IIRFilterNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode}
          [IIRFilterNode]} objects. *)

      val create : context -> opts:opts -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode/IIRFilterNode}creates} a IIR filter node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val get_frequency_response :
        t -> frequencies:Tarray.float32 -> mag_response:Tarray.float32 ->
        phase_response:Tarray.float32 -> unit
      (** [get_frequency_response n ~frequencies ~mag_response
          ~phase_response] calculates
          {{:https://developer.mozilla.org/en-US/docs/Web/API/IIRFilterNode/getFrequencyResponse}frequency
          responses} for [frequencies]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Media element source nodes. *)
    module Media_element_source : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaElementAudioSourceNode/MediaElementAudioSourceNode#Parameters}[MediaElementAudioSourceOptions]}. *)

      val opts : el:Brr_io.Media.El.t -> unit -> opts
      (** [opts ~el ()] are media element source node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaElementAudioSourceNode/MediaElementAudioSourceNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaElementAudioSourceNode}[MediaElementAudioSourceNode]} objects. *)

      val create : context -> opts:opts -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaElementAudioSourceNode/MediaElementAudioSourceNode}creates} a media element
          audio source node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val media_element : t -> Brr_io.Media.El.t
      (** [media_element n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaElementAudioSourceNode/mediaElement}media element} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Media stream destination nodes. *)
    module Media_stream_destination : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioDestinationNode/MediaStreamAudioDestinationNode#Parameters}[MediaStreamAudioDestinationOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t -> unit -> opts
      (** [opts ()] are media stream destination options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioDestinationNode/MediaStreamAudioDestinationNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioDestinationNode}[MediaStreamDestinationNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioDestinationNode/MediaStreamAudioDestinationNode}creates} a media stream destination node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val stream : t -> Brr_io.Media.Stream.t
      (** [stream n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioDestinationNode/stream}stream} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Media stream source nodes. *)
    module Media_stream_source : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode/MediaStreamAudioSourceNode#Parameters}[MediaStreamAudioSourceOptions]}. *)

      val opts : stream:Brr_io.Media.Stream.t -> unit -> opts
      (** [opts ~stream ()] are media stream source node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode/MediaStreamAudioSourceNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode}[MediaStreamAudioSourceNode]} objects. *)

      val create : context -> opts:opts -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode/MediaStreamAudioSourceNode}creates} a media stream
          audio source node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val media_stream : t -> Brr_io.Media.Stream.t
      (** [media_stream n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode/mediaStream}media stream} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Media stream track source nodes. *)
    module Media_stream_track_source : sig
      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrackAudioSourceNode/MediaStreamTrackAudioSourceNode#Parameters}[MediaStreamTrackAudioSourceOptions]}. *)

      val opts : stream:Brr_io.Media.Track.t -> unit -> opts
      (** [opts ~stream ()] are media stream track source node options with
          given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrackAudioSourceNode/MediaStreamTrackAudioSourceNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrackAudioSourceNode}[MediaStreamTrackAudioSourceNode]} objects. *)

      val create : context -> opts:opts -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrackAudioSourceNode/MediaStreamTrackAudioSourceNode}creates} a media stream track audio source node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Oscillator nodes. *)
    module Oscillator : sig

      (** Periodic waves. *)
      module Periodic_wave : sig
        type opts
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/PeriodicWave/PeriodicWave#Parameters}[PeriodicWaveOptions]}. *)

        val opts :
          ?disable_normalization:bool ->
          ?real:Tarray.float32 -> ?imag:Tarray.float32 -> unit -> opts
      (** [opts ()] are periodic wave options with the
          given {{:https://developer.mozilla.org/en-US/docs/Web/API/PeriodicWave/PeriodicWave#Parameters}parameters}. *)

        type t
        (** The type for
            {{:https://developer.mozilla.org/en-US/docs/Web/API/PeriodicWave}
            [PeriodicWave]} objects. *)

        val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/PeriodicWave/PeriodicWave}creates} a periodic wave. *)

        (**/**)
        include Jv.CONV with type t := t
        (**/**)
      end

      (** Oscillator type enumeration. *)
      module Type :sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/type#Value}[OscillatorType]} values. *)

        val sine : t
        val square : t
        val sawtooth : t
        val triangle : t
        val custom : t
      end

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/OscillatorNode#Parameters}[OscillatorOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?type':Type.t -> ?frequency:float -> ?detune:float ->
        ?periodic_wave:Periodic_wave.t -> unit -> opts
      (** [opts ()] are oscillator node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/OscillatorNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode}
          [OscillatorNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/OscillatorNode}creates} an oscillator node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val type' : t -> Type.t
      (** [type' n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/type}type} of [n]. *)

      val set_type : t -> Type.t -> unit
      (** [set_type n v] sets the {!type'} of [n] to [v]. *)

      val detune : t -> Param.t
      (** [detune n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/detune}frequency detuning} of [n]. *)

      val frequency : t -> Param.t
      (** [frequency n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/frequency}frequency} of [n]. *)

      val set_periodic_wave : t -> Periodic_wave.t -> unit
      (** [set_periodic_wave n w] {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/setPeriodicWave}sets} the periodic wave of [n] to [w]. *)

      val start : ?time:float -> t -> unit
      (** [start n] {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/start}starts} node [n]. *)

      val stop : ?time:float -> t -> unit
      (** [stop n] {{:https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/stop}stops} node [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Panner nodes. *)
    module Panner : sig

      (** Panning model type enumeration. *)
      module Panning_model : sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/panningModel}[PanningModelType]} values. *)

        val equalpower : t
        val hrtf : t
      end

      (** Distance model type enumeration. *)
      module Distance_model : sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/distanceModel}[DistanceModelType]} values. *)

        val linear : t
        val inverse : t
        val exponential : t
      end

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/PannerNode#Parameters}[PannerOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?panning_model:Panning_model.t ->
        ?distance_model:Distance_model.t ->
        ?position_x:float -> ?position_y:float -> ?position_z:float ->
        ?orientation_x:float -> ?orientation_y:float -> ?orientation_z:float ->
        ?ref_distance:float -> ?max_distance:float -> ?rolloff_factor:float ->
        ?cone_inner_angle:float -> ?cone_outer_angle:float ->
        ?cone_outer_gain:float -> unit -> opts
      (** [opts ()] are panner node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/PannerNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode}
          [PannerNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/PannerNode}creates} a panner node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val panning_model : t -> Panning_model.t
      (** [panning_model n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/panningModel}panning model} of [n]. *)

      val set_panning_model : t -> Panning_model.t -> unit
      (** [set_panning_model n v] sets the {!panning_model} of [n] to [v]. *)

      val distance_model : t -> Distance_model.t
      (** [distance_model n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/distanceModel}distance model} of [n]. *)

      val set_distance_model : t -> Distance_model.t -> unit
      (** [set_distance_model n v] sets the {!distance_model} of [n] to [v]. *)

      val position_x : t -> Param.t
      (** [position_x n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/positionX}x position} of [n]. *)

      val position_y : t -> Param.t
      (** [position_y n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/positionY}y position} of [n]. *)

      val position_z : t -> Param.t
      (** [position_z n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/positionZ}z position} of [n]. *)

      val orientation_x : t -> Param.t
      (** [orientation_x n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/orientationX}x orientation} of [n]. *)

      val orientation_y : t -> Param.t
      (** [orientation_y n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/orientationY}y orientation} of [n]. *)

      val orientation_z : t -> Param.t
      (** [orientation_z n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/orientationZ}z orientation} of [n]. *)

      val ref_distance : t -> float
      (** [ref_distance n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/refDistance}reference distance} of [n]. *)

      val set_ref_distance : t -> float -> unit
      (** [set_ref_distance n v] sets the {!ref_distance} of [n] to [v]. *)

      val max_distance : t -> float
      (** [max_distance n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/maxDistance}maximal distance} of [n]. *)

      val set_max_distance : t -> float -> unit
      (** [set_max_distance n v] sets the {!max_distance} of [n] to [v]. *)

      val cone_inner_angle : t -> float
      (** [cone_inner_angle n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/coneInnerAngle}cone inner angle} of [n]. *)

      val set_cone_inner_angle : t -> float -> unit
      (** [set_cone_inner_angle n v] sets the {!cone_inner_angle}
          of [n] to [v]. *)

      val cone_outer_angle : t -> float
      (** [cone_outer_angle n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/coneOuterAngle}cone outer angle} of [n]. *)

      val set_cone_outer_angle : t -> float -> unit
      (** [set_cone_outer_angle n v] sets the {!cone_outer_angle}
          of [n] to [v]. *)

      val cone_outer_gain : t -> float
      (** [cone_outer_gain n] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/coneOuterGain}cone outer gain} of [n]. *)

      val set_cone_outer_gain : t -> float -> unit
      (** [set_cone_outer_gain n v] sets the {!cone_outer_gain}
          of [n] to [v]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Stereo panner nodes. *)
    module Stereo_panner : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode/StereoPannerNode#Parameters}[StereoPannerOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?pan:float -> unit -> opts
      (** [opts ()] are stereo panner node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode/StereoPannerNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode}
          [StereoPannerNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode/StereoPannerNode}creates} a stereo panner node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val pan : t -> Param.t
      (** [pan d] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/StereoPannerNode/pan}pan} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Wave shaper nodes. *)
    module Wave_shaper : sig

      (** Oversample type enumeration. *)
      module Oversample : sig
        type t = Jstr.t
        (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/oversample}[OverSampleType]} values. *)

        val none : Jstr.t
        val mul_2x : Jstr.t
        val mul_4x : Jstr.t
      end

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/WaveShaperNode#Parameters}[WaveShaperOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?curve:Tarray.float32 -> ?oversample:Oversample.t -> unit -> opts
      (** [opts ()] are wave shaper node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/WaveShaperNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode}
          [WaveShaperNode]} objects. *)

      val create : ?opts:opts -> context -> t
      (** [create ~opts c] {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/WaveShaperNode}creates} a wave shaper node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val curve : t -> Tarray.float32 option
      (** [curve n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/curve}curve} of [n]. *)

      val set_curve : t -> Tarray.float32 option -> unit
      (** [curve n v] sets the {!curve} of [n] to [v]. *)

      val oversample : t -> Oversample.t
      (** [oversample n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/WaveShaperNode/oversample}oversample} of [n]. *)

      val set_oversample : t -> Oversample.t -> unit
      (** [oversample n v] sets the {!oversample} of [n] to [v]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** Worklet nodes. *)
    module Worklet : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode/AudioWorkletNode#Parameters}[AudioWorkletOptions]}. *)

      val opts :
        ?channel_count:int -> ?channel_count_mode:Channel_count_mode.t ->
        ?channel_interpretation:Channel_interpretation.t ->
        ?input_count:int -> ?output_count:int ->
        ?output_channel_count:int list ->  ?parameters:Jv.t ->
        ?processor_options:Jv.t -> unit -> opts
      (** [opts ()] are worklet node options with given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode/AudioWorkletNode#Parameters}parameters}. *)

      type t
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode}
          [AudioWorkletNode]} objects. *)

      val create : ?opts:opts -> context -> Jstr.t -> t
      (** [create ~opts c n] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode/AudioWorkletNode}creates} a worklet node. *)

      external as_node : t -> node = "%identity"
      (** [as_node n] is [n] as an audio node. *)

      val parameter : t -> Jstr.t -> Param.t
      (** [parameter n p] is the
          {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode/parameters}parameter} [p] of [n]. *)

      val port : t -> Brr_io.Message.Port.t
      (** [port n] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioWorkletNode/port}port} of [n]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Audio timestamps *)
  module Timestamp : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/getOutputTimestamp}[AudioTimestamp]} objects. *)

    val context_time : t -> float
    (** [context_time t] is {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/getOutputTimestamp}the time} of the sample frame being
        rendered by the output device. *)

    val performance_time : t -> float
    (** [performance_time t] is an estimation of
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/getOutputTimestamp}the time}
        when the sample frame was rendered by the output device. *)

    (**/**)
    include Jv.CONV with type t := t
    (**/**)
  end

  (** Audio contexts. *)
  module Context : sig

    (** {1:base_contexts Base audio contexts} *)

    (** The context state enumeration. *)
    module State : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/state#Value}AudioContextState} enumeration. *)

      val suspended : t
      val running : t
      val closed : t
    end

    (** Base audio contexts. *)
    module Base : sig

      (** {1:audio_context Audio contexts} *)

      type t = Node.context
      (** The type for
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext}[BaseAudioContext]} objects. *)

      external as_target : t -> Ev.target = "%identity"
      (** [as_target c] is [c] as an event target. *)

      (* Note sure this is needed. Buffer's constructor can be used.

      val create_buffer :
        channel_count:int -> length:int -> sample_rate:float -> t ->
        Buffer.t
      (** [create_buffer ~channel ~length ~sample_rate c]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createBuffer}creates} an audio buffer. *) *)

      val decode_audio_data : t -> Buffer.t -> Buffer.t Fut.or_error
      (** [decode_audio_data t b]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/decodeAudioData}decodes} the audio data in [b]. *)

      (* Lets leave that out for now, node constructors allow to set params
         directly.

      (** {1:nodes Node creation} *)

      val create_analyser : t -> Node.Analyser.t
      (** [create_analyser c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createAnalyser}creates} an analyser node. *)

      val create_biquad_filter : t -> Node.Biquad_filter.t
      (** [create_biquad_filter c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createBiquadFilter}creates} a biquad filter node. *)

      val create_buffer_source : t -> Node.Buffer_source.t
      (** [create_buffer_source c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createBufferSource}creates} a buffer source node. *)

      val create_channel_merger :
        ?input_count:int -> t -> Node.Channel_merger.t
      (** [create_channel_merger c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createChannelMerger}creates} a channel merger node. *)

      val create_channel_splitter :
        ?output_count:int -> t -> Node.Channel_splitter.t
      (** [create_channel_splitter c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createChannelSplitter}creates} a channel splitter
          node. *)

      val create_constant_source : t -> Node.Constant_source.t
      (** [create_constant_source c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createConstantSource}creates} a constant source
          node. *)

      val create_convolver : t -> Node.Convolver.t
      (** [create_convolver c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createConvolver}creates} a convolver node. *)

      val create_delay : ?max_time:float -> t -> Node.Delay.t
      (** [create_delay c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createDelay}creates} a delay node. *)

      val create_dynamics_compressor : t -> Node.Dynamics_compressor.t
      (** [create_dynamics_compressor c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createDynamicsCompressor}creates} a dynamics
          compressor node. *)

      val create_gain : t -> Node.Gain.t
      (** [create_gain c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createGain}creates} a gain node. *)

      val create_iir_filter :
        feedforward:float -> feedback:float -> t -> Node.Iir_filter.t
      (** [create_iir_filter ~feedforward ~feedback c]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createIIRFilter}creates} an IIR filter node. *)

      val create_oscillator : t -> Node.Oscillator.t
      (** [create_oscillator c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createOscillator}creates} an oscillator node. *)

      val create_panner : t -> Node.Panner.t
      (** [create_panner c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createPanner}creates} creates a panner node. *)

      val create_periodic_wave :
        ?constraints:Node.Periodic_wave.constraints ->
        real:(float,'b) Tarray.t -> imag:(float, 'b) Tarray.t ->
        t -> Node.Periodic_wave.t
      (** [create_periodic_wave ~constraints ~real ~imag c]
          {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createPeriodicWave}creates} a periodic wave node. *)

      val create_stereo_panner : t -> Node.Stereo_panner.t
      (** [create_stereo_panner c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createStereoPanner}creates} a stereo panner
          node. *)

      val create_wave_shaper : t -> Node.Wave_shaper.t
      (** [create_wave_shaper c] {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createWaveShaper}creates} a wave shaper
          node. *)
*)

      (** {1:props Properties} *)

      val destination : t -> Node.Destination.t
      (** [destination c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/destination}destination} of [c]. *)

      val sample_rate : t -> float
      (** [sample_rate c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/sampleRate}sample rate} of [c]. *)

      val current_time : t -> float
      (** [current_time c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/currentTime}current time} of [c]. *)

      val listener : t -> Listener.t
      (** [listener c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/listener}listener} of [c]. *)

      val state : t -> State.t
      (** [state c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/state}state} of [c]. *)

      val audio_worklet : t -> Worklet.t
      (** [audio_worklet c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/audioWorklet}audio worklet} of [c]. *)

      (**/**)
      include Jv.CONV with type t := t
      (**/**)
    end

    (** {1:audio_context Audio contexts} *)

    (** Audio latency category enumeration. *)
    module Latency_category : sig
      type t = Jstr.t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContextLatencyCategory}[AudioContextLatencyCategory]} *)

      val balanced : Jstr.t
      val interactive : Jstr.t
      val playback : Jstr.t
    end

    type opts
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContextOptions}[AudioContextOptions]}. *)

    val opts :
      ?latency_hint:[`Category of Latency_category.t | `Secs of float] ->
      ?sample_rate_hz:float -> unit -> opts
    (** [opts ()] are audio context options with the given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContextOptions#Properties}properties}. *)

    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext}
        [AudioContext]} objects. *)

    val create : ?opts:opts -> unit -> t
    (** [create ~opts ()] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/AudioContext}creates} an audio context. *)

    external as_target : t -> Ev.target = "%identity"
    (** [as_target c] is [c] as an event target. *)

    external as_base : t -> Base.t = "%identity"
    (** [as_base c] is [c] as a base audio context. *)

    val base_latency : t -> float
    (** [base_latency c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/baseLatency}base latency} of [c]. *)

    val output_latency : t -> float
    (** [output_latency c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/outputLatency}output latency} of [c]. *)

    val get_output_timestamp : t -> Timestamp.t
    (** [get_output_timestamp c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/getOutputTimestamp}output timestamp} of [c]. *)

    val resume : t -> unit Fut.or_error
    (** [resume c] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/resume}resumes} progression of time in [c]. *)

    val suspend : t -> unit Fut.or_error
    (** [suspend c] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/suspend}suspend} progression of time in [c]. *)

    val close : t -> unit Fut.or_error
    (** [close c] {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/close}closes} the audio context [c]. *)

(* Lets leave that out for now, node constructors allow to set params
   directly.

    (** {2:nodes Node creation}

        See also {{!Base.nodes}base nodes}. *)

    val create_media_element_source :
      t -> Brr_io.Media.El.t -> Node.Media_element_source.t
    (** [create_media_element_source c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/createMediaElementSource}creates} a media element source node. *)

    val create_media_stream_destination : t -> Node.Media_stream_destination.t
    (** [create_media_stream_destination c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/createMediaStreamDestination}creates} a media stream destination node. *)

    val create_media_stream_source :
      t -> Brr_io.Media.Stream.t -> Node.Media_stream_source.t
    (** [create_media_stream_source c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/createMediaStreamSource}creates} a media stream source node. *)

    val create_media_stream_track_source :
      t -> Brr_io.Media.Track.t -> Node.Media_stream_track_source.t
    (** [create_media_stream_track_source c]
        {{:https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/createMediaStreamTrackSource}creates} a media stream track source node. *)
*)

    (** {1:offline_context Offline audio contexts} *)

    (** Offline audio contexts. *)
    module Offline : sig

      type opts
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/OfflineAudioContext#Parameters}[OfflineAudioContextOptions]}. *)

      val opts :
        channel_count:int -> length:int -> sample_rate_hz:float -> unit -> opts
      (** [opts ~channel_count ~length ~sample_rate_ht ()] are audio context
          options with the given
          {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/OfflineAudioContext#Parameters}properties}. *)

      type t
      (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext}[OfflineAudioContext]} objects. *)

      val create : opts -> t
      (** [create opts] {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/OfflineAudioContext#Parameters}creates} an offline audio
          context with given parameters. *)

      external as_target : t -> Ev.target = "%identity"
      (** [as_target c] is [c] as an event target. *)

      external as_base : t -> Base.t = "%identity"
      (** [as_base c] is [c] as a base audio context. *)

      val length : t -> int
      (** [length c] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/length}length} of the buffer in sample-frames. *)

      val start_rendering : t -> Buffer.t Fut.or_error
      (** [start_rendering c] {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/startRendering}starts} rendering the audio graph
          and determines with the rendered audio buffer. *)

      val suspend : t -> secs:float -> unit Fut.or_error
      (** [suspend c] {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/suspend}suspends} rendering for [secs] seconds. *)

      val resume : t -> unit Fut.or_error
      (** [resume c] {{:https://developer.mozilla.org/en-US/docs/Web/API/OfflineAudioContext/resume}resumes} rendering. *)
    end

  end
end
