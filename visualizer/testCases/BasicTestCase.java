package testCases;

public class BasicTestCase {
	private boolean dummyField;
	
	public enum EnumTest {
		MONDAY(1) {
			public String test() {
				return "test";
			}
		}, TUESDAY, WEDNESDAY;
		
		public EnumTest getMonday() {
			return MONDAY;
		}
	}
	
	public BasicTestCase() {
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
	
	public void secondMethodContainingDuplicateLines(int limit) {
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