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
		case \compilationUnit(list[Declaration] imports, list[Declaration] types): {
			types = standardize(types);
			return copySrc(d, \compilationUnit(imports, types));
		}
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types): {
			types = standardize(types);
			return copySrc(d, \compilationUnit(package, imports, standardize(types)));
		}
		case \enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			constants = standardize(constants);
			body = standardize(body);
			Declaration result = copySrc(d, \enum(head(symbolTableStack)[name], implements, constants, body));
			removeStackHeads();
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
			createNewStacks();
			list[Declaration] newBody = standardize(body);
			Declaration result = copySrc(d, \class(name, extends, implements, newBody));
			removeStackHeads();
			return result;
		}
		case \class(list[Declaration] body): {
			body = standardize(body);
			return copySrc(d, \class(body));
		}
		case \interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			body = standardize(body);
			Declaration result = copySrc(d, \interface(name, extends, implements, body));
			removeStackHeads();
			return result;
		}
		case \field(Type \type, list[Expression] fragments): {
			fragments = standardize(fragments);
			return copySrc(d, \field(\type, fragments));
		}
		case \initializer(Statement initializerBody): {
			initializerBody = standardize(initializerBody);
			return copySrc(d, \initializer(initializerBody));
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
	symbolTableStack[0] += (variable: "v<head(counterStack)>");
	counterStack[0] += 1;
}

public void createNewStacks() {
	push(0, counterStack);
	push(head(symbolTableStack), symbolTableStack);
}

public void removeStackHeads() {
	<_, symbolTableStack> = pop(symbolTableStack);
	<_, counterStack> = pop(counterStack);
}
