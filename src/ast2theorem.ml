open Expr

type lean_type =
  | LeanBaseType of stype
  | LeanFuncType of lean_type * lean_type

type lean_theorem =
  | LeanTheorem of {
      name      : string;
      parameter : (string * lean_type) list;
      statement : Fol_ex.lean_formula;
    }

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

let lean_simp_theorem_of_disjoint_delta (debug : bool) (prog : expr) : lean_theorem =
  if debug then (print_endline "==> generating theorem for disjoint deltas";) else ();
  let statement =
    Fol_ex.lean_formula_of_fol_formula
      (Imp (Ast2fol.constraint_sentence_of_stt debug prog,
        (Imp (Ast2fol.disjoint_delta_sentence_of_stt debug prog, False))))
  in
  LeanTheorem {
    name      = "disjoint_deltas";
    parameter = source_view_to_lean_func_types prog;
    statement = statement;
  }