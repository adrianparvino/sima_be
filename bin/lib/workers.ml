module Env = struct
  type t

  external getUnsafe : t -> string -> 'a = "" [@@mel.get_index]

  let get = getUnsafe
end

module Request = struct
  type t =
    | Get of { path : string array }
    | Post of { path : string array; body : string }
    | Options of { path : string array }
end

module type Handler = sig
  module Response : sig
    type t

    val render : t -> Js.String.t
  end

  val handle : Env.t -> Headers.t -> Request.t -> Response.t Js.Promise.t
end

module Response = struct
  type t
  type options = { headers : Headers.t } [@@warning "-69"]

  external make : 'a -> options -> t = "Response" [@@mel.new]

  let create env response =
    let headers = Headers.empty () in
    headers |> Headers.set "content-type" "application/json";
    headers |> Headers.set "access-control-allow-origin" (Env.get env "ORIGIN");
    headers |> Headers.set "access-control-allow-credentials" "true";
    headers |> Headers.set "access-control-allow-headers" "*";
    headers |> Headers.set "access-control-allow-methods" "*";
    make response { headers }
end

module Workers_request = struct
  type t = {
    url : String.t;
    _method : String.t; [@mel.as "method"]
    headers : Headers.t;
  }

  external text : unit -> String.t Js.Promise.t = "text" [@@mel.send.pipe: t]
  external json : unit -> 'a Js.t Js.Promise.t = "json" [@@mel.send.pipe: t]
end

module URL = struct
  type t = { pathname : string }

  external make : string -> t = "URL" [@@mel.new]
end

module Route (Handler : Handler) = struct
  let handle (request : Workers_request.t) env _ctx =
    let open Promise_utils.Bind in
    let headers = request.headers in
    let path =
      (URL.make request.url).pathname
      |> Js.String.match_ ~regexp:[%re "/\\/([^/]*)/g"]
      |> Option.get |> Array.map Option.get
    in

    let+ r =
      match (path, request._method) with
      | path, "GET" -> Get { path } |> Handler.handle env headers
      | path, "POST" ->
          let* body = request |> Workers_request.text () in
          Post { path; body } |> Handler.handle env headers
      | _, "OPTIONS" -> Options { path } |> Handler.handle env headers
      | _, _ -> failwith "method not supported"
    in

    r |> Handler.Response.render |> Response.create env
end
