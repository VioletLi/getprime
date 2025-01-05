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
    | _ -> raise (FuseErr "there cannot be non-delta rules when verify and fuse")

let getVarNum h = 
  match h with 
    | Deltainsert (n, attrs) -> List.length attrs
    | Deltadelete (n, attrs) -> List.length attrs
    | _ -> raise (FuseErr "there cannot be non-delta rules when verify and fuse")

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
    | Not r ->
      begin
        match r with
          | Pred _ -> false
          | _ -> true
      end
    | _ -> false

let find_index elem lst =
  let rec f i = function
    | [] -> raise (FuseErr "No element in list")
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
          | _ -> raise (FuseErr "Only vars in delta operations need to be rewrited")
      end
    | Not r ->
      begin
        match r with
          | Deltainsert (name, attrs) -> Rel (Deltainsert (name, List.map (renameVar vars updatedVars) attrs))
          | Deltadelete (name, attrs) -> Rel (Deltadelete (name, List.map (renameVar vars updatedVars) attrs))
          | _ -> raise (FuseErr "Only vars in delta operations need to be rewrited")
      end
    | _ -> raise (FuseErr "Only vars in delta operations need to be rewrited")

let getVarName v =
  match v with
    | NamedVar n -> n
    | _ -> raise (FuseErr "Variable needs to be a namedvar")

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
          | _ -> raise (FuseErr "Only vars in non-delta predicates need to be rewrited")
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
    | _ -> raise (FuseErr "Only vars in non-delta operations need to be rewrited")

let isCompareTerm t =
  match t with
    | Equat _ -> true
    | Noneq _ -> true 
    | _ -> false
  
let mkEqualityBinding vars updatedVars =
  List.concat (List.map (fun (x, y) -> if x <> y then [Noneq (Equation ("=", (Var (NamedVar x)), (Var (NamedVar y))))] else []) (List.combine vars updatedVars))

let getRtermVarNames rterm = List.map string_of_var (get_rterm_varlist rterm)

let checkAndCancel insDelta delDeltas =
  let insRelation = getDeltaRelationName insDelta in
  let candidates = List.filter (fun d -> (getDeltaRelationName d) = insRelation) delDeltas in
  let canCancel = List.filter (fun d -> isEqualLists (getRtermVarNames insDelta) (getRtermVarNames d)) candidates in
  if is_empty canCancel then [] else insDelta :: canCancel

let isEqualDelta d1 d2 =
  if (isInsertDelta d1) <> (isInsertDelta d2) then false
  else
    if (getDeltaRelationName d1) <> (getDeltaRelationName d2) then false
    else
      isEqualLists (getRtermVarNames d1) (getRtermVarNames d2)

let inDeltaList d deltas = 
  List.exists (fun delta -> isEqualDelta d delta) deltas

let cancelDelta delta1 delta2 =
  let deltas = List.map unpack_term (delta1 @ delta2) in
  let insDeltas, delDeltas = List.partition isInsertDelta deltas in
  let cancelDeltas = List.concat (List.map (fun insDelta -> checkAndCancel insDelta delDeltas) insDeltas) in
  let resDeltas = List.filter (fun d -> not (inDeltaList d cancelDeltas)) deltas in
  List.map (fun rterm -> Rel rterm) resDeltas

let isNamedVar v =
  match v with
    | NamedVar _ -> true
    | _ -> false

let rec getNamedVarsinVTerm vterm =
  match vterm with
    | Var v -> if isNamedVar v then [v] else []
    | BinaryOp (_, v1, v2) -> (getNamedVarsinVTerm v1) @ (getNamedVarsinVTerm v2)
    | UnaryOp (_, v) -> getNamedVarsinVTerm v
    | _ -> []

let getVtermsinEterm e =
  match e with
    | Equation (_, v1, v2) -> (v1,v2)

let getVtermsinTerm t = 
  match t with
    | Equat e -> getVtermsinEterm e
    | Noneq e -> getVtermsinEterm e

let rec preProcessTerms varsSet terms =
  match terms with
    | [] -> varsSet, [], []
    | t :: terms_ ->
        let v1, v2 = getVtermsinTerm t in
        let vars = List.concat (List.map getNamedVarsinVTerm [v1;v2]) in
        if List.length vars = 1 then 
          begin
            let newset = StringSet.add (string_of_var (getSingleElem vars)) varsSet in
            let resset, handled, unhandled = preProcessTerms newset terms_ in
            (resset, t :: handled, unhandled)
          end
        else 
          begin
            let resset, handled, unhandled = preProcessTerms varsSet terms_ in
            (resset, handled, t :: unhandled)
          end

