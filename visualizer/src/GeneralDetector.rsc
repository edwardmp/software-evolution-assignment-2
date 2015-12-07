module GeneralDetector

import Debug;
import Exception;
import IO;
import lang::java::m3::AST;
import List;
import Map;
import Node;
import Set;

/*
 * Map from each combination of lines appearing at least twice in the analyzed code,
 * to the locations that code appears at.
 */
map[str, list[loc]] duplicationClasses = ();

map[str, tuple[int fileIndex, int lineIndex, int size]] startIndexAndSizeOfFirstElementOfDuplicationClass = ();

/*
 * Defines the least amount of lines considered that would count as a duplicate.
 */
private int minimumDuplicateBlockSizeConsidered = 6;

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
			modifiers = ((e@modifiers)?) ? e@modifiers : [];
			loc startLocation = returnFirstLineLocationFromLocation(getSource(e));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <[modifiers, name, "{"], startLocation> + implements + constants +
			bodyLines + <"}", endLocation>;
		}
		case c:\class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			modifiers = ((c@modifiers)?) ? c@modifiers : [];
			loc startLocation = returnFirstLineLocationFromLocation(getSource(c));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <[modifiers, extImpl, name, "{"], startLocation> +
			bodyLines + <"}", endLocation>;
		}
		case c:\class(list[Declaration] body): {
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			loc startLocation = isEmpty(bodyLines) ? c@src : getSource(head(bodyLines));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <"{", startLocation> + bodyLines + <"}", endLocation>;
		}
		case i:\interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			list[value] bodyLines = ([] | it + x | x <- mapper(body, declarationToLines));
			modifiers = ((i@modifiers)?) ? i@modifiers : [];
			loc startLocation = returnFirstLineLocationFromLocation(getSource(i));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <[modifiers, extImpl, name, "{"], startLocation> + bodyLines + <"}", endLocation>;
		}
		case f:\field(Type \type, list[Expression] fragments):
			return [f];
		case \initializer(Statement initializerBody):
			return statementToLines(initializerBody);
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			list[value] body = statementToLines(impl);
			modifiers = ((m@modifiers)?) ? m@modifiers : [];
			loc startLocation = returnFirstLineLocationFromLocation(getSource(m));
			loc endLocation = getEndSource(startLocation, body);
			return <[modifiers, \return, name, parameters, exceptions, "{"], startLocation> + body + <"}", endLocation>;
		}
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
			modifiers = ((m@modifiers)?) ? m@modifiers : [];
			return <[modifiers, \return, name, parameters], returnFirstLineLocationFromLocation(getSource(m))> + exceptions;
		}
		case c:\constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			list[value] body = statementToLines(impl);
			modifiers = ((c@modifiers)?) ? c@modifiers : [];
			loc startLocation = returnFirstLineLocationFromLocation(getSource(c));
			loc endLocation = getEndSource(startLocation, body);
			return <[modifiers, "instance", name, parameters, exceptions, "{"], startLocation> + body + <"}", endLocation>;
		}
		default:
			return [];
	}
}

/*
 * Get the source of the last line in a list of lines, or the startLocation when the list is empty.
 */
public loc getEndSource(loc startLocation, list[value] bodyLines) {
	if (isEmpty(bodyLines)) {
		return startLocation;
	}
	else {
		return getSource(last(bodyLines));	
	}
}

/*
 * Get the source of a representation of a line, whether it is a part of an AST
 * (a declaration, a statement, or an expression), or a tuple with a location
 * as its last element, as we created while converting the AST to a list of lines.
 */
public loc getSource(Declaration decl) = decl@src;
public loc getSource(Statement stat) = stat@src;
public loc getSource(Expression expr) = expr@src;
public loc getSource(<*value v, loc location>) = location;

/*
 * Remove all annotations from a part of an AST, including all its children.
 */
public Declaration removeAnnotations(Declaration decl) = delAnnotationsRec(decl);
public Statement removeAnnotations(Statement stat) = delAnnotationsRec(stat);
public Expression removeAnnotations(Expression expr) = delAnnotationsRec(expr);

/*
 * Remove all annotations from all elements of a list,
 * which can not contain any elements for which removeAnnotations in not defined.
 */
public list[value] removeAnnotations(list[value] v) {
	return for (val <- v) {
		append (removeAnnotations(val));
	}
}

