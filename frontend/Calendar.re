let monthToString = month => {
  switch (month) {
  | 0 => "January"
  | 1 => "February"
  | 2 => "March"
  | 3 => "April"
  | 4 => "May"
  | 5 => "June"
  | 6 => "July"
  | 7 => "August"
  | 8 => "September"
  | 9 => "October"
  | 10 => "November"
  | 11 => "December"
  | _ => ""
  };
};

[@react.component]
let make = () => {
  let today = Js.Date.make();

  let startingDayOfMonth =
    Js.Date.makeWithYMD(
      ~year=Js.Date.getFullYear(today),
      ~month=Js.Date.getMonth(today),
      ~date=1.0,
    )
    |> Js.Date.getDay
    |> Int.of_float;

  let lastDay =
    Js.Date.makeWithYMD(
      ~year=Js.Date.getFullYear(today),
      ~month=Js.Date.getMonth(today) +. 1.0,
      ~date=0.0,
    )
    |> Js.Date.getDate
    |> Int.of_float;

  <div>
    <div className="text-center">
      {today
       |> Js.Date.getMonth
       |> Int.of_float
       |> monthToString
       |> React.string}
      {React.string(" ")}
      {today |> Js.Date.getFullYear |> Int.of_float |> React.int}
    </div>
    <div className="grid grid-cols-7 text-center">
      <span> {React.string("S")} </span>
      <span> {React.string("M")} </span>
      <span> {React.string("T")} </span>
      <span> {React.string("W")} </span>
      <span> {React.string("T")} </span>
      <span> {React.string("F")} </span>
      <span> {React.string("S")} </span>
    </div>
    <div className="grid grid-cols-7 text-center">
      {Array.init(startingDayOfMonth, i => <span key={i |> Int.to_string} />)
       |> React.array}
      {Array.init(lastDay, i =>
         <span key={i |> Int.to_string}> {React.int(i + 1)} </span>
       )
       |> React.array}
    </div>
  </div>;
};
