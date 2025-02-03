trigger DeleteTerritoryBasedonDeal on Opportunity (Before delete, after insert, after update, before insert,before update) {    
    if (Trigger__mdt.getInstance('Run_All_Triggers')?.IsActive__c == true) {
        if (Trigger.isDelete) {
            List<OpportunityLineItem> OppLineItemIds = [select id from OpportunityLineItem where OpportunityId in: trigger.old AND Deal_Record_Type__c ='Content_Distribution'];
            if (!OppLineItemIds.isEmpty()) {
                OpportunityLineItemHandler.onDelete(OppLineItemIds);          
                //if (!OppLineItemIds.isEmpty()) {
                //insert OppLineItemIds;
            }
        }    
    }

    if(Trigger.isBefore && Trigger.isInsert){
        CP_OpportunityTriggerHandler.beforeInsert(Trigger.new);
    }
    
    
    if(Trigger.isAfter && Trigger.isInsert){
        CP_OpportunityTriggerHandler.afterInsert(Trigger.new);
    }
    
    
    if(Trigger.isAfter && Trigger.isUpdate){
        CP_OpportunityTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        CP_OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
}