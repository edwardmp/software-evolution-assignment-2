package testCases;

public class BasicTestCase2 {
	private boolean dummyField;
	
	public BasicTestCase2() {
		dummyField = true;
	}
	
	public void firstMethodContainingDuplicateLines(int limit) {
		for (int i = 0; i < limit; i++) {
			if (i == 0) {
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
				System.out.println("OMG i == 0");
			}
		}
	}
}