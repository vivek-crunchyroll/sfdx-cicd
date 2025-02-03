public without sharing class CP_OpportunityLineItemHandler {
    public static void populatePriceBookEntry(List<OpportunityLineItem> lineItems){
        Set<String> rightsLineIdSet = new Set<String>();
        for(OpportunityLineItem oli : lineItems){
            if(oli.Deal_Record_Type__c == 'Consumer_Products' || oli.Deal_Record_Type__c == 'Content_Distribution'){
                rightsLineIdSet.add(oli.Product2Id);   
            }
        }
        
        if(!rightsLineIdSet.isEmpty()){
            Map<String, String> mapofIds = new Map<String, String>();        
            for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN :rightsLineIdSet]){
                mapofIds.put(pbe.Product2Id, pbe.Id);
            }
            
            for(OpportunityLineItem oli : lineItems){
                oli.PricebookEntryId = mapofIds.get(oli.Product2Id);
            }
        }
    }
}