grammar edu:umn:cs:melt:rewritedemo:abstractsyntax;

imports core:monad;

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
attribute optimize occurs on Root, Stmt, Expr;
propagate optimizeStep on Expr;
propagate optimize on Root, Stmt, Expr;

autocopy attribute env::[Pair<String Expr>] occurs on Stmt, Expr;
synthesized attribute defs::[Pair<String Expr>] occurs on Stmt;

aspect production root
top::Root ::= s::Stmt
{
  s.env = [];
}
aspect production seq
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.defs = s1.defs ++ s2.defs;
  s1.env = top.env;
  s2.env = s1.defs ++ top.env;
}

aspect production block
top::Stmt ::= s::Stmt
{
  top.defs = [];
  s.env = top.env;
}

aspect production assign
top::Stmt ::= id::String e::Expr
{
  top.defs = [pair(id, e)];
  e.env = top.env;
}

partial strategy attribute inlineStep =
  rule on top::Expr of
  | var(n) when lookupBy(stringEq, n, top.env).isJust ->
    lookupBy(stringEq, n, top.env).fromJust
  end
  occurs on Expr;
strategy attribute optimizeInline =
  -- Not simply using innermost here, since we wish to rewrite the first child of seq,
  -- redecorate the result, then rewrite the second child using the new env.
  -- Using innermost would cause both children to be rewritten in the same pass.
  -- One implementation would be
  -- repeat(onceBottomUp(optimizeStep <+ inlineStep))
  -- A more efficient alternative is
  (seq(optimizeInline, id) <* seq(id, optimizeInline)) <+ -- seq: rewrite the first child, then the second child
  assign(id, innermost(optimizeStep <+ inlineStep)) <+    -- assign: perform an innermost rewrite of the expression
  all(optimizeInline)                                     -- other Stmt/Root productions: optimize all the children
  occurs on Root, Stmt, Expr;

propagate inlineStep on Expr;
propagate optimizeInline on Root, Stmt, Expr;
