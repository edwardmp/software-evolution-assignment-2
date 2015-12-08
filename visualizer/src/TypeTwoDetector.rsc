module TypeTwoDetector

import GeneralDetector;
import IO;
import lang::java::m3::AST;
import Printer;

private int enumCounter = 0;

public void main(loc location) {
	set[Declaration] asts = locToAsts(location);
	list[value] lines = astsToLines(asts);

	map[list[value], list[loc]] duplicationClasses = findDuplicationClasses(lines);
	
	// for debug purposes
	printToFile(removeAnnotations(duplicationClasses));
	println(removeAnnotations(duplicationClasses));
}

public set[Declaration] standardizeIdentifiersLiteralsAndTypes(set[Declaration] ast) {
	top-down visit(ast) {
		case e:\enum(str name, list[Type] implements, list[Declaration] constants, list[Declaration] body): {
		map[str, str] replaceConstantWith = ();
		int constantCount = 0;
			visit(constants) {
				case  \enumConstant(str name, list[Expression] arguments, Declaration class): {
					replaceConstantWith += (name: "enumConstant<constantCount>");
					constantCount += 1;
				}
    			case \enumConstant(str name, list[Expression] arguments): {
    				replaceConstantWith += (name: "enumConstant<constantCount>");
					constantCount += 1;
    			}
			}
		
			insert \enum("enum<enumCounter>", implements,  constants, replaceSimpleNameIdentifiers(body, ()));
			enumCounter += 1;
		}
	}
}

public list[Declaration] replaceSimpleNameIdentifiers(list[Declaration] body, map[str, str] replaceWith) {
	return visit(body) {
		case \simpleName(str name) => \simpleName(replaceWith[name])
	};
}