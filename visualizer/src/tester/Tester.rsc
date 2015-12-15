module tester::Tester

import TypeOneDetector;
import IO;
import Exception;

/*
 * Run the analysis on the code in analyzerTestCases and compare it to the results fixture.
 */
public void runTests(bool isEdwardLaptop) {
	loc pathPrefix;
	str resultsFixturePrefix = "visualizer/src/tester/";
	list[str] fixtureLines;
	if (isEdwardLaptop) {
		pathPrefix = |file:///Users/Edward/eclipse/workspace/Assignment%202/|;
		fixtureLines = readFileLines(pathPrefix + resultsFixturePrefix + "resultFixtureEdward.json");
	}
	else {
		pathPrefix = |file:///C:/Users/Olav/Documents/Software%20Engineering/Software%20Evolution/software-evolution-assignment-2|;
		fixtureLines = readFileLines(pathPrefix + resultsFixturePrefix + "resultFixtureOlav.json");
	}
		
	loc javaTestFiles = (pathPrefix + "visualizer/testCases");
	
	// run TypeOneDetector
	main(javaTestFiles);
	list[str] outputFileLines = readFileLines(pathPrefix + "visualizer/resultOfAnalysis/Type1.json");
	
	if (fixtureLines != outputFileLines) {
		throw AssertionFailed("Fixture output file not equal to generated output file");
	}
	else {
		println("No issues encountered.");
	}
}
