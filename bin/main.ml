let default =
  let open Jsoo_hello.Workers.Route (struct
    module Response = struct
      type t = Tasks of Task.t array | Scores of Score.t array | Empty

      let render = function
        | Tasks tasks -> Js.Json.stringifyAny tasks |> Option.get
        | Scores scores -> Js.Json.stringifyAny scores |> Option.get
        | _ -> "{}"
    end

    let list env email =
      let open Jsoo_hello.Promise_utils.Bind in
      let d1 = Jsoo_hello.D1.make env in

      let+ tasks = Task.list d1 email in
      Response.Tasks tasks

    let list_scores env =
      let open Jsoo_hello.Promise_utils.Bind in
      let d1 = Jsoo_hello.D1.make env in

      let+ scores = Score.list d1 in
      Response.Scores scores

    let add env task =
      let open Jsoo_hello.Promise_utils.Bind in
      let d1 = Jsoo_hello.D1.make env in

      let+ _ = Task.add d1 task in
      Response.Empty

    let finish env email task_id =
      let open Jsoo_hello.Promise_utils.Bind in
      let d1 = Jsoo_hello.D1.make env in

      let+ _ = Task.finish d1 email task_id in
      Response.Empty

    let handle_ env headers req =
      let open Jsoo_hello.Promise_utils.Bind in
      let open Jsoo_hello.Workers.Request in
      let bearer =
        headers
        |> Jsoo_hello.Headers.get "authorization"
        |> Js.Null.getExn |> Js.String.split ~sep:" "
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
      match req with
      | Get { path = [| "/" |]; _ } ->
          let email =
            verified |. Js.Dict.get "email" |> Option.get
            |> Js.Json.decodeString |> Option.get
          in
          list env email
      | Get { path = [| "/scores" |]; _ } -> list_scores env
      | Post { path = [| "/add" |]; body; _ } ->
          let task = body |> Js.Json.parseExn |> Task.create_payload_of_json in
          add env task
      | Post { path = [| task_id; "/finish" |]; _ } ->
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

    let handle env headers req =
      let open Jsoo_hello.Workers.Request in
      match req with
      | Options { path = _ } -> Response.Empty |> Js.Promise.resolve
      | _ -> handle_ env headers req
  end) in
  [%mel.obj { fetch = (fun [@u] request env ctx -> handle request env ctx) }]
