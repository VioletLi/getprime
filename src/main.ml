open Expr
open Lexing
open Parser
open Utils
open Verifier
open Generator
open Sys

let _ =
  let lexbuf = Lexing.from_channel (open_in Sys.argv.(1)) in
  let expr = Parser.main Lexer.token lexbuf in
  try
    let disjointCode = genDisjointCode expr in
    let vc1 = open_out "/home/code/disjoint.lean" in
    Printf.fprintf vc1 "%s\n" disjointCode;
    close_out vc1;
    let injectiveCode = genInjectiveCode expr in
    let vc2 = open_out "/home/code/injective.lean" in
    Printf.fprintf vc2 "%s\n" injectiveCode;
    close_out vc2;
    let composedrule = compose expr in
    let composecode = String.concat "" (List.map string_of_rule (List.concat (List.map crule2rules composedrule)))
    let vc3 = open_out "/home/code/compose.dl" in
    Printf.fprintf vc3 "%s\n" composecode;
    close_out vc3;
    let code = genCode expr in
    let _ = print_string "Generation finished\n" in
    let oc = open_out "/home/code/temp.dl" in
    Printf.fprintf oc "%s\n" code;
    close_out oc;
    Sys.command "birds -f /home/code/temp.dl -v -o result.sql";
    (* Sys.command "rm /home/code/temp.dl"; *)
  with
    | VerificationErr s -> print_string ("Verification Error: " ^ s); exit 0;
    | GenerationErr s   -> print_string ("Generation Error: " ^ s); exit 0;