/*
 * Remove all annotations from a duplication class, represented as map from a list of lines
 * to a list of locations at which these lines appeared.
 */
public map[list[value], list[loc]] removeAnnotations(map[list[value], list[loc]] linesAndLocationMap) {
	map[list[value], list[loc]] result = ();
	for(lines <- linesAndLocationMap) {
		result += (removeAnnotations(lines): linesAndLocationMap[lines]);
	}
	
	return result;
}

/*
 * Remove all annotations from the first element when v is a tuple and return the result.
 * Return v itself in case it is not a tuple with a value and a location.
 */
public value removeAnnotations(value v) { 
	if (<value x, loc location> := v) {
		return removeAnnotations(x);
	}
	else {
		return v;
	}
}

/*
 * Return the location of the first line in a location that ranges over one or more lines.
 */
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
			loc startLocation = getSource(d);
			loc endLocation = getEndSource(startLocation, bodyLines);
			endLocation.end.line += 1;
			return <["do", "{"], returnFirstLineLocationFromLocation(startLocation)> + bodyLines + <["} while(", condition, ")"], endLocation>;
		}
		case f:\foreach(Declaration parameter, Expression collection, Statement body): {
			list[value] bodyLines = statementToLines(body);
			loc startLocation = getSource(f);
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <["foreach", parameter, collection, "{"], returnFirstLineLocationFromLocation(startLocation)> + bodyLines
			+ <"}", endLocation>;
		}
		case f:\for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			list[value] bodyLines = statementToLines(body);		
			loc startLocation = getSource(f);
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <["for", initializers, condition, updaters, "{"], returnFirstLineLocationFromLocation(startLocation)> + bodyLines
			+ <"}", endLocation>;
		}
		case f:\for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			list[value] bodyLines = statementToLines(body);
			loc startLocation = getSource(f);
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <["for", initializers, updaters, "{"], returnFirstLineLocationFromLocation(startLocation)> + bodyLines + <"}", endLocation>;
		} 
		case i:\if(Expression condition, Statement thenBranch): {
			list[value] thenBranchLines = statementToLines(thenBranch);
			loc startLocation = returnFirstLineLocationFromLocation(getSource(i));
			loc thenBranchEndLocation = getEndSource(startLocation, thenBranchLines);
			return <["if", condition, "{"], startLocation> + thenBranchLines + <"}", thenBranchEndLocation>;
		}
		case i:\if(Expression condition, Statement thenBranch, Statement elseBranch): {
			list[value] thenBranchLines = statementToLines(thenBranch);
			list[value] elseBranchLines = statementToLines(elseBranch);
			loc startLocation = returnFirstLineLocationFromLocation(getSource(i));
			loc thenBranchEndLocation = getEndSource(startLocation, thenBranchLines);
			loc endLocation = getEndSource(thenBranchEndLocation, elseBranchLines);
			return <["if", condition, "{"], startLocation> + thenBranchLines
			+ <"} else {", thenBranchEndLocation> + elseBranchLines + <"}", endLocation>;
		}
		case s:\switch(Expression expression, list[Statement] statements): {
			list[value] bodyLines = ([] | it + x | x <- mapper(statements, statementToLines));
			loc startLocation = getSource(s);
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <["switch (", expression, ") {"], returnFirstLineLocationFromLocation(startLocation)>
			+ bodyLines + <"}", endLocation>;
		}
		case s:\synchronizedStatement(Expression lock, Statement body): {
			list[value] bodyLines = statementToLines(body);
			loc startLocation = returnFirstLineLocationFromLocation(getSource(s));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <["synchronized (", lock, ") {"], startLocation> + bodyLines + <"}", endLocation>;
		}
		case t:\try(Statement body, list[Statement] catchClauses): {
			list[value] bodyLines = statementToLines(body);
			loc startLocation = returnFirstLineLocationFromLocation(getSource(t));
			loc endLocation = getEndSource(startLocation, bodyLines);
			return <"try {", startLocation> + bodyLines
			+ <"}", endLocation> + ([] | it + x | x <- mapper(catchClauses, statementToLines));
		}
    	case t:\try(Statement body, list[Statement] catchClauses, Statement \finally): {
    		list[value] bodyLines = statementToLines(body);
    		list[value] finallyLines = statementToLines(\finally);
    		loc startLocation = returnFirstLineLocationFromLocation(getSource(t));
    		loc bodyEndLocation = getEndSource(startLocation, bodyLines);
    		loc finallyStartLocation = isEmpty(finallyLines) ? bodyEndLocation : getSource(head(finallyLines));
    		loc endLocation = getEndSource(finallyStartLocation, finallyLines);
    		return <"try {", startLocation> + bodyLines + <"}", bodyEndLocation>
    		+ ([] | it + x | x <- mapper(catchClauses, statementToLines)) + <"finally {", finallyStartLocation> + finallyLines
    		+ <"}", endLocation>;
    	}
    	case c:\catch(Declaration exception, Statement body): {
    		list[value] bodyLines = statementToLines(body);
    		loc startLocation = returnFirstLineLocationFromLocation(getSource(c));
    		loc endLocation = getEndSource(startLocation, bodyLines);
    		return <["catch (", exception, ") {"], startLocation> + bodyLines + <"}", endLocation>;
    	}
    	case w:\while(Expression condition, Statement body): {
    		list[value] bodyLines = statementToLines(body);
    		loc startLocation = returnFirstLineLocationFromLocation(getSource(w));
    		loc endLocation = getEndSource(startLocation, bodyLines);
    		return <["while (", condition, ") {"], startLocation> + bodyLines + <"}", endLocation>;
    	}
    	default:
    		return [];
	}
}

