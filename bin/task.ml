open Ppx_deriving_json_runtime.Primitives

type hide = Hide : 'a -> hide [@@unboxed]

type t = {
  task_id : int;
  name : string;
  deadline : string;
  finished_at : string option;
}
[@@warning "-69"] [@@deriving of_json]

type create_payload = { name : string; deadline : string } [@@deriving of_json]

let list d1 email : t array Js.Promise.t =
  let open Jsoo_hello.D1 in
  let open Jsoo_hello.Promise_utils.Bind in
  let+ tasks =
    d1
    |. prepare
         {|
         SELECT Tasks.*, Progress.finished_at FROM Tasks 
         LEFT JOIN Progress
         ON Tasks.task_id = Progress.task_id AND Progress.email = ? 
         ORDER BY Progress.finished_at ASC NULLS FIRST, Tasks.deadline ASC
         |}
    |. bind [| email |] |. run
  in
  tasks.results

let add d1 task =
  let open Jsoo_hello.D1 in
  let prepared_statement =
    d1 |. prepare {|INSERT INTO Tasks (name, deadline) VALUES (?, ?)|}
  in
  let bound_prepared_statement =
    prepared_statement |. bind [| task.name; task.deadline |]
  in
  bound_prepared_statement |. run

let finish d1 email task_id =
  let open Jsoo_hello.D1 in
  let prepared_statement =
    d1
    |. prepare
         {|INSERT INTO Progress (task_id, email, finished_at) VALUES (?, ?, STRFTIME("%F", "now"))|}
  in
  Js.Console.log [| Hide task_id; Hide email |];
  let bound_prepared_statement =
    prepared_statement |. bind [| Hide task_id; Hide email |]
  in
  bound_prepared_statement |. run
