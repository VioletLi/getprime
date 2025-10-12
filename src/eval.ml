open Expr
open Utils

(* matching 首先规则中的op个数和rule中op个数要对得上，其次每一个对应位置的op要对得上，然后产生一个environment，合并的时候不能产生冲突；用这个environment和db一起去check predicate，通过了才能判定这个规则match上了，否则这条就没match上；match上之后要subst被trigger的op *)
let rec updEnv env lst =
  match lst with
    | (NamedVar "match", NamedVar "match") :: lst_ -> updEnv env lst_
    | (NamedVar v, ConstVar c) :: lst_ ->
      begin
      try
        if v = "match" then false else
          let v_ = Hashtbl.find env v in
          if v_ = c then updEnv env lst_ else false
      with
        Not_found -> Hashtbl.replace env v c; updEnv env lst_
      end
    | (ConstVar c, ConstVar c_) :: lst_ -> c = c_ && (updEnv env lst_)
    | [] -> true
    | _ -> false

let rec extractEnvfromVTerm env vt1 vt2 =
  match (vt1, vt2) with
    | (Bop (op1, vt11, vt12), Bop (op2, vt21, vt22)) -> op1 = op2 && (extractEnvfromVTerm env vt11 vt21) && (extractEnvfromVTerm env vt12 vt22)
    | (Uop (op1, vt1_), Uop (op2, vt2_)) -> op1 = op2 && (extractEnvfromVTerm env vt1_ vt2_)
    | (Const c1, Const c2) -> c1 = c2
    | (Var v1, Var v2) -> updEnv env [(v1, v2)]
    | (Var v, Const c) -> updEnv env [(v, ConstVar c)]
    | _ -> false


let rec extractEnvfromPred env p1 p2 =
  match (p1, p2) with
    | (And (p11, p12), And (p21, p22)) -> (extractEnvfromPred env p11 p21) && (extractEnvfromPred env p12 p22)
    | (Or (p11, p12), Or (p21, p22)) -> (extractEnvfromPred env p11 p21) && (extractEnvfromPred env p12 p22)
    | (Not p1_, Not p2_) -> extractEnvfromPred env p1_ p2_
    | (In (vars1, r1), In (vars2, r2)) -> r1 = r2 && (updEnv env (zip vars1 vars2))
    | (Only (vars1, r1), Only (vars2, r2)) -> r1 = r2 && (updEnv env (zip vars1 vars2))
    | (Equation (cop1, vt11, vt12), Equation (cop2, vt21, vt22)) ->
      cop1 = cop2 && (extractEnvfromVTerm env vt11 vt21) && (extractEnvfromVTerm env vt12 vt22)
    | _ -> false

let rec opmatch env opp op =
  match (opp, op) with
    | ([], []) -> Some env
    | (p :: opps, userop :: ops) ->
      begin
        match (p, userop) with
          | (Insert (r1, vars1), Insert (r2, vars2)) -> 
            if r1 = r2 then 
              if updEnv env (zip vars1 vars2) then opmatch env opps ops else None
            else None
          | (Delete (r1, vars1), Delete (r2, vars2)) ->
            if r1 = r2 then
              if updEnv env (zip vars1 vars2) then opmatch env opps ops else None
            else None
          | (Forall (v1, p1, ops1), Forall (v2, p2, ops2)) -> 
            begin
              if v1 = v2 then 
                let p1_ = substVarinPred p1 v1 (NamedVar "match") in
                let p2_ = substVarinPred p2 v2 (NamedVar "match") in
                (* let _ = print_endline ("p1:" ^ (string_of_pred p1_)) in
                let _ = print_endline ("p2:" ^ (string_of_pred p2_)) in *)
                if extractEnvfromPred env p1_ p2_ then
                  begin
                    match opmatch env (List.map (fun o -> substVar v1 o (NamedVar "match")) ops1) (List.map (fun o -> substVar v2 o (NamedVar "match")) ops2) with
                      | Some _ -> opmatch env opps ops
                      | None -> None
                  end
                else (print_endline "fail"; None)
              else None
            end
          | _ -> None
      end
    | _ -> None

let extractEnv opp op =
  if List.length opp = List.length op then 
    let env = Hashtbl.create 10 in
    opmatch env opp op
  else None

