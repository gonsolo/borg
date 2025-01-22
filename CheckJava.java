class CheckJava {
        public static void main(String[] args) {
                String version = System.getProperty("java.specification.version");
                if (version.equals("1.8")) {
                        System.out.println("Java version 8, ok!");
                } else {
                        System.out.println("Java has to be version 8!");
                        System.exit(1);
                }
        }
}
