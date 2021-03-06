grammar edu:umn:cs:melt:rewritedemo:driver;

imports silver:langutil;
imports silver:langutil:pp;

imports edu:umn:cs:melt:rewritedemo:concretesyntax;
imports edu:umn:cs:melt:rewritedemo:abstractsyntax;

parser parse::Root_c {
  edu:umn:cs:melt:rewritedemo:concretesyntax;
}

function main
IOVal<Integer> ::= args::[String] ioIn::IO
{
  local fileName :: String = head(args);
  local result::IOMonad<Integer> = do {
    if length(args) != 1 then do {
      printM("Usage: java -jar rewritedemo.jar [file name]\n");
      return 1;
    } else do {
      isF::Boolean <- isFileM(fileName);
      if !isF then do {
        printM("File \"" ++ fileName ++ "\" not found.\n");
        return 2;
      } else do {
        text :: String <- readFileM(fileName);
        let result :: ParseResult<Root_c> = parse(text, fileName);
        if !result.parseSuccess then do {
          printM(result.parseErrors ++ "\n");
          return 3;
        } else do {
          let ast::FunDecl = result.parseTree.ast;
          printM(show(80, ast.pp) ++ "\n");
          printM("\n==============\n\n");
          printM("Free variables: " ++ implode(", ", ast.freeVars) ++ "\n");
          printM("\n==============\n\n");
          printM(show(80, ast.optimize.pp) ++ "\n");
          printM("\n==============\n\n");
          printM(show(80, ast.optimizeInline.pp) ++ "\n");
          return 0;
        };
      };
    };
  };
  
  return evalIO(result, ioIn);
}