let findVar env v =
  match v with
    | NamedVar n -> 
      begin
        try
          ConstVar (Hashtbl.find env n)
        with
          Not_found -> v
      end
    | ConstVar _ -> v
    | AnonVar -> AnonVar

let subst env vars = List.map (findVar env) vars

let matchRcd rcd data =
  (* let _ = print_endline (String.concat "," (List.map string_of_var rcd))in
  let _ = print_endline (String.concat "," (List.map string_of_const data))in *)
  List.for_all (fun (a, b) -> 
    match (a, b) with
      | (AnonVar, _) -> true
      | (ConstVar c1, c2) -> c1 = c2
      | _ -> (raise (RuntimeErr "Unsupported in matchRcd"))
  ) (zip rcd data)

let search db r rcd =
  try
    let rel = Hashtbl.find db r in
    (* let _ = print_endline r in *)
    List.exists (matchRcd rcd) rel
  with
    Not_found -> raise (RuntimeErr ("Unknown relation " ^ r))

let uniqueSearch db r rcd =
  try
    let rel = Hashtbl.find db r in
    let aux acc x = if matchRcd rcd x then acc+1 else acc in
    (List.fold_left aux 0 rel) = 1
  with
    Not_found -> raise (RuntimeErr ("Unknown relation " ^ r))

let rec evalVTerm vt =
  match vt with
    | Const c -> c
    | Var _ -> raise (RuntimeErr "var cannot appear during evaluation")
    | Bop (op, vt1, vt2) -> 
      begin
        let v1 = evalVTerm vt1 in
        let v2 = evalVTerm vt2 in
        match (op, v1, v2) with
          | ("^", String s1, String s2) -> String (s1 ^ s2)
          | ("+", Int i1, Int i2) -> Int (i1 + i2)
          | ("-", Int i1, Int i2) -> Int (i1 - i2)
          | ("*", Int i1, Int i2) -> Int (i1 * i2)
          | ("/", Int i1, Int i2) -> Int (i1 / i2)
          | _ -> raise (RuntimeErr "Unsupported binary operation")
      end
    | Uop (op, vt_) -> 
      begin
        let v = evalVTerm vt_ in
        (* 一元操作符只有取负故此处硬编码 *)
        match v with
          | Int i -> Int (-i)
          | _ -> raise (RuntimeErr "Only integers can be negative")
      end

let rec substVTerm env vt =
  match vt with
    | Const _ -> vt
    | Var v -> 
      begin
        match findVar env v with
          | ConstVar v_ -> Const v_
          | _ -> vt
      end
    | Bop (op, vt1, vt2) -> Bop (op, substVTerm env vt1, substVTerm env vt2)
    | Uop (op, vt_) -> Uop (op, substVTerm env vt_)

let rec check db env p = 
  match p with
    | And (p1, p2) -> (check db env p1) && (check db env p2)
    | Or (p1, p2) -> (check db env p1) || (check db env p2)
    | Not p_ -> not (check db env p_)
    | In (vars, r) -> let rcd = subst env vars in (search db r rcd)
    | Only (vars, r) -> let rcd = subst env vars in (uniqueSearch db r rcd)
    | Equation (op, vt1, vt2) -> 
      let v1 = evalVTerm (substVTerm env vt1) in
      let v2 = evalVTerm (substVTerm env vt2) in
      match (op, v1, v2) with
        | ("=", _, _) -> v1 = v2
        | (">", Int i1, Int i2) -> i1 > i2
        | ("<", Int i1, Int i2) -> i1 < i2
        | (">=", Int i1, Int i2) -> i1 >= i2
        | ("<=", Int i1, Int i2) -> i1 <= i2
        | (">", String s1, String s2) -> s1 > s2
        | ("<", String s1, String s2) -> s1 < s2
        | (">=", String s1, String s2) -> s1 >= s2
        | ("<=", String s1, String s2) -> s1 <= s2
        | _ -> raise (RuntimeErr "Unsupported comparison")

let rec substPred env p =
  match p with
    | And (p1, p2) -> And ((substPred env p1), (substPred env p2))
    | Or (p1, p2) -> Or ((substPred env p1), (substPred env p2))
    | Not p_ -> Not (substPred env p_)
    | In (vars, r) -> In (subst env vars, r)
    | Only (vars, r) -> Only (subst env vars, r)
    | Equation (op, vt1, vt2) -> Equation (op, substVTerm env vt1, substVTerm env vt2)

