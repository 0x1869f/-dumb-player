type state = {
  value: string,
  isShown: bool,
  history: array<string>,
}

type action = Clear | Show | Hide | SetValue(string) | AddToHistory(string)

let reducer = (state, action) => {
  switch action {
    | Clear => {...state, value: ""}
    | Show => {...state, isShown: true}
    | Hide => {...state, isShown: false}
    | SetValue(value) => {...state, value}
    | AddToHistory(value) => {...state, history: [...state.history, value]}
  }
}

let initialState: state = {
    value: "",
    isShown: false,
    history: []
}

