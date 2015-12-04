module TypeOneDetector

import GeneralDetector;
import IO;
import lang::java::m3::AST;
import Debug;
import util::Benchmark;
import util::Math;

/*
 * Find type 1 duplication in all .java-files at a given location.
 * The location must be specified in the file-scheme, because of usage of lang::java::m3::AST::createAstFromFile
 * or lang::java::m3::AST::createAstsFromDirectory.
 */
public void main(loc location) {
	int startTime = getNanoTime();
	set[Declaration] asts = locToAsts(location);
	list[value] lines = astsToLines(asts);

	map[str, list[loc]] duplicationClasses = findDuplicationClasses(lines);
	int endTime = getNanoTime();
	// for debug purposes
	printToFile(duplicationClasses);
	//println(duplicationClasses);
	printToFile(toString(endTime-startTime));
}
