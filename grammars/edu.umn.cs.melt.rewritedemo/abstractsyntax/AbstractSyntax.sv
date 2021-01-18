grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

imports silver:core with empty as mempty;
imports silver:langutil;
imports silver:langutil:pp;

synthesized attribute freeVars::[String];

synthesized attribute wrapPP::Document;
nonterminal Expr with pp, wrapPP, freeVars;

aspect default production
top::Expr ::=
{
  top.wrapPP = parens(top.pp);
}

production add
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} + ${e2.wrapPP}";
  top.freeVars = e1.freeVars ++ e2.freeVars;
}

production sub
top::Expr ::= e1::Expr e2::Expr
{
  top.pp = pp"${e1.wrapPP} - ${e2.wrapPP}";
  top.freeVars = e1.freeVars ++ e2.freeVars;
}

production neg
top::Expr ::= e::Expr
{
  top.pp = pp"-${e.wrapPP}";
  top.freeVars = e.freeVars;
}

production const
top::Expr ::= i::Integer
{
  top.pp = text(toString(i));
  top.wrapPP = top.pp;
  top.freeVars = [];
}

production letE
top::Expr ::= d::Decls e::Expr
{
  top.pp = pp"let ${nestlines(2, ppImplode(line(), d.pps))}in ${e.pp} end";
  top.wrapPP = top.pp;
  top.freeVars = d.freeVars ++ removeAll(map(fst, d.defs), e.freeVars);
}

production var
top::Expr ::= id::String
{
  top.pp = text(id);
  top.wrapPP = top.pp;
  top.freeVars = [id];
}

production app
top::Expr ::= id::String args::Exprs
{
  top.pp = pp"${text(id)}(${ppImplode(pp", ", args.pps)})";
  top.wrapPP = top.pp;
  top.freeVars = args.freeVars;
}

nonterminal Exprs with pps, freeVars;

production consExpr
top::Exprs ::= h::Expr t::Exprs
{
  top.pps = h.pp :: t.pps;
  top.freeVars = h.freeVars ++ t.freeVars;
}

production nilExpr
top::Exprs ::=
{
  top.pps = [];
  top.freeVars = [];
}

nonterminal Decls with pps, freeVars;

production seq
top::Decls ::= d1::Decls d2::Decls
{
  top.pps = d1.pps ++ d2.pps;
  top.freeVars = d1.freeVars ++ removeAll(map(fst, d1.defs), d2.freeVars);
}

production empty
top::Decls ::=
{
  top.pps = [];
  top.freeVars = [];
}

production decl
top::Decls ::= id::String e::Expr
{
  top.pps = [pp"${text(id)} = ${e.pp};"];
  top.freeVars = e.freeVars;
}

nonterminal FunDecl with pp, freeVars;

production funDecl
top::FunDecl ::= name::String args::[String] body::Expr
{
  top.pp = pp"fun ${text(name)}(${ppImplode(pp", ", map(text, args))}) =${nest(2, cat(line(), body.pp))};";
  top.freeVars = removeAll(args, body.freeVars);
}