let rec substOp env op = 
  match op with
    | Insert (r, vars) -> Insert (r, subst env vars)
    | Delete (r, vars) -> Delete (r, subst env vars)
    | Forall (pvar, p, ops) -> Forall (pvar, substPred env p, List.map (substOp env) ops)

let tryMatch db (inop, p, outop) op =
  match extractEnv inop op with
    | None -> (None)
    | Some env -> 
      if check db env p then Some (List.map (substOp env) outop) else (None)

let rec first_match db rules userop =
  match rules with
    | [] -> None
    | r :: rest ->
      match (tryMatch db r userop) with
        | Some op -> Some op
        | None -> first_match db rest userop


let execFwd db prog ops = 
  match first_match db prog.rules ops with
    | Some op -> (List.iter (fun x -> print_endline (string_of_op x)) op);op
    | None -> [] (* identity *)

let execBwd db prog ops = 
  let putRules = List.map (fun (sop, p, vop) -> (vop, p, sop)) prog.rules in
  match first_match db putRules ops with
    | Some op -> (List.iter (fun x -> print_endline (string_of_op x)) op);op
    | None -> raise (RuntimeErr "Invalid view operation")
  
let rec canMatch pat ops =
  List.exists (fun op -> 
    match (op, pat) with
      | (Insert (r1, vars1), Insert (r2, vars2)) -> (r1 = r2) && ((List.length vars1) = (List.length vars2))
      | (Delete (r1, vars1), Delete (r2, vars2)) -> (r1 = r2) && ((List.length vars1) = (List.length vars2))
      | (Forall (v, p, fops), _) -> canMatch pat fops
      | _ -> false
      (* forall查到最里面一层的op list有没有可能和它match上 *)
  ) ops

let findMatch rules op =
  List.filter (fun (a, _, _) -> canMatch op a) rules

let rec extractEnvPart env ops op =
  match (op, ops) with
    | (_, []) -> None
    | (Insert (r1, vars1), (Insert (r2, vars2)) :: ops_) -> 
        if r1 = r2 && (updEnv env (zip vars2 vars1)) 
          then Some ops_
        else (Hashtbl.reset env; 
        match extractEnvPart env ops_ op with
          | Some res -> Some ((Insert (r2, vars2)) :: ops_)
          | _ -> None)
    | (Delete (r1, vars1), (Delete (r2, vars2)) :: ops_) -> 
        if r1 = r2 && (updEnv env (zip vars2 vars1)) 
          then Some ops_ 
        else (Hashtbl.reset env; 
        match extractEnvPart env ops_ op with
          | Some res -> Some ((Delete (r2, vars2)) :: ops_)
          | _ -> None)
    | (_, o :: ops_) -> 
      begin
        match extractEnvPart env ops_ op with
          | Some res -> Some (o :: ops_)
          | _ -> None
      end

let rec canMatchOP env o ops =
  match (o, ops) with
    | (_, []) -> None
    | (Insert (r1, vars1), (Insert (r2, vars2)) :: ops_) ->
      if r1 = r2 then 
        let snap = restore env in
        if updEnv env (zip vars1 vars2) then Some (Insert (r2, vars2), ops_) else (copy env snap; canMatchOP env o ops_)
      else canMatchOP env o ops_
    | (Delete (r1, vars1), (Delete (r2, vars2)) :: ops_) ->
      if r1 = r2 then 
        let snap = restore env in
        if updEnv env (zip vars1 vars2) then Some (Delete (r2, vars2), ops_) else (copy env snap; canMatchOP env o ops_)
      else canMatchOP env o ops_
    | (_, op :: ops_) -> canMatchOP env o ops_

let rec tryOP oppRemain env ops =
  match oppRemain with
    | [] -> ([], [])
    | o :: opp ->
        match canMatchOP env o ops with
          | Some (matchedOP, restOP) -> let (matchedPats, matchedOPs) = tryOP opp env restOP in (o :: matchedPats, matchedOP :: matchedOPs)
          | None -> ([], [])

 (* insert可以用any值来替代，delete的时候要猜就得把后面的可能的变量一起猜了或者检查是不是符合要求 *)

