grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

partial strategy attribute optimizeStep =
  rule on Expr of
  | addOp(e, const(0)) -> ^e
  | addOp(const(0), e) -> ^e
  | addOp(const(a), const(b)) -> const(a + b)
  | subOp(e1, e2) -> addOp(^e1, neg(^e2))
  | neg(neg(e)) -> ^e
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

inherited attribute env::[(String, Maybe<Expr>)] occurs on Expr, Exprs, Decls;
propagate env on Expr, Exprs excluding letE;

inherited attribute usedVars::[String] occurs on Decls;
synthesized attribute defs::[(String, Maybe<Expr>)] occurs on Decls;

aspect production funDecl
top::FunDecl ::= name::String args::[String] body::Expr
{
  body.env = map(pair(fst=_, snd=nothing()), args);
}

aspect production letE
top::Expr ::= d::Decls e::Expr
{
  d.usedVars = e.freeVars;
  d.env = top.env;
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
  local inline::Boolean = null(e.freeVars) || length(filter(eq(id, _), top.usedVars)) <= 1;
  top.defs = [(id, if inline then just(^e) else nothing())];
  e.env = top.env;
}

partial strategy attribute inlineStep =
  rule on top::Expr of
  | var(n) when lookup(n, top.env) matches just(just(e)) -> e
  | letE(empty(), e) -> ^e
  end <+
  rule on top::Decls of
  | decl(id, e) when !contains(id, top.usedVars) -> empty()
  | seq(d, empty()) -> ^d
  | seq(empty(), d) -> ^d
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
