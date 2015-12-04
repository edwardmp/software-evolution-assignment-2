module Debug

import IO;

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
	clearFile(location);
	appendToFile(location, s + "\n");
}

public void clearFile(loc location) {
	writeFile(location, "");
}
