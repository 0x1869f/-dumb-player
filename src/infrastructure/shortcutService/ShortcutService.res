type subscriber = Player | Playlist | FileLoader | BashInput | App
type functinalKey = AltKey | CtrlKey | ShiftKey | MetaKey


type functionalKeys = {
  altKey: bool,
  metaKey: bool,
  shiftKey: bool,
  ctrlKey: bool,
}

type condition = {
  ...functionalKeys,
  code: string,
}

type regexCondtion = {
  ...functionalKeys,
  code: RegExp.t,
}

type keyboardEvent = {
  ...functionalKeys,
  code: string,
  key: string,
}


type callbackPayload = {
  event: keyboardEvent,
  nativeEvent: Dom.keyboardEvent,
  isRepeated: bool,
  previousNumber: option<int>,
  previousEvent: option<keyboardEvent>
}

type rule = RegExpCondtion(regexCondtion) | Condition(condition)

type subscription = {
  callback: (callbackPayload) => unit,
  conditions: array<rule>
}

let buildEvent = (event: Dom.keyboardEvent): keyboardEvent => {
  {
    metaKey: Webapi.Dom.KeyboardEvent.metaKey(event),
    ctrlKey: Webapi.Dom.KeyboardEvent.ctrlKey(event),
    altKey: Webapi.Dom.KeyboardEvent.altKey(event),
    shiftKey: Webapi.Dom.KeyboardEvent.shiftKey(event),
    code: Webapi.Dom.KeyboardEvent.code(event),
    key: Webapi.Dom.KeyboardEvent.key(event),
  }
}


let subscribers: Map.t<subscriber, array<subscription>> = Map.make()
let activeSubscribers: Map.t<subscriber, array<subscription>> = Map.make()
let subscriberBackup: Map.t<subscriber, array<subscription>> = Map.make()
let subscriberLastEvent: Map.t<subscriber, keyboardEvent> = Map.make()

let previousEvent: ref<option<keyboardEvent>> = ref(None)
let enteredNumber: ref<option<string>> = ref(None)



let subscribe = (subscriber: subscriber, subscriptions: array<subscription>) => {
  subscribers -> Map.set(_, subscriber, subscriptions)
}

let unsubscribe = (subscriber: subscriber) => {
  subscribers -> Map.delete(subscriber)->ignore
}

let addActive = (subscriber: subscriber) => {
  switch subscribers -> Map.get(subscriber) {
    | Some(value) => activeSubscribers -> Map.set(subscriber, value)
    | _ => ()
  }
}

let deleteActive = (subscriber: subscriber) => {
  activeSubscribers -> Map.delete(subscriber) -> ignore
}

let backupActiveSubs = () => {
  activeSubscribers -> Map.entries -> Iterator.forEach(
    (value) => { switch value {
      | Some((key, v)) => subscriberBackup -> Map.set(key, v)
      | _ => ()
    }}
  )

  activeSubscribers -> Map.clear
}

let recoverActiveSubs = () => {
  subscriberBackup -> Map.entries -> Iterator.forEach(
    (value) => { switch value {
      | Some((key, v)) => activeSubscribers -> Map.set(key, v)
      | _ => ()
    }}
  )

  subscriberBackup -> Map.clear
}

let compareEvents = (
  event: keyboardEvent,
  previousEvent: keyboardEvent
): bool => {
  event == previousEvent
}

let compareFunctionalKeys = (
  functionalKeys: functionalKeys,
  event: keyboardEvent
) => {
  let eventKeys = {
    ctrlKey: event.ctrlKey,
    altKey: event.altKey,
    shiftKey: event.shiftKey,
    metaKey: event.metaKey
  }

  eventKeys == functionalKeys
}


let compareEventWithCondition = (
  condition: condition,
  event: keyboardEvent
): bool => {
  compareFunctionalKeys({
    altKey: condition.altKey,
    ctrlKey: condition.ctrlKey,
    shiftKey: condition.shiftKey,
    metaKey: condition.metaKey,
  }, event) &&
    condition.code === event.code
}