let rec assignVarsfromIns vars env assignedEnv =
  match vars with
    | [] -> ([], false)
    | v :: vs -> 
      match v with
        | NamedVar n -> 
          begin
            try
              let value = Hashtbl.find env n in
              let (assignedVars, haveAssign) = assignVarsfromIns vs env assignedEnv in 
              ((ConstVar value) :: assignedVars, haveAssign)
            with
              Not_found -> 
                (* 没找到需要在assign里面找 *)
                begin
                  try
                    let assignedVal = Hashtbl.find assignedEnv n in
                    let (assignedVars, haveAssign) = assignVarsfromIns vs env assignedEnv in
                    ((ConstVar assignedVal) :: assignedVars, true)
                  with
                    Not_found ->
                      let _ = Hashtbl.replace assignedEnv n (String "any") in
                      let (assignedVars, haveAssign) = assignVarsfromIns vs env assignedEnv in
                      ((ConstVar (String "any")) :: assignedVars, true)
                end
          end
        | ConstVar c -> let (assignedVars, haveAssign) = assignVarsfromIns vs env assignedEnv in (v :: assignedVars, haveAssign)
        | _ -> raise (RuntimeErr "Unsupported variable in ins")

let rec matchwithRcd pat d =
  match (pat, d) with
    | ([], []) -> true
    | ((ConstVar c1) :: pats, c2 :: ds) -> c1 = c2 && (matchwithRcd pats ds)
    | (AnonVar :: pats, c :: ds) -> (matchwithRcd pats ds)
    | _ -> false

let rec firstMatchRcd datas pat =
  match datas with
    | [] -> raise AssignErr
    | d :: ds -> if matchwithRcd pat d then d else firstMatchRcd ds pat

let rec assignVarsfromDel datas vars env assignedEnv haveMatch =
  match vars with
    | [] -> ([], false)
    | v :: vs ->
      match v with
        | NamedVar n -> 
          begin
            try
              let value = ConstVar (Hashtbl.find env n) in
              let (assignedVars, haveAssign) = assignVarsfromDel datas vs env assignedEnv (haveMatch @ [value]) in 
              (value :: assignedVars, haveAssign)
            with
              Not_found -> 
                (* 没找到需要在assign里面找 *)
                begin
                  try
                    let assignedVal = ConstVar (Hashtbl.find assignedEnv n) in
                    let (assignedVars, haveAssign) = assignVarsfromDel datas vs env assignedEnv (haveMatch @ [assignedVal]) in
                    (assignedVal :: assignedVars, true)
                  with
                    Not_found ->
                      begin
                        let (assignedVars, haveAssign) = assignVarsfromDel datas vs env assignedEnv (haveMatch @ [AnonVar]) in
                        try
                          let assignedValue = Hashtbl.find assignedEnv n in
                          ((ConstVar assignedValue) :: assignedVars, true)
                        with
                          | Not_found ->
                              let pat = haveMatch @ (AnonVar :: assignedVars) in
                              let matchedRcd = firstMatchRcd datas pat in
                              let varValue = nth (List.length haveMatch) matchedRcd in
                              let _ = Hashtbl.replace assignedEnv n varValue in
                              ((ConstVar varValue) :: assignedVars, true)
                      end
                end
          end
        | ConstVar c -> let (assignedVars, haveAssign) = assignVarsfromIns vs env assignedEnv in (v :: assignedVars, haveAssign)
        | _ -> raise (RuntimeErr "Unsupported variable in del")


let rec tryAssignOP db env assignedEnv ops =
  match ops with
    | [] -> ([], [])
    | (Insert (r, vars)) :: ops_ ->
      let (assignedVars, haveAssign) = assignVarsfromIns vars env assignedEnv in
      if haveAssign then 
        let (usedOP, canceledOPs) = tryAssignOP db env assignedEnv ops_ in
        ((Insert (r, assignedVars)) :: usedOP, (Delete (r, assignedVars)) :: canceledOPs)
      else 
        let (usedOP, canceledOPs) = tryAssignOP db env assignedEnv ops_ in
        ((Insert (r, assignedVars)) :: usedOP, canceledOPs)
    | (Delete (r, vars)) :: ops_ ->
      let (assignedVars, haveAssign) = assignVarsfromDel (getRel db r) vars env assignedEnv [] in
      if haveAssign then 
        let (usedOP, canceledOPs) = tryAssignOP db env assignedEnv ops_ in
        ((Delete (r, assignedVars)) :: usedOP, (Insert (r, assignedVars)) :: canceledOPs)
      else 
        let (usedOP, canceledOPs) = tryAssignOP db env assignedEnv ops_ in
        ((Delete (r, assignedVars)) :: usedOP, canceledOPs)
    | _ -> raise (RuntimeErr "Unsupported operation forall")

