type t = string

let id = ref(1)

let getId = (): string => {
  let current = id.contents

  id := id.contents + 1

  current -> Int.toString
}

