%{ (* OCaml preamble *)

  open Expr
  open Utils
  (* let parse_error (s : string) = spec_parse_error s 1 *)
  (* end preamble *)
 %}


/* tokens declaration */

%token <int> INT        /* token with int value    */
%token <string> STRING  /* token with string value */
%token <string> RELNAME /* token with string value */
%token <string> VARNAME /* token with string value */

%token PRIMARY FOREIGN KEY REF UNIQUE CHECK
%token AND NOT OR IN
%token EQ
%token LE GE LT GT
%token PLUS MINUS TIMES DIVIDE CONCAT
%token LPAREN RPAREN LBRACKET RBRACKET SEP SEMICOLON
%token EOF
%token ANONVAR /* anonymous variable */
%token CREATE SOURCE VIEW
%token INTTYPE BOOLEANTYPE STRINGTYPE
%token WHEN THEN INSERT DELETE INTO FROM GROUP
%token BTRUE BFALSE
%token FORALL SUCH THAT ON DO COLON DOT LRECORD RRECORD ONLY

%left OR
%left AND
%nonassoc NOT

%start main               /* entry point */
%type <Expr.expr> main

%start parse_userops
%type <Expr.op list> parse_userops

%start parse_db
%type <Expr.data list> parse_db
/* %start parseDelta
%type <Expr.delta> parseDelta

%start parseIni
%type <Expr.is> parseIni

%start parse_rterm
%type <Expr.rterm> parse_rterm

%start parse_query
%type <Expr.conj_query> parse_query */

