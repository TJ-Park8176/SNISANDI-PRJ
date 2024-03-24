@isTest
private class FlowDebugLogger_Test {
    @isTest static void testCoverage() {
        List<String> testList = new List<String>{'Test'};
        FlowDebugLogger.trace(testList);
    }
}