let compareWithRegexCondition = (
  condition: regexCondtion,
  event: keyboardEvent
): bool => {
  compareFunctionalKeys({
    altKey: condition.altKey,
    ctrlKey: condition.ctrlKey,
    shiftKey: condition.shiftKey,
    metaKey: condition.metaKey,
  }, event) &&
  condition.code -> RegExp.test(event.code)
}

let checkConditions = (conditions: array<rule>, event): bool => {
  conditions -> Array.some((condition) => {
    switch condition {
      | RegExpCondtion(value) => compareWithRegexCondition(value, event)
      | Condition(value) => compareEventWithCondition(value, event)
    }
  })
}

let makePayload = (subscriber: subscriber, event: keyboardEvent, nativeEvent: Dom.keyboardEvent) => {
  let previousEvent = subscriberLastEvent -> Map.get(subscriber)

  let isRepeated = switch previousEvent {
    | Some(value) => compareEvents(event, value)
    | _ => false
  }

  let previousNumber = switch enteredNumber.contents {
    | Some(value) => value -> Int.fromString(~radix=10)
    | None => None
  }

  {
    event,
    isRepeated,
    previousEvent,
    previousNumber,
    nativeEvent,
  }
}

let notify = (event: keyboardEvent, nativeEvent: Dom.keyboardEvent) => {
  let notifiedSubscribers: Set.t<subscriber> = Set.make()

  activeSubscribers -> Map.entries -> Iterator.forEach((subscriptions) => {
    if subscriptions -> Option.isSome {
      let (sub, items) = subscriptions -> Option.getExn

      items -> Array.forEach((subscription) => {
        let isEqual = checkConditions(subscription.conditions, event)

        if isEqual {
          notifiedSubscribers -> Set.add(sub)
          let payload = makePayload(sub, event, nativeEvent)

          subscription.callback(payload)
          subscriberLastEvent -> Map.set(sub, event)
        }

      })
    }
  })

  if notifiedSubscribers -> Set.size === 0 && event.code -> String.includes("Digit") {
    enteredNumber := switch enteredNumber.contents {
      | Some(value) => Some(value ++ event.key)
      | _ => Some(event.key)
    }
  }

  subscriberLastEvent -> Map.keys -> Iterator.forEach((sub) => {
    switch sub {
      | Some(value) => if !(notifiedSubscribers -> Set.has(value)) {
        subscriberLastEvent -> Map.delete(value) -> ignore
      }
      | _ => ()
    }
  })
}

let callback = (nativeEvent: Dom.keyboardEvent) => {
  let event= buildEvent(nativeEvent)
  notify(event, nativeEvent)
}

let init = () => {
  Webapi.Dom.document -> Webapi.Dom.Document.addKeyDownEventListener(
    callback,
  )
}

let stop = () => {
  Webapi.Dom.document -> Webapi.Dom.Document.removeKeyDownEventListener(
    callback,
  )
}

let key = (code: string, ~keys=[]: array<functinalKey>) => {
  let condition: condition = {
    code,
    ctrlKey: keys -> Array.includes(CtrlKey),
    altKey: keys -> Array.includes(AltKey),
    shiftKey: keys -> Array.includes(ShiftKey),
    metaKey: keys -> Array.includes(MetaKey)
  }

  Condition(condition)
}

let regex = (code: Re.t, ~keys=[]: array<functinalKey>) => {
  let condition: regexCondtion = {
    code,
    ctrlKey: keys -> Array.includes(CtrlKey),
    altKey: keys -> Array.includes(AltKey),
    shiftKey: keys -> Array.includes(ShiftKey),
    metaKey: keys -> Array.includes(MetaKey)
  }

  RegExpCondtion(condition)
}

