module TypeTwoDetector

import GeneralDetector;
import lang::java::m3::AST;
import Printer;

private int enumCounter = 0;

// Print for debugging purposes. Not finished yet.
public void main(loc location) = printToJSON(delAnnotationsRec(findDuplicationClasses(astsToLines(locToAsts(location)))));

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