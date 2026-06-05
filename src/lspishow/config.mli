type trigger = Save | Edit | Never

module Refresh : sig
  val when_ : unit -> trigger
  val set : trigger -> unit
end

module Compile : sig
  val when_ : unit -> trigger
  val set : trigger -> unit
end
