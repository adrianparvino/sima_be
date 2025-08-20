open Melange_json.Primitives

type jwk = {
  alg : string;
  use : string;
  n : string;
  kid : string;
  kty : string;
  e : string;
}
[@@deriving of_json]

type response = { keys : jwk array } [@@deriving of_json]

module SubtleCrypto = struct
  type algorithm
  type key = { algorithm : algorithm }
  type key_data = Jwk of jwk

  external importKeyJwk_ :
    (_[@mel.as "jwk"]) ->
    jwk ->
    'a Js.t ->
    bool ->
    string array ->
    key Js.Promise.t = "importKey"
  [@@mel.scope "crypto", "subtle"]

  external verify_ :
    algorithm ->
    key ->
    Js.Typed_array.Uint8Array.t ->
    Js.Typed_array.Uint8Array.t ->
    bool Js.Promise.t = "verify"
  [@@mel.scope "crypto", "subtle"]

  let verify key signed signature = verify_ key.algorithm key signed signature

  let importKey (Jwk jwk) extractable keyUsages =
    let algo =
      match jwk.alg with
      | "RS256" ->
          [%mel.obj
            {
              name = "RSASSA-PKCS1-v1_5";
              hash = [%mel.obj { name = "SHA-256" }];
            }]
      | _ -> failwith "Unsupported algorithm"
    in
    importKeyJwk_ jwk algo extractable keyUsages
end
