module TypeOneDetector

import IO;
import lang::java::m3::AST;
import List;
import Set;
import Node;

// for debugging purposes
public void printToFile(set[value] s) {
	iprintToFile(|project://visualizer/debugPrintSet.txt|, s);
}

// for debugging purposes
public void printToFile(list[value] l) {
	iprintToFile(|project://visualizer/debugPrintList.txt|, l);
}

/*
 * Get a set of Declarations (an AST) from a location.
 * The location must be a directory and must be specified
 * using the file-scheme. E.g. |file:///C:/Users/Test/ts/Test|.
 */
public set[Declaration] locToAsts(loc fileLocation) {
	if (isFile(fileLocation))
		return { createAstFromFile(fileLocation, false) };
	else
		return createAstsFromDirectory(fileLocation, false);
}


/*
 * Get a list of the lines in a set of Declarations (ASTs) the way they
 * are represented in the ASTs.
 */
public list[list[value]] astsToLines(set[Declaration] decs) = ([] | [*it, dec] | dec <- mapper(decs, declarationToLines));

/*
 * Get a list of the lines in a Declaration (AST) the way they are
 * represented in the AST.
 */
public list[value] declarationToLines(Declaration ast)
{	
	switch (ast) {
		case \compilationUnit(list[Declaration] imports, list[Declaration] types):
			return imports + ([] | it + x | x <- mapper(types, declarationToLines));
		case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types):
			return package + imports + ([] | it + x | x <- mapper(types, declarationToLines));
		case e:\enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body):
			return <e@modifiers, name, "{", e@src> + implements + constants + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		case c:\class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			return <c@modifiers, extImpl, name, "{"> + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		}
		case \class(list[Declaration] body):
			return "{" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		case \interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			return <e@modifiers, extImpl, name, "{"> + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		}
		case f:\field(Type \type, list[Expression] fragments):
			return [f];
		case \initializer(Statement initializerBody):
			return statementToLines(initializerBody);
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			return handleMethodOrConstructor(m@modifiers, \return, name, parameters, exceptions, impl);
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
			return "<m@modifiers> <\return> <name> <parameters>" + exceptions;
		case c:\constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			return handleMethodOrConstructor(c@modifiers, "instance", name, parameters, exceptions, impl);
		default:
			return [];
	}
}

public loc returnFirstLineLocationFromLocation(loc location) {
	return location.scheme + location.path + "(<location.offset>,<location.length>,\<<location.begin.line>, 0\>,\<<location.begin.line>, 0\>)" ;
}

/*
 * Wrapper for evaluation code common to both (non-abstract) methods and constructors.
 */
public list[value] handleMethodOrConstructor(list[Modifier] modifiers, value returnType, str nameOfMethod, list[Declaration] parameters, list[Expression] exceptions, Statement impl) {
	list[value] body = statementToLines(impl);
	return <modifiers, returnType, nameOfMethod, parameters, exceptions, "{"> + body + "}";
}

/*
 * Get a list of lines in a Statement.
 */
public list[value] statementToLines(Statement statement) {
	switch (statement) {
		/* Oneliners */
		case a:\assert(_):
			return [a];
		case a:\assert(_, _):
			return [a];
		case b:\break():
			return [b];
		case b:\break(_):
			return [b];
		case c:\continue():
			return [c];
		case c:\continue(_):
			return [c];
		case l:\label(_, _):
			return [l];
		case r:\return(_):
			return [r];
		case r:\return():
			return [r];
		case c:\case(_):
			return [c];
		case d:\defaultCase():
			return [d];
		case t:\throw(_):
			return [t];
		case d:\declarationStatement(_):
			return [d];
		case c:\constructorCall(_, _, _):
			return [c];
   		case c:\constructorCall(_, _):
   			return [c];
   		/* Multiliners */
		case e:\expressionStatement(_):
			return [e];
		case b:\block(list[Statement] statements):
			return ([] | it + x | x <- mapper(statements, statementToLines));
		case \do(Statement body, Expression condition): {
			return "do {" + statementToLines(body) + <"} while(", condition, ")">;
		}
		case \foreach(Declaration parameter, Expression collection, Statement body):
			return <"foreach", parameter, collection, "{"> + statementToLines(body) + "}";
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body):			
			return <"for", initializers, condition, updaters, "{"> + statementToLines(body) + "}";
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body):
			return <"for", initializers, updaters, "{"> + statementToLines(body) + "}"; 
		case \if(Expression condition, Statement thenBranch):
			return <"if", condition, "{"> + statementToLines(thenBranch) + "}";
		case \if(Expression condition, Statement thenBranch, Statement elseBranch):
			return <"if", condition, "{"> + statementToLines(thenBranch) + "} else {" + statementToLines(elseBranch) + "}";
		case \switch(Expression expression, list[Statement] statements):
			return <"switch (", expression, ") {"> + ([] | it + x | x <- mapper(statements, statementToLines)) + "}";
		case \synchronizedStatement(Expression lock, Statement body):
			return <"synchronized (", lock, ") {"> + statementToLines(body) + "}";
		case \try(Statement body, list[Statement] catchClauses):
			return "try {" + statementToLines(body) + "}" + ([] | it + x | x <- mapper(catchClauses, statementToLines));
    	case \try(Statement body, list[Statement] catchClauses, Statement \finally):
    		return "try {" + statementToLines(body) + "}" + ([] | it + x | x <- mapper(catchClauses, statementToLines)) + "finally {" + statementToLines(\finally) + "}";
    	case \catch(Declaration exception, Statement body):
    		return <"catch (", exception, ") {"> + statementToLines(body) + "}";
    	case \while(Expression condition, Statement body): {
    		return <"while (", condition, ") {"> + statementToLines(body) + "}";
    	}
    	default:
    		return [];
	}
}

