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
%token DGET
%token EOF
%token ANONVAR /* anonymous variable */
%token CREATE SOURCE VIEW
%token INTTYPE BOOLEANTYPE STRINGTYPE
%token WHEN THEN INSERT DELETE INTO FROM GROUP
%token BTRUE BFALSE


/* associativity and precedence when needed */
%nonassoc IMPLIEDBY


%start main               /* entry point */
%type <Expr.expr> main

%start parseDelta
%type <Expr.delta> parseDelta

%start parseIni
%type <Expr.is> parseIni

// %start parse_rterm
// %type <Expr.rterm> parse_rterm

// %start parse_query
// %type <Expr.conj_query> parse_query


/* Grammar */
  main:
  // | EOF         { get_empty_expr }
  | program EOF { $1 }
  | error       { spec_parse_error "invalid syntax for a main program" 1; }
  ;

  program:
  | schemas SEMICOLON ON SOURCE LBRACKET rellist RBRACKET SEP VIEW RELNAME dget SEMICOLON  { genExpr $1 $6 $9 $11 }
  | error                             { spec_parse_error "invalid syntax for program definition" 1; }
  ;

  schemas:
  | schema              { $1 :: [] }
  | schema SEP schemas  { $1 :: $3 }
  | error               { spec_parse_error "invalid syntax for schema definitions" 1; }
  ;

  schema:
  | CREATE RELNAME LPAREN attrlist RPAREN             { ($2, $4, []) }
  | CREATE RELNAME LPAREN attrlist SEP conlist RPAREN { ($2, $4, $6) }
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
  | constraint              { $1 :: []}
  | constraint SEP conlist  { $1 :: $3 }
  | error                   { spec_parse_error "invalid syntax for constraints declarations" 1; }
  ;

  constraint:
  | PRIMARY KEY LPAREN varlist RPAREN                           { PK $4 }
  | FOREIGN KEY LPAREN var RPAREN REF RELNAME LPAREN var RPAREN { FK ($4, $7, $9) }
  | CHECK LPAREN pred RPAREN                                    { CHECK $3 }
  | error                                                       { spec_parse_error "invalid syntax for a constraint" 1; }
  ;

  varlist:
  | var             { $1 :: [] }
  | var SEP varlist { $1 :: $3 }
  | error           { spec_parse_error "invalid syntax for varlist" 1; }
  ;

  pred:
  | predic  { $1 }
  | pred AND predic                    { And ($1, $3) }
  | error                            { spec_parse_error "invalid syntax for pred" 1; }
  ;

  predic:
  | predicate     { $1 }
  | predic OR predicate  { Or ($1, $3) }
  | error         { spec_parse_error "invalid syntax for a predic" 1; }
  ;

  predicate:
  | atomPredicate       { $1 }
  | NOT atomPredicate       { Not $1 }
  | error               { spec_parse_error "invalid syntax for a predicate" 1; }
  ;

  atomPredicate:
  | LPAREN pred RPAREN  { $2 }
  | value EQ value      { Equation ("=", $1, $3) }
  | value LT value      { Equation ( "<", $1, $3) }
  | value GT value      { Equation ( ">", $1, $3) }
  | value LE value      { Equation ("<=", $1, $3) }
  | value GE value      { Equation (">=", $1, $3) }
  | varlist IN RELNAME  { In ($1, $3) }
  | error               { spec_parse_error "invalid syntax for an atomic predicate" 1; }
  ;

  value:
  | term              { $1 }
  | value PLUS term   { Bop ("+", $1, $3) }
  | value MINUS term  { Bop ("-", $1, $3) }
  | value CONCAT term { Bop ("^", $1, $3) }
  | error             { spec_parse_error "invalid syntax for a arithmetic expression" 1; }
  ;

  term:
  | factor             { $1 }
  | term TIMES factor  { Bop ("*", $1, $3) }
  | term DIVIDE factor { Bop ("/", $1, $3) }
  | error              { spec_parse_error "invalid syntax for a term" 1; }
  ;

  factor:
  | value_primary { $1 }
  | error         { spec_parse_error "invalid syntax for a factor" 1; }
  ;

  value_primary:
  | parenthesized_value            { $1 }
  | MINUS parenthesized_value      { Uop ("-", $2) }
  | nonparenthesized_value_primary { $1 }
  | error                          { spec_parse_error "invalid syntax for a primary number" 1; }
  ;

  nonparenthesized_value_primary:
  | constant   { Const $1 }
  | VARNAME    { Var (NamedVar $1) }
  | error      { spec_parse_error "invalid syntax for a primar number" 1; }
  ;

  parenthesized_value:
  | LPAREN value RPAREN { $2 }
  | error               { spec_parse_error "invalid syntax for a parenthesized expression" 1; }
  ;

  constant:
  | INT         { Int $1 }
  | MINUS INT   { Int (- $2) }
  | STRING      { String $1 }
  | BTRUE       { Bool true }
  | BFALSE      { Bool false }
  | error       { spec_parse_error "invalid syntax for a constant" 1; }
  ;

  var:
  | VARNAME   { NamedVar $1 }
  | ANONVAR   { AnonVar }
  | constant  { ConstVar $1 }
  | error     { spec_parse_error "invalid syntax for a variables" 1; }
  ;

  dget:
  | rule          { $1 :: [] }
  | rule SEP dget { $1 :: $3 }
  | error         { spec_parse_error "invalid syntax for dget" 1; }
  ;

  rule:
  | dopps WHEN pred THEN dopps { ($1, $3, $5) }
  | error                      { spec_parse_error "invalid syntax for a rule" 1; }

  dopps:
  | dopp            { $1 :: [] }
  | dopp SEMICOLON dopps  { $1 :: $3 }
  | error           { spec_parse_error "invalid syntax for atomic operation patterns" 1; }

  dopp:
  | INSERT LPAREN varlist RPAREN INTO RELNAME { Insert ($6, $3) }
  | DELETE LPAREN varlist RPAREN FROM RELNAME { Delete ($6, $3) }
  | FORALL var SUCH THAT pred DO dopp         { Forall ($2, $5, $7) }
  | error                                     { spec_parse_error "" 1; }

  // parseDelta:
  // | DID 
  // | GROUP LPAREN atomicOPs RPAREN
  // | error {}
  // ;

  // atomicOPs:
  // | atomicOP 
  // | atomicOP SEP atomicOPs
  // | error
  // ;

  // atomicOP:
  // | INSERT LPAREN constlist RPAREN INTO RELNAME
  // | DELETE LPAREN constlist RPAREN FROM RELNAME
  // | error
  // ;

  // constlist:
  // | constant
  // | constant SEP constlist
  // | error
  // ;

  // parse_rterm:
  // | predicate EOF { $1 }
  // | error         { spec_parse_error "invalid syntax for a rterm" 1; }
  // ;

  // parse_query:
  // | conj_query EOF { $1 }
  // | error          { spec_parse_error "invalid syntax for a conj_query" 1; }
  // ;

  // program:
  // | exprlist { $1 }
  // | error    { spec_parse_error "invalid syntax for a program" 1; }
  // ;

  // exprlist:
  // | expr          { add_stt $1 get_empty_expr }
  // | exprlist expr { add_stt $2 $1 }
  // | error         { spec_parse_error "invalid syntax for a list of rules" 1; }
  // ;

  // expr:
  // | primary_key          { Stt_Pk (fst $1, snd $1) }
  // | get_rule             { Stt_Get $1 }
  // | integrity_constraint { Stt_Constraint (fst $1, snd $1) }
  // | rule                 { Stt_Rule (fst $1, snd $1) }
  // | source               { Stt_Source (fst $1, snd $1) }
  // | view                 { Stt_View (fst $1, snd $1) }
  // | fact                 { Stt_Fact $1 }
  // | query                { Stt_Query $1 }
  // | initial_state        { Stt_Is $1 }
  // // | rule_group           { Stt_Rg (fst $1, snd $1) }
  // | error                { spec_parse_error "invalid syntax for a rule or a declaration of query/source/view/constraint" 1; }
  // ;

  // get_rule:
  // | GETRULES TYPING LBRACKET rule_list RBRACKET DOT { $4 }

  // // rule_group:
  // // | initial_state rule_list { ($1, $2) }
  // // | error                   { spec_parse_error "invalid syntax for rule group" 1; }

  // rule_list:
  // | rule                  { $1 :: [] }
  // | rule rule_list        { $1 :: $2 }
  // | error                 { spec_parse_error "invalid syntax for rule_list" 1;}

  // initial_state:
  // | INISTATE TYPING LBRACKET rule_list RBRACKET DOT            { $4 }
  // | error                              { spec_parse_error "invalid syntax for an initial state" 1; }
  // ;

  // primary_key:
  // | PK LPAREN RELNAME SEP LBRACKET attrlist RBRACKET RPAREN	DOT	{ ($3, $6) }
  // | PK LPAREN RELNAME SEP LBRACKET attrlist RBRACKET RPAREN EOF { spec_parse_error "miss a dot for a primary key" 3; }
  // | error                                                       { spec_parse_error "invalid syntax for a primary key" 1; }
  // ;

  // integrity_constraint:
  // | BOT IMPLIEDBY body DOT               { (get_empty_pred, $3) }
  // | BOT LPAREN RPAREN IMPLIEDBY body DOT { (Pred ("⊥", []), $5) }
  // | BOT IMPLIEDBY body EOF               { spec_parse_error "miss a dot for a constraint" 3; }
  // | error                                { spec_parse_error "invalid syntax for a constraint" 1; }
  // ;

  // rule:
  // | head IMPLIEDBY body DOT { ($1, $3) }
  // | head IMPLIEDBY body EOF { spec_parse_error "miss a dot for a rule" 4; }
  // | error                   { spec_parse_error "invalid syntax for a rule" 1; }
  // ;

  // source:
  // | SMARK schema DOT { $2 }
  // | SMARK schema EOF { spec_parse_error "miss a dot for a source relation" 3; }
  // | error            { spec_parse_error "invalid syntax for a source relation" 1; }
  // ;

  // view:
  // | VMARK schema DOT { $2 }
  // | VMARK schema EOF { spec_parse_error "miss a dot for a view relation" 3; }
  // | error            { spec_parse_error "invalid syntax for a view relation" 1; }
  // ;

  // fact:
  // | predicate DOT { $1 }
  // | error         { spec_parse_error "invalid syntax for a fact" 1; }
  // ;

  // query:
  // | QMARK predicate DOT { $2 }
  // | QMARK predicate EOF { spec_parse_error "miss a dot for a query" 3; }
  // | error               { spec_parse_error "invalid syntax for a query" 1; }
  // ;

  // attrlist:
  // | /* empty */         { [] }
  // | STRING              { String.uppercase_ascii (String.sub $1 1 (String.length $1 - 2)) :: [] }
  // | STRING SEP attrlist { String.uppercase_ascii (String.sub $1 1 (String.length $1 - 2)) :: $3 } /* \!/ rec. on the right */
  // | error               { spec_parse_error "invalid syntax for a list of attributes" 1; }
  // ;

  // head:
  // | predicate { $1 }
  // | error     { spec_parse_error "invalid syntax for a head" 1; }
  // ;

  // conj_query:
  // | LPAREN varlist RPAREN IMPLIEDBY signed_literals
  //   {
  //     let pos_literals, neg_literal = $5 in
  //     Expr.Conj_query ($2, pos_literals, neg_literal)
  //   }
  // | error { spec_parse_error "invalid syntax for a conjunctive query" 1; }
  // ;

  // signed_literals:
  // | predicate SEP signed_literals     { let pos, neg = $3 in $1 :: pos, neg }
  // | NOT predicate SEP signed_literals { let pos, neg = $4 in pos, $2 :: neg }
  // | predicate                         { [$1], [] }
  // | NOT predicate                     { [], [$2] }
  // | error                             { spec_parse_error "invalid syntax for a signed_literals" 1; }
  // ;

  // body:
  // | litlist { List.rev $1 }
  // | error   { spec_parse_error "invalid syntax for a body" 1; }
  // ;

  // schema:
  // | RELNAME LPAREN attrtypelist RPAREN { ($1, $3) }
  // | error                              { spec_parse_error "invalid syntax for a predicate" 1; }
  // ;

  // attrtypelist:
  // | /* empty */                          { [] }
  // | STRING TYPING stype                  { (String.uppercase_ascii (String.sub $1 1 (String.length $1 - 2)), $3) :: [] }
  // | STRING TYPING stype SEP attrtypelist { (String.uppercase_ascii (String.sub $1 1 (String.length $1 - 2)), $3) :: $5 } /* \!/ rec. on the right */
  // | error                                { spec_parse_error "invalid syntax for a list of pairs of an attribute and its type" 1; }
  // ;

  // stype:
  // | SINT    { Sint }
  // | SREAL   { Sreal }
  // | SSTRING { Sstring }
  // | SBOOL   { Sbool }
  // ;

  // litlist:
  // | /* empty */         { [] }
  // | literal             { $1 :: [] }
  // | litlist AND literal { $3 :: $1 }
  // | litlist SEP literal { $3 :: $1 }
  // | error               { spec_parse_error "invalid syntax for a conjunction of literals" 1; }
  // ;

  // literal:
  // | predicate     { Rel $1 }
  // | NOT predicate { Not $2 }
  // | equation      { Equat $1 }
  // | NOT equation  { Noneq $2 }
  // | error         { spec_parse_error "invalid syntax for a literal" 1; }
  // ;

  // predicate:
  // | RELNAME LPAREN varlist RPAREN       { Pred ($1, $3) }
  // | PLUS RELNAME LPAREN varlist RPAREN  { Deltainsert ($2, $4) }
  // | MINUS RELNAME LPAREN varlist RPAREN { Deltadelete ($2, $4) }
  // | error                               { spec_parse_error "invalid syntax for a predicate" 1; }
  // ;

  // equation:
  // | value_expression EQ value_expression { Equation ( "=", $1, $3) }
  // | value_expression NE value_expression { Equation ("<>", $1, $3) }
  // | value_expression LT value_expression { Equation ( "<", $1, $3) }
  // | value_expression GT value_expression { Equation ( ">", $1, $3) }
  // | value_expression LE value_expression { Equation ("<=", $1, $3) }
  // | value_expression GE value_expression { Equation (">=", $1, $3) }
  // | error                                { spec_parse_error "invalid syntax for a comparison" 1; }
  // ;

  // value_expression:
  // | term                         { $1 }
  // | value_expression PLUS term   { BinaryOp ("+", $1, $3) }
  // | value_expression CONCAT term { BinaryOp ("^", $1, $3) }
  // | value_expression MINUS term  { BinaryOp ("-", $1, $3) }
  // | error                        { spec_parse_error "invalid syntax for a arithmetic expression" 1; }
  // ;

  // term:
  // | factor             { $1 }
  // | term TIMES factor  { BinaryOp ("*", $1, $3) }
  // | term DIVIDE factor { BinaryOp ("/", $1, $3) }
  // | error              { spec_parse_error "invalid syntax for a term" 1; }
  // ;

  // factor:
  // | value_primary { $1 }
  // | error         { spec_parse_error "invalid syntax for a factor" 1; }
  // ;

  // value_primary:
  // | parenthesized_value_expression       { $1 }
  // | MINUS parenthesized_value_expression { UnaryOp ("-", $2) }
  // | nonparenthesized_value_primary       { $1 }
  // | error                                { spec_parse_error "invalid syntax for a primary number" 1; }
  // ;

  // nonparenthesized_value_primary:
  // | constant   { Const $1 }
  // | var_or_agg { Var $1 }
  // | error      { spec_parse_error "invalid syntax for a primar number" 1; }
  // ;

  // parenthesized_value_expression:
  // | LPAREN value_expression RPAREN { $2 }
  // | error                          { spec_parse_error "invalid syntax for a parenthesized expression" 1; }
  // ;

  // var_or_agg:
  // | VARNAME   { NamedVar $1 }
  // | aggregate { $1 }
  // | error     { spec_parse_error "invalid syntax for a var or a aggreation" 1; }
  // ;

  // constant:
  // | INT         { Int $1 }
  // | MINUS INT   { Int (- $2) }
  // | FLOAT       { Real $1 }
  // | MINUS FLOAT { Real (-. $2) }
  // | STRING      { String $1 }
  // | NULL        { Null }
  // | FF          { Bool false }
  // | TT          { Bool true }
  // | error       { spec_parse_error "invalid syntax for a constant" 1; }
  // ;

  // varlist:
  // | /* empty */     { [] }
  // | var             { $1 :: [] }
  // | var SEP varlist { $1 :: $3 } /* \!/ rec. on the right */
  // | error           { spec_parse_error "invalid syntax for a list of variables" 1; }
  // ;

  // var:
  // | VARNAME   { NamedVar $1 }
  // | ANONVAR   { AnonVar }
  // | constant  { ConstVar $1 }
  // | aggregate { $1 }
  // | error     { spec_parse_error "invalid syntax for a variables" 1; }
  // ;

  // aggregate:
  // | VARNAME LPAREN VARNAME RPAREN { AggVar ($1,$3) }
  // | error                         { spec_parse_error "invalid syntax for a aggregation" 1; }
  // ;
