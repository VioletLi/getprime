open Expr
open Utils

type lean_type =
  | LeanBaseType of stype
  | LeanFuncType of lean_type * lean_type

type lean_theorem =
  | LeanTheorem of {
      name      : string;
      parameter : (string * lean_type) list;
      statement : Fol_ex.lean_formula;
    }

let stype_to_lean_type st = match st with
  (* | Sint -> "ℤ" *)
  | Sint -> "int"
  (* | Sreal -> "ℝ" *)
  (* | Sreal -> "real" *)
  | Sreal -> "rat"
  | Sbool -> "Prop"
  | Sstring -> "string"

let stringify_lean_type (ltyp : lean_type) : string =
  let rec aux (ltyp : lean_type) : string =
    match ltyp with
    | LeanBaseType styp           -> stype_to_lean_type styp
    | LeanFuncType (ltyp1, ltyp2) -> Printf.sprintf "(%s → %s)" (aux ltyp1) (aux ltyp2)
  in
  aux ltyp

let stringify_lean_theorem (thm : lean_theorem) : string =
  let LeanTheorem { name; parameter; statement } = thm in
  let s_parameter =
    parameter |> List.map (fun (x, ltyp) ->
      Printf.sprintf " {%s: %s}" x (stringify_lean_type ltyp)
    ) |> String.concat ""
  in
  let s_statement = Fol_ex.stringify_lean_formula statement in
  Printf.sprintf "theorem %s%s: %s" name s_parameter s_statement

let gen_lean_code_for_theorems (thms : lean_theorem list) : string =
  "import bx

local attribute [instance] classical.prop_decidable

" ^ String.concat "\n\n" (List.map (fun thm -> (stringify_lean_theorem thm) ^ ":=
  begin
  z3_smt
  end") thms)

let source_view_to_lean_func_types (prog : expr) : (string * lean_type) list =
  (* currently just set all the types are int (ℤ) *)
  let p_el (funcs : (string * lean_type) list) ((name, lst) : source) =
    let ltyp =
      List.fold_right (fun (_col, styp) ltyp -> LeanFuncType (LeanBaseType styp, ltyp)) lst (LeanBaseType Sbool)
    in
    (name, ltyp) :: funcs
  in
  List.fold_left p_el [] (get_schema_stts prog)

let make_lean_theorem (name : string) (parameter : (string * lean_type) list) (statement : Fol_ex.lean_formula) : lean_theorem =
  LeanTheorem { name; parameter; statement }

let genDeltaRelation srcs =
  List.concat (List.map (fun (name, attrs) -> [(name ^ "_ins", attrs);(name ^ "_del", attrs)]) srcs)

let genDeltaConstraints srcs =
  List.concat (List.map (fun (name, attrs) -> 
    [ (get_empty_pred, [Rel (source2RTerm (name ^ "_ins", attrs)); Rel (source2RTerm (name ^ "_del", attrs))])
    ; (get_empty_pred, [Rel (source2RTerm (name ^ "_ins", attrs)); Rel (source2RTerm (name, attrs))])
    ; (get_empty_pred, [Rel (source2RTerm (name ^ "_del", attrs)); Not (source2RTerm (name, attrs))])
    ]
  ) srcs)
  (* _|_ :- s_ins(X), s_del(X). *)
  (* _|_ :- s_ins(X), s(X). *)
  (* _|_ :- s_del(X), not s(X). *)

let replaceSDelta rules =
  List.map (fun (head, body) ->
    (head, List.map (fun t ->
      match t with
        | Rel r -> 
            begin
              match r with
                | Deltainsert (sn, varlist) -> Rel (Pred (sn^"_ins", varlist))
                | Deltadelete (sn, varlist) -> Rel (Pred (sn^"_del", varlist))
                | Pred (sn, varlist)        -> t
            end
        | Not r ->
          begin
            match r with
              | Deltainsert (sn, varlist) -> Not (Pred (sn^"_ins", varlist))
              | Deltadelete (sn, varlist) -> Not (Pred (sn^"_del", varlist))
              | Pred (sn, varlist)        -> t
          end
        | _ -> t
    ) body)
  ) rules

