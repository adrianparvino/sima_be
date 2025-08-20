open Melange_json.Primitives

type t = { task_id : int; email : string; finished_at : string }
[@@deriving of_json]
