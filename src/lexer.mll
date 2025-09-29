 {
    open Parser;;        (* The type token is defined in parser.mli *)
    open Utils ;;
    let keyword_table = Hashtbl.create 100
    let _ =
        List.iter (fun (kwd, tok) -> Hashtbl.add keyword_table kwd tok)
        ["CREATE", CREATE;
        "SOURCE", SOURCE;
        "VIEW", VIEW;
        "DO", DO;
        "NOT", NOT;
        "IN", IN;
        "PRIMARY", PRIMARY;
        "FOREIGN", FOREIGN;
        "KEY", KEY;
        "REFERENCE", REF;
        "UNIQUE", UNIQUE;
        "CHECK", CHECK;
        "INT", INTTYPE;
        "BOOLEAN", BOOLEANTYPE;
        "STRING", STRINGTYPE;
        "WHEN", WHEN;
        "THEN", THEN;
        "INSERT", INSERT;
        "DELETE", DELETE;
        "INTO", INTO;
        "FROM", FROM;
        "group", GROUP;
        "true", BTRUE;
        "false", BFALSE;
        (* "identity", DID; *)
        "ON", ON;
        "FORALL", FORALL;
        "SUCH", SUCH;
        "THAT", THAT;
        "ONLY", ONLY;
        ]
(*		exception Eof
*)
 }

  rule token = parse
      [' ' '\t']     				{ token lexbuf }    (* skip blanks *)
    | ['\n' ]        				{ Lexing.new_line lexbuf; token lexbuf }    (* skip newline *)
    | '%''\n'        			{ Lexing.new_line lexbuf; token lexbuf }    (* skip comments *)
    | '%'[^'\n''v''s'][^'\n']*'\n'        			{ Lexing.new_line lexbuf; token lexbuf }    (* skip comments *)
    | '%'[^'\n''v''s'][^'\n']*eof        			{ Lexing.new_line lexbuf; token lexbuf }    (* skip comments *)
    | '%'['v''s'][^':'][^'\n']*'\n'        			{ Lexing.new_line lexbuf; token lexbuf }    (* skip comments *)
    | '%'['v''s'][^':'][^'\n']*eof        			{ Lexing.new_line lexbuf; token lexbuf }    (* skip comments *)
    | ['0'-'9']+ as lxm 			{ INT (int_of_string lxm) }
    | '\''(('\'''\'')|[^'\n''\''])*'\'' as lxm  { STRING(lxm) }
    | '_'*['a'-'z']['a'-'z''0'-'9''_']* as lxm 	{ 
        try
            Hashtbl.find keyword_table lxm
        with Not_found -> RELNAME(lxm) }
    | '_'*['A'-'Z']['A'-'Z''0'-'9''_']*'\''* as lxm 	{
        try
            Hashtbl.find keyword_table lxm
        with Not_found -> VARNAME(lxm)
        (* 注意变量名只能大写 *)
						}
    | "<="                                      { LE }
    | ">="                                      { GE }
    | ','            			            	{ SEP }
    | ';'                                       { SEMICOLON }
    | '('            	            			{ LPAREN }
    | ')'            	            			{ RPAREN }
    | '['            	            			{ LBRACKET }
    | ']'            		            		{ RBRACKET }
    | '='            	            			{ EQ }
    | '_'                                       { ANONVAR }
    | '<'                                       { LT }
    | '>'                                       { GT }
    | '+'                                       { PLUS }
    | '-'                                       { MINUS }
    | '*'                                       { TIMES }
    | '/'                                       { DIVIDE }  
    | '^'                                       { CONCAT }
    | ':'                                       { COLON }
    | '.'                                       { DOT }
    | "&&"                                      { AND }
    | "||"                                      { OR }
    | '{'                                       { LRECORD }
    | '}'                                       { RRECORD }
	| eof                                       { EOF }
    | _                                         { spec_lex_error lexbuf }
	
