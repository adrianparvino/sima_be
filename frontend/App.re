[@mel.scope ("import", "meta", "env")]
external backendUrl: string = "VITE_BACKEND_URL";

[@mel.scope ("import", "meta", "env")]
external googleClientId: string = "VITE_GOOGLE_CLIENT_ID";

module GoogleOAuthProvider = {
  [@mel.module "@react-oauth/google"] [@react.component]
  external make: (~clientId: string, ~children: React.element) => React.element =
    "GoogleOAuthProvider";
};

module RTF = {
  type t;
  type options = {
    localeMatcher: option(string),
    numberingSystem: option(string),
    style: option(string),
    numeric: option(string),
  };

  [@mel.scope "Intl"] [@mel.new]
  external make: unit => t = "RelativeTimeFormat";

  [@mel.scope "Intl"] [@mel.new]
  external makeWithLocale: option(string) => t = "RelativeTimeFormat";

  [@mel.scope "Intl"] [@mel.new]
  external makeWithLocaleAndOptions: (option(string), options) => t =
    "RelativeTimeFormat";

  [@mel.send] external format: (t, float, string) => string = "format";
};

module TaskInput = {
  [@react.component]
  let make = (~onSubmit: (~name: string, ~deadline: string) => unit) => {
    let (name, setName) = React.useReducer((_, newValue) => newValue, "");
    let (deadline, setDeadline) =
      React.useReducer((_, newValue) => newValue, "");

    <form
      onSubmit={event => {
        React.Event.Form.preventDefault(event);
        onSubmit(~name, ~deadline);
      }}
      className={
        "bg-white p-4 drop-shadow grid transition-[grid-template-rows]"
        ++ (
          if (name == "") {
            " grid-rows-[min-content_0fr]";
          } else {
            " grid-rows-[min-content_1fr]";
          }
        )
      }>
      <input
        placeholder="Task Title"
        value=name
        onChange={event => React.Event.Form.target(event)##value |> setName}
      />
      <div className="overflow-hidden">
        <div className="flex flex-row content-center mt-4 ">
          <div className="my-auto">
            {React.string("Deadline")}
            <input
              className="ml-2"
              type_="date"
              value=deadline
              onChange={event =>
                React.Event.Form.target(event)##value |> setDeadline
              }
            />
          </div>
          <button
            className="block ml-auto bg-primary p-2 font-bold text-white w-24"
            type_="submit">
            {React.string("Create")}
          </button>
        </div>
      </div>
    </form>;
  };
};

module Tasks = {
  open Melange_json.Primitives;

  module Raw = {
    [@deriving of_json]
    type task = {
      task_id: int,
      name: string,
      deadline: string,
      finished_at: option(string),
    };

    [@deriving of_json]
    type t = array(task);
  };

  type task = {
    task_id: int,
    name: string,
    deadline: Js.Date.t,
    finished_at: option(Js.Date.t),
  };

  type t = array(task);

  let of_json = str => {
    str
    ->Raw.of_json
    ->(
        Belt.Array.map(({task_id, name, deadline, finished_at}) =>
          {
            task_id,
            name,
            deadline: deadline ++ "T00:00:00+08:00" |> Js.Date.fromString,
            finished_at:
              finished_at
              |> Option.map(x => x ++ "T00:00:00+08:00" |> Js.Date.fromString),
          }
        )
      );
  };

  [@react.component]
  let make = (~task: task, ~onFinish: int => unit) => {
    <div className="grid grid-cols-[1fr_min-content] text-left items-center">
      <div> {React.string(task.name)} </div>
      <div className="row-span-2">
        <button
          className="block my-auto text-white bg-primary p-2 font-bold w-24 disabled:opacity-50"
          disabled={task.finished_at |> Option.is_some}
          onClick={_ => onFinish(task.task_id)}>
          {React.string("Finish")}
        </button>
      </div>
      <div className="text-gray-500">
        {let relativeTime = Js.Date.getTime(task.deadline) -. Js.Date.now();
         let days =
           (relativeTime +. 86400000.)
           /. 86400000.
           |> Js.Math.round
           |> Int.of_float;
         let relative =
           RTF.makeWithLocaleAndOptions(
             None,
             {
               localeMatcher: None,
               numberingSystem: None,
               style: Some("long"),
               numeric: Some("auto"),
             },
           )
           ->(RTF.format(Float.of_int(days), "day"));

         let deadline = task.deadline |> Js.Date.toDateString;

         switch (task.finished_at) {
         | Some(finished_at) =>
           <span title=deadline>
             {React.string(
                relative
                ++ " (Finished: "
                ++ (finished_at |> Js.Date.toDateString)
                ++ ")",
              )}
           </span>
         | None => <span title=deadline> {React.string(relative)} </span>
         }}
      </div>
    </div>;
  };
};

module Scores = {
  module Raw = {
    open Melange_json.Primitives;

