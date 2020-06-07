grammar edu:umn:cs:melt:rewritedemo:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:rewritedemo:abstractsyntax;

ignore terminal WhiteSpace_t /[\n\r\t\ ]+/;
ignore terminal Comment_t /[/][/].*/;

terminal Identifier_t /[A-Za-z_]+/;
terminal Constant_t /[0-9]+/;

terminal Plus_t '+' association = left, precedence = 1;
terminal Minus_t '-' association = left, precedence = 1;

terminal LParen_t '(';
terminal RParen_t ')';
terminal LBrace_t '{';
terminal RBrace_t '}';
terminal Assign_t '=';
terminal Semi_t ';';

nonterminal Root_c with ast<Root>;
concrete production root_c
top::Root_c ::= s::Stmts_c
{ abstract root; }

nonterminal Stmts_c with ast<Stmt>;
concrete productions top::Stmts_c
| h::Stmt_c t::Stmts_c
  { abstract seq; }
| s::Stmt_c
  { top.ast = s.ast; }

nonterminal Stmt_c with ast<Stmt>;
concrete productions top::Stmt_c
| id::Identifier_t '=' e::Expr_c ';'
  { top.ast = assign(id.lexeme, e.ast); }
| '{' s::Stmts_c '}'
  { top.ast = block(s.ast); }

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
| id::Identifier_t
  { top.ast = var(id.lexeme); }
| '(' e::Expr_c ')'
  { top.ast = e.ast; }
