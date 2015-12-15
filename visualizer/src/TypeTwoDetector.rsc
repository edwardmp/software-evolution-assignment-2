module TypeTwoDetector

import GeneralDetector;
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;
import Exception;

/*
 * Stack of counters for each scope in which the currently analyzed line is nested, used for standardizing variables etc.
 */
private list[int] counterStack;

/*
 * Stack of symbol tables for each scope in which the currently analyzed line is nested
 * A symbol table is a map from the original name of a variable to the standardized name for that variable.
 */
private list[map[str, str]] symbolTableStack;

/*
 * Main method to detect type-2 clones in a specified location.
 */
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

/*
 * Standardize a Declaration.
 */
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
		case \field(Type \type, list[Expression] fragments): {
			addVariablesToSymbolTable(fragments);
			insert copySrc(d, \field(\type, standardize(fragments)));
		}
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
		case \variables(Type \type, list[Expression] \fragments): {
			addVariablesToSymbolTable(fragments);
			insert copySrc(d, \variables(\type, standardize(\fragments)));
		}
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

/*
 * Add all variables in a list of expressions to the symbol table.
 */
public void addVariablesToSymbolTable(list[Expression] exprs) {
	for (expr <- exprs) {
		if (\variable(str name, _) := expr || \variable(str name, _, _) := expr) {
			addToSymbolTable(name);
		}
	}
}

/*
 * Standardize alle elements of a list.
 */
public list[&T] standardize(list[&T] values) = [standardize(v) | v <- values];

/*
 * Standardize an Expression.
 */
public Expression standardize(Expression e) {
  	return top-down-break visit(e) {
  		case \newArray(Type \type, list[Expression] dimensions, Expression init) => copySrc(e, \newArray(\type, standardize(dimensions), standardize(init)))
   		case \newArray(Type \type, list[Expression] dimensions) => copySrc(e, \newArray(\type, standardize(dimensions)))
   		case \arrayInitializer(list[Expression] elements) => copySrc(e, \arrayInitializer(standardize(elements)))
	    case \fieldAccess(bool isSuper, Expression expression, str name) => copySrc(e, \fieldAccess(isSuper, standardize(expression), retrieveFromCurrentSymbolTable(name)))
	    case \fieldAccess(bool isSuper, str name) => copySrc(e, \fieldAccess(isSuper, retrieveFromCurrentSymbolTable(name)))
	    case \methodCall(bool isSuper, str name, list[Expression] arguments) => copySrc(e, \methodCall(isSuper, name, standardize(arguments)))
    	case \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments) => copySrc(e, \methodCall(isSuper, receiver, name, standardize(arguments)))
	    case \newObject(Expression expr, Type \type, list[Expression] args, Declaration class) => copySrc(e, \newObject(standardize(expr), \type, standardize(args), standardize(class)))
    	case \newObject(Type \type, list[Expression] args, Declaration class) => copySrc(e, \newObject(\type, standardize(args), standardize(class)))
    	case \newObject(Expression expr, Type \type, list[Expression] args) => copySrc(e, \newObject(standardize(expr), \type, standardize(args)))
    	case \newObject(Type \type, list[Expression] args) => copySrc(e, \newObject(\type, standardize(args)))
		case \simpleName(str name) => copySrc(e, \simpleName(retrieveFromCurrentSymbolTable(name)))
		/* literals */
		case \booleanLiteral(bool boolValue) => copySrc(e, \booleanLiteral(false))
		case \characterLiteral(str charValue) => copySrc(e, \characterLiteral("c"))
   		case \number(str numberValue) => copySrc(e, \number("1"))
    	case \stringLiteral(str stringValue) => copySrc(e, \stringLiteral("string"))
    	/* variables */
    	case \variable(str name, int extraDimensions) => copySrc(e, \variable(retrieveFromCurrentSymbolTable(name), extraDimensions))
    	case \variable(str name, int extraDimensions, Expression \initializer) => copySrc(e, \variable(retrieveFromCurrentSymbolTable(name), extraDimensions, standardize(initializer)))
    	case \declarationExpression(Declaration decl) => copySrc(e, \declarationExpression(standardize(decl)))
  	}
}

/*
 * Standardize a Statement.
 */
