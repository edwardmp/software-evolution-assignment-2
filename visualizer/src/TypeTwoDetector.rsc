module TypeTwoDetector

import GeneralDetector;
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;
private int counter;

private list[map[str, str]] symbolTableStack;

public void main(loc location) {
	initialize();
	return printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(standardize(locToAsts(location))))));
}

public void initialize() {
	counter = 0;
	map[str, str] initialSymbolTable = ();
	symbolTableStack = [initialSymbolTable];
}

public set[Declaration] standardize(set[Declaration] asts) = {standardize(ast) |  ast <- asts};

public Declaration standardize(Declaration d) {
	switch(d) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = [standardize(\type) | \type <- types];
			return copySrc(d, \compilationUnit(imports, newTypes));
		}
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = [standardize(\type) | \type <- types];
			return copySrc(d, \compilationUnit(package, imports, standardize(types)));
		}
		case \enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			addToSymbolTable(name);
			createNewSymbolTable();
			list[Declaration] newConstants = [];
			for (constant <- constants) {
				// All cases, if-statement for binding arguments only
				if (\enumConstant(str constantName, list[Expression] arguments, _) := constant
				|| \enumConstant(str constantName, list[Expression] arguments) := constant) {
					addToSymbolTable(constantName);
					newArguments = [standardize(argument) | argument <- arguments];
					if (\enumConstant(str constantName, list[Expression] arguments, list[Declaration] class) := constant) {
						class = [standardize(elem) | elem <- class];
						newConstants += copySrc(constant, (\enumConstant(symbolTable[constantName], newArguments, class)));
					}
					else {
					newConstants += copySrc(constant, (\enumConstant(head(symbolTableStack)[constantName], newArguments)));
					}
				}
			}
			Declaration result = copySrc(d, \enum(head(symbolTableStack)[name], implements, newConstants, standardize(body)));
			removeLatestSymbolTable();
			return result;
		}
		default: return d; //TODO handle other cases
	}
}

public list[Declaration] standardize(list[Declaration] decls) = [standardize(decl) | decl <- decls];

public Expression standardize(Expression e) {
	return e; //TODO handle cases
}

public Declaration copySrc(Declaration from, Declaration to) {
	to@src = from@src;
	return to;
}

public void addToSymbolTable(str variable) {
	symbolTableStack[0] += (variable: "v<counter>");
	counter += 1;
}

public void createNewSymbolTable() {
	push(head(symbolTableStack), symbolTableStack);
}

public void removeLatestSymbolTable() {
	<_,symbolTableStack> = pop(symbolTableStack);
}
