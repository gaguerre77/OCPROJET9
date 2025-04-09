public class TriggerControl {
  private static Set<String> executed = new Set<String>();

  public static Boolean isFirstRun(String key) {
    if (executed.contains(key)) {
      return false;
    }
    executed.add(key);
    return true;
  }
}