let isEqualEquat t =
  match t with
    | Equat e -> 
        begin
          match e with
            | Equation (s, _, _) -> if s = "=" then true else false
        end
    | Noneq _ -> false
    | _ -> raise (EnvErr "Only Equations in value binding")

let rec bfs varSet terms =
  match terms with
    | [] -> ([], [], [])
    | t :: terms_ ->
        let v1, v2 = getVtermsinTerm t in
        let leftVars = List.map string_of_var (getNamedVarsinVTerm v1) in
        let rightVars = List.map string_of_var (getNamedVarsinVTerm v2) in
        if List.exists (fun v -> not (StringSet.mem v varSet)) leftVars then
          begin
            if List.exists (fun v -> not (StringSet.mem v varSet)) rightVars then 
              begin
                (* 两边都有未明确赋值的变量 *)
                let vars, handled, unhandled = bfs varSet terms_ in
                (vars, handled, t :: unhandled)
              end
            else
              begin
                (* 右边没有未明确赋值的变量 *)
                let vars, handled, unhandled = bfs varSet terms_ in
                let newVars = List.filter (fun v -> not (StringSet.mem v varSet)) leftVars in
                (vars @ newVars, t :: handled, unhandled)
              end
          end
        else
          if List.exists (fun v -> not (StringSet.mem v varSet)) rightVars then 
            begin
              (* 左边没有未明确赋值的变量 *)
              let vars, handled, unhandled = bfs varSet terms_ in
              let newVars = List.filter (fun v -> not (StringSet.mem v varSet)) rightVars in
              (vars @ newVars, t :: handled, unhandled)
            end
          else
            (* 左右两边都没有未明确赋值的变量 *)
            let vars, handled, unhandled = bfs varSet terms_ in
            (vars, t :: handled, unhandled)

let rec findAllAssignedVars varSet terms =
  let newVars, handled, unhandled = bfs varSet terms in
  if is_empty newVars then (varSet, handled, unhandled)
  else
    begin
      let newVarSet = addElems2StringSet newVars varSet in
      let finalSet, finalHandled, finalUnhandled = findAllAssignedVars newVarSet unhandled in
      (finalSet, (handled @ finalHandled), finalUnhandled)
    end

let collectVarsinEquation varsNeedtobeTested terms = 
  let empty_set = StringSet.empty in
  let equalEquat, negEquat = List.partition (isEqualEquat) terms in
  let varSet, termsHandled, termsUnhandled = preProcessTerms empty_set equalEquat in
  let finalSet, finalHandled, finalUnhandled = findAllAssignedVars varSet termsUnhandled in
  let handledNegs = List.filter (fun e -> not (List.exists (fun v -> not (StringSet.mem (string_of_var v) finalSet)) (List.concat (List.map getNamedVarsinVTerm (let v1, v2 = getVtermsinTerm e in [v1;v2]))))) negEquat in
  (finalSet, termsHandled @ finalHandled @ handledNegs)

let removeDupVars varlist =
  List.fold_left (fun acc x ->
    if List.exists (fun y -> (string_of_var x) = (string_of_var y)) acc then acc else x :: acc
  ) [] varlist