/*
 * A list is passed which contains a list with lines for each file discovered.
 */
public map[str, list[loc]] findDuplicationClasses(list[list[value]] linesPerFile) {	
	// manually loop through all files, which contain the source lines
	int indexOfCurrentlyProcessedFile = 0;
	while (indexOfCurrentlyProcessedFile < size(linesPerFile)) {
		//printToFile("Currently processing file: <(indexOfCurrentlyProcessedFile + 1)> <(indexOfCurrentlyProcessedFile + 1) / (size(linesPerFile) * 1.0)>");
		list[value] linesForCurrentFileProcessed = linesPerFile[indexOfCurrentlyProcessedFile];
		
		if (size(linesForCurrentFileProcessed) >= minimumDuplicateBlockSizeConsidered) {
			printToFile("Processing file with index <indexOfCurrentlyProcessedFile>, path: <getSource(head(linesPerFile[indexOfCurrentlyProcessedFile])).path>");
			findDuplicationForLinesInFile(linesPerFile, linesForCurrentFileProcessed, indexOfCurrentlyProcessedFile);
		}
		
		indexOfCurrentlyProcessedFile += 1;
	}
	filterDuplicationClasses();
	return duplicationClasses;
}

/*
 * Find duplicates for all lines in a file - within that file and in other files - and add them to
 * the duplication classes.
 */
public void findDuplicationForLinesInFile(list[list[value]] linesPerFile, list[value] linesForCurrentFileProcessed,
int indexOfCurrentlyProcessedFile) {
	int startIndexOfBlockEncountered = 0;
	while (startIndexOfBlockEncountered < (size(linesForCurrentFileProcessed) - minimumDuplicateBlockSizeConsidered)) {
		printToFile("	Comparing block starting at index <startIndexOfBlockEncountered>");
		startIndexOfBlockEncountered += addBlockToDuplicationClass(indexOfCurrentlyProcessedFile, linesPerFile,
			linesForCurrentFileProcessed, startIndexOfBlockEncountered);
	}
}

/*
 * Loop through all currently known duplicate blocks and check if the block from a current line position (startLocationDuplicateBlock)
 * to end position (endLocationDuplicateBlock) matches with that known duplicate block.
 * If so, we've found yet another duplication instance of that block. If not, we've found a new duplication class.
 */
