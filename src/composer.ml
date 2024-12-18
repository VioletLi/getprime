open Expr
open Utils
open Verifier
open Sys

let renameRterm r =
  match r with
    | Pred (n, attrs) -> Pred (n ^ "_prime", attrs)
    | Deltainsert (n, attrs) -> Deltainsert (n ^ "_prime", attrs)
    | Deltadelete (n, attrs) -> Deltadelete (n ^ "_prime", attrs)

let renameTerm t = 
  match t with
    | Rel r -> Rel (renameRterm r)
    | Not r -> Not (renameRterm r)
    | _ -> t

let renameRule (h, b) =
  let nb = List.map renameTerm b in
  let nh = renameRterm h in
  (nh, nb)

let isDeltaRule (h, b) =
  match h with
    | Pred _ -> false
    | _ -> true

let isInsertRule (h, b) =
  match h with
    | Deltainsert _ -> true
    | Deltadelete _ -> false
    | _ -> raise (ComposeErr "there cannot be non-delta rules when verify and compose")

let getVarNum h = 
  match h with 
    | Deltainsert (n, attrs) -> List.length attrs
    | Deltadelete (n, attrs) -> List.length attrs
    | _ -> raise (ComposeErr "there cannot be non-delta rules when verify and compose")

let generate_combinations vars =
  let n = List.length vars in
  (* 生成每个变量的两个版本：原变量和原变量+"1" *)
  let extended_vars = List.map (fun v -> [v; v ^ "1"]) vars in
  (* 生成所有可能的组合 *)
  let rec combine acc i =
    if i = n then
      (* 到达末尾时，生成当前组合 *)
      [acc]
    else
      (* 对当前变量的两个版本进行递归组合 *)
      List.flatten (List.map (fun v ->
        combine (acc @ [v]) (i + 1)
      ) (List.nth extended_vars i))
  in
  combine [] 0

let applyUpdateRules (name, attrs) = 
  let head = get_schema_rterm (name ^ "_prime", attrs) in
  let src = get_schema_rterm (name, attrs) in
  [ (head, [(Rel src);(Not (Deltadelete (name, (List.map (fun (n, _) ->(NamedVar n)) attrs))))])
  ; (head, [(Rel (Deltainsert (name, (List.map (fun (n, _) ->(NamedVar n)) attrs))))])
  ]

let isDeltaTerm t =
  match t with
    | Rel r ->
      begin
        match r with
          | Pred _ -> false
          | _ -> true
      end
    | _ -> false

let find_index elem lst =
  let rec f i = function
    | [] -> raise (ComposeErr "No element in list")
    | x::xs -> if x = elem then i else f (i + 1) xs
  in
  f 0 lst

let renameVar vars updatedVars var =
  match var with
    | NamedVar n -> 
        let index = find_index n vars in
        let newName = List.nth updatedVars index in
        NamedVar newName
    | _ -> var

let renameDeltaVars vars updatedVars term =
  match term with
    | Rel r ->
      begin
        match r with
          | Deltainsert (name, attrs) -> Rel (Deltainsert (name, List.map (renameVar vars updatedVars) attrs))
          | Deltadelete (name, attrs) -> Rel (Deltadelete (name, List.map (renameVar vars updatedVars) attrs))
          | _ -> raise (ComposeErr "Only vars in delta operations need to be rewrited")
      end
    | _ -> raise (ComposeErr "Only vars in delta operations need to be rewrited")

let getVarName v =
  match v with
    | NamedVar n -> n
    | _ -> raise (ComposeErr "Variable needs to be a namedvar")

let rec renameVarinVterm vars updatedVars v =
  match v with
    | Var var -> Var (renameVar vars updatedVars var)
    | BinaryOp (s, v1, v2) -> BinaryOp (s, renameVarinVterm vars updatedVars v1, renameVarinVterm vars updatedVars v2)
    | UnaryOp (s, v1) -> UnaryOp (s, renameVarinVterm vars updatedVars v1)
    | _ -> v

let renamePredVars vars updatedVars term =
  match term with
    | Rel r ->
      begin
        match r with
          | Pred (name, attrs) -> Rel (Pred (name, List.map (renameVar vars updatedVars) attrs))
          | _ -> raise (ComposeErr "Only vars in non-delta predicates need to be rewrited")
      end
    | Not r ->
      begin
        match r with
          | Pred (name, attrs) -> Not (Pred (name, List.map (renameVar vars updatedVars) attrs))
          | Deltainsert (name, attrs) -> Not (Deltainsert (name, List.map (renameVar vars updatedVars) attrs))
          | Deltadelete (name, attrs) -> Not (Deltadelete (name, List.map (renameVar vars updatedVars) attrs))
      end
    | Equat e -> 
      begin
        match e with
          | Equation (s, v1, v2) -> Equat (Equation (s, renameVarinVterm vars updatedVars v1, renameVarinVterm vars updatedVars v2))
      end
    | Noneq e -> 
      begin
        match e with
          | Equation (s, v1, v2) -> Noneq (Equation (s, renameVarinVterm vars updatedVars v1, renameVarinVterm vars updatedVars v2))
      end
    | _ -> raise (ComposeErr "Only vars in non-delta operations need to be rewrited")

let isCompareTerm t =
  match t with
    | Equat _ -> true
    | Noneq _ -> true 
    | _ -> false

