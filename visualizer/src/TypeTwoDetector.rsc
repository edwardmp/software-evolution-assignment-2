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
			addToSymbolTable(constantName); // why dont create new stack here?
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
  	top-down-break visit(e) {
  		case \arrayAccess(Expression array, Expression index): {
  			insert copySrc(e, \arrrayAccess(standardize(array), standardize(index)));
  		}
  		case \newArray(Type \type, list[Expression] dimensions, Expression init): {
  			insert copySrc(e, \newArray(standardize(dimensions), standardize(init)));
  		}
   		case \newArray(Type \type, list[Expression] dimensions): {
   			// handle literals
   			insert copySrc(e, \newArray(standardize(dimensions)));
   		}
   		case \arrayInitializer(list[Expression] elements): {
   			insert copySrc(e, \arrayInitializer(standardize(elements))); 
   		}
   		case \assignment(Expression lhs, str operator, Expression rhs): {
   			// left hand side is variable name (e.g. testInt = ), should have been standardized earlier
   			insert copySrc(e, \assignment(standardize(lhs), operator, standardize(rhs)));
   		}
	    case \fieldAccess(bool isSuper, Expression expression, str name) => copySrc(\fieldAccess(isSuper, standardize(expression), retrieveFromCurrentSymbolTable(name)))
	    case \fieldAccess(bool isSuper, str name) => copySrc(\fieldAccess(isSuper, retrieveFromCurrentSymbolTable(name)))
	    case \newObject(Expression expr, Type \type, list[Expression] args, Declaration class) => \newObject(standardize(expr), \type, standardize(args), standardize(class))
    	case \newObject(Type \type, list[Expression] args, Declaration class) => \newObject(\type, standardize(args), standardize(class)) 
		case \simpleName(str name) => copySrc(\simpleName(retrieveFromCurrentSymbolTable(name)))
		/* literals */
		case \booleanLiteral(bool boolValue) => \booleanLiteral(true)
		case \characterLiteral(str charValue): {
   			insert copySrc(e, \characterLiteral("c")); // always the same?
   		}
   		case \number(str numberValue) => \number("1") // assuming this is a number literal
    	case \stringLiteral(str stringValue) => \stringLiteral("string")
    	case \variable(str name, int extraDimensions) => \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \variable(str name, int extraDimensions, Expression \initializer) => \variable(retrieveFromCurrentSymbolTable(name), extraDimensions)
    	case \declarationExpression(Declaration decl) => \declarationExpression(standardize(decl))
    	default: return e;
  	}
}

public list[Expression] standardize(list[Expression] exprs) = [standardize(expr) | expr <- exprs];

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