    [@deriving of_json]
    type score = {
      email: string,
      score: int,
    };

    [@deriving of_json]
    type t = array(score);
  };

  type score = {
    email: string,
    score: int,
  };

  type t = array(score);

  let of_json = Raw.of_json;
};

module Leaderboard = {
  [@react.component]
  let make = () => {
    let credential = React.useContext(Authentication.Provider.themeContext);

    let (scores, setScores) =
      React.useReducer((_, newValue) => newValue, [||]);

    let fetchScores = () =>
      if (credential != "") {
        Js.Promise.(
          Fetch.(
            RequestInit.make(
              ~method_=Get,
              ~headers=
                HeadersInit.make({
                  "Content-Type": "application/json",
                  "Authorization": "Bearer " ++ credential,
                }),
              (),
            )
            |> fetchWithInit(backendUrl ++ "/scores")
          )
          |> then_(Fetch.Response.json)
          |> then_(x => {
               x |> Scores.of_json |> setScores;

               resolve();
             })
        )
        |> ignore;
      };

    React.useEffect0(() => {
      fetchScores();
      None;
    });

    <div className="flex flex-col p-8 space-y-8">
      <div className="text-center w-full text-gray-900 text-4xl font-bold">
        {React.string("Leaderboard")}
      </div>
      <table className="bg-white *:*:*:p-2">
        <thead>
          <tr>
            <th className="text-left"> {React.string("Email")} </th>
            <th className="text-left"> {React.string("Score")} </th>
          </tr>
        </thead>
        <tbody>
          {scores
           ->Belt.Array.map(score => {
               <tr key={score.email}>
                 <td className="text-left"> {React.string(score.email)} </td>
                 <td className="text-left"> {React.int(score.score)} </td>
               </tr>
             })
           ->React.array}
        </tbody>
      </table>
    </div>;
  };
};

module MainApp = {
  [@react.component]
  let make = () => {
    let credential = React.useContext(Authentication.Provider.themeContext);

    let (tasks, setTasks) =
      React.useReducer((_, newValue) => Some(newValue), None);

    let fetchTasks = () =>
      if (credential != "") {
        Js.Promise.(
          Fetch.(
            RequestInit.make(
              ~method_=Get,
              ~headers=
                HeadersInit.make({
                  "Content-Type": "application/json",
                  "Authorization": "Bearer " ++ credential,
                }),
              (),
            )
            |> fetchWithInit(backendUrl ++ "/")
          )
          |> then_(Fetch.Response.json)
          |> then_(x => {
               x |> Tasks.of_json |> setTasks;

               resolve();
             })
        )
        |> ignore;
      };

    let finish = task_id => {
      Js.Promise.(
        Fetch.(
          RequestInit.make(
            ~method_=Post,
            ~body=BodyInit.make("{}"),
            ~headers=
              HeadersInit.make({
                "Content-Type": "application/json",
                "Authorization": "Bearer " ++ credential,
              }),
            (),
          )
          |> fetchWithInit(
               backendUrl ++ "/" ++ (task_id |> Int.to_string) ++ "/finish",
             )
          |> then_(_ => {
               fetchTasks();
               resolve();
             })
        )
      )
      |> ignore;
    };

    React.useEffect1(
      () => {
        fetchTasks();
        None;
      },
      [|credential|],
    );

    <div className="flex flex-col w-screen h-screen md:flex-row">
      <div
        className="flex-1 flex flex-col h-full overflow-y-scroll items-center">
        <div className="text-6xl font-bold m-8">
          {React.string("Tasks")}
        </div>
        <div className="h-full md:max-w-3xl w-full md:space-y-4">
          <div
            className="w-full *:bg-white md:space-y-4 *:p-4 *:w-full *:drop-shadow">
            {tasks
             |> Option.value(~default=[||])
             |> Array.map(task => <Tasks task onFinish=finish />)
             |> React.array}
          </div>
        </div>
      </div>
      <div
        className="bg-[#ced5d4] w-screen md:max-w-md flex flex-col p-8 space-y-8">
        <Leaderboard />
      </div>
    </div>;
  };
};

[@react.component]
let make = () => {
  <GoogleOAuthProvider clientId=googleClientId>
    <Authentication> <MainApp /> </Authentication>
  </GoogleOAuthProvider>;
};
