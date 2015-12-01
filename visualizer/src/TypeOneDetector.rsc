module TypeOneDetector

import GeneralDetector;
import IO;
import lang::java::m3::AST;
import Debug;

/*
 * Find type 1 duplication in all .java-files at a given location.
 * The location must be specified in the file-scheme, because of usage of lang::java::m3::AST::createAstFromFile
 * or lang::java::m3::AST::createAstsFromDirectory.
 */
public void main(loc location) {
	set[Declaration] asts = locToAsts(location);
	list[value] lines = astsToLines(asts);

	map[list[value], list[loc]] duplicationClasses = findDuplicationClasses(lines);
	
	// for debug purposes
	printToFile(removeAnnotations(duplicationClasses));
	println(removeAnnotations(duplicationClasses));
}
