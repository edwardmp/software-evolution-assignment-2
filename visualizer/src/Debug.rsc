module Debug

import IO;

// for debugging purposes
public void printToFile(set[value] s) {
	clearFile();
	iprintToFile(|project://visualizer/debugPrintSet.txt|, s);
}

// for debugging purposes
public void printToFile(list[value] l) {
	clearFile();
	iprintToFile(|project://visualizer/debugPrintList.txt|, l);
}

// for debugging purposes
public void printToFile(map[value, value] m) {
	clearFile();
	iprintToFile(|project://visualizer/debugPrintMap.txt|, m);
}

// for debugging purposes
public void printToFile(str s) {
	if (isFile(|project://visualizer/debugPrintString.txt|)) {
		appendToFile(|project://visualizer/debugPrintString.txt|, s + "\n");
	}
	else {
		iprintToFile(|project://visualizer/debugPrintString.txt|, s);
	}
}

public void clearFile() {
	writeFile(|project://visualizer/debugPrintSet.txt|, "");
}
