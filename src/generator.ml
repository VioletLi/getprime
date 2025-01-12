open Expr
open Utils

let getKey head = 
  match head with 
    | Pred (name, attrs) -> (name, List.length attrs)
    | _ -> raise (GenerationErr "The key must be a normal rule head")

(* let pred2rule name varlist =
  let newvarlist = List.mapi (fun i x -> (NamedVar ("X" ^ (string_of_int i)))) varlist in
  let rulehead = Pred ((name ^ "0"), newvarlist)
  in
  (rulehead, (List.map2 (fun a b -> (Equat (Equation ("=", (Var a), (Var b))))) newvarlist varlist))

let insertInistateRule table r =
  match r with
    | Pred (name, varlist) ->
        let key = (name, List.length varlist) in
        if Hashtbl.mem table key then
          Hashtbl.replace table key ((Hashtbl.find table key)@[pred2rule name varlist])
        else
          raise (GenerationErr ("No corresponding source/view definition " ^ name ^ ".\n"))
    | _ -> raise (GenerationErr "There can only be ground atoms in the definition of initial state.\n") *)

(* let extractSchema expr = 
  let table:symtable = Hashtbl.create (2 * (List.length expr.sources) + 2) in
  match expr.view with
      | Some v -> 
          Hashtbl.add table (getKey v) []; 
          List.iter (fun x -> Hashtbl.add table (getKey x) []) expr.sources;
          match expr.initial_state with
              | Some l -> 
                  List.iter (insertInistateRule table) l;
                  table
              | None -> table
      | None -> raise (GenerationErr "No view definition") *)

(* let iniOfRelation (name, varlist) =
  let 
    varlist_ = List.map (fun (x, _) -> (NamedVar x)) varlist
  in
  string_of_rterm (Pred (name ^ "0", varlist_))


let genIniCode table sources =
  String.concat "" (List.map (fun s -> 
    let rules = Hashtbl.find table (getKey s) in
    match rules with
        | [] -> 
          ((fun (name, lst) -> "source " ^ name ^ "0" ^ "(" ^ String.concat ", " (List.map (fun (col,typ) -> "'"^col^"':"^ (string_of_stype typ)) lst) ^ ").\n" ) s) ^ "_|_ :- " ^ (iniOfRelation s) ^ ".\n"
        | _ -> String.concat "" (List.map (fun r -> (string_of_rule r)) rules))
    sources) *)

let find_relation name iniRelations = 
  List.fold_right (||) (List.map (fun (n, _) -> String.equal name n) iniRelations) false

let genIniRules expr iniRelations =
  let table:symtable = Hashtbl.create (List.length iniRelations) in
  let insertInistateRule (head, body) =
    let (name, attrs) = getKey head in
    if find_relation name iniRelations then 
      let key = (name, attrs) in
      if Hashtbl.mem table key then
        Hashtbl.replace table key ((Hashtbl.find table key) @ [(head, body)])
      else Hashtbl.add table key [(head, body)]
    else raise (GenerationErr "Only initial relations can be calculated in initial state.")
  in
  let genRules (name, attrs) =
    let key = (name, List.length attrs) in
    if Hashtbl.mem table key then (Hashtbl.find table key, ("", [])) else ([(get_empty_pred, [Rel (Pred (name, List.map (fun x -> AnonVar) attrs))])], (name, attrs))
  in
  List.map insertInistateRule expr.initial_state;
  let inirules = List.map genRules iniRelations in
  (List.concat (List.map (fun (r, _) -> r) inirules), List.concat (List.map (fun (_, (name, attrs)) -> if name = "" then [] else [(name, attrs)]) inirules))

  
(* let genSourceDelta (name, varlist) =
  let newvarlist = List.map (fun (name, _) -> NamedVar name) varlist in
  let insRule = (Pred (name ^ "_ins", newvarlist), [Rel (Pred (name, newvarlist));Not (Pred (name ^ "0", newvarlist))]) in
  let delRule = (Pred (name ^ "_del", newvarlist), [Rel (Pred (name ^ "0", newvarlist));Not (Pred (name, newvarlist))]) in
    [insRule; delRule]

let genPreDatalog expr = 
  String.concat "" (List.map string_of_rule (List.concat (List.map genSourceDelta expr.sources))) *)

let extractConstraint expr = 
  let filteredConstraints = List.map (fun (r, ts) -> (rterm2noDelta r, List.map term2noDelta ts)) expr.constraints
  in filteredConstraints
  (* String.concat "" (List.map string_of_constraint filteredConstraints) *)

(* let source2initial names t =
  match t with
      | Rel r -> let resTerm = 
          match r with
            | Pred (name, varlist) -> 
                let e = List.find_opt ((=) name) names in
                let res = 
                  match e with 
                      | Some _ -> Rel (Pred (name ^ "0", varlist))
                      | _ -> t
                in res
            | _ -> t
          in resTerm
      | Not r -> let resTerm = 
          match r with
            | Pred (name, varlist) -> 
                let e = List.find_opt ((=) name) names in
                let res = 
                  match e with 
                      | Some _ -> Not (Pred (name ^ "0", varlist))
                      | _ -> t
                in res
            | _ -> t
        in resTerm
      | _ -> t *)

