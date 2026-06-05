type trigger = Save | Edit | Never

module Refresh = struct
  let on = ref Edit
  let when_ () = !on
  let set when_ = on := when_
end

module Compile = struct
  let on = ref Save
  let when_ () = !on
  let set when_ = on := when_
end
