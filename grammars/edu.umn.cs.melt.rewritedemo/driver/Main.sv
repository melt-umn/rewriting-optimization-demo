grammar edu:umn:cs:melt:rewritedemo:driver;

imports core:monad;
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
  local result::IOMonad<Integer> = do (bindIO, returnIO) {
    if length(args) != 1 then {
      printM("Usage: java -jar rewritedemo.jar [file name]\n");
      return 1;
    } else {
      isF::Boolean <- isFileM(fileName);
      if !isF then {
        printM("File \"" ++ fileName ++ "\" not found.\n");
        return 2;
      } else {
        text :: String <- readFileM(fileName);
        result :: ParseResult<Root_c> = parse(text, fileName);
        if !result.parseSuccess then {
          printM(result.parseErrors ++ "\n");
          return 3;
        } else {
          ast::Root = result.parseTree.ast;
          printM(show(80, ast.pp) ++ "\n\n============\n\n");
          printM(show(80, ast.optimizeInline.pp) ++ "\n");
          return 0;
        }
      }
    }
  };
  
  return evalIO(result, ioIn);
}
