module State : sig
  module EditorStateConfig : sig
    type t

    include Jv.CONV with type t := t
    (* TODO: Add selection *)

    val undefined : t
  end

  module EditorState : sig
    type t

    include Jv.CONV with type t := t
  end

  module Text : sig
    type t

    include Jv.CONV with type t := t
  end

  module EditorSelection : sig
    type t

    include Jv.CONV with type t := t
  end

  module Transaction : sig
    type t

    include Jv.CONV with type t := t
  end

  module StateEffect : sig
    type 'a t

    include Tjv.CONV with type 'a t := 'a t
  end

  module StateField : sig
    type 'a t

    include Tjv.CONV with type 'a t := 'a t

    val extension : 'a t -> Extension.t
  end

  module Facet : sig
    type ('input, 'output) t

    val to_jv : ('input, 'output) t -> Jv.t
    val to_conv : ('input, 'output) t -> 'input Tjv.conv
    val create : 'input Tjv.conv -> Jv.t -> ('input, 'output) t
  end

  module ChangeSet : sig
    type t

    include Jv.CONV with type t := t
  end
end

module View : sig
  module EditorView : sig
    type t

    include Jv.CONV with type t := t
  end
end
