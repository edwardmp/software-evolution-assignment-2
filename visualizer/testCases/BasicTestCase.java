package testCases;

public class BasicTestCase {
	private boolean dummyField;
	
	public BasicTestCase() {
		dummyField = true;
	}
	
	public firstMethodContainingDuplicateLines() {
		for (int i = 0; i < 10; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
			}
		}
	}
	
	public secondMethodContainingDuplicateLines() {
		for (int i = 0; i < 10; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
			}
		}
	}
	
}