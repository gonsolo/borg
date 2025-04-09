class CheckJava {
        public static void main(String[] args) {
                String version = System.getProperty("java.specification.version");
		System.out.println(version);
                if (version.equals("1.8")) {
                        System.out.println("Java version 8, ok!");
                } else if (version.equals("24")) {
                        System.out.println("Java version 24, ok!");
		} else {
                        System.out.println("Java has to be version 8!");
                        System.exit(1);
                }
        }
}
