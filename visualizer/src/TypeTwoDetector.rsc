module TypeTwoDetector

import GeneralDetector;
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;
private int counter;

private list[map[str, str]] symbolTableStack;

public void main(loc location) {
	counter = 0;
	symbolTableStack = [()];
	return printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(standardize(locToAsts(location))))));
}

public set[Declaration] standardize(set[Declaration] asts) = mapper(asts, standardize);

public Declaration standardize(Declaration d) {
	switch(d) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = mapper(types, standardize);
			return copySrc(d, \compilationUnit(imports, newTypes));
		}
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types): {
			list[Declaration] newTypes = mapper(types, standardize);
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
						class = mapper(class, standardize);
						newConstants += (\enumConstant(symbolTable[constantName], newArguments, class));
					}
					else {
					newConstants += (\enumConstant(symbolTable[constantName], newArguments));
					}
				}
			}
			removeLatestSymbolTable();
			return copySrc(d, \enum(symbolTable[name], implements, newConstants, standardize(body, symbolTable)));
		}
		default: return d; //TODO handle other cases
	}
}

public Expression standardize(Expression e) {
	return e; //TODO handle cases
}

public Declaration copySrc(Declaration from, Declaration to) {
	to@src = from@src;
	return to;
}

public void addToSymbolTable(str variable) {
	head(symbolTableStack) += (name: "v<counter>");
	counter += 1;
}

public void createNewSymbolTable() {
	symbolTable = push(head(symbolTableStack), symbolTableStack);
}

public void removeLatestSymbolTable() {
	<_,symbolTable> = pop(symbolTable);
}