(* let modifyTerms sourceNames (head, body) =
  (rterm2noDelta head, List.map term2noDelta (List.map (source2initial sourceNames) body)) *)

let rec findV vn is =
  match is with
    | [] -> (None, [])
    | t :: ts -> 
      let (resv, rests) = findV vn ts in
      match t with
        | Rel rt -> begin
            match rt with
              | Pred (name, _) -> 
                  if name = vn then 
                    match resv with
                      | Some _ -> raise (GenerationErr "There should be only one view atom in an IS definition.")
                      | None -> (Some rt, rests)
                  else
                    (resv, t :: rests)
              | _ -> raise (GenerationErr "No delta operation in IS definition")
            end 
        | _ -> (resv, t :: rests)

let genDelta sourceRelations =
  List.concat (List.map (fun (sn, attrs) ->
    let varlist = List.map (fun (n, _) -> NamedVar n) attrs in
    [ (Pred (sn^"_ins", varlist), [Rel (Pred (sn, varlist)); Not (Pred (sn^"0", varlist))])
    ; (Pred (sn^"_del", varlist), [Rel (Pred (sn^"0", varlist)); Not (Pred (sn, varlist))])]
  ) sourceRelations)

let replaceSAndDelta rules =
  List.map (fun (head, body) ->
    (head, List.map (fun t ->
      match t with
        | Rel r -> 
            begin
              match r with
                | Deltainsert (sn, varlist) -> Rel (Pred (sn^"_ins", varlist))
                | Deltadelete (sn, varlist) -> Rel (Pred (sn^"_del", varlist))
                | Pred (sn, varlist)        -> Rel (Pred (sn^"0", varlist))
            end
        | Not r ->
          begin
            match r with
              | Deltainsert (sn, varlist) -> Not (Pred (sn^"_ins", varlist))
              | Deltadelete (sn, varlist) -> Not (Pred (sn^"_del", varlist))
              | Pred (sn, varlist)        -> Not (Pred (sn^"0", varlist))
          end
        | _ -> t
    ) body)
  ) rules

let replaceVDelta rules =
  List.map (fun (head, body) ->
    match head with
      | Deltainsert (n, attrs) -> (Pred (n^"_ins", attrs), body)
      | Deltadelete (n, attrs) -> (Pred (n^"_del", attrs), body)
      | _ -> (head, body)
  ) rules

let getvn view = 
  match view with
    | Some (vn, attrs) -> (vn, List.map (fun (n, _) -> NamedVar n) attrs)
    | None -> raise (GenerationErr "No view definition")

let genGetRules expr fuserules =
  if is_empty expr.get_rules then
    let (vn, varlist) = getvn expr.view in
    let rules = expr.rules @ (List.concat (List.map crule2rules fuserules)) in
    let getPrimeRules = replaceSAndDelta rules in
    [ (Pred (vn, varlist), [Rel (Pred (vn^"0", varlist)); Not (Pred (vn^"_del", varlist))])
    ; (Pred (vn, varlist), [Rel (Pred (vn^"_ins", varlist))])] @ (genDelta expr.sources) @ (replaceVDelta getPrimeRules)
  else expr.get_rules

let rec findDelta ls =
  match ls with
      | [] -> ([], [])
      | t :: ts -> 
          let (deltas, nondeltas) = findDelta ts in
          match t with
            | Rel rt -> 
                begin
                  match rt with
                    | Pred _ -> (deltas, t :: nondeltas)
                    | _ -> (t :: deltas, nondeltas)
                end
            | Not rt ->
                begin
                  match rt with
                    | Pred _ -> (deltas, t :: nondeltas)
                    | _ -> (deltas, nondeltas)
                end
            | _ -> (deltas, t :: nondeltas)

let getInvRule (vn, varlist) (head, body) =
  let (deltas, remain) = findDelta body in
  match deltas with
      | [] -> (head, body)
      | _  -> (deltas, head @ remain)
  (* canUpdate中每一个key是一个view中的变量 如果可以被update就置为true 如果这条规则的head只有一个操作那么在swap之后要把对应位为true的变量置为匿名变量并加not 这样的反操作加到里面 *)

let genInvRules fuserules (vn, varlist) =
  List.map (getInvRule (vn, varlist)) fuserules

let replaceV2IniDelta (h, b) =
  (List.map (fun p ->
    match p with
      | Rel x ->
        begin
          match x with
            | Deltainsert (vn, attrs) -> Rel (Pred (vn ^ "_ini_ins", attrs))
            | Deltadelete (vn, attrs) -> Rel (Pred (vn ^ "_ini_del", attrs))
            | _ -> p
        end
      | Not x ->
        begin
          match x with
            | Deltainsert (vn, attrs) -> Not (Pred (vn ^ "_ini_ins", attrs))
            | Deltadelete (vn, attrs) -> Not (Pred (vn ^ "_ini_del", attrs))
            | _ -> p
        end
  ) h, b)

