open Expr
open Utils

let genDisjointCode expr =
  let script = ""
  in script

let genVerifyCode expr =
  let edb = extract_edb expr in
  let idb = extract_idb expr in
  genDisjointCode expr