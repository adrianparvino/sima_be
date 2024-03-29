module Response = struct
  type t = int

  let render x = string_of_int x
end

let handle _ _ _ = Js.Promise.resolve 1