public int addBlockToDuplicationClass(int indexOfCurrentlyProcessedFile, list[list[value]] linesPerFile,
list[value] linesForCurrentFileProcessed, int startIndexOfBlockEncountered) {
	for (str duplicationClass <- duplicationClasses) {
		tuple[int fileIndex, int lineIndex, int size] startIndexAndFile = startIndexAndSizeOfFirstElementOfDuplicationClass[duplicationClass];
		int numberOfLinesOfDuplicationClass = startIndexAndFile.size;
		
		list[value] linesWithAnnotations = linesForCurrentFileProcessed[startIndexOfBlockEncountered..(startIndexOfBlockEncountered + numberOfLinesOfDuplicationClass)];
		loc startLocation = getSource(head(linesWithAnnotations));
		tuple[int, str] startLocationTuple = <startLocation.begin.line, startLocation.path>;
		list[tuple[int, str]] locationsInClass = [<l.begin.line, l.path> | l <- duplicationClasses[duplicationClass]];
		if (startLocationTuple notin locationsInClass) {
			str linesAsStringWithoutAnnotations = toString(removeAnnotations(linesWithAnnotations));
			
			// compare with representative block of duplication class
			if (duplicationClass == linesAsStringWithoutAnnotations) {
				// if only one example of this class was found yet, check for larger duplication block
				if (size(duplicationClasses[duplicationClass]) == 1) {
					int fileIndex = startIndexAndFile.fileIndex;
					int firstLineIndex = startIndexAndFile.lineIndex;
					list[value] linesForFileOfFirstItemInDuplicationClass = linesPerFile[fileIndex];
					list[value] linesForDuplicationBlock
						= linesForFileOfFirstItemInDuplicationClass[firstLineIndex..firstLineIndex + minimumDuplicateBlockSizeConsidered];
						
					int i = minimumDuplicateBlockSizeConsidered;
					// expand duplication class if possible
					while (firstLineIndex + i < size(linesForFileOfFirstItemInDuplicationClass)
						&& startIndexOfBlockEncountered + i < size(linesForCurrentFileProcessed)
						&& linesForFileOfFirstItemInDuplicationClass[firstLineIndex + i]
							== linesForCurrentFileProcessed[startIndexOfBlockEncountered + i]) {
						linesForDuplicationBlock += startIndexOfBlockEncountered + i < size(linesForCurrentFileProcessed);
						linesWithAnnotations += linesForCurrentFileProcessed[startIndexOfBlockEncountered + i];
					}
					
					duplicationClasses = delete(duplicationClasses, duplicationClass);
					loc startLocationDuplicateBlock = getSource(head(linesForDuplicationBlock));
					loc endLocationDuplicateBlock = getSource(last(linesForDuplicationBlock));
					loc locationDuplicateBlock = mergeLocations(startLocationDuplicateBlock, endLocationDuplicateBlock);
					loc startLocationEncounteredBlock = getSource(head(linesWithAnnotations));
					loc endLocationEncounteredBlock = getSource(last(linesWithAnnotations));
					loc locationEncounteredBlock = mergeLocations(startLocationEncounteredBlock, endLocationEncounteredBlock);
					duplicationClasses += (toString(removeAnnotations(linesForDuplicationBlock)):
						[locationDuplicateBlock, locationEncounteredBlock]);
					return size(linesWithAnnotations);
				}
				else {
					loc startLocationDuplicateBlock = getSource(head(linesWithAnnotations));
					loc endLocationDuplicateBlock = getSource(last(linesWithAnnotations));
					
					duplicationClasses[duplicationClass] += mergeLocations(startLocationDuplicateBlock, endLocationDuplicateBlock);
					return size(linesForCurrentFileProcessed);
				}
			}
		}
	}
	
	list[value] block = linesForCurrentFileProcessed[startIndexOfBlockEncountered..startIndexOfBlockEncountered
		+ minimumDuplicateBlockSizeConsidered];
	loc startLocation = getSource(head(block));
	loc endLocation = getSource(last(block));
	loc location = mergeLocations(startLocation, endLocation);
	str blockAsString = toString(removeAnnotations(block));
	duplicationClasses += (blockAsString: [location]);
	startIndexAndSizeOfFirstElementOfDuplicationClass += (blockAsString: <indexOfCurrentlyProcessedFile, startIndexOfBlockEncountered,
		size(block)>);
	
	return 1;
}

/*
 * Remove 'duplication classes' containing only one location.
 */
public void filterDuplicationClasses() {
	duplicationClasses = (c: duplicationClasses[c] | c <- duplicationClasses, size(duplicationClasses[c]) != 1);
}

/*
 * Merge two locations into one by starting at the start of startLocation and ending at then end of endLocation.
 */
public loc mergeLocations(loc startLocation, loc endLocation) {
	startLocation.end.line = endLocation.end.line;
	startLocation.end.column = endLocation.end.column;
	return startLocation;
}