let rec deleteSharedOP ops usedops =
  match usedops with
    | [] -> ops
    | o :: usedops_ ->
      deleteSharedOP (List.filter (fun op -> not (o = op)) ops) usedops_

let rec extractEnvfromVarsinForall env lst =
  match lst with 
    | [] -> ()
    | (NamedVar n, ConstVar c) :: lst_ -> 
      begin
        try
          let v = Hashtbl.find env n in
          if v = c then extractEnvfromVarsinForall env lst_
          else raise AssignErr
        with
          Not_found -> Hashtbl.replace env n c; extractEnvfromVarsinForall env lst_
      end
    | _ -> raise AssignErr

let rec findMatchedEnv env path fops op =
  match (fops, op) with
    | ([], _) -> None
    | ((Insert (r1, vars1)) :: ops, Insert (r2, vars2)) ->
      begin
        try
          if r1 = r2 then (extractEnvfromVarsinForall env (zip vars1 vars2); Some path)
          else findMatchedEnv env path ops op
        with
          AssignErr -> Hashtbl.reset env; findMatchedEnv env path ops op
      end
        (* 如果都是insert试着找一下environment，失败了就回退environment匹配下一个，成功直接就返回
        如果forall就在里面找一下 *)
    | ((Delete (r1, vars1)) :: ops, Delete (r2, vars2)) ->
      begin
        try
          if r1 = r2 then (extractEnvfromVarsinForall env (zip vars1 vars2); Some path)
          else findMatchedEnv env path ops op
        with
          AssignErr -> Hashtbl.reset env; findMatchedEnv env path ops op
      end
    | ((Forall ((NamedVar v), p, fops_)) :: ops, _) -> 
      begin
        match findMatchedEnv env (v :: path) fops_ op with
          | None -> findMatchedEnv env path ops op
          | Some path_ -> Some path_
      end
    | (o :: ops, _) -> findMatchedEnv env path ops op

let rec genOPfromForall db env op =
  (* let _ = print_endline (string_of_op op) in *)
  (* let _ = print_db db in *)
  (* let _ = Hashtbl.iter (fun k v -> print_endline (k ^ ": " ^ (string_of_const v))) env in *)
  match op with
    | Forall (pvar, p, fops) -> 
      begin
      let vs = List.map (fun c -> ConstVar c) (collectVal db pvar p) in
      (* let _ = print_endline ("vals:" ^ (String.concat "," (List.map string_of_var vs))) in *)
      let ops = List.concat (List.map (fun v -> List.map (fun o -> substVar pvar o v) fops) vs) in
      List.concat (List.map (genOPfromForall db env) ops)
      end
    | Insert (r, vars) -> [Insert (r, subst env vars)]
    | Delete (r, vars) -> [Delete (r, subst env vars)]

