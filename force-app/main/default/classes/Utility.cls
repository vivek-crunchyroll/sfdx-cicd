public without sharing class Utility {
    public static Error_Log__c prepareErrorLog(String errorMessage, String location, String stackTrace, String recordId){
        Error_Log__c log = new Error_Log__c();
        log.Error_Message__c = errorMessage;
        log.Error_Location__c = location;
        log.Error_Stack_Trace__c = stackTrace;
        log.Record_ID__c = recordId;
        log.Status__c = 'Open';
        log.User__c = UserInfo.getUserId();
        return log;
    }
    
    public static void createErrorLog(List<Error_Log__c> errorLogs){
        if(!errorLogs.isEmpty()){
            insert errorLogs;
        }
    }
}