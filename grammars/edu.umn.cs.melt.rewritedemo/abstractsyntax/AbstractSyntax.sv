grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp;

nonterminal Root with pp;

abstract production root
top::Root ::= s::Stmt
{
  top.pp = s.pp;
}

nonterminal Stmt with pp;

abstract production seq
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.pp = ppConcat([s1.pp, line(), s2.pp]);
}

abstract production block
top::Stmt ::= s::Stmt
{
  top.pp = braces(nestlines(2, s.pp));
}

abstract production assign
top::Stmt ::= id::String e::Expr
{
  top.pp = pp"${text(id)} = ${e.pp};";
}

synthesized attribute wrapPP::Document;
nonterminal Expr with pp, wrapPP;

aspect default production
top::Expr ::=
{
  top.wrapPP = parens(top.pp);
}

abstract production add
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} + ${e2.wrapPP}";
}

abstract production sub
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} - ${e2.wrapPP}";
}

abstract production neg
top::Expr ::= e::Expr
{
  top.pp = pp"-${e.wrapPP}";
}

abstract production const
top::Expr ::= i::Integer
{
  top.pp = text(toString(i));
  top.wrapPP = top.pp;
}

abstract production var
top::Expr ::= id::String
{
  top.pp = text(id);
  top.wrapPP = top.pp;
}
