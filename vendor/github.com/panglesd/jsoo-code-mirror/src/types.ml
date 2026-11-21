module State = struct
  module EditorState = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end

  module EditorStateConfig = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)

    let undefined : t = Jv.undefined
  end

  module Text = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end

  module EditorSelection = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end

  module ChangeDesc = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end

  module StateEffect = struct
    type 'a t = 'a Tjv.t

    include (Tjv.Id : Tjv.CONV with type 'a t := 'a t)
  end

  module StateField = struct
    type 'a t = 'a Tjv.t

    include (Tjv.Id : Tjv.CONV with type 'a t := 'a t)

    let extension v = Extension.of_jv (to_jv v)
  end

  module Facet = struct
    type ('input, 'output) t = 'input Tjv.t

    let to_jv v = Tjv.Id.to_jv v
    let create = Tjv.Id.of_jv
    let to_conv = Tjv.Id.conv
  end

  module Transaction = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end

  module ChangeSet = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end
end

module View = struct
  module EditorView = struct
    type t = Jv.t

    include (Jv.Id : Jv.CONV with type t := t)
  end
end
