module Debug

import IO;

// for debugging purposes
public void printToFile(set[value] s) {
	iprintToFile(|project://visualizer/debugPrintSet.txt|, s);
}

// for debugging purposes
public void printToFile(list[value] l) {
	iprintToFile(|project://visualizer/debugPrintList.txt|, l);
}

// for debugging purposes
public void printToFile(map[value, value] m) {
	iprintToFile(|project://visualizer/debugPrintMap.txt|, m);
}