%%
/* Grammar */
  main:
  | program EOF { $1 }
  | error       { spec_parse_error "invalid syntax for a main program" 1; }
  ;

  program:
  | schemas SEMICOLON ON SOURCE LBRACKET rellist RBRACKET SEP VIEW RELNAME COLON dget DOT  { genExpr $1 $6 $10 $12 }
  | error                             { spec_parse_error "invalid syntax for program definition" 1; }
  ;

  rellist:
  | RELNAME { $1 :: [] }
  | RELNAME SEP rellist { $1 :: $3 }
  | error { spec_parse_error "invalid syntax for relation list" 1; }
  ;

  schemas:
  | schema              { $1 :: [] }
  | schema SEP schemas  { $1 :: $3 }
  | error               { spec_parse_error "invalid syntax for schema definitions" 1; }
  ;

  schema:
  | CREATE RELNAME LPAREN attrlist RPAREN             { ($2, $4, []) }
  | CREATE RELNAME LPAREN attrlist SEMICOLON conlist RPAREN { ($2, $4, $6) }
  | error                                             { spec_parse_error "invalid syntax for a schema definition" 1; }
  ;

  attrlist:
  | attr              { $1 :: [] }
  | attr SEP attrlist { $1 :: $3 }
  | error             { spec_parse_error "invalid syntax for attribute declarations" 1; }
  ;

  attr:
  | VARNAME INTTYPE                        { ($1, Aint) }
  | VARNAME BOOLEANTYPE                    { ($1, Abool) }
  | VARNAME STRINGTYPE                     { ($1, Astring) }
  | error                                  { spec_parse_error "invalid syntax for an attribute" 1; } 
  ;

  conlist:
  | constt              { $1 :: []}
  | constt SEP conlist  { $1 :: $3 }
  | error                   { spec_parse_error "invalid syntax for constraints declarations" 1; }
  ;

  constt:
  | PRIMARY KEY LPAREN varlist RPAREN                           { PK $4 }
  | FOREIGN KEY LPAREN var RPAREN REF RELNAME LPAREN var RPAREN { FK ($4, $7, $9) }
  | CHECK LPAREN pred RPAREN                                    { Check $3 }
  | error                                                       { spec_parse_error "invalid syntax for a constraint" 1; }
  ;

  varlist:
  | var             { $1 :: [] }
  | var SEP varlist { $1 :: $3 }
  // | error           { spec_parse_error "invalid syntax for varlist" 1; }
  ;

  pred:
  | pred AND pred                    { And ($1, $3) }
  | pred OR pred                     { Or ($1, $3) }
  | NOT pred                         { Not $2 }
  | predicate                        { $1 }
  | error                            { spec_parse_error "invalid syntax for pred" 1; }
  ;

  predicate:
  // | LRECORD var RRECORD IN RELNAME  { In ([$2], $5) }
  | LRECORD varlist RRECORD IN RELNAME  { In ($2, $5) }
  | ONLY LRECORD varlist RRECORD IN RELNAME { Only ($3, $6) }
  | value EQ value      { Equation ("=", $1, $3) }
  | value LT value      { Equation ( "<", $1, $3) }
  | value GT value      { Equation ( ">", $1, $3) }
  | value LE value      { Equation ("<=", $1, $3) }
  | value GE value      { Equation (">=", $1, $3) }
  | LPAREN pred RPAREN  { $2 }
  // | error               { spec_parse_error "invalid syntax for an atomic predicate" 1; }
  ;

  value:
  | term              { $1 }
  | value PLUS term   { Bop ("+", $1, $3) }
  | value MINUS term  { Bop ("-", $1, $3) }
  | value CONCAT term { Bop ("^", $1, $3) }
  // | error             { spec_parse_error "invalid syntax for a arithmetic expression" 1; }
  ;

  term:
  | factor             { $1 }
  | term TIMES factor  { Bop ("*", $1, $3) }
  | term DIVIDE factor { Bop ("/", $1, $3) }
  // | error              { spec_parse_error "invalid syntax for a term" 1; }
  ;

  factor:
  | value_primary { $1 }
  // | error         { spec_parse_error "invalid syntax for a factor" 1; }
  ;

  value_primary:
  | parenthesized_value            { $1 }
  | MINUS parenthesized_value      { Uop ("-", $2) }
  | nonparenthesized_value_primary { $1 }
  // | error                          { spec_parse_error "invalid syntax for a primary number" 1; }
  ;

  nonparenthesized_value_primary:
  | constant   { Const $1 }
  | VARNAME    { Var (NamedVar $1) }
  // | error      { spec_parse_error "invalid syntax for a primar number" 1; }
  ;

  parenthesized_value:
  | LPAREN value RPAREN { $2 }
  // | error               { spec_parse_error "invalid syntax for a parenthesized expression" 1; }
  ;

  constant:
  | INT         { Int $1 }
  | MINUS INT   { Int (- $2) }
  | STRING      { String $1 }
  | BTRUE       { Bool true }
  | BFALSE      { Bool false }
  // | error       { spec_parse_error "invalid syntax for a constant" 1; }
  ;

  var:
  | VARNAME   { NamedVar $1 }
  | ANONVAR   { AnonVar }
  | constant  { ConstVar $1 }
  // | error     { spec_parse_error "invalid syntax for a variables" 1; }
  ;

  dget:
  | rule          { $1 :: [] }
  | rule SEP dget { $1 :: $3 }
  | error         { spec_parse_error "invalid syntax for dget" 1; }
  ;

  rule:
  | ops WHEN pred THEN ops { ($1, $3, $5) }
  | error                      { spec_parse_error "invalid syntax for a rule" 1; }
  ;

  ops:
  | op            { $1 :: [] }
  | op SEMICOLON ops  { $1 :: $3 }
  | error           { spec_parse_error "invalid syntax for operation list" 1; }
  ;

  op:
  | INSERT LRECORD varlist RRECORD INTO RELNAME { Insert ($6, $3) }
  | DELETE LRECORD varlist RRECORD FROM RELNAME { Delete ($6, $3) }
  | FORALL var SUCH THAT pred DO LBRACKET ops RBRACKET     { Forall ($2, $5, $8) }
  | error                                     { spec_parse_error "invalid syntax for op" 1; }
  ;

  parse_userops:
  | ops DOT { $1 }
  | error   { spec_parse_error "invalid syntax for operation when running" 1; }

  parse_db:
  | datalist { $1 }
  | EOF { [] }
  | error { spec_parse_error "invalid syntax for database" 1; }

  datalist:
  | data { $1 :: [] }
  | data datalist { $1 :: $2 }

  data:
  | RELNAME LPAREN varlist RPAREN DOT { ($1, $3) }