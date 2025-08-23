module Provider = {
  let themeContext = React.createContext("");

  include React.Context;
  let make = React.Context.provider(themeContext);
};

type successResponse = {credential: string};

module PromptMomentNotification = {
  type t =
    | Displayed
    | NotDisplayed(string)
    | Skipped(string)
    | Dismissed(string);
  type raw;

  [@mel.send]
  external getNotDisplayedReason: raw => string = "getNotDisplayedReason";

  [@mel.send] external getMomentType: raw => string = "getMomentType";
};

[@deriving jsProperties]
type args = {
  onSuccess: successResponse => unit,
  [@mel.optional]
  onError: option(unit => unit),
  [@mel.optional]
  hosted_domain: option(string),
  [@mel.optional]
  auto_select: option(bool),
  [@mel.optional]
  use_fedcm_for_prompt: option(bool),
  [@mel.optional]
  promptMomentNotification: option(PromptMomentNotification.raw => unit),
};

[@mel.module "@react-oauth/google"]
external useGoogleOneTapLogin: args => unit = "useGoogleOneTapLogin";

module GoogleLogin = {
  [@react.component] [@mel.module "@react-oauth/google"]
  external make:
    (
      ~onSuccess: successResponse => unit,
      ~hosted_domain: string=?,
      ~auto_select: bool=?,
      ~use_fedcm_for_prompt: bool=?,
      ~promptMomentNotification: PromptMomentNotification.raw => unit=?,
      ~useOneTap: bool=?,
      unit
    ) =>
    React.element =
    "GoogleLogin";
};

[@react.component]
let make = (~children: React.element) => {
  let (credential, setCredential) =
    React.useReducer((_, newValue) => newValue, "");
  // let (reason, setReason) = React.useReducer((_, newValue) => newValue, "");

  // Js.Console.log({
  //   "credential": credential,
  //   "reason": reason,
  // });

  <Provider value=credential>
    {credential != ""
       ? children
       : <div
           className="flex flex-col justify-center items-center h-full w-full">
           <GoogleLogin
             onSuccess={credential => {setCredential(credential.credential)}}
             hosted_domain="up.edu.ph"
             auto_select=true
             use_fedcm_for_prompt=false
             useOneTap=true
           />
         </div>}
  </Provider>;
};
