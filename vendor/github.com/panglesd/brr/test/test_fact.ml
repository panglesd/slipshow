(*---------------------------------------------------------------------------
   Copyright (c) 2024 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

let rec fact n = if n <= 0 then 1 else n * fact (n - 1)
let fact' n = Jv.of_int (fact (Jv.to_int n))
let () = Jv.set Jv.global "fact" (Jv.callback ~arity:1 fact')
