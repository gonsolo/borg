class CheckJava {
        public static void main(String[] args) {
                String version = System.getProperty("java.specification.version");
                if (version.equals("1.8")) {
                        System.out.println("Java version 8, ok!");
		// Old scala versions have a problem with Java 24
		// Updating triggers multiple other nasty updates
                //} else if (version.equals("24")) {
                //        System.out.println("Java version 24, ok!");
		} else {
                        System.out.println("Java has to be version 8!");
                        System.exit(1);
                }
        }
}
