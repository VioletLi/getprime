(*******************************************************)
(**
Functions to transform datalog ast to first-order logic formula and vice versa
 *)
(********************************************************)
(* This code is based on existing code and some functions are added:
functions to check injectivity;
functions to check reachability.
*)
(********************************************************)
(*
@origin author: Vandang Tran
@modifier: Guanchen Guo
*)


open Lib
open Formulas
open Fol
open Skolem
open Fol_ex
open Expr
open Utils
open Rule_preprocess
open Stratification
open Derivation


let lean_string_of_fol_formula (fm : fol formula) : string =
  stringify_lean_formula (lean_formula_of_fol_formula fm)


(** convert vterm into Fol.term *)
let rec folterm_of_vterm ae =
    match ae with
      Const c -> Fn (string_of_const c,[])
    | Var v -> Fol.Var (string_of_var v)
    | BinaryOp(op, f,g) -> Fn(op,[folterm_of_vterm f; folterm_of_vterm g])
    | UnaryOp (op,e) ->  Fn(op,[folterm_of_vterm e])
    (* | BoolAnd (f,g) -> Fn("and",[folterm_of_vterm f; folterm_of_vterm g])
    | BoolOr (f,g) -> Fn("or",[folterm_of_vterm f; folterm_of_vterm g])
    | BoolNot e ->  Fn("not",[folterm_of_vterm e]) *)


let const_of_string str =
    try  (Int (int_of_string str)) with
    (* try test () with *)
    | Failure e ->
        try  (Real (float_of_string str)) with
        (* try test () with *)
        | Failure e ->
            try  (Bool (bool_of_string str)) with
            (* try test () with *)
            | Failure e | Invalid_argument e -> if (str = "null") then  Null else  (String str)

(** convert Fol.term into vterm*)
let rec vterm_of_folterm ft =
    match ft with
      Fol.Var s -> (Var (NamedVar s))
    | Fol.Fn(c,[]) -> Const (const_of_string c)
    | Fol.Fn(op,[tm1;tm2]) -> (match op with
        "/" | "*" | "-" | "+" | "^" | "::" -> BinaryOp (op, vterm_of_folterm tm1, vterm_of_folterm tm2)
        | _ -> raise (SemErr ("unkown arithmetic operator " ^op)))
    | Fol.Fn("-",[tm1]) -> UnaryOp ("-", vterm_of_folterm tm1)
    | Fol.Fn(f,_) -> raise (SemErr ("unkown arithmetic operator " ^f))


(** For non-recursive datalog, we do not need stratification, we just need to recursively translate each idb predicate (identified symtkey) into a FO formula,
this function takes a symtkey of a rterm and generates its FO formula recursively (this function is recursive because of unfolding all the idb predicate)*)
let rec fol_of_symtkey (idb:symtable) (cnt:colnamtab) (goal:symtkey)  =
    let rule_lst = try Hashtbl.find idb goal
        with Not_found -> raise(SemErr( "Not_found in func fol_of_symtkey"))
        in
        (* print_string (string_of_symtkey goal); print_string ":\n";
        print_string (String.concat "\n" (List.map (string_of_rule) rule_lst)); *)
    (* disjunction of all rules then we have FO formula for a idb predicate*)
    let fol_of_rule_lst (idb:symtable) (cnt:colnamtab) rules =
        let fol_list = List.map (fol_of_rule idb cnt) rules in
        let fm = match fol_list with
            hd::bd -> if (List.length bd = 0) then hd else
                    List.fold_left (fun form e -> Formulas.Or(form, e)) hd bd
            | _ -> failwith "there is no rule for the idb relation" in
        fm in
    let fm = fol_of_rule_lst idb cnt rule_lst in
    fm
