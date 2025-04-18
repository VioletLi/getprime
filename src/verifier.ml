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

let genValBindingCode expr valBindingRTerm = 
  let lt = lean_simp_theorem_of_valbinding false expr valBindingRTerm in
  let script = gen_lean_code_for_theorems [lt]
  in script

let genContradictoryCode expr contradictoryRTerm =
  let lt = lean_simp_theorem_of_contradictory false expr contradictoryRTerm in
  let script = gen_lean_code_for_theorems [lt]
  in script

let genFusableCode expr queryRTerm1 queryRTerm2 =
  let lt = lean_simp_theorem_of_fusable false expr queryRTerm1 queryRTerm2 in
  let script = gen_lean_code_for_theorems [lt]
  in script

let genTestEmptyCode expr queryRTerm =
  let lt = lean_simp_theorem_of_empty false expr queryRTerm in
  let script = gen_lean_code_for_theorems [lt]
  in script

(* let genReachableCode expr =
  let lt = lean_simp_theorem_of_reachability false expr in
  let script = gen_lean_code_for_theorems [lt]
  in script *)