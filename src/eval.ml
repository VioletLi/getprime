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
  List.for_all (fun (a, b) -> 
    match (a, b) with
      | (AnonVar, _) -> true
      | (ConstVar c1, c2) -> c1 = c2
      | _ -> raise (RuntimeErr "Unsupported in matchRcd")
  ) (zip rcd data)

let search db r rcd =
  try
    let rel = Hashtbl.find db r in
    List.exists (matchRcd rcd) rel
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
    | Equation (op, vt1, vt2) -> 
      let v1 = evalVTerm (substVTerm env vt1) in
      let v2 = evalVTerm (substVTerm env vt2) in
      match (op, v1, v2) with
        | ("=", _, _) -> v1 = v2
        | (">", Int i1, Int i2) -> i1 > i2
        | ("<", Int i1, Int i2) -> i1 < i2
        | (">=", Int i1, Int i2) -> i1 >= i2
        | ("<=", Int i1, Int i2) -> i1 <= i2
        | _ -> raise (RuntimeErr "Unsupported comparison")

let rec substPred env p =
  match p with
    | And (p1, p2) -> And ((substPred env p1), (substPred env p2))
    | Or (p1, p2) -> Or ((substPred env p1), (substPred env p2))
    | Not p_ -> Not (substPred env p_)
    | In (vars, r) -> In (subst env vars, r)
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
  