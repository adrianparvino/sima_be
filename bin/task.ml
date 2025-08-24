open Melange_json.Primitives

type t = {
  task_id : int;
  name : string;
  deadline : string;
  finished_at : string option;
}
[@@deriving of_json]

type create_payload = {
  name : string;
  deadline : string;
  ext_id : string option;
}

module Repository = struct
  let list d1 email : t array Js.Promise.t =
    let open Cf_workers.D1 in
    let open Cf_workers.Promise_utils.Bind in
    let+ tasks =
      d1
      |. prepare
           {|
         SELECT active_tasks.*, Progress.finished_at FROM active_tasks 
         LEFT JOIN Progress
         ON active_tasks.task_id = Progress.task_id AND Progress.email = ? 
         ORDER BY Progress.finished_at ASC NULLS FIRST, active_tasks.deadline ASC
         |}
      |. bind Bind.[| string email |]
      |. run
    in
    tasks.results

  let add d1 tasks =
    let open Cf_workers.D1 in
    let prepared_statement =
      d1
      |. prepare
           {|INSERT INTO tasks (name, deadline, ext_id) VALUES (?, ?, ?)
           ON CONFLICT (ext_id) DO UPDATE SET name = excluded.name, deadline = excluded.deadline|}
    in
    let bound_prepared_statements =
      tasks
      |> Array.map @@ fun task ->
         prepared_statement
         |. bind
              Bind.
                [|
                  string task.name;
                  string task.deadline;
                  null string task.ext_id;
                |]
    in
    d1 |. batch bound_prepared_statements

  let finish d1 email task_id =
    let open Cf_workers.D1 in
    let prepared_statement =
      d1
      |. prepare
           {|INSERT INTO Progress (task_id, email, finished_at) VALUES (?, ?, STRFTIME("%F", "now"))|}
    in
    let bound_prepared_statement =
      prepared_statement
      |. bind Bind.[| number @@ int_of_string task_id; string email |]
    in
    bound_prepared_statement |. run
end

module Controller = struct
  let list (env : Cf_workers.Workers.Env.t) email =
    let open Cf_workers.Promise_utils.Bind in
    let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

    let+ tasks = Repository.list d1 email in
    Js.Json.stringifyAny tasks |> Option.get

  let finish (env : Cf_workers.Workers.Env.t) email task_id =
    let open Cf_workers.Promise_utils.Bind in
    let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

    let+ _ = Repository.finish d1 email task_id in
    ""
end
