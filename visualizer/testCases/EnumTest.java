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