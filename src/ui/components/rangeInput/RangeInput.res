%%raw("import './RangeInput.css'")

@react.component
let make = (
  ~onChange: (~e: float) => unit,
  ~value: float,
  ~min: float,
  ~max: float,
  ~step: float,
  ~className: string,
) => {
  <input
    className={className}
    value={value -> Float.toString}
    onChange={(e: ReactEvent.Form.t) => onChange(~e=ReactEvent.Form.target(e)["value"] -> Float.fromString -> Option.getUnsafe)}
    type_="range"
    step={step}
    max={max -> Float.toString}
    min={min -> Float.toString}
  />
}