and fol_of_rule (idb:symtable) (cnt:colnamtab) rule =
    let head = rule_head rule in
    let body = rule_body rule in
    let (p_rt,n_rt,all_eqs,all_ineqs) = split_terms body in
    (* substitute variables of the head to column name of the prediate of the head *)
    let cols =
        try Hashtbl.find cnt (symtkey_of_rterm head)
        with Not_found -> raise(SemErr ("Not found in cnt the atom "^string_of_rterm head))
        in
    let varlst = get_rterm_varlist head in
    let subfn = fpf (List.map (fun x -> string_of_var x) varlst) (List.map (fun x -> Fol.Var x) cols) in

    (* existential vars of the body is vars in body but not in the head *)
    let exvars = VarSet.filter (fun x -> not (is_anon x)) (VarSet.diff (get_termlst_varset body) (VarSet.of_list (get_rterm_varlist head))) in
    let conjunction_lst =  (List.map (fun x ->  fol_of_rterm x idb cnt) p_rt)@(List.map (fun x ->  Formulas.Not(fol_of_rterm x idb cnt) ) n_rt)@ (List.map (fun x -> fol_of_eq x) all_eqs) @ (List.map (fun x -> fol_of_ineq x) all_ineqs) in
    let fm = match conjunction_lst with
        hd::bd -> if (List.length bd = 0) then hd else
            List.fold_left (fun form e -> Formulas.And(form, e)) hd bd
        | _ -> failwith "the body of rule contains nothing" in
    let fm2 = itlist mk_exists (List.map string_of_var (VarSet.elements exvars)) fm in
        subst subfn fm2
and fol_of_rterm r (idb:symtable) (cnt:colnamtab)=
    let cols =
        try Hashtbl.find cnt (symtkey_of_rterm r)
        with Not_found -> raise(SemErr ("Not found in cnt the atom "^string_of_rterm r))
        in
    let varlst = get_rterm_varlist r in
    let excols = List.fold_right2 (fun col var l -> if (is_anon var) then col::l else l) cols varlst [] in
    (* create substitution function convert anonymous variables to named variable with alias,
    they will be existential varialbes  *)
    let subfn = List.fold_right2 (fun col var l-> if (is_anon var) then l else (col |-> Fol.Var (string_of_var var)) l) cols varlst undefined in
    let fm = if Hashtbl.mem idb (symtkey_of_rterm r) then
    (* in the case that the predicate is of idb relation, need to recursive construct FO formula for it *)
    fol_of_symtkey idb cnt (symtkey_of_rterm r)
    else
    (* if this predicate is of an edb relation, just need to call by its name *)
    Atom(R(get_rterm_predname r, (List.map (fun x -> Fol.Var x) cols))) in
    let fm2 = itlist mk_exists excols fm in
    subst subfn fm2
and fol_or_eterm et = match et with
    Equation(op, exp1, exp2) -> Atom(R(op,[folterm_of_vterm exp1; folterm_of_vterm exp2]))
and fol_of_eq eq = match eq with
    Equat (Equation("=", exp1, exp2))
    | Noneq (Equation("<>", exp1, exp2)) -> Atom(R("=",[folterm_of_vterm exp1; folterm_of_vterm exp2]))
    | _ -> failwith "not a equality"
and fol_of_ineq ineq = match ineq with
    Equat (Equation("=", exp1, exp2)) -> failwith "not a inequality"
    | Noneq (Equation("<>", exp1, exp2)) -> failwith "not a inequality"
    | Equat et -> fol_or_eterm et
    | Noneq et -> fol_or_eterm (negate_eq et)
    | _ -> failwith "not a inequality"

(** Take a query term and rules of idb relations stored in a symtable, generate a FO formula for it *)
let fol_of_query (idb:symtable) (cnt:colnamtab) (query:rterm) =
    (* query is just a rterm which is a predicate therefore need to create a new temporary rule for this query term
    for example if query is q(X,Y,_,5) we create a rule for it: _dummy_(X,Y) :- q(X,Y,_,Z), Z=5. (_dummy_ is a fixed name in the function rule_of_query)
    *)
    let qrule = rule_of_query query idb in
    (* qrule is in the form of _dummy_(x,y) :- query_predicate(x,y), x=1 *)
        let local_idb = Hashtbl.copy idb in
        let local_cnt = Hashtbl.copy cnt in
        (* because insert a temporary dummy qrule, we should work with a local variable of idb *)
        symt_insert local_idb qrule;
        (* add the variable of the head of the qrule to local_cnt *)
        let key = symtkey_of_rule qrule in
        if not (Hashtbl.mem local_cnt key) then
        Hashtbl.add local_cnt key (List.map string_of_var (get_rterm_varlist (rule_head qrule)));
        (try Hashtbl.find local_cnt key
        with Not_found -> raise(SemErr("Not found in cnt the atom "^string_of_symtkey key));
        , fol_of_symtkey local_idb local_cnt (symtkey_of_rterm (rule_head qrule)))

