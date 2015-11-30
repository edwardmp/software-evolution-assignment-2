package testCases;

public class BasicTestCase2 {
	private boolean dummyField;
	
	public BasicTestCase2() {
		dummyField = true;
	}
	
	public void firstMethodContainingDuplicateLines() {
		for (int i = 0; i < 10; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
			}
		}
	}
}