public list[set [list [value]]] getDuplicationClasses(list[list[value]] linesPerFile) {
	list[set [list [value]]] duplicationClasses = [];
	
	int i = 0;
	while (i < size(linesPerFile)) {
		if (size(linesPerFile[i]) >= 6)
		{
			for (int j <- [0..(size(linesPerFile[i]) - 5)]) {
				bool foundSomething = false;
				for (set [list [value]] duplicationClass <- duplicationClasses ) {
					set [list [value]] firstElementOfDuplicationClass = head(duplicationClass);
					
					int numberOfLinesOfDuplicationClass = size(firstElementOfDuplicationClass);
					list[value] lines = linesPerFile[i][j..(j + numberOfLinesOfDuplicationClass)];
					
					// compare with initial block of six lines of duplication class
					if (firstElementOfDuplicationClass == lines) {
						duplicationClass += firstFile;
						foundSomething = true;
						break;
					}
				}			
						
				if (!foundSomething) {
					tuple[list[value], loc] largestMatch = <[], |project:///|>; 
					list[value] lines = linesPerFile[i][j..(j + 6)];
					for (int k <- [(j + 6)..size(linesPerFile[i]) - 5]) {
						list[value] blockToCompare = linesPerFile[i][k..(k + 6)];
						
						if (lines == blockToCompare) {
							int l = 0;
							println("yo");
							while ((k + 6 + l) < size(linesPerFile[i]) && linesPerFile[i][(j + l)] == linesPerFile[i][(k + l)]) {
								blockToCompare += linesPerFile[i][(j + l)];
								lines += linesPerFile[i][(j + l)];
								if (size(largestMatch[0]) < size(blockToCompare)) {
									loc startLocation = (head(blockToCompare))@src;
									loc endLocation = (last(blockToCompare))@src;
									loc file = startLocation.scheme + startLocation.path;
									loc startLine = startLocation.begin;
									loc endLine = endLocation.end;
									loc blockLocation = file + startLine + endLine;
									println("bb <blockLocation>");
									//largestMatch = <blockToCompare, >;
								}
							
								l += 1;
							}
						}
					}
				}
			}
		}	

		bool foundSomething = false;
		list[value] firstFile = linesPerFile[i]; 
		for (set [list [value]] duplicationClass <- duplicationClasses ) {
			set [list [value]] firstElementOfDuplicationClass = head(duplicationClass);
			
			if (firstElementOfDuplicationClass == firstFile) {
				duplicationClass += firstFile;
				foundSomething = true;
				break;
			}
		}
		
		if (!foundSomething) {
			int j = i + 1;
			while(j < size(linesPerFile)) {
				list[value] secondFile = linesPerFile[j];
				if (firstFile == secondFile) {
					duplicationClasses += {firstFile, secondFile};
					foundSomething = true;
					break;
				}
			}
		}
		
		i += 1;
	}
	
	return duplicationClasses;
}

public void main(loc location) {
	set[Declaration] asts = locToAsts(location);
	list[value] lines = astsToLines(asts);
	printToFile(lines);
	
	getDuplicationClasses(lines);
}
