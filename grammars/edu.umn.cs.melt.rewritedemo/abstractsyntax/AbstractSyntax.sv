grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp;

synthesized attribute freeVars::[String];

nonterminal FunDecl with pp, freeVars;

abstract production funDecl
top::FunDecl ::= name::String args::[String] body::Expr
{
  top.pp = pp"fun ${text(name)}(${ppImplode(pp", ", map(text, args))}) =${nest(2, cat(line(), body.pp))};";
  top.freeVars = removeAllBy(stringEq, args, body.freeVars);
}

synthesized attribute wrapPP::Document;
nonterminal Expr with pp, wrapPP, freeVars;

aspect default production
top::Expr ::=
{
  top.wrapPP = parens(top.pp);
}

abstract production add
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} + ${e2.wrapPP}";
  top.freeVars = e1.freeVars ++ e2.freeVars;
}

abstract production sub
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} - ${e2.wrapPP}";
  top.freeVars = e1.freeVars ++ e2.freeVars;
}

abstract production neg
top::Expr ::= e::Expr
{
  top.pp = pp"-${e.wrapPP}";
  top.freeVars = e.freeVars;
}

abstract production const
top::Expr ::= i::Integer
{
  top.pp = text(toString(i));
  top.wrapPP = top.pp;
  top.freeVars = [];
}

abstract production letE
top::Expr ::= d::Decls e::Expr
{
  top.pp = pp"let ${nestlines(2, ppImplode(line(), d.pps))}in ${e.pp} end";
  top.wrapPP = top.pp;
  top.freeVars = d.freeVars ++ removeAllBy(stringEq, map(fst, d.defs), e.freeVars);
}

abstract production var
top::Expr ::= id::String
{
  top.pp = text(id);
  top.wrapPP = top.pp;
  top.freeVars = [id];
}

abstract production app
top::Expr ::= id::String args::Exprs
{
  top.pp = pp"${text(id)}(${ppImplode(pp", ", args.pps)})";
  top.wrapPP = top.pp;
  top.freeVars = args.freeVars;
}

nonterminal Exprs with pps, freeVars;

abstract production consExpr
top::Exprs ::= h::Expr t::Exprs
{
  top.pps = h.pp :: t.pps;
  top.freeVars = h.freeVars ++ t.freeVars;
}

abstract production nilExpr
top::Exprs ::=
{
  top.pps = [];
  top.freeVars = [];
}

nonterminal Decls with pps, freeVars;

abstract production seq
top::Decls ::= d1::Decls d2::Decls
{
  top.pps = d1.pps ++ d2.pps;
  top.freeVars = d1.freeVars ++ removeAllBy(stringEq, map(fst, d1.defs), d2.freeVars);
}

abstract production empty
top::Decls ::=
{
  top.pps = [];
  top.freeVars = [];
}

abstract production decl
top::Decls ::= id::String e::Expr
{
  top.pps = [pp"${text(id)} = ${e.pp};"];
  top.freeVars = e.freeVars;
}
