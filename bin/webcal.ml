module JCal = struct
  type prop
  type recur

  type propPayload =
    | Binary of (string * string array)
    | Boolean of (string * bool array)
    | CalAddress of (string * string array)
    | Date of (string * string array)
    | DateTime of (string * string array)
    | Duration of (string * string array)
    | Float of (string * float array)
    | Period of (string * (string * string) array)
    | Recur of (string * recur array)
    | Text of (string * string array)
    | Time of (string * string array)
    | Uri of (string * string array)
    | UtcOffset of (string * string array)
    | Geo of (string * (float * float) array)
    | Unknown

  type t = JCal of (string * prop array * t array) [@@unboxed]

  external unsafeCast : 'a -> 'b = "%identity"

  external parse : string -> t = "parse"
  [@@mel.module "ical.js"] [@@mel.scope "default"]

  let unProp (prop : prop) =
    let name = unsafeCast prop |. Js.Array.unsafe_get 0 in
    let type_ = unsafeCast prop |. Js.Array.unsafe_get 2 in

    match (name, type_) with
    | "geo", "float" -> Geo (name, unsafeCast prop |. Js.Array.unsafe_get 3)
    | _, "binary" -> Binary (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "boolean" -> Boolean (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "cal-address" ->
        CalAddress (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "date" -> Date (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "date-time" ->
        DateTime (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "duration" ->
        Duration (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "float" -> Float (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "period" -> Period (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "recur" -> Recur (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "text" -> Text (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "time" -> Time (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "uri" -> Uri (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _, "utc-offset" ->
        UtcOffset (name, unsafeCast prop |. Js.Array.slice ~start:3)
    | _ -> Unknown
end

let rec extractVevents = function
  | JCal.JCal ("vevent", props, _) -> [| props |]
  | JCal.JCal (_, _, components) ->
      components |. Belt.Array.flatMap extractVevents

let propsToClass props =
  let uid = ref None in
  let summary = ref None in
  let dtstart = ref None in
  props
  |> Array.iter (fun prop ->
         match JCal.unProp prop with
         | JCal.Text ("uid", values) -> uid := Some values.(0)
         | JCal.Text ("summary", values) -> summary := Some values.(0)
         | JCal.DateTime ("dtstart", values) -> dtstart := Some values.(0)
         | _ -> ());
  match (!uid, !summary, !dtstart) with
  | Some uid, Some summary, Some dtstart -> Some (uid, summary, dtstart)
  | _ -> None

let fetch url =
  let open Cf_workers.Promise_utils.Bind in
  let* response = Fetch.fetch url in
  let+ text = response |> Fetch.Response.text in
  text |> JCal.parse |> extractVevents |. Belt.Array.map propsToClass
