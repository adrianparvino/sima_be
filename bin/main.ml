module URL = struct
  type t = { pathname : string }

  external make : string -> t = "URL" [@@mel.new]
end

let scheduled (env : Cf_workers.Workers.Env.t) =
  let open Cf_workers.Promise_utils.Bind in
  let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in
  let url = env |. Cf_workers.Workers.Env.get "CALENDAR_URL" |> Option.get in
  let* webcals = Webcal.fetch url in
  let+ _ =
    webcals
    |. Belt.Array.flatMap (function
         | Some (ext_id, name, dtstart) ->
             let deadline =
               dtstart
               |> Js.String.replaceByRe ~regexp:[%re "/T.*/g"] ~replacement:""
             in
             Task.[| { name; deadline; ext_id = Some ext_id } |]
         | None -> [||])
    |> Task.Repository.add d1
  in
  ()

module Worker = Cf_workers.Workers.Make (struct
  module ControllerResponse = struct
    type t = Scores of Score.t array

    let render = function
      | Scores scores -> Js.Json.stringifyAny scores |> Option.get
  end

  let default_headers _env =
    let headers = Cf_workers.Headers.empty () in
    headers

  let list_scores (env : Cf_workers.Workers.Env.t) =
    let open Cf_workers.Promise_utils.Bind in
    let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

    let+ scores = Score.list d1 in
    ControllerResponse.Scores scores

  let handle_ headers env url req =
    let open Cf_workers.Promise_utils.Bind in
    let open Cf_workers.Workers.Request in
    let bearer =
      headers
      |> Cf_workers.Headers.get "authorization"
      |> Option.get |> Js.String.split ~sep:" "
      |> function
      | [| "Bearer"; token |] -> token
      | _ -> failwith "Invalid authorization header"
    in
    let google_client_id = Cf_workers.Workers.Env.get env "GOOGLE_CLIENT_ID" |> Option.get in
    let* jwk = Fetch.fetch "https://www.googleapis.com/oauth2/v3/certs" in
    let* jwk = jwk |> Fetch.Response.json in
    let jwk = jwk |> Verify.response_of_json in
    let* verified =
      Jwt.verify bearer jwk.keys [%mel.obj { hd = "up.edu.ph"; aud = google_client_id }]
    in
    let path =
      (URL.make url).pathname
      |> Js.String.match_ ~regexp:[%re "/\\/([^/]+)/g"]
      |> Option.get |> Array.map Option.get
    in
    match (path, req) with
    | [| "/api" |], Get ->
        let email =
          verified |. Js.Dict.get "email" |> Option.get |> Js.Json.decodeString
          |> Option.get
        in
        Task.Controller.list env email
    | [| "/api"; "/scores" |], Get ->
        let+ scores = list_scores env in
        ControllerResponse.render scores
    | [| "/api"; task_id; "/finish" |], Post _ ->
        let email =
          verified |. Js.Dict.get "email" |> Option.get |> Js.Json.decodeString
          |> Option.get
        in
        let task_id = task_id |> Js.String.slice ~start:1 in
        Task.Controller.finish env email task_id
    | _ -> failwith "Invalid path"

  let handle headers env url req =
    let open Cf_workers.Promise_utils.Bind in
    let open Cf_workers.Workers.Request in
    match req with
    | Options ->
        ""
        |> Cf_workers.Workers.Response.create ~headers:(default_headers env)
        |> Js.Promise.resolve
    | _ ->
        let+ x = handle_ headers env url req in
        x |> Cf_workers.Workers.Response.create ~headers:(default_headers env)
end)

let default =
  [%mel.obj
    {
      fetch = (fun [@u] request env ctx -> Worker.handle request env ctx);
      scheduled = (fun [@u] (_event : unit) env (_ctx : unit) -> scheduled env);
    }]
