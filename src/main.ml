open Expr
open Lexing
open Parser
open Utils
open Eval
(* open Verifier
open Generator
open Fuser *)
open Sys

let rec repl db prog =
  print_string "> ";
  flush stdout;
  match read_line () with
    | "exit" -> print_endline "EXIT"
    | exception End_of_file -> ()  (* Ctrl+D 退出 *)
    | "show" -> print_db db; repl db prog
    | "fwd" ->
      let line = read_line () in
      let ops = Parser.parse_userops Lexer.token (Lexing.from_string line) in
      let vops = execFwd db prog ops in
      List.iter (fun op -> apply db op) (vops @ ops);
      (* print_string (String.concat "; " (List.map string_of_op vops));  *)
      repl db prog
    | "bwd" ->
      let line = read_line () in
      let ops = Parser.parse_userops Lexer.token (Lexing.from_string line) in
      let sops = execBwd db prog ops in
      List.iter (fun op -> apply db op) (ops @ sops);
      (* print_string (String.concat "; " (List.map string_of_op ops));  *)
      repl db prog
    (* | "db" ->
      let line = read_line () in
      let datas = Parser.parse_db Lexer.token (Lexing.from_channel (open_in line)) in
      let newdb = genDB (prog.view :: prog.source) datas in
      print_db newdb; repl db prog *)
    | "fwd_diff" ->
      let line = read_line () in
      let datas = Parser.parse_db Lexer.token (Lexing.from_channel (open_in line)) in
      let newdb = genDB prog.source datas in
      (* let op = diff_db db newdb prog.source in
      print_string (String.concat "; " (List.map string_of_op op));  *)
      fwdDiff db newdb prog;
      repl db prog
    | "bwd_diff" ->
      let line = read_line () in
      let datas = Parser.parse_db Lexer.token (Lexing.from_channel (open_in line)) in
      let newdb = genDB [prog.view] datas in
      (* let op = diff_db db newdb [prog.view] in
      print_string (String.concat "; " (List.map string_of_op op));  *)
      bwdDiff db newdb prog;
      repl db prog
    | _ -> repl db prog

let _ = 
  let lexbuf = Lexing.from_channel (open_in Sys.argv.(1)) in
  let prog = Parser.main Lexer.token lexbuf in
  let _ = print_string (to_string prog) in
  let _ = print_string "\n Finish Initialization\n" in
  repl (createDB prog) prog

(* let _ =
  let lexbuf = Lexing.from_channel (open_in Sys.argv.(1)) in
  let prog = Parser.main Lexer.token lexbuf in
  try
    let expr = preProcessProg prog in
    let disjoint_start = Unix.gettimeofday() in
    let disjointCode = genDisjointCode expr in
    let exitcode1, message1 = verify_fo_lean false 300 disjointCode in
    if exitcode1 = 0 then
      begin
        let disjoint_end = Unix.gettimeofday() in
        let disjoint_time = disjoint_end -. disjoint_start in
        let _ = Printf.printf "Verification of non-contradictory time: %f seconds\n" disjoint_time in
        let inj_start = Unix.gettimeofday() in
        let injectiveCode = genInjectiveCode expr in
        let exitcode2, message2 = verify_fo_lean false 300 injectiveCode in
        if exitcode2 = 0 then
          begin
            let inj_end = Unix.gettimeofday() in
            let inj_time = inj_end -. inj_start in
            let _ = Printf.printf "Verification of injectivity time: %f seconds\n" inj_time in
            let pre_start = Unix.gettimeofday() in
            let fusedrule = fuseRules expr in
            let pre_end = Unix.gettimeofday() in
            let pre_time = pre_end -. pre_start in
            let _ = Printf.printf "Compose Rules time: %f seconds\n" pre_time in
            (* let fusecode = String.concat "" (List.map string_of_rule (List.concat (List.map crule2rules fusedrule))) in
            let vc3 = open_out "/home/code/fuse.dl" in
            Printf.fprintf vc3 "%s\n" fusecode;
            close_out vc3; *)
            let code = genCode expr fusedrule in
            let _ = print_string "Generation finished\n" in
            let oc = open_out "./result.dl" in
            Printf.fprintf oc "%s\n" code;
            close_out oc;
            (* Sys.command "birds -f /home/code/temp.dl -v -o result.sql"; *)
          end
        else raise (VerificationErr ("This program is not injective, the message from lean is: " ^ message2))
      end
    else raise (VerificationErr ("This program is contradictory (disjoint of insertion and deletion), the message from lean is: " ^ message1))
    (* Sys.command "rm /home/code/temp.dl"; *)
  with
    | VerificationErr s -> print_string ("Verification Error: " ^ s); exit 0;
    | GenerationErr s   -> print_string ("Generation Error: " ^ s); exit 0; *)