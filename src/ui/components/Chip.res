@react.component
let make = (~value: string, ~className: string="") => {
  let style = `rounded h-10 px-2 flex items-center justify-content-center
    tracking-[.25em] ${className}`

  <div className={style}>
    {React.string(value)}
  </div>
}