(** Generate a FO formula from the ast, the goal is the view predicate. *)
let fol_of_stt (debug:bool) prog =
    if (debug) then print_endline ("==> generating FOL formula of view " ^ string_of_view (get_view prog)^ " in datalog program" ) else ();
    (* todo: need to check if prog is non-recursive *)
    let edb = extract_edb prog in
    let view_rt = get_schema_rterm (get_view prog) in
    (*Extract and pre-process the IDB from the program*)
    let idb = extract_idb prog in
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    (* print_symtable idb; *)
    (*Build the colnamtab for referencing the table's columns*)
    let cnt = build_colnamtab edb idb in
    (*Return the desired lambda expression*)
    fol_of_query idb cnt view_rt

(** Generate FO formula from the ast, the goal is the query predicate of datalog program. *)
let fol_of_program_query (debug:bool) prog =
    if (debug) then print_endline ("==> generating FOL formula of datalog program of query " ^ string_of_query (get_query prog)) else ();
    (* todo: need to check if prog is non-recursive *)
    let edb = extract_edb prog in
    let query_rt = (get_query prog) in
    (*Extract and pre-process the IDB from the program*)
    let idb = extract_idb prog in
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    (* print_symtable idb; *)
    (*Build the colnamtab for referencing the table's columns*)
    let cnt = build_colnamtab edb idb in
    (*Return the desired lambda expression*)
    fol_of_query idb cnt query_rt

(** Take a view update datalog program and generate the FO sentence of checking whether all delta relations are disjoint. *)
let disjoint_delta_sentence_of_stt (debug:bool) prog =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let delta_rt_lst = get_delta_rterms prog in
    (* get each pair of delta relations from the delta relation lst delta_rt_lst *)
    let delta_pair_lst =
        let pair_of_delta_insert lst ins_rel =
            let del_rels = List.filter (is_delta_pair ins_rel) delta_rt_lst in
            if (List.length del_rels = 0) then lst else (ins_rel, (List.hd del_rels))::lst in
        List.fold_left pair_of_delta_insert [] delta_rt_lst in

    (* get the emptiness FO sentence of a relation *)
    let disjoint_fo_sentence ins_rel del_rel =
        let cols = List.map string_of_var (get_rterm_varlist ins_rel) in
        itlist mk_exists cols (And(snd (fol_of_query idb cnt ins_rel), snd (fol_of_query idb cnt del_rel))) in
    let djsjoint_sen_lst = List.map (fun (r1,r2) -> disjoint_fo_sentence r1 r2) delta_pair_lst in
    Prop.list_disj djsjoint_sen_lst


(** Take a view update datalog program and generate FO sentence of SourceStability (put s v = s) for its view update strategy. *)
let sourcestability_sentence_of_stt (debug:bool) prog =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let delta_rt_lst = get_delta_rterms prog in
    (* get the emptiness FO sentence of a relation *)
    let emptiness_fo_sentence rel =
         let cols = List.map string_of_var (get_rterm_varlist rel) in
         let freevars, delta_fm = (fol_of_query idb cnt rel) in
         (* minimize the delta of relation *)
         let min_delta = (match rel with
            | Deltadelete (predname,lst) ->  And(delta_fm, Atom(R(predname, (List.map (fun x -> Fol.Var x) freevars))) )
            | Deltainsert (predname,lst) -> And(delta_fm, Not (Atom(R(predname, (List.map (fun x -> Fol.Var x) freevars)))))
            | _ -> invalid_arg @@ "predicate" ^ string_of_rterm rel ^"is not a delta predicate"
         ) in
        itlist mk_exists cols min_delta in
    let delta_fo_sentence_lst = List.map emptiness_fo_sentence delta_rt_lst in
    Prop.list_disj delta_fo_sentence_lst


(** Take a view update datalog program (containing both get and put directions) and generate FO sentence of getput property for its view update strategy. *)
let getput_sentence_of_stt (debug:bool) prog =
    let edb = extract_edb prog in
    let idb = extract_idb prog in
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let delta_rt_lst = get_delta_rterms prog in
    (* get the emptiness FO sentence of a relation *)
    let emptiness_fo_sentence rel =
         let cols = List.map string_of_var (get_rterm_varlist rel) in
         let freevars, delta_fm = (fol_of_query idb cnt rel) in
         (* minimize the delta of relation *)
         let min_delta = (match rel with
            | Deltadelete (predname,lst) ->  And(delta_fm, Atom(R(predname, (List.map (fun x -> Fol.Var x) freevars))) )
            | Deltainsert (predname,lst) -> And(delta_fm, Not (Atom(R(predname, (List.map (fun x -> Fol.Var x) freevars)))))
            | _ -> invalid_arg @@ "predicate" ^ string_of_rterm rel ^"is not a delta predicate"
         ) in
        itlist mk_exists cols min_delta in
    let delta_fo_sentence_lst = List.map emptiness_fo_sentence delta_rt_lst in
    Prop.list_disj delta_fo_sentence_lst


(** Take a view update datalog program (containing both get and put directions) and generate FO sentence of putget property for its view update strategy. *)
let putget_sentence_of_stt (debug:bool) prog =
    let putget_prog =  datalog_of_putget debug false prog in
    let edb = extract_edb putget_prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view putget_prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb putget_prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let new_view_rt = rename_rterm "__dummy_new_" view_rt in
    let putget_fm = snd (fol_of_query idb cnt new_view_rt) in
    let view_fm = snd (fol_of_query idb cnt view_rt) in
    generalize (Iff(putget_fm, view_fm))


(** Take a view update datalog program (may contain both get and put directions) and generate the FO sentence of all constraints. *)
let constraint_sentence_of_stt (debug:bool) prog =
    if debug then (print_endline "==> generating all constraints";) else ();
    let edb = extract_edb prog in
    let idb = extract_idb prog in
    if Hashtbl.mem idb (symtkey_of_rterm get_empty_pred) then
        (* need to change the view (in query predicate) to a edb relation *)
        let view_rt = get_schema_rterm (get_view prog) in
        (* need to convert the view to be an edb relation *)
        symt_insert edb (view_rt,[]);
        (* if having get (view rules) then remove it *)
        if Hashtbl.mem idb (symtkey_of_rterm view_rt) then
            symt_remove idb (symtkey_of_rterm view_rt);
        preprocess_rules idb;
        if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
        let cnt = build_colnamtab edb idb in
        Imp(snd (fol_of_query idb cnt get_empty_pred), False)
    else True


(** Take a view update datalog program (may contain both get and put directions) and generate FO sentence of constraints not involving view. *)
let non_view_constraint_sentence_of_stt (debug:bool) prog =
    if debug then (print_endline "==> generating constraint not involving view";) else ();
    let clean_prog = remove_constraint_of_view debug prog in
    let edb = extract_edb clean_prog in
    let idb = extract_idb clean_prog in
    if Hashtbl.mem idb (symtkey_of_rterm get_empty_pred) then
        (* need to change the view (in query predicate) to a edb relation *)
        let view_rt = get_schema_rterm (get_view clean_prog) in
        (* need to convert the view to be an edb relation *)
        (* remove_constraint_of_view debug view_rt edb idb ; *)
        symt_insert edb (view_rt,[]);
        symt_remove idb (symtkey_of_rterm view_rt);
        preprocess_rules idb;
        if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
        let cnt = build_colnamtab edb idb in
        if Hashtbl.mem idb (symtkey_of_rterm get_empty_pred) then
            Imp(snd (fol_of_query idb cnt get_empty_pred), False)
        else True
    else True


(** Take a view update datalog program (may contain both get and put directions) and generate FO sentence of only constraints involving view. *)
let view_constraint_sentence_of_stt (debug:bool) prog =
    if debug then (print_endline "==> generating a sentence of only constraints involving view";) else ();
    let clean_prog = keep_only_constraint_of_view debug prog in
    let edb = extract_edb clean_prog in
    let idb = extract_idb clean_prog in
    if Hashtbl.mem idb (symtkey_of_rterm get_empty_pred) then
        (* need to change the view (in query predicate) to a edb relation *)
        let view_rt = get_schema_rterm (get_view clean_prog) in
        (* need to convert the view to be an edb relation *)
        (* remove_constraint_of_view debug view_rt edb idb ; *)
        symt_insert edb (view_rt,[]);
        symt_remove idb (symtkey_of_rterm view_rt);
        preprocess_rules idb;
        if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
        let cnt = build_colnamtab edb idb in
        if Hashtbl.mem idb (symtkey_of_rterm get_empty_pred) then
            Imp(snd (fol_of_query idb cnt get_empty_pred), False)
        else True
    else True


let get_goal_predicate freevars  goal_num = Pred("p_"^(string_of_int goal_num), (List.map (fun x -> NamedVar x) freevars))

(** Take a RANF formula and return the equivalent datalog program. *)
let rec ranf2datalog fm freevars (goal_num:int) (last_goal_num:int)=
    match fm with
    Atom(R("=",[Var x; Fn (c,[])]))
    | Atom(R("=",[Fn (c,[]); Var x])) -> let goal_predicate = get_goal_predicate freevars goal_num in
        ([(goal_predicate, [Equat (Equation("=", Var (NamedVar x), Const (const_of_string c)))])], goal_predicate, (max (goal_num+1) last_goal_num))
    | Atom(R(_,_))
    | Exists(_,_)
    | Formulas.Not _ -> datalog_of_conj [fm] freevars goal_num last_goal_num
    | And(p,q) -> datalog_of_conj (to_conj_lst fm) freevars goal_num last_goal_num
    | Or(p,q) ->
        let prog1,_,last_goal_num1 =  ranf2datalog p freevars goal_num last_goal_num in
        let prog2,_,last_goal_num2 = ranf2datalog q freevars goal_num last_goal_num1 in

        (prog1@prog2, (get_goal_predicate freevars goal_num), last_goal_num2)
    | _ -> failwith ("fail to get datalog program of " ^ Fol_ex.string_of_fol_formula fm )
and datalog_of_conj conj_lst freevars (goal_num:int) (last_goal_num:int)=
    let rec datalog_of_subfm subfm (rule_termlst, prog, sub_num, local_last_goal_num) =
        (match subfm with
              False -> ((Equat (Equation("=", Const (Int 1), Const (Int 2))))::rule_termlst, prog,sub_num+1, local_last_goal_num)
            | True -> ((Equat (Equation("=",Const (Int 1), Const (Int 1))))::rule_termlst, prog, sub_num+1, local_last_goal_num)
            | Atom(R(p,args)) ->
                if (List.mem p ["="; "<"; "<="; ">"; ">="; "<>"]) then
                    (match args with
                        [term1;term2] -> if (p = "=") then ((Equat (Equation("=", vterm_of_folterm term1, vterm_of_folterm term2)))::rule_termlst, prog, sub_num+1, local_last_goal_num)
                            else ((Equat (Equation(p, vterm_of_folterm term1, vterm_of_folterm term2)))::rule_termlst, prog, sub_num+1, local_last_goal_num)
                        | _ -> failwith ("fail to get datalog predicate of " ^ Fol_ex.string_of_fol_formula subfm )
                    )
                else
                if is_relation_symbol p then
                    (* replace each term not a variable in args to an variable and add an equation of that new variable *)
                    let convert_term t (varlst,eqlst,i)=
                        match t with
                            Fol.Var v -> (NamedVar v::varlst, eqlst,i)
                            | Fol.Fn (c,[]) -> (ConstVar (const_of_string c)::varlst, eqlst,i)
                            | _ -> ((NamedVar ("VAR_"^(string_of_int sub_num)^"_"^(string_of_int i)))::varlst, Equat (Equation("=", Var (NamedVar ("VAR_"^(string_of_int sub_num)^"_"^(string_of_int i))), vterm_of_folterm t)) ::eqlst,i+1) in
                    let varlst, eqlst,_ = List.fold_right convert_term args ([],[],0) in
                    ( (Rel (Pred(p, varlst)))::eqlst@rule_termlst, prog, sub_num+1, local_last_goal_num)
                else failwith ("fail to get datalog program of " ^ Fol_ex.string_of_fol_formula subfm )
            | Formulas.Not Atom(R(p,args)) -> let t1, t2, t3, t4 = datalog_of_subfm (Atom(R(p,args))) (rule_termlst, prog, sub_num, local_last_goal_num) in
                (match t1 with
                    head::tail -> ((negate_term head)::tail, t2, t3, t4)
                    | _ -> failwith ("fail to get datalog program of " ^ Fol_ex.string_of_fol_formula subfm )
                )
            | Exists(x,p) ->
                let quants, psi = extract_ex_quants (Exists(x,p)) in
                (match psi with
                    | Atom(R(p,args)) -> let t1, t2, t3, t4 = datalog_of_subfm (Atom(R(p,args))) (rule_termlst, prog, sub_num, local_last_goal_num) in
                        (match t1 with
                            (Rel predicate)::tail ->
                                let newvarlst = List.map (fun x -> if List.mem (string_of_var x) quants then AnonVar else x ) (get_rterm_varlist predicate) in
                                ((Rel (Pred(get_rterm_predname predicate, newvarlst)))::tail, t2, t3, t4)
                            | _ -> failwith ("can not obtain for datalog program of " ^ Fol_ex.string_of_fol_formula subfm )
                        )
                    | And(p,q ) ->
                        let subfn = fpf quants (List.map (fun x -> Fol.Var (variant x freevars)) quants) in
                        let psi2 = subst subfn psi in
                        let local_conj_lst = to_conj_lst psi2 in
                        let t1, t2, t3, t4 = List.fold_right datalog_of_subfm local_conj_lst (rule_termlst, prog, sub_num, local_last_goal_num) in
                        (t1, t2, t3, t4)
                    | _ ->
                        let subprog, subgoal_pred, new_local_last_goal_num = ranf2datalog psi (fv psi) local_last_goal_num local_last_goal_num in
                        let varlst = get_rterm_varlist subgoal_pred in
                        let newvarlst = List.map (fun x -> if List.mem (string_of_var x) quants then AnonVar else x ) varlst in
                        ((Rel (Pred(get_rterm_predname subgoal_pred, newvarlst)))::rule_termlst, subprog@prog, sub_num+1, new_local_last_goal_num)
                )
            | Formulas.Not (Exists(x,p)) ->
                let quants, psi = extract_ex_quants (Exists(x,p)) in
                (match psi with
                    | Atom(R(p,args)) -> let t1, t2, t3, t4 = datalog_of_subfm (Atom(R(p,args))) (rule_termlst, prog, sub_num, local_last_goal_num) in
                        (match t1 with
                            (Rel predicate)::tail ->
                                let newvarlst = List.map (fun x -> if List.mem (string_of_var x) quants then AnonVar else x ) (get_rterm_varlist predicate) in
                                ((Not (Pred(get_rterm_predname predicate, newvarlst)))::tail, t2, t3, t4)
                            | _ -> failwith ("can not obtain for datalog program of " ^ Fol_ex.string_of_fol_formula subfm )
                        )
                    | _ ->
                        let subprog, subgoal_pred, new_local_last_goal_num = ranf2datalog (Exists(x,p)) (fv (Exists(x,p))) local_last_goal_num local_last_goal_num in
                        ((Not (subgoal_pred))::rule_termlst, subprog@prog,  sub_num+1, new_local_last_goal_num)
                )
                (* let t1, t2, t3, t4 = datalog_of_subfm (Exists(x,p)) (rule_termlst, prog, sub_num, local_last_goal_num) in
                (match t1 with
                    head::tail -> ((negate_term head)::tail, t2, t3, t4)
                    | _ -> failwith ("fail to get datalog program of " ^ Fol_ex.string_of_fol_formula subfm )
                ) *)
            | Formulas.Not p -> let subprog, subgoal_pred, new_local_last_goal_num = ranf2datalog p (fv p) local_last_goal_num local_last_goal_num in
                ((Not (subgoal_pred))::rule_termlst, subprog@prog,  sub_num+1, new_local_last_goal_num)
            | _ -> let subprog, subgoal_pred, new_local_last_goal_num = ranf2datalog subfm (fv subfm) local_last_goal_num local_last_goal_num in
                (((Rel(subgoal_pred)))::rule_termlst, subprog@prog, sub_num+1, new_local_last_goal_num) ) in
    let goal_predicate = get_goal_predicate freevars goal_num in
    let rule_termlst, prog, _, new_last_goal_num = List.fold_right datalog_of_subfm conj_lst ([],[],0, (max (goal_num+1) last_goal_num) ) in
    ( (goal_predicate, rule_termlst))::prog, goal_predicate, new_last_goal_num

(** Transform a safe range FO formula to a Datalog program. *)
let fol2datalog freevars fm =
    if set_eq (setify freevars) (fv fm) then
        let lst, rt, _ = ranf2datalog (ranf (simplify (normalize_comparison fm))) freevars 0 0 in
        {get_empty_expr with query = Some rt; rules = lst}
    else failwith "the list of variables must be exactly the free varilabes in FO formula"

(** Transform a safe range FO formula of a view to a datalog program, we need all schema statements for source and view. *)
let view_fol2datalog (debug:bool) view sources freevars fm =
    let view_rt = get_schema_rterm view in
    if (debug) then print_endline ("==> generating datalog program of view " ^ string_of_rterm (view_rt)) else ();
    if set_eq (setify freevars) (fv fm) then
        let lst, rt, _ = ranf2datalog (ranf (simplify (normalize_comparison fm))) freevars 0 0 in
        {get_empty_expr with view = Some view; sources = sources; rules = (Pred((get_rterm_predname view_rt), get_rterm_varlist rt ), [Rel rt])::lst}
    else failwith "the list of variables must be exactly the free varilabes in FO formula"

(** Transform a safe range FO formula of a view to a datalog program, we need all schema statements for source and view. *)
let fol2datalog (debug:bool) (is_ranf:bool) query sources freevars fm =
    if (debug) then print_endline ("==> generating datalog program of query " ^ string_of_query query) else ();
    (* let query_rt = get_query_rterm query in   *)
    if set_eq (setify freevars) (fv fm) then
        let ranf_fm = if is_ranf then fm else (ranf (simplify (normalize_comparison fm))) in
        let lst, rt, _ = ranf2datalog ranf_fm freevars 0 0 in
        {get_empty_expr with query = Some query; sources = sources; rules = (change_vars query (get_rterm_varlist rt), [Rel rt])::lst}
    else failwith "the list of variables must be exactly the free varilabes in FO formula"

let optimize_query_datalog (debug:bool) prog =
    let query = (get_query prog) in
    (* let query_rt = get_query_rterm query in *)
    if (debug) then print_endline ("==> optimizing datalog program of query " ^ string_of_query query) else ();
    let freevars, fm = fol_of_program_query ( debug) prog in
    if (debug) then print_endline ("==> intermediate FOL formula of datalog optimization of query " ^ string_of_query (get_query prog) ^ "is: \n" ^ lean_string_of_fol_formula fm^ "\n________\n") else ();

    (* fm is already in ranf so we do not need to transform in to ranf more *)
    let refined_fm = remove_trivial fm in
    (* if the obtained formula is false then the query is always empty, we just need to remove it from prog *)
    if refined_fm = False then
        {get_empty_expr with view = prog.view; sources = prog.sources}
    else
        let new_prog = fol2datalog debug true query prog.sources freevars refined_fm in
        if debug then (
            print_endline ("_____optimized datalog program of query " ^ string_of_query query^"_______");
            print_endline (string_of_prog new_prog);
            print_endline "______________\n";
        ) else ();
        new_prog

let rules_to_fo_list (idb: symtable) (cnt: colnamtab) (query: rterm) =
    (* Step 1: Create a temporary rule for the query *)
    (* let qrule = rule_of_query query idb in
    
    (* Step 2: Create local copies of idb and cnt for safe modifications *)
    let local_idb = Hashtbl.copy idb in
    let local_cnt = Hashtbl.copy cnt in
    
    (* Step 3: Insert the temporary rule into local_idb *)
    symt_insert local_idb qrule;
    
    (* Step 4: Extract the key of the query's head *)
    let key = symtkey_of_rterm (rule_head qrule) in *)
    let key = symtkey_of_rterm query in

    (* Step 5: Ensure the variables of the query's head are in local_cnt *)
    (* if not (Hashtbl.mem local_cnt key) then
        Hashtbl.add local_cnt key (List.map string_of_var (get_rterm_varlist (rule_head qrule))); *)
    
    (* Step 6: Find all rules with the query's head and convert them to FO formulas *)
    try
        let rules = Hashtbl.find idb key in
        (* print_string (String.concat "\n" (List.map (string_of_rule) rules)); *)
        List.map (fol_of_rule idb cnt) rules
    with Not_found ->
        raise (SemErr ("No rules found for the query head: " ^ string_of_rterm (query)))
    


(** Take a view update datalog program and generate the FO sentence of checking whether get' is injectivity. *)
let injectivity_sentence_of_stt (debug:bool) prog =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let delta_rt_lst = get_delta_rterms prog in
    (* injective: two deltas are same if and only if states are same
    check: given two rules with the same delta, check (state1 and state2 -> false) *)
    (* get the emptiness FO sentence of a relation *)
    let injectivity_fo_sentence delta =
        let cols = List.map string_of_var (get_rterm_varlist delta) in
        let ruleslist = rules_to_fo_list idb cnt delta in
        let folList = 
            let join2rules (r1,r2) = And(r1,r2) in
            let rulepairs = get_pairs ruleslist in
            List.map join2rules rulepairs
        in
        List.map (itlist mk_exists cols) folList in
    let injectivity_sen_lst = List.map (fun d -> injectivity_fo_sentence d) delta_rt_lst in
    Prop.list_disj (List.concat injectivity_sen_lst)

let replaceVDelta rules =
    List.map (fun (h, b) -> (rterm2noDelta h, b)) rules

(* let rules_to_fo_fuse idb cnt newrterm =  *)

let fusable_sentence_of_stt debug prog queryRTerm1 queryRTerm2 =
    let newprog = { prog with
        rules = replaceVDelta prog.rules
    } in
    let edb = extract_edb newprog in
    let view_rt = get_schema_rterm (get_view newprog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb newprog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let newrterm1 = variablize_rterm queryRTerm1 in
    let newrterm2 = variablize_rterm queryRTerm2 in
    let cols = List.map string_of_var (get_rterm_varlist newrterm1) in
    let sentence = And (Imp (itlist mk_exists cols (Prop.list_disj (rules_to_fo_list idb cnt newrterm1)), False), Imp (itlist mk_exists cols (Prop.list_disj (rules_to_fo_list idb cnt newrterm2)), False)) in
    sentence

let empty_sentence_of_stt (debug:bool) prog (queryRTerm : rterm) =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let newrterm = variablize_rterm queryRTerm in
    let cols = List.map string_of_var (get_rterm_varlist newrterm) in
    let sentence = itlist mk_exists cols (Prop.list_disj (rules_to_fo_list idb cnt newrterm)) in
    sentence

let contradictory_sentence_of_stt (debug:bool) (prog : expr) (contradictoryRTerm : rterm) =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let newrterm = variablize_rterm contradictoryRTerm in
    let cols = List.map string_of_var (get_rterm_varlist newrterm) in
    let sentence = itlist mk_exists cols (Prop.list_disj (rules_to_fo_list idb cnt newrterm)) in
    sentence

let valbinding_sentence_of_stt (debug:bool) (prog : expr) (valBindingRTerm : rterm) =
    let edb = extract_edb prog in
    (* need to change the view (in query predicate) to a edb relation *)
    let view_rt = get_schema_rterm (get_view prog) in
    (* need to convert the view to be an edb relation *)
    symt_insert edb (view_rt,[]);
    let idb = extract_idb prog in
    symt_remove idb (symtkey_of_rterm view_rt);
    preprocess_rules idb;
    if debug then (
        print_endline "_____preprocessed datalog rules_______";
        print_symtable idb;
        print_endline "______________\n";
    ) else ();
    let cnt = build_colnamtab edb idb in
    let newrterm = variablize_rterm valBindingRTerm in
    let cols = List.map string_of_var (get_rterm_varlist newrterm) in
    let sentence = itlist mk_exists cols (Prop.list_disj (rules_to_fo_list idb cnt newrterm)) in
    sentence