public class OpportunityLineItemHandler {
    public static void onInsert(List<OpportunityLineItem> newOpportunityLineItems) {
        system.debug('Inside Insert');
        List<Territory__c> customRecordsToInsert = new List<Territory__c>();       
        for (OpportunityLineItem oli : newOpportunityLineItems) {
            if (oli.Deal_Record_Type__c == 'Content_Distribution' && !String.isEmpty(oli.Territories_Requested__c)) {
                List<String> multiPicklistValues = oli.Territories_Requested__c.split(';');                
                for (String value : multiPicklistValues) {
                    Territory__c customRecord = new Territory__c();
                    customRecord.Values__c = value;
                    customRecord.Deal_Title_del__c = oli.Id;
                    customRecord.Deal_Title__c = oli.Name;
                    customRecord.Deal_Title_Id__c = oli.Id;
                    customRecord.Deal__c = oli.OpportunityId;
                    customRecordsToInsert.add(customRecord);
                }
            }
        }
        if (!customRecordsToInsert.isEmpty()) {
            insert customRecordsToInsert;
        }
    }    
    public static void onUpdate(List<OpportunityLineItem> newOpportunityLineItems) {
        List<Territory__c> customRecordsToInsert1 = new List<Territory__c>();
        Map<String,String> territoriesMap=new Map<String,String>();
        List<Territory__c> recordsToDelete1 = new List<Territory__c>();
        Set<String> stringSet = new Set<String>();
        List<String> opplineItemId=new List<String>();
        for (OpportunityLineItem oli : newOpportunityLineItems) {
            if (oli.Deal_Record_Type__c == 'Content_Distribution') {
            opplineItemId.add(oli.Id);
            List<Territory__c> customRecordsToUpdate = [Select Id,Values__c,Deal_Title_del__c from Territory__c where Deal_Title_del__c=: oli.Id];
            for(Territory__c ter:customRecordsToUpdate){
                territoriesMap.put(ter.Values__c, ter.Id);
            }
            if (!String.isEmpty(oli.Territories_Requested__c)) {
                List<String> multiPicklistValues = oli.Territories_Requested__c.split(';');                
                for (String value : multiPicklistValues) {
                    stringSet.add(value);
                    if(!territoriesMap.containskey(value)){
                        Territory__c customRecord = new Territory__c();
                        customRecord.Values__c = value;
                        customRecord.Deal_Title_del__c = oli.Id;
                        customRecord.Deal_Title__c = oli.Name;
                        customRecord.Deal_Title_Id__c = oli.Id;
                        customRecord.Deal__c = oli.OpportunityId;
                        customRecordsToInsert1.add(customRecord);
                    }
                }
            }
         }
     }
        if (!customRecordsToInsert1.isEmpty()) {
            insert customRecordsToInsert1;
        }
        for (Territory__c acc : [Select Id,Values__c,Deal_Title_del__c from Territory__c where Deal_Title_del__c In :opplineItemId]) {
            if(!stringSet.contains(acc.Values__c)){
                recordsToDelete1.add(acc);
            }
        }
        delete recordsToDelete1;
    }    
    public static void onDelete(List<OpportunityLineItem> deletedOpportunityLineItems) {
        List<Territory__c> recordsToDelete = new List<Territory__c>();        
        for (OpportunityLineItem oli : deletedOpportunityLineItems) {
            system.debug('Oli '+oli);
            system.debug('Oli Id'+oli.Id);
            system.debug('Query'+[SELECT Id FROM Territory__c WHERE Deal_Title_del__c = :oli.Id]);
            if (oli.Deal_Record_Type__c == 'Content_Distribution') {
            List<Territory__c> matchingRecords = [SELECT Id FROM Territory__c WHERE Deal_Title_Id__c = :oli.Id];
             system.debug('matchingRecords '+matchingRecords);
            recordsToDelete.addAll(matchingRecords);
            system.debug('recordsToDelete '+recordsToDelete);
            }
        }
        if (!recordsToDelete.isEmpty()) {
            system.debug('recordsToDelete2 '+recordsToDelete);
            delete recordsToDelete;
        }
    }
}