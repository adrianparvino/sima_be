module Env : sig
  type t

  val get : t -> string -> string
  val getUnsafe : t -> string -> 'a
end

module Response : sig
  type t
  type options
end

module Workers_request : sig
  type t = {
    url : String.t;
    _method : String.t; [@mel.as "method"]
    headers : Headers.t;
  }

  external text : unit -> String.t Js.Promise.t = "text" [@@mel.send.pipe: t]
  external json : unit -> 'a Js.t Js.Promise.t = "json" [@@mel.send.pipe: t]
end

module Request : sig
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

module Route (_ : Handler) : sig
  val handle : Workers_request.t -> Env.t -> unit -> Response.t Js.Promise.t
end
