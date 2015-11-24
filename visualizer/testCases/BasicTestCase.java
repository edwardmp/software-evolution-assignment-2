package testCases;

public class BasicTestCase {
	private boolean dummyField;
	
	public BasicTestCase() {
		dummyField = true;
	}
	
	public void firstMethodContainingDuplicateLines() {
		for (int i = 0; i < 10; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
			}
		}
	}
	
	public void secondMethodContainingDuplicateLines() {
		for (int i = 0; i < 10; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
			}
		}
	}
	
}