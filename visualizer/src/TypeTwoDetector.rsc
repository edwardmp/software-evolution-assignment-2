module TypeTwoDetector

import GeneralDetector;
import lang::java::m3::AST;
import Printer;

public void main(loc location) = printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(standardize(locToAsts(location))))));

public set[Declaration] standardize(set[Declaration] asts) =
	{standardize(ast, (), 0) | ast <- asts};

public Declaration standardize(Declaration d, map[str, str] symbolTable, int counter) {
	switch(d) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = [standardize(\type, symbolTable, counter) | \type <- types];
			return copySrc(d, \compilationUnit(imports, newTypes));
		}
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = [standardize(\type, symbolTable, counter) | \type <- types];
			return copySrc(d, \compilationUnit(package, imports, standardize(types, symbolTable, counter)));
		}
		case \enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			symbolTable += (name: "v<counter>");
			counter += 1;
			list[Declaration] newConstants = [];
			for (constant <- constants) {
				// All cases, if-statement for binding arguments only
				if (\enumConstant(str constantName, list[Expression] arguments, _) := constant
				|| \enumConstant(str constantName, list[Expression] arguments) := constant) {
					symbolTable += (constantName: "v<counter>");
					counter += 1;
					newArguments = [standardize(argument, symbolTable, counter) | argument <- arguments];
					if (\enumConstant(str constantName, list[Expression] arguments, list[Declaration] class) := constant) {
						class = standardize(class, symbolTable, counter);
						newConstants += (\enumConstant(symbolTable[constantName], newArguments, class));
					}
					else {
					newConstants += (\enumConstant(symbolTable[constantName], newArguments));
					}
				}
			}
			return copySrc(d, \enum(symbolTable[name], implements, newConstants, standardize(body, symbolTable, counter)));
		}
		default: return d; //TODO handle other cases
	}
}

public list[Declaration] standardize(list[Declaration] decls, map[str, str] symbolTable, int counter) {
	return decls; //TODO handle body
}

public Expression standardize(Expression e, map[str, str] symbolTable, int counter) {
	return e; //TODO handle cases
}

public Declaration copySrc(Declaration from, Declaration to) {
	to@src = from@src;
	return to;
}
