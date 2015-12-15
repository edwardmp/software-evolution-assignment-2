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
			addToSymbolTable(constantName);
			arguments = standardize(arguments);
			class = standardize(class);
			insert copySrc(d, (\enumConstant(retrieveFromCurrentSymbolTable(constantName), arguments, class)));
		}
		case \class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			body = standardize(body);
			Declaration result = copySrc(d, \class(retrieveFromCurrentSymbolTable(name), extends, implements, body));
			removeStackHeads();
			insert result;
		}
		case \class(list[Declaration] body) => copySrc(d, \class(standardize(body)))
		case \interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			addToSymbolTable(name);
			createNewStacks();
			body = standardize(body);
			Declaration result = copySrc(d, \interface(retrieveFromCurrentSymbolTable(name), extends, implements, body));
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
			Declaration result = copySrc(d, \method(\return, retrieveFromCurrentSymbolTable(name), parameters, exceptions, impl));
			removeStackHeads();
			insert result;
		}
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
			addToSymbolTable(name);
			parameters = standardize(parameters);
			insert copySrc(d, \method(\return, retrieveFromCurrentSymbolTable(name), parameters, exception));
		}
		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			addToSymbolTable(name);
			createNewStacks();
			parameters = standardize(parameters);
			impl = standardize(impl);
			Declaration result = copySrc(d, \constructor(retrieveFromCurrentSymbolTable(name), parameters, exceptions, impl));
			removeStackHeads();
			insert result;
		}
		case \variables(Type \type, list[Expression] \fragments) => copySrc(d, \variables(\type, standardize(\fragments)))
		case \parameter(Type \type, str name, int extraDimensions): {
			addToSymbolTable(name);
			insert copySrc(d, \parameter(\type, retrieveFromCurrentSymbolTable(name), extraDimensions));
		}
		case \vararg(Type \type, str name): {
			addToSymbolTable(name);
			insert copySrc(d, \vararg(\type, retrieveFromCurrentSymbolTable(name)));
		}
	}
}

public list[&T] standardize(list[&T] values) = [standardize(v) | v <- values];

//TODO add cases for "recursion" to other instances of this overloaded method
public Expression standardize(Expression e) {
  	return top-down-break visit(e) {
	    case \fieldAccess(bool isSuper, Expression expression, str name)
	    	=> copySrc(e, \fieldAccess(isSuper, standardize(expression), retrieveFromCurrentSymbolTable(name)))
	    case \fieldAccess(bool isSuper, str name) => copySrc(e, \fieldAccess(isSuper, retrieveFromCurrentSymbolTable(name)))
	    case \newObject(Expression expr, Type \type, list[Expression] args, Declaration class)
	    	=> \newObject(standardize(expr), \type, standardize(args), standardize(class))
    	case \newObject(Type \type, list[Expression] args, Declaration class)
    		=> \newObject(\type, standardize(args), standardize(class)) 
		case \simpleName(str name) => copySrc(e, \simpleName(retrieveFromCurrentSymbolTable(name)))
		/* literals */
		case \booleanLiteral(bool boolValue) => \booleanLiteral(true)
		case \characterLiteral(str charValue) => copySrc(e, \characterLiteral("c")) // always the same?
   		case \number(str numberValue) => \number("1") // assuming this is a number literal
    	case \stringLiteral(str stringValue) => \stringLiteral("string")
    	case \variable(str name, int extraDimensions) => \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \variable(str name, int extraDimensions, Expression \initializer)
    		=> \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \declarationExpression(Declaration decl) => \declarationExpression(standardize(decl))
  	}
}

public Statement standardize(Statement s) {
	return top-down-break visit(s) {
		case \assert(Expression expression) => copySrc(s, \assert(standardize(expression)))
		case \assert(Expression expression, Expression message) => copySrc(s, \assert(standardize(expression), standardize(message)))
		case \block(list[Statement] statements) => copySrc(s, standardize(statements))
		case \break(str label) => copySrc(s, \break(retrieveFromCurrentSymbolTable(label)))
		case \continue(str label) => copySrc(s, \continue(label, \continue(retrieveFromCurrentSymbolTable(label))))
		case \do(Statement body, Expression condition): {
			condition = standardize(condition);
			createNewStacks();
			body = standardize(body);
			removeStackHeads();
			insert copySrc(s, \do(body, condition));
		}
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			collection = standardize(collection);
			createNewStacks();
			parameter = standardize(parameter);
			body = standardize(body);
			removeStackHeads();
			insert copySrc(s, \foreach(parameter, collection, body));
		}
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			createNewStacks();
			Statement result = \for(standardize(initializers), standardize(condition), standardize(updaters), standardize(body));
			removeStackHeads();
			insert result;
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			createNewStacks();
			Statement result = \for(standardize(initializers), standardize(updaters), standardize(body));
			removeStackHeads();
			insert result;
		}
		
		default: insert s; //TODO handle other cases
	}
}

public &T copySrc(&T from, &T to) {
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
