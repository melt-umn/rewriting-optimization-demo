grammar edu:umn:cs:melt:rewritedemo:driver;

imports silver:langutil;
imports silver:langutil:pp;

imports edu:umn:cs:melt:rewritedemo:concretesyntax;
imports edu:umn:cs:melt:rewritedemo:abstractsyntax;

parser parse::Root_c {
  edu:umn:cs:melt:rewritedemo:concretesyntax;
}

function main
IOVal<Integer> ::= args::[String] ioIn::IOToken
{
  local fileName :: String = head(args);
  local result::IO<Integer> = do {
    if length(args) != 1 then do {
      print("Usage: java -jar rewritedemo.jar [file name]\n");
      return 1;
    } else do {
      isF::Boolean <- isFile(fileName);
      if !isF then do {
        print("File \"" ++ fileName ++ "\" not found.\n");
        return 2;
      } else do {
        text :: String <- readFile(fileName);
        let result :: ParseResult<Root_c> = parse(text, fileName);
        if !result.parseSuccess then do {
          print(result.parseErrors ++ "\n");
          return 3;
        } else do {
          let ast::FunDecl = result.parseTree.ast;
          print(show(80, ast.pp) ++ "\n");
          print("\n==============\n\n");
          print("Free variables: " ++ implode(", ", ast.freeVars) ++ "\n");
          print("\n==============\n\n");
          print(show(80, ast.optimize.pp) ++ "\n");
          print("\n==============\n\n");
          print(show(80, ast.optimizeInline.pp) ++ "\n");
          return 0;
        };
      };
    };
  };
  
  return evalIO(result, ioIn);
}
