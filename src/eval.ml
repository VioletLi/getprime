open Expr
open Utils

(* matching 首先规则中的op个数和rule中op个数要对得上，其次每一个对应位置的op要对得上，然后产生一个environment，合并的时候不能产生冲突；用这个environment和db一起去check predicate，通过了才能判定这个规则match上了，否则这条就没match上；match上之后要subst被trigger的op *)
let rec updEnv env lst =
  match lst with
    | (NamedVar v, ConstVar c) :: lst_ ->
      begin
      try
        if v = "match" then false else
          let v_ = Hashtbl.find env v in
          if v_ = c then updEnv env lst_ else false
      with
        Not_found -> Hashtbl.replace env v c; updEnv env lst_
      end
    | (NamedVar "match", NamedVar "match") :: lst_ -> updEnv env lst_
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
                let env = Hashtbl.create 10 in
                if extractEnvfromPred env p1 p2 then
                  begin
                    match opmatch env ops1 ops2 with
                      | Some _ -> opmatch env opps ops
                      | None -> None
                  end
                else None
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

let check db env p = true

let subst env op = op

let tryMatch db (inop, p, outop) op =
  match extractEnv inop op with
    | None -> None
    | Some env -> 
      if check db env p then Some (subst env outop) else None

let rec first_match db rules userop =
  match rules with
    | [] -> None
    | r :: rest ->
      match (tryMatch db r userop) with
        | Some op -> Some userop
        | None -> first_match db rest userop


let execFwd db prog ops = 
  match first_match db prog.rules ops with
    | Some op -> op
    | None -> [] (* identity *)

let execBwd db prog ops = 
  let putRules = List.map (fun (sop, p, vop) -> (vop, p, sop)) prog.rules in
  match first_match db putRules ops with
    | Some op -> op
    | None -> raise (RuntimeErr "Invalid view operation")
  