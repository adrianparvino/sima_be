open Melange_json.Primitives

module Unsafe = struct
  external get : 'a Js.t -> string -> 'b option = "" [@@mel.get_index]
end

type t = string
type header = { alg : string; kid : string; typ : string } [@@deriving of_json]

let verify jwt keys claims =
  let open Cf_workers.Promise_utils.Bind in
  let header, payload, signature =
    match Js.String.split ~sep:"." jwt with
    | [| header; payload; signature |] -> (header, payload, signature)
    | _ -> failwith "Invalid bearer token"
  in
  let signed =
    Js.Array.join ~sep:"." [| header; payload |]
    |. Text_encoder.encode (Text_encoder.make ())
  in
  let header = header |> Base64.decode |> Js.Json.parseExn |> header_of_json in
  let payload =
    payload |> Base64.decode |> Js.Json.parseExn |> Js.Json.decodeObject
    |> Option.get
  in
  let signature = signature |> Base64.toUint8Array in
  let key_data =
    Verify.SubtleCrypto.Jwk
      (keys
      |> Array.find_opt (fun (k : Verify.jwk) -> k.kid = header.kid)
      |> Option.get)
  in
  let* key = Verify.SubtleCrypto.importKey key_data true [| "verify" |] in
  let+ verified = Verify.SubtleCrypto.verify key signature signed in
  if not verified then failwith "Invalid signature";
  let invalid_claims =
    Js.Obj.keys claims
    |> Array.exists (fun k -> Js.Dict.get payload k != Unsafe.get claims k)
  in
  if invalid_claims then failwith "Invalid claims";
  payload
