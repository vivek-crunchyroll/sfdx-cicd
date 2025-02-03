public without sharing class CP_TerritoryTriggerHandler {

    public static void afterDelete(List<CP_Territory__c> territories){
        List<CP_Territory__c> childTerritories = new List<CP_Territory__c>();
        Map<Id, Set<Id>> masterTerritoryIds = new Map<Id, Set<Id>>();
        Set<Id> masterTerritoryIdSet = new Set<Id>();
        for(CP_Territory__c territory : territories){
            if(territory.Type__c == 'C'){
                childTerritories.add(territory);
                masterTerritoryIdSet.add(territory.Master_Territory__c);
                if(masterTerritoryIds.containsKey(territory.Deal__c)){
                    Set<Id> masterIdSet = masterTerritoryIds.get(territory.Deal__c);
                    masterIdSet.add(territory.Master_Territory__c);                    
                    masterTerritoryIds.put(territory.Deal__c, masterIdSet);
                }
                else{
                    masterTerritoryIds.put(territory.Deal__c, new Set<Id>{territory.Master_Territory__c});
                }
            }
        }
        
        if(!childTerritories.isEmpty()){
            territoryDeletionProcess(childTerritories, masterTerritoryIdSet, masterTerritoryIds);
        }
    }
    
    public static void territoryDeletionProcess(List<CP_Territory__c> territories, Set<Id> masterTerritoryIdSet, Map<Id, Set<Id>> masterTerritoryIds){
        Map<Id, Id> territoryIdWithParentTerritoryId = new Map<Id, Id>();
        for(Master_Territory__c territory : [Select Id, Parent_Territory__c  From Master_Territory__c Where Id IN: masterTerritoryIdSet]){
            territoryIdWithParentTerritoryId.put(territory.Id, territory.Parent_Territory__c);
        }
        
        Map<Id, List<CP_Territory__c>> dealIdWithRelatedTerritories = new Map<Id, List<CP_Territory__c>>();
        for(CP_Territory__c territory : [Select Id, Deal__c, Master_Territory__c, Master_Territory__r.Parent_Territory__c From CP_Territory__c Where Deal__c IN: masterTerritoryIds.keySet()]){
            if(dealIdWithRelatedTerritories.containsKey(territory.Deal__c)){
                List<CP_Territory__c> dealTerritories = dealIdWithRelatedTerritories.get(territory.Deal__c);
                dealTerritories.add(territory);                    
                dealIdWithRelatedTerritories.put(territory.Deal__c, dealTerritories);
            }
            else{
                dealIdWithRelatedTerritories.put(territory.Deal__c, new List<CP_Territory__c>{territory});
            }
        }
        
        List<CP_Territory__c> territoriesToDelete = new List<CP_Territory__c>();
        List<CP_Territory__c> territoriesToUpdate = new List<CP_Territory__c>();
        for(CP_Territory__c territory : territories){
            if(dealIdWithRelatedTerritories.containsKey(territory.Deal__c)){
                for(CP_Territory__c relatedTerritory : dealIdWithRelatedTerritories.get(territory.Deal__c)){
                    if(territoryIdWithParentTerritoryId.containsKey(territory.Master_Territory__c) && territoryIdWithParentTerritoryId.get(territory.Master_Territory__c) == relatedTerritory.Master_Territory__c){
                        territoriesToDelete.add(relatedTerritory);
                    }
                    else if(territoryIdWithParentTerritoryId.containsKey(territory.Master_Territory__c) && territoryIdWithParentTerritoryId.get(territory.Master_Territory__c) == relatedTerritory.Master_Territory__r.Parent_Territory__c){
                        relatedTerritory.Type__c = 'M';
                        territoriesToUpdate.add(relatedTerritory);
                    }
                }
            }
        }
        
        if(!territoriesToDelete.isEmpty()){
            delete territoriesToDelete;
        }
        if(!territoriesToUpdate.isEmpty()){
            update territoriesToUpdate;
        }
    }
}