let genGetDelta expr =
  let deltaRelation = genDeltaRelation expr.sources in
  let deltaConstraints = genDeltaConstraints expr.sources in
  { expr with 
    sources = expr.sources @ deltaRelation;
    constraints = expr.constraints @ deltaConstraints;
    rules = replaceSDelta expr.rules
  }

let lean_simp_theorem_of_disjoint_delta (debug : bool) (prog : expr) : lean_theorem =
  if debug then (print_endline "==> generating theorem for disjoint deltas";) else ();
  let newprog = constraint2rule (genGetDelta prog) in
  (* print_string (to_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        (Imp (Ast2fol.disjoint_delta_sentence_of_stt debug newprog, False))))
  in
  LeanTheorem {
    name      = "disjoint_deltas";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }

let lean_simp_theorem_of_injectivity (debug : bool) (prog : expr) : lean_theorem =
  if debug then (print_endline "==> generating theorem for injectivity";) else ();
  let newprog = constraint2rule (genGetDelta prog) in
  (* print_string (to_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        (Imp (Ast2fol.injectivity_sentence_of_stt debug newprog, False))))
  in
  LeanTheorem {
    name      = "injectivity";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }

let lean_simp_theorem_of_fusable (debug : bool) (prog : expr) (queryRTerm1 : rterm) (queryRTerm2 : rterm) : lean_theorem =
  if debug then (print_endline "==> generating theorem for fusable";) else ();
  let sourcePrime = List.map (fun (n, attrs) -> (n ^ "_prime", attrs)) prog.sources in
  let deltaRelation = genDeltaRelation sourcePrime in
  let deltaConstraints = genDeltaConstraints sourcePrime in
  let temp = genGetDelta prog in
  let tmp = { temp with
    sources = temp.sources @ deltaRelation;
    constraints = temp.constraints @ deltaConstraints
  } in
  let newprog = constraint2rule tmp in
  (* print_string (to_birds_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        Ast2fol.fusable_sentence_of_stt debug newprog queryRTerm1 queryRTerm2))
  in
  LeanTheorem {
    name      = "fusable";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }

let lean_simp_theorem_of_empty (debug : bool) (prog : expr) (queryRTerm : rterm) : lean_theorem =
  if debug then (print_endline "==> generating theorem for empty testing";) else ();
  let newprog = constraint2rule (genGetDelta prog) in
  (* print_string (to_birds_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        (Imp (Ast2fol.empty_sentence_of_stt debug newprog queryRTerm, False))))
  in
  LeanTheorem {
    name      = "emptyTesting";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }

let lean_simp_theorem_of_contradictory (debug : bool) (prog : expr) (contradictoryRTerm : rterm) : lean_theorem =
  if debug then (print_endline "==> generating theorem for contradictory testing";) else ();
  let newprog = constraint2rule prog in
  (* print_string (to_birds_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        (Imp (Ast2fol.contradictory_sentence_of_stt debug newprog contradictoryRTerm, False))))
  in
  LeanTheorem {
    name      = "contradictoryTesting";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }

let lean_simp_theorem_of_valbinding (debug : bool) (prog : expr) (valBindingRTerm : rterm) : lean_theorem =
  if debug then (print_endline "==> generating theorem for valBinding testing";) else ();
  (* print_string (to_birds_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.valbinding_sentence_of_stt debug prog valBindingRTerm, False))
  in
  LeanTheorem {
    name      = "valBindingTesting";
    parameter = [];
    statement = statement;
  }

(* let lean_simp_theorem_of_reachability (debug : bool) (prog : expr) : lean_theorem =
  if debug then (print_endline "==> generating theorem for injectivity";) else ();
  let newprog = constraint2rule (genGetDelta prog) in
  (* print_string (to_string newprog); *)
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug newprog,
        (Imp (Ast2fol.reachability_sentence_of_stt debug newprog, False))))
  in
  LeanTheorem {
    name      = "reachability";
    parameter = source_view_to_lean_func_types newprog;
    statement = statement;
  }   *)