let renameV2Ini r = 
  match r with
    | Pred (n, var) -> Pred (n ^ "_ini", var)
    | _ -> raise (GenerationErr "Only view can be head of get rules")

let diffVDelta rules fuserules =
  if is_empty fuserules then List.map rule2crule rules
  else
    let vdeltaRules, other = List.partition isDeltaRule rules in
    let vdeltas = List.map (fun (h, _) -> h) fuserules in
    let startList = List.map (fun _ -> true) (get_rterm_varlist (unpack_term (List.nth (List.nth vdeltas 0) 0))) in
    let insDiff = List.fold_left (fun acc a -> let var1 = get_rterm_varlist (unpack_term (List.nth a 0)) in let var2 = get_rterm_varlist (unpack_term (List.nth a 1)) in let update = List.map (fun (a, b) -> a = b) (List.combine var1 var2) in List.map (fun (a, b) -> a && b) (List.combine acc update)) startList vdeltas in
    let diffRules = List.map (fun (h, b) -> let varlist = get_rterm_varlist h in let newvarlist = List.map (fun (a, b) -> if b then a else AnonVar) (List.combine varlist insDiff) in let newhead = if isInsertDelta h then Not (Deltadelete (getDeltaRelationName h, newvarlist)) else Not (Deltainsert (getDeltaRelationName h, newvarlist)) in ([Rel h; newhead], b)) vdeltaRules in
    diffRules @ (List.map rule2crule other) @ fuserules

let genPutdeltaRules expr fuserules = 
  let ruleswithDeltaDiff = diffVDelta expr.rules fuserules in
  if is_empty expr.get_rules then
    let (vn, varlist) = getvn expr.view in
    let viniRules =
      [ (Pred (vn^"_ini", varlist), [Rel (Pred (vn^"0", varlist)); Not (Pred (vn^"_del", varlist))])
      ; (Pred (vn^"_ini", varlist), [Rel (Pred (vn^"_ins", varlist))])]
    in
    let viniDeltaRules =
      [ (Pred (vn^"_ini_ins", varlist), [Rel (Pred (vn, varlist)); Not (Pred (vn^"_ini", varlist))])
      ; (Pred (vn^"_ini_del", varlist), [Rel (Pred (vn^"_ini", varlist)); Not (Pred (vn, varlist))])]
    in
    let rules =  List.map replaceV2IniDelta ruleswithDeltaDiff in
    let invRules = genInvRules rules (vn, varlist) in
    let unpackedRules = List.concat (List.map crule2rules invRules) in
    viniRules @ viniDeltaRules @ unpackedRules
  else
    let (vn, varlist) = getvn expr.view in
    let viniRules = List.map (fun (h, b) -> (renameV2Ini h, b)) expr.get_rules in
    let viniDeltaRules =
      [ (Pred (vn^"_ini_ins", varlist), [Rel (Pred (vn, varlist)); Not (Pred (vn^"_ini", varlist))])
      ; (Pred (vn^"_ini_del", varlist), [Rel (Pred (vn^"_ini", varlist)); Not (Pred (vn, varlist))])]
    in
    let rules =  List.map replaceV2IniDelta ruleswithDeltaDiff in
    let invRules = genInvRules rules (vn, varlist) in
    let unpackedRules = List.concat (List.map crule2rules invRules) in
    viniRules @ viniDeltaRules @ unpackedRules


let genIniRelation rs =
  List.map (fun (name, attrs)->(name ^ "0", attrs)) rs

let genCode expr fuserules = 
  let v = match expr.view with
    | Some view -> view
    | None -> raise (GenerationErr "No view Definition")
  in
  let iniRelation = genIniRelation (expr.sources @ [v]) in
  let (inistateRules, needIniSources) = genIniRules expr iniRelation in
  (* let svDef = 
    (List.fold_right (^) (List.map string_of_source (expr.sources @ needIniSources)) "") ^ (string_of_view v)
  in *)
  (* let inistateCode = String.concat "" (List.map string_of_rule inistateRules) in *)
  let updatedConstraints = extractConstraint expr in
  let getRules = genGetRules expr fuserules in
  (* let get = String.concat "" (List.map string_of_rule getRules) in *)
  let putdeltaRules = genPutdeltaRules expr fuserules in
  (* let putdelta = String.concat "" (List.map string_of_rule putdeltaRules) in *)
  let newexpr = { expr with
    sources = expr.sources @ needIniSources;
    constraints = updatedConstraints;
    rules =  inistateRules @ getRules @ putdeltaRules
  } in
  to_birds_string newexpr
    (* "% schema definition\n" ^ svDef ^ "\n% initial state\n" ^ inistateCode ^ "% constraints\n" ^ constraints ^ "\n% get\n" ^ get ^ "\n% putdelta\n" ^ putdelta *)