let rec tryRules db splitTime matchedRules rules op ops isFwd =
  (* let _ = print_endline (string_of_op op) in
  let _ = print_endline (String.concat "\n" (List.map string_of_rule matchedRules)) in *)
  (* let _ = print_endline ("try") in *)
  match matchedRules with
    | [] -> (false, [])
    | ([Forall (v, p, fops)], pred, opso) :: rs ->
      begin
        try
          let env = Hashtbl.create 10 in
          match findMatchedEnv env [] [Forall (v, p, fops)] op with
            | Some path ->
              let _ = List.iter (Hashtbl.remove env) path in
              (* let _ = Hashtbl.iter (fun k v -> print_endline (k ^ ":" ^ (string_of_const v))) env in *)
              let actop = substOp env (Forall (v, p, fops)) in
              let allop = genOPfromForall db env actop in
              (* let _ = print_endline (String.concat "," (List.map string_of_op allop)) in *)
              (* let _ = print_endline "111" in *)
              if (List.for_all (fun o -> List.mem o (op :: ops)) allop) && (check db env pred) then
                (* let _ = print_endline "222" in *)
                let snap = restore db in
                let remains = deleteSharedOP ops allop in
                let corop = List.map (substOp env) opso in
                let execops = if isFwd then corop @ allop else allop @ corop in
                let _ = List.iter (apply db) execops in
                match (searchpath db splitTime rules remains isFwd) with
                  | (true, res) -> (true, corop @ res)
                  | (false, _) -> copy db snap; tryRules db splitTime rs rules op ops isFwd
              else
                tryRules db splitTime rs rules op ops isFwd
            | None -> tryRules db splitTime rs rules op ops isFwd
    (* 找好environment之后就试着把pattern 变量都找出来从environment里删掉，然后按forall语义生成所有需要的操作，看是不是都执行了，没有的话就不考虑这条规则了
            forall先做pattern matching找到env，不考虑找到environment失败的情况，然后找到所有可能取值的operation，看是不是所有op都存在，如果不是就直接跳过这条规则 *)
        with
          AssignErr -> tryRules db splitTime rs rules op ops isFwd
      end
    | (opsi, p, opso) :: rs ->
      let env = Hashtbl.create 10 in 
      match extractEnvPart env opsi op with
        | None -> tryRules db splitTime rs rules op ops isFwd
        | Some opRemain -> 
          begin
            try
              let (matchedPats, matchedOPs) = tryOP opRemain env ops in
              let assignedEnv = Hashtbl.create 10 in
              let (usedOP, canceledOPs) = tryAssignOP db env assignedEnv opsi in
              let completeenv = mergeEnv env assignedEnv in
              if check db env p then 
                let remains = deleteSharedOP ops usedOP in
                            (* let _ = print_endline (String.concat "," (List.map string_of_op remains)) in
                            let _ = print_endline (String.concat "," (List.map string_of_op ops)) in *)
                let snap = restore db in
                let corop = List.map (substOp env) opso in
                let execops = if isFwd then corop @ usedOP else usedOP @ corop in
                let _ = List.iter (apply db) execops in
                match (searchpath db (splitTime + (List.length canceledOPs)) rules (canceledOPs @ remains) isFwd) with
                  | (true, res) -> (true, corop @ res)
                  | (false, _) -> copy db snap; tryRules db splitTime rs rules op ops isFwd
              else
                tryRules db splitTime rs rules op ops isFwd
            with
              AssignErr -> tryRules db splitTime rs rules op ops isFwd
          end
          (* 找到了一个匹配上的内容，然后要尝试给没匹配上的赋值
          赋值之后要check predicates
          如果通过了那这个就用上了，把没匹配上的cancel op加到剩下的op里，然后继续searchpath，成功了就加上现在的操作然后直接返回，失败了就尝试下一条rule
          返回的是output的delta而不是input *)

and searchpath db splitTime rules ops isFwd =
  match (splitTime, ops) with
    | (_, []) -> (true, [])
    | (n, op :: ops_) ->
      begin
        if n > 3 then (false, []) else
        let snap = restore db in
        let matchedRules = findMatch rules op in
        match (tryRules db splitTime matchedRules rules op ops_ isFwd) with
          | (true, res) -> (true, res)
          | (false, _) -> copy db snap; (false, [])
      end
(* 这些都不动，加一个根据rule decompose的算法 *)
(* 如果backward返回none那么就是错了 forward返回none就贪心（尽可能消耗掉所有op）直到最大限度然后剩下的以id处理 *)

let fwdDiff dbold dbnew prog =
  let ops = diff_db dbold dbnew prog.source in
  (* let _ = List.iter (fun x -> print_endline (string_of_op x)) ops in *)
  match searchpath dbold 0 prog.rules ops true with
    | (true, res) -> (List.iter (fun x -> print_endline (string_of_op x)) res)
    | (false, _) -> (List.iter (apply dbold) ops); print_endline "No update of view"
    (* 现在就不做复杂partition了，没找到匹配的所有的operation都认为是没有match *)

let bwdDiff dbold dbnew prog =
  let ops = diff_db dbold dbnew [prog.view] in
  (* let _ = List.iter (fun x -> print_endline (string_of_op x)) ops in *)
  let brules = List.map (fun (a, b, c) -> (c, b, a)) prog.rules in
  match searchpath dbold 0 brules ops false with
    | (true, res) -> (List.iter (fun x -> print_endline (string_of_op x)) res)
    | (false, _) -> (print_endline "invalid operation of view")