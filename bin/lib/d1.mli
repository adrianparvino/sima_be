type t
type bound_prepared_statement
type prepared_statement
type 'a results = { results : 'a }

val run : bound_prepared_statement -> 'a results Js.Promise.t
val bind : prepared_statement -> 'a array -> bound_prepared_statement
val prepare : t -> string -> prepared_statement
val make : Workers.Env.t -> t
