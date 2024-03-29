type t
type bound_prepared_statement
type prepared_statement
type 'a results = { results : 'a }

external run : bound_prepared_statement -> 'a results Js.Promise.t = "run"
[@@mel.send]

external bind : prepared_statement -> 'a array -> bound_prepared_statement
  = "bind"
[@@mel.send] [@@mel.variadic]

external prepare : t -> string -> prepared_statement = "prepare" [@@mel.send]

let make env = Workers.Env.getUnsafe env "DB"
