module TypeFourDetector

import GeneralDetector;
import TypeTwoDetector;
import IO;//debug
import lang::java::m3::AST;
import List; // head (as peek), pop and push are used for simulating a stack
import Printer;
import Set;
import Exception;

public void main(loc location) {
	printToJSON(findDuplicationClasses(astsToLines(rewrite(standardize(locToAsts(location))))), "Type4");
}

public set[Declaration] rewrite(set[Declaration] asts) = { rewrite(ast) | ast <- asts };

public Declaration rewrite(Declaration s) {
	return top-down visit(s) {
		/*
		case \do(Statement body, Expression condition): {

		}
		*/
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			;
		}
		/*
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
		}
		*/
		case f:\for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			list[Statement] initializerStatements = [ copySrc(initializer, \expressionStatement(initializer)) | initializer <- initializers];
			list[Statement] updaterStatements = [ copySrc(updater, \expressionStatement(updater)) | updater <- updaters];
			Statement convertedBody = copySrc(f, \block(body + updaterStatements));
			Statement convertedWhile = copySrc(f, \while(condition, convertedBody));
			Statement forToWhileLines = copySrc(f, \block(initializerStatements + convertedWhile));
			insert forToWhileLines;
		}
	}
}
