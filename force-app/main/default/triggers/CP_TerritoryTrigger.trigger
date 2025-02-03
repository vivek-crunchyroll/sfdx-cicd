trigger CP_TerritoryTrigger on CP_Territory__c (after delete) {
    
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            CP_TerritoryTriggerHandler.afterDelete(Trigger.old);
        }
    }
}