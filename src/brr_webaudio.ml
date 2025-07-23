(*----------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

module Audio = struct
  module Param = struct
    module Automation_rate = struct
      type t = Jstr.t
      let a_rate = Jstr.v "a-rate"
      let k_rate = Jstr.v "k-rate"
    end
    type descriptor = Jv.t
    let descriptor ?automation_rate ?min_value ?max_value ?default_value n =
      ignore default_value ;
      let o = Jv.obj [||] in
      Jv.set o "name" (Jv.of_jstr n);
      Jv.Jstr.set_if_some o "automationRate" automation_rate;
      Jv.Float.set_if_some o "minValue" min_value;
      Jv.Float.set_if_some o "maxValue" max_value;
      Jv.Float.set_if_some o "defaultValue" max_value;
      o

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let value p = Jv.Float.get p "value"
    let set_value p v = Jv.Float.set p "value" v
    let automation_rate p = Jv.Jstr.get p "automationRate"
    let set_automation_rate p v = Jv.Jstr.set p "automationRate" v
    let default_value p = Jv.Float.get p "defaultValue"
    let min_value p = Jv.Float.get p "minValue"
    let max_value p = Jv.Float.get p "maxValue"
    let set_value_at_time p ~value:v ~time:t =
      ignore @@ Jv.call p "setValueAtTime" Jv.[| of_float v; of_float t |]

    let linear_ramp_to_value_at_time p ~value:v ~end_time:t =
      ignore @@
      Jv.call p "linearRampToValueAtTime" Jv.[| of_float v; of_float t |]

    let exponential_ramp_to_value_at_time p ~value:v ~end_time:t =
      ignore @@
      Jv.call p "exponentialRampToValueAtTime" Jv.[| of_float v; of_float t |]

    let set_target_at_time p ~target:v ~start_time:t ~decay_rate:r =
      ignore @@
      Jv.call p "setTargetAtTime" Jv.[| of_float v; of_float t; of_float r |]

    let set_value_curve_at_time p vs ~start_time:t ~dur_s:d =
      let args = Jv.[| Tarray.to_jv vs; of_float t; of_float d |] in
      ignore @@ Jv.call p "setValueCurveAtTime" args

    let cancel_scheduled_values p ~time:t =
      ignore @@ Jv.call p "cancelScheduledValues" Jv.[| of_float t |]

    let cancel_and_hold_at_time p ~time:t =
      ignore @@ Jv.call p "cancelAndHoldAtTime" Jv.[| of_float t |]
  end

  module Listener= struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let position_x l = Param.of_jv @@ Jv.call l "positionX" [||]
    let position_y l = Param.of_jv @@ Jv.call l "positionY" [||]
    let position_z l = Param.of_jv @@ Jv.call l "positionZ" [||]
    let forward_x l = Param.of_jv @@ Jv.call l "forwardX" [||]
    let forward_y l = Param.of_jv @@ Jv.call l "forwardY" [||]
    let forward_z l = Param.of_jv @@ Jv.call l "forwardZ" [||]
    let up_x l = Param.of_jv @@ Jv.call l "upX" [||]
    let up_y l = Param.of_jv @@ Jv.call l "upY" [||]
    let up_z l = Param.of_jv @@ Jv.call l "upZ" [||]
  end

  module Worklet = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let add_module w url =
      Fut.of_promise ~ok:ignore @@ Jv.call w "addModule" Jv.[| of_jstr url |]


    module G = struct
      let register_processor n c =
        let args = Jv.[|of_jstr n; c|] in
        ignore @@ Jv.apply (Jv.get Jv.global "registerProcessor") args

      let current_frame () = Jv.Int.get Jv.global "currentFrame"
      let current_time () = Jv.Float.get Jv.global "currentTime"
      let sample_rate () = Jv.Float.get Jv.global "sampleRate"
    end

    module Processor = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      let port p = Brr_io.Message.Port.of_jv @@ Jv.get p "port"
    end
  end

  module Buffer = struct
    type opts = Jv.t
    let opts ~channel_count:cc ~length:l ~sample_rate_hz:r () =
      Jv.obj Jv.[| "numberOfChannels", of_int cc;
                   "length", of_int l;
                   "sampleRate", of_float r |]

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let create opts = Jv.new' (Jv.get Jv.global "AudioBuffer") [| opts |]
    let sample_rate b = Jv.Float.get b "sampleRate"
    let length b = Jv.Int.get b "length"
    let duration_s b = Jv.Float.get b "length"
    let channel_count b = Jv.Int.get b "numberOfChannels"
    let get_channel_data b ~channel =
      Tarray.of_jv @@ Jv.call b "getChannelData" Jv.[| of_int channel |]

    let copy_from_channel ?(dst_start = 0) b ~channel:c ~dst =
      let args = Jv.[| Tarray.to_jv dst; of_int c; of_int dst_start |] in
      ignore @@ Jv.call b "copyFromChannel" args

    let copy_to_channel ?(dst_start = 0) b ~src ~channel:c =
      let args = Jv.[| Tarray.to_jv src; of_int c; of_int dst_start |] in
      ignore @@ Jv.call b "copyToChannel" args
  end

  module Node = struct
    module Channel_count_mode = struct
      type t = Jstr.t
      let max = Jstr.v "max"
      let clamped_max = Jstr.v "clamped-max"
      let explicit = Jstr.v "explicit"
    end
    module Channel_interpretation = struct
      type t = Jstr.t
      let speakers = Jstr.v "speakers"
      let discrete = Jstr.v "discrete"
    end

    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    type node = t
    type context = Jv.t
    external as_target : t -> Ev.target = "%identity"

    let context n = Jv.get n "context"
    let input_count n = Jv.Int.get n "numberOfInputs"
    let output_count n = Jv.Int.get n "numberOfOutputs"
    let channel_count n = Jv.Int.get n "channelCount"
    let set_channel_count n c = Jv.Int.set n "channelCount" c
    let channel_count_mode n = Jv.Jstr.get n "channelCountMode"
    let set_channel_count_mode n m = Jv.Jstr.set n "channelCountMode" m
    let channel_interpretation n = Jv.Jstr.get n "channelInterpretation"
    let set_channel_interpretation n i =
      Jv.Jstr.set n "channelInterpretation" i

    let connect_node ?(output = 0) ?(input = 0) n ~dst =
      ignore @@ Jv.call n "connect" Jv.[| dst; of_int output; of_int input |]

    let connect_param ?(output = 0) n ~dst =
      ignore @@ Jv.call n "connect" Jv.[| dst; of_int output |]

    let disconnect n = ignore @@ Jv.call n "disconnect" [||]
    let disconnect_node ?output ?input n ~dst =
      let output = Jv.of_option ~none:Jv.undefined Jv.of_int output in
      let input = Jv.of_option ~none:Jv.undefined Jv.of_int input in
      ignore @@ Jv.call n "disconnect" [| dst; output; input |]

    let disconnect_param ?output n ~dst =
      let output = Jv.of_option ~none:Jv.undefined Jv.of_int output in
      ignore @@ Jv.call n "disconnect" [| dst; output |]

    (* Node types *)

    module Analyser = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?fft_size ?max_decibels ?min_decibels ?smoothing_time_constant ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Int.set_if_some o "fftSize" fft_size;
        Jv.Float.set_if_some o "minDecibels" min_decibels;
        Jv.Float.set_if_some o "maxDecibels" max_decibels;
        Jv.Float.set_if_some o "smoothingTimeConstant" smoothing_time_constant;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"

      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "AnalyserNode") [|c; opts|]

      let get_float_frequency_data n a =
        ignore @@ Jv.call n "getFloatFrequencyData" [| Tarray.to_jv a |]

      let get_byte_frequency_data n a =
        ignore @@ Jv.call n "getByteFrequencyData" [| Tarray.to_jv a |]

      let get_float_time_domain_data n a =
        ignore @@ Jv.call n "getFloatTimeDomainData" [| Tarray.to_jv a |]

      let get_byte_time_domain_data n a =
        ignore @@ Jv.call n "getByteTimeDomainData" [| Tarray.to_jv a |]

      let fft_size n = Jv.Int.get n "fftSize"
      let set_fft_size n v = Jv.Int.set n "fftSize" v
      let frequency_bin_count n = Jv.Int.get n "frequencyBinCount"
      let min_decibels n = Jv.Float.get n "minDecibels"
      let set_min_decibels n v = Jv.Float.set n "minDecibels" v
      let max_decibels n = Jv.Float.get n "maxDecibels"
      let set_max_decibels n v = Jv.Float.set n "maxDecibels" v

      let smoothing_time_constant n = Jv.Float.get n "smoothingTimeConstant"
      let set_smoothing_time_constant n v =
        Jv.Float.set n "smoothingTimeConstant" v
    end

    module Biquad_filter = struct
      module Type = struct
        type t = Jstr.t

        let lowpass = Jstr.v "lowpass"
        let highpass = Jstr.v "highpass"
        let bandpass = Jstr.v "bandpass"
        let lowshelf = Jstr.v "lowshelf"
        let highshelf = Jstr.v "highshelf"
        let peaking = Jstr.v "peaking"
        let notch = Jstr.v "notch"
        let allpass = Jstr.v "allpass"
      end
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation ?type'
          ?q ?detune ?frequency ?gain ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Jstr.set_if_some o "type" type';
        Jv.Float.set_if_some o "Q" q;
        Jv.Float.set_if_some o "detune" detune;
        Jv.Float.set_if_some o "frequency" frequency;
        Jv.Float.set_if_some o "gain" gain;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"

      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "BiquadFilterNode") [| c; opts |]

      let type' n = Jv.Jstr.get n "type"
      let set_type n v = Jv.Jstr.set n "type" v
      let detune n = Param.of_jv @@ Jv.call n "detune" [||]
      let frequency n = Param.of_jv @@ Jv.call n "frequency" [||]
      let q n = Param.of_jv @@ Jv.call n "Q" [||]
      let gain n = Param.of_jv @@ Jv.call n "gain" [||]
      let get_frequency_response
          n ~frequencies:f ~mag_response:m ~phase_response:p
        =
        let args = Tarray.[| to_jv f; to_jv m; to_jv p |] in
        ignore @@ Jv.call n "getFrequencyResponse" args
    end

    module Buffer_source = struct
      type opts = Jv.t
      let opts
          ?buffer ?detune ?loop ?loop_start ?loop_end ?playback_rate ()
        =
        let o = Jv.obj [||] in
        Jv.set_if_some o "buffer" buffer;
        Jv.Float.set_if_some o "detune" detune;
        Jv.Bool.set_if_some o "loop" loop;
        Jv.Float.set_if_some o "loop_start" loop_start;
        Jv.Float.set_if_some o "loop_end" loop_end;
        Jv.Float.set_if_some o "playbackRate" playback_rate;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "AudioBufferSourceNode") [| c; opts |]

      let buffer n = Jv.find_map Buffer.of_jv n "buffer"
      let set_buffer n v =
        Jv.set n "buffer" (Jv.of_option ~none:Jv.null Buffer.to_jv v)

      let playback_rate n = Param.of_jv @@ Jv.get n "playbackRate"
      let detune n =  Param.of_jv @@ Jv.get n "detune"
      let loop n = Jv.Bool.get n "loop"
      let set_loop n b =  Jv.Bool.set n "loop" b
      let loop_start n = Jv.Float.get n "loopStart"
      let set_loop_start n v = Jv.Float.set n "loopStart" v
      let loop_end n = Jv.Float.get n "loopEnd"
      let set_loop_end n v = Jv.Float.set n "loopEnd" v

      let start ?time:t ?offset:o ?dur_s:d n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        let o = Jv.of_option ~none:Jv.undefined Jv.of_float o in
        let d = Jv.of_option ~none:Jv.undefined Jv.of_float d in
        ignore @@ Jv.call n "start" [| t; o; d |]

      let stop ?time:t n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        ignore @@ Jv.call n "stop" [| t |]
    end

    module Channel_merger = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?input_count ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Int.set_if_some o "numberOfInputs" input_count;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "ChannelMergerNode") [| c; opts |]
    end

    module Channel_splitter = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?output_count ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Int.set_if_some o "numberOfOutput" output_count;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "ChannelSplitterNode") [| c; opts |]
    end

    module Constant_source = struct
      type opts = Jv.t
      let opts ?offset () =
        let o = Jv.obj [||] in
        Jv.Float.set_if_some o "offset" offset;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "ConstantSourceNode") [| c; opts |]

      let offset n = Param.of_jv @@ Jv.get n "offset"

      let start ?time:t n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        ignore @@ Jv.call n "start" [| t |]

      let stop ?time:t n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        ignore @@ Jv.call n "stop" [| t |]
    end

    module Convolver = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?buffer ?disable_normalization ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.set_if_some o "buffer" buffer;
        Jv.Bool.set_if_some o "disableNormalization" disable_normalization;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "ConvolverNode") [| c; opts |]

      let buffer n = Jv.find_map Buffer.of_jv n "buffer"
      let set_buffer n v =
        Jv.set n "buffer" (Jv.of_option ~none:Jv.null Buffer.to_jv v)

      let normalize n = Jv.Bool.get n "normalize"
      let set_normalize n b =  Jv.Bool.set n "normalize" b
    end

    module Delay = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?delay_time ?max_delay_time ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Float.set_if_some o "delayTime" delay_time;
        Jv.Float.set_if_some o "maxDelayTime" max_delay_time;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "DelayNode") [| c; opts |]

      let delay_time n = Param.of_jv @@ Jv.get n "delayTime"
    end

    module Destination = struct
      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let max_channel_count n = Jv.Int.get n "maxChannelCount"
    end

    module Dynamics_compressor = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?attack ?knee ?ratio ?release ?threshold ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Float.set_if_some o "attack" attack;
        Jv.Float.set_if_some o "knee" knee;
        Jv.Float.set_if_some o "ratio" ratio;
        Jv.Float.set_if_some o "release" release;
        Jv.Float.set_if_some o "threshold" threshold;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "DynamicsCompressorNode") [| c; opts |]

      let attack n = Param.of_jv @@ Jv.get n "attack"
      let knee n = Param.of_jv @@ Jv.get n "knee"
      let ratio n = Param.of_jv @@ Jv.get n "ratio"
      let reduction n = Jv.Float.get n "reduction"
      let release n = Param.of_jv @@ Jv.get n "release"
      let threshold n = Param.of_jv @@ Jv.get n "threshold"
    end

    module Gain = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation ?gain () =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Float.set_if_some o "gain" gain;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "GainNode") [| c; opts |]

      let gain n = Param.of_jv @@ Jv.get n "gain"
    end

    module Iir_filter = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ~feedforward ~feedback ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.set o "feedforward" (Tarray.to_jv feedforward);
        Jv.set o "feedback" (Tarray.to_jv feedback);
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create c ~opts =
        Jv.new' (Jv.get Jv.global "IIRFilterNode") [| c; opts |]

      let get_frequency_response
          n ~frequencies:f ~mag_response:m ~phase_response:p
        =
        let args = Tarray.[| to_jv f; to_jv m; to_jv p |] in
        ignore @@ Jv.call n "getFrequencyResponse" args
    end

    module Media_element_source = struct
      type opts = Jv.t
      let opts ~el () =
        let o = Jv.obj [||] in
        Jv.set o "mediaElement" (Brr_io.Media.El.to_jv el);
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create c ~opts =
        Jv.new' (Jv.get Jv.global "MediaElementAudioSourceNode") [| c; opts |]

      let media_element n = Brr_io.Media.El.of_jv @@ Jv.get n "mediaElement"
    end

    module Media_stream_destination = struct
      type opts = Jv.t
      let opts ?channel_count ?channel_count_mode ?channel_interpretation () =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "MediaStreamAudioDestinationNode")
          [| c; opts |]

      let stream n = Brr_io.Media.Stream.of_jv @@ Jv.get n "stream"
    end

    module Media_stream_source = struct
      type opts = Jv.t
      let opts ~stream () =
        let o = Jv.obj [||] in
        Jv.set o "mediaStream" (Brr_io.Media.Stream.to_jv stream);
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create c ~opts =
        Jv.new' (Jv.get Jv.global "MediaStreamAudioSourceNode") [| c; opts |]

      let media_stream n = Brr_io.Media.Stream.of_jv @@ Jv.get n "mediaStream"
    end

    module Media_stream_track_source = struct
      type opts = Jv.t
      let opts ~stream () =
        let o = Jv.obj [||] in
        Jv.set o "mediaStreamTrack" (Brr_io.Media.Track.to_jv stream);
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create c ~opts =
        Jv.new' (Jv.get Jv.global "MediaStreamTrackAudioSourceNode ")
          [| c; opts |]
    end

    module Oscillator = struct
      module Periodic_wave = struct
        type opts = Jv.t
        let opts ?disable_normalization ?real ?imag () =
          let o = Jv.obj [||] in
          Jv.Bool.set_if_some o "disableNormalization" disable_normalization;
          Jv.set o "real" (Jv.of_option ~none:Jv.undefined Tarray.to_jv real);
          Jv.set o "imag" (Jv.of_option ~none:Jv.undefined Tarray.to_jv imag);
          o

        type t = Jv.t
        include (Jv.Id : Jv.CONV with type t := t)
        let create ?(opts = Jv.undefined) c =
          Jv.new' (Jv.get Jv.global "PeriodicWave") [| c; opts |]
      end
      module Type = struct
        type t = Jstr.t
        let sine = Jstr.v "sine"
        let square = Jstr.v "square"
        let sawtooth = Jstr.v "sawtooth"
        let triangle = Jstr.v "triangle"
        let custom = Jstr.v "custom"
      end
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?type' ?frequency ?detune ?periodic_wave () =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Jstr.set_if_some o "type" type';
        Jv.Float.set_if_some o "frequency" frequency;
        Jv.Float.set_if_some o "detune" detune;
        Jv.set_if_some o "periodicWave" periodic_wave;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "OscillatorNode") [| c; opts |]

      let type' n = Jv.Jstr.get n "type"
      let set_type n v = Jv.Jstr.set n "type" v
      let detune n = Param.of_jv @@ Jv.call n "detune" [||]
      let frequency n = Param.of_jv @@ Jv.call n "frequency" [||]
      let set_periodic_wave n w =
        ignore @@ Jv.call n "setPeriodicWave" [| Periodic_wave.to_jv w |]

      let start ?time:t n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        ignore @@ Jv.call n "start" [| t |]

      let stop ?time:t n =
        let t = Jv.of_option ~none:Jv.undefined Jv.of_float t in
        ignore @@ Jv.call n "stop" [| t |]
    end

    module Panner = struct
      module Panning_model = struct
        type t = Jstr.t
        let equalpower = Jstr.v "equalpower"
        let hrtf = Jstr.v "HRTF"
      end
      module Distance_model = struct
        type t = Jstr.t
        let linear = Jstr.v "linear"
        let inverse = Jstr.v "inverse"
        let exponential = Jstr.v "exponential"
      end
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?panning_model ?distance_model ?position_x ?position_y
          ?position_z ?orientation_x ?orientation_y ?orientation_z
          ?ref_distance ?max_distance ?rolloff_factor ?cone_inner_angle
          ?cone_outer_angle ?cone_outer_gain ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Jstr.set_if_some o "panningModel" panning_model;
        Jv.Jstr.set_if_some o "distanceModel" distance_model;
        Jv.Float.set_if_some o "positionX" position_x;
        Jv.Float.set_if_some o "positionY" position_y;
        Jv.Float.set_if_some o "positionZ" position_z;
        Jv.Float.set_if_some o "orientationX" orientation_x;
        Jv.Float.set_if_some o "orientationY" orientation_y;
        Jv.Float.set_if_some o "orientationZ" orientation_z;
        Jv.Float.set_if_some o "refDistance" ref_distance;
        Jv.Float.set_if_some o "maxDistance" max_distance;
        Jv.Float.set_if_some o "rolloff_factor" rolloff_factor;
        Jv.Float.set_if_some o "cone_inner_angle" cone_inner_angle;
        Jv.Float.set_if_some o "cone_outer_angle" cone_outer_angle;
        Jv.Float.set_if_some o "cone_outer_gain" cone_outer_gain;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "PannerNode") [| c; opts |]

      let panning_model n = Jv.Jstr.get n "panningModel"
      let set_panning_model n v = Jv.Jstr.set n "panningModel" v
      let distance_model n = Jv.Jstr.get n "distanceModel"
      let set_distance_model n v = Jv.Jstr.set n "distanceModel" v
      let position_x n = Param.of_jv @@ Jv.get n "positionX"
      let position_y n = Param.of_jv @@ Jv.get n "positionY"
      let position_z n = Param.of_jv @@ Jv.get n "positionZ"
      let orientation_x n = Param.of_jv @@ Jv.get n "orientationX"
      let orientation_y n = Param.of_jv @@ Jv.get n "orientationY"
      let orientation_z n = Param.of_jv @@ Jv.get n "orientationZ"
      let ref_distance n = Jv.Float.get n "refDistance"
      let set_ref_distance n v = Jv.Float.set n "refDistance" v
      let max_distance n = Jv.Float.get n "maxDistance"
      let set_max_distance n v = Jv.Float.set n "maxDistance" v
      let cone_inner_angle n = Jv.Float.get n "coneInnerAngle"
      let set_cone_inner_angle n v = Jv.Float.set n "coneInnerAngle" v
      let cone_outer_angle n = Jv.Float.get n "coneOuterAngle"
      let set_cone_outer_angle n v = Jv.Float.set n "coneOuterAngle" v
      let cone_outer_gain n = Jv.Float.get n "coneOuterGain"
      let set_cone_outer_gain n v = Jv.Float.set n "coneOuterGain" v
    end

    module Stereo_panner = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation ?pan ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Float.set_if_some o "pan" pan;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "StereoPannerNode") [| c; opts |]

      let pan n = Param.of_jv @@ Jv.get n "pan"
    end

    module Wave_shaper = struct
      module Oversample = struct
        type t = Jstr.t
        let none = Jstr.v "none"
        let mul_2x = Jstr.v "2x"
        let mul_4x = Jstr.v "4x"
      end
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation ?curve
          ?oversample () =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.set o "curve" (Jv.of_option ~none:Jv.undefined Tarray.to_jv curve);
        Jv.Jstr.set_if_some o "oversample" oversample;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c =
        Jv.new' (Jv.get Jv.global "WaveShaperNode") [| c; opts |]

      let curve n = Jv.to_option Tarray.of_jv @@ Jv.get n "curve"
      let set_curve n v =
        Jv.set n "curve" (Jv.of_option ~none:Jv.null Tarray.to_jv v)

      let oversample n = Jv.Jstr.get n "oversample"
      let set_oversample n v = Jv.Jstr.set n "oversample" v
    end

    module Worklet = struct
      type opts = Jv.t
      let opts
          ?channel_count ?channel_count_mode ?channel_interpretation
          ?input_count ?output_count ?output_channel_count ?parameters
          ?processor_options ()
        =
        let o = Jv.obj [||] in
        Jv.Int.set_if_some o "channelCount" channel_count;
        Jv.Jstr.set_if_some o "channelCountMode" channel_count_mode;
        Jv.Jstr.set_if_some o "channelInterpretation" channel_interpretation;
        Jv.Int.set_if_some o "numberOfInputs" input_count;
        Jv.Int.set_if_some o "numberOfOutputs" output_count;
        Jv.set_if_some o "outputChannelCount"
          (Option.map (Jv.of_list Jv.of_int) output_channel_count);
        Jv.set_if_some o "parameterData" parameters;
        Jv.set_if_some o "processorOptions" processor_options;
        o

      type t = Jv.t
      include (Jv.Id : Jv.CONV with type t := t)
      external as_node : t -> node = "%identity"
      let create ?(opts = Jv.undefined) c name =
        let args = Jv.[| c; of_jstr name; opts |] in
        Jv.new' (Jv.get Jv.global "AudioWorkletNode") args

      let parameter n k =
        let p = Jv.call (Jv.get n "parameters") "get" Jv.[|of_jstr k|] in
        if Jv.is_none p then Jv.throw (Jstr.(v "no parameter named " + k)) else
        p

      let port n = Brr_io.Message.Port.of_jv @@ Jv.get n "port"
    end

  end

  module Timestamp = struct
    type t = Jv.t
    include (Jv.Id : Jv.CONV with type t := t)
    let context_time t = Jv.Float.get t "contextTime"
    let performance_time t = Jv.Float.get t "performanceTime"
  end

  module Context = struct
    module State = struct
      type t = Jstr.t
      let suspended = Jstr.v "suspended"
      let running = Jstr.v "running"
      let closed = Jstr.v "closed"
    end
    module Base = struct
      type t = Node.context
      include (Jv.Id : Jv.CONV with type t := t)
      external as_target : t -> Ev.target = "%identity"

      (* Note sure this is needed. Buffer's constructor can be used.

      let create_buffer ~channel_count:cc ~length:l ~sample_rate:r c =
         Buffer.of_jv @@
         Jv.call c "createBuffer" Jv.[| of_int cc; of_int l; of_float r |]
      *)

      let decode_audio_data c b =
        Fut.of_promise ~ok:Buffer.of_jv @@
        Jv.call c "decodeAudioData" [| Buffer.to_jv b |]

      (* Lets leave that out for now, node constructors allow to set params
         directly.

      let create_analyser c =
        Node.Analyser.of_jv @@ Jv.call c "createAnalyser" [||]

      let create_biquad_filter c =
        Node.Biquad_filter.of_jv @@ Jv.call c "createBiquadFilter" [||]

      let create_buffer_source c =
        Node.Buffer_source.of_jv @@ Jv.call c "createBufferSource" [||]

      let create_channel_merger ?input_count:ic c =
        let ic = Jv.of_option ~none:Jv.undefined Jv.of_int ic in
        Node.Channel_merger.of_jv @@ Jv.call c "createChannelMerger" [|ic|]

      let create_channel_splitter ?output_count:oc c =
        let oc = Jv.of_option ~none:Jv.undefined Jv.of_int oc in
        Node.Channel_splitter.of_jv @@ Jv.call c "createChannelSplitter" [|oc|]

      let create_constant_source c =
        Node.Constant_source.of_jv @@ Jv.call c "createConstantSource" [||]

      let create_convolver c =
        Node.Convolver.of_jv @@ Jv.call c "createConvolver" [||]

      let create_delay ?max_time:m c =
        let m = Jv.of_option ~none:Jv.undefined Jv.of_float m in
        Node.Delay.of_jv @@ Jv.call c "createDelay" [|m|]

      let create_dynamics_compressor c =
        Node.Dynamics_compressor.of_jv @@
        Jv.call c "createDynamicsCompressor" [||]

      let create_gain c =
        Node.Gain.of_jv @@ Jv.call c "createGain" [||]

      let create_iir_filter ~feedforward:ff ~feedback:fb c =
        Node.Iir_filter.of_jv @@
        Jv.call c "createIIRFilter" Jv.[|of_float ff; of_float fb|]

      let create_oscillator c =
        Node.Oscillator.of_jv @@ Jv.call c "createOscillator" [||]

      let create_panner c =
        Node.Panner.of_jv @@ Jv.call c "createPanner" [||]

      let create_periodic_wave ?(constraints = Jv.undefined) ~real ~imag c =
        Node.Periodic_wave.of_jv @@
        let args = [|Tarray.to_jv real; Tarray.to_jv imag; constraints |] in
        Jv.call c "createPeriodicWave" args

      let create_stereo_panner c =
        Node.Stereo_panner.of_jv @@ Jv.call c "createStereoPanner" [||]

      let create_wave_shaper c =
        Node.Wave_shaper.of_jv @@ Jv.call c "createWaveShaper" [||] *)

      let destination c = Node.Destination.of_jv @@ Jv.get c "destination"
      let sample_rate c = Jv.Float.get c "sampleRate"
      let current_time c = Jv.Float.get c "currentTime"
      let listener c = Listener.of_jv @@ Jv.get c "listener"
      let state c = Jv.Jstr.get c "state"
      let audio_worklet c = Worklet.of_jv @@ Jv.get c "audioWorklet"
    end

    (* Audio contexts *)

    module Latency_category = struct
      type t = Jstr.t
      let balanced = Jstr.v "balanced"
      let interactive = Jstr.v "interactive"
      let playback = Jstr.v "playback"
    end

    type opts = Jv.t
    let opts ?latency_hint ?sample_rate_hz () =
      let o = Jv.obj [||] in
      let latency_hint = match latency_hint with
      | None -> None
      | Some (`Category c) -> Some (Jv.of_jstr c)
      | Some (`Secs s) -> Some (Jv.of_float s)
      in
      Jv.set_if_some o "latencyHint" latency_hint;
      Jv.Float.set_if_some o "sampleRate" sample_rate_hz;
      o

    type t = Jv.t
    external as_target : t -> Ev.target = "%identity"
    external as_base : t -> Base.t = "%identity"

    let create ?(opts = Jv.undefined) () =
      Jv.new' (Jv.get Jv.global "AudioContext") [| opts |]

    let base_latency c = Jv.Float.get c "baseLatency"
    let output_latency c = Jv.Float.get c "outputLatency"

    let get_output_timestamp c =
      Timestamp.of_jv @@ Jv.call c "getOutputTimestamp" [||]

    let resume c = Fut.of_promise ~ok:ignore @@ Jv.call c "resume" [||]
    let suspend c = Fut.of_promise ~ok:ignore @@ Jv.call c "suspend" [||]
    let close c = Fut.of_promise ~ok:ignore @@ Jv.call c "close" [||]

    (* Lets leave that out for now, node constructors allow to set params
       directly.

    let create_media_element_source c el =
      Node.Media_element_source.of_jv @@
      Jv.call c "createMediaElementSource" [| Brr_io.Media.El.to_jv el |]

    let create_media_stream_destination c =
      Node.Media_stream_destination.of_jv @@
      Jv.call c "createMediaStreamDestination" [||]

    let create_media_stream_source c s =
      Node.Media_stream_source.of_jv @@
      Jv.call c "createMediaStreamSource" [| Brr_io.Media.Stream.to_jv s |]

    let create_media_stream_track_source c t =
      Node.Media_stream_track_source.of_jv @@
      Jv.call c "createMediaStreamTrackSource" [| Brr_io.Media.Track.to_jv t |]
    *)

    (* Offline audio contexts *)

    module Offline = struct
      type opts = Jv.t
      let opts ~channel_count:cc ~length:l ~sample_rate_hz:r () =
        Jv.obj Jv.[| "numberOfChannels", of_int cc;
                     "length", of_int l;
                     "sampleRate", of_float r |]

      type t = Jv.t
      external as_target : t -> Ev.target = "%identity"
      external as_base : t -> Base.t = "%identity"
      let length c = Jv.Int.get c "length"
      let create opts =
        Jv.new' (Jv.get Jv.global "OfflineAudioContext") [| opts |]

      let start_rendering c =
        Fut.of_promise ~ok:Buffer.of_jv @@ Jv.call c "startRenderig" [||]

      let suspend c ~secs =
        Fut.of_promise ~ok:ignore @@ Jv.call c "suspend" Jv.[|of_float secs|]

      let resume c = Fut.of_promise ~ok:ignore @@ Jv.call c "resume" [||]
    end
  end
end