public Statement standardize(Statement s) {
	return top-down-break visit(s) {
		case \assert(Expression expression) => copySrc(s, \assert(standardize(expression)))
		case \assert(Expression expression, Expression message) => copySrc(s, \assert(standardize(expression), standardize(message)))
		case \block(list[Statement] statements) => copySrc(s, \block(standardize(statements)))
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
			Statement result = copySrc(s,
				\for(standardize(initializers), standardize(condition), standardize(updaters), standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			createNewStacks();
			Statement result = copySrc(s, \for(standardize(initializers), standardize(updaters), standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \if(Expression condition, Statement thenBranch): {
			condition = standardize(condition);
			createNewStacks();
			Statement result = copySrc(s, \if(condition, standardize(thenBranch)));
			removeStackHeads();
			insert result;
		}
		case \if(Expression condition, Statement thenBranch, Statement elseBranch):{
			condition = standardize(condition);
			createNewStacks();
			thenBranch = standardize(thenBranch);
			removeStackHeads();
			createNewStacks();
			elseBranch = standardize(elseBranch);
			removeStackHeads();
			insert copySrc(s, \if(conditioon, thenBranch, elseBranch));
		}
		case \label(str name, Statement body): {
			addToSymbolTable(name);
			createNewStacks();
			Statement result = copySrc(s, \label(retrieveFromCurrentSymbolTable(name), standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \return(Expression expression) => copySrc(s, \return(standardize(expression)))
		case \switch(Expression expression, list[Statement] statements): {
			expression = standardize(expression);
			createNewStack();
			Statement result = copySrc(s, \switch(expression, standardize(statements)));
			removeStackHeads();
			insert result;
		}
		case \case(Expression expression): {
			createNewStack();
			Statement result = copySrc(s, \case(standardize(expression)));
			removeStackHeads();
			insert result;
		}
		case \synchronizedStatement(Expression lock, Statement body): {
			lock = standardize(lock);
			createNewStacks();
			Statement result = copySrc(s, \synchronizedStatement(lock, standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \throw(Expression expression) => copySrc(s, \throw(standardize(expression)))
		case \try(Statement body, list[Statement] catchClauses): {
			createNewStacks();
			body = standardize(body);
			removeStackHeads();
			catchClauses = standardize(catchClauses);
			insert copySrc(s, \try(body, catchClauses));
		}
		case \try(Statement body, list[Statement] catchClauses, Statement \finally): {
			createNewStacks();
			body = standardize(body);
			removeStackHeads();
			catchClauses = standardize(catchClauses);
			\finally = standardize(\finally);
			insert copySrc(s, \try(body, catchClauses, \finally));
		}
		case \catch(Declaration exception, Statement body): {
			exception = standardize(exception);
			createNewStacks();
			Statement result = copySrc(s, \catch(exception, standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \declarationStatement(Declaration declaration) => copySrc(s, \declarationStatement(standardize(declaration)))
		case \while(Expression condition, Statement body): {
			condition = standardize(condition);
			createNewStacks();
			Statement result = copySrc(s, \while(condtion, standardize(body)));
			removeStackHeads();
			insert result;
		}
		case \expressionStatement(Expression stmt) => copySrc(s, \expressionStatement(standardize(stmt)))
		case \constructorCall(bool isSuper, Expression expr, list[Expression] arguments)
			=> copySrc(s, \constructorCall(isSuper, standardize(expr), standardize(arguments)))
		case \constructorCall(bool isSuper, list[Expression] arguments)
			=> copySrc(s, \constructorCall(isSuper, standardize(arguments)))
	}
}

/*
 * Copy the value of the src-annotation of some value to another value of the same type, if it is present.
 */
public &T copySrc(&T from, &T to) {
	if (from@src ?) {
		to@src = from@src;
	}
	return to;
}

/*
 * Add a str to the current symbol table (mapped to a new standardized name.
 */
public void addToSymbolTable(str variable) {
	symbolTableStack[0] += (variable: reserveNewName());
}

/*
 * Retrieve the standardized name for some str from the current symbol table.
 */
public str retrieveFromCurrentSymbolTable(str constantName) {
	if (size(symbolTableStack) == 0) {
		throw AssertionFailed("No symbol tables initialized.");
	}
	
	return head(symbolTableStack)[constantName];
}

/*
 * Reserve a name for a new thing that has to be given a standardized name.
 */
public str reserveNewName() {
	str tempResult = "v<head(counterStack)>";
	counterStack[0] += 1;
	return tempResult;
}

/*
 * Add a new element that is a copy of the current head to the counterStack and symbolTableStack.
 */
public void createNewStacks() {
	counterStack = push(0, counterStack);
	symbolTableStack = push(head(symbolTableStack), symbolTableStack);
}

/*
 * Remove the heads of the counterStack and symbolTableStack.
 */
public void removeStackHeads() {
	tuple[map[str, str] head, list[map[str, str]] tail] symbolTableTuple = pop(symbolTableStack);
	symbolTableStack = symbolTableTuple.tail;
	tuple[int head, list[int] tail] counterTuple = pop(counterStack);
	counterStack = counterTuple.tail;
}
