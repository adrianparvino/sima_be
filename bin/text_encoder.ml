type t
type encodeIntoResult = { read : int; written : int }

external make : unit -> t = "TextEncoder" [@@mel.new]

external encode : string -> Js.Typed_array.Uint8Array.t = "encode"
[@@mel.send.pipe: t]

external encodeInto : string -> Js.Typed_array.Uint8Array.t -> encodeIntoResult
  = "encodeInto"
[@@mel.send.pipe: t]