let tryFuse expr vars updatedVars allInterRules (h1, b1) (oldh2, oldb2) (h2, b2) =
  let deltab1, nondeltab1 = List.partition isDeltaTerm b1 in
  let deltaoldb2, nondeltaoldb2 = List.partition isDeltaTerm oldb2 in
  let deltab2, nondeltab2 = List.partition isDeltaTerm b2 in
  let valueBindingb1, o1 = List.partition isCompareTerm nondeltab1 in
  let valueBindingoldb2, oldo2 = List.partition isCompareTerm nondeltaoldb2 in
  let valueBindingb2, o2 = List.partition isCompareTerm nondeltab2 in
  let h1vars = List.map getVarName (get_rterm_varlist h1) in
  let oldh2vars = List.map getVarName (get_rterm_varlist oldh2) in
  let h2vars = List.map getVarName (get_rterm_varlist h2) in
  let newDeltab1 = List.map (renameDeltaVars h1vars vars) deltab1 in
  let newDeltaoldb2 = List.map (renameDeltaVars oldh2vars updatedVars) deltaoldb2 in
  let newDeltab2 = List.map (renameDeltaVars h2vars updatedVars) deltab2 in
  let newh1 = match h1 with
    | Deltainsert (n, _) -> raise (FuseErr "head of rule 1 is delete")
    | Deltadelete (n, _) -> Deltadelete (n, List.map (fun v -> NamedVar v) vars)
    | _ -> raise (FuseErr "Head need to be a delta of view")
  in
  let newoldh2 = match oldh2 with
    | Deltainsert (n, _) -> Deltainsert (n, List.map (fun v -> NamedVar v) updatedVars)
    | Deltadelete (n, _) -> raise (FuseErr "head of rule 2 is insert")
    | _ -> raise (FuseErr "Head need to be a delta of view")
  in
  let newh2 = match h2 with
    | Deltainsert (n, _) -> Deltainsert (n, List.map (fun v -> NamedVar v) updatedVars)
    | Deltadelete (n, _) -> raise (FuseErr "head of rule 2 is insert")
    | _ -> raise (FuseErr "Head need to be a delta of view")
  in
  let newb1 = List.map (renamePredVars h1vars vars) nondeltab1 in
  let newoldb2 = List.map (renamePredVars oldh2vars updatedVars) nondeltaoldb2 in
  let newvalBindingb1 = List.map (renamePredVars h1vars vars) valueBindingb1 in
  let newvalBindingoldb2 = List.map (renamePredVars oldh2vars updatedVars) valueBindingoldb2 in
  let newvalBindingb2 = List.map (renamePredVars h2vars updatedVars) valueBindingb2 in
  let varsNeedtobeTested = List.map (fun v -> NamedVar v) (vars @ (removeDup vars updatedVars)) in
  let contradictoryRTerm = Pred ("contradictory", varsNeedtobeTested) in
  (* let queryRTerm2 = Pred ("cannotExecAfter", varsNeedtobeTested) in *)
  let equalityBinding = mkEqualityBinding vars updatedVars in
  (* 第一条规则和第二条规则都能执行 也就是说他们的执行条件不冲突 *)
  let contradictoryRule = (contradictoryRTerm, newb1 @ newoldb2 @ equalityBinding) in
  let varSet, assignments = collectVarsinEquation varsNeedtobeTested (newvalBindingb1 @ newvalBindingoldb2 @ equalityBinding) in
  if is_empty assignments then 
    begin
      let contradictoryExpr = { expr with
        rules = contradictoryRule :: allInterRules
      } in
      let checkContradictoryCode = genContradictoryCode contradictoryExpr contradictoryRTerm in
      let exitcode, message = verify_fo_lean false 300 checkContradictoryCode in
      if exitcode = 0 then 
        begin
          print_string (String.concat "," updatedVars);
          print_string "\n";
          print_string (string_of_rule (h1, b1));
          print_string (string_of_rule (oldh2, oldb2));
          print_string (string_of_rule contradictoryRule);
          print_string "\n\n";
          []
        end
      else []
    end
  else
    begin
      let varsinValBinding = List.map (fun v -> NamedVar v) (StringSet.elements varSet) in
      let valBindingRTerm = Pred ("valbinding", varsinValBinding) in
      let valBindingRule = (valBindingRTerm, assignments) in
      let testValBindingExpr = { expr with
        rules = [valBindingRule]
      } in
      let checkValBindingCode = genValBindingCode testValBindingExpr valBindingRTerm in
      let exitcodeVal, messageVal = verify_fo_lean true 120 checkValBindingCode in
      if exitcodeVal = 0 then []
      else
      begin
        let contradictoryExpr = { expr with
          rules = contradictoryRule :: allInterRules
        } in
        let checkContradictoryCode = genContradictoryCode contradictoryExpr contradictoryRTerm in
        let exitcode, message = verify_fo_lean false 300 checkContradictoryCode in
        if exitcode = 0 then 
          begin
            print_string (String.concat "," updatedVars);
            print_string "\n";
            print_string (string_of_rule (h1, b1));
            print_string (string_of_rule (oldh2, oldb2));
            print_string (string_of_rule contradictoryRule);
            print_string "\n\n";
            []
          end
        else []
      end
    end
  (* let rule1 = (queryRTerm1, newDeltab1 @ [Rel newh1] @ newDeltaoldb2 @ [Rel newoldh2] @ newvalBindingb1 @ newvalBindingoldb2 @ equalityBinding) in
  let rule2 = (queryRTerm2, newDeltab1 @ newDeltab2 @ [Rel newh1; Not newh2] @ newvalBindingb1 @ newvalBindingb2 @ equalityBinding)
  in
  let newexpr = { expr with 
    rules = [rule1; rule2; (h1, b1); (oldh2, oldb2); (h2, b2)] @ allInterRules
  } in
  (* print_string (to_string newexpr); *)
  let code = genFusableCode newexpr queryRTerm1 queryRTerm2 in
  (* print_string "here"; *)
  let exitcode, message = verify_fo_lean true 300 code in
  if not (exitcode = 0) then 
    begin
    print_string "cannot fused:\n";
    print_string (string_of_rule (h1, b1));
    print_string (string_of_rule (oldh2, oldb2));
    print_string (string_of_rule rule1);
    print_string (string_of_rule rule2);
    if exitcode = 124 then raise (FuseErr "Stop composing: timeout, cannot verify if the two rules can be fused or not")
    else []
    end
  else 
    let newruleHead = Pred ("isEmpty", varsNeedtobeTested) in
    let fuseDelta = cancelDelta newDeltab1 newDeltaoldb2 in
    let newruleBody = fuseDelta @ newb1 @ newvalBindingb1 @ newvalBindingoldb2 @ equalityBinding in
    (* let testEmptyExpr = {expr with rules = (newruleHead, newruleBody) :: allInterRules} in *)
    print_string "can fused:\n";
    print_string (string_of_rule (h1, b1));
    print_string (string_of_rule (oldh2, oldb2));
    print_string (string_of_rule rule1);
    print_string (string_of_rule rule2);
    print_string (string_of_rule (newruleHead, newruleBody));
    (* let isEmptyCode = genTestEmptyCode testEmptyExpr newruleHead in
    let exitcode2, message2 = verify_fo_lean false 120 isEmptyCode in
    if not (exitcode = 0) then 
      if exitcode = 124 then raise (FuseErr "Stop testing: timeout, cannot verify if the fused rule is empty")
      else [([newh1; newoldh2], newruleBody)]
    else *)
      [] *)

