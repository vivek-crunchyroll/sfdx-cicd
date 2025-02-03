trigger TerritorieswiseDeals on OpportunityLineItem (before insert, after insert, after update, after delete) {
    if (Trigger__mdt.getInstance('Run_All_Triggers')?.IsActive__c == true) {
        if (Trigger.isInsert) {
            List<OpportunityLineItem> OppList =new List<OpportunityLineItem>();
            for(OpportunityLineItem OLI: trigger.new){
                if (OLI.Deal_Record_Type__c == 'Content_Distribution') {
                    OppList.add(OLI);
                }     
            }
            if (!OppList.isEmpty()) {
                OpportunityLineItemHandler.onInsert(OppList); 
            }
        }
        if (Trigger.isUpdate){
            List<OpportunityLineItem> OppList =new List<OpportunityLineItem>();
            for(OpportunityLineItem OLI: trigger.new){
                if (OLI.Deal_Record_Type__c == 'Content_Distribution') {
                    OppList.add(OLI);
                }
            }
            if (!OppList.isEmpty()) {
                OpportunityLineItemHandler.onUpdate(OppList); 
            }
        }
        
        if (Trigger.isDelete) {
            List<OpportunityLineItem> OppList =new List<OpportunityLineItem>();        
            for(OpportunityLineItem OLI: trigger.old){
                if (OLI.Deal_Record_Type__c == 'Content_Distribution') {
                    OppList.add(OLI);
                }
            }
            if (!OppList.isEmpty()) {
                OpportunityLineItemHandler.onDelete(OppList);
            }
        }
    }
    
    //Consumer Products Before Insert Events
    if(Trigger.isBefore && Trigger.isInsert){
        CP_OpportunityLineItemHandler.populatePriceBookEntry(Trigger.new);
    }
}