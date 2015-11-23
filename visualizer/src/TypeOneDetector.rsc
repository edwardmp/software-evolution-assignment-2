module TypeOneDetector

import IO;
import lang::java::m3::AST;

// for debugging purposes
public void treeToFile(set[Declaration] asts) {
	iprintToFile(|project://visualizer/treeFile.txt|, asts);
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
public list[value] astsToLines(set[Declaration] decs)
{
	return ([] | it + dec | dec <- mapper(decs, declarationToLines));
}

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
			return "<e@modifiers> <name> {"  + implements + constants + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		case \class(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			
			list[value] result;
			if (isEmpty(extImpl)) {
				result = "<e@modifiers> <name> {" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
			}
			else {
				result = "<e@modifiers> <extImpl> <name> {" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
			}
			
			return result;
		}
		case \class(list[Declaration] body):
			return "{" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
		case \interface(str name, list[Type] extends, list[Type] implements, list[Declaration] body): {
			list[value] extImpl = extends + implements;
			
			list[value] result;
			if (isEmpty(extImpl)) {
				result = "<e@modifiers> <name> {" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
			}
			else {
				result = "<e@modifiers> <extImpl> <name> {" + ([] | it + x | x <- mapper(body, declarationToLines)) + "}";
			}
			
			return result;
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
		case \variables(Type \type, list[Expression] \fragments):
			return [];
		default:
			return [];
	}
}

/*
 * Wrapper for evaluation code common to both (non-abstract) methods and constructors.
 */
public list[value] handleMethodOrConstructor(list[Modifier] modifiers, value returnType, str nameOfMethod, list[Declaration] parameters, list[Expression] exceptions, Statement impl) {
	list[value] body = statementToLines(impl);
	
	return "<modifiers> <returnType> <nameOfMethod> <parameters>" + exceptions + body;
}