let checkAndCombine expr vars updatedVars allInterRules (h1, b1) (h2, b2) =
  let deltab1, nondeltab1 = List.partition isDeltaTerm b1 in
  let deltab2, nondeltab2 = List.partition isDeltaTerm b2 in
  let valueBindingb1, o1 = List.partition isCompareTerm nondeltab1 in
  let valueBindingb2, o2 = List.partition isCompareTerm nondeltab2 in
  let h1vars = List.map getVarName (get_rterm_varlist h1) in
  let h2vars = List.map getVarName (get_rterm_varlist h2) in
  let newDeltab1 = List.map (renameDeltaVars h1vars updatedVars) deltab1 in
  let newDeltab2 = List.map (renameDeltaVars h2vars updatedVars) deltab2 in
  let newh1 = match h1 with
    | Deltainsert (n, _) -> Deltainsert (n, List.map (fun v -> NamedVar v) vars)
    | Deltadelete (n, _) -> Deltadelete (n, List.map (fun v -> NamedVar v) vars)
    | _ -> raise (ComposeErr "Head need to be a delta of view")
  in
  let newh2 = match h2 with
    | Deltainsert (n, _) -> Deltainsert (n, List.map (fun v -> NamedVar v) updatedVars)
    | Deltadelete (n, _) -> Deltadelete (n, List.map (fun v -> NamedVar v) updatedVars)
    | _ -> raise (ComposeErr "Head need to be a delta of view")
  in
  let newb1 = List.map (renamePredVars h1vars vars) nondeltab1 in
  let newvalBindingb1 = List.map (renamePredVars h1vars vars) valueBindingb1 in
  let newvalBindingb2 = List.map (renamePredVars h2vars updatedVars) valueBindingb2 in
  let queryRTerm = Pred ("testcompose", List.map (fun v -> NamedVar v) (vars @ updatedVars)) in
  let rule = (queryRTerm, newDeltab1 @ newDeltab2 @ [Rel newh1; Not newh2] @ newvalBindingb1 @ newvalBindingb2)
  in
  let newexpr = { expr with 
    rules = rule :: [(h1, b1); (h2, b2)] @ allInterRules
  } in
  (* print_string (to_string newexpr); *)
  let code = genUncomposableCode newexpr queryRTerm in
  (* print_string "here"; *)
  let exitcode, message = verify_fo_lean true 120 code in
  if not (exitcode = 0) then
    if exitcode = 124 then raise (ComposeErr "Stop composing: timeout, cannot verify if the two rules can be composed or not")
    else []
  else [([newh1; newh2], newDeltab1 @ newDeltab2 @ newb1 @ newvalBindingb1 @ newvalBindingb2)]

let print_rulePairs rulePairs =
  print_string "begin rulepairs:\n";
  List.map (fun (r1, r2) -> print_string (string_of_rule r1);print_string (string_of_rule r2);print_string "\n") rulePairs;
  print_string "end rulepairs\n"

let compose expr =
  (* 分开需要的中间规则和delta规则 *)
  let deltaRules, interRules = List.partition isDeltaRule expr.rules in
  let insRules, delRules = List.partition isInsertRule deltaRules in
  (* delta规则变compose *)
  (* let crules = List.map rule2crule expr.rules in *)
  (* 给中间规则和delta规则重命名 *)
  let newInterRules = List.map renameRule interRules in
  let newInsRules = List.map renameRule insRules in
  let newSourceRules = List.concat (List.map applyUpdateRules expr.sources) in
  (* let newrules = List.map (rule2crule) (List.map renameRule expr.rules) in *)
  (* delta重命名组合pair *)
  let allInterRules = interRules @ newInterRules @ newSourceRules in
  let viewSchema = match expr.view with
    | Some v -> v
    | _ -> raise (ComposeErr "No view definition")
  in
  let vars = get_schema_attrs viewSchema in
  let combinedVars = List.filter (fun combination -> List.exists (fun (a, b) -> a <> b) (List.combine combination vars)) (generate_combinations vars) in
  let rulePairs = List.concat (List.map (fun x -> List.map (fun y -> (x, y)) newInsRules) delRules) in
  let verifyAndCompose ((h1, b1), (h2, b2)) = 
    List.concat (List.map (fun updatedVars -> checkAndCombine expr vars updatedVars allInterRules (h1, b1) (h2, b2)) combinedVars) 
  in
  List.concat (List.map verifyAndCompose rulePairs)
  (* 对每一个pair 中间规则的两个版本+重命名新的pair的两个rule+新规则 尝试不同的变量组合 翻译成lean验证 *)


  (* compose的思路：对于任意的两条规则的pair：
  已经验证了每次只会trigger一条规则
1. 给第二条规则改名，s改为s'之类的，添加规则s' :- s,not s_del, s' :- s_ins, s_ins', s_del'
2. 找到v中所有的可以更新的变量组合 only X，only Y，X+Y。。。
3. 给两条规则分别改名为 t1(Xs) :- ds, s. t2(Xs) :- ds', s'.
4. 对于所有的可以更新的变量组合，验证constraint-> (forall vs, ds, ds', t1, not t2->false),如果验证为永真，那么组合[dv1, dv2] :- ds1, ds2(去重), s. 
*)