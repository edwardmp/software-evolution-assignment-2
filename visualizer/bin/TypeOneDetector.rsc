module TypeOneDetector

import IO;
import lang::java::m3::AST;

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

public void treeToFile(set[Declaration] asts) {
	list[Statement] methods = [];
	visit(asts) {
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
			methods += impl;
	}
	
	println("comparison: <methods> <methods[0] == methods[1]>");

	iprintToFile(|project://visualizer/treeFile.txt|, methods);
}

public void detectDuplication(loc location) {
	set[Declaration] asts = locToAsts(location);
}