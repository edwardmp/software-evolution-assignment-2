module TypeTwoDetector

import GeneralDetector;
import IO;//debug
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
			constants = standardize(constants);
			body = standardize(body);
			Declaration result = copySrc(d, \enum(head(symbolTableStack)[name], implements, constants, body));
			removeLatestSymbolTable();
			return result;
		}
		case \enumConstant(str constantName, list[Expression] arguments): {
			addToSymbolTable(constantName);
			return copySrc(d, (\enumConstant(head(symbolTableStack)[constantName], arguments)));
		}
		case \enumConstant(str constantName, list[Expression] arguments, Declaration class): {
			addToSymbolTable(constantName);
			arguments = standardize(arguments);
			class = standardize(class);
			return copySrc(d, (\enumConstant(head(symbolTableStack)[constantName], arguments, class)));
		}
		case \class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewSymbolTable();
			list[Declaration] newBody = standardize(body);
			Declaration result = copySrc(d, \class(name, extends, implements, newBody));
			removeLatetestSymbolTable();
			return result;
		}
		default: return d; //TODO handle other cases
	}
}

public list[Declaration] standardize(list[Declaration] decls) = [standardize(decl) | decl <- decls];

public Expression standardize(Expression e) {
	return e; //TODO handle cases
}

public list[Expression] standardize(list[Expression] exprs) = exprs; //TODO handle case

public Declaration copySrc(Declaration from, Declaration to) {
	to@src = from@src;
	return to;
}

public Expression copySrc(Expression from, Expression to) {
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
