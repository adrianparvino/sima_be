type t = { email : string; score : float }

let list d1 : t array Js.Promise.t =
  let open Jsoo_hello.D1 in
  let open Jsoo_hello.Promise_utils.Bind in
  let+ scores =
    d1
    |. prepare
         {|
          SELECT email, SUM((unixepoch(deadline) - unixepoch(finished_at)))/86400.0*5.0 AS score
          FROM progress
          INNER JOIN tasks USING (task_id)
          GROUP BY email
          ORDER BY score DESC
          |}
    |. bind [||] |. run
  in
  scores.results
