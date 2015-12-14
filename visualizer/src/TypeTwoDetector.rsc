module TypeTwoDetector

import GeneralDetector;
import IO;//debug
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;

private list[int] counterStack;

private list[map[str, str]] symbolTableStack;

public void main(loc location) {
	initialize();
	return printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(standardize(locToAsts(location))))));
}

public void initialize() {
	counterStack = [0];
	map[str, str] initialSymbolTable = ();
	symbolTableStack = [initialSymbolTable];
}

public set[Declaration] standardize(set[Declaration] asts) = {standardize(ast) |  ast <- asts};

public Declaration standardize(Declaration d) {
	top-down-break visit(d) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types)
			=> copySrc(d, \compilationUnit(imports, standardize(types)))
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types)
			=> copySrc(d, \compilationUnit(package, imports, standardize(types)))
		case \enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			constants = standardize(constants);
			body = standardize(body);
			Declaration result = copySrc(d, \enum(head(symbolTableStack)[name], implements, constants, body));
			removeStackHeads();
			insert result;
		}
		case \enumConstant(str constantName, list[Expression] arguments): {
			addToSymbolTable(constantName);
			insert copySrc(d, (\enumConstant(head(symbolTableStack)[constantName], arguments)));
		}
		case \enumConstant(str constantName, list[Expression] arguments, Declaration class): {
			addToSymbolTable(constantName);
			arguments = standardize(arguments);
			class = standardize(class);
			insert copySrc(d, (\enumConstant(head(symbolTableStack)[constantName], arguments, class)));
		}
		case \class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			list[Declaration] newBody = standardize(body);
			Declaration result = copySrc(d, \class(name, extends, implements, newBody));
			removeStackHeads();
			insert result;
		}
		case \class(list[Declaration] body) => copySrc(d, \class(standardize(body)))
		case \interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			body = standardize(body);
			Declaration result = copySrc(d, \interface(name, extends, implements, body));
			removeStackHeads();
			insert result;
		}
		case \field(Type \type, list[Expression] fragments)
			=> copySrc(d, \field(\type, standardize(fragments)))
		case \initializer(Statement initializerBody)
			=> copySrc(d, \initializer(standardize(initializerBody)))
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			addToSymbolTable(name);
			createNewStacks();
			parameters = standardize(parameters);
			impl = standardize(impl);
			Declaration result = copySrc(d, \method(\return, name, parameters, exceptions, impl));
			removeStackHeads();
			insert result;
		}
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
			addToSymbolTable(name);
			parameters = standardize(parameters);
			insert copySrc(d, \method(\return, name, parameters, exception));
		}
		// TODO handle other cases
	}
}

public list[Declaration] standardize(list[Declaration] decls) = [standardize(decl) | decl <- decls];

public Expression standardize(Expression e) {
  	top-down visit(e) {
  		case \arrayAccess(Expression array, Expression index): {
  			standardize(array);
  			standardize(index);
  		}
  	}
	return e; //TODO handle cases
}

public list[Expression] standardize(list[Expression] exprs) = exprs; //TODO handle case

public Statement standardize(Statement stat) = stat; //TODO handle case

public Declaration copySrc(Declaration from, Declaration to) {
	to@src = from@src;
	return to;
}

public Expression copySrc(Expression from, Expression to) {
	to@src = from@src;
	return to;
}

public void addToSymbolTable(str variable) {
	symbolTableStack[0] += (variable: newNameForLiteral());
}

public str newNameForLiteral() {
	str tempResult = "v<head(counterStack)>";
	counterStack[0] += 1;
	return tempResult;
}

public void createNewStacks() {
	push(0, counterStack);
	push(head(symbolTableStack), symbolTableStack);
}

public void removeStackHeads() {
	<_, symbolTableStack> = pop(symbolTableStack);
	<_, counterStack> = pop(counterStack);
}
