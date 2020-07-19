grammar edu:umn:cs:melt:rewritedemo:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:rewritedemo:abstractsyntax;

ignore terminal WhiteSpace_t /[\n\r\t\ ]+/;
ignore terminal Comment_t /--.*/;

terminal Identifier_t /[A-Za-z_][A-Za-z0-9_]*/;
terminal Constant_t /[0-9]+/;

terminal Plus_t '+' association = left, precedence = 1;
terminal Minus_t '-' association = left, precedence = 1;

terminal LParen_t '(';
terminal RParen_t ')';
terminal LBrace_t '{';
terminal RBrace_t '}';
terminal Assign_t '=';
terminal Semi_t ';';
terminal Comma_t ',';

terminal Fun_t 'fun' dominates Identifier_t;
terminal Let_t 'let' dominates Identifier_t;
terminal In_t 'in' dominates Identifier_t;
terminal End_t 'end' dominates Identifier_t;

nonterminal Root_c with ast<FunDecl>;
concrete production root_c
top::Root_c ::= 'fun' n::Identifier_t '(' params::Params_c ')' '=' e::Expr_c ';'
{ top.ast = funDecl(n.lexeme, params.ast, e.ast); }

nonterminal Params_c with ast<[String]>;
concrete productions top::Params_c
| h::Identifier_t ',' t::Params_c
  { top.ast = h.lexeme :: t.ast; }
| h::Identifier_t
  { top.ast = [h.lexeme]; }
|
  { top.ast = []; }

nonterminal Decls_c with ast<Decls>;
concrete productions top::Decls_c
| h::Decl_c t::Decls_c
  { abstract seq; }
| s::Decl_c
  { top.ast = s.ast; }

nonterminal Decl_c with ast<Decls>;
concrete productions top::Decl_c
| id::Identifier_t '=' e::Expr_c ';'
  { top.ast = decl(id.lexeme, e.ast); }

nonterminal Expr_c with ast<Expr>;
concrete productions top::Expr_c
| e1::Expr_c '+' e2::Expr_c
  { abstract add; }
| e1::Expr_c '-' e2::Expr_c
  { abstract sub; }
| '-' e::Expr_c
  { abstract neg; }
| i::Constant_t
  { top.ast = const(toInteger(i.lexeme)); }
| 'let' d::Decls_c 'in' e::Expr_c 'end'
  { abstract letE; }
| id::Identifier_t
  { top.ast = var(id.lexeme); }
| '(' e::Expr_c ')'
  { top.ast = e.ast; }
