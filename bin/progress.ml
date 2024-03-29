open Ppx_deriving_json_runtime.Primitives

type t = { task_id : int; email : string; finished_at : string }
[@@deriving of_json]
