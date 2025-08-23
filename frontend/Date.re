type day = int;
type month = int;
type year = int;

type t = {
  day,
  month,
  year,
};

let day_in_week_of_date = (date: t) => {
  let {day: q, month, year} = date;

  let (month, year) =
    switch (month) {
    | 1 => (13, year - 1)
    | 2 => (14, year - 1)
    | month => (month, year)
    };

  let k = Int.rem(year, 100);
  let j = Int.div(year, 100);

  Int.rem(
    q
    + Int.div(13 * (month + 1) - 1, 5)
    + k
    + Int.div(k, 4)
    + Int.div(j, 4)
    + 5
    * j,
    7,
  );
};
