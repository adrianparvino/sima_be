external toUint8Array : string -> Js.Typed_array.Uint8Array.t = "toUint8Array"
[@@mel.module "js-base64"]

external decode : string -> string = "decode" [@@mel.module "js-base64"]