let print_rulePairs rulePairs =
  print_string "begin rulepairs:\n";
  List.map (fun (r1, r2) -> print_string (string_of_rule r1);print_string (string_of_rule r2);print_string "\n") rulePairs;
  print_string "end rulepairs\n"

let fuseRules expr =
  let viewSchema = match expr.view with
    | Some v -> v
    | _ -> raise (FuseErr "No view definition")
  in
  let vars = get_schema_attrs viewSchema in
  let tempVars = List.filter (fun combination -> List.exists (fun (a, b) -> a <> b) (List.combine combination vars)) (generate_combinations vars) in
  let combinedVars = List.filter (fun combination -> List.exists (fun (a, b) -> a = b) (List.combine combination vars)) tempVars in
  if is_empty combinedVars then [] else
  (* 分开需要的中间规则和delta规则 *)
    let deltaRules, interRules = List.partition isDeltaRule expr.rules in
    let insRules, delRules = List.partition isInsertRule deltaRules in
    (* delta规则变fuse *)
    (* let crules = List.map rule2crule expr.rules in *)
    (* 给中间规则和delta规则重命名 *)
    let newInterRules = List.map renameRule interRules in
    let newInsRules = List.map renameRule insRules in
    let newSourceRules = List.concat (List.map applyUpdateRules expr.sources) in
    (* let newrules = List.map (rule2crule) (List.map renameRule expr.rules) in *)
    (* delta重命名组合pair *)
    let allInterRules = interRules @ newInterRules @ newSourceRules in
    let rulePairs = List.concat (List.map (fun x -> List.map (fun y -> (x, y)) (List.combine insRules newInsRules)) delRules) in
    let verifyAndFuse ((h1, b1), ((oldh2, oldb2), (h2, b2))) = 
      List.concat (List.map (fun updatedVars -> tryFuse expr vars updatedVars allInterRules (h1, b1) (oldh2, oldb2) (h2, b2)) combinedVars) 
    in
    List.concat (List.map verifyAndFuse rulePairs)
  (* 对每一个pair 中间规则的两个版本+重命名新的pair的两个rule+新规则 尝试不同的变量组合 翻译成lean验证 *)


  (* fuse的思路：对于任意的两条规则的pair：
  已经验证了每次只会trigger一条规则
1. 给第二条规则改名，s改为s'之类的，添加规则s' :- s,not s_del, s' :- s_ins, s_ins', s_del'
2. 找到v中所有的可以更新的变量组合 only X，only Y，X+Y。。。
3. 给两条规则分别改名为 t1(Xs) :- ds, s. t2(Xs) :- ds', s'.
4. 对于所有的可以更新的变量组合，验证constraint-> (forall vs, ds, ds', t1, not t2->false),如果验证为永真，那么组合[dv1, dv2] :- ds1, ds2(去重), s. 
*)