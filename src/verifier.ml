open Expr
open Utils
open Ast2theorem

let genDisjointCode expr =
  let lt = lean_simp_theorem_of_disjoint_delta false expr in
  let script = gen_lean_code_for_theorems [lt]
  in script

let genInjectiveCode expr =
  let lt = lean_simp_theorem_of_injectivity false expr in
  let script = gen_lean_code_for_theorems [lt]
  in script

let genVerifyCode expr =
  let edb = extract_edb expr in
  let idb = extract_idb expr in
  genInjectiveCode expr