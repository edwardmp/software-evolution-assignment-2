module TypeTwoDetector

import GeneralDetector;
import IO;//debug
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;
import Exception;

private list[int] counterStack;

private list[map[str, str]] symbolTableStack;

public void main(loc location) {
	initialize();
	return printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(standardize(locToAsts(location))))));
}

/*
 * Initializes the symbol table and counter stack
 */
public void initialize() {
	counterStack = [0];
	map[str, str] initialSymbolTable = ();
	symbolTableStack = [initialSymbolTable];
}

/*
 * Loop over all Asts generated from the source files.
 * This will normalize identifiers to faciliate type-2 clone detection.
 */
public set[Declaration] standardize(set[Declaration] asts) = { standardize(ast) | ast <- asts };

public Declaration standardize(Declaration d) {
	return top-down-break visit(d) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types)
			=> copySrc(d, \compilationUnit(imports, standardize(types)))
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types)
			=> copySrc(d, \compilationUnit(package, imports, standardize(types)))
		case \enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			constants = standardize(constants);
			body = standardize(body);
			Declaration result = copySrc(d, \enum(retrieveFromCurrentSymbolTable(name), implements, constants, body));
			removeStackHeads();
			insert result;
		}
		case \enumConstant(str constantName, list[Expression] arguments): {
			addToSymbolTable(constantName);
			insert copySrc(d, (\enumConstant(retrieveFromCurrentSymbolTable(constantName), arguments)));
		}
		case \enumConstant(str constantName, list[Expression] arguments, Declaration class): {
			addToSymbolTable(constantName); // why dont create new stack here?
			arguments = standardize(arguments);
			class = standardize(class);
			insert copySrc(d, (\enumConstant(retrieveFromCurrentSymbolTable(constantName), arguments, class)));
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
  	return top-down-break visit(e) {
	    case \fieldAccess(bool isSuper, Expression expression, str name) => copySrc(\fieldAccess(isSuper, standardize(expression), retrieveFromCurrentSymbolTable(name)))
	    case \fieldAccess(bool isSuper, str name) => copySrc(\fieldAccess(isSuper, retrieveFromCurrentSymbolTable(name)))
	    case \newObject(Expression expr, Type \type, list[Expression] args, Declaration class) => \newObject(standardize(expr), \type, standardize(args), standardize(class))
    	case \newObject(Type \type, list[Expression] args, Declaration class) => \newObject(\type, standardize(args), standardize(class)) 
		case \simpleName(str name) => copySrc(\simpleName(retrieveFromCurrentSymbolTable(name)))
		/* literals */
		case \booleanLiteral(bool boolValue) => \booleanLiteral(true)
		case \characterLiteral(str charValue) => copySrc(e, \characterLiteral("c")) // always the same?
   		case \number(str numberValue) => \number("1") // assuming this is a number literal
    	case \stringLiteral(str stringValue) => \stringLiteral("string")
    	case \variable(str name, int extraDimensions) => \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \variable(str name, int extraDimensions, Expression \initializer) => \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \declarationExpression(Declaration decl) => \declarationExpression(standardize(decl))
    	default: return e;
  	}
}

public list[Expression] standardize(list[Expression] exprs) = [standardize(expr) | expr <- exprs];

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

public str retrieveFromCurrentSymbolTable(str constantName) {
	if (size(symbolTableStack) == 0) {
		throw AssertionFailed("No symbol tables initialized.");
	}
	
	return head(symbolTableStack)[constantName];
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
