module TypeOneDetector

import Prelude;
import IO;
import lang::java::m3::AST;
import List;
import Set;
import Node;
import Exception;

private map[str, loc] locationForDuplicateBlock = ();

/*
 * Defines the least amount of lines considered that would count as a duplicate.
 */
private int minimumDuplicateBlockSizeConsidered = 6;

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
		case e:\enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			return <[e@modifiers, name, "{"], returnFirstLineLocationFromLocation(getSource(e))> + implements + constants +
			bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case c:\class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			return <[c@modifiers, extImpl, name, "{"], returnFirstLineLocationFromLocation(getSource(c))> +
			bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case \class(list[Declaration] body): {
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			return <"{", getSource(head(bodyLines))> + bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case i:\interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			return <[e@modifiers, extImpl, name, "{"], returnFirstLineLocationFromLocation(getSource(i))> + bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case f:\field(Type \type, list[Expression] fragments):
			return [f];
		case \initializer(Statement initializerBody):
			return statementToLines(initializerBody);
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			list[value] body = statementToLines(impl);
			return <[m@modifiers, \return, name, parameters, exceptions, "{"], returnFirstLineLocationFromLocation(getSource(m))> + body + <"}", getSource(last(body))>;
		}
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
			return <[m@modifiers, \return, name, parameters], returnFirstLineLocationFromLocation(getSource(m))> + exceptions;
		case c:\constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			list[value] body = statementToLines(impl);
			return <[c@modifiers, "instance", name, parameters, exceptions, "{"], returnFirstLineLocationFromLocation(getSource(c))> + body + <"}", getSource(last(body))>;
		}
		default:
			return [];
	}
}

public loc getSource(Declaration decl) = decl@src;

public loc getSource(Statement stat) = stat@src;

public loc getSource(Expression expr) = expr@src;

public loc getSource(<*value v, loc location>) = location;

public Declaration removeAnnotations(Declaration decl) = delAnnotationsRec(decl);

public Statement removeAnnotations(Statement stat) = delAnnotationsRec(stat);

public Expression removeAnnotations(Expression expr) = delAnnotationsRec(expr);

public list[value] removeAnnotations(list[value] v) {
	return for (val <- v) {
		append (removeAnnotations(val));
	}
}

public value removeAnnotations(value v) { 
	if (<value x, loc location> := v) {
		return removeAnnotations(x);
	}
	else {
		return v;
	}
}

public loc returnFirstLineLocationFromLocation(loc location) {
	location.length = 0;
	location.begin.column = 0;
	location.end.line = location.begin.line;
	location.end.column = 0;
	return location;
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
		case d:\do(Statement body, Expression condition): {
			list[value] bodyLines = statementToLines(body);
			loc location = getSource(last(bodyLines));
			location.end.line += 1;
			return <["do", "{"], returnFirstLineLocationFromLocation(getSource(d))> + bodyLines + <["} while(", condition, ")"], location>;
		}
		case f:\foreach(Declaration parameter, Expression collection, Statement body): {
			list[value] bodyLines = statementToLines(body);
			return <["foreach", parameter, collection, "{"], returnFirstLineLocationFromLocation(getSource(f))> + bodyLines
			+ <"}", getSource(last(bodyLines))>;
		}
		case f:\for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			list[value] bodyLines = statementToLines(body);		
			return <["for", initializers, condition, updaters, "{"], returnFirstLineLocationFromLocation(getSource(f))> + bodyLines
			+ <"}", getSource(last(bodyLines))>;
		}
		case f:\for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			list[value] bodyLines = statementToLines(body);
			return <["for", initializers, updaters, "{"], returnFirstLineLocationFromLocation(getSource(f))> + bodyLines + <"}", getSource(last(bodyLines))>;
		} 
		case i:\if(Expression condition, Statement thenBranch): {
			list[value] thenBranchLines = statementToLines(thenBranch);
			return <["if", condition, "{"], returnFirstLineLocationFromLocation(getSource(i))> + thenBranchLines + <"}", getSource(last(thenBranchLines))>;
		}
		case i:\if(Expression condition, Statement thenBranch, Statement elseBranch): {
			list[value] thenBranchLines = statementToLines(thenBranch);
			list[value] elseBranchLines = statementToLines(elseBranch);
			return <["if", condition, "{"], returnFirstLineLocationFromLocation(getSource(i))> + thenBranchLines
			+ <"} else {", getSource(last(thenBranchLines))> + elseBranchLines + <"}", getSource(last(elseBranchLines))>;
		}
		case s:\switch(Expression expression, list[Statement] statements): {
			list[value] bodyLines = ([] | it + x | x <- mapper(statements, statementToLines));
			return <["switch (", expression, ") {"], returnFirstLineLocationFromLocation(getSource(s))>
			+ bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case s:\synchronizedStatement(Expression lock, Statement body): {
			list[value] bodyLines = statementToLines(body);
			return <["synchronized (", lock, ") {"], returnFirstLineLocationFromLocation(getSource(s))> + bodyLines + <"}", getSource(last(bodyLines))>;
		}
		case t:\try(Statement body, list[Statement] catchClauses): {
			list[value] bodyLines = statementToLines(body);
			return <"try {", returnFirstLineLocationFromLocation(getSource(t))> + bodyLines
			+ <"}", getSource(last(bodyLines))> + ([] | it + x | x <- mapper(catchClauses, statementToLines));
		}
    	case t:\try(Statement body, list[Statement] catchClauses, Statement \finally): {
    		list[value] bodyLines = statementToLines(body);
    		list[value] finallyLines = statementToLines(\finally);
    		return <"try {", returnFirstLineLocationFromLocation(getSource(t))> + bodyLines + <"}", getSource(last(bodyLines))>
    		+ ([] | it + x | x <- mapper(catchClauses, statementToLines)) + <"finally {", getSource(first(finallyLines))> + finallyLines
    		+ <"}", getSource(last(finallyLines))>;
    	}
    	case c:\catch(Declaration exception, Statement body): {
    		list[value] bodyLines = statementToLines(body);
    		return <["catch (", exception, ") {"], returnFirstLineLocationFromLocation(getSource(c))> + bodyLines + <"}", getSource(last(bodyLines))>;
    	}
    	case w:\while(Expression condition, Statement body): {
    		list[value] bodyLines = statementToLines(body);
    		return <["while (", condition, ") {"], returnFirstLineLocationFromLocation(getSource(w))> + bodyLines + <"}", getSource(last(bodyLines))>;
    	}
    	default:
    		return [];
	}
}

