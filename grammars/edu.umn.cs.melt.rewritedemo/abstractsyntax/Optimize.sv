grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

partial strategy attribute optimizeStep =
  rule on Expr of
  | add(e, const(0)) -> e
  | add(const(0), e) -> e
  | add(const(a), const(b)) -> const(a + b)
  | sub(e1, e2) -> add(e1, neg(e2))
  | neg(neg(e)) -> e
  | neg(const(a)) -> const(-a)
  end;
strategy attribute optimize =
  -- innermost(optimizeStep)
  all(optimize) <*
  ((optimizeStep <* optimize) <+ id);

attribute optimizeStep occurs on Expr;
attribute optimize occurs on FunDecl, Expr, Exprs, Decls;
propagate optimizeStep on Expr;
propagate optimize on FunDecl, Expr, Exprs, Decls;

autocopy attribute env::[Pair<String Maybe<Expr>>] occurs on Expr, Exprs, Decls;
inherited attribute usedVars::[String] occurs on Decls;
synthesized attribute defs::[Pair<String Maybe<Expr>>] occurs on Decls;

aspect production funDecl
top::FunDecl ::= name::String args::[String] body::Expr
{
  body.env = map(pair(_, nothing()), args);
}

aspect production letE
top::Expr ::= d::Decls e::Expr
{
  d.usedVars = e.freeVars;
  e.env = d.defs ++ top.env;
}

aspect production seq
top::Decls ::= d1::Decls d2::Decls
{
  top.defs = d1.defs ++ d2.defs;
  d1.env = top.env;
  d2.env = d1.defs ++ top.env;
  d1.usedVars = d2.freeVars ++ removeAll(map(fst, d2.defs), top.usedVars);
  d2.usedVars = top.usedVars;
}

aspect production empty
top::Decls ::=
{
  top.defs = [];
}

aspect production decl
top::Decls ::= id::String e::Expr
{
  -- Inline constants and expressions with only one use
  local inline::Boolean = null(e.freeVars) || length(filter(stringEq(id, _), top.usedVars)) <= 1; 
  top.defs = [pair(id, if inline then just(e) else nothing())];
  e.env = top.env;
}

partial strategy attribute inlineStep =
  rule on top::Expr of
  | var(n) when lookup(n, top.env) matches just(just(e)) -> e
  | letE(empty(), e) -> e
  end <+
  rule on top::Decls of
  | decl(id, e) when !contains(id, top.usedVars) -> empty()
  | seq(d, empty()) -> d
  | seq(empty(), d) -> d
  end
  occurs on Expr, Decls;
strategy attribute optimizeInline =
  -- Not simply using innermost here, since for let and seq we wish to rewrite the first child,
  -- redecorate the result, rewrite the second child using the new env, redecorate the result,
  -- then rewrite the first child again with usedVars computed from the first child.
  -- Using innermost would cause both children to be rewritten in the same pass.
  -- One implementation would be
  -- repeat(onceBottomUp(optimizeStep <+ inlineStep))
  -- A more efficient alternative is
  ((seq(optimizeInline, id) <* seq(id, optimizeInline) <* seq(optimizeInline, id)) <+
   (letE(optimizeInline, id) <* letE(id, optimizeInline) <* letE(optimizeInline, id)) <+
   all(optimizeInline))
  <* try((optimizeStep <+ inlineStep) <* optimizeInline)
  occurs on FunDecl, Expr, Exprs, Decls;

propagate inlineStep on Expr, Decls;
propagate optimizeInline on FunDecl, Expr, Exprs, Decls;
