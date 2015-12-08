module Printer

import IO;
import util::Math;
import lang::json::IO;

int teller = 0;

// for debugging purposes
public void printToFile(set[value] s) {
	loc location = |project://visualizer/debugPrintSet.txt|;
	clearFile(location);
	iprintToFile(location, s);
}

// for debugging purposes
public void printToFile(list[value] l) {
	loc location = |project://visualizer/debugPrintList.txt|;
	clearFile(location);
	iprintToFile(location, l);
}

// for debugging purposes
public void printToFile(map[value, value] m) {
	loc location = |project://visualizer/debugPrintMap.txt|;
	clearFile(location);
	iprintToFile(location, m);
}

// for debugging purposes
public void printToFile(str s) {
	loc location = |project://visualizer/debugPrintString.txt|;
	
	if(!isFile(location))
		clearFile(location); 
	
	teller += 1;	
	appendToFile(location, toString(teller) + " " + s + "\n");
}

public void printToJSON(map[value, value] m) {
	loc location = |project://visualizer/resultOfAnalysis.json|;
	clearFile(location);
	appendToFile(location, toJSON(m));
}

public void clearFile(loc location) {
	teller = 0;
	writeFile(location, "");
}
