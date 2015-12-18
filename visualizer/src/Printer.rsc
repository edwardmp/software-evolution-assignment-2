module Printer

import IO;
import util::Math;
import lang::json::IO;

int lineCounter = 0;

// for debugging purposes
public void printToFile(set[value] s) {
	loc location = |project://visualizer/debug/debugPrintSet.txt|;
	clearFile(location);
	iprintToFile(location, s);
}

// for debugging purposes
public void printToFile(list[value] l) {
	loc location = |project://visualizer/debug/debugPrintList.txt|;
	clearFile(location);
	iprintToFile(location, l);
}

// for debugging purposes
public void printToFile(map[value, value] m) {
	loc location = |project://visualizer/debug/debugPrintMap.txt|;
	clearFile(location);
	iprintToFile(location, m);
}

// for debugging purposes
public void printToFile(str s) {
	loc location = |project://visualizer/debug/debugPrintString.txt|;
	
	if(!isFile(location))
		clearFile(location); 
	
	lineCounter += 1;	
	appendToFile(location, toString(lineCounter) + " " + s + "\n");
}

/*
 * Convert result to JSON so it can be imported in web app.
 */
public void printToJSON(map[value, value] m, str fileNameSuffix) {
	loc location = |project://visualizer/debug/resultOfAnalysis|;
	location += fileNameSuffix + ".json";
	clearFile(location);
	appendToFile(location, toJSON(m));
}

/*
 * Clears a file completely if its content is not empty.
 */
public void clearFile(loc location) {
	lineCounter = 0;
	writeFile(location, "");
}
