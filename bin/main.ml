module URL = struct
  type t = { pathname : string }

  external make : string -> t = "URL" [@@mel.new]
end

let default =
  let open Cf_workers.Workers.Make (struct
    module ControllerResponse = struct
      type t = Tasks of Task.t array | Scores of Score.t array | Empty

      let render = function
        | Tasks tasks -> Js.Json.stringifyAny tasks |> Option.get
        | Scores scores -> Js.Json.stringifyAny scores |> Option.get
        | _ -> "{}"
    end

    let default_headers _env =
      let headers = Cf_workers.Headers.empty () in
      (* if Cf_workers.Workers.Env.get env "DISABLE_CORS" = Some "true" then ( *)
      if true then (
        headers |> Cf_workers.Headers.set "access-control-allow-origin" "*";
        headers
        |> Cf_workers.Headers.set "access-control-allow-credentials" "true";
        headers |> Cf_workers.Headers.set "access-control-allow-headers" "*";
        headers |> Cf_workers.Headers.set "access-control-allow-methods" "*");
      headers

    let list (env : Cf_workers.Workers.Env.t) email =
      let open Cf_workers.Promise_utils.Bind in
      let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

      let+ tasks = Task.list d1 email in
      ControllerResponse.Tasks tasks

    let list_scores (env : Cf_workers.Workers.Env.t) =
      let open Cf_workers.Promise_utils.Bind in
      let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

      let+ scores = Score.list d1 in
      ControllerResponse.Scores scores

    let finish (env : Cf_workers.Workers.Env.t) email task_id =
      let open Cf_workers.Promise_utils.Bind in
      let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in

      let+ _ = Task.finish d1 email task_id in
      ControllerResponse.Empty

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
      let* jwk = Fetch.fetch "https://www.googleapis.com/oauth2/v3/certs" in
      let* jwk = jwk |> Fetch.Response.json in
      let jwk = jwk |> Verify.response_of_json in
      let* verified =
        Jwt.verify bearer jwk.keys [%mel.obj { hd = "up.edu.ph" }]
      in
      let path =
        (URL.make url).pathname
        |> Js.String.match_ ~regexp:[%re "/\\/([^/]*)/g"]
        |> Option.get |> Array.map Option.get
      in
      match (path, req) with
      | [| "/" |], Get ->
          let email =
            verified |. Js.Dict.get "email" |> Option.get
            |> Js.Json.decodeString |> Option.get
          in
          list env email
      | [| "/scores" |], Get -> list_scores env
      | [| task_id; "/finish" |], Post _ ->
          let email =
            verified |. Js.Dict.get "email" |> Option.get
            |> Js.Json.decodeString |> Option.get
          in
          let task_id =
            (task_id
            |> Js.String.match_ ~regexp:[%re "/\\/(\\d+)/"]
            |> Option.get).(1)
            |> Option.get |> int_of_string
          in
          finish env email task_id
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
          x |> ControllerResponse.render
          |> Cf_workers.Workers.Response.create ~headers:(default_headers env)
  end) in
  let open struct
    let scheduled (env : Cf_workers.Workers.Env.t) =
      let open Cf_workers.Promise_utils.Bind in
      let d1 = env |. Cf_workers.Workers.Env.getD1 "DB" |> Option.get in
      let url =
        env |. Cf_workers.Workers.Env.get "CALENDAR_URL" |> Option.get
      in
      let+ webcals = Webcal.fetch url in
      webcals |> Seq.filter_map Fun.id
      |> Seq.map (fun (ext_id, name, dtstart) ->
             let deadline =
               dtstart
               |> Js.String.replaceByRe ~regexp:[%re "/T.*/g"] ~replacement:""
             in
             Task.add d1 { name; deadline; ext_id = Some ext_id })
      |> Array.of_seq |> Js.Promise.all |> ignore;
      ()
  end in
  [%mel.obj
    {
      fetch = (fun [@u] request env ctx -> handle request env ctx);
      scheduled = (fun [@u] (_event : unit) env (_ctx : unit) -> scheduled env);
    }]