/*
 * A list is passed which contains a list with lines for each file discovered.
 */
public list[list [list [value]]] getDuplicationClasses(list[list[value]] linesPerFile) {
	list[list [list [value]]] duplicationClasses = [];
	
	// manually loop through all files, which contain the source lines
	int i = 0;
	while (i < size(linesPerFile)) {
		list[value] linesForCurrentFileProcessed = linesPerFile[i];
		
		if (size(linesForCurrentFileProcessed ) >= minimumDuplicateBlockSizeConsidered) {
			for (int j <- [0..(size(linesForCurrentFileProcessed) - (minimumDuplicateBlockSizeConsidered - 1))]) {
				//println("Comparing from file <i> line <j> with existing duplication classes");
				bool foundSomething = false;
				
				// Loop through all currently known duplicate blocks and check if the block starting at current position
				// plus amount of lines of known duplicate block matches with that known duplicate block.
				// If so, we've found yet another duplication instance of that block.
				for (set [list [value]] duplicationClass <- duplicationClasses ) {
					set [list [value]] firstElementOfDuplicationClass = head(duplicationClass);
					
					int numberOfLinesOfDuplicationClass = size(firstElementOfDuplicationClass);
					list[value] lines = linesPerFile[i][j..(j + numberOfLinesOfDuplicationClass)];
					
					// compare with representative block of duplication class
					if (firstElementOfDuplicationClass == lines) {
						duplicationClass += linesForCurrentFileProcessed;
						foundSomething = true;
						break;
					}
				}
				
				// no match yet, try to find duplicate in same file
				if (!foundSomething) {
					list[value] largestOriginal = [];
					tuple[list[value], loc] largestMatch = <[], |project:///|>; 
					
					list[value] lines = linesForCurrentFileProcessed[j..(j + minimumDuplicateBlockSizeConsidered)];
					for (int k <- [(j + minimumDuplicateBlockSizeConsidered)..size(linesForCurrentFileProcessed) - (minimumDuplicateBlockSizeConsidered - 1)]) {
						list[value] blockToCompare = linesForCurrentFileProcessed[k..(k + minimumDuplicateBlockSizeConsidered)];
						
						// remove annotations such as @src because they will let the equality check fail though their lines are equal
						if (removeAnnotations(lines) == removeAnnotations(blockToCompare)) {
							int l = minimumDuplicateBlockSizeConsidered;				
							
							// increase duplicate block size by one line each iteration to see if an even larger match can be found	
							while ((k + l) < size(linesForCurrentFileProcessed) && linesForCurrentFileProcessed[(j + l)] == linesForCurrentFileProcessed[(k + l)]) {
								blockToCompare += linesForCurrentFileProcessed[(j + l)];
								lines += linesForCurrentFileProcessed[(j + l)];
								l += 1;
							}
							
							// we have found a new largest match, store it
							if (size(largestMatch[0]) < size(blockToCompare)) {
								loc startLocation = getSource(head(blockToCompare));
								loc endLocation = getSource(last(blockToCompare));

								startLocation.end.column = endLocation.end.column;
								startLocation.end.line = endLocation.end.line;

								largestOriginal = lines;
								largestMatch = <blockToCompare, startLocation>;
							}
						}
					}
					
					// duplication found
					if (size(largestOriginal) >= 1) {						
						// 'remember' location of duplicate blocks
						str blockWithLinesToOneString = toString(largestMatch[0]);
						locationForDuplicateBlock[blockWithLinesToOneString] = largestMatch[1];

						duplicationClasses = [*duplicationClasses, [largestOriginal, largestMatch[0]]]; // first index of largestMatch is blockToCompare value
					}
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

	list[list[list[value]]] duplicationClasses = getDuplicationClasses(lines);
	
	// for debug purposes
	printToFile(removeAnnotations(duplicationClasses));
	println(range(locationForDuplicateBlock));
}
