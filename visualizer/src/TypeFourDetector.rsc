module TypeFourDetector

import GeneralDetector;
import TypeTwoDetector;
import IO;
import lang::java::m3::AST;
import List; 
import Printer;
import Set;

public void main(loc location) {
	initialize();
	printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(rewrite(standardize(locToAsts(location)))))), "Type4");
}

public set[Declaration] rewrite(set[Declaration] asts) = { rewrite(ast) | ast <- asts };

public Declaration rewrite(Declaration s) {
	return top-down visit(s) {
		case f:\for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			list[Statement] initializerStatements = [ copySrc(f, \expressionStatement(initializer)) | initializer <- initializers];
			
			list[Statement] updaterStatements = [ copySrc(f, \expressionStatement(updater)) | updater <- updaters];
			Statement convertedBody = copySrc(f, \block(body + updaterStatements));
			Statement convertedWhile = copySrc(f, \while(condition, convertedBody));
			Statement forToWhileLines = copySrc(f, \block(initializerStatements + convertedWhile));
			println(forToWhileLines);
			insert forToWhileLines;
		}
	}
}
