open Expr

type crule = (rterm list) * term list

let rule2crule (h, b) = ([h], b)

let crule2rules (h, b) =
  List.map (fun x -> (x, b)) h

let compose expr =
  let canUpdate = [] in
  List.map rule2crule expr.rules
  (* 存储view中哪些变量可以被更新 *)