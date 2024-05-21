@react.component
let make = (~url: option<string>, ~className: string) => {
  switch url {
    | Some(value) => <div className="flex content-center">
      <img className={className} alt="" src={value} />
    </div>
    | None => <div className={className}></div>
  }
}


